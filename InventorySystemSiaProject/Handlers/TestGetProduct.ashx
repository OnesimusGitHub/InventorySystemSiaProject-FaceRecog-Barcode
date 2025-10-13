<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.TestGetProduct" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Test handler for debugging GetProduct functionality
    /// Usage: /Handlers/TestGetProduct.ashx?test=connection
    ///        /Handlers/TestGetProduct.ashx?test=products
    ///        /Handlers/TestGetProduct.ashx?productId=YOUR_PRODUCT_ID
    /// </summary>
    public class TestGetProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                string test = context.Request.QueryString["test"];
                string productId = context.Request.QueryString["productId"];

                var response = new Dictionary<string, object>();
                response["timestamp"] = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss");
                response["success"] = true;

                // Test 1: Database Connection
                if (!string.IsNullOrEmpty(test) && test.ToLower() == "connection")
                {
                    try
                    {
                        var database = DatabaseHelper.Database;
                        response["database"] = database.DatabaseNamespace.DatabaseName;
                        response["connectionSuccessful"] = true;
                        response["message"] = "? Database connection successful!";
                    }
                    catch (Exception dbEx)
                    {
                        response["success"] = false;
                        response["connectionSuccessful"] = false;
                        response["error"] = "Database connection failed: " + dbEx.Message;
                    }

                    context.Response.Write(serializer.Serialize(response));
                    return;
                }

                // Test 2: List All Products
                if (!string.IsNullOrEmpty(test) && test.ToLower() == "products")
                {
                    try
                    {
                        var productsColl = DatabaseHelper.GetProductsCollection();
                        var products = productsColl.Find(_ => true).Limit(10).ToList();
                        
                        response["productCount"] = products.Count;
                        response["products"] = products.Select(p => new {
                            id = p.Id,
                            name = p.ProductName,
                            category = p.ProductCategory
                        }).ToList();
                        response["message"] = $"? Found {products.Count} products";
                    }
                    catch (Exception prodEx)
                    {
                        response["success"] = false;
                        response["error"] = "Failed to get products: " + prodEx.Message;
                    }

                    context.Response.Write(serializer.Serialize(response));
                    return;
                }

                // Test 3: Get Specific Product
                if (!string.IsNullOrEmpty(productId))
                {
                    try
                    {
                        var productsColl = DatabaseHelper.GetProductsCollection();
                        
                        // Try both ObjectId and string matching
                        FilterDefinition<Product> filter;
                        if (ObjectId.TryParse(productId, out ObjectId objectId))
                        {
                            filter = Builders<Product>.Filter.Eq("_id", objectId);
                            response["filterType"] = "ObjectId";
                        }
                        else
                        {
                            filter = Builders<Product>.Filter.Eq("_id", productId);
                            response["filterType"] = "String";
                        }

                        var product = productsColl.Find(filter).FirstOrDefault();

                        if (product == null)
                        {
                            response["success"] = false;
                            response["error"] = "Product not found with ID: " + productId;
                        }
                        else
                        {
                            response["product"] = new {
                                id = product.Id,
                                productName = product.ProductName ?? string.Empty,
                                productCategory = product.ProductCategory ?? string.Empty,
                                productDesc = product.ProductDesc ?? string.Empty,
                                baseIngredients = product.BaseIngredients ?? string.Empty,
                                supplier = product.Supplier ?? string.Empty,
                                productImg = product.ProductImg ?? string.Empty,
                                productVal = product.ProductVal,
                                isActive = product.IsActive,
                                createdAt = product.CreatedAt,
                                updatedAt = product.UpdatedAt
                            };
                            response["message"] = $"? Product '{product.ProductName}' found successfully!";
                        }
                    }
                    catch (Exception prodEx)
                    {
                        response["success"] = false;
                        response["error"] = "Error getting product: " + prodEx.Message;
                        response["stackTrace"] = prodEx.StackTrace;
                    }

                    context.Response.Write(serializer.Serialize(response));
                    return;
                }

                // Default: Show usage instructions
                response["message"] = "Test handler ready";
                response["usage"] = new {
                    testConnection = "/Handlers/TestGetProduct.ashx?test=connection",
                    testProducts = "/Handlers/TestGetProduct.ashx?test=products",
                    testGetProduct = "/Handlers/TestGetProduct.ashx?productId=YOUR_PRODUCT_ID"
                };
                response["note"] = "Use the endpoints above to test database connectivity and product retrieval";

                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new {
                    success = false,
                    error = ex.Message,
                    details = ex.GetType().Name,
                    stackTrace = ex.StackTrace
                }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
