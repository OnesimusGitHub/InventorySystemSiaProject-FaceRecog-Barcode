<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateStockRequestStatus" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class UpdateStockRequestStatus : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.Cache.SetNoStore();
            context.Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));
            context.Response.AppendHeader("Pragma", "no-cache");

            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    if (string.IsNullOrWhiteSpace(raw))
                        throw new ArgumentException("No data received in request body.");

                    var requestData = serializer.Deserialize<Dictionary<string, object>>(raw);

                    string requestId = requestData.ContainsKey("requestId") && requestData["requestId"] != null ? requestData["requestId"].ToString() : null;
                    string newStatus = requestData.ContainsKey("newStatus") && requestData["newStatus"] != null ? requestData["newStatus"].ToString() : null;

                    if (string.IsNullOrWhiteSpace(requestId))
                        throw new ArgumentException("requestId is required.");
                    if (string.IsNullOrWhiteSpace(newStatus))
                        throw new ArgumentException("newStatus is required.");

                    var stockRequestsColl = DatabaseHelper.GetStockRequestsCollection();
                    if (stockRequestsColl == null)
                        throw new InvalidOperationException("Failed to retrieve the stock requests collection from the database.");

                    FilterDefinition<StockRequest> filter;
                    try
                    {
                        filter = Builders<StockRequest>.Filter.Eq("_id", new ObjectId(requestId));
                    }
                    catch (FormatException)
                    {
                        filter = Builders<StockRequest>.Filter.Eq("_id", requestId);
                    }

                    var update = Builders<StockRequest>.Update
                        .Set("requestStatus", newStatus)
                        .Set("statusUpdatedDate", DateTime.UtcNow)
                        .Set("updatedAt", DateTime.UtcNow);

                    var result = stockRequestsColl.UpdateOne(filter, update);

                    if (result.MatchedCount == 0)
                        throw new InvalidOperationException("No stock request found with ID: " + requestId);

                    context.Response.Write(serializer.Serialize(new
                    {
                        success = true,
                        message = "Stock request status updated successfully.",
                        requestId = requestId,
                        newStatus = newStatus
                    }));
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new
                {
                    error = ex.Message,
                    details = ex.GetType().Name,
                    success = false
                }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
