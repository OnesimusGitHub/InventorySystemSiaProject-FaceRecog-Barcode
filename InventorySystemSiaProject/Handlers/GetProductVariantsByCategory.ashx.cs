using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Web.Script.Serialization;
using System.Text.RegularExpressions;

namespace InventorySystemSiaProject.Handlers
{
    public class GetProductVariantsByCategory : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            string category = context.Request["category"];

            try
            {
                var productCollection = DatabaseHelper.GetProductsCollection();
                var variantCollection = DatabaseHelper.GetProductVariantsCollection();

                // ---------- PRODUCTS (safe via BsonDocument) ----------
                var bsonProductsColl = productCollection.Database.GetCollection<BsonDocument>(
                    productCollection.CollectionNamespace.CollectionName);

                var statusFilters = new List<FilterDefinition<BsonDocument>>
        {
            Builders<BsonDocument>.Filter.Eq("status", "Active"),
            Builders<BsonDocument>.Filter.Eq("status", BsonNull.Value),
            Builders<BsonDocument>.Filter.Exists("status", false)
        };
                var statusFilter = Builders<BsonDocument>.Filter.Or(statusFilters);

                FilterDefinition<BsonDocument> productFilter;
                if (!string.IsNullOrEmpty(category))
                {
                    var catFilter = Builders<BsonDocument>.Filter.Eq("productCategory", category);
                    productFilter = Builders<BsonDocument>.Filter.And(catFilter, statusFilter);
                }
                else
                {
                    productFilter = statusFilter;
                }

                // Exclude heavy productImg binary from products
                var productProjection = Builders<BsonDocument>.Projection.Exclude("productImg");

                var productDocs = bsonProductsColl.Find(productFilter)
                    .Project<BsonDocument>(productProjection)
                    .ToList();

                if (productDocs.Count == 0)
                {
                    context.Response.Write("[]");
                    return;
                }

                // Collect product IDs as strings
                var productIds = productDocs
                    .Where(d => d.Contains("_id"))
                    .Select(d => d["_id"].ToString())
                    .ToList();

                // ---------- VARIANTS (safe via BsonDocument) ----------
                var bsonVariantsColl = variantCollection.Database.GetCollection<BsonDocument>(
                    DatabaseHelper.GetProductVariantsCollectionName());

                // Build variant filter: productId/ProductId in productIds (ObjectId or string)
                var idFilters = new List<FilterDefinition<BsonDocument>>();

                foreach (var pid in productIds)
                {
                    if (!string.IsNullOrWhiteSpace(pid) &&
                        pid.Length == 24 &&
                        Regex.IsMatch(pid, "^[0-9a-fA-F]{24}$"))
                    {
                        try
                        {
                            var oid = ObjectId.Parse(pid);
                            // productId / ProductId as ObjectId
                            idFilters.Add(Builders<BsonDocument>.Filter.Eq("productId", oid));
                            idFilters.Add(Builders<BsonDocument>.Filter.Eq("ProductId", oid));
                        }
                        catch
                        {
                            // ignore parse failures
                        }
                    }

                    // Also match string productId / ProductId
                    idFilters.Add(Builders<BsonDocument>.Filter.Eq("productId", pid));
                    idFilters.Add(Builders<BsonDocument>.Filter.Eq("ProductId", pid));
                }

                var productIdFilter = idFilters.Count > 0
                    ? Builders<BsonDocument>.Filter.Or(idFilters)
                    : Builders<BsonDocument>.Filter.Empty;

                // NOTE: intentionally no isActive filter here, to avoid filtering out legacy data
                var variantFilter = productIdFilter;

                // IMPORTANT: do not exclude variantImgUrls – handler needs it for images
                var variantDocs = bsonVariantsColl.Find(variantFilter).ToList();

                System.Diagnostics.Debug.WriteLine(
                    $"[GetProductVariantsByCategory] category='{category}', products={productDocs.Count}, variants={variantDocs.Count}");

                // ---------- URL base path ----------
                var appPath = context.Request.ApplicationPath ?? string.Empty;
                if (appPath == "/") appPath = string.Empty;
                var basePath = appPath.TrimEnd('/');

                // ---------- Map BsonDocument → safe anonymous DTO ----------
                var variants = variantDocs.Select(d =>
                {
                    string id = null;
                    try
                    {
                        if (d.Contains("_id"))
                            id = d["_id"].ToString();
                    }
                    catch { }

                    string productId = null;
                    try
                    {
                        if (d.Contains("productId"))
                        {
                            var pidVal = d["productId"];
                            productId = pidVal.IsObjectId
                                ? pidVal.AsObjectId.ToString()
                                : pidVal.ToString();
                        }
                        else if (d.Contains("ProductId"))
                        {
                            var pidVal = d["ProductId"];
                            productId = pidVal.IsObjectId
                                ? pidVal.AsObjectId.ToString()
                                : pidVal.ToString();
                        }
                    }
                    catch { }

                    decimal price = 0;
                    try
                    {
                        BsonValue pv = null;
                        if (d.TryGetValue("price", out pv) || d.TryGetValue("Price", out pv))
                        {
                            if (pv.IsNumeric)
                                price = (decimal)pv.ToDouble();
                            else if (pv.BsonType == BsonType.String)
                            {
                                decimal parsed;
                                if (decimal.TryParse(pv.AsString, out parsed))
                                    price = parsed;
                            }
                        }
                    }
                    catch { }

                    int stock = 0;
                    try
                    {
                        if (d.Contains("stockQuantity") && d["stockQuantity"].IsNumeric)
                            stock = Convert.ToInt32(d["stockQuantity"].ToDouble());
                        else if (d.Contains("StockQuantity") && d["StockQuantity"].IsNumeric)
                            stock = Convert.ToInt32(d["StockQuantity"].ToDouble());
                    }
                    catch { }

                    int minStock = 0;
                    try
                    {
                        if (d.Contains("minimumStock") && d["minimumStock"].IsNumeric)
                            minStock = Convert.ToInt32(d["minimumStock"].ToDouble());
                        else if (d.Contains("MinimumStock") && d["MinimumStock"].IsNumeric)
                            minStock = Convert.ToInt32(d["MinimumStock"].ToDouble());
                    }
                    catch { }

                    string variantImg = null;
                    try
                    {
                        if (d.Contains("variantImg") && d["variantImg"].IsString)
                            variantImg = d["variantImg"].AsString;
                        else if (d.Contains("VariantImg") && d["VariantImg"].IsString)
                            variantImg = d["VariantImg"].AsString;
                    }
                    catch { }

                    bool isActive = true;
                    try
                    {
                        if (d.Contains("isActive") && d["isActive"].IsBoolean)
                            isActive = d["isActive"].AsBoolean;
                        else if (d.Contains("IsActive") && d["IsActive"].IsBoolean)
                            isActive = d["IsActive"].AsBoolean;
                    }
                    catch { }

                    // Build VariantImgUrls as handler URLs if there is real binary data
                    string[] variantImgUrls = null;
                    try
                    {
                        BsonValue urlsVal;
                        if (!string.IsNullOrEmpty(id) &&
                            d.TryGetValue("variantImgUrls", out urlsVal) &&
                            urlsVal.IsBsonArray)
                        {
                            var arr = urlsVal.AsBsonArray;
                            bool hasBinary = false;

                            foreach (var entry in arr)
                            {
                                if (entry.BsonType == BsonType.Binary)
                                {
                                    var bytes = entry.AsBsonBinaryData.Bytes;
                                    if (bytes != null && bytes.Length > 0)
                                    {
                                        hasBinary = true;
                                        break;
                                    }
                                }
                                else if (entry.BsonType == BsonType.Document)
                                {
                                    var sub = entry.AsBsonDocument;
                                    BsonValue inner;
                                    if (sub.TryGetValue("imageData", out inner) &&
                                        inner.BsonType == BsonType.Binary)
                                    {
                                        var bytes = inner.AsBsonBinaryData.Bytes;
                                        if (bytes != null && bytes.Length > 0)
                                        {
                                            hasBinary = true;
                                            break;
                                        }
                                    }
                                    else if (sub.TryGetValue("data", out inner) &&
                                             inner.BsonType == BsonType.Binary)
                                    {
                                        var bytes = inner.AsBsonBinaryData.Bytes;
                                        if (bytes != null && bytes.Length > 0)
                                        {
                                            hasBinary = true;
                                            break;
                                        }
                                    }
                                }
                                // string entries are legacy URLs – handled via VariantImg
                            }

                            if (hasBinary)
                            {
                                variantImgUrls = new[]
                                {
                            string.Format(
                                "{0}/Handlers/GetVariantImage.ashx?variantId={1}&index=0",
                                basePath,
                                HttpUtility.UrlEncode(id))
                        };
                            }
                        }
                    }
                    catch
                    {
                        // ignore image mapping errors; client will use VariantImg/placeholder
                    }

                    return new
                    {
                        Id = id,
                        ProductId = productId,
                        VariantName = d.Contains("variantName") && d["variantName"].IsString
                            ? d["variantName"].AsString
                            : (d.Contains("VariantName") && d["VariantName"].IsString
                                ? d["VariantName"].AsString
                                : null),
                        SKU = d.Contains("sku") && d["sku"].IsString
                            ? d["sku"].AsString
                            : (d.Contains("SKU") && d["SKU"].IsString
                                ? d["SKU"].AsString
                                : null),
                        Size = d.Contains("size") && d["size"].IsString
                            ? d["size"].AsString
                            : (d.Contains("Size") && d["Size"].IsString
                                ? d["Size"].AsString
                                : null),
                        Color = d.Contains("color") && d["color"].IsString
                            ? d["color"].AsString
                            : (d.Contains("Color") && d["Color"].IsString
                                ? d["Color"].AsString
                                : null),
                        Price = price,
                        StockQuantity = stock,
                        MinimumStock = minStock,
                        IsLowStock = stock <= minStock,
                        Location = d.Contains("location") && d["location"].IsString
                            ? d["location"].AsString
                            : (d.Contains("Location") && d["Location"].IsString
                                ? d["Location"].AsString
                                : null),
                        VariantImg = variantImg,          // legacy URL/base64 fallback
                        VariantImgUrls = variantImgUrls,  // handler URLs when blobs exist
                        IsActive = isActive,
                        Status = d.Contains("Status") && d["Status"].IsString
                            ? d["Status"].AsString
                            : "Active"
                    };
                }).ToList();

                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(variants));
            }
            catch (Exception ex)
            {
                // keep 200 so client JS can read the error body
                context.Response.StatusCode = 200;
                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(new
                {
                    error = ex.Message,
                    details = ex.GetType().Name
                }));
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}