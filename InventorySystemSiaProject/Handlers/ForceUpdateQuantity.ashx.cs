using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Direct MongoDB update handler - forces quantity field on all EmployeeActivity records
    /// </summary>
    public class ForceUpdateQuantity : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            
            try
            {
                System.Diagnostics.Debug.WriteLine("[ForceUpdateQuantity] STARTING FORCE UPDATE");

                // Get collection directly
                var db = DatabaseHelper.Database;
                var collection = db.GetCollection<BsonDocument>("EmployeeActivities");

                System.Diagnostics.Debug.WriteLine("[ForceUpdateQuantity] Connected to EmployeeActivities collection");

                // Step 1: Get total count
                long totalCount = collection.CountDocuments(FilterDefinition<BsonDocument>.Empty);
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] Total records: {totalCount}");
                context.Response.Write($"Total records in collection: {totalCount}\r\n");

                // Step 2: Count records WITHOUT quantity field
                var noQuantityFilter = Builders<BsonDocument>.Filter.Not(
                    Builders<BsonDocument>.Filter.Exists("quantity")
                );
                long noQuantityCount = collection.CountDocuments(noQuantityFilter);
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] Records without quantity field: {noQuantityCount}");
                context.Response.Write($"Records without quantity field: {noQuantityCount}\r\n");

                // Step 3: Count records with NULL quantity
                var nullQuantityFilter = Builders<BsonDocument>.Filter.Eq("quantity", BsonNull.Value);
                long nullQuantityCount = collection.CountDocuments(nullQuantityFilter);
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] Records with null quantity: {nullQuantityCount}");
                context.Response.Write($"Records with null quantity: {nullQuantityCount}\r\n");

                // Step 4: UPDATE - Set ALL records to have quantity = 0
                System.Diagnostics.Debug.WriteLine("[ForceUpdateQuantity] Executing bulk update...");
                context.Response.Write("\r\n--- APPLYING UPDATE ---\r\n");

                var updateFilter = Builders<BsonDocument>.Filter.Empty; // ALL records
                var updateDef = Builders<BsonDocument>.Update.Set("quantity", 0);
                
                var result = collection.UpdateMany(updateFilter, updateDef);
                
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] Update result - Matched: {result.MatchedCount}, Modified: {result.ModifiedCount}");
                context.Response.Write($"Records matched: {result.MatchedCount}\r\n");
                context.Response.Write($"Records modified: {result.ModifiedCount}\r\n");

                // Step 5: Verify - recount
                long verifyNoQuantity = collection.CountDocuments(noQuantityFilter);
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] After update - Records without quantity: {verifyNoQuantity}");
                context.Response.Write($"\r\n--- VERIFICATION ---\r\n");
                context.Response.Write($"Records still without quantity: {verifyNoQuantity}\r\n");

                if (verifyNoQuantity == 0)
                {
                    context.Response.Write("\r\n? SUCCESS! All records now have quantity field set to 0\r\n");
                    System.Diagnostics.Debug.WriteLine("[ForceUpdateQuantity] SUCCESS - All records updated!");
                }
                else
                {
                    context.Response.Write($"\r\n?? WARNING: {verifyNoQuantity} records still missing quantity field\r\n");
                    System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] WARNING - {verifyNoQuantity} records still need updating");
                }

                context.Response.Write("\r\nNext: Go to Activity Log page and refresh with Ctrl+F5\r\n");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] ERROR: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[ForceUpdateQuantity] Stack: {ex.StackTrace}");
                context.Response.Write($"ERROR: {ex.Message}\r\n");
                context.Response.Write($"Details: {ex.StackTrace}\r\n");
            }
        }

        public bool IsReusable => false;
    }
}
