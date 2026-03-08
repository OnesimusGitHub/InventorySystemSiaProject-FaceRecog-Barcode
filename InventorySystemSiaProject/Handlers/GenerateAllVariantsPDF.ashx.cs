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
    /// Generates comprehensive PDF report showing all variants for a product.
    /// Sales data is read from db_shessentials.tbl_order (same source as the
    /// ProductProfile page charts).
    /// </summary>
    public class GenerateAllVariantsPDF : HttpTaskAsyncHandler
    {
        private ProductService _productService;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                _productService = new ProductService();

                string productId = context.Request.QueryString["productId"];
                if (string.IsNullOrEmpty(productId))
                    throw new ArgumentException("Product ID is required");

                byte[] pdfBytes = await GenerateAllVariantsReportAsync(productId);

                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                string fileName = "All_Variants_Report_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".pdf";
                context.Response.AddHeader("Content-Disposition", "attachment; filename=" + fileName);
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error generating PDF: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("[GenerateAllVariantsPDF] " + ex.Message);
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
                System.Diagnostics.Debug.WriteLine("[GenerateAllVariantsPDF] LoadOrderRowsAsync ERROR: " + ex.Message);
            }
            return result;
        }

        private async Task<byte[]> GenerateAllVariantsReportAsync(string productId)
        {
            // ── Fetch product WITHOUT the binary productImg field ──────────────────
            var productsCol = DatabaseHelper.GetProductsCollection();
            var projection = Builders<Product>.Projection
                .Exclude(p => p.productImg)
                .Exclude(p => p.ProductImgContentType);

            var product = await productsCol
                .Find(Builders<Product>.Filter.Eq(p => p.Id, productId))
                .Project<Product>(projection)
                .FirstOrDefaultAsync()
                .ConfigureAwait(false);

            if (product == null) throw new Exception("Product not found");

            var variants = await _productService.GetProductVariantsByProductIdAsync(productId);

            // Build variant id set
            var variantIdSet = new HashSet<string>(variants.Select(v => v.Id));
            variantIdSet.Add(productId);

            // Load all matching order rows once
            var allRows = await LoadOrderRowsAsync(variantIdSet);

            var doc = new Document();
            doc.Info.Title = product.productName + " - All Variants Report";
            doc.Info.Subject = "Comprehensive variant information and performance";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);
            section.PageSetup.BottomMargin = Unit.FromCentimeter(2);

            AddTitlePage(section, product, variants);
            section.AddPageBreak();
            AddProductOverview(section, product, variants);
            section.AddPageBreak();
            AddVariantsDetailTable(section, variants);

            if (variants.Any())
            {
                section.AddPageBreak();
                AddSalesPerformanceSection(section, variants, allRows);
            }

            section.AddPageBreak();
            AddStockAnalysisSection(section, variants);

            return RenderDocument(doc);
        }

        private void AddTitlePage(Section section, Product product, List<ProductVariant> variants)
        {
            var title = section.AddParagraph("All Variants Report");
            title.Format.Font.Size = 24;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Color.FromRgb(33, 150, 243);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromCentimeter(4);
            title.Format.SpaceAfter = Unit.FromPoint(20);

            var productName = section.AddParagraph(product.productName);
            productName.Format.Font.Size = 18;
            productName.Format.Font.Bold = true;
            productName.Format.Alignment = ParagraphAlignment.Center;
            productName.Format.SpaceAfter = Unit.FromPoint(10);

            var subtitle = section.AddParagraph("Comprehensive Variant Analysis");
            subtitle.Format.Font.Size = 14;
            subtitle.Format.Font.Italic = true;
            subtitle.Format.Alignment = ParagraphAlignment.Center;
            subtitle.Format.SpaceAfter = Unit.FromCentimeter(3);

            var statsTable = section.AddTable();
            statsTable.Borders.Width = 0;
            statsTable.AddColumn(Unit.FromCentimeter(16));
            AddCenteredRow(statsTable, "Product Category: " + (product.productCategory ?? "N/A"), 12);
            AddCenteredRow(statsTable, "Total Variants: " + variants.Count, 12);
            AddCenteredRow(statsTable, "Active Variants: " + variants.Count(v => v.IsActive), 12);
            AddCenteredRow(statsTable, "Total Stock Units: " + variants.Sum(v => v.StockQuantity), 12);

            section.AddParagraph().Format.SpaceAfter = Unit.FromCentimeter(5);

            var src = section.AddParagraph("Sales data");
            src.Format.Font.Size = 8;
            src.Format.Font.Italic = true;
            src.Format.Alignment = ParagraphAlignment.Center;
            src.Format.Font.Color = Colors.Gray;

            var genDate = section.AddParagraph("Generated on: " + DateTime.Now.ToString("MMMM dd, yyyy 'at' HH:mm"));
            genDate.Format.Font.Size = 10;
            genDate.Format.Alignment = ParagraphAlignment.Center;
            genDate.Format.Font.Color = Colors.Gray;
        }

        private void AddCenteredRow(Table table, string text, int fontSize)
        {
            var row = table.AddRow();
            row.Height = Unit.FromPoint(25);
            row.Cells[0].AddParagraph(text).Format.Font.Size = fontSize;
            row.Cells[0].Format.Alignment = ParagraphAlignment.Center;
        }

        private void AddProductOverview(Section section, Product product, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Product Overview");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(8));
            table.AddColumn(Unit.FromCentimeter(8));

            AddSummaryRow(table, "Product Name:", product.productName);
            AddSummaryRow(table, "Category:", product.productCategory ?? "N/A");
            AddSummaryRow(table, "Product ID:", product.Id);
            AddSummaryRow(table, "Base Price:", string.Format("${0:N2}", product.productVal));
            AddSummaryRow(table, "Total Variants:", variants.Count.ToString());
            AddSummaryRow(table, "Active Variants:", variants.Count(v => v.IsActive).ToString());
            AddSummaryRow(table, "Inactive Variants:", variants.Count(v => !v.IsActive).ToString());
            AddSummaryRow(table, "Total Stock Value:", string.Format("${0:N2}", variants.Sum(v => v.TotalValue)));
            AddSummaryRow(table, "Low Stock Variants:", variants.Count(v => v.IsLowStock).ToString());

            if (!string.IsNullOrEmpty(product.productDesc))
            {
                section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(15);
                var dh = section.AddParagraph("Description");
                dh.Format.Font.Bold = true;
                dh.Format.SpaceAfter = Unit.FromPoint(5);
                var desc = section.AddParagraph(product.productDesc);
                desc.Format.Font.Size = 9;
            }
        }

        private void AddVariantsDetailTable(Section section, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Variant Details");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            if (!variants.Any())
            {
                var noVariants = section.AddParagraph("No variants found for this product.");
                noVariants.Format.Font.Italic = true;
                noVariants.Format.Font.Color = Colors.Gray;
                return;
            }

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(4));
            table.AddColumn(Unit.FromCentimeter(2.5));
            table.AddColumn(Unit.FromCentimeter(2.5));
            table.AddColumn(Unit.FromCentimeter(2.5));
            table.AddColumn(Unit.FromCentimeter(2));
            table.AddColumn(Unit.FromCentimeter(2));
            table.AddColumn(Unit.FromCentimeter(2));

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "Variant Name", "TableHeader");
            SetCell(headerRow, 1, "Size", "TableHeader");
            SetCell(headerRow, 2, "Color", "TableHeader");
            SetCell(headerRow, 3, "Price", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 4, "Stock", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 5, "Min Stock", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 6, "Status", "TableHeader");

            decimal totalValue = 0;
            int totalStock = 0;

            foreach (var variant in variants.OrderBy(v => v.VariantName))
            {
                var row = table.AddRow();
                SetCell(row, 0, variant.VariantName ?? "N/A");
                SetCell(row, 1, variant.Size ?? "-");
                SetCell(row, 2, variant.Color ?? "-");
                SetCell(row, 3, string.Format("${0:N2}", variant.Price), alignment: ParagraphAlignment.Right);

                var stockCell = row.Cells[4].AddParagraph(variant.StockQuantity.ToString());
                stockCell.Format.Alignment = ParagraphAlignment.Right;
                if (variant.IsLowStock) { stockCell.Format.Font.Color = Colors.Red; stockCell.Format.Font.Bold = true; }

                SetCell(row, 5, variant.MinimumStock.ToString(), alignment: ParagraphAlignment.Right);

                var status = !variant.IsActive ? "Inactive" : (variant.IsLowStock ? "Low Stock" : "Active");
                var statusCell = row.Cells[6].AddParagraph(status);
                if (!variant.IsActive) { statusCell.Format.Font.Color = Colors.Gray; statusCell.Format.Font.Italic = true; }
                else if (variant.IsLowStock) { statusCell.Format.Font.Color = Colors.Red; statusCell.Format.Font.Bold = true; }
                else statusCell.Format.Font.Color = Colors.Green;

                totalValue += variant.TotalValue;
                totalStock += variant.StockQuantity;
            }

            var summaryRow = table.AddRow();
            summaryRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(summaryRow, 0, "TOTAL", "TableHeader");
            SetCell(summaryRow, 1, "-", "TableHeader");
            SetCell(summaryRow, 2, "-", "TableHeader");
            SetCell(summaryRow, 3, string.Format("${0:N2}", totalValue), "TableHeader", ParagraphAlignment.Right);
            SetCell(summaryRow, 4, totalStock.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(summaryRow, 5, "-", "TableHeader");
            SetCell(summaryRow, 6, variants.Count.ToString(), "TableHeader");
        }

        private void AddSalesPerformanceSection(Section section,
            List<ProductVariant> variants, List<OrderRow> allRows)
        {
            var heading = section.AddParagraph("Sales Performance (Last 30 Days)");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var thirtyDaysAgo = DateTime.Now.AddDays(-30).Date;

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(5));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(2.5));
            table.AddColumn(Unit.FromCentimeter(3));

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "Variant Name", "TableHeader");
            SetCell(headerRow, 1, "Units Sold", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 2, "Revenue", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 3, "Orders", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 4, "Avg Order", "TableHeader", ParagraphAlignment.Right);

            decimal totalRevenue = 0;
            int totalUnitsSold = 0;
            int totalOrders = 0;

            foreach (var variant in variants.OrderBy(v => v.VariantName))
            {
                var vRows = allRows
                    .Where(r => r.VariantId == variant.Id && r.Date.Date >= thirtyDaysAgo)
                    .ToList();

                int unitsSold = vRows.Sum(r => r.Quantity);
                decimal revenue = vRows.Sum(r => r.Amount);
                int orderCount = vRows.Count;
                decimal avgOrder = orderCount > 0 ? revenue / orderCount : 0;

                var row = table.AddRow();
                SetCell(row, 0, variant.VariantName ?? "N/A");
                SetCell(row, 1, unitsSold.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 2, string.Format("${0:N2}", revenue), alignment: ParagraphAlignment.Right);
                SetCell(row, 3, orderCount.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 4, string.Format("${0:N2}", avgOrder), alignment: ParagraphAlignment.Right);

                totalRevenue += revenue;
                totalUnitsSold += unitsSold;
                totalOrders += orderCount;
            }

            var totalRow = table.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(totalRow, 0, "TOTAL", "TableHeader");
            SetCell(totalRow, 1, totalUnitsSold.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 2, string.Format("${0:N2}", totalRevenue), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 3, totalOrders.ToString(), "TableHeader", ParagraphAlignment.Right);
            decimal totalAvg = totalOrders > 0 ? totalRevenue / totalOrders : 0;
            SetCell(totalRow, 4, string.Format("${0:N2}", totalAvg), "TableHeader", ParagraphAlignment.Right);
        }

        private void AddStockAnalysisSection(Section section, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Stock Analysis");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            int lowStockCount = variants.Count(v => v.IsLowStock);
            int normalStockCount = variants.Count(v => !v.IsLowStock && v.IsActive);
            int inactiveCount = variants.Count(v => !v.IsActive);

            var summaryTable = section.AddTable();
            summaryTable.Borders.Width = 0.5;
            summaryTable.Borders.Color = Colors.LightGray;
            summaryTable.AddColumn(Unit.FromCentimeter(8));
            summaryTable.AddColumn(Unit.FromCentimeter(8));

            AddSummaryRow(summaryTable, "Total Variants:", variants.Count.ToString());
            AddSummaryRow(summaryTable, "Normal Stock:", normalStockCount.ToString());

            var lowRow = summaryTable.AddRow();
            lowRow.Cells[0].AddParagraph("Low Stock:").Format.Font.Bold = true;
            var lowCell = lowRow.Cells[1].AddParagraph(lowStockCount.ToString());
            lowCell.Format.Alignment = ParagraphAlignment.Right;
            if (lowStockCount > 0) { lowCell.Format.Font.Color = Colors.Red; lowCell.Format.Font.Bold = true; }

            AddSummaryRow(summaryTable, "Inactive:", inactiveCount.ToString());
            AddSummaryRow(summaryTable, "Total Stock Value:", string.Format("${0:N2}", variants.Sum(v => v.TotalValue)));
            AddSummaryRow(summaryTable, "Average Stock per Variant:", string.Format("{0:N1} units", variants.Average(v => v.StockQuantity)));

            if (lowStockCount > 0)
            {
                section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(20);
                var wh = section.AddParagraph("Low Stock Alert");
                wh.Format.Font.Bold = true;
                wh.Format.Font.Size = 12;
                wh.Format.Font.Color = Colors.Red;
                wh.Format.SpaceAfter = Unit.FromPoint(10);

                var lst = section.AddTable();
                lst.Borders.Width = 0.5;
                lst.Borders.Color = Colors.LightGray;
                lst.AddColumn(Unit.FromCentimeter(6));
                lst.AddColumn(Unit.FromCentimeter(3));
                lst.AddColumn(Unit.FromCentimeter(3));
                lst.AddColumn(Unit.FromCentimeter(4));

                var lh = lst.AddRow();
                lh.Shading.Color = Colors.LightGray;
                SetCell(lh, 0, "Variant", "TableHeader");
                SetCell(lh, 1, "Current Stock", "TableHeader", ParagraphAlignment.Right);
                SetCell(lh, 2, "Min Stock", "TableHeader", ParagraphAlignment.Right);
                SetCell(lh, 3, "Reorder Needed", "TableHeader", ParagraphAlignment.Right);

                foreach (var variant in variants.Where(v => v.IsLowStock).OrderBy(v => v.StockQuantity))
                {
                    var row = lst.AddRow();
                    SetCell(row, 0, variant.VariantName ?? "N/A");
                    var sc = row.Cells[1].AddParagraph(variant.StockQuantity.ToString());
                    sc.Format.Alignment = ParagraphAlignment.Right;
                    sc.Format.Font.Color = Colors.Red;
                    sc.Format.Font.Bold = true;
                    SetCell(row, 2, variant.MinimumStock.ToString(), alignment: ParagraphAlignment.Right);
                    int reorder = Math.Max(0, variant.MinimumStock * 2 - variant.StockQuantity);
                    SetCell(row, 3, reorder + " units", alignment: ParagraphAlignment.Right);
                }
            }
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
            h1.Font.Color = Color.FromRgb(33, 150, 243);
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