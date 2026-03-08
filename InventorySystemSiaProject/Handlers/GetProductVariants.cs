
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Text.RegularExpressions;
using System.Diagnostics;
using System.Threading;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetProductVariants : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.CacheControl = "no-cache";
            var serializer = new JavaScriptSerializer();

            if (!string.IsNullOrEmpty(context.Request["ping"]))
            {
                context.Response.Write(serializer.Serialize(new { success = true, message = "handler ok" }));
                return;
            }

            try
            {
                string productId = context.Request["productId"];
                if (string.IsNullOrWhiteSpace(productId))
                {
                    context.Response.Write(serializer.Serialize(new { error = "Product ID is required" }));
                    return;
                }

                productId = HttpUtility.UrlDecode(productId ?? string.Empty).Trim().Trim('\'', '"');
                bool looksLikeObjectId = productId.Length == 24 && Regex.IsMatch(productId, "^[0-9a-fA-F]{24}$");

                var swTotal = Stopwatch.StartNew();
                var timings = new Dictionary<string, long>();
                var logs = new List<string>();

                var productsColl = DatabaseHelper.GetProductsCollection();
                var variantsColl = DatabaseHelper.GetProductVariantsCollection();

                // ✅ FIX: Use BsonDocument collection to avoid typed deserialization errors
                var swProduct = Stopwatch.StartNew();
                Product product = null;

                try
                {
                    var bsonProductsColl = productsColl.Database.GetCollection<BsonDocument>(
                        productsColl.CollectionNamespace.CollectionName);

                    var idFilters = new List<FilterDefinition<BsonDocument>>();

                    if (looksLikeObjectId)
                    {
                        try { idFilters.Add(Builders<BsonDocument>.Filter.Eq("_id", ObjectId.Parse(productId))); }
                        catch { /* parse guard */ }
                    }

                    // Always also try as plain string
                    idFilters.Add(Builders<BsonDocument>.Filter.Eq("_id", productId));

                    var idFilter = Builders<BsonDocument>.Filter.Or(idFilters);
                    var statusFilter = Builders<BsonDocument>.Filter.Eq("status", "Active");
                    var combined = Builders<BsonDocument>.Filter.And(idFilter, statusFilter);

                    var productDoc = bsonProductsColl.Find(combined).FirstOrDefault();

                    if (productDoc != null)
                    {
                        // Map BsonDocument to Product manually to avoid deserialization issues
                        product = new Product
                        {
                            Id = productDoc.Contains("_id") ? productDoc["_id"].ToString() : null,
                            productName = productDoc.Contains("productName") ? productDoc["productName"].AsString : null,
                            productCategory = productDoc.Contains("productCategory") ? productDoc["productCategory"].AsString : null,
                            productVal = productDoc.Contains("productVal") && productDoc["productVal"].IsNumeric
                                ? (decimal)productDoc["productVal"].ToDouble() : 0
                        };
                        logs.Add("Product found via BsonDocument: " + product.productName);
                    }
                }
                catch (Exception ex)
                {
                    logs.Add("Product lookup error: " + ex.Message);
                }

                swProduct.Stop();
                timings["productMs"] = swProduct.ElapsedMilliseconds;

                if (product == null)
                {
                    swTotal.Stop();
                    timings["totalMs"] = swTotal.ElapsedMilliseconds;
                    context.Response.Write(serializer.Serialize(new { error = "Product not found", timings, productId, logs }));
                    return;
                }

                // VARIANTS lookup
                var swVariants = Stopwatch.StartNew();
                List<ProductVariant> variantsRaw = new List<ProductVariant>();

                try
                {
                    var bsonColl = variantsColl.Database.GetCollection<BsonDocument>(DatabaseHelper.GetProductVariantsCollectionName());

                    logs.Add("Looking for variants with productId: " + productId);
                    logs.Add("looksLikeObjectId: " + looksLikeObjectId);

                    var filters = new List<FilterDefinition<BsonDocument>>();

                    if (looksLikeObjectId)
                    {
                        try { filters.Add(Builders<BsonDocument>.Filter.Eq("productId", ObjectId.Parse(productId))); }
                        catch { /*parse guard*/ }
                    }

                    filters.Add(Builders<BsonDocument>.Filter.Eq("productId", productId));

                    var filter = Builders<BsonDocument>.Filter.Or(filters);
                    var docs = bsonColl.Find(filter).ToList();
                    logs.Add("Found " + docs.Count + " variants with combined filter");

                    if (docs.Count == 0)
                    {
                        var allVariants = bsonColl.Find(new BsonDocument()).ToList();
                        logs.Add("Total variants in collection: " + allVariants.Count);

                        docs = allVariants.Where(d =>
                        {
                            if (!d.Contains("productId")) return false;
                            var pid = d["productId"];
                            try
                            {
                                if (pid.IsObjectId) return pid.AsObjectId.ToString() == productId;
                                if (pid.IsString) return pid.AsString == productId;
                            }
                            catch { }
                            return false;
                        }).ToList();

                        logs.Add("Filtered to " + docs.Count + " matching variants (fallback)");
                    }

                    variantsRaw = docs.Select(d =>
                    {
                        string id = null;
                        try { if (d.Contains("_id")) id = d["_id"].ToString(); } catch { id = null; }

                        string prodIdValue = product.Id;
                        try
                        {
                            if (d.Contains("productId"))
                            {
                                var pid = d["productId"];
                                if (pid.IsObjectId) prodIdValue = pid.AsObjectId.ToString();
                                else if (pid.IsString) prodIdValue = pid.AsString;
                                else prodIdValue = pid.ToString();
                            }
                        }
                        catch { }

                        string variantImgData = null;
                        try
                        {
                            if (d.Contains("variantImgUrls") && d["variantImgUrls"].IsBsonArray)
                            {
                                var arr = d["variantImgUrls"].AsBsonArray;
                                if (arr.Count > 0)
                                {
                                    var first = arr.FirstOrDefault();
                                    if (first != null && first.IsBsonBinaryData)
                                    {
                                        var bytes = first.AsBsonBinaryData.Bytes;
                                        if (bytes != null && bytes.Length > 0)
                                            variantImgData = "data:image/jpeg;base64," + Convert.ToBase64String(bytes);
                                    }
                                }
                            }
                        }
                        catch (Exception ex) { logs.Add("Image mapping error for doc " + id + ": " + ex.Message); }

                        decimal priceVal = 0;
                        try { if (d.Contains("price") && d["price"].IsNumeric) priceVal = (decimal)d["price"].ToDouble(); } catch { }

                        int stockVal = 0;
                        try { if (d.Contains("stockQuantity") && d["stockQuantity"].IsNumeric) stockVal = Convert.ToInt32(d["stockQuantity"].ToDouble()); } catch { }

                        int minStockVal = 0;
                        try { if (d.Contains("minimumStock") && d["minimumStock"].IsNumeric) minStockVal = Convert.ToInt32(d["minimumStock"].ToDouble()); } catch { }

                        decimal? weightVal = null;
                        try { if (d.Contains("weight") && d["weight"].IsNumeric) weightVal = (decimal?)d["weight"].ToDouble(); } catch { }

                        int? shelfLife = null;
                        try { if (d.Contains("shelfLifeYears") && d["shelfLifeYears"].IsInt32) shelfLife = d["shelfLifeYears"].AsInt32; } catch { }

                        bool isActive = true;
                        string status = "Active";
                        try { if (d.Contains("isActive") && d["isActive"].IsBoolean) isActive = d["isActive"].AsBoolean; } catch { }
                        try { if (d.Contains("Status") && d["Status"].IsString) status = d["Status"].AsString; } catch { }

                        return new ProductVariant
                        {
                            Id = id,
                            ProductId = prodIdValue,
                            VariantName = d.Contains("variantName") ? d["variantName"].AsString : null,
                            SKU = d.Contains("sku") ? d["sku"].AsString : null,
                            Size = d.Contains("size") ? d["size"].AsString : null,
                            Color = d.Contains("color") ? d["color"].AsString : null,
                            Price = priceVal,
                            StockQuantity = stockVal,
                            MinimumStock = minStockVal,
                            Weight = weightVal,
                            Dimensions = d.Contains("dimensions") ? d["dimensions"].AsString : null,
                            Description = d.Contains("description") ? d["description"].AsString : null,
                            Location = d.Contains("location") ? d["location"].AsString : null,
                            ShelfLifeYears = shelfLife,
                            VariantImg = variantImgData,
                            IsActive = isActive,
                            Status = status
                        };
                    })
                    .Where(v => v != null && (v.IsActive || string.Equals(v.Status, "Active", StringComparison.OrdinalIgnoreCase)))
                    .ToList();

                    logs.Add("Mapped " + variantsRaw.Count + " active variants");
                }
                catch (Exception ex)
                {
                    logs.Add("ERROR: " + ex.Message);
                    logs.Add("Stack: " + ex.StackTrace);
                }

                swVariants.Stop();
                timings["variantsMs"] = swVariants.ElapsedMilliseconds;

                var variants = (variantsRaw ?? new List<ProductVariant>())
                    .Where(v => v != null)
                    .Select(v => new
                    {
                        Id = v.Id,
                        VariantName = v.VariantName,
                        SKU = v.SKU,
                        Size = v.Size,
                        Color = v.Color,
                        Price = v.Price,
                        StockQuantity = v.StockQuantity,
                        MinimumStock = v.MinimumStock,
                        IsLowStock = v.StockQuantity <= v.MinimumStock,
                        Weight = v.Weight,
                        Dimensions = v.Dimensions,
                        VariantImg = v.VariantImg,
                        Location = v.Location,
                        ShelfLifeYears = v.ShelfLifeYears,
                        Description = v.Description
                    }).ToList();

                swTotal.Stop();
                timings["totalMs"] = swTotal.ElapsedMilliseconds;

                context.Response.Write(serializer.Serialize(new
                {
                    success = true,
                    product = new { product.Id, product.productName, product.productCategory, product.productVal },
                    variants,
                    variantCount = variants.Count,
                    timings,
                    logs,
                    diagnostic = new
                    {
                        looksLikeObjectId,
                        receivedProductId = productId
                    }
                }));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 200;
                context.Response.Write(serializer.Serialize(new { error = ex.Message, stack = ex.StackTrace }));
            }
        }

        public bool IsReusable => false;
    }
}