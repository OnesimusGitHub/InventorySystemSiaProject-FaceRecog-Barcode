<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ProductImage" %>

using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using System.Configuration;

namespace InventorySystemSiaProject.Handlers
{
    public class ProductImage : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            string productId = context.Request["productId"];
            if (string.IsNullOrEmpty(productId))
            {
                context.Response.ContentType = "image/png";
                context.Response.BinaryWrite(GetDefaultImage());
                return;
            }

            byte[] imageBytes = null;
            string contentType = "image/png";

            try
            {
                // MongoDB connection using web.config keys
                var mongoConnStr = ConfigurationManager.ConnectionStrings["MongoDBConnection"].ConnectionString;
                var dbName = ConfigurationManager.AppSettings["MongoDBDatabase"] ?? "InventorySystemDB";
                var collectionName = ConfigurationManager.AppSettings["ProductsCollection"] ?? "Products";
                var client = new MongoClient(mongoConnStr);
                var db = client.GetDatabase(dbName);
                var products = db.GetCollection<BsonDocument>(collectionName);

                var filter = Builders<BsonDocument>.Filter.Eq("_id", ObjectId.Parse(productId));
                var product = products.Find(filter).FirstOrDefault();
                if (product != null && product.Contains("ProductImage") && product["ProductImage"].IsBsonBinaryData)
                {
                    imageBytes = product["ProductImage"].AsBsonBinaryData.Bytes;
                    // Optionally, you can store content type in DB and retrieve it here
                    if (product.Contains("ImgContentType"))
                        contentType = product["ImgContentType"].AsString;
                }
            }
            catch
            {
                imageBytes = null;
            }

            if (imageBytes != null && imageBytes.Length > 0)
            {
                context.Response.ContentType = contentType;
                context.Response.BinaryWrite(imageBytes);
            }
            else
            {
                context.Response.ContentType = "image/png";
                context.Response.BinaryWrite(GetDefaultImage());
            }
        }

        public bool IsReusable { get { return false; } }

        private byte[] GetDefaultImage()
        {
            // Return a default PNG image as a byte array
            // This is a 1x1 transparent PNG
            return new byte[] {
                137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,1,0,0,0,1,8,6,0,0,0,31,21,196,137,0,0,0,12,73,68,65,84,8,153,99,0,1,0,0,5,0,1,13,10,38,169,0,0,0,0,73,69,78,68,174,66,96,130
            };
        }
    }
}
