<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateVariant" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.SessionState; // enable session access

namespace InventorySystemSiaProject.Handlers
{
    public class UpdateVariant : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("UpdateVariant handler called");
                
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

                    string variantId = requestData.ContainsKey("variantId") && requestData["variantId"] != null ? requestData["variantId"].ToString() : null;
                    string variantName = requestData.ContainsKey("variantName") && requestData["variantName"] != null ? requestData["variantName"].ToString() : null;
                    string variantSKU = requestData.ContainsKey("variantSKU") && requestData["variantSKU"] != null ? requestData["variantSKU"].ToString() : null;
                    string size = requestData.ContainsKey("variantSize") && requestData["variantSize"] != null ? requestData["variantSize"].ToString() : string.Empty;
                    string color = requestData.ContainsKey("variantColor") && requestData["variantColor"] != null ? requestData["variantColor"].ToString() : string.Empty;
                    string dimensions = requestData.ContainsKey("variantDimensions") && requestData["variantDimensions"] != null ? requestData["variantDimensions"].ToString() : string.Empty;
                    string variantImg = requestData.ContainsKey("variantImg") && requestData["variantImg"] != null ? requestData["variantImg"].ToString() : string.Empty;
                    
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
                        decimal w;
                        if (decimal.TryParse(requestData["variantWeight"].ToString(), out w))
                        {
                            weight = w;
                        }
                    }

                    System.Diagnostics.Debug.WriteLine("Variant data extracted:");
                    System.Diagnostics.Debug.WriteLine("  Variant ID: '" + variantId + "'");
                    System.Diagnostics.Debug.WriteLine("  Variant Name: '" + variantName + "'");
                    System.Diagnostics.Debug.WriteLine("  SKU: '" + variantSKU + "'");
                    System.Diagnostics.Debug.WriteLine("  Price: " + price);

                    if (string.IsNullOrWhiteSpace(variantId))
                        throw new ArgumentException("Variant ID is required.");
                    if (string.IsNullOrWhiteSpace(variantName))
                        throw new ArgumentException("Variant name is required.");
                    if (string.IsNullOrWhiteSpace(variantSKU))
                        throw new ArgumentException("Variant SKU is required.");
                    if (price <= 0)
                        throw new ArgumentException("Valid price is required.");

                    var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                    if (variantsColl == null)
                        throw new InvalidOperationException("Failed to retrieve the product variants collection from the database.");

                    System.Diagnostics.Debug.WriteLine("Creating MongoDB filter and update...");

                    FilterDefinition<ProductVariant> filter;
                    try 
                    {
                        filter = Builders<ProductVariant>.Filter.Eq("_id", new ObjectId(variantId));
                    }
                    catch (FormatException)
                    {
                        filter = Builders<ProductVariant>.Filter.Eq("_id", variantId);
                    }

                    // Capture a minimal before snapshot for the log
                    var beforeDoc = variantsColl.Find(filter).FirstOrDefault();

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

                    if (!string.IsNullOrWhiteSpace(variantImg))
                    {
                        update = update.Set("VariantImg", variantImg);
                    }

                    if (weight.HasValue)
                    {
                        update = update.Set("Weight", weight.Value);
                    }

                    System.Diagnostics.Debug.WriteLine("Executing UpdateOne operation...");
                    var result = variantsColl.UpdateOne(filter, update);

                    System.Diagnostics.Debug.WriteLine("Update result: MatchedCount=" + result.MatchedCount + ", ModifiedCount=" + result.ModifiedCount);

                    if (result.MatchedCount == 0)
                        throw new InvalidOperationException("No variant found with ID: " + variantId + ". Please check the Variant ID.");

                    if (result.ModifiedCount == 0)
                        System.Diagnostics.Debug.WriteLine("No changes were made (data might be the same)");

                    // Activity log with before/after
                    try
                    {
                        var details = new {
                            before = beforeDoc != null ? new { beforeDoc.Id, beforeDoc.VariantName, beforeDoc.SKU, beforeDoc.Price, beforeDoc.StockQuantity, beforeDoc.MinimumStock } : null,
                            after = new { Id = variantId, VariantName = variantName, SKU = variantSKU, Price = price, StockQuantity = stock, MinimumStock = minStock }
                        };
                        ActivityLogger.Log("Update", "ProductVariant", variantId, new JavaScriptSerializer().Serialize(details));
                    }
                    catch { }

                    System.Diagnostics.Debug.WriteLine("Variant updated successfully");
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
                System.Diagnostics.Debug.WriteLine("Error in UpdateVariant handler: " + ex.Message);
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