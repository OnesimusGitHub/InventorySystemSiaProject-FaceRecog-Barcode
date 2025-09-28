using System;
using System.Web;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.Helpers
{
    public static class ActivityLogger
    {
        public static void Log(string action, string entityType, string entityId, string detailsJson, string userId = null, string userName = null, string revertedFromId = null)
        {
            try
            {
                var ctx = HttpContext.Current;
                if (ctx != null)
                {
                    var ses = ctx.Session; // may be null for some handlers
                    if (string.IsNullOrWhiteSpace(userId)) userId = ses != null ? ses["UserId"] as string : null;
                    if (string.IsNullOrWhiteSpace(userName)) userName = ses != null ? ses["UserName"] as string : null;

                    // Fallbacks: try headers if session is not available
                    if (string.IsNullOrWhiteSpace(userName)) userName = ctx.Request.Headers["X-User-Name"]; 
                    if (string.IsNullOrWhiteSpace(userId)) userId = ctx.Request.Headers["X-User-Id"]; 
                }

                var log = new ActivityLog
                {
                    Timestamp = DateTime.UtcNow,
                    UserId = string.IsNullOrWhiteSpace(userId) ? null : userId,
                    UserName = string.IsNullOrWhiteSpace(userName) ? null : userName,
                    Action = action,
                    EntityType = entityType,
                    EntityId = entityId,
                    Details = detailsJson,
                    RevertedFromId = revertedFromId
                };
                DatabaseHelper.GetActivityLogCollection().InsertOne(log);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Activity log failed: " + ex.Message);
            }
        }
    }
}
