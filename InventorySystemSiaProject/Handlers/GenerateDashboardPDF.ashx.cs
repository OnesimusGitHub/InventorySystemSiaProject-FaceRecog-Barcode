using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;
using System.Collections.Generic;
using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;

namespace InventorySystemSiaProject.Handlers
{
    public class GenerateDashboardPDF : HttpTaskAsyncHandler
    {
        private ProductService _productService;
        private SalesService _salesService;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                _productService = new ProductService();
                _salesService = new SalesService();

                string reportType = context.Request.QueryString["type"] ?? "standard";
                byte[] pdfBytes;

                if (reportType == "standard")
                {
                    string period = context.Request.QueryString["period"] ?? "monthly";
                    pdfBytes = await GenerateStandardReportAsync(period);
                }
                else
                {
                    string startDateStr = context.Request.QueryString["startDate"];
                    string endDateStr = context.Request.QueryString["endDate"];
                    DateTime startDate = DateTime.Parse(startDateStr);
                    DateTime endDate = DateTime.Parse(endDateStr);
                    pdfBytes = await GenerateCustomReportAsync(startDate, endDate);
                }

                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                context.Response.AddHeader("Content-Disposition",
                    $"attachment; filename=Dashboard_Report_{DateTime.Now:yyyyMMdd_HHmmss}.pdf");
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error: " + ex.Message);
            }
        }

        private async Task<byte[]> GenerateStandardReportAsync(string period)
        {
            var allSales = await _salesService.GetAllSalesAsync();
            var products = await _productService.GetAllProductsAsync();
            var variants = await _productService.GetAllProductVariantsAsync();

            var doc = new Document();
            doc.Info.Title = "Dashboard Sales Report - All Periods";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            // Generate overview page
            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            // Main Title
            var title = section.AddParagraph("Dashboard Sales Report");
            title.Format.Font.Size = 20;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Colors.White;
            title.Format.Shading.Color = Color.FromRgb(166, 77, 121);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromPoint(10);
            title.Format.SpaceAfter = Unit.FromPoint(10);

            var subtitle = section.AddParagraph("Daily, Weekly, and Monthly Analysis");
            subtitle.Format.Font.Size = 12;
            subtitle.Format.Font.Italic = true;
            subtitle.Format.Alignment = ParagraphAlignment.Center;
            subtitle.Format.SpaceAfter = Unit.FromPoint(5);

            // Generated date
            var dateInfo = section.AddParagraph($"Generated: {DateTime.Now:MMM dd, yyyy HH:mm}");
            dateInfo.Format.Font.Size = 9;
            dateInfo.Format.Alignment = ParagraphAlignment.Center;
            dateInfo.Format.SpaceAfter = Unit.FromPoint(20);

            // Overall Summary Statistics
            AddSummarySection(section, allSales, products, variants);

            // Product List Table
            AddProductListTable(section, products, variants);

            // Add page break before period reports
            section.AddPageBreak();

            // Add Daily Report
            AddPeriodReport(section, allSales, "Daily", "Last 7 Days");
            section.AddPageBreak();

            // Add Weekly Report
            AddPeriodReport(section, allSales, "Weekly", "Last 4 Weeks");
            section.AddPageBreak();

            // Add Monthly Report
            AddPeriodReport(section, allSales, "Monthly", "Last 12 Months");

            return RenderDocument(doc);
        }

        private void AddPeriodReport(Section section, List<Sale> sales, string periodName, string periodDescription)
        {
            // Period Title
            var periodTitle = section.AddParagraph($"{periodName} Sales Report");
            periodTitle.Format.Font.Size = 16;
            periodTitle.Format.Font.Bold = true;
            periodTitle.Format.Font.Color = Color.FromRgb(166, 77, 121);
            periodTitle.Format.SpaceBefore = Unit.FromPoint(10);
            periodTitle.Format.SpaceAfter = Unit.FromPoint(5);

            var periodSubtitle = section.AddParagraph(periodDescription);
            periodSubtitle.Format.Font.Size = 10;
            periodSubtitle.Format.Font.Italic = true;
            periodSubtitle.Format.SpaceAfter = Unit.FromPoint(15);

            // Filter sales based on period
            var filteredSales = FilterSalesByPeriod(sales, periodName);

            // Group and aggregate sales data
            var aggregatedData = AggregateSalesByPeriod(filteredSales, periodName);

            if (aggregatedData.Count == 0)
            {
                var noData = section.AddParagraph("No sales data available for this period.");
                noData.Format.Font.Italic = true;
                noData.Format.SpaceAfter = Unit.FromPoint(20);
                return;
            }

            // Create sales table
            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(5));    // Period Label
            table.AddColumn(Unit.FromCentimeter(3));    // Total Sales
            table.AddColumn(Unit.FromCentimeter(3));    // Orders
            table.AddColumn(Unit.FromCentimeter(3));    // Avg Order Value

            // Header row
            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            headerRow.Cells[0].AddParagraph("Period").Style = "TableHeader";
            headerRow.Cells[1].AddParagraph("Total Sales").Style = "TableHeader";
            headerRow.Cells[2].AddParagraph("Orders").Style = "TableHeader";
            headerRow.Cells[3].AddParagraph("Avg Value").Style = "TableHeader";

            // Data rows
            decimal grandTotal = 0;
            int totalOrders = 0;

            foreach (var item in aggregatedData)
            {
                var row = table.AddRow();
                row.Cells[0].AddParagraph(item.PeriodLabel);
                row.Cells[1].AddParagraph($"${item.TotalSales:N2}");
                row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[2].AddParagraph(item.OrderCount.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[3].AddParagraph($"${item.AverageOrderValue:N2}");
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;

                grandTotal += item.TotalSales;
                totalOrders += item.OrderCount;
            }

            // Total row
            var totalRow = table.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            totalRow.Cells[0].AddParagraph("TOTAL").Style = "TableHeader";
            totalRow.Cells[1].AddParagraph($"${grandTotal:N2}").Style = "TableHeader";
            totalRow.Cells[1].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[2].AddParagraph(totalOrders.ToString()).Style = "TableHeader";
            totalRow.Cells[2].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[3].AddParagraph($"${(totalOrders > 0 ? grandTotal / totalOrders : 0):N2}").Style = "TableHeader";
            totalRow.Cells[3].Format.Alignment = ParagraphAlignment.Right;

            section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(20);
        }

        private List<Sale> FilterSalesByPeriod(List<Sale> sales, string periodName)
        {
            var now = DateTime.Now;
            DateTime startDate;

            switch (periodName.ToLower())
            {
                case "daily":
                    startDate = now.AddDays(-7);
                    break;
                case "weekly":
                    startDate = now.AddDays(-28);
                    break;
                case "monthly":
                    startDate = now.AddMonths(-12);
                    break;
                default:
                    startDate = now.AddMonths(-12);
                    break;
            }

            return sales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= now).ToList();
        }

        private List<PeriodSalesData> AggregateSalesByPeriod(List<Sale> sales, string periodName)
        {
            var result = new List<PeriodSalesData>();

            switch (periodName.ToLower())
            {
                case "daily":
                    for (int i = 6; i >= 0; i--)
                    {
                        var date = DateTime.Now.AddDays(-i).Date;
                        var daySales = sales.Where(s => s.TransactionDate.Date == date).ToList();
                        result.Add(new PeriodSalesData
                        {
                            PeriodLabel = date.ToString("MMM dd, yyyy"),
                            TotalSales = daySales.Sum(s => s.SalePrice * s.Quantity),
                            OrderCount = daySales.Count,
                            AverageOrderValue = daySales.Count > 0 ? daySales.Sum(s => s.SalePrice * s.Quantity) / daySales.Count : 0
                        });
                    }
                    break;

                case "weekly":
                    for (int i = 3; i >= 0; i--)
                    {
                        var weekStart = DateTime.Now.AddDays(-((i + 1) * 7)).Date;
                        var weekEnd = DateTime.Now.AddDays(-(i * 7)).Date;
                        var weekSales = sales.Where(s => s.TransactionDate.Date >= weekStart && s.TransactionDate.Date < weekEnd).ToList();
                        result.Add(new PeriodSalesData
                        {
                            PeriodLabel = $"Week of {weekStart:MMM dd}",
                            TotalSales = weekSales.Sum(s => s.SalePrice * s.Quantity),
                            OrderCount = weekSales.Count,
                            AverageOrderValue = weekSales.Count > 0 ? weekSales.Sum(s => s.SalePrice * s.Quantity) / weekSales.Count : 0
                        });
                    }
                    break;

                case "monthly":
                    for (int i = 11; i >= 0; i--)
                    {
                        var month = DateTime.Now.AddMonths(-i);
                        var monthSales = sales.Where(s => s.TransactionDate.Year == month.Year && s.TransactionDate.Month == month.Month).ToList();
                        result.Add(new PeriodSalesData
                        {
                            PeriodLabel = month.ToString("MMMM yyyy"),
                            TotalSales = monthSales.Sum(s => s.SalePrice * s.Quantity),
                            OrderCount = monthSales.Count,
                            AverageOrderValue = monthSales.Count > 0 ? monthSales.Sum(s => s.SalePrice * s.Quantity) / monthSales.Count : 0
                        });
                    }
                    break;
            }

            return result;
        }

        private class PeriodSalesData
        {
            public string PeriodLabel { get; set; }
            public decimal TotalSales { get; set; }
            public int OrderCount { get; set; }
            public decimal AverageOrderValue { get; set; }
        }

        private async Task<byte[]> GenerateCustomReportAsync(DateTime startDate, DateTime endDate)
        {
            var allSales = await _salesService.GetAllSalesAsync();
            var salesInRange = allSales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate).ToList();
            var products = await _productService.GetAllProductsAsync();
            var variants = await _productService.GetAllProductVariantsAsync();

            var doc = new Document();
            doc.Info.Title = "Custom Dashboard Report";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            // Title
            var title = section.AddParagraph($"Custom Report: {startDate:MMM dd, yyyy} - {endDate:MMM dd, yyyy}");
            title.Format.Font.Size = 18;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Colors.White;
            title.Format.Shading.Color = Color.FromRgb(166, 77, 121);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromPoint(10);
            title.Format.SpaceAfter = Unit.FromPoint(10);

            // Generated date
            var dateInfo = section.AddParagraph($"Generated: {DateTime.Now:MMM dd, yyyy HH:mm}");
            dateInfo.Format.Font.Size = 9;
            dateInfo.Format.SpaceAfter = Unit.FromPoint(20);

            // Summary Statistics
            AddSummarySection(section, salesInRange, products, variants);

            // Product List Table
            AddProductListTable(section, products, variants);

            return RenderDocument(doc);
        }

        private void DefineStyles(Document doc)
        {
            var normal = doc.Styles["Normal"];
            normal.Font.Name = "Arial";
            normal.Font.Size = 10;

            var heading = doc.Styles.AddStyle("Heading1", "Normal");
            heading.Font.Bold = true;
            heading.Font.Size = 14;
            heading.Font.Color = Color.FromRgb(166, 77, 121);

            var tableHeader = doc.Styles.AddStyle("TableHeader", "Normal");
            tableHeader.Font.Bold = true;
            tableHeader.Font.Size = 10;
        }

        private void AddSummarySection(Section section, List<Sale> sales, List<Product> products, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Sales Report Summary");
            heading.Style = "Heading1";
            heading.Format.SpaceBefore = Unit.FromPoint(10);
            heading.Format.SpaceAfter = Unit.FromPoint(10);

            var totalSales = sales.Sum(s => s.SalePrice * s.Quantity);
            var totalOrders = sales.Count;
            var totalProducts = products.Count;
            var lowStock = variants.Count(v => v.StockQuantity <= v.MinimumStock);

            // Create summary table
            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(8));
            table.AddColumn(Unit.FromCentimeter(6));

            AddSummaryRow(table, "Total Sales:", $"${totalSales:N2}");
            AddSummaryRow(table, "Total Orders:", totalOrders.ToString());
            AddSummaryRow(table, "Total Products:", totalProducts.ToString());
            AddSummaryRow(table, "Low Stock Items:", lowStock.ToString());

            section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(20);
        }

        private void AddSummaryRow(Table table, string label, string value)
        {
            var row = table.AddRow();
            row.Cells[0].AddParagraph(label).Format.Font.Bold = true;
            row.Cells[1].AddParagraph(value);
            row.Cells[0].Format.Alignment = ParagraphAlignment.Left;
            row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
        }

        private void AddProductListTable(Section section, List<Product> products, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Product List");
            heading.Style = "Heading1";
            heading.Format.SpaceBefore = Unit.FromPoint(10);
            heading.Format.SpaceAfter = Unit.FromPoint(10);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;

            // Define columns
            table.AddColumn(Unit.FromCentimeter(1.5));  // #
            table.AddColumn(Unit.FromCentimeter(8));     // Product Name
            table.AddColumn(Unit.FromCentimeter(3));     // Stock Qty
            table.AddColumn(Unit.FromCentimeter(2.5));   // Status

            // Header row
            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            headerRow.Cells[0].AddParagraph("#").Style = "TableHeader";
            headerRow.Cells[1].AddParagraph("Product Name").Style = "TableHeader";
            headerRow.Cells[2].AddParagraph("Stock Qty").Style = "TableHeader";
            headerRow.Cells[3].AddParagraph("Status").Style = "TableHeader";

            // Data rows
            int index = 1;
            foreach (var product in products.Take(15))
            {
                var productVariants = variants.Where(v => v.ProductId == product.Id).ToList();
                var stockQty = productVariants.Sum(v => v.StockQuantity);
                var minStock = productVariants.Sum(v => v.MinimumStock);
                var status = stockQty <= minStock ? "Low Stock" : "Normal";

                var row = table.AddRow();
                row.Cells[0].AddParagraph(index.ToString());
                row.Cells[1].AddParagraph(product.ProductName ?? "");
                row.Cells[2].AddParagraph(stockQty.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                
                var statusPara = row.Cells[3].AddParagraph(status);
                if (status == "Low Stock")
                {
                    statusPara.Format.Font.Color = Colors.Red;
                    statusPara.Format.Font.Bold = true;
                }

                index++;
            }
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