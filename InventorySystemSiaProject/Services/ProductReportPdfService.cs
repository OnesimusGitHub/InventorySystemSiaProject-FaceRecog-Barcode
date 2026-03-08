using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using InventorySystemSiaProject.Helpers;
using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;
using MongoDB.Bson;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Services
{
    /// <summary>
    /// Generates a PDF report (daily, weekly, monthly) for a single product.
    /// Sales data is sourced from db_shessentials.tbl_order — same source as
    /// the ProductProfile page charts.
    /// </summary>
    public class ProductReportPdfService
    {
        // ── shared row DTO ────────────────────────────────────────────────────
        private class OrderRow
        {
            public DateTime Date { get; set; }
            public decimal Amount { get; set; }
            public int Quantity { get; set; }
        }

        // ── read tbl_order and return rows that match any of the supplied IDs ─
        private static async Task<List<OrderRow>> LoadOrderRowsAsync(
            HashSet<string> variantIdSet)
        {
            var result = new List<OrderRow>();
            try
            {
                var col = DatabaseHelper.GetOrdersCollection();
                var filter = Builders<BsonDocument>.Filter.In(
                    "payment_status", new[] { "Paid", "paid", "PAID" });
                var orders = await col.Find(filter).ToListAsync().ConfigureAwait(false);

                foreach (var order in orders)
                {
                    DateTime orderDate;
                    BsonValue dv;
                    bool hasDate = false;
                    if (order.TryGetValue("created_at", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else if (order.TryGetValue("createdAt", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else if (order.TryGetValue("updated_at", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else if (order.TryGetValue("updatedAt", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else orderDate = DateTime.UtcNow;

                    decimal amount = 0;
                    BsonValue av;
                    if (order.TryGetValue("total_amount", out av)) amount = BsonToDecimal(av);
                    else if (order.TryGetValue("totalAmount", out av)) amount = BsonToDecimal(av);
                    else if (order.TryGetValue("total", out av)) amount = BsonToDecimal(av);

                    int quantity = 0;
                    BsonValue iv;
                    if (order.TryGetValue("items", out iv) && iv.IsBsonArray)
                    {
                        foreach (BsonValue item in iv.AsBsonArray)
                        {
                            if (!item.IsBsonDocument) continue;
                            var itemDoc = item.AsBsonDocument;
                            BsonValue pidVal;
                            string pid = null;
                            if (itemDoc.TryGetValue("product_id", out pidVal)) pid = pidVal.ToString();
                            else if (itemDoc.TryGetValue("variant_id", out pidVal)) pid = pidVal.ToString();
                            else if (itemDoc.TryGetValue("productId", out pidVal)) pid = pidVal.ToString();
                            if (string.IsNullOrWhiteSpace(pid) || !variantIdSet.Contains(pid)) continue;
                            BsonValue qv;
                            int itemQty = 1;
                            if (itemDoc.TryGetValue("quantity", out qv))
                                itemQty = Math.Max(1, (int)BsonToDecimal(qv));
                            quantity += itemQty;
                        }
                    }

                    if (quantity == 0) continue;
                    result.Add(new OrderRow
                    {
                        Date = (hasDate ? orderDate : DateTime.UtcNow).ToLocalTime(),
                        Amount = amount,
                        Quantity = quantity
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ProductReportPdfService] LoadOrderRowsAsync ERROR: " + ex.Message);
            }
            return result;
        }

        // ── public entry point ────────────────────────────────────────────────
        public async Task<byte[]> GenerateSingleProductReportPdfAsync(
            string productId, string productName,
            IEnumerable<string> variantIds = null)
        {
            if (string.IsNullOrWhiteSpace(productId)) return new byte[0];

            // Build variant id set (include productId itself as fallback)
            var idSet = new HashSet<string>();
            idSet.Add(productId);
            if (variantIds != null)
                foreach (var id in variantIds)
                    if (!string.IsNullOrWhiteSpace(id)) idSet.Add(id);

            // If no variant ids supplied, try to load them from the DB
            if (idSet.Count == 1)
            {
                try
                {
                    var varCol = DatabaseHelper.Database.GetCollection<BsonDocument>(
                        DatabaseHelper.GetProductVariantsCollectionName());
                    ObjectId oid;
                    FilterDefinition<BsonDocument> vf;
                    if (ObjectId.TryParse(productId, out oid))
                        vf = Builders<BsonDocument>.Filter.Or(
                            Builders<BsonDocument>.Filter.Eq("productId", oid),
                            Builders<BsonDocument>.Filter.Eq("ProductId", oid),
                            Builders<BsonDocument>.Filter.Eq("productId", productId),
                            Builders<BsonDocument>.Filter.Eq("ProductId", productId));
                    else
                        vf = Builders<BsonDocument>.Filter.Or(
                            Builders<BsonDocument>.Filter.Eq("productId", productId),
                            Builders<BsonDocument>.Filter.Eq("ProductId", productId));

                    var vDocs = await varCol.Find(vf)
                        .Project(Builders<BsonDocument>.Projection.Include("_id"))
                        .ToListAsync().ConfigureAwait(false);
                    foreach (var d in vDocs) idSet.Add(d["_id"].ToString());
                }
                catch { /* non-critical */ }
            }

            var rows = await LoadOrderRowsAsync(idSet).ConfigureAwait(false);
            var now = DateTime.UtcNow;
            var localNow = now.ToLocalTime().Date;

            var daily = AggregateDaily(rows, localNow);
            var weekly = AggregateWeekly(rows, localNow);
            var monthly = AggregateMonthly(rows, localNow);

            var doc = new Document();
            doc.Info.Title = "Product Sales Report";
            doc.Info.Subject = "Daily / Weekly / Monthly product sales";
            doc.Info.Author = "InventorySystem";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(1.5);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(1.5);
            section.PageSetup.RightMargin = Unit.FromCentimeter(1.5);

            var title = section.AddParagraph("Product Sales Report - " + productName);
            title.Format.Font.Size = 16;
            title.Format.Font.Bold = true;
            title.Format.SpaceAfter = Unit.FromPoint(6);

            var info = section.AddParagraph("Generated (UTC): " + now.ToString("yyyy-MM-dd HH:mm"));
            info.Format.Font.Size = 9;
            info.Format.SpaceAfter = Unit.FromPoint(4);

            var src = section.AddParagraph("Data source: db_shessentials.tbl_order (paid orders)");
            src.Format.Font.Size = 8;
            src.Format.Font.Italic = true;
            src.Format.SpaceAfter = Unit.FromPoint(10);

            AddBlock(section, "Daily (Last 7 Days)", daily);
            AddBlock(section, "Weekly (Last 8 Weeks)", weekly);
            AddBlock(section, "Monthly (Year-To-Date)", monthly);

            var renderer = new PdfDocumentRenderer(true);
            renderer.Document = doc;
            renderer.RenderDocument();
            using (var ms = new MemoryStream())
            {
                renderer.PdfDocument.Save(ms, false);
                return ms.ToArray();
            }
        }

        // ── aggregation helpers ───────────────────────────────────────────────
        private static List<ProductSalesAggregation> AggregateDaily(
            List<OrderRow> rows, DateTime localNow)
        {
            var result = new List<ProductSalesAggregation>();
            var start = localNow.AddDays(-6);
            for (var d = start; d <= localNow; d = d.AddDays(1))
            {
                var dayRows = rows.Where(r => r.Date.Date == d).ToList();
                result.Add(new ProductSalesAggregation
                {
                    ProductId = "",
                    PeriodStartUtc = d,
                    PeriodEndUtc = d.AddDays(1),
                    PeriodLabel = d.ToString("yyyy-MM-dd"),
                    TotalQuantity = dayRows.Sum(r => r.Quantity),
                    GrossAmount = dayRows.Sum(r => r.Amount),
                    NetAmount = dayRows.Sum(r => r.Amount)
                });
            }
            return result;
        }

        private static List<ProductSalesAggregation> AggregateWeekly(
            List<OrderRow> rows, DateTime localNow)
        {
            var result = new List<ProductSalesAggregation>();
            var weekStart = localNow.AddDays(-(int)localNow.DayOfWeek).AddDays(-49); // 8 weeks back
            for (int i = 0; i < 8; i++)
            {
                var ws = weekStart.AddDays(7 * i);
                var we = ws.AddDays(6);
                var wRows = rows.Where(r => r.Date.Date >= ws && r.Date.Date <= we).ToList();
                result.Add(new ProductSalesAggregation
                {
                    ProductId = "",
                    PeriodStartUtc = ws,
                    PeriodEndUtc = we.AddDays(1),
                    PeriodLabel = "W" + ws.ToString("MMdd") + "-" + we.ToString("MMdd"),
                    TotalQuantity = wRows.Sum(r => r.Quantity),
                    GrossAmount = wRows.Sum(r => r.Amount),
                    NetAmount = wRows.Sum(r => r.Amount)
                });
            }
            return result;
        }

        private static List<ProductSalesAggregation> AggregateMonthly(
            List<OrderRow> rows, DateTime localNow)
        {
            var result = new List<ProductSalesAggregation>();
            var yearStart = new DateTime(localNow.Year, 1, 1);
            for (var m = yearStart; m <= localNow; m = m.AddMonths(1))
            {
                var mEnd = m.AddMonths(1).AddDays(-1);
                var mRows = rows.Where(r => r.Date.Date >= m && r.Date.Date <= mEnd).ToList();
                result.Add(new ProductSalesAggregation
                {
                    ProductId = "",
                    PeriodStartUtc = m,
                    PeriodEndUtc = mEnd.AddDays(1),
                    PeriodLabel = m.ToString("yyyy-MM"),
                    TotalQuantity = mRows.Sum(r => r.Quantity),
                    GrossAmount = mRows.Sum(r => r.Amount),
                    NetAmount = mRows.Sum(r => r.Amount)
                });
            }
            return result;
        }

        // ── PDF helpers ───────────────────────────────────────────────────────
        private void DefineStyles(Document doc)
        {
            var normal = doc.Styles["Normal"];
            normal.Font.Name = "Arial";
            normal.Font.Size = 9;
            var header = doc.Styles.AddStyle("TableHeader", "Normal");
            header.Font.Bold = true;
            header.Font.Size = 9;
            var footer = doc.Styles.AddStyle("TableFooter", "Normal");
            footer.Font.Bold = true;
            footer.Font.Size = 9;
        }

        private void AddBlock(Section section, string heading,
            List<ProductSalesAggregation> rows)
        {
            var h = section.AddParagraph(heading);
            h.Format.SpaceBefore = Unit.FromPoint(10);
            h.Format.SpaceAfter = Unit.FromPoint(3);
            h.Format.Font.Bold = true;
            h.Format.Font.Size = 11;

            if (rows == null || rows.Count == 0)
            {
                section.AddParagraph("(no data)").Format.Font.Italic = true;
                return;
            }

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Rows.LeftIndent = 0;
            table.AddColumn(Unit.FromCentimeter(3.0));
            table.AddColumn(Unit.FromCentimeter(2.0));
            table.AddColumn(Unit.FromCentimeter(3.0));
            table.AddColumn(Unit.FromCentimeter(3.0));

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "Period", "TableHeader");
            SetCell(headerRow, 1, "Qty", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 2, "Gross", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 3, "Net", "TableHeader", ParagraphAlignment.Right);

            foreach (var r in rows.OrderBy(r => r.PeriodStartUtc))
            {
                var row = table.AddRow();
                SetCell(row, 0, r.PeriodLabel);
                SetCell(row, 1, r.TotalQuantity.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 2, r.GrossAmount.ToString("C"), alignment: ParagraphAlignment.Right);
                SetCell(row, 3, r.NetAmount.ToString("C"), alignment: ParagraphAlignment.Right);
            }

            var totalQty = rows.Sum(r => r.TotalQuantity);
            var totalGross = rows.Sum(r => r.GrossAmount);
            var totalNet = rows.Sum(r => r.NetAmount);
            var totalRow = table.AddRow();
            totalRow.Shading.Color = Colors.AliceBlue;
            SetCell(totalRow, 0, "TOTAL", "TableFooter");
            SetCell(totalRow, 1, totalQty.ToString(), "TableFooter", ParagraphAlignment.Right);
            SetCell(totalRow, 2, totalGross.ToString("C"), "TableFooter", ParagraphAlignment.Right);
            SetCell(totalRow, 3, totalNet.ToString("C"), "TableFooter", ParagraphAlignment.Right);
        }

        private void SetCell(Row row, int idx, string text,
            string style = null, ParagraphAlignment alignment = ParagraphAlignment.Left)
        {
            var p = row.Cells[idx].AddParagraph(text ?? string.Empty);
            p.Format.Alignment = alignment;
            if (!string.IsNullOrEmpty(style)) p.Style = style;
        }

        // ── Bson helpers ──────────────────────────────────────────────────────
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
                if (val.BsonType == BsonType.String)
                {
                    decimal d;
                    if (decimal.TryParse(val.AsString, out d)) return d;
                }
            }
            catch { }
            return 0;
        }
    }
}