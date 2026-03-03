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
    /// <summary>
    /// Handler to get stock statistics for the Dashboard pie chart
    /// Returns counts of normal stock, low stock, and out of stock items
    /// Supports filtering by stock status (Low, Normal, All)
    /// </summary>
    public class GetStockStats : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            try
            {
                // Get filter parameter from query string
                string filter = context.Request.QueryString["filter"];

                var variantCollection = DatabaseHelper.GetProductVariantsCollection();
                var productCollection = DatabaseHelper.GetProductsCollection();

                // Build filter for active products only
                var productStatusFilter = Builders<Product>.Filter.Or(
                    Builders<Product>.Filter.Eq(p => p.status, "Active"),
                    Builders<Product>.Filter.Eq("Status", MongoDB.Bson.BsonNull.Value),
                    Builders<Product>.Filter.Eq("Status", (string)null)
                );

                // ✅ FIX: Use only Include() - cannot mix Include and Exclude
                var projection = Builders<Product>.Projection
                    .Include(p => p.Id)
                    .Include(p => p.productName)
                    .Include(p => p.productCategory)
                    .Include(p => p.status);

                // Get all active product IDs (without productImg)
                var activeProducts = productCollection.Find(productStatusFilter)
                    .Project<Product>(projection)
                    .ToList();

                var activeProductIds = activeProducts.Select(p => p.Id).ToList();

                // Create a dictionary for quick product lookup
                var productDict = activeProducts.ToDictionary(p => p.Id, p => p);

                // Build filter for active variants of active products
                var variantFilter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.In(v => v.ProductId, activeProductIds),
                    Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true)
                );

                // ✅ FIX: Use only Include() for variant projection
                var variantProjection = Builders<ProductVariant>.Projection
                    .Include(v => v.Id)
                    .Include(v => v.ProductId)
                    .Include(v => v.VariantName)
                    .Include(v => v.SKU)
                    .Include(v => v.StockQuantity)
                    .Include(v => v.MinimumStock)
                    .Include(v => v.IsActive);

                // Get all active variants (without binary image data)
                var variants = variantCollection.Find(variantFilter)
                    .Project<ProductVariant>(variantProjection)
                    .ToList();

                // Calculate stock statistics
                int normalStock = 0;
                int lowStock = 0;
                int outOfStock = 0;

                foreach (var variant in variants)
                {
                    int stock = variant.StockQuantity;
                    int minStock = variant.MinimumStock;

                    if (stock == 0)
                    {
                        outOfStock++;
                    }
                    else if (stock <= minStock)
                    {
                        lowStock++;
                    }
                    else
                    {
                        normalStock++;
                    }
                }

                // Filter variants based on stock status
                List<ProductVariant> filteredVariants = variants;

                if (!string.IsNullOrEmpty(filter) && filter.ToLower() != "all")
                {
                    if (filter.ToLower() == "low")
                    {
                        // Show only low stock and out of stock items
                        filteredVariants = variants.Where(v => v.StockQuantity <= v.MinimumStock).ToList();
                    }
                    else if (filter.ToLower() == "normal")
                    {
                        // Show only normal stock items
                        filteredVariants = variants.Where(v => v.StockQuantity > v.MinimumStock).ToList();
                    }
                }

                // Build product list with details
                List<object> productList = new List<object>();
                foreach (var variant in filteredVariants.Take(10)) // Limit to 10 items for display
                {
                    Product product = null;
                    if (productDict.ContainsKey(variant.ProductId))
                    {
                        product = productDict[variant.ProductId];
                    }

                    string stockStatus = "normal";
                    if (variant.StockQuantity == 0)
                        stockStatus = "out";
                    else if (variant.StockQuantity <= variant.MinimumStock)
                        stockStatus = "low";

                    // ✅ Check if variant has images by querying separately
                    string productImageUrl;
                    bool hasVariantImages = false;

                    // Query variant to check if it has images (separate query with projection)
                    var imgCheckFilter = Builders<ProductVariant>.Filter.Eq(v => v.Id, variant.Id);
                    var imgCheckProjection = Builders<ProductVariant>.Projection
                        .Include("variantImgUrls"); // Use string field name

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
                        // Variant has images - use handler to serve first image
                        productImageUrl = "/Handlers/GetVariantImage.ashx?variantId=" + variant.Id + "&index=0";
                    }
                    else
                    {
                        // Check if product has image
                        bool hasProductImage = false;
                        if (product != null)
                        {
                            var productImgCheckFilter = Builders<Product>.Filter.Eq(p => p.Id, product.Id);
                            var productImgCheckProjection = Builders<Product>.Projection
                                .Include("productImg"); // Use string field name

                            var imgCheck = productCollection.Find(productImgCheckFilter)
                                .Project<MongoDB.Bson.BsonDocument>(productImgCheckProjection)
                                .FirstOrDefault();

                            if (imgCheck != null && imgCheck.Contains("productImg"))
                            {
                                var imgData = imgCheck["productImg"];
                                hasProductImage = imgData != null && imgData.IsBsonBinaryData && imgData.AsByteArray.Length > 0;
                            }
                        }

                        if (hasProductImage)
                        {
                            // Product has blob image - use handler to serve it
                            productImageUrl = "/Handlers/GetProductImage.ashx?productId=" + product.Id;
                        }
                        else
                        {
                            // No image - use default
                            productImageUrl = "/Content/images/sample-generic.png";
                        }
                    }

                    productList.Add(new
                    {
                        variantId = variant.Id,
                        variantName = variant.VariantName,
                        productName = product?.productName ?? "Unknown Product",
                        productImage = productImageUrl,
                        stockQuantity = variant.StockQuantity,
                        minimumStock = variant.MinimumStock,
                        stockStatus = stockStatus,
                        sku = variant.SKU ?? ""
                    });
                }

                // Add filtered count and items list
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