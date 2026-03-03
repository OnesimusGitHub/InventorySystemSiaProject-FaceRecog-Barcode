using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Collections.Generic;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;
using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Generates comprehensive PDF report showing all variants for a product
    /// Includes variant details, stock information, pricing, and sales performance
    /// </summary>
    public class GenerateAllVariantsPDF : HttpTaskAsyncHandler
    {
        private ProductService _productService;
        private SalesService _salesService;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                _productService = new ProductService();
                _salesService = new SalesService();

                string productId = context.Request.QueryString["productId"];
                
                if (string.IsNullOrEmpty(productId))
                {
                    throw new ArgumentException("Product ID is required");
                }

                byte[] pdfBytes = await GenerateAllVariantsReportAsync(productId);

                // Send PDF to browser
                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                string fileName = $"All_Variants_Report_{DateTime.Now:yyyyMMdd_HHmmss}.pdf";
                context.Response.AddHeader("Content-Disposition", $"attachment; filename={fileName}");
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error generating PDF: " + ex.Message);
                System.Diagnostics.Debug.WriteLine($"Error in GenerateAllVariantsPDF: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            }
        }

        private async Task<byte[]> GenerateAllVariantsReportAsync(string productId)
        {
            // Get product details
            var product = await _productService.GetProductByIdAsync(productId);
            if (product == null)
            {
                throw new Exception("Product not found");
            }

            // Get all variants for the product
            var variants = await _productService.GetProductVariantsByProductIdAsync(productId);
            
            var doc = new Document();
            doc.Info.Title = $"{product.productName} - All Variants Report";
            doc.Info.Subject = "Comprehensive variant information and performance";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);
            section.PageSetup.BottomMargin = Unit.FromCentimeter(2);

            // ========== TITLE PAGE ==========
            AddTitlePage(section, product, variants);

            // ========== PRODUCT OVERVIEW ==========
            section.AddPageBreak();
            AddProductOverview(section, product, variants);

            // ========== VARIANTS DETAIL TABLE ==========
            section.AddPageBreak();
            await AddVariantsDetailTable(section, product, variants);

            // ========== SALES PERFORMANCE ==========
            if (variants.Any())
            {
                section.AddPageBreak();
                await AddSalesPerformanceSection(section, variants);
            }

            // ========== STOCK ANALYSIS ==========
            section.AddPageBreak();
            AddStockAnalysisSection(section, variants);

            return RenderDocument(doc);
        }

        private void AddTitlePage(Section section, Product product, List<ProductVariant> variants)
        {
            // Main Title
            var title = section.AddParagraph("All Variants Report");
            title.Format.Font.Size = 24;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Color.FromRgb(33, 150, 243);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromCentimeter(4);
            title.Format.SpaceAfter = Unit.FromPoint(20);

            // Product Name
            var productName = section.AddParagraph(product.productName);
            productName.Format.Font.Size = 18;
            productName.Format.Font.Bold = true;
            productName.Format.Alignment = ParagraphAlignment.Center;
            productName.Format.SpaceAfter = Unit.FromPoint(10);

            // Subtitle
            var subtitle = section.AddParagraph("Comprehensive Variant Analysis");
            subtitle.Format.Font.Size = 14;
            subtitle.Format.Font.Italic = true;
            subtitle.Format.Alignment = ParagraphAlignment.Center;
            subtitle.Format.SpaceAfter = Unit.FromCentimeter(3);

            // Statistics box
            var statsTable = section.AddTable();
            statsTable.Borders.Width = 0;
            statsTable.AddColumn(Unit.FromCentimeter(16));

            var row1 = statsTable.AddRow();
            row1.Cells[0].AddParagraph($"Product Category: {product.productCategory ?? "N/A"}");
            row1.Cells[0].Format.Font.Size = 12;
            row1.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row1.Height = Unit.FromPoint(25);

            var row2 = statsTable.AddRow();
            row2.Cells[0].AddParagraph($"Total Variants: {variants.Count}");
            row2.Cells[0].Format.Font.Size = 12;
            row2.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row2.Height = Unit.FromPoint(25);

            var row3 = statsTable.AddRow();
            row3.Cells[0].AddParagraph($"Active Variants: {variants.Count(v => v.IsActive)}");
            row3.Cells[0].Format.Font.Size = 12;
            row3.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row3.Height = Unit.FromPoint(25);

            var row4 = statsTable.AddRow();
            row4.Cells[0].AddParagraph($"Total Stock Units: {variants.Sum(v => v.StockQuantity)}");
            row4.Cells[0].Format.Font.Size = 12;
            row4.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row4.Height = Unit.FromPoint(25);

            // Generated date at bottom
            section.AddParagraph().Format.SpaceAfter = Unit.FromCentimeter(5);
            var genDate = section.AddParagraph($"Generated on: {DateTime.Now:MMMM dd, yyyy 'at' HH:mm}");
            genDate.Format.Font.Size = 10;
            genDate.Format.Alignment = ParagraphAlignment.Center;
            genDate.Format.Font.Color = Colors.Gray;
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
            AddSummaryRow(table, "Base Price:", $"${product.productVal:N2}");
            AddSummaryRow(table, "Total Variants:", variants.Count.ToString());
            AddSummaryRow(table, "Active Variants:", variants.Count(v => v.IsActive).ToString());
            AddSummaryRow(table, "Inactive Variants:", variants.Count(v => !v.IsActive).ToString());
            AddSummaryRow(table, "Total Stock Value:", $"${variants.Sum(v => v.TotalValue):N2}");
            AddSummaryRow(table, "Low Stock Variants:", variants.Count(v => v.IsLowStock).ToString());

            if (!string.IsNullOrEmpty(product.productDesc))
            {
                section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(15);
                var descHeading = section.AddParagraph("Description");
                descHeading.Format.Font.Bold = true;
                descHeading.Format.SpaceAfter = Unit.FromPoint(5);
                
                var desc = section.AddParagraph(product.productDesc);
                desc.Format.Font.Size = 9;
            }
        }

        private async Task AddVariantsDetailTable(Section section, Product product, List<ProductVariant> variants)
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
            
            // Define columns
            table.AddColumn(Unit.FromCentimeter(4));   // Variant Name
            table.AddColumn(Unit.FromCentimeter(2.5)); // Size
            table.AddColumn(Unit.FromCentimeter(2.5)); // Color
            table.AddColumn(Unit.FromCentimeter(2.5)); // Price
            table.AddColumn(Unit.FromCentimeter(2));   // Stock
            table.AddColumn(Unit.FromCentimeter(2));   // Min Stock
            table.AddColumn(Unit.FromCentimeter(2));   // Status

            // Header row
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

            // Data rows
            decimal totalValue = 0;
            int totalStock = 0;

            foreach (var variant in variants.OrderBy(v => v.VariantName))
            {
                var row = table.AddRow();
                
                // Variant Name
                SetCell(row, 0, variant.VariantName ?? "N/A");
                
                // Size
                SetCell(row, 1, variant.Size ?? "-");
                
                // Color
                SetCell(row, 2, variant.Color ?? "-");
                
                // Price
                SetCell(row, 3, $"${variant.Price:N2}", alignment: ParagraphAlignment.Right);
                
                // Stock
                var stockCell = row.Cells[4].AddParagraph(variant.StockQuantity.ToString());
                stockCell.Format.Alignment = ParagraphAlignment.Right;
                if (variant.IsLowStock)
                {
                    stockCell.Format.Font.Color = Colors.Red;
                    stockCell.Format.Font.Bold = true;
                }
                
                // Min Stock
                SetCell(row, 5, variant.MinimumStock.ToString(), alignment: ParagraphAlignment.Right);
                
                // Status
                var status = !variant.IsActive ? "Inactive" : (variant.IsLowStock ? "? Low Stock" : "Active");
                var statusCell = row.Cells[6].AddParagraph(status);
                if (!variant.IsActive)
                {
                    statusCell.Format.Font.Color = Colors.Gray;
                    statusCell.Format.Font.Italic = true;
                }
                else if (variant.IsLowStock)
                {
                    statusCell.Format.Font.Color = Colors.Red;
                    statusCell.Format.Font.Bold = true;
                }
                else
                {
                    statusCell.Format.Font.Color = Colors.Green;
                }

                totalValue += variant.TotalValue;
                totalStock += variant.StockQuantity;
            }

            // Summary row
            var summaryRow = table.AddRow();
            summaryRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(summaryRow, 0, "TOTAL", "TableHeader");
            SetCell(summaryRow, 1, "-", "TableHeader");
            SetCell(summaryRow, 2, "-", "TableHeader");
            SetCell(summaryRow, 3, $"${totalValue:N2}", "TableHeader", ParagraphAlignment.Right);
            SetCell(summaryRow, 4, totalStock.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(summaryRow, 5, "-", "TableHeader");
            SetCell(summaryRow, 6, variants.Count.ToString(), "TableHeader");

            await Task.CompletedTask;
        }

        private async Task AddSalesPerformanceSection(Section section, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Sales Performance (Last 30 Days)");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var now = DateTime.UtcNow;
            var thirtyDaysAgo = now.AddDays(-30);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            
            table.AddColumn(Unit.FromCentimeter(5));   // Variant Name
            table.AddColumn(Unit.FromCentimeter(3));   // Units Sold
            table.AddColumn(Unit.FromCentimeter(3));   // Revenue
            table.AddColumn(Unit.FromCentimeter(2.5)); // Orders
            table.AddColumn(Unit.FromCentimeter(3));   // Avg Order Value

            // Header
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
                var sales = await _salesService.GetSalesByVariantAsync(variant.Id);
                var recentSales = sales.Where(s => s.TransactionDate >= thirtyDaysAgo).ToList();

                var unitsSold = recentSales.Sum(s => s.Quantity);
                var revenue = recentSales.Sum(s => s.TotalAmount);
                var orderCount = recentSales.Count;
                var avgOrder = orderCount > 0 ? revenue / orderCount : 0;

                var row = table.AddRow();
                SetCell(row, 0, variant.VariantName ?? "N/A");
                SetCell(row, 1, unitsSold.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 2, $"${revenue:N2}", alignment: ParagraphAlignment.Right);
                SetCell(row, 3, orderCount.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 4, $"${avgOrder:N2}", alignment: ParagraphAlignment.Right);

                totalRevenue += revenue;
                totalUnitsSold += unitsSold;
                totalOrders += orderCount;
            }

            // Total row
            var totalRow = table.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(totalRow, 0, "TOTAL", "TableHeader");
            SetCell(totalRow, 1, totalUnitsSold.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 2, $"${totalRevenue:N2}", "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 3, totalOrders.ToString(), "TableHeader", ParagraphAlignment.Right);
            var totalAvg = totalOrders > 0 ? totalRevenue / totalOrders : 0;
            SetCell(totalRow, 4, $"${totalAvg:N2}", "TableHeader", ParagraphAlignment.Right);
        }

        private void AddStockAnalysisSection(Section section, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Stock Analysis");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            // Stock Status Summary
            var lowStockCount = variants.Count(v => v.IsLowStock);
            var normalStockCount = variants.Count(v => !v.IsLowStock && v.IsActive);
            var inactiveCount = variants.Count(v => !v.IsActive);

            var summaryTable = section.AddTable();
            summaryTable.Borders.Width = 0.5;
            summaryTable.Borders.Color = Colors.LightGray;
            summaryTable.AddColumn(Unit.FromCentimeter(8));
            summaryTable.AddColumn(Unit.FromCentimeter(8));

            AddSummaryRow(summaryTable, "Total Variants:", variants.Count.ToString());
            AddSummaryRow(summaryTable, "Normal Stock:", normalStockCount.ToString());
            
            var lowStockRow = summaryTable.AddRow();
            lowStockRow.Cells[0].AddParagraph("Low Stock:").Format.Font.Bold = true;
            var lowStockCell = lowStockRow.Cells[1].AddParagraph(lowStockCount.ToString());
            lowStockCell.Format.Alignment = ParagraphAlignment.Right;
            if (lowStockCount > 0)
            {
                lowStockCell.Format.Font.Color = Colors.Red;
                lowStockCell.Format.Font.Bold = true;
            }
            
            AddSummaryRow(summaryTable, "Inactive:", inactiveCount.ToString());
            AddSummaryRow(summaryTable, "Total Stock Value:", $"${variants.Sum(v => v.TotalValue):N2}");
            AddSummaryRow(summaryTable, "Average Stock per Variant:", $"{variants.Average(v => v.StockQuantity):N1} units");

            // Low Stock Warning
            if (lowStockCount > 0)
            {
                section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(20);
                
                var warningHeading = section.AddParagraph("? Low Stock Alert");
                warningHeading.Format.Font.Bold = true;
                warningHeading.Format.Font.Size = 12;
                warningHeading.Format.Font.Color = Colors.Red;
                warningHeading.Format.SpaceAfter = Unit.FromPoint(10);

                var lowStockTable = section.AddTable();
                lowStockTable.Borders.Width = 0.5;
                lowStockTable.Borders.Color = Colors.LightGray;
                lowStockTable.AddColumn(Unit.FromCentimeter(6));
                lowStockTable.AddColumn(Unit.FromCentimeter(3));
                lowStockTable.AddColumn(Unit.FromCentimeter(3));
                lowStockTable.AddColumn(Unit.FromCentimeter(4));

                var lowStockHeader = lowStockTable.AddRow();
                lowStockHeader.Shading.Color = Colors.LightGray;
                SetCell(lowStockHeader, 0, "Variant", "TableHeader");
                SetCell(lowStockHeader, 1, "Current Stock", "TableHeader", ParagraphAlignment.Right);
                SetCell(lowStockHeader, 2, "Min Stock", "TableHeader", ParagraphAlignment.Right);
                SetCell(lowStockHeader, 3, "Reorder Needed", "TableHeader", ParagraphAlignment.Right);

                foreach (var variant in variants.Where(v => v.IsLowStock).OrderBy(v => v.StockQuantity))
                {
                    var row = lowStockTable.AddRow();
                    SetCell(row, 0, variant.VariantName ?? "N/A");
                    
                    var stockCell = row.Cells[1].AddParagraph(variant.StockQuantity.ToString());
                    stockCell.Format.Alignment = ParagraphAlignment.Right;
                    stockCell.Format.Font.Color = Colors.Red;
                    stockCell.Format.Font.Bold = true;
                    
                    SetCell(row, 2, variant.MinimumStock.ToString(), alignment: ParagraphAlignment.Right);
                    
                    var reorderQty = Math.Max(0, variant.MinimumStock * 2 - variant.StockQuantity);
                    SetCell(row, 3, $"{reorderQty} units", alignment: ParagraphAlignment.Right);
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
            heading1.Font.Color = Color.FromRgb(33, 150, 243);

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
