<%@ WebHandler Language="C#" Class="GetArchivedProducts" %>

using System;
using System.Web;
using System.Linq;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;
using Newtonsoft.Json;

public class GetArchivedProducts : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        try
        {
            var productsCollection = DatabaseHelper.GetProductsCollection();
            var productVariantsCollection = DatabaseHelper.GetProductVariantsCollection();

            var filterBuilder = Builders<Product>.Filter;

            // Match Archived and legacy Inactive product status
            var filter = filterBuilder.Regex(
                "status", // <-- important: lowercase
                new BsonRegularExpression("^(archived|in\\s*active|inactive)$", "i")
            );

            var projection = Builders<Product>.Projection
                .Exclude(p => p.productImg);

            var products = productsCollection.Find(filter)
                .Project<Product>(projection)
                .ToList();

            var result = products.Select(p =>
            {
                var stockCount = 0;
                try
                {
                    var variantProjection = Builders<ProductVariant>.Projection
                        .Exclude(v => v.VariantImgUrls);

                    var variants = productVariantsCollection
                        .Find(Builders<ProductVariant>.Filter.Eq("productId", p.Id))
                        .Project<ProductVariant>(variantProjection)
                        .ToList();

                    stockCount = variants.Sum(v => v.StockQuantity);
                }
                catch
                {
                    stockCount = 0;
                }

                return new
                {
                    ProductId = p.Id,
                    ProductName = p.productName ?? "",
                    ProductCategory = p.productCategory ?? "",
                    ProductImg = "/Content/images/sample-generic.png",
                    ProductVal = p.productVal,
                    StockCount = stockCount,
                    Status = p.status ?? "",
                    CreatedAt = p.createdAt
                };
            })
            .OrderByDescending(p => p.ProductName)
            .ToList();

            context.Response.Write(JsonConvert.SerializeObject(new { success = true, products = result }));
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            var errorMessage = ex.Message + (ex.InnerException != null ? " | Inner: " + ex.InnerException.Message : "");
            context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = errorMessage, stackTrace = ex.StackTrace }));
        }
    }

    public bool IsReusable { get { return false; } }
}