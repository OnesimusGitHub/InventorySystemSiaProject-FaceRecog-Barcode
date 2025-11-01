<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetArchivedProductVariants" %>

using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Handlers
{
    public class GetArchivedProductVariants : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();
            try
            {
                string productId = context.Request["productId"];
                if (string.IsNullOrWhiteSpace(productId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Product ID is required." }));
                    return;
                }

                ObjectId prodObjectId;
                try
                {
                    prodObjectId = ObjectId.Parse(productId);
                }
                catch (Exception ex)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid Product ID format.", details = ex.Message }));
                    return;
                }

                var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                var filter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.Eq("productId", prodObjectId),
                    Builders<ProductVariant>.Filter.Eq("isActive", false)
                );
                var archivedVariants = variantsColl.Find(filter).ToList();

                context.Response.Write(serializer.Serialize(new { success = true, variants = archivedVariants }));
            }
            catch (Exception ex)
            {
                context.Response.Write(serializer.Serialize(new { success = false, error = ex.Message, stack = ex.StackTrace }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
