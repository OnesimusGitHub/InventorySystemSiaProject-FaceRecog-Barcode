using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    public class GetStockStats : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            try
            {
                string filter = context.Request.QueryString["filter"];

                var variantCollection = DatabaseHelper.GetProductVariantsCollection();
                var productCollection = DatabaseHelper.GetProductsCollection();

                // Build filter for active products only
                var productStatusFilter = Builders<Product>.Filter.Or(
                    Builders<Product>.Filter.Eq(p => p.status, "Active"),
                    Builders<Product>.Filter.Eq("Status", MongoDB.Bson.BsonNull.Value),
                    Builders<Product>.Filter.Eq("Status", (string)null)
                );

                var projection = Builders<Product>.Projection
                    .Include(p => p.Id)
                    .Include(p => p.productName)
                    .Include(p => p.productCategory)
                    .Include(p => p.status);

                var activeProducts = productCollection.Find(productStatusFilter)
                    .Project<Product>(projection)
                    .ToList();

                var activeProductIds = activeProducts.Select(p => p.Id).ToList();
                var productDict = activeProducts.ToDictionary(p => p.Id, p => p);

                var variantFilter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.In(v => v.ProductId, activeProductIds),
                    Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true)
                );

                var variantProjection = Builders<ProductVariant>.Projection
                    .Include(v => v.Id)
                    .Include(v => v.ProductId)
                    .Include(v => v.VariantName)
                    .Include(v => v.SKU)
                    .Include(v => v.StockQuantity)
                    .Include(v => v.MinimumStock)
                    .Include(v => v.IsActive);

                var variants = variantCollection.Find(variantFilter)
                    .Project<ProductVariant>(variantProjection)
                    .ToList();

                // Calculate stock statistics from ALL variants (unfiltered)
                int normalStock = 0;
                int lowStock = 0;
                int outOfStock = 0;

                foreach (var variant in variants)
                {
                    int stock = variant.StockQuantity;
                    int minStock = variant.MinimumStock;

                    if (stock == 0)
                        outOfStock++;
                    else if (stock <= minStock)
                        lowStock++;
                    else
                        normalStock++;
                }

                // Apply filter to determine which variants appear in the product list
                List<ProductVariant> filteredVariants = variants;

                if (!string.IsNullOrEmpty(filter) && filter.ToLower() != "all")
                {
                    if (filter.ToLower() == "low")
                        filteredVariants = variants.Where(v => v.StockQuantity <= v.MinimumStock).ToList();
                    else if (filter.ToLower() == "normal")
                        filteredVariants = variants.Where(v => v.StockQuantity > v.MinimumStock).ToList();
                }

                // ✅ FIX: Removed .Take(10) — return ALL filtered variants
                List<object> productList = new List<object>();
                foreach (var variant in filteredVariants)
                {
                    Product product = null;
                    if (productDict.ContainsKey(variant.ProductId))
                        product = productDict[variant.ProductId];

                    string stockStatus = "normal";
                    if (variant.StockQuantity == 0)
                        stockStatus = "out";
                    else if (variant.StockQuantity <= variant.MinimumStock)
                        stockStatus = "low";

                    // Check if variant has images
                    string productImageUrl;
                    bool hasVariantImages = false;

                    var imgCheckFilter = Builders<ProductVariant>.Filter.Eq(v => v.Id, variant.Id);
                    var imgCheckProjection = Builders<ProductVariant>.Projection
                        .Include("variantImgUrls");

                    var variantWithImages = variantCollection.Find(imgCheckFilter)
                        .Project<MongoDB.Bson.BsonDocument>(imgCheckProjection)
                        .FirstOrDefault();

                    if (variantWithImages != null && variantWithImages.Contains("variantImgUrls"))
                    {
                        var imgUrls = variantWithImages["variantImgUrls"];
                        hasVariantImages = imgUrls != null && imgUrls.IsBsonArray && imgUrls.AsBsonArray.Count > 0;
                    }

                    if (hasVariantImages)
                    {
                        productImageUrl = "/Handlers/GetVariantImage.ashx?variantId=" + variant.Id + "&index=0";
                    }
                    else
                    {
                        bool hasProductImage = false;
                        if (product != null)
                        {
                            var productImgCheckFilter = Builders<Product>.Filter.Eq(p => p.Id, product.Id);
                            var productImgCheckProjection = Builders<Product>.Projection
                                .Include("productImg");

                            var imgCheck = productCollection.Find(productImgCheckFilter)
                                .Project<MongoDB.Bson.BsonDocument>(productImgCheckProjection)
                                .FirstOrDefault();

                            if (imgCheck != null && imgCheck.Contains("productImg"))
                            {
                                var imgData = imgCheck["productImg"];
                                hasProductImage = imgData != null && imgData.IsBsonBinaryData && imgData.AsByteArray.Length > 0;
                            }
                        }

                        productImageUrl = hasProductImage
                            ? "/Handlers/GetProductImage.ashx?productId=" + product.Id
                            : "/Content/images/sample-generic.png";
                    }

                    productList.Add(new
                    {
                        variantId = variant.Id,
                        variantName = variant.VariantName,
                        productName = product != null ? product.productName ?? "Unknown Product" : "Unknown Product",
                        productImage = productImageUrl,
                        stockQuantity = variant.StockQuantity,
                        minimumStock = variant.MinimumStock,
                        stockStatus = stockStatus,
                        sku = variant.SKU ?? ""
                    });
                }

                var result = new
                {
                    success = true,
                    normalStock = normalStock,
                    lowStock = lowStock,
                    outOfStock = outOfStock,
                    totalItems = variants.Count,
                    filteredCount = filteredVariants.Count,
                    appliedFilter = filter ?? "All",
                    products = productList,
                    message = "Stock statistics retrieved successfully"
                };

                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(result));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                var serializer = new JavaScriptSerializer();
                var error = new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace,
                    message = "Failed to retrieve stock statistics"
                };
                context.Response.Write(serializer.Serialize(error));
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}