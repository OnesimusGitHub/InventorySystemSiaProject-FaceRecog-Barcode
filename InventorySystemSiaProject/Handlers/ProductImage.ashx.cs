using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;

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
                var productsColl = DatabaseHelper.GetProductsCollection();
                Product product = null;
                // Try both ObjectId and string matching
                if (ObjectId.TryParse(productId, out ObjectId objectId))
                {
                    product = productsColl.Find(Builders<Product>.Filter.Eq("_id", objectId)).FirstOrDefault();
                }
                else
                {
                    product = productsColl.Find(Builders<Product>.Filter.Eq("_id", productId)).FirstOrDefault();
                }

                if (product != null && product.ProductImage != null && product.ProductImage.Length > 0)
                {
                    imageBytes = product.ProductImage;
                    // Optionally, you can store content type in DB, e.g. product.ImgContentType
                    // If not, default to PNG
                    contentType = "image/png";
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
