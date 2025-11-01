<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.RestoreProductVariant" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class RestoreProductVariant : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();
            try
            {
                string json;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    json = reader.ReadToEnd();
                }
                
                var data = serializer.Deserialize<RestoreRequest>(json);
                if (data == null || string.IsNullOrEmpty(data.variantId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid variantId." }));
                    return;
                }
                
                // Validate MongoDB ObjectId format (24 hex characters)
                if (data.variantId.Length != 24 || !System.Text.RegularExpressions.Regex.IsMatch(data.variantId, "^[0-9a-fA-F]{24}$"))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid variantId format. Expected MongoDB ObjectId." }));
                    return;
                }
                
                // Get MongoDB collection
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                if (variantsCollection == null)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Database connection failed." }));
                    return;
                }
                
                // Create filter for MongoDB
                var filter = Builders<ProductVariant>.Filter.Eq("_id", new ObjectId(data.variantId));
                
                // Create update to set IsActive to true
                var update = Builders<ProductVariant>.Update
                    .Set(v => v.IsActive, true)
                    .Set(v => v.UpdatedAt, DateTime.UtcNow);
                
                // Execute update
                var result = variantsCollection.UpdateOne(filter, update);
                
                if (result.ModifiedCount > 0)
                {
                    context.Response.Write(serializer.Serialize(new { success = true, message = "Variant restored successfully!" }));
                }
                else if (result.MatchedCount > 0)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant is already active." }));
                }
                else
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant not found." }));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("RestoreProductVariant error: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("Stack trace: {0}", ex.StackTrace));
                context.Response.Write(serializer.Serialize(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable { get { return false; } }

        private class RestoreRequest
        {
            public string variantId { get; set; }
        }
    }
}