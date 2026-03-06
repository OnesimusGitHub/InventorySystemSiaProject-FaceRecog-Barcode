using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
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
                string indexStr  = context.Request.QueryString["index"];

                if (string.IsNullOrEmpty(variantId))
                {
                    context.Response.StatusCode = 400;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Variant ID is required");
                    return;
                }

                int imageIndex = 0;
                if (!string.IsNullOrEmpty(indexStr))
                    int.TryParse(indexStr, out imageIndex);
                if (imageIndex < 0) imageIndex = 0;

                // ── Load raw BsonDocument (avoids List<byte[]> deserialisation crash) ──
                var col = DatabaseHelper.Database.GetCollection<BsonDocument>(
                    DatabaseHelper.GetProductVariantsCollectionName());

                BsonDocument doc = null;

                // Try ObjectId first
                try
                {
                    var oid = ObjectId.Parse(variantId);
                    doc = col.Find(Builders<BsonDocument>.Filter.Eq("_id", oid))
                             .FirstOrDefault();
                }
                catch { /* not a valid ObjectId */ }

                // Fallback: string _id
                if (doc == null)
                    doc = col.Find(Builders<BsonDocument>.Filter.Eq("_id", variantId))
                             .FirstOrDefault();

                if (doc == null)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Variant not found");
                    return;
                }

                // ── Extract image bytes from variantImgUrls[index] ──────────────
                byte[] imageData = null;

                BsonValue arrayVal;
                if (doc.TryGetValue("variantImgUrls", out arrayVal) && arrayVal.IsBsonArray)
                {
                    var arr = arrayVal.AsBsonArray;
                    if (imageIndex < arr.Count)
                    {
                        var entry = arr[imageIndex];

                        // Case 1 — element is raw Binary
                        if (entry.BsonType == BsonType.Binary)
                        {
                            imageData = entry.AsBsonBinaryData.Bytes;
                        }
                        // Case 2 — element is a sub-document { "imageData": <binary>, ... }
                        else if (entry.IsBsonDocument)
                        {
                            BsonValue inner;
                            var sub = entry.AsBsonDocument;
                            if (sub.TryGetValue("imageData", out inner) && inner.BsonType == BsonType.Binary)
                                imageData = inner.AsBsonBinaryData.Bytes;
                            else if (sub.TryGetValue("data", out inner) && inner.BsonType == BsonType.Binary)
                                imageData = inner.AsBsonBinaryData.Bytes;
                        }
                    }
                }

                if (imageData == null || imageData.Length == 0)
                {
                    context.Response.StatusCode = 404;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Image data not found");
                    return;
                }

                string contentType = DetectImageMimeType(imageData);

                context.Response.Clear();
                context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
                context.Response.Cache.SetNoStore();
                context.Response.Cache.SetMaxAge(TimeSpan.Zero);
                context.Response.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
                context.Response.AddHeader("Pragma", "no-cache");
                context.Response.AddHeader("Cache-Control", "no-cache, no-store, must-revalidate");
                context.Response.ContentType = contentType;
                context.Response.BinaryWrite(imageData);
                context.Response.Flush();
            }
            catch (Exception ex)
            {
                try
                {
                    context.Response.Clear();
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "text/plain";
                    context.Response.Write("Error: " + ex.Message);
                }
                catch (HttpException) { /* headers already sent */ }

                System.Diagnostics.Trace.TraceError("GetVariantImage.ProcessRequest error: " + ex);
            }
        }

        private static string DetectImageMimeType(byte[] bytes)
        {
            if (bytes == null || bytes.Length < 4) return "application/octet-stream";
            if (bytes[0] == 0xFF && bytes[1] == 0xD8)                                         return "image/jpeg";
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return "image/png";
            if (bytes[0] == (byte)'G' && bytes[1] == (byte)'I' && bytes[2] == (byte)'F')      return "image/gif";
            if (bytes[0] == (byte)'B' && bytes[1] == (byte)'M')                               return "image/bmp";
            return "application/octet-stream";
        }

        public bool IsReusable => false;
    }
}