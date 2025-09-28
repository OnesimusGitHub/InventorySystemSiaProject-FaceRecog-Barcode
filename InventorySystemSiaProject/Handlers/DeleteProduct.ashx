<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteProduct" %>

using System;
using System.Web;
using System.Web.Script.Serialization; // serializer (fixed)
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.SessionState; // for session access

namespace InventorySystemSiaProject.Handlers
{
    public class DeleteProduct : IHttpHandler, IRequiresSessionState
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
                    string suppliedPassword = requestData.ContainsKey("adminPassword") && requestData["adminPassword"] != null ? requestData["adminPassword"].ToString() : null; // reuse field label

                    System.Diagnostics.Debug.WriteLine("Delete request data:");
                    System.Diagnostics.Debug.WriteLine("  Product ID: '" + productId + "'");
                    System.Diagnostics.Debug.WriteLine("  Password supplied: " + (!string.IsNullOrEmpty(suppliedPassword)).ToString());

                    if (string.IsNullOrWhiteSpace(productId))
                        throw new ArgumentException("Product ID is required.");

                    // Session / role validation
                    var session = context.Session;
                    if (session == null || session["UserId"] == null)
                        throw new UnauthorizedAccessException("User not logged in.");

                    string userId = session["UserId"].ToString();
                    string userRole = session["UserRole"] != null ? session["UserRole"].ToString() : string.Empty;

                    if (string.IsNullOrEmpty(userRole) || userRole.ToLower() != "admin")
                        throw new UnauthorizedAccessException("Only admin users can delete products.");

                    // Load user to verify password (extra security layer)
                    var usersColl = DatabaseHelper.GetUsersCollection();
                    var user = usersColl.Find(u => u.Id == userId && u.IsActive).FirstOrDefault();
                    if (user == null)
                        throw new UnauthorizedAccessException("Admin user not found or inactive.");

                    if (string.IsNullOrEmpty(suppliedPassword))
                        throw new UnauthorizedAccessException("Admin password is required.");

                    if (!VerifyPassword(suppliedPassword, user.PasswordHash))
                        throw new UnauthorizedAccessException("Invalid admin password.");

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

                    // Capture a minimal before snapshot for the log
                    var beforeDoc = productsColl.Find(filter).FirstOrDefault();

                    System.Diagnostics.Debug.WriteLine("Executing delete operation...");
                    var result = productsColl.DeleteOne(filter);

                    System.Diagnostics.Debug.WriteLine("Delete result: DeletedCount=" + result.DeletedCount);

                    if (result.DeletedCount == 0)
                        throw new InvalidOperationException("No product found with ID: " + productId + ". Please check the Product ID.");

                    // Log activity
                    try
                    {
                        var details = new { before = beforeDoc != null ? new { beforeDoc.Id, beforeDoc.ProductName, beforeDoc.ProductCategory, beforeDoc.ProductVal } : null };
                        ActivityLogger.Log("Delete", "Product", productId, new JavaScriptSerializer().Serialize(details));
                    }
                    catch { }

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

        private bool VerifyPassword(string password, string storedHash)
        {
            try
            {
                using (var sha = SHA256.Create())
                {
                    var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(password + "SaltKey2024"));
                    var base64 = Convert.ToBase64String(bytes);
                    return string.Equals(base64, storedHash, StringComparison.Ordinal);
                }
            }
            catch { return false; }
        }

        public bool IsReusable { get { return false; } }
    }
}