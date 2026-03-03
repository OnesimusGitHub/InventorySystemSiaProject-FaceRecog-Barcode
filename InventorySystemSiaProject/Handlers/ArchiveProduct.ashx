<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ArchiveProduct" %>

using System;
using System.Web;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.Handlers
{
    public class ArchiveProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            try
            {
                string productId = context.Request["productId"];
                if (string.IsNullOrWhiteSpace(productId))
                {
                    context.Response.Write("{\"success\":false,\"error\":\"Missing productId\"}");
                    return;
                }
                string status = context.Request["status"] ?? "Inactive";
                var products = DatabaseHelper.GetProductsCollection();
                // Build robust filter supporting ObjectId and string
                var filters = new System.Collections.Generic.List<FilterDefinition<Product>>();
                try { filters.Add(Builders<Product>.Filter.Eq("_id", new MongoDB.Bson.ObjectId(productId))); } catch { /* ignore */ }
                filters.Add(Builders<Product>.Filter.Eq("_id", productId));
                filters.Add(Builders<Product>.Filter.Eq(p => p.Id, productId));
                var anyIdFilter = Builders<Product>.Filter.Or(filters);
                var update = Builders<Product>.Update.Set(p => p.status, status);
                var result = products.UpdateOne(anyIdFilter, update);
                if (result.ModifiedCount > 0)
                {
                    context.Response.Write("{\"success\":true}");
                }
                else
                {
                    context.Response.Write("{\"success\":false,\"error\":\"Product not found or already archived\"}");
                }
            }
            catch (Exception ex)
            {
                context.Response.Write("{\"success\":false,\"error\":\""
                    + HttpUtility.JavaScriptStringEncode(ex.Message)
                    + "\",\"stack\":\""
                    + HttpUtility.JavaScriptStringEncode(ex.StackTrace ?? "")
                    + "\"}");
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
