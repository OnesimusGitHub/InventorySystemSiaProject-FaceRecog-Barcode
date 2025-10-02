<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteProduct" %>

using System;
using System.Web;
using System.Web.Script.Serialization; // correct namespace
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
                    
                    string productId = requestData.ContainsKey("productId") && requestData["productId"] != null ? requestData["productId"].ToString().Trim() : null;
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

                    // Build resilient filter that supports both ObjectId and string ids
                    var filters = new List<FilterDefinition<Product>>();
                    try { filters.Add(Builders<Product>.Filter.Eq("_id", new ObjectId(productId))); } catch { /* ignore */ }
                    filters.Add(Builders<Product>.Filter.Eq("_id", productId)); // string _id (legacy docs)
                    filters.Add(Builders<Product>.Filter.Eq(p => p.Id, productId)); // typed filter (maps to _id)
                    var anyIdFilter = Builders<Product>.Filter.Or(filters);

                    // Try to find document first
                    var beforeDoc = productsColl.Find(anyIdFilter).FirstOrDefault();

                    if (beforeDoc == null)
                    {
                        System.Diagnostics.Debug.WriteLine("Product not found with typed filters; trying BsonDocument fallback.");

                        // FINAL FALLBACK: query as BsonDocument using multiple strategies
                        var bsonColl = productsColl.Database.GetCollection<MongoDB.Bson.BsonDocument>(DatabaseHelper.GetProductsCollectionName());
                        MongoDB.Bson.BsonDocument rawDoc = null;
                        try { rawDoc = bsonColl.Find(Builders<MongoDB.Bson.BsonDocument>.Filter.Eq("_id", new ObjectId(productId))).FirstOrDefault(); } catch { }
                        if (rawDoc == null)
                        {
                            try { rawDoc = bsonColl.Find(Builders<MongoDB.Bson.BsonDocument>.Filter.Eq("_id", productId)).FirstOrDefault(); } catch { }
                        }
                        if (rawDoc != null)
                        {
                            // Create minimal placeholder just to carry the Id forward
                            var canonicalId = rawDoc["_id"].ToString();
                            beforeDoc = new Product { Id = canonicalId };
                        }
                        else
                        {
                            // Idempotent delete: treat not-found as success
                            context.Response.StatusCode = 200;
                            context.Response.Write(serializer.Serialize(new {
                                success = true,
                                message = "Product already removed or does not exist.",
                                productId = productId
                            }));
                            return;
                        }
                    }

                    // Prefer soft-delete for safety (set IsActive=false)
                    var softDelete = Builders<Product>.Update.Set(p => p.IsActive, false);
                    FilterDefinition<Product> softFilter;
                    try { softFilter = Builders<Product>.Filter.Eq("_id", new ObjectId(beforeDoc.Id)); }
                    catch { softFilter = Builders<Product>.Filter.Eq(p => p.Id, beforeDoc.Id); }
                    var softRes = productsColl.UpdateOne(softFilter, softDelete);
                    System.Diagnostics.Debug.WriteLine("Soft delete Matched=" + softRes.MatchedCount + ", Modified=" + softRes.ModifiedCount);

                    // As a fallback, if nothing was modified (already inactive?), still return success
                    if (softRes.MatchedCount == 0)
                    {
                        System.Diagnostics.Debug.WriteLine("Soft delete matched 0; product might already be removed. Returning success.");
                    }

                    // Cascade soft delete variants for this product so UI stays consistent
                    try
                    {
                        var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                        var vFilter = Builders<ProductVariant>.Filter.Eq(v => v.ProductId, beforeDoc.Id);
                        var vUpdate = Builders<ProductVariant>.Update.Set(v => v.IsActive, false);
                        var vRes = variantsColl.UpdateMany(vFilter, vUpdate);
                        System.Diagnostics.Debug.WriteLine("Cascade variants soft-deleted: Matched=" + vRes.MatchedCount + ", Modified=" + vRes.ModifiedCount);
                    }
                    catch (Exception cex)
                    {
                        System.Diagnostics.Debug.WriteLine("Variant cascade delete warning: " + cex.Message);
                    }

                    // Log activity
                    try
                    {
                        var details = new { before = new { beforeDoc.Id }, action = "SoftDelete" };
                        ActivityLogger.Log("Delete", "Product", beforeDoc.Id, new JavaScriptSerializer().Serialize(details));
                    }
                    catch { }

                    System.Diagnostics.Debug.WriteLine("Product deleted successfully (soft-delete)");
                    context.Response.Write(serializer.Serialize(new { 
                        success = true, 
                        message = "Product deleted successfully.",
                        productId = beforeDoc.Id
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