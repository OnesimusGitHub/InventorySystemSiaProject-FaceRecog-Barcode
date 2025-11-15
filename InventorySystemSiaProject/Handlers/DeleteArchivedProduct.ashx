<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteArchivedProduct" %>

using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using System.Security.Cryptography;
using System.Text;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.Handlers
{
    public class DeleteArchivedProduct : IHttpHandler, System.Web.SessionState.IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            // Prevent form resubmission dialog by setting proper cache headers
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.Cache.SetNoStore();
            context.Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));
            context.Response.AppendHeader("Pragma", "no-cache");
            
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                string productId = null;
                string adminPassword = null;
                
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    if (!string.IsNullOrWhiteSpace(raw))
                    {
                        var data = serializer.Deserialize<Dictionary<string, object>>(raw);
                        if (data != null)
                        {
                            if (data.ContainsKey("productId") && data["productId"] != null)
                            {
                                productId = data["productId"].ToString();
                            }
                            if (data.ContainsKey("adminPassword") && data["adminPassword"] != null)
                            {
                                adminPassword = data["adminPassword"].ToString();
                            }
                        }
                    }
                }

                // Fallback to querystring/form
                if (string.IsNullOrEmpty(productId))
                {
                    productId = context.Request["productId"];
                }
                if (string.IsNullOrEmpty(adminPassword))
                {
                    adminPassword = context.Request["adminPassword"];
                }

                // Validate required fields
                if (string.IsNullOrEmpty(productId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Missing productId." }));
                    return;
                }
                if (string.IsNullOrEmpty(adminPassword))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Missing admin password." }));
                    return;
                }

                // Session / role validation
                var session = context.Session;
                if (session == null || session["UserId"] == null)
                {
                    // Debug: Output session info
                    var sessionInfo = new Dictionary<string, object>();
                    sessionInfo["SessionId"] = context.Session != null ? context.Session.SessionID : "null";
                    if (session != null)
                    {
                        foreach (string key in session.Keys)
                        {
                            sessionInfo[key] = session[key];
                        }
                    }
                    context.Response.Write(serializer.Serialize(new { success = false, error = "User not logged in.", sessionDebug = sessionInfo }));
                    return;
                }

                string userId = session["UserId"].ToString();
                string userRole = session["UserRole"] != null ? session["UserRole"].ToString() : string.Empty;
                string userEmail = session["UserEmail"] as string;

                if (string.IsNullOrEmpty(userRole) || userRole.ToLower() != "admin")
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Only admin users can delete archived products." }));
                    return;
                }

                // MongoDB connection setup
                var mongoConnStr = System.Configuration.ConfigurationManager.ConnectionStrings["MongoDBConnection"].ConnectionString;
                var mongoDbName = System.Configuration.ConfigurationManager.AppSettings["MongoDBDatabase"];
                var client = new MongoClient(mongoConnStr);
                var db = client.GetDatabase(mongoDbName);
                var users = db.GetCollection<User>("Users");
                var products = db.GetCollection<BsonDocument>("Products");

                string debugLog = "[DEBUG] Using DB: " + mongoDbName + "\n";
                debugLog += "[DEBUG] Using Collection: Users\n";

                // List all user IDs in the collection for debugging
                var allUserIds = users.Find(_ => true).Project(u => u.Id).Limit(10).ToList();
                debugLog += "[DEBUG] First 10 user IDs in Users collection: " + string.Join(", ", allUserIds) + "\n";
                debugLog += "[DEBUG] Querying for user with Id: " + userId + "\n";

                // Query by ObjectId, not string
                ObjectId userObjectId;
                if (!ObjectId.TryParse(userId, out userObjectId))
                {
                    debugLog += "[DEBUG] Invalid ObjectId format for userId\n";
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid UserId format.", debug = debugLog }));
                    return;
                }
                var filter = Builders<User>.Filter.Eq("_id", userObjectId);
                debugLog += "[DEBUG] MongoDB filter: { _id: ObjectId('" + userObjectId.ToString() + "') }\n";
                var user = users.Find(filter).FirstOrDefault();
                if (user == null)
                {
                    debugLog += "[DEBUG] User not found for Id: " + userObjectId.ToString() + "\n";
                    context.Response.Write(serializer.Serialize(new { success = false, error = "User not found in DB for UserId: " + userId, debug = debugLog }));
                    return;
                }
                if (string.IsNullOrEmpty(user.PasswordHash))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "User found but passwordHash missing in DB for UserId: " + userId }));
                    return;
                }

                // Verify password
                string enteredHash = GetSHA256Hash(adminPassword);
                if (enteredHash != user.PasswordHash)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Incorrect admin password." }));
                    return;
                }

                // Delete product from MongoDB
                var prodFilter = Builders<BsonDocument>.Filter.Eq("_id", ObjectId.Parse(productId));
                var deleteResult = products.DeleteOne(prodFilter);
                
                if (deleteResult.DeletedCount > 0)
                {
                    // Log activity to ActivityLog collection
                    var activityLog = db.GetCollection<BsonDocument>("ActivityLog");
                    var logEntry = new BsonDocument
                    {
                        { "Action", "Delete" },
                        { "Entity", "Product" },
                        { "ProductId", productId },
                        { "UserId", userId },
                        { "UserEmail", userEmail ?? "" },
                        { "Timestamp", DateTime.UtcNow },
                        { "Details", "Archived product deleted via DeleteArchivedProduct.ashx" }
                    };
                    activityLog.InsertOne(logEntry);

                    context.Response.Write(serializer.Serialize(new { success = true, message = "Product deleted permanently." }));
                }
                else
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Product not found or already deleted." }));
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { 
                    success = false, 
                    error = ex.Message,
                    details = ex.GetType().Name
                }));
            }
        }

        public bool IsReusable { get { return false; } }

        private static string GetSHA256Hash(string input)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(input + "SaltKey2024"));
                return Convert.ToBase64String(bytes);
            }
        }
    }
}
