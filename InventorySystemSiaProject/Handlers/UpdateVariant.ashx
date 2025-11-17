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
    using System.Collections;

namespace InventorySystemSiaProject.Handlers
{
    public class UpdateVariant : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            // ? FIX: Prevent form resubmission dialog by setting proper cache headers
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.Cache.SetNoStore();
            context.Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));
            context.Response.AppendHeader("Pragma", "no-cache");
            
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("========================================");
                System.Diagnostics.Debug.WriteLine("?? UpdateVariant handler called");
                System.Diagnostics.Debug.WriteLine("========================================");
                
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    System.Diagnostics.Debug.WriteLine("?? Received raw JSON data:");
                    System.Diagnostics.Debug.WriteLine(raw);

                    if (string.IsNullOrWhiteSpace(raw))
                    {
                        throw new ArgumentException("No data received in request body.");
                    }

                    var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                    System.Diagnostics.Debug.WriteLine("? Parsed request data keys: " + string.Join(", ", requestData.Keys));

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

                    // ? Parse shelf life years
                    int? shelfLifeYears = null;
                    if (requestData.ContainsKey("shelfLifeYears") && requestData["shelfLifeYears"] != null)
                    {
                        int years;
                        if (int.TryParse(requestData["shelfLifeYears"].ToString(), out years))
                        {
                            shelfLifeYears = years;
                        }
                    }

                    // ? Parse location
                    string location = requestData.ContainsKey("location") && requestData["location"] != null ? requestData["location"].ToString() : string.Empty;

                    // ========================================
                    // ?? DEBUG: Parse VariantImgUrls from request
                    // ========================================
                    List<string> variantImgUrls = null;
                    
                    System.Diagnostics.Debug.WriteLine("========================================");
                    System.Diagnostics.Debug.WriteLine("?? PARSING VARIANT IMAGE URLS");
                    System.Diagnostics.Debug.WriteLine("========================================");
                    
                    if (requestData.ContainsKey("VariantImgUrls"))
                    {
                        System.Diagnostics.Debug.WriteLine("? Key 'VariantImgUrls' found in request");
                        var imgUrlsData = requestData["VariantImgUrls"];
                        
                        if (imgUrlsData == null)
                        {
                            System.Diagnostics.Debug.WriteLine("?? VariantImgUrls is NULL");
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("?? VariantImgUrls type: " + imgUrlsData.GetType().Name);
                            
                            try
                            {
                                if (imgUrlsData is string)
                                {
                                    System.Diagnostics.Debug.WriteLine("?? VariantImgUrls is a STRING, deserializing...");
                                    System.Diagnostics.Debug.WriteLine("   String value: " + imgUrlsData.ToString());
                                    variantImgUrls = serializer.Deserialize<List<string>>(imgUrlsData.ToString());
                                    System.Diagnostics.Debug.WriteLine("? Deserialized to List<string>");
                                }
                                else if (imgUrlsData is ArrayList)
                                {
                                    System.Diagnostics.Debug.WriteLine("?? VariantImgUrls is an ARRAYLIST, converting...");
                                    var arr = (ArrayList)imgUrlsData;
                                    variantImgUrls = new List<string>();
                                    System.Diagnostics.Debug.WriteLine("   ArrayList count: " + arr.Count);
                                    
                                    for (int i = 0; i < arr.Count; i++)
                                    {
                                        if (arr[i] != null)
                                        {
                                            var url = arr[i].ToString();
                                            variantImgUrls.Add(url);
                                            System.Diagnostics.Debug.WriteLine("   [" + i + "] Added URL: " + url);
                                        }
                                        else
                                        {
                                            System.Diagnostics.Debug.WriteLine("   [" + i + "] NULL value, skipping");
                                        }
                                    }
                                    System.Diagnostics.Debug.WriteLine("? Converted ArrayList to List<string>");
                                }
                                else if (imgUrlsData is List<string>)
                                {
                                    System.Diagnostics.Debug.WriteLine("? VariantImgUrls is already a List<string>");
                                    variantImgUrls = (List<string>)imgUrlsData;
                                }
                                else
                                {
                                    System.Diagnostics.Debug.WriteLine("?? Unknown type: " + imgUrlsData.GetType().FullName);
                                }
                                
                                if (variantImgUrls != null)
                                {
                                    System.Diagnostics.Debug.WriteLine("========================================");
                                    System.Diagnostics.Debug.WriteLine("?? PARSED IMAGE URLS SUMMARY");
                                    System.Diagnostics.Debug.WriteLine("========================================");
                                    System.Diagnostics.Debug.WriteLine("   Total URLs: " + variantImgUrls.Count);
                                    for (int i = 0; i < variantImgUrls.Count; i++)
                                    {
                                        System.Diagnostics.Debug.WriteLine("   [" + i + "] " + variantImgUrls[i]);
                                    }
                                    System.Diagnostics.Debug.WriteLine("========================================");
                                }
                            }
                            catch (Exception parseEx)
                            {
                                System.Diagnostics.Debug.WriteLine("? ERROR parsing VariantImgUrls: " + parseEx.Message);
                                System.Diagnostics.Debug.WriteLine("   Stack trace: " + parseEx.StackTrace);
                                variantImgUrls = null;
                            }
                        }
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("?? Key 'VariantImgUrls' NOT FOUND in request");
                    }

                    System.Diagnostics.Debug.WriteLine("========================================");
                    System.Diagnostics.Debug.WriteLine("?? VARIANT DATA SUMMARY");
                    System.Diagnostics.Debug.WriteLine("========================================");
                    System.Diagnostics.Debug.WriteLine("  Variant ID: '" + variantId + "'");
                    System.Diagnostics.Debug.WriteLine("  Variant Name: '" + variantName + "'");
                    System.Diagnostics.Debug.WriteLine("  SKU: '" + variantSKU + "'");
                    System.Diagnostics.Debug.WriteLine("  Price: " + price);
                    System.Diagnostics.Debug.WriteLine("  Stock: " + stock);
                    System.Diagnostics.Debug.WriteLine("  Location: " + location);
                    System.Diagnostics.Debug.WriteLine("  Image URLs Count: " + (variantImgUrls != null ? variantImgUrls.Count.ToString() : "NULL"));
                    System.Diagnostics.Debug.WriteLine("========================================");

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

                    System.Diagnostics.Debug.WriteLine("?? Creating MongoDB filter and update...");

                    FilterDefinition<ProductVariant> filter;
                    try 
                    {
                        filter = Builders<ProductVariant>.Filter.Eq("_id", new ObjectId(variantId));
                    }
                    catch (FormatException)
                    {
                        filter = Builders<ProductVariant>.Filter.Eq("_id", variantId);
                    }

                    // ========================================
                    // ?? DEBUG: Capture BEFORE state
                    // ========================================
                    var beforeDoc = variantsColl.Find(filter).FirstOrDefault();
                    
                    if (beforeDoc != null)
                    {
                        System.Diagnostics.Debug.WriteLine("========================================");
                        System.Diagnostics.Debug.WriteLine("?? BEFORE UPDATE - DATABASE STATE");
                        System.Diagnostics.Debug.WriteLine("========================================");
                        System.Diagnostics.Debug.WriteLine("  Variant Name: " + beforeDoc.VariantName);
                        System.Diagnostics.Debug.WriteLine("  SKU: " + beforeDoc.SKU);
                        
                        if (beforeDoc.VariantImgUrls != null)
                        {
                            System.Diagnostics.Debug.WriteLine("  OLD Image URLs Count: " + beforeDoc.VariantImgUrls.Count);
                            for (int i = 0; i < beforeDoc.VariantImgUrls.Count; i++)
                            {
                                System.Diagnostics.Debug.WriteLine("    [" + i + "] " + beforeDoc.VariantImgUrls[i]);
                            }
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("  OLD Image URLs: NULL");
                        }
                        System.Diagnostics.Debug.WriteLine("========================================");
                    }

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

                    if (shelfLifeYears.HasValue)
                    {
                        update = update.Set("ShelfLifeYears", shelfLifeYears.Value);
                    }

                    if (!string.IsNullOrWhiteSpace(location))
                    {
                        update = update.Set("Location", location);
                    }

                    // ========================================
                    // ?? DEBUG: Update VariantImgUrls array
                    // ========================================
                    if (variantImgUrls != null)
                    {
                        System.Diagnostics.Debug.WriteLine("========================================");
                        System.Diagnostics.Debug.WriteLine("?? UPDATING IMAGE URLS IN DATABASE");
                        System.Diagnostics.Debug.WriteLine("========================================");
                        System.Diagnostics.Debug.WriteLine("  NEW Image URLs Count: " + variantImgUrls.Count);
                        for (int i = 0; i < variantImgUrls.Count; i++)
                        {
                            System.Diagnostics.Debug.WriteLine("    [" + i + "] " + variantImgUrls[i]);
                        }
                        
                        update = update.Set("VariantImgUrls", variantImgUrls);
                        System.Diagnostics.Debug.WriteLine("? Added .Set('VariantImgUrls', ...) to update definition");
                        System.Diagnostics.Debug.WriteLine("========================================");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("?? WARNING: variantImgUrls is NULL, NOT updating database field");
                    }

                    System.Diagnostics.Debug.WriteLine("?? Executing UpdateOne operation...");
                    var result = variantsColl.UpdateOne(filter, update);

                    System.Diagnostics.Debug.WriteLine("========================================");
                    System.Diagnostics.Debug.WriteLine("?? UPDATE RESULT");
                    System.Diagnostics.Debug.WriteLine("========================================");
                    System.Diagnostics.Debug.WriteLine("  Matched Count: " + result.MatchedCount);
                    System.Diagnostics.Debug.WriteLine("  Modified Count: " + result.ModifiedCount);
                    System.Diagnostics.Debug.WriteLine("========================================");

                    if (result.MatchedCount == 0)
                        throw new InvalidOperationException("No variant found with ID: " + variantId + ". Please check the Variant ID.");

                    if (result.ModifiedCount == 0)
                        System.Diagnostics.Debug.WriteLine("?? WARNING: No changes were made (data might be the same)");

                    // ========================================
                    // ?? DEBUG: Verify AFTER state
                    // ========================================
                    var afterDoc = variantsColl.Find(filter).FirstOrDefault();
                    
                    if (afterDoc != null)
                    {
                        System.Diagnostics.Debug.WriteLine("========================================");
                        System.Diagnostics.Debug.WriteLine("? AFTER UPDATE - DATABASE STATE");
                        System.Diagnostics.Debug.WriteLine("========================================");
                        System.Diagnostics.Debug.WriteLine("  Variant Name: " + afterDoc.VariantName);
                        System.Diagnostics.Debug.WriteLine("  SKU: " + afterDoc.SKU);
                        
                        if (afterDoc.VariantImgUrls != null)
                        {
                            System.Diagnostics.Debug.WriteLine("  CURRENT Image URLs Count: " + afterDoc.VariantImgUrls.Count);
                            for (int i = 0; i < afterDoc.VariantImgUrls.Count; i++)
                            {
                                System.Diagnostics.Debug.WriteLine("    [" + i + "] " + afterDoc.VariantImgUrls[i]);
                            }
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("  CURRENT Image URLs: NULL");
                        }
                        System.Diagnostics.Debug.WriteLine("========================================");
                        
                        // Compare before and after
                        if (beforeDoc != null)
                        {
                            System.Diagnostics.Debug.WriteLine("========================================");
                            System.Diagnostics.Debug.WriteLine("?? COMPARISON: BEFORE vs AFTER");
                            System.Diagnostics.Debug.WriteLine("========================================");
                            
                            int beforeCount = beforeDoc.VariantImgUrls != null ? beforeDoc.VariantImgUrls.Count : 0;
                            int afterCount = afterDoc.VariantImgUrls != null ? afterDoc.VariantImgUrls.Count : 0;
                            
                            System.Diagnostics.Debug.WriteLine("  Image URLs Count: " + beforeCount + " ? " + afterCount);
                            
                            if (variantImgUrls != null)
                            {
                                int expectedCount = variantImgUrls.Count;
                                System.Diagnostics.Debug.WriteLine("  Expected Count: " + expectedCount);
                                
                                if (afterCount == expectedCount)
                                {
                                    System.Diagnostics.Debug.WriteLine("  ? SUCCESS: Count matches expected!");
                                }
                                else
                                {
                                    System.Diagnostics.Debug.WriteLine("  ? MISMATCH: Expected " + expectedCount + " but got " + afterCount);
                                }
                            }
                            System.Diagnostics.Debug.WriteLine("========================================");
                        }
                    }

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

                    System.Diagnostics.Debug.WriteLine("========================================");
                    System.Diagnostics.Debug.WriteLine("? Variant updated successfully");
                    System.Diagnostics.Debug.WriteLine("========================================");
                    
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
                System.Diagnostics.Debug.WriteLine("========================================");
                System.Diagnostics.Debug.WriteLine("? ERROR in UpdateVariant handler");
                System.Diagnostics.Debug.WriteLine("========================================");
                System.Diagnostics.Debug.WriteLine("  Error Message: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("  Exception Type: " + ex.GetType().Name);
                System.Diagnostics.Debug.WriteLine("  Stack Trace: " + ex.StackTrace);
                System.Diagnostics.Debug.WriteLine("========================================");
                
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