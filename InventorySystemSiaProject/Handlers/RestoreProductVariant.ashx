<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.RestoreProductVariant" %>

using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using System.Web.Script.Serialization;

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

                // Only restore if currently Archived
                var filter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.Eq("_id", varObjectId),
                    Builders<ProductVariant>.Filter.Eq("Status", "Archived")
                );

                var update = Builders<ProductVariant>.Update
                    .Set("Status", "Active")   // back to active
                    .Set("isActive", true)     // keep this in sync
                    .Set("archivedAt", BsonNull.Value);

                var result = variantsColl.UpdateOne(filter, update);

                if (result.ModifiedCount == 0)
                {
                    context.Response.Write(serializer.Serialize(
                        new { success = false, error = "Variant not found or already active." }));
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