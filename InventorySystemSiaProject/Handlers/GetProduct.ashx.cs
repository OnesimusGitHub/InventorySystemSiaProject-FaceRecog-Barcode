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
    public class GetProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("? GetProduct handler called");
                System.Diagnostics.Debug.WriteLine($"Request method: {context.Request.HttpMethod}");
                System.Diagnostics.Debug.WriteLine($"Request URL: {context.Request.Url}");
                
                // Support both POST (JSON body) and GET (query string)
                string productId = null;
                
                if (context.Request.HttpMethod == "POST")
                {
                    context.Request.InputStream.Position = 0;
                    using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                    {
                        var raw = reader.ReadToEnd();
                        System.Diagnostics.Debug.WriteLine($"POST body: {raw}");

                        if (!string.IsNullOrWhiteSpace(raw))
                        {
                            try
                            {
                                var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                                productId = requestData.ContainsKey("productId") && requestData["productId"] != null 
                                    ? requestData["productId"].ToString() 
                                    : null;
                            }
                            catch (Exception jsonEx)
                            {
                                System.Diagnostics.Debug.WriteLine($"? JSON parse error: {jsonEx.Message}");
                                context.Response.StatusCode = 400;
                                context.Response.Write(serializer.Serialize(new {
                                    error = "Invalid JSON format",
                                    details = jsonEx.Message,
                                    success = false
                                }));
                                return;
                            }
                        }
                    }
                }
                else // GET request
                {
                    productId = context.Request.QueryString["productId"];
                    System.Diagnostics.Debug.WriteLine($"GET productId: {productId}");
                }

                if (string.IsNullOrWhiteSpace(productId))
                {
                    System.Diagnostics.Debug.WriteLine("? Product ID is missing");
                    context.Response.StatusCode = 400;
                    context.Response.Write(serializer.Serialize(new {
                        error = "Product ID is required",
                        success = false
                    }));
                    return;
                }

                System.Diagnostics.Debug.WriteLine($"? Processing product ID: '{productId}'");

                // Get the products collection
                IMongoCollection<Product> productsColl = DatabaseHelper.GetProductsCollection();
                if (productsColl == null)
                {
                    System.Diagnostics.Debug.WriteLine("? Failed to get products collection");
                    context.Response.StatusCode = 500;
                    context.Response.Write(serializer.Serialize(new {
                        error = "Database connection failed",
                        details = "Could not retrieve products collection",
                        success = false
                    }));
                    return;
                }

                // Create filter
                FilterDefinition<Product> filter;
                if (ObjectId.TryParse(productId, out ObjectId objectId))
                {
                    filter = Builders<Product>.Filter.Eq("_id", objectId);
                    System.Diagnostics.Debug.WriteLine($"? Using ObjectId filter: {objectId}");
                }
                else
                {
                    filter = Builders<Product>.Filter.Eq("_id", productId);
                    System.Diagnostics.Debug.WriteLine($"? Using string filter: {productId}");
                }

                // Find the product
                Product product = productsColl.Find(filter).FirstOrDefault();

                if (product == null)
                {
                    System.Diagnostics.Debug.WriteLine($"? Product not found with ID: {productId}");
                    context.Response.StatusCode = 404;
                    context.Response.Write(serializer.Serialize(new {
                        error = "Product not found",
                        productId = productId,
                        success = false
                    }));
                    return;
                }

                System.Diagnostics.Debug.WriteLine($"? Product found: {product.ProductName}");

                // Return product data
                var response = new {
                    success = true,
                    product = new {
                        id = product.Id ?? productId,
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
                    }
                };

                string jsonResponse = serializer.Serialize(response);
                System.Diagnostics.Debug.WriteLine($"? Sending response for product: {product.ProductName}");
                context.Response.Write(jsonResponse);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? Unexpected error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");

                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new {
                    error = "Internal server error",
                    details = ex.Message,
                    type = ex.GetType().Name,
                    success = false
                }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
