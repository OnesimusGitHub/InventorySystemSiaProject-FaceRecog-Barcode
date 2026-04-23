using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetNearExpiryIngredients : IHttpHandler
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
                var start = now.AddDays(-days);       // include recently expired
                var end = now.AddDays(days);

                bool debug = string.Equals(context.Request.QueryString["debug"], "1", StringComparison.OrdinalIgnoreCase)
                             || string.Equals(context.Request.QueryString["debug"], "true", StringComparison.OrdinalIgnoreCase);

                var col = DatabaseHelper.Database.GetCollection<BsonDocument>("IngredientStockRequests");
                var ingredientsCol = DatabaseHelper.GetIngredientsCollection();

                // Consider documents that have any of the date fields we'll use as fallback
                var existsFilter =
                    (Builders<BsonDocument>.Filter.Exists("actualDeliveryDate", true) & Builders<BsonDocument>.Filter.Ne("actualDeliveryDate", BsonNull.Value))
                    | (Builders<BsonDocument>.Filter.Exists("ActualDeliveryDate", true) & Builders<BsonDocument>.Filter.Ne("ActualDeliveryDate", BsonNull.Value))
                    | (Builders<BsonDocument>.Filter.Exists("expectedDeliveryDate", true) & Builders<BsonDocument>.Filter.Ne("expectedDeliveryDate", BsonNull.Value))
                    | (Builders<BsonDocument>.Filter.Exists("ExpectedDeliveryDate", true) & Builders<BsonDocument>.Filter.Ne("ExpectedDeliveryDate", BsonNull.Value))
                    | (Builders<BsonDocument>.Filter.Exists("requestDate", true) & Builders<BsonDocument>.Filter.Ne("requestDate", BsonNull.Value))
                    | (Builders<BsonDocument>.Filter.Exists("RequestDate", true) & Builders<BsonDocument>.Filter.Ne("RequestDate", BsonNull.Value));

                var projection = Builders<BsonDocument>.Projection
                    .Include("packageId").Include("PackageId").Include("packageID")
                    .Include("ingredientId").Include("IngredientID").Include("ingredientID")
                    .Include("quantityRequested").Include("quantity")
                    .Include("actualDeliveryDate").Include("ActualDeliveryDate")
                    .Include("expectedDeliveryDate").Include("ExpectedDeliveryDate")
                    .Include("requestDate").Include("RequestDate")
                    .Include("requestID").Include("RequestID")
                    .Include("outinInventory"); // include for filter/debug

                // Only include requests that are completed. Match common casings using case-insensitive regex.
                var completedRegex = new BsonRegularExpression("^completed$", "i");
                var statusFilter = Builders<BsonDocument>.Filter.Or(
                    Builders<BsonDocument>.Filter.Regex("requestStatus", completedRegex),
                    Builders<BsonDocument>.Filter.Regex("RequestStatus", completedRegex)
                );

                // Only include requests where outinInventory is missing/null OR explicitly false
                var outInFilter = Builders<BsonDocument>.Filter.Or(
                    Builders<BsonDocument>.Filter.Exists("outinInventory", false),           // field missing
                    Builders<BsonDocument>.Filter.Eq("outinInventory", false),             // explicit false
                    Builders<BsonDocument>.Filter.Eq("outinInventory", BsonNull.Value)     // explicit null
                );

                // Combine: require date field exists AND status is completed AND outinInventory not true
                var finalFilter = Builders<BsonDocument>.Filter.And(existsFilter, statusFilter, outInFilter);

                var docs = col.Find(finalFilter)
                              .Project(projection)
                              .Sort(Builders<BsonDocument>.Sort.Descending("actualDeliveryDate"))
                              .Limit(500)
                              .ToList();

                var totalWithDelivery = col.CountDocuments(finalFilter);

                var resultList = new List<Dictionary<string, object>>(docs.Count);
                int matchedInRange = 0;

                foreach (var d in docs)
                {
                    // choose date value from several possible fields (ActualDeliveryDate -> ExpectedDeliveryDate -> RequestDate)
                    BsonValue dateVal = null;
                    if (d.TryGetValue("actualDeliveryDate", out var dv) && dv != null && dv.BsonType != BsonType.Null) dateVal = dv;
                    else if (d.TryGetValue("ActualDeliveryDate", out dv) && dv != null && dv.BsonType != BsonType.Null) dateVal = dv;
                    else if (d.TryGetValue("expectedDeliveryDate", out dv) && dv != null && dv.BsonType != BsonType.Null) dateVal = dv;
                    else if (d.TryGetValue("ExpectedDeliveryDate", out dv) && dv != null && dv.BsonType != BsonType.Null) dateVal = dv;
                    else if (d.TryGetValue("requestDate", out dv) && dv != null && dv.BsonType != BsonType.Null) dateVal = dv;
                    else if (d.TryGetValue("RequestDate", out dv) && dv != null && dv.BsonType != BsonType.Null) dateVal = dv;

                    if (dateVal == null) continue;

                    DateTime dt;
                    if (!TryParseDate(dateVal, out dt))
                        continue;

                    var mfg = dt.Date;

                    // extract ingredient id (handle ObjectId or string variants)
                    string ingredientId = null;
                    BsonValue iv;
                    if (d.TryGetValue("ingredientId", out iv) && iv != null && iv.BsonType != BsonType.Null) ingredientId = BsonValueToIdString(iv);
                    else if (d.TryGetValue("ingredientID", out iv) && iv != null && iv.BsonType != BsonType.Null) ingredientId = BsonValueToIdString(iv);
                    else if (d.TryGetValue("IngredientID", out iv) && iv != null && iv.BsonType != BsonType.Null) ingredientId = BsonValueToIdString(iv);
                    else if (d.TryGetValue("IngredientId", out iv) && iv != null && iv.BsonType != BsonType.Null) ingredientId = BsonValueToIdString(iv);

                    double shelfYears = 0;
                    if (!string.IsNullOrWhiteSpace(ingredientId))
                    {
                        try
                        {
                            var ing = ingredientsCol.Find(i => i.Id == ingredientId).FirstOrDefault();
                            if (ing != null && ing.ShelfLifeYears.HasValue)
                                shelfYears = ing.ShelfLifeYears.Value;
                        }
                        catch { /* tolerant lookup */ }
                    }

                    if (shelfYears > 0)
                    {
                        var wholeYears = (int)Math.Floor(shelfYears);
                        var fractional = shelfYears - wholeYears;
                        var exp = mfg.AddYears(wholeYears).AddDays(fractional * 365.0).ToUniversalTime();

                        // INCLUDE items expired within the lookback window and items expiring in the next 'days'
                        if (exp >= start && exp <= end)
                        {
                            matchedInRange++;

                            var obj = new Dictionary<string, object>();

                            // package id casing variations
                            string pkg = "";
                            if (d.Contains("packageId")) pkg = BsonValueToIdString(d["packageId"]);
                            else if (d.Contains("PackageId")) pkg = BsonValueToIdString(d["PackageId"]);
                            else if (d.Contains("packageID")) pkg = BsonValueToIdString(d["packageID"]);

                            obj["packageId"] = pkg;
                            obj["ingredientId"] = ingredientId;

                            // quantity
                            int? qty = null;
                            if (d.Contains("quantityRequested"))
                            {
                                var qv = d["quantityRequested"];
                                if (qv != null && qv.BsonType != BsonType.Null && qv.IsNumeric) qty = Convert.ToInt32(qv.ToDouble());
                            }
                            else if (d.Contains("quantity"))
                            {
                                var qv = d["quantity"];
                                if (qv != null && qv.BsonType != BsonType.Null && qv.IsNumeric) qty = Convert.ToInt32(qv.ToDouble());
                            }

                            obj["quantity"] = qty;
                            obj["manufacturedAt"] = mfg.ToString("yyyy-MM-dd");
                            obj["expirationAt"] = exp.ToString("o");

                            string reqId = null;
                            if (d.Contains("requestID")) reqId = BsonValueToIdString(d["requestID"]);
                            else if (d.Contains("RequestID")) reqId = BsonValueToIdString(d["RequestID"]);
                            obj["requestId"] = reqId ?? "";

                            string name = null;
                            if (!string.IsNullOrWhiteSpace(ingredientId))
                            {
                                try
                                {
                                    var ing = ingredientsCol.Find(i => i.Id == ingredientId).FirstOrDefault();
                                    if (ing != null) name = ing.IngredientName;
                                }
                                catch { }
                            }
                            obj["ingredientName"] = name ?? "N/A";

                            // optional: include outinInventory for debugging/inspection
                            if (d.Contains("outinInventory"))
                            {
                                try
                                {
                                    obj["outinInventory"] = d["outinInventory"].BsonType == BsonType.Boolean ? (object)d["outinInventory"].AsBoolean : null;
                                }
                                catch { obj["outinInventory"] = null; }
                            }

                            resultList.Add(obj);
                        }
                    }
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
                            totalWithDelivery = totalWithDelivery,
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

                System.Diagnostics.Debug.WriteLine("GetNearExpiryIngredients error: " + ex);
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