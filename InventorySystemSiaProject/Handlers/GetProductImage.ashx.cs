
using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetProductImage : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                string productId = context.Request.QueryString["productId"];

                if (string.IsNullOrEmpty(productId))
                {
                    System.Diagnostics.Debug.WriteLine("❌ No productId provided");
                    ReturnPlaceholder(context);
                    return;
                }

                System.Diagnostics.Debug.WriteLine(string.Format("📥 GetProductImage request for productId: {0}", productId));

                var productsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("Products");
                var filter = Builders<BsonDocument>.Filter.Eq("_id", ObjectId.Parse(productId));
                var product = productsCollection.Find(filter).FirstOrDefault();

                if (product == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Product not found");
                    ReturnPlaceholder(context);
                    return;
                }

                // ✅ CRITICAL: Check for productImg field (not productImage)
                if (product.Contains("productImg") && product["productImg"].IsBsonBinaryData)
                {
                    var imageData = product["productImg"].AsBsonBinaryData.Bytes;

                    System.Diagnostics.Debug.WriteLine(string.Format("✅ Found productImg: {0} bytes", imageData.Length));

                    var contentType = product.Contains("ProductImgContentType")
                        ? product["ProductImgContentType"].AsString
                        : "image/png";

                    // ✅ CRITICAL: Disable all caching
                    context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
                    context.Response.Cache.SetNoStore();
                    context.Response.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
                    context.Response.Cache.SetRevalidation(HttpCacheRevalidation.AllCaches);
                    context.Response.AppendHeader("Pragma", "no-cache");
                    context.Response.AppendHeader("Cache-Control", "no-cache, no-store, must-revalidate");
                    context.Response.AppendHeader("Expires", "0");

                    context.Response.ContentType = contentType;
                    context.Response.BinaryWrite(imageData);

                    System.Diagnostics.Debug.WriteLine("✅ Image served successfully");
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("⚠️ Product has no productImg field");
                    ReturnPlaceholder(context);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ GetProductImage Error: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("Stack trace: {0}", ex.StackTrace));
                ReturnPlaceholder(context);
            }
        }

        private void ReturnPlaceholder(HttpContext context)
        {
            context.Response.ContentType = "image/svg+xml";
            context.Response.Write("<svg width='100' height='80' xmlns='http://www.w3.org/2000/svg'><rect width='100' height='80' fill='#f0f0f0'/><text x='50' y='40' font-family='Arial' font-size='10' fill='#999' text-anchor='middle'>No Image</text></svg>");
        }

        public bool IsReusable { get { return false; } }
    }
}