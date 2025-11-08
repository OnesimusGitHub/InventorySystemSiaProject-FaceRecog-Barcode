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
using MongoDB.Driver;
using MongoDB.Bson;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Generates PDF report for overall product performance across all variants
    /// Shows daily, weekly, and monthly sales data for all products and variants
    /// </summary>
    public class GenerateOverallProductPerformancePDF : HttpTaskAsyncHandler
    {
        private ProductService _productService;
        private SalesService _salesService;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                _productService = new ProductService();
                _salesService = new SalesService();

                // Get productId from query string
                string productIdStr = context.Request.QueryString["productId"];
                
                if (string.IsNullOrEmpty(productIdStr))
                {
                    throw new ArgumentException("Product ID is required");
                }

                ObjectId productId = ObjectId.Parse(productIdStr);

                string reportType = context.Request.QueryString["type"] ?? "standard";
                byte[] pdfBytes;

                if (reportType == "standard")
                {
                    // Generate standard report with Daily, Weekly, Monthly sections
                    pdfBytes = await GenerateStandardOverallPerformanceReportAsync(productId);
                }
                else if (reportType == "custom")
                {
                    // Generate custom date range report
                    string startDateStr = context.Request.QueryString["startDate"];
                    string endDateStr = context.Request.QueryString["endDate"];
                    
                    if (string.IsNullOrEmpty(startDateStr) || string.IsNullOrEmpty(endDateStr))
                    {
                        throw new ArgumentException("Start date and end date are required for custom reports");
                    }

                    DateTime startDate = DateTime.Parse(startDateStr);
                    DateTime endDate = DateTime.Parse(endDateStr);
                    pdfBytes = await GenerateCustomOverallPerformanceReportAsync(productId, startDate, endDate);
                }
                else
                {
                    throw new ArgumentException("Invalid report type. Use 'standard' or 'custom'");
                }

                // Send PDF to browser
                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                string fileName = $"Overall_Product_Performance_{DateTime.Now:yyyyMMdd_HHmmss}.pdf";
                context.Response.AddHeader("Content-Disposition", $"attachment; filename={fileName}");
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error generating PDF: " + ex.Message);
                System.Diagnostics.Debug.WriteLine($"Error in GenerateOverallProductPerformancePDF: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
            }
        }

        /// <summary>
        /// Generates standard report with Daily, Weekly, and Monthly sections for all products
        /// </summary>
        private async Task<byte[]> GenerateStandardOverallPerformanceReportAsync(ObjectId productId)
        {
            var allSales = await _salesService.GetAllSalesAsync();
            var products = await _productService.GetAllProductsAsync();
            var variants = await _productService.GetAllProductVariantsAsync();

            var doc = new Document();
            doc.Info.Title = "Overall Product Performance Report";
            doc.Info.Subject = "Sales performance across all products and variants";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);
            section.PageSetup.BottomMargin = Unit.FromCentimeter(2);

            // ========== TITLE PAGE ==========
            AddTitlePage(section, products.Count, variants.Count, allSales.Count);

            // ========== EXECUTIVE SUMMARY ==========
            section.AddPageBreak();
            AddExecutiveSummary(section, allSales, products, variants);

            // ========== DAILY PERFORMANCE ==========
            section.AddPageBreak();
            await AddDailyPerformanceSection(section, allSales, products, variants, productId);

            // ========== WEEKLY PERFORMANCE ==========
            section.AddPageBreak();
            await AddWeeklyPerformanceSection(section, allSales, products, variants, productId);

            // ========== MONTHLY PERFORMANCE ==========
            section.AddPageBreak();
            await AddMonthlyPerformanceSection(section, allSales, products, variants, productId);

            // ========== TOP PERFORMERS ==========
            section.AddPageBreak();
            AddTopPerformersSection(section, allSales, products, variants);

            return RenderDocument(doc);
        }

        /// <summary>
        /// Generates custom date range report for all products
        /// </summary>
        private async Task<byte[]> GenerateCustomOverallPerformanceReportAsync(ObjectId productId, DateTime startDate, DateTime endDate)
        {
            var allSales = await _salesService.GetAllSalesAsync();
            var salesInRange = allSales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate).ToList();
            var products = await _productService.GetAllProductsAsync();
            var variants = await _productService.GetAllProductVariantsAsync();

            var doc = new Document();
            doc.Info.Title = $"Overall Product Performance - {startDate:MMM dd, yyyy} to {endDate:MMM dd, yyyy}";
            doc.Info.Subject = "Custom date range sales performance report";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            // Title
            var title = section.AddParagraph($"Overall Product Performance");
            title.Format.Font.Size = 20;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Colors.White;
            title.Format.Shading.Color = Color.FromRgb(166, 77, 121);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromPoint(10);
            title.Format.SpaceAfter = Unit.FromPoint(10);

            var dateRange = section.AddParagraph($"{startDate:MMM dd, yyyy} - {endDate:MMM dd, yyyy}");
            dateRange.Format.Font.Size = 12;
            dateRange.Format.Font.Italic = true;
            dateRange.Format.Alignment = ParagraphAlignment.Center;
            dateRange.Format.SpaceAfter = Unit.FromPoint(5);

            var genDate = section.AddParagraph($"Generated: {DateTime.Now:MMM dd, yyyy HH:mm}");
            genDate.Format.Font.Size = 9;
            genDate.Format.Alignment = ParagraphAlignment.Center;
            genDate.Format.SpaceAfter = Unit.FromPoint(20);

            // Summary statistics
            AddCustomRangeSummary(section, salesInRange, products, variants, startDate, endDate);

            // Product performance details
            section.AddPageBreak();
            AddCustomRangeProductDetails(section, salesInRange, products, variants);

            return RenderDocument(doc);
        }

        private void AddTitlePage(Section section, int productCount, int variantCount, int totalSales)
        {
            // Main Title
            var title = section.AddParagraph("Overall Product Performance Report");
            title.Format.Font.Size = 24;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Color.FromRgb(166, 77, 121);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromCentimeter(4);
            title.Format.SpaceAfter = Unit.FromPoint(20);

            // Subtitle
            var subtitle = section.AddParagraph("Comprehensive Sales Analysis Across All Products and Variants");
            subtitle.Format.Font.Size = 14;
            subtitle.Format.Font.Italic = true;
            subtitle.Format.Alignment = ParagraphAlignment.Center;
            subtitle.Format.SpaceAfter = Unit.FromCentimeter(3);

            // Statistics box
            var statsTable = section.AddTable();
            statsTable.Borders.Width = 0;
            statsTable.AddColumn(Unit.FromCentimeter(16));

            var row1 = statsTable.AddRow();
            row1.Cells[0].AddParagraph($"Total Products: {productCount}");
            row1.Cells[0].Format.Font.Size = 12;
            row1.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row1.Height = Unit.FromPoint(25);

            var row2 = statsTable.AddRow();
            row2.Cells[0].AddParagraph($"Total Variants: {variantCount}");
            row2.Cells[0].Format.Font.Size = 12;
            row2.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row2.Height = Unit.FromPoint(25);

            var row3 = statsTable.AddRow();
            row3.Cells[0].AddParagraph($"Total Sales Transactions: {totalSales}");
            row3.Cells[0].Format.Font.Size = 12;
            row3.Cells[0].Format.Alignment = ParagraphAlignment.Center;
            row3.Height = Unit.FromPoint(25);

            // Generated date at bottom
            section.AddParagraph().Format.SpaceAfter = Unit.FromCentimeter(5);
            var genDate = section.AddParagraph($"Generated on: {DateTime.Now:MMMM dd, yyyy 'at' HH:mm}");
            genDate.Format.Font.Size = 10;
            genDate.Format.Alignment = ParagraphAlignment.Center;
            genDate.Format.Font.Color = Colors.Gray;
        }

        private void AddExecutiveSummary(Section section, List<Sale> allSales, List<Product> products, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Executive Summary");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var now = DateTime.UtcNow;
            var last30Days = allSales.Where(s => s.TransactionDate >= now.AddDays(-30)).ToList();
            var previous30Days = allSales.Where(s => s.TransactionDate >= now.AddDays(-60) && s.TransactionDate < now.AddDays(-30)).ToList();

            var totalRevenue = last30Days.Sum(s => s.TotalAmount);
            var previousRevenue = previous30Days.Sum(s => s.TotalAmount);
            var revenueGrowth = previousRevenue > 0 ? ((totalRevenue - previousRevenue) / previousRevenue * 100) : 0;

            var totalOrders = last30Days.Count;
            var previousOrders = previous30Days.Count;
            var orderGrowth = previousOrders > 0 ? ((totalOrders - previousOrders) / (decimal)previousOrders * 100) : 0;

            var avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

            // Summary table
            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(10));
            table.AddColumn(Unit.FromCentimeter(6));

            AddSummaryRow(table, "Period:", "Last 30 Days");
            AddSummaryRow(table, "Total Revenue:", $"${totalRevenue:N2}");
            AddSummaryRow(table, "Revenue Growth:", $"{revenueGrowth:+0.0;-0.0;0}%");
            AddSummaryRow(table, "Total Orders:", totalOrders.ToString());
            AddSummaryRow(table, "Order Growth:", $"{orderGrowth:+0.0;-0.0;0}%");
            AddSummaryRow(table, "Average Order Value:", $"${avgOrderValue:N2}");
            AddSummaryRow(table, "Active Products:", products.Count.ToString());
            AddSummaryRow(table, "Active Variants:", variants.Count(v => v.IsActive).ToString());

            var lowStockVariants = variants.Count(v => v.IsLowStock);
            AddSummaryRow(table, "Low Stock Variants:", lowStockVariants.ToString());
        }

        private void AddSummaryRow(Table table, string label, string value)
        {
            var row = table.AddRow();
            row.Cells[0].AddParagraph(label).Format.Font.Bold = true;
            row.Cells[1].AddParagraph(value);
            row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
        }

        private async Task AddDailyPerformanceSection(Section section, List<Sale> allSales, List<Product> products, List<ProductVariant> variants, ObjectId productId)
        {
            var heading = section.AddParagraph("Daily Performance (Last 7 Days)");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var now = DateTime.UtcNow;
            var dailyData = new List<DailySalesData>();

            string productIdStr = productId.ToString();
            for (int i = 6; i >= 0; i--)
            {
                var date = now.AddDays(-i).Date;
                var daySales = allSales.Where(s => s.TransactionDate.Date == date && s.ProductId == productIdStr).ToList();

                dailyData.Add(new DailySalesData
                {
                    Date = date,
                    TotalSales = daySales.Sum(s => s.TotalAmount),
                    OrderCount = daySales.Count,
                    UniqueProducts = daySales.Select(s => s.ProductId).Distinct().Count(),
                    UniqueVariants = daySales.Select(s => s.VariantId).Distinct().Count()
                });
            }

            // Create table
            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(3.5));  // Date
            table.AddColumn(Unit.FromCentimeter(3));    // Total Sales
            table.AddColumn(Unit.FromCentimeter(2.5));  // Orders
            table.AddColumn(Unit.FromCentimeter(3));    // Avg Order Value
            table.AddColumn(Unit.FromCentimeter(2.5));  // Products Sold
            table.AddColumn(Unit.FromCentimeter(2.5));  // Variants Sold

            // Header
            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            headerRow.Cells[0].AddParagraph("Date").Style = "TableHeader";
            headerRow.Cells[1].AddParagraph("Total Sales").Style = "TableHeader";
            headerRow.Cells[2].AddParagraph("Orders").Style = "TableHeader";
            headerRow.Cells[3].AddParagraph("Avg Value").Style = "TableHeader";
            headerRow.Cells[4].AddParagraph("Products").Style = "TableHeader";
            headerRow.Cells[5].AddParagraph("Variants").Style = "TableHeader";

            // Data rows
            decimal grandTotal = 0;
            int totalOrders = 0;

            foreach (var item in dailyData)
            {
                var row = table.AddRow();
                row.Cells[0].AddParagraph(item.Date.ToString("MMM dd, yyyy"));
                row.Cells[1].AddParagraph($"${item.TotalSales:N2}");
                row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[2].AddParagraph(item.OrderCount.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                
                var avgValue = item.OrderCount > 0 ? item.TotalSales / item.OrderCount : 0;
                row.Cells[3].AddParagraph($"${avgValue:N2}");
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;
                
                row.Cells[4].AddParagraph(item.UniqueProducts.ToString());
                row.Cells[4].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[5].AddParagraph(item.UniqueVariants.ToString());
                row.Cells[5].Format.Alignment = ParagraphAlignment.Right;

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
            
            var totalAvg = totalOrders > 0 ? grandTotal / totalOrders : 0;
            totalRow.Cells[3].AddParagraph($"${totalAvg:N2}").Style = "TableHeader";
            totalRow.Cells[3].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[4].AddParagraph("-");
            totalRow.Cells[4].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[5].AddParagraph("-");
            totalRow.Cells[5].Format.Alignment = ParagraphAlignment.Right;

            await Task.CompletedTask;
        }

        private async Task AddWeeklyPerformanceSection(Section section, List<Sale> allSales, List<Product> products, List<ProductVariant> variants, ObjectId productId)
        {
            var heading = section.AddParagraph("Weekly Performance (Last 4 Weeks)");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var now = DateTime.UtcNow;
            var weeklyData = new List<WeeklySalesData>();

            string productIdStr = productId.ToString();
            for (int i = 3; i >= 0; i--)
            {
                var weekStart = now.AddDays(-((i + 1) * 7)).Date;
                var weekEnd = now.AddDays(-(i * 7)).Date;
                var weekSales = allSales.Where(s => s.TransactionDate.Date >= weekStart && s.TransactionDate.Date < weekEnd && s.ProductId == productIdStr).ToList();

                weeklyData.Add(new WeeklySalesData
                {
                    WeekLabel = $"Week of {weekStart:MMM dd}",
                    StartDate = weekStart,
                    EndDate = weekEnd.AddDays(-1),
                    TotalSales = weekSales.Sum(s => s.TotalAmount),
                    OrderCount = weekSales.Count,
                    UniqueProducts = weekSales.Select(s => s.ProductId).Distinct().Count(),
                    UniqueVariants = weekSales.Select(s => s.VariantId).Distinct().Count()
                });
            }

            // Create table
            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(4));    // Week
            table.AddColumn(Unit.FromCentimeter(3));    // Total Sales
            table.AddColumn(Unit.FromCentimeter(2.5));  // Orders
            table.AddColumn(Unit.FromCentimeter(3));    // Avg Order Value
            table.AddColumn(Unit.FromCentimeter(2.5));  // Products
            table.AddColumn(Unit.FromCentimeter(2));    // Variants

            // Header
            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            headerRow.Cells[0].AddParagraph("Week").Style = "TableHeader";
            headerRow.Cells[1].AddParagraph("Total Sales").Style = "TableHeader";
            headerRow.Cells[2].AddParagraph("Orders").Style = "TableHeader";
            headerRow.Cells[3].AddParagraph("Avg Value").Style = "TableHeader";
            headerRow.Cells[4].AddParagraph("Products").Style = "TableHeader";
            headerRow.Cells[5].AddParagraph("Variants").Style = "TableHeader";

            // Data rows
            decimal grandTotal = 0;
            int totalOrders = 0;

            foreach (var item in weeklyData)
            {
                var row = table.AddRow();
                row.Cells[0].AddParagraph(item.WeekLabel);
                row.Cells[1].AddParagraph($"${item.TotalSales:N2}");
                row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[2].AddParagraph(item.OrderCount.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                
                var avgValue = item.OrderCount > 0 ? item.TotalSales / item.OrderCount : 0;
                row.Cells[3].AddParagraph($"${avgValue:N2}");
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;
                
                row.Cells[4].AddParagraph(item.UniqueProducts.ToString());
                row.Cells[4].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[5].AddParagraph(item.UniqueVariants.ToString());
                row.Cells[5].Format.Alignment = ParagraphAlignment.Right;

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
            
            var totalAvg = totalOrders > 0 ? grandTotal / totalOrders : 0;
            totalRow.Cells[3].AddParagraph($"${totalAvg:N2}").Style = "TableHeader";
            totalRow.Cells[3].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[4].AddParagraph("-");
            totalRow.Cells[4].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[5].AddParagraph("-");
            totalRow.Cells[5].Format.Alignment = ParagraphAlignment.Right;

            await Task.CompletedTask;
        }

        private async Task AddMonthlyPerformanceSection(Section section, List<Sale> allSales, List<Product> products, List<ProductVariant> variants, ObjectId productId)
        {
            var heading = section.AddParagraph("Monthly Performance (Last 12 Months)");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var now = DateTime.UtcNow;
            var monthlyData = new List<MonthlySalesData>();

            string productIdStr = productId.ToString();
            for (int i = 11; i >= 0; i--)
            {
                var month = now.AddMonths(-i);
                var monthSales = allSales.Where(s => s.TransactionDate.Year == month.Year && s.TransactionDate.Month == month.Month && s.ProductId == productIdStr).ToList();

                monthlyData.Add(new MonthlySalesData
                {
                    MonthLabel = month.ToString("MMMM yyyy"),
                    Year = month.Year,
                    Month = month.Month,
                    TotalSales = monthSales.Sum(s => s.TotalAmount),
                    OrderCount = monthSales.Count,
                    UniqueProducts = monthSales.Select(s => s.ProductId).Distinct().Count(),
                    UniqueVariants = monthSales.Select(s => s.VariantId).Distinct().Count()
                });
            }

            // Create table
            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(4));    // Month
            table.AddColumn(Unit.FromCentimeter(3));    // Total Sales
            table.AddColumn(Unit.FromCentimeter(2.5));  // Orders
            table.AddColumn(Unit.FromCentimeter(3));    // Avg Order Value
            table.AddColumn(Unit.FromCentimeter(2.5));  // Products
            table.AddColumn(Unit.FromCentimeter(2));    // Variants

            // Header
            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            headerRow.Cells[0].AddParagraph("Month").Style = "TableHeader";
            headerRow.Cells[1].AddParagraph("Total Sales").Style = "TableHeader";
            headerRow.Cells[2].AddParagraph("Orders").Style = "TableHeader";
            headerRow.Cells[3].AddParagraph("Avg Value").Style = "TableHeader";
            headerRow.Cells[4].AddParagraph("Products").Style = "TableHeader";
            headerRow.Cells[5].AddParagraph("Variants").Style = "TableHeader";

            // Data rows
            decimal grandTotal = 0;
            int totalOrders = 0;

            foreach (var item in monthlyData)
            {
                var row = table.AddRow();
                row.Cells[0].AddParagraph(item.MonthLabel);
                row.Cells[1].AddParagraph($"${item.TotalSales:N2}");
                row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[2].AddParagraph(item.OrderCount.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                
                var avgValue = item.OrderCount > 0 ? item.TotalSales / item.OrderCount : 0;
                row.Cells[3].AddParagraph($"${avgValue:N2}");
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;
                
                row.Cells[4].AddParagraph(item.UniqueProducts.ToString());
                row.Cells[4].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[5].AddParagraph(item.UniqueVariants.ToString());
                row.Cells[5].Format.Alignment = ParagraphAlignment.Right;

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
            
            var totalAvg = totalOrders > 0 ? grandTotal / totalOrders : 0;
            totalRow.Cells[3].AddParagraph($"${totalAvg:N2}").Style = "TableHeader";
            totalRow.Cells[3].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[4].AddParagraph("-");
            totalRow.Cells[4].Format.Alignment = ParagraphAlignment.Right;
            totalRow.Cells[5].AddParagraph("-");
            totalRow.Cells[5].Format.Alignment = ParagraphAlignment.Right;

            await Task.CompletedTask;
        }

        private void AddTopPerformersSection(Section section, List<Sale> allSales, List<Product> products, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Top Performers (Last 30 Days)");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var now = DateTime.UtcNow;
            var last30Days = allSales.Where(s => s.TransactionDate >= now.AddDays(-30)).ToList();

            // Top 10 Products by Revenue
            var topProductsByRevenue = last30Days
                .GroupBy(s => s.ProductId)
                .Select(g => new
                {
                    ProductId = g.Key,
                    ProductName = products.FirstOrDefault(p => p.Id == g.Key)?.ProductName ?? "Unknown",
                    TotalRevenue = g.Sum(s => s.TotalAmount),
                    OrderCount = g.Count()
                })
                .OrderByDescending(x => x.TotalRevenue)
                .Take(10)
                .ToList();

            // Top Products Table
            var prodHeading = section.AddParagraph("Top 10 Products by Revenue");
            prodHeading.Format.Font.Size = 12;
            prodHeading.Format.Font.Bold = true;
            prodHeading.Format.SpaceBefore = Unit.FromPoint(10);
            prodHeading.Format.SpaceAfter = Unit.FromPoint(5);

            var prodTable = section.AddTable();
            prodTable.Borders.Width = 0.5;
            prodTable.Borders.Color = Colors.LightGray;
            prodTable.AddColumn(Unit.FromCentimeter(1.5));  // Rank
            prodTable.AddColumn(Unit.FromCentimeter(8));    // Product Name
            prodTable.AddColumn(Unit.FromCentimeter(3.5));  // Revenue
            prodTable.AddColumn(Unit.FromCentimeter(3));    // Orders

            var prodHeader = prodTable.AddRow();
            prodHeader.HeadingFormat = true;
            prodHeader.Shading.Color = Colors.LightGray;
            prodHeader.Cells[0].AddParagraph("#").Style = "TableHeader";
            prodHeader.Cells[1].AddParagraph("Product").Style = "TableHeader";
            prodHeader.Cells[2].AddParagraph("Revenue").Style = "TableHeader";
            prodHeader.Cells[3].AddParagraph("Orders").Style = "TableHeader";

            int rank = 1;
            foreach (var item in topProductsByRevenue)
            {
                var row = prodTable.AddRow();
                row.Cells[0].AddParagraph(rank.ToString());
                row.Cells[0].Format.Alignment = ParagraphAlignment.Center;
                row.Cells[1].AddParagraph(item.ProductName);
                row.Cells[2].AddParagraph($"${item.TotalRevenue:N2}");
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[3].AddParagraph(item.OrderCount.ToString());
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;
                rank++;
            }

            section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(20);

            // Top 10 Variants by Quantity Sold
            var topVariantsByQuantity = last30Days
                .GroupBy(s => s.VariantId)
                .Select(g => new
                {
                    VariantId = g.Key,
                    Variant = variants.FirstOrDefault(v => v.Id == g.Key),
                    TotalQuantity = g.Sum(s => s.Quantity),
                    TotalRevenue = g.Sum(s => s.TotalAmount)
                })
                .Where(x => x.Variant != null)
                .OrderByDescending(x => x.TotalQuantity)
                .Take(10)
                .ToList();

            var varHeading = section.AddParagraph("Top 10 Variants by Quantity Sold");
            varHeading.Format.Font.Size = 12;
            varHeading.Format.Font.Bold = true;
            varHeading.Format.SpaceBefore = Unit.FromPoint(10);
            varHeading.Format.SpaceAfter = Unit.FromPoint(5);

            var varTable = section.AddTable();
            varTable.Borders.Width = 0.5;
            varTable.Borders.Color = Colors.LightGray;
            varTable.AddColumn(Unit.FromCentimeter(1.5));  // Rank
            varTable.AddColumn(Unit.FromCentimeter(7));    // Variant Name
            varTable.AddColumn(Unit.FromCentimeter(2.5));  // Quantity
            varTable.AddColumn(Unit.FromCentimeter(3.5));  // Revenue
            varTable.AddColumn(Unit.FromCentimeter(2));    // Stock

            var varHeader = varTable.AddRow();
            varHeader.HeadingFormat = true;
            varHeader.Shading.Color = Colors.LightGray;
            varHeader.Cells[0].AddParagraph("#").Style = "TableHeader";
            varHeader.Cells[1].AddParagraph("Variant").Style = "TableHeader";
            varHeader.Cells[2].AddParagraph("Qty Sold").Style = "TableHeader";
            varHeader.Cells[3].AddParagraph("Revenue").Style = "TableHeader";
            varHeader.Cells[4].AddParagraph("Stock").Style = "TableHeader";

            rank = 1;
            foreach (var item in topVariantsByQuantity)
            {
                var row = varTable.AddRow();
                row.Cells[0].AddParagraph(rank.ToString());
                row.Cells[0].Format.Alignment = ParagraphAlignment.Center;
                row.Cells[1].AddParagraph(item.Variant.VariantName ?? "Unknown");
                row.Cells[2].AddParagraph(item.TotalQuantity.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[3].AddParagraph($"${item.TotalRevenue:N2}");
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[4].AddParagraph(item.Variant.StockQuantity.ToString());
                row.Cells[4].Format.Alignment = ParagraphAlignment.Right;
                
                // Highlight low stock
                if (item.Variant.IsLowStock)
                {
                    row.Cells[4].Format.Font.Color = Colors.Red;
                }
                
                rank++;
            }
        }

        private void AddCustomRangeSummary(Section section, List<Sale> sales, List<Product> products, List<ProductVariant> variants, DateTime startDate, DateTime endDate)
        {
            var heading = section.AddParagraph("Period Summary");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var totalRevenue = sales.Sum(s => s.TotalAmount);
            var totalOrders = sales.Count;
            var avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
            var uniqueProducts = sales.Select(s => s.ProductId).Distinct().Count();
            var uniqueVariants = sales.Select(s => s.VariantId).Distinct().Count();

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(10));
            table.AddColumn(Unit.FromCentimeter(6));

            AddSummaryRow(table, "Date Range:", $"{startDate:MMM dd, yyyy} - {endDate:MMM dd, yyyy}");
            AddSummaryRow(table, "Total Revenue:", $"${totalRevenue:N2}");
            AddSummaryRow(table, "Total Orders:", totalOrders.ToString());
            AddSummaryRow(table, "Average Order Value:", $"${avgOrderValue:N2}");
            AddSummaryRow(table, "Products Sold:", uniqueProducts.ToString());
            AddSummaryRow(table, "Variants Sold:", uniqueVariants.ToString());
            AddSummaryRow(table, "Total Active Products:", products.Count.ToString());
            AddSummaryRow(table, "Total Active Variants:", variants.Count(v => v.IsActive).ToString());
        }

        private void AddCustomRangeProductDetails(Section section, List<Sale> sales, List<Product> products, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Product Performance Details");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var productSales = sales
                .GroupBy(s => s.ProductId)
                .Select(g => new
                {
                    ProductId = g.Key,
                    ProductName = products.FirstOrDefault(p => p.Id == g.Key)?.ProductName ?? "Unknown",
                    TotalRevenue = g.Sum(s => s.TotalAmount),
                    TotalQuantity = g.Sum(s => s.Quantity),
                    OrderCount = g.Count(),
                    VariantsSold = g.Select(s => s.VariantId).Distinct().Count()
                })
                .OrderByDescending(x => x.TotalRevenue)
                .ToList();

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(6));    // Product
            table.AddColumn(Unit.FromCentimeter(3));    // Revenue
            table.AddColumn(Unit.FromCentimeter(2.5));  // Quantity
            table.AddColumn(Unit.FromCentimeter(2.5));  // Orders
            table.AddColumn(Unit.FromCentimeter(2));    // Variants

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            headerRow.Cells[0].AddParagraph("Product").Style = "TableHeader";
            headerRow.Cells[1].AddParagraph("Revenue").Style = "TableHeader";
            headerRow.Cells[2].AddParagraph("Quantity").Style = "TableHeader";
            headerRow.Cells[3].AddParagraph("Orders").Style = "TableHeader";
            headerRow.Cells[4].AddParagraph("Variants").Style = "TableHeader";

            foreach (var item in productSales)
            {
                var row = table.AddRow();
                row.Cells[0].AddParagraph(item.ProductName);
                row.Cells[1].AddParagraph($"${item.TotalRevenue:N2}");
                row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[2].AddParagraph(item.TotalQuantity.ToString());
                row.Cells[2].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[3].AddParagraph(item.OrderCount.ToString());
                row.Cells[3].Format.Alignment = ParagraphAlignment.Right;
                row.Cells[4].AddParagraph(item.VariantsSold.ToString());
                row.Cells[4].Format.Alignment = ParagraphAlignment.Right;
            }
        }

        private void DefineStyles(Document doc)
        {
            var normal = doc.Styles["Normal"];
            normal.Font.Name = "Arial";
            normal.Font.Size = 10;

            var heading1 = doc.Styles.AddStyle("Heading1", "Normal");
            heading1.Font.Bold = true;
            heading1.Font.Size = 14;
            heading1.Font.Color = Color.FromRgb(166, 77, 121);

            var tableHeader = doc.Styles.AddStyle("TableHeader", "Normal");
            tableHeader.Font.Bold = true;
            tableHeader.Font.Size = 10;
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

        // Helper classes for data aggregation
        private class DailySalesData
        {
            public DateTime Date { get; set; }
            public decimal TotalSales { get; set; }
            public int OrderCount { get; set; }
            public int UniqueProducts { get; set; }
            public int UniqueVariants { get; set; }
        }

        private class WeeklySalesData
        {
            public string WeekLabel { get; set; }
            public DateTime StartDate { get; set; }
            public DateTime EndDate { get; set; }
            public decimal TotalSales { get; set; }
            public int OrderCount { get; set; }
            public int UniqueProducts { get; set; }
            public int UniqueVariants { get; set; }
        }

        private class MonthlySalesData
        {
            public string MonthLabel { get; set; }
            public int Year { get; set; }
            public int Month { get; set; }
            public decimal TotalSales { get; set; }
            public int OrderCount { get; set; }
            public int UniqueProducts { get; set; }
            public int UniqueVariants { get; set; }
        }
    }
}
