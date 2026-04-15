using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;

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
                var end = now.AddDays(days);

                bool debug = string.Equals(context.Request.QueryString["debug"], "1", StringComparison.OrdinalIgnoreCase)
                             || string.Equals(context.Request.QueryString["debug"], "true", StringComparison.OrdinalIgnoreCase);

                var col = DatabaseHelper.Database.GetCollection<BsonDocument>("PackageStockEntries");

                // NEW: fetch documents that have an expirationAt (any BSON type), then filter in C#
                var existsFilter = Builders<BsonDocument>.Filter.Exists("expirationAt", true) &
                                   Builders<BsonDocument>.Filter.Ne("expirationAt", BsonNull.Value);

                var projection = Builders<BsonDocument>.Projection
                    .Include("_id").Include("packageId").Include("sku").Include("quantity")
                    .Include("expirationAt").Include("manufacturedAt").Include("itemId");

                var docs = col.Find(existsFilter)
                              .Project(projection)
                              .Sort(Builders<BsonDocument>.Sort.Ascending("expirationAt"))
                              .Limit(100)
                              .ToList();

                var totalWithExpiration = col.CountDocuments(existsFilter);

                var resultList = new List<Dictionary<string, object>>(docs.Count);
                int matchedInRange = 0;

                var variantsCol = DatabaseHelper.GetProductVariantsCollection();
                var productsCol = DatabaseHelper.GetProductsCollection();

                foreach (var d in docs)
                {
                    DateTime dt;
                    if (d.TryGetValue("expirationAt", out var ev) && ev != null && ev.BsonType != BsonType.Null && TryParseDate(ev, out dt))
                    {
                        // convert to UTC for consistent comparison
                        var dtUtc = dt.ToUniversalTime();
                        if (dtUtc >= now && dtUtc <= end)
                        {
                            matchedInRange++;

                            var obj = new Dictionary<string, object>();
                            obj["id"] = d.Contains("_id") ? d["_id"].ToString() : "";
                            obj["packageId"] = d.Contains("packageId") ? d["packageId"].ToString() : "";
                            obj["sku"] = d.Contains("sku") ? d["sku"].ToString() : "";
                            obj["quantity"] = d.Contains("quantity") ? (d["quantity"].IsNumeric ? (int)d["quantity"].ToDouble() : (int?)null) : (int?)null;
                            obj["expirationAt"] = dtUtc.ToString("o");

                            string itemId = d.Contains("itemId") ? d["itemId"].ToString() : null;
                            obj["itemId"] = itemId;

                            string resolvedName = null;
                            if (!string.IsNullOrWhiteSpace(itemId))
                            {
                                try
                                {
                                    var variant = variantsCol.Find(Builders<ProductVariant>.Filter.Eq(v => v.Id, itemId)).FirstOrDefault();
                                    if (variant != null && !string.IsNullOrWhiteSpace(variant.VariantName))
                                        resolvedName = variant.VariantName;
                                    else
                                    {
                                        var product = productsCol.Find(Builders<Product>.Filter.Eq(p => p.Id, itemId)).FirstOrDefault();
                                        if (product != null && !string.IsNullOrWhiteSpace(product.productName))
                                            resolvedName = product.productName;
                                        else if (ObjectId.TryParse(itemId, out var oid))
                                        {
                                            var idStr = oid.ToString();
                                            variant = variantsCol.Find(Builders<ProductVariant>.Filter.Eq(v => v.Id, idStr)).FirstOrDefault();
                                            if (variant != null && !string.IsNullOrWhiteSpace(variant.VariantName))
                                                resolvedName = variant.VariantName;
                                            else
                                            {
                                                product = productsCol.Find(Builders<Product>.Filter.Eq(p => p.Id, idStr)).FirstOrDefault();
                                                if (product != null && !string.IsNullOrWhiteSpace(product.productName))
                                                    resolvedName = product.productName;
                                            }
                                        }
                                    }
                                }
                                catch { }
                            }
                            obj["itemName"] = resolvedName ?? null;

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
                            end = end.ToString("o"),
                            totalWithExpiration = totalWithExpiration,
                            matchedInRange = matchedInRange,
                            docsReturned = docs.Count,
                            sampleExpirationType = sampleDoc != null && sampleDoc.Contains("expirationAt") ? sampleDoc["expirationAt"].BsonType.ToString() : null,
                            sampleDocJson = sampleDoc != null ? sampleDoc.ToJson() : null,
                            db = DatabaseHelper.Database.DatabaseNamespace.DatabaseName
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
                var error = new { success = false, error = ex.Message };
                context.Response.Write(new JavaScriptSerializer().Serialize(error));
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
    }
}