using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Web;

namespace InventorySystemSiaProject.Handlers
{
    public class GetProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            try
            {
                var request = new StreamReader(context.Request.InputStream).ReadToEnd();
                var data = JsonConvert.DeserializeObject<Dictionary<string, string>>(request);

                if (!data.ContainsKey("productId"))
                {
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "Product ID is required" }));
                    return;
                }

                string productId = data["productId"];
                
                // ✅ Get MongoDB collection with projection to EXCLUDE productImg binary data
                var collection = DatabaseHelper.GetProductsCollection();
                
                var projection = Builders<Product>.Projection
                    .Exclude(p => p.productImg)  // ✅ Exclude binary image data
                    .Exclude(p => p.ProductImgContentType); // ✅ Also exclude content type
                
                var filter = Builders<Product>.Filter.Eq(p => p.Id, productId);
                
                var product = collection.Find(filter)
                    .Project<Product>(projection)
                    .FirstOrDefault();

                if (product != null)
                {
                    // ✅ Return the image handler URL instead of blob data
                    var response = new
                    {
                        success = true,
                        product = new
                        {
                            productId = product.Id,
                            productName = product.productName,
                            productCategory = product.productCategory,
                            productDesc = product.productDesc,
                            baseIngredients = product.baseIngredients,
                            // ✅ Use the handler endpoint to fetch the image
                            productImg = $"/Handlers/GetProductImage.ashx?productId={product.Id}",
                            productValue = product.productVal
                        }
                    };

                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                else
                {
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "Product not found" }));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ GetProduct error: {ex.Message}\n{ex.StackTrace}");
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable => false;
    }
}