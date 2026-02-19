<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetSalesByCategory" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;
using System.Linq;
using System.Collections.Generic;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using System.Text;

namespace InventorySystemSiaProject.Handlers
{
    public class GetSalesByCategory : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();
            try
            {
                // Get query params
                string period = context.Request["period"] ?? "monthly";
                string category = context.Request["category"];
                string startDateStr = context.Request["startDate"];
                string endDateStr = context.Request["endDate"];

                DateTime? startDate = null;
                DateTime? endDate = null;
                DateTime temp;
                if (!string.IsNullOrEmpty(startDateStr) && DateTime.TryParse(startDateStr, out temp)) startDate = temp;
                if (!string.IsNullOrEmpty(endDateStr) && DateTime.TryParse(endDateStr, out temp)) endDate = temp;

                // Load collections
                var salesCollection = InventorySystemSiaProject.Helpers.DatabaseHelper.GetSalesCollection();
                var sales = ((IMongoCollection<Sale>)salesCollection).Find(Builders<Sale>.Filter.Empty).ToList();

                // Products & variants lookup for category attribution
                var productCollection = InventorySystemSiaProject.Helpers.DatabaseHelper.GetProductsCollection();
                var variantCollection = InventorySystemSiaProject.Helpers.DatabaseHelper.GetProductVariantsCollection();
                var products = ((IMongoCollection<Product>)productCollection).Find(Builders<Product>.Filter.Empty).ToList();
                var variants = ((IMongoCollection<ProductVariant>)variantCollection).Find(Builders<ProductVariant>.Filter.Empty).ToList();

                var productDict = products.ToDictionary(p => p.Id, p => p);
                var variantDict = variants.ToDictionary(v => v.Id, v => v);

                // Helper to normalize category strings for comparison
                Func<string, string> norm = s =>
                {
                    if (string.IsNullOrWhiteSpace(s)) return null;
                    s = s.Trim();
                    var sb = new StringBuilder(s.Length);
                    foreach (var ch in s)
                    {
                        if (!char.IsWhiteSpace(ch)) sb.Append(char.ToUpperInvariant(ch));
                    }
                    return sb.ToString();
                };

                // Project sales with category (robust lookup: try ProductId, then VariantId -> ProductId)
                var salesWithCategory = sales.Select(s => {
                    string cat = null;
                    // Try direct product link first
                    if (!string.IsNullOrEmpty(s.ProductId) && productDict.ContainsKey(s.ProductId))
                        cat = productDict[s.ProductId].ProductCategory;
                    // If still unknown, try through variant linkage even if ProductId existed but wasn't found
                    if (cat == null && !string.IsNullOrEmpty(s.VariantId) && variantDict.ContainsKey(s.VariantId))
                    {
                        var variant = variantDict[s.VariantId];
                        if (!string.IsNullOrEmpty(variant.ProductId) && productDict.ContainsKey(variant.ProductId))
                            cat = productDict[variant.ProductId].ProductCategory;
                    }
                    return new {
                        s.TransactionDate,
                        s.Quantity,
                        s.TotalAmount,
                        Category = cat
                    };
                }).ToList();

                // ? Store the category-filtered list BEFORE date filtering for last year calculations
                var salesByCategoryOnly = salesWithCategory;
                
                // Category filter
                if (!string.IsNullOrEmpty(category))
                {
                    var wanted = norm(category);
                    // Log all unique normalized categories for debugging
                    var uniqueCats = salesWithCategory.Select(s => norm(s.Category)).Distinct().ToList();
                    System.Diagnostics.Debug.WriteLine("[GetSalesByCategory] Unique normalized categories: " + string.Join(", ", uniqueCats));
                    salesByCategoryOnly = salesWithCategory.Where(s => wanted != null && norm(s.Category) == wanted).ToList();
                }

                // ? Date range filter ONLY for current period
                var salesCurrent = salesByCategoryOnly;
                if (startDate.HasValue)
                    salesCurrent = salesCurrent.Where(s => s.TransactionDate >= startDate.Value).ToList();
                if (endDate.HasValue)
                    salesCurrent = salesCurrent.Where(s => s.TransactionDate <= endDate.Value).ToList();

                var labels = new List<string>();
                var data = new List<decimal>();
                var lastYearData = new List<decimal>();

                var now = DateTime.Now;

                // ? Fixed helpers: Current uses filtered list, Last Year uses category-only filtered list
                Func<DateTime, DateTime, decimal> spanSumCurrent = (from, to) => 
                    salesCurrent.Where(s => s.TransactionDate >= from && s.TransactionDate <= to).Sum(s => s.TotalAmount);
                
                Func<DateTime, DateTime, decimal> spanSumPrev = (from, to) => 
                    salesByCategoryOnly.Where(s => s.TransactionDate >= from.AddYears(-1) && s.TransactionDate <= to.AddYears(-1)).Sum(s => s.TotalAmount);

                if (period == "daily")
                {
                    // If custom date range, use that; otherwise last 14 days
                    DateTime rangeStart, rangeEnd;
                    if (startDate.HasValue && endDate.HasValue)
                    {
                        rangeStart = startDate.Value;
                        rangeEnd = endDate.Value;
                    }
                    else
                    {
                        rangeStart = now.Date.AddDays(-13); // Last 14 days inclusive
                        rangeEnd = now.Date;
                    }
                    
                    for (var day = rangeStart.Date; day <= rangeEnd.Date; day = day.AddDays(1))
                    {
                        labels.Add(day.ToString("MMM dd, yyyy"));
                        data.Add(salesCurrent.Where(s => s.TransactionDate.Date == day.Date).Sum(s => s.TotalAmount));
                        var prevDay = day.AddYears(-1);
                        lastYearData.Add(salesByCategoryOnly.Where(s => s.TransactionDate.Date == prevDay.Date).Sum(s => s.TotalAmount));
                    }
                }
                else if (period == "weekly")
                {
                    // Last 8 weeks or custom range
                    var culture = System.Globalization.CultureInfo.InvariantCulture;
                    var cal = culture.Calendar;
                    
                    DateTime rangeStart, rangeEnd;
                    if (startDate.HasValue && endDate.HasValue)
                    {
                        rangeStart = startDate.Value;
                        rangeEnd = endDate.Value;
                    }
                    else
                    {
                        rangeEnd = now.Date.AddDays(DayOfWeek.Sunday - now.Date.DayOfWeek);
                        rangeStart = rangeEnd.AddDays(-7 * 7); // 8 weeks back
                    }
                    
                    // Generate weeks from start to end
                    var currentWeekStart = rangeStart.Date.AddDays(-(int)rangeStart.DayOfWeek + (int)DayOfWeek.Monday);
                    if (currentWeekStart > rangeStart) currentWeekStart = currentWeekStart.AddDays(-7);
                    
                    while (currentWeekStart <= rangeEnd)
                    {
                        var weekEnd = currentWeekStart.AddDays(6);
                        int weekNumber = cal.GetWeekOfYear(currentWeekStart, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday);
                        int year = currentWeekStart.Year;
                        labels.Add(string.Format("W{0} {1}", weekNumber, year));
                        data.Add(spanSumCurrent(currentWeekStart, weekEnd));
                        lastYearData.Add(spanSumPrev(currentWeekStart, weekEnd));
                        currentWeekStart = currentWeekStart.AddDays(7);
                    }
                }
                else // monthly
                {
                    // Determine the range: if custom dates provided, use those; otherwise use current year
                    DateTime rangeStart, rangeEnd;
                    if (startDate.HasValue && endDate.HasValue)
                    {
                        rangeStart = new DateTime(startDate.Value.Year, startDate.Value.Month, 1);
                        rangeEnd = new DateTime(endDate.Value.Year, endDate.Value.Month, 1);
                    }
                    else if (startDate.HasValue)
                    {
                        rangeStart = new DateTime(startDate.Value.Year, startDate.Value.Month, 1);
                        rangeEnd = new DateTime(now.Year, 12, 1);
                    }
                    else if (endDate.HasValue)
                    {
                        rangeStart = new DateTime(now.Year, 1, 1);
                        rangeEnd = new DateTime(endDate.Value.Year, endDate.Value.Month, 1);
                    }
                    else
                    {
                        // Default: current year
                        rangeStart = new DateTime(now.Year, 1, 1);
                        rangeEnd = new DateTime(now.Year, 12, 1);
                    }
                    
                    // Generate all months in the range
                    var currentMonth = rangeStart;
                    while (currentMonth <= rangeEnd)
                    {
                        var monthStart = currentMonth;
                        var monthEnd = monthStart.AddMonths(1).AddDays(-1);
                        
                        // Format label with year if spanning multiple years
                        if (rangeStart.Year != rangeEnd.Year)
                        {
                            labels.Add(string.Format("{0} {1}", 
                                System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(currentMonth.Month), 
                                currentMonth.Year));
                        }
                        else
                        {
                            labels.Add(System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(currentMonth.Month));
                        }
                        
                        data.Add(spanSumCurrent(monthStart, monthEnd));
                        lastYearData.Add(spanSumPrev(monthStart, monthEnd));
                        
                        currentMonth = currentMonth.AddMonths(1);
                    }
                }

                System.Diagnostics.Debug.WriteLine(string.Format("[GetSalesByCategory] Returning {0} data points. Current total: {1}, Last year total: {2}", 
                    labels.Count, 
                    data.Sum(), 
                    lastYearData.Sum()));

                var result = new
                {
                    labels = labels,
                    data = data,
                    lastYearData = lastYearData
                };
                context.Response.Write(serializer.Serialize(result));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[GetSalesByCategory] ERROR: " + ex.Message);
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { error = ex.Message, details = ex.GetType().Name }));
            }
        }
        public bool IsReusable { get { return false; } }
    }
}
