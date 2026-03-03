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

                // Build product status filter: Status == "Active" or Status == null
                var statusFilter = Builders<Product>.Filter.Or(
                    Builders<Product>.Filter.Eq(p => p.status, "Active"),
                    Builders<Product>.Filter.Eq("Status", BsonNull.Value),
                    Builders<Product>.Filter.Eq("Status", (string)null)
                );

                FilterDefinition<Product> productFilter;
                if (string.IsNullOrEmpty(category))
                {
                    // No category: all products with status Active or null
                    productFilter = statusFilter;
                }
                else
                {
                    // Category + status
                    var catFilter = Builders<Product>.Filter.Eq(p => p.productCategory, category);
                    productFilter = Builders<Product>.Filter.And(catFilter, statusFilter);
                }

                // ✅ FIX: Exclude productImg from product projection
                var productProjection = Builders<Product>.Projection
                    .Exclude(p => p.productImg);

                // Find product IDs with the given filter (without binary image data)
                var products = productCollection.Find(productFilter)
                    .Project<Product>(productProjection)
                    .ToList();

                var productIds = products.Select(p => p.Id).ToList();

                if (productIds.Count == 0)
                {
                    context.Response.Write("[]");
                    return;
                }

                // ✅ FIX: Exclude binary image fields from variant projection
                var variantProjection = Builders<ProductVariant>.Projection
                    .Exclude(v => v.VariantImgUrls); // Exclude binary blob array

                // Find variants with ProductId in productIds AND IsActive = true (without binary image data)
                var productIdFilter = Builders<ProductVariant>.Filter.In(v => v.ProductId, productIds);
                var isActiveFilter = Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true);
                var variantFilter = Builders<ProductVariant>.Filter.And(productIdFilter, isActiveFilter);

                variants = variantCollection.Find(variantFilter)
                    .Project<ProductVariant>(variantProjection)
                    .ToList();

                // Serialize and return
                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(variants));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                var serializer = new JavaScriptSerializer();
                var error = new
                {
                    error = ex.Message,
                    details = ex.GetType().Name,
                    stackTrace = ex.StackTrace
                };
                context.Response.Write(serializer.Serialize(error));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}