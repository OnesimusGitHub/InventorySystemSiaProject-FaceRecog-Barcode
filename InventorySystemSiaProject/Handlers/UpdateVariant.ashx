<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateVariant" %>

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
    public class UpdateVariant : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("?? UpdateVariant handler called");
                
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    System.Diagnostics.Debug.WriteLine($"?? Received raw data: {raw}");

                    if (string.IsNullOrWhiteSpace(raw))
                    {
                        throw new ArgumentException("No data received in request body.");
                    }

                    // Parse the JSON data as a dictionary first to handle the actual format being sent
                    var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                    
                    System.Diagnostics.Debug.WriteLine($"?? Parsed request data keys: {string.Join(", ", requestData.Keys)}");

                    // Extract the variant data from the request
                    string variantId = requestData.ContainsKey("variantId") ? requestData["variantId"]?.ToString() : null;
                    string variantName = requestData.ContainsKey("variantName") ? requestData["variantName"]?.ToString() : null;
                    string variantSKU = requestData.ContainsKey("variantSKU") ? requestData["variantSKU"]?.ToString() : null;
                    string size = requestData.ContainsKey("variantSize") ? requestData["variantSize"]?.ToString() : "";
                    string color = requestData.ContainsKey("variantColor") ? requestData["variantColor"]?.ToString() : "";
                    string dimensions = requestData.ContainsKey("variantDimensions") ? requestData["variantDimensions"]?.ToString() : "";
                    
                    decimal price = 0;
                    if (requestData.ContainsKey("variantPrice") && requestData["variantPrice"] != null)
                    {
                        decimal.TryParse(requestData["variantPrice"].ToString(), out price);
                    }

                    int stock = 0;
                    if (requestData.ContainsKey("variantStock") && requestData["variantStock"] != null)
                    {
                        int.TryParse(requestData["variantStock"].ToString(), out stock);
                    }

                    int minStock = 0;
                    if (requestData.ContainsKey("variantMinStock") && requestData["variantMinStock"] != null)
                    {
                        int.TryParse(requestData["variantMinStock"].ToString(), out minStock);
                    }

                    decimal? weight = null;
                    if (requestData.ContainsKey("variantWeight") && requestData["variantWeight"] != null)
                    {
                        if (decimal.TryParse(requestData["variantWeight"].ToString(), out decimal w))
                        {
                            weight = w;
                        }
                    }

                    System.Diagnostics.Debug.WriteLine($"?? Variant data extracted:");
                    System.Diagnostics.Debug.WriteLine($"  ? Variant ID: '{variantId}'");
                    System.Diagnostics.Debug.WriteLine($"  ? Variant Name: '{variantName}'");
                    System.Diagnostics.Debug.WriteLine($"  ? SKU: '{variantSKU}'");
                    System.Diagnostics.Debug.WriteLine($"  ? Price: {price}");

                    // Validate required fields
                    if (string.IsNullOrWhiteSpace(variantId))
                    {
                        throw new ArgumentException("Variant ID is required.");
                    }

                    if (string.IsNullOrWhiteSpace(variantName))
                    {
                        throw new ArgumentException("Variant name is required.");
                    }

                    if (string.IsNullOrWhiteSpace(variantSKU))
                    {
                        throw new ArgumentException("Variant SKU is required.");
                    }

                    if (price <= 0)
                    {
                        throw new ArgumentException("Valid price is required.");
                    }

                    // Get the variants collection
                    var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                    if (variantsColl == null)
                    {
                        throw new InvalidOperationException("Failed to retrieve the product variants collection from the database.");
                    }

                    System.Diagnostics.Debug.WriteLine("?? Creating MongoDB filter and update...");

                    // Create the filter using ObjectId
                    FilterDefinition<ProductVariant> filter;
                    try 
                    {
                        filter = Builders<ProductVariant>.Filter.Eq("_id", new ObjectId(variantId));
                    }
                    catch (FormatException)
                    {
                        // If variantId is not a valid ObjectId, try as string
                        filter = Builders<ProductVariant>.Filter.Eq("_id", variantId);
                    }

                    // Create the update definition
                    var update = Builders<ProductVariant>.Update
                        .Set("VariantName", variantName)
                        .Set("SKU", variantSKU)
                        .Set("Size", size)
                        .Set("Color", color)
                        .Set("Price", price)
                        .Set("StockQuantity", stock)
                        .Set("MinimumStock", minStock)
                        .Set("Dimensions", dimensions)
                        .Set("UpdatedAt", DateTime.UtcNow);

                    if (weight.HasValue)
                    {
                        update = update.Set("Weight", weight.Value);
                    }

                    System.Diagnostics.Debug.WriteLine("?? Executing UpdateOne operation...");
                    var result = variantsColl.UpdateOne(filter, update);

                    System.Diagnostics.Debug.WriteLine($"?? Update result: MatchedCount={result.MatchedCount}, ModifiedCount={result.ModifiedCount}");

                    if (result.MatchedCount == 0)
                    {
                        throw new InvalidOperationException($"No variant found with ID: {variantId}. Please check the Variant ID.");
                    }

                    if (result.ModifiedCount == 0)
                    {
                        System.Diagnostics.Debug.WriteLine("?? No changes were made (data might be the same)");
                        // This is not necessarily an error - the data might be the same
                    }

                    System.Diagnostics.Debug.WriteLine("? Variant updated successfully");
                    context.Response.Write(serializer.Serialize(new { 
                        success = true, 
                        message = "Variant updated successfully.",
                        variantId = variantId,
                        variantName = variantName
                    }));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"?? Error in UpdateVariant handler: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"?? Exception type: {ex.GetType().Name}");
                System.Diagnostics.Debug.WriteLine($"?? Stack trace: {ex.StackTrace}");
                
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { 
                    error = ex.Message,
                    details = ex.GetType().Name,
                    success = false
                }));
            }
        }

        public bool IsReusable => false;
    }
}