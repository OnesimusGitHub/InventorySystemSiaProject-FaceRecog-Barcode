<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ArchiveProductVariant" %>

using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
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
                string variantId = context.Request["variantId"];
                // --- PATCH: Support JSON body for variantId ---
                if (string.IsNullOrWhiteSpace(variantId))
                {
                    context.Request.InputStream.Position = 0;
                    using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                    {
                        var body = reader.ReadToEnd();
                        if (!string.IsNullOrWhiteSpace(body))
                        {
                            try
                            {
                                var json = serializer.Deserialize<dynamic>(body);
                                if (json != null && json.ContainsKey("variantId"))
                                {
                                    variantId = json["variantId"];
                                }
                            }
                            catch (Exception ex)
                            {
                                context.Response.Write(serializer.Serialize(new { success = false, error = "JSON parse error: " + ex.Message, stack = ex.StackTrace }));
                                return;
                            }
                        }
                    }
                }
                // --- END PATCH ---
                if (string.IsNullOrWhiteSpace(variantId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant ID is required." }));
                    return;
                }

                ObjectId objectId;
                try
                {
                    objectId = ObjectId.Parse(variantId);
                }
                catch (Exception ex)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid Variant ID format.", details = ex.Message, stack = ex.StackTrace }));
                    return;
                }

                var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                var filter = Builders<ProductVariant>.Filter.Eq("_id", objectId);
                var update = Builders<ProductVariant>.Update.Set("isActive", false);
                var result = variantsColl.UpdateOne(filter, update);

                if (result.ModifiedCount > 0)
                {
                    context.Response.Write(serializer.Serialize(new { success = true, message = "Product variant archived successfully." }));
                }
                else
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Product variant not found or already archived." }));
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(serializer.Serialize(new { success = false, error = ex.Message, stack = ex.StackTrace }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
