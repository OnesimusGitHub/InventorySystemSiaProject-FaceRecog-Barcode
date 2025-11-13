<%@ WebHandler Language="C#" Class="Handlers.GetDashboardIndicators" %>

using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;

namespace Handlers
{
    public class GetDashboardIndicators : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            try
            {
                var db = DatabaseHelper.GetDatabase();

                // Total Stocks: sum of all product variant quantities
                var productVariants = db.GetCollection<BsonDocument>("product_variants");
                long totalStocks = 0;
                var variants = productVariants.Find(new BsonDocument()).ToList();
                foreach (var variant in variants)
                {
                    if (variant.Contains("quantity") && variant["quantity"].IsInt32)
                        totalStocks += variant["quantity"].AsInt32;
                }

                // Total Products: count of products
                var products = db.GetCollection<BsonDocument>("products");
                long totalProducts = products.CountDocuments(new BsonDocument());

                // Archived Products: count of products with isArchived = true
                var archivedFilter = Builders<BsonDocument>.Filter.Eq("isArchived", true);
                long archivedProducts = products.CountDocuments(archivedFilter);

                var result = new
                {
                    totalStocks,
                    totalProducts,
                    archivedProducts
                };
                context.Response.Write(Newtonsoft.Json.JsonConvert.SerializeObject(result));
            }
            catch (Exception ex)
            {
                context.Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
