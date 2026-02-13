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
                // ? Get filter parameter from query string
                string filter = context.Request.QueryString["filter"];
                
                var variantCollection = DatabaseHelper.GetProductVariantsCollection();
                var productCollection = DatabaseHelper.GetProductsCollection();
                
                // Build filter for active products only
                var productStatusFilter = Builders<Product>.Filter.Or(
                    Builders<Product>.Filter.Eq(p => p.Status, "Active"),
                    Builders<Product>.Filter.Eq("Status", MongoDB.Bson.BsonNull.Value),
                    Builders<Product>.Filter.Eq("Status", (string)null)
                );
                
                // Get all active product IDs
                var activeProducts = productCollection.Find(productStatusFilter).ToList();
                var activeProductIds = activeProducts.Select(p => p.Id).ToList();
                
                // Create a dictionary for quick product lookup
                var productDict = activeProducts.ToDictionary(p => p.Id, p => p);
                
                // Build filter for active variants of active products
                var variantFilter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.In(v => v.ProductId, activeProductIds),
                    Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true)
                );
                
                // Get all active variants
                var variants = variantCollection.Find(variantFilter).ToList();
                
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
                
                // ? Filter variants based on stock status
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
                
                // ? Build product list with details
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
                    
                    productList.Add(new
                    {
                        variantId = variant.Id,
                        variantName = variant.VariantName,
                        productName = product?.ProductName ?? "Unknown Product",
                        productImage = product?.ProductImg ?? "/Content/images/sample-generic.png",
                        stockQuantity = variant.StockQuantity,
                        minimumStock = variant.MinimumStock,
                        stockStatus = stockStatus,
                        sku = variant.SKU ?? ""
                    });
                }
                
                // ? Add filtered count and items list
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
