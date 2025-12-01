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
                string category = context.Request["category"]; // exact match required
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

                // Category filter (normalize both sides to tolerate whitespace/case differences)
                if (!string.IsNullOrEmpty(category))
                {
                    var wanted = norm(category);
                    // Log all unique normalized categories for debugging
                    var uniqueCats = salesWithCategory.Select(s => norm(s.Category)).Distinct().ToList();
                    System.Diagnostics.Debug.WriteLine("[GetSalesByCategory] Unique normalized categories in sales: " + string.Join(", ", uniqueCats));
                    salesWithCategory = salesWithCategory
                        .Where(s => wanted != null && norm(s.Category) == wanted)
                        .ToList();
                }
                else
                {
                    // All categories selected: debug log sales for key categories
                    string[] debugCategories = { "Skincare", "Haircare", "Makeup", "Fragrance", "Body Care" };
                    foreach (var cat in debugCategories)
                    {
                        var total = salesWithCategory.Where(s => norm(s.Category) == norm(cat)).Sum(s => s.TotalAmount);
                        System.Diagnostics.Debug.WriteLine("[GetSalesByCategory] Total sales for '" + cat + "': " + total);
                    }
                }

                // Date range filter
                if (startDate.HasValue)
                    salesWithCategory = salesWithCategory.Where(s => s.TransactionDate >= startDate.Value).ToList();
                if (endDate.HasValue)
                    salesWithCategory = salesWithCategory.Where(s => s.TransactionDate <= endDate.Value).ToList();

                var labels = new List<string>();
                var data = new List<decimal>();
                var lastYearData = new List<decimal>();

                var now = DateTime.Now;
                int currentYear = now.Year;

                // Helper: sum sales in a date span
                Func<DateTime, DateTime, decimal> spanSumCurrent = (from, to) => salesWithCategory.Where(s => s.TransactionDate >= from && s.TransactionDate <= to).Sum(s => s.TotalAmount);
                Func<DateTime, DateTime, decimal> spanSumPrev = (from, to) => salesWithCategory.Where(s => s.TransactionDate >= from.AddYears(-1) && s.TransactionDate <= to.AddYears(-1)).Sum(s => s.TotalAmount);

                if (period == "daily")
                {
                    // Last 14 days (inclusive today)
                    int days = 14;
                    for (int i = days - 1; i >= 0; i--)
                    {
                        var day = now.Date.AddDays(-i);
                        labels.Add(day.ToString("MMM dd"));
                        data.Add(salesWithCategory.Where(s => s.TransactionDate.Date == day.Date).Sum(s => s.TotalAmount));
                        var prevDay = day.AddYears(-1);
                        lastYearData.Add(salesWithCategory.Where(s => s.TransactionDate.Date == prevDay.Date).Sum(s => s.TotalAmount));
                    }
                }
                else if (period == "weekly")
                {
                    // Last 8 weeks (Monday-based weeks ending Sunday)
                    var culture = System.Globalization.CultureInfo.InvariantCulture;
                    var cal = culture.Calendar;
                    // Find last Sunday to anchor weeks
                    var endOfCurrentWeek = now.Date.AddDays(DayOfWeek.Sunday - now.Date.DayOfWeek);
                    for (int i = 7; i >= 0; i--)
                    {
                        var weekEnd = endOfCurrentWeek.AddDays(-7 * i);
                        var weekStart = weekEnd.AddDays(-6); // 7-day window
                        int weekNumber = cal.GetWeekOfYear(weekStart, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday);
                        labels.Add("W" + weekNumber.ToString());
                        data.Add(spanSumCurrent(weekStart, weekEnd));
                        lastYearData.Add(spanSumPrev(weekStart, weekEnd));
                    }
                }
                else // monthly
                {
                    // Full 12 months for current year
                    for (int m = 1; m <= 12; m++)
                    {
                        var monthStart = new DateTime(currentYear, m, 1);
                        var monthEnd = monthStart.AddMonths(1).AddDays(-1);
                        labels.Add(System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(m));
                        data.Add(spanSumCurrent(monthStart, monthEnd));
                        lastYearData.Add(spanSumPrev(monthStart, monthEnd));
                    }

                    // If user provided date range restrict output to covered months
                    if (startDate.HasValue || endDate.HasValue)
                    {
                        DateTime from = startDate ?? new DateTime(currentYear, 1, 1);
                        DateTime to = endDate ?? new DateTime(currentYear, 12, 31);
                        var filteredIndices = labels.Select((lbl, idx) => new { lbl, idx, month = idx + 1 })
                                                     .Where(x => new DateTime(currentYear, x.month, 1) >= new DateTime(currentYear, from.Month, 1) && new DateTime(currentYear, x.month, 1) <= new DateTime(currentYear, to.Month, 1))
                                                     .Select(x => x.idx)
                                                     .ToList();
                        labels = filteredIndices.Select(i => labels[i]).ToList();
                        data = filteredIndices.Select(i => data[i]).ToList();
                        lastYearData = filteredIndices.Select(i => lastYearData[i]).ToList();
                    }
                }

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
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { error = ex.Message, details = ex.GetType().Name }));
            }
        }
        public bool IsReusable { get { return false; } }
    }
}
