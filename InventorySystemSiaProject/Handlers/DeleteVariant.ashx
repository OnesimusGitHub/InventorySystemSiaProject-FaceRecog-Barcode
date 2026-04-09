<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.DeleteVariant" %>

using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;

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

                // Work at raw BSON level to avoid ProductVariant deserialization issues
                var typedColl = DatabaseHelper.GetProductVariantsCollection();
                var bsonColl = typedColl.Database.GetCollection<BsonDocument>(
                    typedColl.CollectionNamespace.CollectionName);

                var filter = Builders<BsonDocument>.Filter.Eq("_id", varObjectId);

                // Physically delete; if you only soft-delete, replace with UpdateOne
                var result = bsonColl.DeleteOne(filter);

                if (result.DeletedCount == 0)
                {
                    context.Response.Write(serializer.Serialize(
                        new { success = false, error = "Variant not found or already deleted." }));
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