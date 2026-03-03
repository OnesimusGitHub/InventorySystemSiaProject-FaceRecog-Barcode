using System;
using System.Web;
using System.Web.SessionState;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class DownloadProductReportPdf : HttpTaskAsyncHandler, IRequiresSessionState
    {
        public override bool IsReusable => false;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            // Always set plain text temporarily; will change for PDF.
            try
            {
                // Basic auth / session
                if (context.Session == null)
                {
                    context.Response.StatusCode = 403;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("Forbidden: no session").ConfigureAwait(false);
                    return;
                }
                var role = context.Session["UserRole"] as string;
                if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
                {
                    context.Response.StatusCode = 403;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("Forbidden: not admin").ConfigureAwait(false);
                    return;
                }

                var productId = context.Request.QueryString["productId"];
                if (string.IsNullOrWhiteSpace(productId))
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("Missing productId").ConfigureAwait(false);
                    return;
                }

                DatabaseHelper.EnsureSalesIndexes();

                var productsCol = DatabaseHelper.GetProductsCollection();
                var product = await productsCol.Find(p => p.Id == productId).FirstOrDefaultAsync().ConfigureAwait(false);
                if (product == null)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("Product not found").ConfigureAwait(false);
                    return;
                }

                bool debug = string.Equals(context.Request.QueryString["debug"], "1");
                var salesService = new SalesService();
                var now = DateTime.UtcNow;

                if (debug)
                {
                    // Debug path - gather aggregations asynchronously
                    var dailyTask = salesService.GetSingleProductAggregatedAsync(productId, ProductReportGranularity.Daily, now.AddDays(-7), now);
                    var weeklyTask = salesService.GetSingleProductAggregatedAsync(productId, ProductReportGranularity.Weekly, now.AddDays(-56), now);
                    var monthlyTask = salesService.GetSingleProductAggregatedAsync(productId, ProductReportGranularity.Monthly, new DateTime(now.Year,1,1,0,0,0,DateTimeKind.Utc), now);
                    await Task.WhenAll(dailyTask, weeklyTask, monthlyTask).ConfigureAwait(false);

                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("DEBUG PRODUCT SALES REPORT\nProduct: " + product.productName + " (" + productId + ")\nGenerated UTC: " + now.ToString("u") + "\n\n").ConfigureAwait(false);
                    async Task WriteBlock(string title, System.Collections.Generic.List<ProductSalesAggregation> list)
                    {
                        await context.Response.Output.WriteAsync(title + " (rows=" + list.Count + ")\n").ConfigureAwait(false);
                        foreach (var r in list)
                        {
                            await context.Response.Output.WriteAsync(r.PeriodLabel + " | Qty=" + r.TotalQuantity + " | Gross=" + r.GrossAmount + " | Net=" + r.NetAmount + "\n").ConfigureAwait(false);
                        }
                        await context.Response.Output.WriteAsync("--\n").ConfigureAwait(false);
                    }
                    await WriteBlock("DAILY", dailyTask.Result).ConfigureAwait(false);
                    await WriteBlock("WEEKLY", weeklyTask.Result).ConfigureAwait(false);
                    await WriteBlock("MONTHLY", monthlyTask.Result).ConfigureAwait(false);
                    return;
                }

                // PDF path
                var pdfService = new ProductReportPdfService();
                var pdfBytes = await pdfService.GenerateSingleProductReportPdfAsync(productId, product.productName).ConfigureAwait(false);
                if (pdfBytes == null || pdfBytes.Length < 20)
                {
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("PDF generation returned empty output (length=" + (pdfBytes==null?0:pdfBytes.Length) + ") – try ?debug=1").ConfigureAwait(false);
                    return;
                }

                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
                context.Response.Cache.SetNoStore();
                var safeName = string.Join("_", (product.productName ?? "Product").Split(System.IO.Path.GetInvalidFileNameChars()));
                context.Response.AddHeader("Content-Disposition", $"attachment; filename=ProductReport_{safeName}_{DateTime.UtcNow:yyyyMMddHHmm}.pdf");
                context.Response.AddHeader("X-Pdf-Length", pdfBytes.Length.ToString());
                await context.Response.OutputStream.WriteAsync(pdfBytes, 0, pdfBytes.Length).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                try
                {
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("Handler error: " + ex.Message + "\n" + ex.StackTrace).ConfigureAwait(false);
                }
                catch { }
            }
        }
    }
}