using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.SessionState;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;
using MongoDB.Bson;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Handlers
{
    public class DownloadProductReportPdf : HttpTaskAsyncHandler, IRequiresSessionState
    {
        public override bool IsReusable => false;

        public override async Task ProcessRequestAsync(HttpContext context)
        {
            try
            {
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

                var productsCol = DatabaseHelper.GetProductsCollection();
                var product = await productsCol.Find(p => p.Id == productId)
                    .FirstOrDefaultAsync().ConfigureAwait(false);
                if (product == null)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync("Product not found").ConfigureAwait(false);
                    return;
                }

                // Load variant IDs so the PDF service can match tbl_order items
                var variantIds = new List<string>();
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
                    variantIds = vDocs.Select(d => d["_id"].ToString()).ToList();
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[DownloadProductReportPdf] Variant load warning: " + ex.Message);
                }

                var pdfService = new ProductReportPdfService();
                var pdfBytes = await pdfService.GenerateSingleProductReportPdfAsync(
                    productId, product.productName, variantIds).ConfigureAwait(false);

                if (pdfBytes == null || pdfBytes.Length < 20)
                {
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync(
                        "PDF generation returned empty output (length=" +
                        (pdfBytes == null ? 0 : pdfBytes.Length) + ")").ConfigureAwait(false);
                    return;
                }

                context.Response.Clear();
                context.Response.ContentType = "application/pdf";
                context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
                context.Response.Cache.SetNoStore();
                var safeName = string.Join("_",
                    (product.productName ?? "Product").Split(System.IO.Path.GetInvalidFileNameChars()));
                context.Response.AddHeader("Content-Disposition",
                    "attachment; filename=ProductReport_" + safeName + "_" +
                    DateTime.UtcNow.ToString("yyyyMMddHHmm") + ".pdf");
                context.Response.AddHeader("X-Pdf-Length", pdfBytes.Length.ToString());
                await context.Response.OutputStream.WriteAsync(pdfBytes, 0, pdfBytes.Length)
                    .ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                try
                {
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "text/plain";
                    await context.Response.Output.WriteAsync(
                        "Handler error: " + ex.Message + "\n" + ex.StackTrace).ConfigureAwait(false);
                }
                catch { }
            }
        }
    }
}