<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetSalesByCategory" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;
using System.Linq;
using System.Collections.Generic;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;

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
                if (!string.IsNullOrEmpty(startDateStr)) {
                    DateTime tempStart;
                    if (DateTime.TryParse(startDateStr, out tempStart)) startDate = tempStart;
                }
                if (!string.IsNullOrEmpty(endDateStr)) {
                    DateTime tempEnd;
                    if (DateTime.TryParse(endDateStr, out tempEnd)) endDate = tempEnd;
                }

                var salesCollection = InventorySystemSiaProject.Helpers.DatabaseHelper.GetSalesCollection();
                var sales = ((IMongoCollection<Sale>)salesCollection).Find(Builders<Sale>.Filter.Empty).ToList();

                // Fetch products and variants for category lookup
                var productCollection = InventorySystemSiaProject.Helpers.DatabaseHelper.GetProductsCollection();
                var variantCollection = InventorySystemSiaProject.Helpers.DatabaseHelper.GetProductVariantsCollection();
                var products = ((IMongoCollection<Product>)productCollection).Find(Builders<Product>.Filter.Empty).ToList();
                var variants = ((IMongoCollection<ProductVariant>)variantCollection).Find(Builders<ProductVariant>.Filter.Empty).ToList();

                var productDict = products.ToDictionary(p => p.Id, p => p);
                var variantDict = variants.ToDictionary(v => v.Id, v => v);

                // Attach category to each sale
                var salesWithCategory = sales.Select(s => {
                    string cat = null;
                    if (!string.IsNullOrEmpty(s.ProductId) && productDict.ContainsKey(s.ProductId))
                        cat = productDict[s.ProductId].ProductCategory;
                    else if (!string.IsNullOrEmpty(s.VariantId) && variantDict.ContainsKey(s.VariantId))
                    {
                        var variant = variantDict[s.VariantId];
                        if (!string.IsNullOrEmpty(variant.ProductId) && productDict.ContainsKey(variant.ProductId))
                            cat = productDict[variant.ProductId].ProductCategory;
                    }
                    return new {
                        s.Id,
                        s.ProductId,
                        s.VariantId,
                        s.TransactionDate,
                        s.Quantity,
                        s.SalePrice,
                        s.TotalAmount,
                        Category = cat
                    };
                }).ToList();

                // Filter by category
                if (!string.IsNullOrEmpty(category))
                    salesWithCategory = salesWithCategory.Where(s => s.Category == category).ToList();

                // Filter by date range
                if (startDate.HasValue)
                    salesWithCategory = salesWithCategory.Where(s => s.TransactionDate >= startDate.Value).ToList();
                if (endDate.HasValue)
                    salesWithCategory = salesWithCategory.Where(s => s.TransactionDate <= endDate.Value).ToList();

                // Aggregate by period
                var labels = new List<string>();
                var data = new List<decimal>();
                var lastYearData = new List<decimal>();

                if (period == "daily")
                {
                    var grouped = salesWithCategory
                        .GroupBy(s => s.TransactionDate.Date)
                        .OrderBy(g => g.Key)
                        .ToList();
                    labels = grouped.Select(g => g.Key.ToString("MMM dd")).ToList();
                    data = grouped.Select(g => g.Sum(x => x.TotalAmount)).ToList();

                    // Last year comparison
                    var lastYear = salesWithCategory.Where(s => s.TransactionDate.Year == DateTime.Now.Year - 1)
                        .GroupBy(s => s.TransactionDate.Date)
                        .OrderBy(g => g.Key)
                        .ToList();
                    lastYearData = lastYear.Select(g => g.Sum(x => x.TotalAmount)).ToList();
                }
                else if (period == "weekly")
                {
                    var grouped = salesWithCategory
                        .GroupBy(s => System.Globalization.CultureInfo.InvariantCulture.Calendar.GetWeekOfYear(s.TransactionDate, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday))
                        .OrderBy(g => g.Key)
                        .ToList();
                    labels = grouped.Select(g => "Week " + g.Key).ToList();
                    data = grouped.Select(g => g.Sum(x => x.TotalAmount)).ToList();

                    var lastYear = salesWithCategory.Where(s => s.TransactionDate.Year == DateTime.Now.Year - 1)
                        .GroupBy(s => System.Globalization.CultureInfo.InvariantCulture.Calendar.GetWeekOfYear(s.TransactionDate, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday))
                        .OrderBy(g => g.Key)
                        .ToList();
                    lastYearData = lastYear.Select(g => g.Sum(x => x.TotalAmount)).ToList();
                }
                else // monthly
                {
                    var grouped = salesWithCategory
                        .GroupBy(s => s.TransactionDate.Month)
                        .OrderBy(g => g.Key)
                        .ToList();
                    labels = grouped.Select(g => System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(g.Key)).ToList();
                    data = grouped.Select(g => g.Sum(x => x.TotalAmount)).ToList();

                    var lastYear = salesWithCategory.Where(s => s.TransactionDate.Year == DateTime.Now.Year - 1)
                        .GroupBy(s => s.TransactionDate.Month)
                        .OrderBy(g => g.Key)
                        .ToList();
                    lastYearData = lastYear.Select(g => g.Sum(x => x.TotalAmount)).ToList();
                }

                var result = new {
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
