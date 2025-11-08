using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Services;
using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Generates PDF report for a specific product showing all its variants' performance
    /// </summary>
    public class GenerateProductProfilePerformancePDF : HttpTaskAsyncHandler
    {
        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                string productId = context.Request.QueryString["productId"];
                if (string.IsNullOrEmpty(productId))
                {
                    throw new ArgumentException("Product ID is required");
                }

                string reportType = context.Request.QueryString["type"] ?? "standard";
                byte[] pdfBytes;

                if (reportType == "standard")
                {
                    pdfBytes = await GenerateStandardReportAsync(productId);
                }
                else if (reportType == "custom")
                {
                    string startDateStr = context.Request.QueryString["startDate"];
                    string endDateStr = context.Request.QueryString["endDate"];
                    
                    if (string.IsNullOrEmpty(startDateStr) || string.IsNullOrEmpty(endDateStr))
                    {
                        throw new ArgumentException("Start date and end date are required for custom reports");
                    }

                    DateTime startDate = DateTime.Parse(startDateStr);
                    DateTime endDate = DateTime.Parse(endDateStr);
                    pdfBytes = await GenerateCustomReportAsync(productId, startDate, endDate);
                }
                else
                {
                    throw new ArgumentException("Invalid report type");
                }

                // Send PDF to browser
                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                string fileName = $"Product_Performance_{DateTime.Now:yyyyMMdd_HHmmss}.pdf";
                context.Response.AddHeader("Content-Disposition", $"attachment; filename={fileName}");
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error generating PDF: " + ex.Message);
                System.Diagnostics.Debug.WriteLine($"Error: {ex.Message}\n{ex.StackTrace}");
            }
        }

        private async Task<byte[]> GenerateStandardReportAsync(string productId)
        {
            var productReportService = new ProductReportPdfService();
            
            // Get product details
            var productService = new ProductService();
            var product = await productService.GetProductByIdAsync(productId);
            
            if (product == null)
            {
                throw new Exception("Product not found");
            }

            return await productReportService.GenerateSingleProductReportPdfAsync(productId, product.ProductName);
        }

        private async Task<byte[]> GenerateCustomReportAsync(string productId, DateTime startDate, DateTime endDate)
        {
            var productService = new ProductService();
            var salesService = new SalesService();
            
            var product = await productService.GetProductByIdAsync(productId);
            if (product == null)
            {
                throw new Exception("Product not found");
            }

            var variants = await productService.GetProductVariantsByProductIdAsync(productId);
            
            var doc = new Document();
            doc.Info.Title = $"{product.ProductName} - Performance Report";
            doc.Info.Subject = $"Custom date range: {startDate:MMM dd, yyyy} - {endDate:MMM dd, yyyy}";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            // Title
            var title = section.AddParagraph(product.ProductName);
            title.Format.Font.Size = 18;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Color.FromRgb(156, 39, 176);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceAfter = Unit.FromPoint(10);

            var subtitle = section.AddParagraph($"Performance Report: {startDate:MMM dd, yyyy} - {endDate:MMM dd, yyyy}");
            subtitle.Format.Font.Size = 12;
            subtitle.Format.Font.Italic = true;
            subtitle.Format.Alignment = ParagraphAlignment.Center;
            subtitle.Format.SpaceAfter = Unit.FromPoint(5);

            var genDate = section.AddParagraph($"Generated: {DateTime.Now:MMM dd, yyyy HH:mm}");
            genDate.Format.Font.Size = 9;
            genDate.Format.Alignment = ParagraphAlignment.Center;
            genDate.Format.SpaceAfter = Unit.FromPoint(20);

            // Summary
            var summaryHeading = section.AddParagraph("Summary");
            summaryHeading.Style = "Heading1";
            summaryHeading.Format.SpaceAfter = Unit.FromPoint(10);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.AddColumn(Unit.FromCentimeter(10));
            table.AddColumn(Unit.FromCentimeter(6));

            AddSummaryRow(table, "Product:", product.ProductName);
            AddSummaryRow(table, "Category:", product.ProductCategory ?? "N/A");
            AddSummaryRow(table, "Total Variants:", variants.Count.ToString());
            AddSummaryRow(table, "Active Variants:", variants.Count(v => v.IsActive).ToString());
            AddSummaryRow(table, "Date Range:", $"{startDate:MMM dd, yyyy} - {endDate:MMM dd, yyyy}");

            // Get sales data for each variant
            var variantPerformance = new System.Collections.Generic.List<dynamic>();
            foreach (var variant in variants)
            {
                var sales = await salesService.GetSalesByVariantAsync(variant.Id);
                var salesInRange = sales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate).ToList();
                
                variantPerformance.Add(new
                {
                    VariantName = variant.VariantName,
                    TotalSales = salesInRange.Sum(s => s.TotalAmount),
                    TotalQuantity = salesInRange.Sum(s => s.Quantity),
                    OrderCount = salesInRange.Count,
                    Stock = variant.StockQuantity,
                    IsLowStock = variant.IsLowStock
                });
            }

            // Variant Performance Table
            section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(15);
            var varHeading = section.AddParagraph("Variant Performance");
            varHeading.Style = "Heading1";
            varHeading.Format.SpaceAfter = Unit.FromPoint(10);

            var varTable = section.AddTable();
            varTable.Borders.Width = 0.5;
            varTable.AddColumn(Unit.FromCentimeter(5));   // Variant Name
            varTable.AddColumn(Unit.FromCentimeter(3));   // Total Sales
            varTable.AddColumn(Unit.FromCentimeter(2.5)); // Quantity
            varTable.AddColumn(Unit.FromCentimeter(2.5)); // Orders
            varTable.AddColumn(Unit.FromCentimeter(2));   // Stock
            varTable.AddColumn(Unit.FromCentimeter(2));   // Status

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

            foreach (var vp in variantPerformance.OrderByDescending(v => v.TotalSales))
            {
                var row = varTable.AddRow();
                SetCell(row, 0, vp.VariantName);
                SetCell(row, 1, $"${vp.TotalSales:N2}", alignment: ParagraphAlignment.Right);
                SetCell(row, 2, vp.TotalQuantity.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 3, vp.OrderCount.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 4, vp.Stock.ToString(), alignment: ParagraphAlignment.Right);
                
                var status = vp.IsLowStock ? "?? LOW" : "Normal";
                var statusCell = row.Cells[5].AddParagraph(status);
                if (vp.IsLowStock)
                {
                    statusCell.Format.Font.Color = Colors.Red;
                    statusCell.Format.Font.Bold = true;
                }

                grandTotalSales += vp.TotalSales;
                grandTotalQty += vp.TotalQuantity;
                grandTotalOrders += vp.OrderCount;
            }

            // Total row
            var totalRow = varTable.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(totalRow, 0, "TOTAL", "TableHeader");
            SetCell(totalRow, 1, $"${grandTotalSales:N2}", "TableHeader", ParagraphAlignment.Right);
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

        private void SetCell(Row row, int idx, string text, string style = null, ParagraphAlignment alignment = ParagraphAlignment.Left)
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

            var heading1 = doc.Styles.AddStyle("Heading1", "Normal");
            heading1.Font.Bold = true;
            heading1.Font.Size = 14;
            heading1.Font.Color = Color.FromRgb(156, 39, 176);

            var tableHeader = doc.Styles.AddStyle("TableHeader", "Normal");
            tableHeader.Font.Bold = true;
            tableHeader.Font.Size = 9;
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
    }
}
