using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetVariantImage : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                string variantId = context.Request.QueryString["variantId"];
                string indexStr = context.Request.QueryString["index"];

                if (string.IsNullOrEmpty(variantId))
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Variant ID is required");
                    return;
                }

                int imageIndex = 0;
                if (!string.IsNullOrEmpty(indexStr) && !int.TryParse(indexStr, out imageIndex))
                {
                    imageIndex = 0;
                }

                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();

                // Accept both ObjectId and string id formats
                ProductVariant variant = null;
                try
                {
                    var filterByObjectId = Builders<ProductVariant>.Filter.Eq("_id", ObjectId.Parse(variantId));
                    variant = variantsCollection.Find(filterByObjectId).FirstOrDefault();
                }
                catch
                {
                    // ignore parse error
                }

                if (variant == null)
                {
                    // try by string id field
                    var filterByString = Builders<ProductVariant>.Filter.Eq(p => p.Id, variantId);
                    variant = variantsCollection.Find(filterByString).FirstOrDefault();
                }

                if (variant == null)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Variant not found");
                    return;
                }

                if (variant.VariantImgUrls == null || variant.VariantImgUrls.Count == 0)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("No images found");
                    return;
                }

                if (imageIndex < 0 || imageIndex >= variant.VariantImgUrls.Count)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Image index out of range");
                    return;
                }

                byte[] imageData = variant.VariantImgUrls[imageIndex];

                if (imageData == null || imageData.Length == 0)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Image data not found");
                    return;
                }

                // Detect mime type from bytes
                string contentType = DetectImageMimeType(imageData);

                // Prepare response headers (no Response.End)
                context.Response.Clear();
                context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
                context.Response.Cache.SetNoStore();
                context.Response.Cache.SetMaxAge(TimeSpan.Zero);
                context.Response.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
                context.Response.AddHeader("Pragma", "no-cache");
                context.Response.AddHeader("Cache-Control", "no-cache, no-store, must-revalidate");

                context.Response.ContentType = contentType;
                context.Response.BinaryWrite(imageData);

                // Avoid Response.End (which throws ThreadAbortException). Flush and return.
                context.Response.Flush();
                return;
            }
            catch (Exception ex)
            {
                // Try to send a 500 response only if possible. If headers already sent, Clear()/StatusCode will throw,
                // so catch HttpException and fall back to server-side logging.
                try
                {
                    context.Response.Clear();
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Error: " + ex.Message);
                }
                catch (HttpException)
                {
                    // Headers already sent - cannot modify response; just log server-side.
                }

                System.Diagnostics.Trace.TraceError("GetVariantImage.ProcessRequest error: " + ex.ToString());
            }
        }

        private static string DetectImageMimeType(byte[] bytes)
        {
            if (bytes == null || bytes.Length < 4) return "application/octet-stream";
            if (bytes[0] == 0xFF && bytes[1] == 0xD8) return "image/jpeg";
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return "image/png";
            if (bytes[0] == (byte)'G' && bytes[1] == (byte)'I' && bytes[2] == (byte)'F') return "image/gif";
            if (bytes[0] == (byte)'B' && bytes[1] == (byte)'M') return "image/bmp";
            return "application/octet-stream";
        }

        public bool IsReusable => false;
    }
}