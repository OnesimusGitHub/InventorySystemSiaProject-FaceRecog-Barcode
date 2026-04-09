<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetArchivedProductVariants" %>

using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using System.Linq;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using System.Web.Script.Serialization;

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
                if (!ObjectId.TryParse(productId, out prodObjectId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid Product ID format." }));
                    return;
                }

                var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                var bsonColl = variantsColl.Database.GetCollection<BsonDocument>(
                    DatabaseHelper.GetProductVariantsCollectionName());

                // ✅ Archived = Status == "Archived"
                var filter = Builders<BsonDocument>.Filter.And(
                    Builders<BsonDocument>.Filter.Or(
                        Builders<BsonDocument>.Filter.Eq("productId", prodObjectId),
                        Builders<BsonDocument>.Filter.Eq("productId", productId)
                    ),
                    Builders<BsonDocument>.Filter.Eq("Status", "Archived")
                );

                var docs = bsonColl.Find(filter).ToList();

                var archivedVariants = docs.Select(d => new
                {
                    Id = d.Contains("_id") ? d["_id"].ToString() : null,
                    VariantName = d.Contains("variantName") ? d["variantName"].AsString : null,
                    SKU = d.Contains("sku") ? d["sku"].AsString : null,
                    Size = d.Contains("size") ? d["size"].AsString : null,
                    Color = d.Contains("color") ? d["color"].AsString : null,
                    Price = (d.Contains("price") && d["price"].IsNumeric) ? (decimal)d["price"].ToDouble() : 0,
                    StockQuantity = (d.Contains("stockQuantity") && d["stockQuantity"].IsNumeric)
                        ? Convert.ToInt32(d["stockQuantity"].ToDouble()) : 0,
                    MinimumStock = (d.Contains("minimumStock") && d["minimumStock"].IsNumeric)
                        ? Convert.ToInt32(d["minimumStock"].ToDouble()) : 0,
                    Status = d.Contains("Status") ? d["Status"].AsString : null
                }).ToList();

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