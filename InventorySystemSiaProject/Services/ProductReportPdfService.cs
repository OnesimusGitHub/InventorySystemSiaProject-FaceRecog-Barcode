using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using MigraDoc.DocumentObjectModel;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.Rendering;

namespace InventorySystemSiaProject.Services
{
    /// <summary>
    /// Generates a PDF report (daily, weekly, monthly) for a single product.
    /// </summary>
    public class ProductReportPdfService
    {
        private readonly SalesService _salesService = new SalesService();

        public async Task<byte[]> GenerateSingleProductReportPdfAsync(string productId, string productName)
        {
            if (string.IsNullOrWhiteSpace(productId)) return new byte[0];
            var now = DateTime.UtcNow;

            // time windows
            var dailyStart = now.Date.AddDays(-7); // last 7 days
            var weeklyStart = now.Date.AddDays(-56); // last 8 weeks
            var monthlyStart = new DateTime(now.Year, 1, 1, 0, 0, 0, DateTimeKind.Utc);

            var daily = await _salesService.GetSingleProductAggregatedAsync(productId, ProductReportGranularity.Daily, dailyStart, now);
            var weekly = await _salesService.GetSingleProductAggregatedAsync(productId, ProductReportGranularity.Weekly, weeklyStart, now);
            var monthly = await _salesService.GetSingleProductAggregatedAsync(productId, ProductReportGranularity.Monthly, monthlyStart, now);

            var doc = new Document();
            doc.Info.Title = "Product Sales Report";
            doc.Info.Subject = "Daily / Weekly / Monthly product sales";
            doc.Info.Author = "InventorySystem";
            DefineStyles(doc);

            var section = doc.AddSection();
            section.PageSetup.TopMargin = Unit.FromCentimeter(1.5);
            section.PageSetup.LeftMargin = Unit.FromCentimeter(1.5);
            section.PageSetup.RightMargin = Unit.FromCentimeter(1.5);

            var title = section.AddParagraph($"Product Sales Report - {productName}");
            title.Format.Font.Size = 16;
            title.Format.Font.Bold = true;
            title.Format.SpaceAfter = Unit.FromPoint(6);

            var info = section.AddParagraph("Generated (UTC): " + now.ToString("yyyy-MM-dd HH:mm"));
            info.Format.Font.Size = 9;
            info.Format.SpaceAfter = Unit.FromPoint(10);

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

        private void DefineStyles(Document doc)
        {
            var normal = doc.Styles["Normal"];
            normal.Font.Name = "Arial";
            normal.Font.Size = 9;
            var header = doc.Styles.AddStyle("TableHeader", "Normal");
            header.Font.Bold = true; header.Font.Size = 9;
            var footer = doc.Styles.AddStyle("TableFooter", "Normal");
            footer.Font.Bold = true; footer.Font.Size = 9;
        }

        private void AddBlock(Section section, string heading, List<ProductSalesAggregation> rows)
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
            table.AddColumn(Unit.FromCentimeter(3.0)); // Period
            table.AddColumn(Unit.FromCentimeter(2.0)); // Qty
            table.AddColumn(Unit.FromCentimeter(3.0)); // Gross
            table.AddColumn(Unit.FromCentimeter(3.0)); // Net

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

        private void SetCell(Row row, int idx, string text, string style = null, ParagraphAlignment alignment = ParagraphAlignment.Left)
        {
            var p = row.Cells[idx].AddParagraph(text ?? string.Empty);
            p.Format.Alignment = alignment;
            if (!string.IsNullOrEmpty(style)) p.Style = style;
        }
    }
}
