using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    public class GetProductVariantsByCategory : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            string category = context.Request["category"];

            try
            {
                var productCollection = DatabaseHelper.GetProductsCollection();
                var variantCollection = DatabaseHelper.GetProductVariantsCollection();
                List<ProductVariant> variants;

                if (string.IsNullOrEmpty(category))
                {
                    // No category: return all variants
                    variants = variantCollection.Find(Builders<ProductVariant>.Filter.Empty).ToList();
                }
                else
                {
                    // Find product IDs with the given category
                    var products = productCollection.Find(Builders<Product>.Filter.Eq(p => p.ProductCategory, category)).ToList();
                    var productIds = products.Select(p => p.Id).ToList();

                    if (productIds.Count == 0)
                    {
                        context.Response.Write("[]");
                        return;
                    }

                    // Find variants with ProductId in productIds
                    var filter = Builders<ProductVariant>.Filter.In(v => v.ProductId, productIds);
                    variants = variantCollection.Find(filter).ToList();
                }

                // Serialize and return
                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(variants));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
