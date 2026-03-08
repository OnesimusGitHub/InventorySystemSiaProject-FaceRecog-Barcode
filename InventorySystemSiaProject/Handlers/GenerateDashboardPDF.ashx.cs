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
    public class GenerateDashboardPDF : HttpTaskAsyncHandler
    {
        private ProductService _productService;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
                _productService = new ProductService();

                string reportType = context.Request.QueryString["type"] ?? "standard";
                string category = context.Request.QueryString["category"];
                byte[] pdfBytes;

                if (reportType == "standard")
                {
                    string period = context.Request.QueryString["period"] ?? "monthly";
                    pdfBytes = await GenerateStandardReportAsync(period, category);
                }
                else
                {
                    string startDateStr = context.Request.QueryString["startDate"];
                    string endDateStr = context.Request.QueryString["endDate"];
                    DateTime startDate = DateTime.Parse(startDateStr);
                    DateTime endDate = DateTime.Parse(endDateStr);
                    pdfBytes = await GenerateCustomReportAsync(startDate, endDate, category);
                }

                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                string fileName = string.IsNullOrEmpty(category)
                    ? "Dashboard_Report_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".pdf"
                    : "Dashboard_" + category + "_Report_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".pdf";
                context.Response.AddHeader("Content-Disposition", "attachment; filename=" + fileName);
                context.Response.BinaryWrite(pdfBytes);
                context.Response.End();
            }
            catch (Exception ex)
            {
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error: " + ex.Message);
            }
        }

        // ── tbl_order row DTO ─────────────────────────────────────────────────
        private class OrderRow
        {
            public DateTime Date { get; set; }
            public decimal Amount { get; set; }
            public int Quantity { get; set; }
            public List<string> ProductIds { get; set; }
            public OrderRow() { ProductIds = new List<string>(); }
        }

        // ── Read paid orders from db_shessentials.tbl_order ──────────────────
        private static async Task<List<OrderRow>> LoadOrderRowsAsync(string categoryFilter = null)
        {
            var result = new List<OrderRow>();
            try
            {
                var col = DatabaseHelper.GetOrdersCollection();
                var filter = Builders<BsonDocument>.Filter.In(
                    "payment_status", new[] { "Paid", "paid", "PAID" });
                var orders = await col.Find(filter).ToListAsync().ConfigureAwait(false);

                // Build category → productId lookup if filtering by category
                HashSet<string> categoryVariantIds = null;
                if (!string.IsNullOrWhiteSpace(categoryFilter))
                    categoryVariantIds = await BuildCategoryVariantIdSetAsync(categoryFilter).ConfigureAwait(false);

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

                    var productIds = new List<string>();
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
                            if (string.IsNullOrWhiteSpace(pid)) continue;
                            if (categoryVariantIds != null && !categoryVariantIds.Contains(pid)) continue;

                            productIds.Add(pid);
                            BsonValue qv;
                            int itemQty = 1;
                            if (itemDoc.TryGetValue("quantity", out qv))
                                itemQty = Math.Max(1, (int)BsonToDecimal(qv));
                            quantity += itemQty;
                        }
                    }

                    if (categoryVariantIds != null && productIds.Count == 0) continue;

                    result.Add(new OrderRow
                    {
                        Date = (hasDate ? orderDate : DateTime.UtcNow).ToLocalTime(),
                        Amount = amount,
                        Quantity = quantity,
                        ProductIds = productIds
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[GenerateDashboardPDF] LoadOrderRowsAsync ERROR: " + ex.Message);
            }
            return result;
        }

        /// <summary>Builds the set of variant IDs that belong to the given category.</summary>
        private static async Task<HashSet<string>> BuildCategoryVariantIdSetAsync(string category)
        {
            var set = new HashSet<string>();
            try
            {
                var productsCol = DatabaseHelper.GetProductsCollection();
                var products = await productsCol
                    .Find(Builders<Product>.Filter.Eq(p => p.productCategory, category))
                    .ToListAsync().ConfigureAwait(false);
                var productIds = products.Select(p => p.Id).ToList();
                if (productIds.Count == 0) return set;

                var variantsCol = DatabaseHelper.GetProductVariantsCollection();
                var variants = await variantsCol
                    .Find(Builders<ProductVariant>.Filter.In(v => v.ProductId, productIds))
                    .Project(Builders<ProductVariant>.Projection.Include(v => v.Id))
                    .As<BsonDocument>()
                    .ToListAsync().ConfigureAwait(false);
                foreach (var d in variants) set.Add(d["_id"].ToString());
                // Also include productIds directly in case items store product_id rather than variant_id
                foreach (var pid in productIds) set.Add(pid);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[GenerateDashboardPDF] BuildCategoryVariantIdSetAsync ERROR: " + ex.Message);
            }
            return set;
        }

        // ── Standard report (daily / weekly / monthly) ───────────────────────
        private async Task<byte[]> GenerateStandardReportAsync(string period, string category = null)
        {
            var orderRows = await LoadOrderRowsAsync(category).ConfigureAwait(false);
            var products = await _productService.GetAllProductsAsync().ConfigureAwait(false);
            var variants = await _productService.GetAllProductVariantsAsync().ConfigureAwait(false);

            if (!string.IsNullOrEmpty(category))
            {
                products = products.Where(p => p.productCategory == category).ToList();
                var catProductIds = new HashSet<string>(products.Select(p => p.Id));
                variants = variants.Where(v => catProductIds.Contains(v.ProductId)).ToList();
            }

            var doc = new Document();
            doc.Info.Title = string.IsNullOrEmpty(category)
                ? "Dashboard Sales Report - All Periods"
                : "Dashboard Sales Report - " + category + " - All Periods";
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            var title = section.AddParagraph(string.IsNullOrEmpty(category)
                ? "Dashboard Sales Report"
                : "Dashboard Sales Report - " + category);
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

            var srcNote = section.AddParagraph("Sales Report");
            srcNote.Format.Font.Size = 8;
            srcNote.Format.Font.Italic = true;
            srcNote.Format.Alignment = ParagraphAlignment.Center;
            srcNote.Format.SpaceAfter = Unit.FromPoint(5);

            if (!string.IsNullOrEmpty(category))
            {
                var catInfo = section.AddParagraph("Category: " + category);
                catInfo.Format.Font.Size = 10;
                catInfo.Format.Alignment = ParagraphAlignment.Center;
                catInfo.Format.SpaceAfter = Unit.FromPoint(5);
            }

            var dateInfo = section.AddParagraph("Generated: " + DateTime.Now.ToString("MMM dd, yyyy HH:mm"));
            dateInfo.Format.Font.Size = 9;
            dateInfo.Format.Alignment = ParagraphAlignment.Center;
            dateInfo.Format.SpaceAfter = Unit.FromPoint(20);

            AddSummarySection(section, orderRows, products, variants);
            AddProductListTable(section, products, variants);
            section.AddPageBreak();
            AddPeriodReport(section, orderRows, "Daily", "Last 7 Days");
            section.AddPageBreak();
            AddPeriodReport(section, orderRows, "Weekly", "Last 4 Weeks");
            section.AddPageBreak();
            AddPeriodReport(section, orderRows, "Monthly", "Last 12 Months");

            return RenderDocument(doc);
        }

        private void AddPeriodReport(Section section, List<OrderRow> orderRows,
            string periodName, string periodDescription)
        {
            var periodTitle = section.AddParagraph(periodName + " Sales Report");
            periodTitle.Format.Font.Size = 16;
            periodTitle.Format.Font.Bold = true;
            periodTitle.Format.Font.Color = Color.FromRgb(166, 77, 121);
            periodTitle.Format.SpaceBefore = Unit.FromPoint(10);
            periodTitle.Format.SpaceAfter = Unit.FromPoint(5);

            var periodSubtitle = section.AddParagraph(periodDescription);
            periodSubtitle.Format.Font.Size = 10;
            periodSubtitle.Format.Font.Italic = true;
            periodSubtitle.Format.SpaceAfter = Unit.FromPoint(15);

            var aggregatedData = AggregateSalesByPeriod(orderRows, periodName);

            if (aggregatedData.Count == 0)
            {
                var noData = section.AddParagraph("No sales data available for this period.");
                noData.Format.Font.Italic = true;
                noData.Format.SpaceAfter = Unit.FromPoint(20);
                return;
            }

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(5));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(3));

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "Period", "TableHeader");
            SetCell(headerRow, 1, "Total Sales", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 2, "Orders", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 3, "Avg Value", "TableHeader", ParagraphAlignment.Right);

            decimal grandTotal = 0;
            int totalOrders = 0;

            foreach (var item in aggregatedData)
            {
                var row = table.AddRow();
                SetCell(row, 0, item.PeriodLabel);
                SetCell(row, 1, string.Format("₱{0:N2}", item.TotalSales), alignment: ParagraphAlignment.Right);
                SetCell(row, 2, item.OrderCount.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 3, string.Format("₱{0:N2}", item.AverageOrderValue), alignment: ParagraphAlignment.Right);
                grandTotal += item.TotalSales;
                totalOrders += item.OrderCount;
            }

            var totalRow = table.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(totalRow, 0, "TOTAL", "TableHeader");
            SetCell(totalRow, 1, string.Format("₱{0:N2}", grandTotal), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 2, totalOrders.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 3, string.Format("₱{0:N2}", totalOrders > 0 ? grandTotal / totalOrders : 0), "TableHeader", ParagraphAlignment.Right);

            section.AddParagraph().Format.SpaceAfter = Unit.FromPoint(20);
        }

        private class PeriodSalesData
        {
            public string PeriodLabel { get; set; }
            public decimal TotalSales { get; set; }
            public int OrderCount { get; set; }
            public decimal AverageOrderValue { get; set; }
        }

        private List<PeriodSalesData> AggregateSalesByPeriod(List<OrderRow> rows, string periodName)
        {
            var result = new List<PeriodSalesData>();
            var now = DateTime.Now.Date;

            switch (periodName.ToLower())
            {
                case "daily":
                    for (int i = 6; i >= 0; i--)
                    {
                        var date = now.AddDays(-i);
                        var dayRows = rows.Where(r => r.Date.Date == date).ToList();
                        result.Add(new PeriodSalesData
                        {
                            PeriodLabel = date.ToString("MMM dd, yyyy"),
                            TotalSales = dayRows.Sum(r => r.Amount),
                            OrderCount = dayRows.Count,
                            AverageOrderValue = dayRows.Count > 0 ? dayRows.Sum(r => r.Amount) / dayRows.Count : 0
                        });
                    }
                    break;

                case "weekly":
                    var weekStartRef = now.AddDays(-(int)now.DayOfWeek);
                    for (int i = 3; i >= 0; i--)
                    {
                        var weekStart = weekStartRef.AddDays(-7 * i);
                        var weekEnd = weekStart.AddDays(6);
                        var weekRows = rows.Where(r => r.Date.Date >= weekStart && r.Date.Date <= weekEnd).ToList();
                        result.Add(new PeriodSalesData
                        {
                            PeriodLabel = "Week of " + weekStart.ToString("MMM dd"),
                            TotalSales = weekRows.Sum(r => r.Amount),
                            OrderCount = weekRows.Count,
                            AverageOrderValue = weekRows.Count > 0 ? weekRows.Sum(r => r.Amount) / weekRows.Count : 0
                        });
                    }
                    break;

                case "monthly":
                    for (int i = 11; i >= 0; i--)
                    {
                        var month = now.AddMonths(-i);
                        var monthRows = rows.Where(r => r.Date.Year == month.Year && r.Date.Month == month.Month).ToList();
                        result.Add(new PeriodSalesData
                        {
                            PeriodLabel = month.ToString("MMMM yyyy"),
                            TotalSales = monthRows.Sum(r => r.Amount),
                            OrderCount = monthRows.Count,
                            AverageOrderValue = monthRows.Count > 0 ? monthRows.Sum(r => r.Amount) / monthRows.Count : 0
                        });
                    }
                    break;
            }

            return result;
        }

        // ── Custom date range report ──────────────────────────────────────────
        private async Task<byte[]> GenerateCustomReportAsync(DateTime startDate, DateTime endDate,
            string category = null)
        {
            var allRows = await LoadOrderRowsAsync(category).ConfigureAwait(false);
            var rowsInRange = allRows
                .Where(r => r.Date.Date >= startDate.Date && r.Date.Date <= endDate.Date)
                .ToList();

            var products = await _productService.GetAllProductsAsync().ConfigureAwait(false);
            var variants = await _productService.GetAllProductVariantsAsync().ConfigureAwait(false);

            if (!string.IsNullOrEmpty(category))
            {
                products = products.Where(p => p.productCategory == category).ToList();
                var catIds = new HashSet<string>(products.Select(p => p.Id));
                variants = variants.Where(v => catIds.Contains(v.ProductId)).ToList();
            }

            var doc = new Document();
            doc.Info.Title = string.IsNullOrEmpty(category)
                ? "Custom Dashboard Report"
                : "Custom Dashboard Report - " + category;
            doc.Info.Author = "BELLE Inventory System";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(2);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(2);
            section.PageSetup.RightMargin = Unit.FromCentimeter(2);

            var titleText = string.IsNullOrEmpty(category)
                ? "Custom Report: " + startDate.ToString("MMM dd, yyyy") + " - " + endDate.ToString("MMM dd, yyyy")
                : "Custom Report - " + category + ": " + startDate.ToString("MMM dd, yyyy") + " - " + endDate.ToString("MMM dd, yyyy");

            var title = section.AddParagraph(titleText);
            title.Format.Font.Size = 18;
            title.Format.Font.Bold = true;
            title.Format.Font.Color = Colors.White;
            title.Format.Shading.Color = Color.FromRgb(166, 77, 121);
            title.Format.Alignment = ParagraphAlignment.Center;
            title.Format.SpaceBefore = Unit.FromPoint(10);
            title.Format.SpaceAfter = Unit.FromPoint(10);

            var srcNote = section.AddParagraph("Sales Report");
            srcNote.Format.Font.Size = 8;
            srcNote.Format.Font.Italic = true;
            srcNote.Format.Alignment = ParagraphAlignment.Center;
            srcNote.Format.SpaceAfter = Unit.FromPoint(5);

            var dateInfo = section.AddParagraph("Generated: " + DateTime.Now.ToString("MMM dd, yyyy HH:mm"));
            dateInfo.Format.Font.Size = 9;
            dateInfo.Format.SpaceAfter = Unit.FromPoint(20);

            AddSummarySection(section, rowsInRange, products, variants);
            AddProductListTable(section, products, variants);

            // Daily breakdown within the custom range
            section.AddPageBreak();
            AddCustomRangeBreakdown(section, rowsInRange, startDate, endDate);

            return RenderDocument(doc);
        }

        private void AddCustomRangeBreakdown(Section section, List<OrderRow> rows,
            DateTime startDate, DateTime endDate)
        {
            var heading = section.AddParagraph("Daily Breakdown");
            heading.Style = "Heading1";
            heading.Format.SpaceAfter = Unit.FromPoint(15);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(5));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(3));

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "Date", "TableHeader");
            SetCell(headerRow, 1, "Total Sales", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 2, "Orders", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 3, "Avg Value", "TableHeader", ParagraphAlignment.Right);

            decimal grandTotal = 0;
            int grandOrders = 0;

            for (var day = startDate.Date; day <= endDate.Date; day = day.AddDays(1))
            {
                var dayRows = rows.Where(r => r.Date.Date == day).ToList();
                decimal total = dayRows.Sum(r => r.Amount);
                int count = dayRows.Count;
                decimal avg = count > 0 ? total / count : 0;

                var row = table.AddRow();
                SetCell(row, 0, day.ToString("MMM dd, yyyy"));
                SetCell(row, 1, string.Format("₱{0:N2}", total), alignment: ParagraphAlignment.Right);
                SetCell(row, 2, count.ToString(), alignment: ParagraphAlignment.Right);
                SetCell(row, 3, string.Format("₱{0:N2}", avg), alignment: ParagraphAlignment.Right);

                grandTotal += total;
                grandOrders += count;
            }

            var totalRow = table.AddRow();
            totalRow.Shading.Color = Color.FromRgb(245, 245, 245);
            SetCell(totalRow, 0, "TOTAL", "TableHeader");
            SetCell(totalRow, 1, string.Format("₱{0:N2}", grandTotal), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 2, grandOrders.ToString(), "TableHeader", ParagraphAlignment.Right);
            SetCell(totalRow, 3, string.Format("₱{0:N2}", grandOrders > 0 ? grandTotal / grandOrders : 0), "TableHeader", ParagraphAlignment.Right);
        }

        // ── PDF helpers ───────────────────────────────────────────────────────
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

        private void AddSummarySection(Section section, List<OrderRow> rows,
            List<Product> products, List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Sales Report Summary");
            heading.Style = "Heading1";
            heading.Format.SpaceBefore = Unit.FromPoint(10);
            heading.Format.SpaceAfter = Unit.FromPoint(10);

            decimal totalSales = rows.Sum(r => r.Amount);
            int totalOrders = rows.Count;
            int totalProducts = products.Count;
            int lowStock = variants.Count(v => v.StockQuantity <= v.MinimumStock);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(8));
            table.AddColumn(Unit.FromCentimeter(6));

            AddSummaryRow(table, "Total Sales:", string.Format("₱{0:N2}", totalSales));
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
            row.Cells[1].Format.Alignment = ParagraphAlignment.Right;
        }

        private void AddProductListTable(Section section, List<Product> products,
            List<ProductVariant> variants)
        {
            var heading = section.AddParagraph("Product List");
            heading.Style = "Heading1";
            heading.Format.SpaceBefore = Unit.FromPoint(10);
            heading.Format.SpaceAfter = Unit.FromPoint(10);

            var table = section.AddTable();
            table.Borders.Width = 0.5;
            table.Borders.Color = Colors.LightGray;
            table.AddColumn(Unit.FromCentimeter(1.5));
            table.AddColumn(Unit.FromCentimeter(8));
            table.AddColumn(Unit.FromCentimeter(3));
            table.AddColumn(Unit.FromCentimeter(2.5));

            var headerRow = table.AddRow();
            headerRow.HeadingFormat = true;
            headerRow.Shading.Color = Colors.LightGray;
            SetCell(headerRow, 0, "#", "TableHeader");
            SetCell(headerRow, 1, "Product Name", "TableHeader");
            SetCell(headerRow, 2, "Stock Qty", "TableHeader", ParagraphAlignment.Right);
            SetCell(headerRow, 3, "Status", "TableHeader");

            int index = 1;
            foreach (var product in products.Take(15))
            {
                var productVariants = variants.Where(v => v.ProductId == product.Id).ToList();
                var stockQty = productVariants.Sum(v => v.StockQuantity);
                var minStock = productVariants.Sum(v => v.MinimumStock);
                var status = stockQty <= minStock ? "Low Stock" : "Normal";

                var row = table.AddRow();
                SetCell(row, 0, index.ToString());
                SetCell(row, 1, product.productName ?? "");
                SetCell(row, 2, stockQty.ToString(), alignment: ParagraphAlignment.Right);
                var statusPara = row.Cells[3].AddParagraph(status);
                if (status == "Low Stock") { statusPara.Format.Font.Color = Colors.Red; statusPara.Format.Font.Bold = true; }
                index++;
            }
        }

        private void SetCell(Row row, int idx, string text,
            string style = null, ParagraphAlignment alignment = ParagraphAlignment.Left)
        {
            var p = row.Cells[idx].AddParagraph(text ?? string.Empty);
            p.Format.Alignment = alignment;
            if (!string.IsNullOrEmpty(style)) p.Style = style;
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
                if (val.BsonType == BsonType.String) { decimal d; if (decimal.TryParse(val.AsString, out d)) return d; }
            }
            catch { }
            return 0;
        }
    }
}