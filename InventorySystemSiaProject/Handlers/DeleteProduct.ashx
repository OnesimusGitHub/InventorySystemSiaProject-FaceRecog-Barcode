<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteProduct" %>

using System;
using System.Web;
using System.Web.JavaScript;
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class DeleteProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("DeleteProduct handler called");
                
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    System.Diagnostics.Debug.WriteLine("Received raw data: " + raw);

                    if (string.IsNullOrWhiteSpace(raw))
                        throw new ArgumentException("No data received in request body.");

                    var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                    
                    string productId = requestData.ContainsKey("productId") && requestData["productId"] != null ? requestData["productId"].ToString() : null;
                    string adminPassword = requestData.ContainsKey("adminPassword") && requestData["adminPassword"] != null ? requestData["adminPassword"].ToString() : null;

                    System.Diagnostics.Debug.WriteLine("Delete request data:");
                    System.Diagnostics.Debug.WriteLine("  Product ID: '" + productId + "'");
                    System.Diagnostics.Debug.WriteLine("  Admin Password provided: " + (!string.IsNullOrEmpty(adminPassword)).ToString());

                    if (string.IsNullOrWhiteSpace(productId))
                        throw new ArgumentException("Product ID is required.");

                    // Optional admin password check (enforce in production)
                    if (!string.IsNullOrWhiteSpace(adminPassword))
                    {
                        if (!AdminAuthenticationService.ValidateAdminPassword(adminPassword))
                            throw new UnauthorizedAccessException("Invalid admin password.");
                    }

                    var productsColl = DatabaseHelper.GetProductsCollection();
                    if (productsColl == null)
                        throw new InvalidOperationException("Failed to retrieve the products collection from the database.");

                    // Create the filter using ObjectId
                    FilterDefinition<Product> filter;
                    try 
                    {
                        filter = Builders<Product>.Filter.Eq("_id", new ObjectId(productId));
                    }
                    catch (FormatException)
                    {
                        // If productId is not a valid ObjectId, try as string
                        filter = Builders<Product>.Filter.Eq("_id", productId);
                    }

                    System.Diagnostics.Debug.WriteLine("Executing delete operation...");
                    var result = productsColl.DeleteOne(filter);

                    System.Diagnostics.Debug.WriteLine("Delete result: DeletedCount=" + result.DeletedCount);

                    if (result.DeletedCount == 0)
                        throw new InvalidOperationException("No product found with ID: " + productId + ". Please check the Product ID.");

                    System.Diagnostics.Debug.WriteLine("Product deleted successfully");
                    context.Response.Write(serializer.Serialize(new { 
                        success = true, 
                        message = "Product deleted successfully.",
                        productId = productId
                    }));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error in DeleteProduct handler: " + ex.Message);
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