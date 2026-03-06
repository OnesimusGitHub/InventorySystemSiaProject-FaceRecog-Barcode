<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetSalesByCategory" %>

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
    public class GetSalesByCategory : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                string period       = context.Request["period"]    ?? "monthly";
                string category     = context.Request["category"]  ?? "";
                string startDateStr = context.Request["startDate"] ?? "";
                string endDateStr   = context.Request["endDate"]   ?? "";

                DateTime? startDate = null;
                DateTime? endDate   = null;
                DateTime temp;
                if (!string.IsNullOrEmpty(startDateStr) && DateTime.TryParse(startDateStr, out temp)) startDate = temp;
                if (!string.IsNullOrEmpty(endDateStr)   && DateTime.TryParse(endDateStr,   out temp)) endDate   = temp.Date.AddDays(1).AddSeconds(-1);

                // ── 1. Load paid orders ───────────────────────────────────────────
                var ordersCollection = DatabaseHelper.GetOrdersCollection();
                var orderFilter = Builders<BsonDocument>.Filter.In("payment_status",
                    new[] { "Paid", "paid", "PAID" });
                var paidOrders = ordersCollection.Find(orderFilter).ToList();

                System.Diagnostics.Debug.WriteLine("[GetSalesByCategory] Total paid orders: " + paidOrders.Count);

                // ── 2. Build flat list ────────────────────────────────────────────
                var orderRows  = new List<OrderRow>();
                int skipped    = 0;
                int noAmount   = 0;

                foreach (var order in paidOrders)
                {
                    // ── Date: try createdAt, created_at, updatedAt ────────────────
                    DateTime orderDate;
                    BsonValue dateVal;
                    if      (order.TryGetValue("createdAt",  out dateVal) && TryParseDate(dateVal, out orderDate)) { }
                    else if (order.TryGetValue("created_at", out dateVal) && TryParseDate(dateVal, out orderDate)) { }
                    else if (order.TryGetValue("updatedAt",  out dateVal) && TryParseDate(dateVal, out orderDate)) { }
                    else { skipped++; continue; }

                    // ── Amount: try total_amount, totalAmount, total ───────────────
                    decimal totalAmount = 0;
                    BsonValue amtVal;
                    if      (order.TryGetValue("total_amount", out amtVal)) totalAmount = BsonToDecimal(amtVal);
                    else if (order.TryGetValue("totalAmount",  out amtVal)) totalAmount = BsonToDecimal(amtVal);
                    else if (order.TryGetValue("total",        out amtVal)) totalAmount = BsonToDecimal(amtVal);
                    else noAmount++;

                    // ── Items: product_id / variant_id / productId ────────────────
                    var productIds = new List<string>();
                    BsonValue itemsVal;
                    if (order.TryGetValue("items", out itemsVal) && itemsVal.IsBsonArray)
                    {
                        foreach (BsonValue item in itemsVal.AsBsonArray)
                        {
                            if (!item.IsBsonDocument) continue;
                            var doc = item.AsBsonDocument;
                            BsonValue pidVal;
                            string pid = null;
                            if      (doc.TryGetValue("product_id", out pidVal)) pid = pidVal.ToString();
                            else if (doc.TryGetValue("variant_id", out pidVal)) pid = pidVal.ToString();
                            else if (doc.TryGetValue("productId",  out pidVal)) pid = pidVal.ToString();
                            if (!string.IsNullOrWhiteSpace(pid)) productIds.Add(pid);
                        }
                    }

                    orderRows.Add(new OrderRow
                    {
                        Date        = orderDate.ToLocalTime(),
                        TotalAmount = totalAmount,
                        ProductIds  = productIds
                    });
                }

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[GetSalesByCategory] Parsed {0} rows, skipped {1} (no date), {2} had no amount",
                    orderRows.Count, skipped, noAmount));

                // ── 3. Category filter ────────────────────────────────────────────
                if (!string.IsNullOrWhiteSpace(category))
                {
                    var variantsCol = DatabaseHelper.GetProductVariantsCollection();
                    var productsCol = DatabaseHelper.GetProductsCollection();

                    var allVariants = variantsCol
                        .Find(Builders<ProductVariant>.Filter.Empty)
                        .Project(Builders<ProductVariant>.Projection
                            .Include(v => v.Id).Include(v => v.ProductId))
                        .As<BsonDocument>()
                        .ToList();

                    var variantToProduct = new Dictionary<string, string>();
                    foreach (var d in allVariants)
                    {
                        var key = d["_id"].ToString();
                        BsonValue pv;
                        var val = (d.TryGetValue("productId", out pv) || d.TryGetValue("ProductId", out pv))
                            ? pv.ToString() : "";
                        if (!variantToProduct.ContainsKey(key))
                            variantToProduct[key] = val;
                    }

                    var allProducts = productsCol
                        .Find(Builders<Product>.Filter.Empty)
                        .Project(Builders<Product>.Projection
                            .Include("_id").Include("productCategory"))
                        .As<BsonDocument>()
                        .ToList();

                    var productToCategory = new Dictionary<string, string>();
                    foreach (var d in allProducts)
                    {
                        var key = d["_id"].ToString();
                        BsonValue cv;
                        var val = (d.TryGetValue("productCategory", out cv) || d.TryGetValue("ProductCategory", out cv))
                            ? cv.ToString() : "";
                        if (!productToCategory.ContainsKey(key))
                            productToCategory[key] = val;
                    }

                    string wantedCat = category.Trim().ToLowerInvariant();

                    orderRows = orderRows.Where(row =>
                    {
                        foreach (var pid in row.ProductIds)
                        {
                            string productId;
                            if (variantToProduct.TryGetValue(pid, out productId) && !string.IsNullOrEmpty(productId))
                            {
                                string cat;
                                if (productToCategory.TryGetValue(productId, out cat))
                                    if ((cat ?? "").Trim().ToLowerInvariant() == wantedCat)
                                        return true;
                            }
                            // Also try pid directly as a productId
                            string catDirect;
                            if (productToCategory.TryGetValue(pid, out catDirect))
                                if ((catDirect ?? "").Trim().ToLowerInvariant() == wantedCat)
                                    return true;
                        }
                        return false;
                    }).ToList();

                    System.Diagnostics.Debug.WriteLine(string.Format(
                        "[GetSalesByCategory] After category filter '{0}': {1} orders",
                        category, orderRows.Count));
                }

                // ── 4. Date filter ────────────────────────────────────────────────
                var currentRows = orderRows.ToList();
                if (startDate.HasValue) currentRows = currentRows.Where(r => r.Date >= startDate.Value).ToList();
                if (endDate.HasValue)   currentRows = currentRows.Where(r => r.Date <= endDate.Value).ToList();

                // ── 5. Aggregate ──────────────────────────────────────────────────
                var labels       = new List<string>();
                var data         = new List<decimal>();
                var lastYearData = new List<decimal>();
                var now          = DateTime.Now;

                Func<DateTime, DateTime, List<OrderRow>, decimal> sumRange =
                    (from, to, rows) => rows
                        .Where(r => r.Date >= from && r.Date <= to)
                        .Sum(r => r.TotalAmount);

                if (period == "daily")
                {
                    DateTime rangeStart = startDate.HasValue ? startDate.Value.Date : now.Date.AddDays(-13);
                    DateTime rangeEnd   = endDate.HasValue   ? endDate.Value.Date   : now.Date;
                    for (var day = rangeStart; day <= rangeEnd; day = day.AddDays(1))
                    {
                        labels.Add(day.ToString("MMM dd, yyyy"));
                        data.Add(sumRange(day, day.AddDays(1).AddSeconds(-1), currentRows));
                        lastYearData.Add(sumRange(day.AddYears(-1), day.AddYears(-1).AddDays(1).AddSeconds(-1), orderRows));
                    }
                }
                else if (period == "weekly")
                {
                    DateTime rangeEnd   = endDate.HasValue   ? endDate.Value.Date   : now.Date.AddDays((int)DayOfWeek.Sunday - (int)now.DayOfWeek);
                    DateTime rangeStart = startDate.HasValue ? startDate.Value.Date : rangeEnd.AddDays(-49);
                    var weekStart = rangeStart.AddDays(-((int)rangeStart.DayOfWeek + 6) % 7);
                    while (weekStart <= rangeEnd)
                    {
                        var weekEnd = weekStart.AddDays(6).AddHours(23).AddMinutes(59).AddSeconds(59);
                        int wn = System.Globalization.CultureInfo.InvariantCulture.Calendar
                            .GetWeekOfYear(weekStart, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday);
                        labels.Add(string.Format("W{0} {1}", wn, weekStart.Year));
                        data.Add(sumRange(weekStart, weekEnd, currentRows));
                        lastYearData.Add(sumRange(weekStart.AddYears(-1), weekEnd.AddYears(-1), orderRows));
                        weekStart = weekStart.AddDays(7);
                    }
                }
                else // monthly
                {
                    DateTime rangeStart = startDate.HasValue
                        ? new DateTime(startDate.Value.Year, startDate.Value.Month, 1)
                        : new DateTime(now.Year, 1, 1);
                    DateTime rangeEnd = endDate.HasValue
                        ? new DateTime(endDate.Value.Year, endDate.Value.Month, 1)
                        : new DateTime(now.Year, 12, 1);
                    bool multiYear = rangeStart.Year != rangeEnd.Year;
                    for (var m = rangeStart; m <= rangeEnd; m = m.AddMonths(1))
                    {
                        var mEnd = m.AddMonths(1).AddSeconds(-1);
                        labels.Add(multiYear
                            ? string.Format("{0} {1}",
                                System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(m.Month),
                                m.Year)
                            : System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(m.Month));
                        data.Add(sumRange(m, mEnd, currentRows));
                        lastYearData.Add(sumRange(m.AddYears(-1), mEnd.AddYears(-1), orderRows));
                    }
                }

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[GetSalesByCategory] {0} data points | current total: {1:N2} | last year total: {2:N2}",
                    labels.Count, data.Sum(), lastYearData.Sum()));

                context.Response.Write(serializer.Serialize(new
                {
                    labels       = labels,
                    data         = data,
                    lastYearData = lastYearData,
                    debug = new
                    {
                        totalPaidOrders    = paidOrders.Count,
                        parsedRows         = orderRows.Count,
                        skippedNoDate      = skipped,
                        skippedNoAmount    = noAmount,
                        filteredOrderCount = currentRows.Count,
                        requestedCategory  = category,
                        period             = period
                    }
                }));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[GetSalesByCategory] ERROR: {0}\n{1}", ex.Message, ex.StackTrace));
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
                if (val.BsonType == BsonType.DateTime)
                {
                    result = val.ToUniversalTime();
                    return true;
                }
                if (val.BsonType == BsonType.String)
                    return DateTime.TryParse(val.AsString, out result);
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
                if (val.BsonType == BsonType.String)
                {
                    decimal d;
                    if (decimal.TryParse(val.AsString, out d)) return d;
                }
            }
            catch { }
            return 0;
        }

        private class OrderRow
        {
            public OrderRow() { ProductIds = new List<string>(); }
            public DateTime     Date        { get; set; }
            public decimal      TotalAmount { get; set; }
            public List<string> ProductIds  { get; set; }
        }

        public bool IsReusable { get { return false; } }
    }
}