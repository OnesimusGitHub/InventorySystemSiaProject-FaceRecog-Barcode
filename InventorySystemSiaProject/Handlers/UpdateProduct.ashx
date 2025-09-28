<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateProduct" %>

using System;
using System.Web;
using System.Web.JavaScript.Serialization; // correct namespace
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class UpdateProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("UpdateProduct handler called");
                
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    System.Diagnostics.Debug.WriteLine("Received raw data: " + raw);

                    if (string.IsNullOrWhiteSpace(raw))
                    {
                        throw new ArgumentException("No data received in request body.");
                    }

                    var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                    System.Diagnostics.Debug.WriteLine("Parsed request data keys: " + string.Join(", ", requestData.Keys));

                    // Extract product data (avoid null-conditional for C#5)
                    string productId = requestData.ContainsKey("productId") && requestData["productId"] != null ? requestData["productId"].ToString() : null;
                    string productName = requestData.ContainsKey("productName") && requestData["productName"] != null ? requestData["productName"].ToString() : null;
                    string category = requestData.ContainsKey("category") && requestData["category"] != null ? requestData["category"].ToString() : null;
                    string description = requestData.ContainsKey("description") && requestData["description"] != null ? requestData["description"].ToString() : string.Empty;
                    string baseIngredients = requestData.ContainsKey("baseIngredients") && requestData["baseIngredients"] != null ? requestData["baseIngredients"].ToString() : string.Empty;
                    string supplier = requestData.ContainsKey("supplier") && requestData["supplier"] != null ? requestData["supplier"].ToString() : string.Empty;
                    string imageUrl = requestData.ContainsKey("imageUrl") && requestData["imageUrl"] != null ? requestData["imageUrl"].ToString() : string.Empty;
                    
                    decimal productValue = 0;
                    if (requestData.ContainsKey("productValue") && requestData["productValue"] != null)
                    {
                        decimal.TryParse(requestData["productValue"].ToString(), out productValue);
                    }

                    System.Diagnostics.Debug.WriteLine("Product data extracted:");
                    System.Diagnostics.Debug.WriteLine("  Product ID: '" + productId + "'");
                    System.Diagnostics.Debug.WriteLine("  Product Name: '" + productName + "'");
                    System.Diagnostics.Debug.WriteLine("  Category: '" + category + "'");

                    if (string.IsNullOrWhiteSpace(productId))
                        throw new ArgumentException("Product ID is required.");
                    if (string.IsNullOrWhiteSpace(productName))
                        throw new ArgumentException("Product name is required.");
                    if (string.IsNullOrWhiteSpace(category))
                        throw new ArgumentException("Product category is required.");

                    var productsColl = DatabaseHelper.GetProductsCollection();
                    if (productsColl == null)
                        throw new InvalidOperationException("Failed to retrieve the products collection from the database.");

                    System.Diagnostics.Debug.WriteLine("Creating MongoDB filter and update...");

                    FilterDefinition<Product> filter;
                    try
                    {
                        filter = Builders<Product>.Filter.Eq("_id", new ObjectId(productId));
                    }
                    catch (FormatException)
                    {
                        filter = Builders<Product>.Filter.Eq("_id", productId);
                    }

                    var update = Builders<Product>.Update
                        .Set("ProductName", productName)
                        .Set("ProductCategory", category)
                        .Set("ProductDesc", description)
                        .Set("BaseIngredients", baseIngredients)
                        .Set("Supplier", supplier)
                        .Set("ProductVal", productValue)
                        .Set("ProductImg", imageUrl)
                        .Set("UpdatedAt", DateTime.UtcNow);

                    System.Diagnostics.Debug.WriteLine("Executing UpdateOne operation...");
                    var result = productsColl.UpdateOne(filter, update);
                    System.Diagnostics.Debug.WriteLine("Update result: MatchedCount=" + result.MatchedCount + ", ModifiedCount=" + result.ModifiedCount);

                    if (result.MatchedCount == 0)
                        throw new InvalidOperationException("No product found with ID: " + productId + ". Please check the Product ID.");

                    if (result.ModifiedCount == 0)
                        System.Diagnostics.Debug.WriteLine("No changes were made (data might be the same)");

                    // Activity log (no 'before' snapshot because we don't fetch the document here)
                    var details = new { productName, category, description, supplier, productValue, imageUrl };
                    try
                    {
                        ActivityLogger.Log("Update", "Product", productId, new JavaScriptSerializer().Serialize(details));
                    }
                    catch { }

                    System.Diagnostics.Debug.WriteLine("Product updated successfully");
                    context.Response.Write(serializer.Serialize(new {
                        success = true,
                        message = "Product updated successfully.",
                        productId = productId,
                        productName = productName
                    }));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error in UpdateProduct handler: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("Exception type: " + ex.GetType().Name);
                System.Diagnostics.Debug.WriteLine("Stack trace: " + ex.StackTrace);

                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new {
                    error = ex.Message,
                    details = ex.GetType().Name,
                    success = false
                }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}