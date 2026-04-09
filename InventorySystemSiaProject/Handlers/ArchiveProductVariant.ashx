<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ArchiveProductVariant" %>

using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    public class ArchiveProductVariant : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                string body;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    body = reader.ReadToEnd();
                }

                var dto = serializer.Deserialize<dynamic>(body);
                string variantId = dto["variantId"];

                if (string.IsNullOrWhiteSpace(variantId))
                {
                    context.Response.Write(serializer.Serialize(
                        new { success = false, error = "Variant ID is required." }));
                    return;
                }

                ObjectId varObjectId;
                if (!ObjectId.TryParse(variantId, out varObjectId))
                {
                    context.Response.Write(serializer.Serialize(
                        new { success = false, error = "Invalid Variant ID format." }));
                    return;
                }

                var variantsColl = DatabaseHelper.GetProductVariantsCollection();

                // Only archive variants that are NOT already Archived
                var filter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.Eq("_id", varObjectId),
                    Builders<ProductVariant>.Filter.Ne("Status", "Archived")
                );

                var update = Builders<ProductVariant>.Update
                    .Set("Status", "Archived")           // 🔑 main flag
                    .Set("isActive", false)              // optional: keep for backwards-compat
                    .Set("archivedAt", DateTime.UtcNow);

                var result = variantsColl.UpdateOne(filter, update);

                if (result.ModifiedCount == 0)
                {
                    context.Response.Write(serializer.Serialize(
                        new { success = false, error = "Product variant not found or already archived." }));
                    return;
                }

                context.Response.Write(serializer.Serialize(new { success = true }));
            }
            catch (Exception ex)
            {
                context.Response.Write(serializer.Serialize(
                    new { success = false, error = ex.Message, stack = ex.StackTrace }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}