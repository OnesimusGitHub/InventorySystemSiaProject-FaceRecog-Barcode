using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;
using MongoDB.Bson;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Generates PDF report for a specific product showing all its variants' performance.
    /// Sales data is read from db_shessentials.tbl_order (same source as the
    /// ProductProfile page charts).
    /// </summary>
    public class GenerateProductProfilePerformancePDF : HttpTaskAsyncHandler
    {
        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                string productId = context.Request.QueryString["productId"];
                if (string.IsNullOrEmpty(productId))
                    throw new ArgumentException("Product ID is required");

                string reportType = context.Request.QueryString["type"] ?? "standard";
                byte[] pdfBytes;

                if (reportType == "standard")
                    pdfBytes = await GenerateStandardReportAsync(productId);
                else if (reportType == "custom")
                {
                    string startDateStr = context.Request.QueryString["startDate"];
                    string endDateStr = context.Request.QueryString["endDate"];
                    if (string.IsNullOrEmpty(startDateStr) || string.IsNullOrEmpty(endDateStr))
                        throw new ArgumentException("Start date and end date are required for custom reports");
                    pdfBytes = await GenerateCustomReportAsync(productId,
                        DateTime.Parse(startDateStr), DateTime.Parse(endDateStr));
                }
                else
                    throw new ArgumentException("Invalid report type");

                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                string fileName = "Product_Performance_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".pdf";
                context.Response.AddHeader("Content-Disposition", "attachment; filename=" + fileName);
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error generating PDF: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("[GenerateProductProfilePerformancePDF] " + ex.Message);
            }
        }

        // ── tbl_order reader ──────────────────────────────────────────────────
        private class OrderRow
        {
            public DateTime Date { get; set; }
            public decimal Amount { get; set; }
            public int Quantity { get; set; }
            public string VariantId { get; set; }
        }

        private static async Task<List<OrderRow>> LoadOrderRowsAsync(HashSet<string> variantIdSet)
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

                    BsonValue iv;
                    if (!order.TryGetValue("items", out iv) || !iv.IsBsonArray) continue;

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
                        int qty = 1;
                        if (itemDoc.TryGetValue("quantity", out qv))
                            qty = Math.Max(1, (int)BsonToDecimal(qv));

                        result.Add(new OrderRow
                        {
                            Date = (hasDate ? orderDate : DateTime.UtcNow).ToLocalTime(),
                            Amount = amount,
                            Quantity = qty,
                            VariantId = pid
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[GenerateProductProfilePerformancePDF] LoadOrderRowsAsync ERROR: " + ex.Message);
            }
            return result;
        }

        private async Task<byte[]> GenerateStandardReportAsync(string productId)
        {
            var pdfService = new ProductReportPdfService();
            var productService = new ProductService();
            var product = await productService.GetProductByIdAsync(productId);
            if (product == null) throw new Exception("Product not found");

            var variants = await productService.GetProductVariantsByProductIdAsync(productId);
            var variantIds = variants.Select(v => v.Id).ToList();

            return await pdfService.GenerateSingleProductReportPdfAsync(
                productId, product.productName, variantIds);
        }

        private async Task<byte[]> GenerateCustomReportAsync(
            string productId, DateTime startDate, DateTime endDate)
        {
            var productService = new ProductService();
            var product = await productService.GetProductByIdAsync(productId);
            if (product == null) throw new Exception("Product not found");

            var variants = await productService.GetProductVariantsByProductIdAsync(productId);

            var variantIdSet = new HashSet<string>(variants.Select(v => v.Id));
            variantIdSet.Add(productId);
            var allRows = await LoadOrderRowsAsync(variantIdSet);
            var rowsInRange = allRows
                .Where(r => r.Date.Date >= startDate.Date && r.Date.Date <= endDate.Date)
                .ToList();

            var doc = new Document();
            doc.Info.Title = product.productName + " - Performance Report";
            doc.Info.Subject = "Custom date range: " + startDate.ToString("MMM dd, yyyy") + " - " + endDate.ToString("MMM dd, yyyy");
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            var title = section.AddParagraph(product.productName);
            title.Format.Font.Size = 18;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Color.FromRgb(156, 39, 176);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceAfter = Unit.FromPoint(10);

            var subtitle = section.AddParagraph("Performance Report: " +
                startDate.ToString("MMM dd, yyyy") + " - " + endDate.ToString("MMM dd, yyyy"));
            subtitle.Format.Font.Size = 12;
            subtitle.Format.Font.Italic = true;
            subtitle.Format.Alignment = ParagraphAlignment.Center;
            subtitle.Format.SpaceAfter = Unit.FromPoint(5);

            var srcNote = section.AddParagraph("Data source: db_shessentials.tbl_order");
            srcNote.Format.Font.Size = 8;
            srcNote.Format.Font.Italic = true;
            srcNote.Format.Alignment = ParagraphAlignment.Center;
            srcNote.Format.SpaceAfter = Unit.FromPoint(5);

            var genDate = section.AddParagraph("Generated: " + DateTime.Now.ToString("MMM dd, yyyy HH:mm"));
            genDate.Format.Font.Size = 9;
            genDate.Format.Alignment = ParagraphAlignment.Center;
            genDate.Format.SpaceAfter = Unit.FromPoint(20);

            // Summary table
            var summaryHeading = section.AddParagraph("Summary");
            summaryHeading.Style = "Heading1";
            summaryHeading.Format.SpaceAfter = Unit.FromPoint(10);

            var tbl = section.AddTable();
            tbl.Borders.Width = 0.5;
            tbl.AddColumn(Unit.FromCentimeter(10));
            tbl.AddColumn(Unit.FromCentimeter(6));
            AddSummaryRow(tbl, "Product:", product.productName);
            AddSummaryRow(tbl, "Category:", product.productCategory ?? "N/A");
            AddSummaryRow(tbl, "Total Variants:", variants.Count.ToString());
            AddSummaryRow(tbl, "Active Variants:", variants.Count(v => v.IsActive).ToString());
            AddSummaryRow(tbl, "Date Range:", startDate.ToString("MMM dd, yyyy") + " - " + endDate.ToString("MMM dd, yyyy"));

            // Variant performance table
            section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(15);
            var varHeading = section.AddParagraph("Variant Performance");
            varHeading.Style = "Heading1";
            varHeading.Format.SpaceAfter = Unit.FromPoint(10);

            var varTable = section.AddTable();
            varTable.Borders.Width = 0.5;
            varTable.AddColumn(Unit.FromCentimeter(5));
            varTable.AddColumn(Unit.FromCentimeter(3));
            varTable.AddColumn(Unit.FromCentimeter(2.5));
            varTable.AddColumn(Unit.FromCentimeter(2.5));
            varTable.AddColumn(Unit.FromCentimeter(2));
            varTable.AddColumn(Unit.FromCentimeter(2));

            var headerRow = varTable.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "Variant", "TableHeader");
            SetCell(headerRow, 1, "Total Sales", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 2, "Quantity", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 3, "Orders", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 4, "Stock", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 5, "Status", "TableHeader");

            decimal grandTotalSales = 0;
            int grandTotalQty = 0;
            int grandTotalOrders = 0;

            foreach (var variant in variants.OrderByDescending(v =>
                rowsInRange.Where(r => r.VariantId == v.Id).Sum(r => r.Amount)))
            {
                var vRows = rowsInRange.Where(r => r.VariantId == variant.Id).ToList();
                decimal totalSales = vRows.Sum(r => r.Amount);
                int totalQty = vRows.Sum(r => r.Quantity);
                int orderCount = vRows.Count;

                var row = varTable.AddRow();
                SetCell(row, 0, variant.VariantName);
                SetCell(row, 1, string.Format("${0:N2}", totalSales), alignment: ParagraphAlignment.Right);
                SetCell(row, 2, totalQty.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 3, orderCount.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 4, variant.StockQuantity.ToString(), alignment: ParagraphAlignment.Right);

                var status = variant.IsLowStock ? "LOW" : "Normal";
                var statusCell = row.Cells[5].AddParagraph(status);
                if (variant.IsLowStock) { statusCell.Format.Font.Color = Colors.Red; statusCell.Format.Font.Bold = true; }

                grandTotalSales += totalSales;
                grandTotalQty += totalQty;
                grandTotalOrders += orderCount;
            }

            var totalRow = varTable.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(totalRow, 0, "TOTAL", "TableHeader");
            SetCell(totalRow, 1, string.Format("${0:N2}", grandTotalSales), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 2, grandTotalQty.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 3, grandTotalOrders.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 4, "-", "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 5, "-", "TableHeader");

            return RenderDocument(doc);
        }

        private void AddSummaryRow(Table table, string label, string value)
        {
            var row = table.AddRow();
            row.Cells[0].AddParagraph(label).Format.Font.Bold = true;
            row.Cells[1].AddParagraph(value);
            row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
        }

        private void SetCell(Row row, int idx, string text,
            string style = null, ParagraphAlignment alignment = ParagraphAlignment.Left)
        {
            var p = row.Cells[idx].AddParagraph(text ?? string.Empty);
            p.Format.Alignment = alignment;
            if (!string.IsNullOrEmpty(style)) p.Style = style;
        }

        private void DefineStyles(Document doc)
        {
            var normal = doc.Styles["Normal"];
            normal.Font.Name = "Arial";
            normal.Font.Size = 9;
            var h1 = doc.Styles.AddStyle("Heading1", "Normal");
            h1.Font.Bold = true;
            h1.Font.Size = 14;
            h1.Font.Color = Color.FromRgb(156, 39, 176);
            var th = doc.Styles.AddStyle("TableHeader", "Normal");
            th.Font.Bold = true;
            th.Font.Size = 9;
        }

        private byte[] RenderDocument(Document doc)
        {
            var renderer = new PdfDocumentRenderer(true);
            renderer.Document = doc;
            renderer.RenderDocument();
            using (var ms = new MemoryStream())
            {
                renderer.PdfDocument.Save(ms, false);
                return ms.ToArray();
            }
        }

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