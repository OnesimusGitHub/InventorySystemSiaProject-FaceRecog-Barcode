<%@ WebHandler Language="C#" Class="GetArchivedProducts" %>

using System;
using System.Web;
using System.Linq;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;
using Newtonsoft.Json;
using System.Collections.Generic;

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
                "status",
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
    decimal? lowestPrice = null;
    decimal? highestPrice = null;
    int variantCount = 0;

    // Temporary debug list to return variant info to the client
    List<object> debugVariants = null;

    try
    {
        var variantProjection = Builders<ProductVariant>.Projection
            .Exclude(v => v.VariantImgUrls);

        var variants = productVariantsCollection
            .Find(Builders<ProductVariant>.Filter.Eq("productId", p.Id))
            .Project<ProductVariant>(variantProjection)
            .ToList();

        // build debug list
        if (variants != null)
        {
            debugVariants = variants.Select(v => new {
                Id = v.Id ?? "",
                Price = v.Price,
                StockQuantity = v.StockQuantity,
                IsActive = v.IsActive
            }).ToList<object>();
        }

        variantCount = variants != null ? variants.Count : 0;
        stockCount = variants != null ? variants.Sum(v => v.StockQuantity) : 0;

        if (variants != null && variants.Count > 0)
        {
            lowestPrice = variants.Min(v => v.Price);
            highestPrice = variants.Max(v => v.Price);
        }
    }
    catch
    {
        stockCount = 0;
        lowestPrice = null;
        highestPrice = null;
    }

    var displayPrice = lowestPrice ?? p.productVal;
    string priceRange;
    if (lowestPrice.HasValue && highestPrice.HasValue)
    {
        priceRange = lowestPrice.Value == highestPrice.Value
            ? string.Format("₱{0:F2}", lowestPrice.Value)
            : string.Format("₱{0:F2} - ₱{1:F2}", lowestPrice.Value, highestPrice.Value);
    }
    else if (p.productVal != 0)
    {
        priceRange = string.Format("₱{0:F2}", p.productVal);
    }
    else
    {
        priceRange = "₱0.00";
    }

    return new
    {
        ProductId = p.Id,
        ProductName = p.productName ?? "",
        ProductCategory = p.productCategory ?? "",
        ProductImg = "/Content/images/sample-generic.png",
        ProductVal = displayPrice,
        PriceRange = priceRange,
        VariantCount = variantCount,
        StockCount = stockCount,
        Status = p.status ?? "",
        CreatedAt = p.createdAt,
        DebugVariants = debugVariants // temporary for debugging - remove later
    };
})
.OrderByDescending(p => p.ProductName)
.ToList();

            // Add a top-level debug marker so client can detect updated handler
            context.Response.Write(JsonConvert.SerializeObject(new { success = true, handlerDebug = "GetArchivedProducts-v2", products = result }));
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