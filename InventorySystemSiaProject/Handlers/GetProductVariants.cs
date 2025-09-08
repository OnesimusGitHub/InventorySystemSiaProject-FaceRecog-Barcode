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

                // sanitize and validate
                productId = HttpUtility.UrlDecode(productId ?? string.Empty).Trim().Trim('\'', '"');
                if (productId.Length != 24 || !Regex.IsMatch(productId, "^[0-9a-fA-F]{24}$"))
                {
                    context.Response.Write(serializer.Serialize(new { error = "Invalid productId format. Expected 24-hex ObjectId.", value = productId }));
                    return;
                }

                var swTotal = Stopwatch.StartNew();
                var timings = new System.Collections.Generic.Dictionary<string, long>();
                var cts = new CancellationTokenSource(TimeSpan.FromSeconds(15));

                var productsColl = DatabaseHelper.GetProductsCollection();
                var variantsColl = DatabaseHelper.GetProductVariantsCollection();

                // PRODUCT lookup
                var swProduct = Stopwatch.StartNew();
                var pf = Builders<Product>.Filter.Eq("_id", ObjectId.Parse(productId)) & Builders<Product>.Filter.Eq("isActive", true);
                var pOpts = new FindOptions<Product> { Limit = 1, MaxTime = TimeSpan.FromSeconds(10) };
                Product product = null;
                using (var cursor = productsColl.FindSync(pf, pOpts, cts.Token))
                {
                    product = cursor.FirstOrDefault(cts.Token);
                }
                swProduct.Stop();
                timings["productMs"] = swProduct.ElapsedMilliseconds;

                if (product == null)
                {
                    swTotal.Stop();
                    timings["totalMs"] = swTotal.ElapsedMilliseconds;
                    context.Response.Write(serializer.Serialize(new { error = "Product not found", timings }));
                    return;
                }

                // VARIANTS lookup
                var swVariants = Stopwatch.StartNew();
                var vf = Builders<ProductVariant>.Filter.Eq("productId", ObjectId.Parse(productId)) & Builders<ProductVariant>.Filter.Eq("isActive", true);
                var vOpts = new FindOptions<ProductVariant> { MaxTime = TimeSpan.FromSeconds(10) };
                List<ProductVariant> variantsRaw;
                using (var vCursor = variantsColl.FindSync(vf, vOpts, cts.Token))
                {
                    variantsRaw = vCursor.ToList(cts.Token);
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
                        MinimumStock = v.MinimumStock
                    }).ToList();

                swTotal.Stop();
                timings["totalMs"] = swTotal.ElapsedMilliseconds;

                context.Response.Write(serializer.Serialize(new
                {
                    success = true,
                    product = new { product.Id, product.ProductName, product.ProductCategory, product.ProductVal },
                    variants = variants,
                    variantCount = variants.Count,
                    timings
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
                context.Response.Write(serializer.Serialize(new { error = ex.Message }));
            }
        }

        public bool IsReusable => false;
    }
}
