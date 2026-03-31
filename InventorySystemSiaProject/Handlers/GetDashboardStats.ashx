<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetDashboardStats" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.Handlers
{
    public class GetDashboardStats : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();
            try
            {
                System.Diagnostics.Debug.WriteLine("[GetDashboardStats] ===== HANDLER HIT =====");

                string category     = context.Request["category"]  ?? "";
                string startDateStr = context.Request["startDate"] ?? "";
                string endDateStr   = context.Request["endDate"]   ?? "";

                DateTime? startDate = null;
                DateTime? endDate   = null;
                DateTime temp;
                if (!string.IsNullOrEmpty(startDateStr) && DateTime.TryParse(startDateStr, out temp)) startDate = temp;
                if (!string.IsNullOrEmpty(endDateStr)   && DateTime.TryParse(endDateStr,   out temp)) endDate   = temp.Date.AddDays(1).AddSeconds(-1);

                // ── 1. Load paid orders from tbl_order ────────────────────────────
                var rows = new List<OrderRow>();
                try
                {
                    var ordersCol   = DatabaseHelper.GetOrdersCollection();
                    var orderFilter = Builders<BsonDocument>.Filter.In("payment_status",
                        new[] { "Paid", "paid", "PAID" });
                    var paidOrders  = ordersCol.Find(orderFilter).ToList();
                    System.Diagnostics.Debug.WriteLine("[GetDashboardStats] Paid orders found: " + paidOrders.Count);

                    int skipped = 0;
                    foreach (var order in paidOrders)
                    {
                        DateTime orderDate;
                        BsonValue dv;
                        if      (order.TryGetValue("createdAt",  out dv) && TryParseDate(dv, out orderDate)) { }
                        else if (order.TryGetValue("created_at", out dv) && TryParseDate(dv, out orderDate)) { }
                        else if (order.TryGetValue("updatedAt",  out dv) && TryParseDate(dv, out orderDate)) { }
                        else { skipped++; continue; }

                        decimal amount = 0;
                        BsonValue av;
                        if      (order.TryGetValue("total_amount", out av)) amount = BsonToDecimal(av);
                        else if (order.TryGetValue("totalAmount",  out av)) amount = BsonToDecimal(av);
                        else if (order.TryGetValue("total",        out av)) amount = BsonToDecimal(av);

                        var productIds = new List<string>();
                        BsonValue iv;
                        if (order.TryGetValue("items", out iv) && iv.IsBsonArray)
                        {
                            foreach (BsonValue item in iv.AsBsonArray)
                            {
                                if (!item.IsBsonDocument) continue;
                                var doc = item.AsBsonDocument;
                                BsonValue pv;
                                string pid = null;
                                if      (doc.TryGetValue("product_id", out pv)) pid = pv.ToString();
                                else if (doc.TryGetValue("variant_id", out pv)) pid = pv.ToString();
                                else if (doc.TryGetValue("productId",  out pv)) pid = pv.ToString();
                                if (!string.IsNullOrWhiteSpace(pid)) productIds.Add(pid);
                            }
                        }

                        rows.Add(new OrderRow { Date = orderDate.ToLocalTime(), Amount = amount, ProductIds = productIds, Source = "order" });
                    }
                    System.Diagnostics.Debug.WriteLine("[GetDashboardStats] Order rows parsed: " + rows.Count + ", skipped: " + skipped);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[GetDashboardStats] tbl_order query failed (non-fatal): " + ex.Message);
                }

                // ── 2b. Load from Sales collection (main DB) ──────────────────────
                try
                {
                    var salesCol    = DatabaseHelper.GetSalesCollection();
                    var allSales    = salesCol.Find(Builders<Sale>.Filter.Empty).ToList();
                    var productSalesCol = DatabaseHelper.GetProductSalesCollection();
                    var allProductSales = productSalesCol.Find(Builders<Sale>.Filter.Empty).ToList();

                    var seenIds  = new HashSet<string>();
                    var combined = new List<Sale>();
                    foreach (var s in allSales.Concat(allProductSales))
                    {
                        if (!string.IsNullOrEmpty(s.Id) && seenIds.Add(s.Id))
                            combined.Add(s);
                    }

                    foreach (var sale in combined)
                    {
                        var saleDate = sale.TransactionDate.Kind == DateTimeKind.Utc
                            ? sale.TransactionDate.ToLocalTime()
                            : sale.TransactionDate;
                        decimal amount = sale.SalePrice * sale.Quantity;
                        rows.Add(new OrderRow
                        {
                            Date       = saleDate,
                            Amount     = amount,
                            ProductIds = new List<string> { sale.VariantId ?? "", sale.ProductId ?? "" }
                                             .Where(x => !string.IsNullOrWhiteSpace(x)).ToList(),
                            Source     = "sale"
                        });
                    }
                    System.Diagnostics.Debug.WriteLine("[GetDashboardStats] Total rows after merging Sales collection: " + rows.Count);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[GetDashboardStats] Sales collection query failed (non-fatal): " + ex.Message);
                }

                if (rows.Count > 0)
                    System.Diagnostics.Debug.WriteLine("[GetDashboardStats] Date range in DB: " +
                        rows.Min(r => r.Date).ToString("yyyy-MM-dd") + " to " +
                        rows.Max(r => r.Date).ToString("yyyy-MM-dd"));

                // ── 3. Optional category filter ────────────────────────────────────
                if (!string.IsNullOrWhiteSpace(category))
                {
                    // ✅ Use BsonDocument projection to avoid VariantImgUrls deserialization crash
                    var variantsCol = DatabaseHelper.GetCollection<BsonDocument>(
                        DatabaseHelper.GetProductVariantsCollectionName());
                    var productsCol = DatabaseHelper.GetProductsCollection();

                    var allVariants = variantsCol
                        .Find(Builders<BsonDocument>.Filter.Empty)
                        .Project(Builders<BsonDocument>.Projection
                            .Include("_id").Include("productId").Include("ProductId"))
                        .ToList();

                    var variantToProduct = new Dictionary<string, string>();
                    foreach (var d in allVariants)
                    {
                        BsonValue pv2;
                        var pid2 = (d.TryGetValue("productId", out pv2) || d.TryGetValue("ProductId", out pv2))
                            ? pv2.ToString() : "";
                        var k = d["_id"].ToString();
                        if (!variantToProduct.ContainsKey(k)) variantToProduct[k] = pid2;
                    }

                    var allProducts = productsCol
                        .Find(Builders<Product>.Filter.Empty)
                        .Project(Builders<Product>.Projection.Include("_id").Include("productCategory"))
                        .As<BsonDocument>().ToList();

                    var productToCategory = new Dictionary<string, string>();
                    foreach (var d in allProducts)
                    {
                        BsonValue cv;
                        var cat2 = (d.TryGetValue("productCategory", out cv) || d.TryGetValue("ProductCategory", out cv))
                            ? cv.ToString() : "";
                        var k = d["_id"].ToString();
                        if (!productToCategory.ContainsKey(k)) productToCategory[k] = cat2;
                    }

                    string wantedCat = category.Trim().ToLowerInvariant();
                    rows = rows.Where(row =>
                    {
                        foreach (var pid3 in row.ProductIds)
                        {
                            string productId2;
                            if (variantToProduct.TryGetValue(pid3, out productId2) && !string.IsNullOrEmpty(productId2))
                            {
                                string c2;
                                if (productToCategory.TryGetValue(productId2, out c2))
                                    if ((c2 ?? "").Trim().ToLowerInvariant() == wantedCat) return true;
                            }
                            string cDirect;
                            if (productToCategory.TryGetValue(pid3, out cDirect))
                                if ((cDirect ?? "").Trim().ToLowerInvariant() == wantedCat) return true;
                        }
                        return false;
                    }).ToList();
                }

                // ── 4. Date filter ─────────────────────────────────────────────────
                if (startDate.HasValue) rows = rows.Where(r => r.Date >= startDate.Value).ToList();
                if (endDate.HasValue)   rows = rows.Where(r => r.Date <= endDate.Value).ToList();

                // ── 5. Compute stats ───────────────────────────────────────────────
                var now               = DateTime.Now;
                var currentYearStart  = new DateTime(now.Year, 1, 1);
                var lastMonthStart    = new DateTime(now.Year, now.Month, 1).AddMonths(-1);
                var lastMonthEnd      = new DateTime(now.Year, now.Month, 1).AddSeconds(-1);
                var currentMonthStart = new DateTime(now.Year, now.Month, 1);

                var yearRows = startDate.HasValue || endDate.HasValue
                                ? rows
                                : rows.Where(r => r.Date >= currentYearStart).ToList();

                decimal totalSales  = yearRows.Sum(r => r.Amount);
                int     totalOrders = yearRows.Count;

                System.Diagnostics.Debug.WriteLine("[GetDashboardStats] yearRows=" + yearRows.Count +
                    ", totalSales=" + totalSales + ", currentYearStart=" + currentYearStart.ToString("yyyy-MM-dd"));

                decimal lastMonthSales    = rows.Where(r => r.Date >= lastMonthStart && r.Date <= lastMonthEnd).Sum(r => r.Amount);
                decimal currentMonthSales = rows.Where(r => r.Date >= currentMonthStart).Sum(r => r.Amount);
                decimal salesGrowth = lastMonthSales > 0
                    ? Math.Round((currentMonthSales - lastMonthSales) / lastMonthSales * 100, 2) : 0;

                int lastMonthOrders    = rows.Count(r => r.Date >= lastMonthStart && r.Date <= lastMonthEnd);
                int currentMonthOrders = rows.Count(r => r.Date >= currentMonthStart);
                decimal orderGrowth = lastMonthOrders > 0
                    ? Math.Round((currentMonthOrders - lastMonthOrders) / (decimal)lastMonthOrders * 100, 2) : 0;

                // ── 6. Products / variants — use BsonDocument to avoid VariantImgUrls crash ──
                var variantsBson = DatabaseHelper.GetCollection<BsonDocument>(
                    DatabaseHelper.GetProductVariantsCollectionName())
                    .Find(Builders<BsonDocument>.Filter.Empty)
                    .Project(Builders<BsonDocument>.Projection
                        .Include("_id").Include("stockQuantity").Include("StockQuantity")
                        .Include("minimumStock").Include("MinimumStock"))
                    .ToList();

                var products2      = DatabaseHelper.GetProductsCollection()
                    .Find(Builders<Product>.Filter.Empty).ToList();
                int totalProducts2  = products2.Count;
                int activeVariants2 = variantsBson.Count;
                int lowStockItems2  = variantsBson.Count(v =>
                {
                    BsonValue sv;
                    int stock = (v.TryGetValue("stockQuantity", out sv) || v.TryGetValue("StockQuantity", out sv))
                        ? (int)BsonToDecimal(sv) : 0;
                    BsonValue mv;
                    int min = (v.TryGetValue("minimumStock", out mv) || v.TryGetValue("MinimumStock", out mv))
                        ? (int)BsonToDecimal(mv) : 5;
                    return stock <= min;
                });

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[GetDashboardStats] RESULT totalSales={0:N2}, totalOrders={1}, salesGrowth={2}%",
                    totalSales, totalOrders, salesGrowth));

                context.Response.Write(serializer.Serialize(new
                {
                    totalSales     = totalSales,
                    salesGrowth    = salesGrowth,
                    totalOrders    = totalOrders,
                    orderGrowth    = orderGrowth,
                    totalProducts  = totalProducts2,
                    lowStockItems  = lowStockItems2,
                    activeVariants = activeVariants2
                }));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[GetDashboardStats] ERROR: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("[GetDashboardStats] STACK: " + ex.StackTrace);
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { error = ex.Message, details = ex.GetType().Name }));
            }
        }

        // ── Helpers ───────────────────────────────────────────────────────────────
        private static bool TryParseDate(BsonValue val, out DateTime result)
        {
            result = DateTime.MinValue;
            if (val == null || val.IsBsonNull) return false;
            try
            {
                if (val.BsonType == BsonType.DateTime) { result = val.ToUniversalTime(); return true; }
                if (val.BsonType == BsonType.String) return DateTime.TryParse(val.AsString, out result);
            }
            catch { }
            return false;
        }

        private static decimal BsonToDecimal(BsonValue val)
        {
            if (val == null || val.IsBsonNull) return 0;
            try
            {
                if (val.IsNumeric) return (decimal)val.ToDouble();
                if (val.BsonType == BsonType.String) { decimal d; if (decimal.TryParse(val.AsString, out d)) return d; }
            }
            catch { }
            return 0;
        }

        private class OrderRow
        {
            public OrderRow() { ProductIds = new List<string>(); }
            public DateTime     Date       { get; set; }
            public decimal      Amount     { get; set; }
            public List<string> ProductIds { get; set; }
            public string       Source     { get; set; }
        }

        public bool IsReusable { get { return false; } }
    }
}