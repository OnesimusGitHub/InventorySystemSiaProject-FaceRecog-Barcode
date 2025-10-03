<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteVariant" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.SessionState; // enable session access

namespace InventorySystemSiaProject.Handlers
{
    public class DeleteVariant : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("DeleteVariant handler called");
                // ----- Read raw body -----
                context.Request.InputStream.Position = 0;
                string raw;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    raw = reader.ReadToEnd();
                }
                System.Diagnostics.Debug.WriteLine("Received raw data: " + raw);
                if (string.IsNullOrWhiteSpace(raw))
                    throw new ArgumentException("No data received in request body.");

                var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);
                string variantId = requestData.ContainsKey("variantId") && requestData["variantId"] != null ? requestData["variantId"].ToString() : null;
                string suppliedPassword = requestData.ContainsKey("adminPassword") && requestData["adminPassword"] != null ? requestData["adminPassword"].ToString() : null; // same key as product deletion

                System.Diagnostics.Debug.WriteLine("Delete variant request data:\n  Variant ID: '" + variantId + "'\n  Password supplied: " + (!string.IsNullOrEmpty(suppliedPassword)));                

                if (string.IsNullOrWhiteSpace(variantId))
                    throw new ArgumentException("Variant ID is required.");

                // ----- Session / admin validation -----
                var session = context.Session;
                if (session == null || session["UserId"] == null)
                    throw new UnauthorizedAccessException("User not logged in.");
                string userId = session["UserId"].ToString();
                string userRole = session["UserRole"] != null ? session["UserRole"].ToString() : string.Empty;
                if (string.IsNullOrEmpty(userRole) || userRole.ToLower() != "admin")
                    throw new UnauthorizedAccessException("Only admin users can delete variants.");

                if (string.IsNullOrEmpty(suppliedPassword))
                    throw new UnauthorizedAccessException("Admin password is required.");

                // Load admin user for password verification
                var usersColl = DatabaseHelper.GetUsersCollection();
                var user = usersColl.Find(u => u.Id == userId && u.IsActive).FirstOrDefault();
                if (user == null)
                    throw new UnauthorizedAccessException("Admin user not found or inactive.");
                if (!VerifyPassword(suppliedPassword, user.PasswordHash))
                    throw new UnauthorizedAccessException("Invalid admin password.");

                // ----- DB collection -----
                var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                if (variantsColl == null)
                    throw new InvalidOperationException("Failed to retrieve the product variants collection from the database.");

                // Build filter (ObjectId or string)
                FilterDefinition<ProductVariant> filter;
                try { filter = Builders<ProductVariant>.Filter.Eq("_id", new ObjectId(variantId)); }
                catch { filter = Builders<ProductVariant>.Filter.Eq("_id", variantId); }

                var beforeDoc = variantsColl.Find(filter).FirstOrDefault();
                if (beforeDoc == null)
                    throw new InvalidOperationException("No variant found with ID: " + variantId + ". Please check the Variant ID.");

                System.Diagnostics.Debug.WriteLine("Executing delete variant operation...");
                var result = variantsColl.DeleteOne(filter); // hard delete (kept as original behaviour)
                System.Diagnostics.Debug.WriteLine("Delete variant result: DeletedCount=" + result.DeletedCount);
                if (result.DeletedCount == 0)
                    throw new InvalidOperationException("Variant delete failed (not found after fetch).");

                // Log activity
                try
                {
                    var details = new { before = new { beforeDoc.Id, beforeDoc.VariantName, beforeDoc.SKU, beforeDoc.Price, beforeDoc.StockQuantity }, action = "HardDelete" };
                    ActivityLogger.Log("Delete", "ProductVariant", variantId, new JavaScriptSerializer().Serialize(details));
                }
                catch { }

                context.Response.Write(serializer.Serialize(new {
                    success = true,
                    message = "Variant deleted successfully.",
                    variantId = variantId
                }));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error in DeleteVariant handler: " + ex.Message);
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