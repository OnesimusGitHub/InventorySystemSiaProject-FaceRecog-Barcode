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
    // Lightweight HTTP handler (bypasses WebForms PageMethods pipeline)
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

                // sanitize and validate (allow both 24 hex and raw string id if user manually inserted string _id earlier)
                productId = HttpUtility.UrlDecode(productId ?? string.Empty).Trim().Trim('\'', '"');
                bool looksLikeObjectId = productId.Length == 24 && Regex.IsMatch(productId, "^[0-9a-fA-F]{24}$");

                var swTotal = Stopwatch.StartNew();
                var timings = new System.Collections.Generic.Dictionary<string, long>();
                var cts = new CancellationTokenSource(TimeSpan.FromSeconds(15));

                var productsColl = DatabaseHelper.GetProductsCollection();
                var variantsColl = DatabaseHelper.GetProductVariantsCollection();

                // Ensure useful indexes exist (idempotent) - no removal of existing lines, just additions
                try
                {
                    var indexModels = new List<CreateIndexModel<ProductVariant>>
                    {
                        new CreateIndexModel<ProductVariant>(Builders<ProductVariant>.IndexKeys.Ascending(v => v.ProductId).Ascending(v => v.IsActive)),
                        new CreateIndexModel<ProductVariant>(Builders<ProductVariant>.IndexKeys.Ascending(v => v.SKU))
                    };
                    variantsColl.Indexes.CreateMany(indexModels);
                }
                catch { /* ignore index creation issues */ }

                // PRODUCT lookup (support both string and ObjectId _id legacy docs)
                var swProduct = Stopwatch.StartNew();
                Product product = null;
                var productFilters = new List<FilterDefinition<Product>>();
                if (looksLikeObjectId)
                {
                    productFilters.Add(Builders<Product>.Filter.Eq("_id", ObjectId.Parse(productId)));
                }
                // fallback string id support
                productFilters.Add(Builders<Product>.Filter.Eq("_id", productId));
                productFilters.Add(Builders<Product>.Filter.Eq(p => p.Id, productId));
                var finalProductFilter = Builders<Product>.Filter.And(
                    Builders<Product>.Filter.Or(productFilters),
                    Builders<Product>.Filter.Eq("isActive", true)
                );
                product = productsColl.Find(finalProductFilter).FirstOrDefault();
                swProduct.Stop();
                timings["productMs"] = swProduct.ElapsedMilliseconds;

                if (product == null)
                {
                    swTotal.Stop();
                    timings["totalMs"] = swTotal.ElapsedMilliseconds;
                    context.Response.Write(serializer.Serialize(new { error = "Product not found", timings, productId }));
                    return;
                }

                // VARIANTS lookup with multi-strategy
                var swVariants = Stopwatch.StartNew();
                var variantFilters = new List<FilterDefinition<ProductVariant>>();
                if (looksLikeObjectId)
                {
                    // variant.productId stored as ObjectId
                    variantFilters.Add(Builders<ProductVariant>.Filter.Eq("productId", ObjectId.Parse(productId)));
                }
                // variant.productId stored as string (historical / inconsistent inserts)
                variantFilters.Add(Builders<ProductVariant>.Filter.Eq("productId", productId));
                // typed comparison (driver handles conversion)
                variantFilters.Add(Builders<ProductVariant>.Filter.Eq(v => v.ProductId, productId));
                var variantsFilter = Builders<ProductVariant>.Filter.And(
                    Builders<ProductVariant>.Filter.Or(variantFilters),
                    Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true)
                );

                List<ProductVariant> variantsRaw = variantsColl.Find(variantsFilter).ToList();

                // FINAL fallback: if still empty and id looked like ObjectId, try scanning any variant referencing product Id in either string or object form manually with Bson
                if (variantsRaw.Count == 0 && looksLikeObjectId)
                {
                    try
                    {
                        var bsonColl = variantsColl.Database.GetCollection<BsonDocument>(DatabaseHelper.GetProductVariantsCollectionName());
                        var raw = bsonColl.Find(new BsonDocument {{"productId", productId}}).ToList();
                        if (raw.Count == 0)
                        {
                            raw = bsonColl.Find(new BsonDocument {{"productId", ObjectId.Parse(productId)}}).ToList();
                        }
                        if (raw.Count > 0)
                        {
                            variantsRaw = raw.Select(d => new ProductVariant
                            {
                                Id = d.Contains("_id")? d["_id"].ToString(): null,
                                ProductId = product.Id,
                                VariantName = d.Contains("variantName")? d["variantName"].ToString(): null,
                                SKU = d.Contains("sku")? d["sku"].ToString(): null,
                                Size = d.Contains("size")? d["size"].ToString(): null,
                                Color = d.Contains("color")? d["color"].ToString(): null,
                                Price = d.Contains("price") && d["price"].IsNumeric ? (decimal)d["price"].ToDouble():0,
                                StockQuantity = d.Contains("stockQuantity") && d["stockQuantity"].IsInt32? d["stockQuantity"].AsInt32:0,
                                MinimumStock = d.Contains("minimumStock") && d["minimumStock"].IsInt32? d["minimumStock"].AsInt32:0,
                                IsActive = d.Contains("isActive") && d["isActive"].IsBoolean ? d["isActive"].AsBoolean : true
                            }).Where(v => v.IsActive).ToList();
                        }
                    }
                    catch { }
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
                        IsLowStock = v.StockQuantity <= v.MinimumStock
                    }).ToList();

                swTotal.Stop();
                timings["totalMs"] = swTotal.ElapsedMilliseconds;

                context.Response.Write(serializer.Serialize(new
                {
                    success = true,
                    product = new { product.Id, product.ProductName, product.ProductCategory, product.ProductVal },
                    variants = variants,
                    variantCount = variants.Count,
                    timings,
                    diagnostic = new {
                        productFilterTried = productFilters.Count,
                        variantFiltersTried = variantFilters.Count,
                        looksLikeObjectId,
                        receivedProductId = productId
                    }
                }));
            }
            catch (OperationCanceledException)
            {
                context.Response.StatusCode = 200;
                context.Response.Write(serializer.Serialize(new { error = "Request timed out", timeout = true }));
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
