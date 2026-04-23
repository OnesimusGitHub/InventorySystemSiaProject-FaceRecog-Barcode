using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetNearExpiryPackages : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                int days = 30;
                int.TryParse(context.Request.QueryString["days"], out days);
                if (days <= 0) days = 30;

                var now = DateTime.UtcNow;
                var start = now.AddDays(-days); // include recently expired
                var end = now.AddDays(days);

                bool debug = string.Equals(context.Request.QueryString["debug"], "1", StringComparison.OrdinalIgnoreCase)
                             || string.Equals(context.Request.QueryString["debug"], "true", StringComparison.OrdinalIgnoreCase);

                var col = DatabaseHelper.Database.GetCollection<BsonDocument>("PackageStockEntries");

                // require an expiration date (handle common casings) and not null
                var existsFilter =
                    (Builders<BsonDocument>.Filter.Exists("expirationAt", true) & Builders<BsonDocument>.Filter.Ne("expirationAt", BsonNull.Value))
                    | (Builders<BsonDocument>.Filter.Exists("ExpirationAt", true) & Builders<BsonDocument>.Filter.Ne("ExpirationAt", BsonNull.Value));

                // outinInventory must be missing/null OR explicitly false
                var outInFilter = Builders<BsonDocument>.Filter.Or(
                    Builders<BsonDocument>.Filter.Exists("outinInventory", false),        // field missing
                    Builders<BsonDocument>.Filter.Eq("outinInventory", false),          // explicit false
                    Builders<BsonDocument>.Filter.Eq("outinInventory", BsonNull.Value)  // explicit null
                );

                var finalFilter = Builders<BsonDocument>.Filter.And(existsFilter, outInFilter);

                var projection = Builders<BsonDocument>.Projection
                    .Include("packageId").Include("PackageId").Include("packageID")
                    .Include("itemType").Include("itemId")
                    .Include("sku").Include("quantity")
                    .Include("manufacturedAt").Include("ManufacturedAt")
                    .Include("expirationAt").Include("ExpirationAt")
                    .Include("outinInventory");

                var docs = col.Find(finalFilter)
                              .Project(projection)
                              .Sort(Builders<BsonDocument>.Sort.Ascending("expirationAt"))
                              .Limit(500)
                              .ToList();

                var totalWithExpiry = col.CountDocuments(finalFilter);

                var resultList = new List<Dictionary<string, object>>(docs.Count);
                int matchedInRange = 0;

                foreach (var d in docs)
                {
                    // prefer explicit expirationAt fields
                    BsonValue expVal = null;
                    if (d.TryGetValue("expirationAt", out var ev) && ev != null && ev.BsonType != BsonType.Null) expVal = ev;
                    else if (d.TryGetValue("ExpirationAt", out ev) && ev != null && ev.BsonType != BsonType.Null) expVal = ev;

                    if (expVal == null) continue;

                    DateTime expDate;
                    if (!TryParseDate(expVal, out expDate)) continue;

                    var expUtc = expDate.ToUniversalTime();

                    // only include entries within the lookback window
                    if (expUtc < start || expUtc > end) continue;

                    matchedInRange++;

                    var obj = new Dictionary<string, object>();

                    // package id casing variations
                    string pkg = "";
                    if (d.Contains("packageId")) pkg = BsonValueToIdString(d["packageId"]);
                    else if (d.Contains("PackageId")) pkg = BsonValueToIdString(d["PackageId"]);
                    else if (d.Contains("packageID")) pkg = BsonValueToIdString(d["packageID"]);

                    obj["packageId"] = pkg;

                    string itemType = d.Contains("itemType") && d["itemType"] != null && d["itemType"].BsonType == BsonType.String
                        ? d["itemType"].AsString : null;
                    obj["itemType"] = itemType;

                    string itemId = null;
                    if (d.Contains("itemId") && d["itemId"] != null && d["itemId"].BsonType != BsonType.Null) itemId = BsonValueToIdString(d["itemId"]);
                    obj["itemId"] = itemId;

                    string sku = d.Contains("sku") && d["sku"] != null && d["sku"].BsonType == BsonType.String ? d["sku"].AsString : null;
                    obj["sku"] = sku;

                    int qty = 0;
                    if (d.Contains("quantity") && d["quantity"] != null && d["quantity"].IsNumeric) qty = Convert.ToInt32(d["quantity"].ToDouble());
                    obj["quantity"] = qty;

                    obj["expirationAt"] = expUtc.ToString("o");
                    obj["daysLeft"] = (int)Math.Floor((expUtc - now).TotalDays);

                    // optional: include outinInventory status for debugging
                    if (d.Contains("outinInventory"))
                    {
                        try
                        {
                            if (d["outinInventory"].BsonType == BsonType.Boolean)
                                obj["outinInventory"] = d["outinInventory"].AsBoolean;
                            else
                                obj["outinInventory"] = null;
                        }
                        catch { obj["outinInventory"] = null; }
                    }

                    resultList.Add(obj);
                }

                if (debug)
                {
                    var sampleDoc = docs.Count > 0 ? docs[0] : null;
                    var respDebug = new
                    {
                        success = true,
                        count = resultList.Count,
                        packages = resultList,
                        debug = new
                        {
                            now = now.ToString("o"),
                            start = start.ToString("o"),
                            end = end.ToString("o"),
                            totalWithExpiry = totalWithExpiry,
                            matchedInRange = matchedInRange,
                            docsReturned = docs.Count,
                            sampleDocJson = sampleDoc != null ? sampleDoc.ToJson() : null,
                            db = DatabaseHelper.Database?.DatabaseNamespace?.DatabaseName
                        }
                    };
                    context.Response.Write(serializer.Serialize(respDebug));
                    return;
                }

                var resp = new
                {
                    success = true,
                    count = resultList.Count,
                    packages = resultList
                };

                context.Response.Write(serializer.Serialize(resp));
            }
            catch (Exception ex)
            {
                bool debug = string.Equals(context.Request.QueryString["debug"], "1", StringComparison.OrdinalIgnoreCase)
                             || string.Equals(context.Request.QueryString["debug"], "true", StringComparison.OrdinalIgnoreCase);

                if (debug)
                {
                    var errorObj = new { success = false, error = ex.Message, stack = ex.StackTrace };
                    context.Response.Write(serializer.Serialize(errorObj));
                }
                else
                {
                    var errorObj = new { success = false, error = ex.Message };
                    context.Response.Write(serializer.Serialize(errorObj));
                }

                System.Diagnostics.Debug.WriteLine("GetNearExpiryPackages error: " + ex);
            }
        }

        public bool IsReusable => false;

        private static bool TryParseDate(BsonValue val, out DateTime result)
        {
            result = DateTime.MinValue;
            try
            {
                if (val == null || val.IsBsonNull) return false;
                if (val.BsonType == BsonType.DateTime) { result = val.ToUniversalTime(); return true; }
                if (val.BsonType == BsonType.String) return DateTime.TryParse(val.AsString, out result);
            }
            catch { }
            return false;
        }

        private static string BsonValueToIdString(BsonValue v)
        {
            try
            {
                if (v == null || v.IsBsonNull) return null;
                if (v.BsonType == BsonType.ObjectId) return v.AsObjectId.ToString();
                if (v.BsonType == BsonType.String) return v.AsString;
                // fallback to plain ToString()
                return v.ToString();
            }
            catch { return v?.ToString(); }
        }
    }
}