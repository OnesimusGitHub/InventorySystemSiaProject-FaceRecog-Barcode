using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Handler to fix missing quantity values in EmployeeActivity records
    /// This populates null/missing quantity fields with 0
    /// </summary>
    public class FixEmployeeActivityQuantity : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("[FixEmployeeActivityQuantity] Handler started");

                // Get the EmployeeActivities collection
                var employeeActivitiesCollection = DatabaseHelper.GetCollection<BsonDocument>("EmployeeActivities");
                
                if (employeeActivitiesCollection == null)
                {
                    System.Diagnostics.Debug.WriteLine("[FixEmployeeActivityQuantity] ERROR: Collection is null");
                    WriteJsonResponse(context, false, "ERROR: Could not connect to EmployeeActivities collection", 0, 0);
                    return;
                }

                System.Diagnostics.Debug.WriteLine("[FixEmployeeActivityQuantity] Connected to collection");

                // Count ALL records first
                long totalRecords = 0;
                try
                {
                    totalRecords = employeeActivitiesCollection.CountDocuments(FilterDefinition<BsonDocument>.Empty);
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Total records: {totalRecords}");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Error counting total: {ex.Message}");
                }

                // Create filter: Find all documents where quantity field is missing or is null
                // This is the correct MongoDB query
                var filterBuilder = Builders<BsonDocument>.Filter;
                var filter = filterBuilder.Or(
                    filterBuilder.Not(filterBuilder.Exists("quantity")),
                    filterBuilder.Eq("quantity", BsonNull.Value),
                    filterBuilder.Eq("quantity", 0)  // Include zeros to ensure all are set
                );

                // Count matching documents
                long matchedCount = 0;
                try
                {
                    matchedCount = employeeActivitiesCollection.CountDocuments(filter);
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Matched records: {matchedCount}");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Error counting matched: {ex.Message}");
                }

                if (matchedCount == 0)
                {
                    System.Diagnostics.Debug.WriteLine("[FixEmployeeActivityQuantity] No records to update");
                    WriteJsonResponse(context, true, "All records already have quantity field set", totalRecords, 0);
                    return;
                }

                // Create update: Set quantity to 0 for all matching records
                var update = Builders<BsonDocument>.Update.Set("quantity", 0);

                // Execute the batch update
                System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Executing UpdateMany on {matchedCount} records");
                UpdateResult updateResult = null;
                try
                {
                    updateResult = employeeActivitiesCollection.UpdateMany(filter, update);
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] UpdateMany completed. ModifiedCount: {updateResult.ModifiedCount}");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] ERROR during UpdateMany: {ex.Message}");
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Stack trace: {ex.StackTrace}");
                    WriteJsonResponse(context, false, $"ERROR during update: {ex.Message}", matchedCount, 0);
                    return;
                }

                // Verify the fix
                long verifyCount = 0;
                try
                {
                    var verifyFilter = filterBuilder.Or(
                        filterBuilder.Not(filterBuilder.Exists("quantity")),
                        filterBuilder.Eq("quantity", BsonNull.Value)
                    );
                    verifyCount = employeeActivitiesCollection.CountDocuments(verifyFilter);
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Verification: {verifyCount} records still missing quantity");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Error during verification: {ex.Message}");
                }

                System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Fix completed successfully");
                WriteJsonResponse(context, true, 
                    $"Successfully fixed {updateResult.ModifiedCount} records. {verifyCount} may still need attention if they had errors.",
                    matchedCount, updateResult.ModifiedCount);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] UNHANDLED EXCEPTION: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Stack trace: {ex.StackTrace}");
                WriteJsonResponse(context, false, $"Unexpected error: {ex.Message}", 0, 0);
            }
        }

        private void WriteJsonResponse(HttpContext context, bool success, string message, long matched, long modified)
        {
            try
            {
                var serializer = new JavaScriptSerializer();
                var response = new
                {
                    success = success,
                    message = message,
                    matched = matched,
                    modified = modified,
                    timestamp = DateTime.UtcNow.ToString("O")
                };

                string json = serializer.Serialize(response);
                System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Response: {json}");
                context.Response.Write(json);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FixEmployeeActivityQuantity] Error writing response: {ex.Message}");
                context.Response.Write("{\"success\":false,\"message\":\"Error writing response\"}");
            }
        }

        public bool IsReusable => false;
    }
}
