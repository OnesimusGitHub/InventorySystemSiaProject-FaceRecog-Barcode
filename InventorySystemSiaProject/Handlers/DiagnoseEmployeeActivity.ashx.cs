using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Diagnostic handler to analyze EmployeeActivity records
    /// </summary>
    public class DiagnoseEmployeeActivity : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            try
            {
                var collection = DatabaseHelper.GetCollection<BsonDocument>("EmployeeActivities");

                // Total count
                long totalCount = collection.CountDocuments(FilterDefinition<BsonDocument>.Empty);

                // Count with quantity field
                var withQuantityFilter = Builders<BsonDocument>.Filter.Exists("quantity");
                long withQuantity = collection.CountDocuments(withQuantityFilter);

                // Count without quantity field
                var withoutQuantityFilter = Builders<BsonDocument>.Filter.Not(withQuantityFilter);
                long withoutQuantity = collection.CountDocuments(withoutQuantityFilter);

                // Count with null quantity
                var nullQuantityFilter = Builders<BsonDocument>.Filter.Eq("quantity", BsonNull.Value);
                long nullQuantity = collection.CountDocuments(nullQuantityFilter);

                // Sample a few records to see their structure
                var sampleRecords = collection.Find(FilterDefinition<BsonDocument>.Empty).Limit(3).ToList();

                WriteResponse(context, new
                {
                    success = true,
                    totalRecords = totalCount,
                    withQuantityField = withQuantity,
                    withoutQuantityField = withoutQuantity,
                    withNullQuantity = nullQuantity,
                    sampleRecords = sampleRecords,
                    readyToFix = withoutQuantity + nullQuantity > 0
                });
            }
            catch (Exception ex)
            {
                WriteResponse(context, new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        private void WriteResponse(HttpContext context, object data)
        {
            var serializer = new JavaScriptSerializer();
            context.Response.Write(serializer.Serialize(data));
        }

        public bool IsReusable => false;
    }
}
