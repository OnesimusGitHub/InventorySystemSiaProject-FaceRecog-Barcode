<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteVariant" %>

using System;
using System.Web;
using System.Web.JavaScript.Serialization;
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class DeleteVariant : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("DeleteVariant handler called");
                
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    System.Diagnostics.Debug.WriteLine("Received raw data: " + raw);

                    if (string.IsNullOrWhiteSpace(raw))
                    {
                        throw new ArgumentException("No data received in request body.");
                    }

                    // Parse the JSON data as a dictionary first
                    var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                    
                    string variantId = requestData.ContainsKey("variantId") && requestData["variantId"] != null ? requestData["variantId"].ToString() : null;

                    System.Diagnostics.Debug.WriteLine("Delete variant request data:");
                    System.Diagnostics.Debug.WriteLine("  Variant ID: '" + variantId + "'");

                    if (string.IsNullOrWhiteSpace(variantId))
                    {
                        throw new ArgumentException("Variant ID is required.");
                    }

                    var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                    if (variantsColl == null)
                    {
                        throw new InvalidOperationException("Failed to retrieve the product variants collection from the database.");
                    }

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

                    System.Diagnostics.Debug.WriteLine("Executing delete variant operation...");
                    var result = variantsColl.DeleteOne(filter);

                    System.Diagnostics.Debug.WriteLine("Delete variant result: DeletedCount=" + result.DeletedCount);

                    if (result.DeletedCount == 0)
                    {
                        throw new InvalidOperationException("No variant found with ID: " + variantId + ". Please check the Variant ID.");
                    }

                    System.Diagnostics.Debug.WriteLine("Variant deleted successfully");
                    context.Response.Write(serializer.Serialize(new { 
                        success = true, 
                        message = "Variant deleted successfully.",
                        variantId = variantId
                    }));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error in DeleteVariant handler: " + ex.Message);
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