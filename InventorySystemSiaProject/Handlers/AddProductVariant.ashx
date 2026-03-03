<%@ WebHandler Language="C#" Class="AddProductVariant" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;

public class AddProductVariant : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        var serializer = new JavaScriptSerializer();

        try
        {
            var productId = context.Request.Form["ProductId"];
            var variantName = context.Request.Form["VariantName"];
            var sku = context.Request.Form["SKU"];
            var size = context.Request.Form["Size"];
            var color = context.Request.Form["Color"];
            var priceStr = context.Request.Form["Price"];
            var stockStr = context.Request.Form["StockQuantity"];
            var minStockStr = context.Request.Form["MinimumStock"];
            var weightStr = context.Request.Form["Weight"];
            var dimensions = context.Request.Form["Dimensions"];
            var description = context.Request.Form["Description"];
            var shelfLifeYearsStr = context.Request.Form["ShelfLifeYears"];
            var location = context.Request.Form["Location"];

            // Validation
            if (string.IsNullOrWhiteSpace(productId) || string.IsNullOrWhiteSpace(variantName) || string.IsNullOrWhiteSpace(sku))
            {
                context.Response.Write(serializer.Serialize(new { success = false, error = "ProductId, VariantName, and SKU are required." }));
                return;
            }

            decimal price = 0;
            int stockQuantity = 0;
            int minimumStock = 1000;

            if (!decimal.TryParse(priceStr, out price) || !int.TryParse(stockStr, out stockQuantity))
            {
                context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid Price or StockQuantity." }));
                return;
            }

            if (!string.IsNullOrEmpty(minStockStr))
            {
                int.TryParse(minStockStr, out minimumStock);
            }

            decimal? weight = null;
            if (!string.IsNullOrEmpty(weightStr))
            {
                decimal w;
                if (decimal.TryParse(weightStr, out w))
                {
                    weight = w;
                }
            }

            int? shelfLifeYears = null;
            if (!string.IsNullOrEmpty(shelfLifeYearsStr))
            {
                int sly;
                if (int.TryParse(shelfLifeYearsStr, out sly))
                {
                    shelfLifeYears = sly;
                }
            }

            // ✅ NEW: Process uploaded images as raw binary data
            var imageDataList = new List<byte[]>();
            var files = context.Request.Files;

            if (files.Count > 0)
            {
                for (int i = 0; i < files.Count; i++)
                {
                    var file = files[i];
                    if (file != null && file.ContentLength > 0 && file.ContentType.StartsWith("image/"))
                    {
                        using (var ms = new MemoryStream())
                        {
                            file.InputStream.CopyTo(ms);
                            imageDataList.Add(ms.ToArray()); // ✅ Store raw bytes
                        }
                    }
                }
            }

            // Create variant object
            var variant = new ProductVariant
            {
                ProductId = productId,
                VariantName = variantName,
                SKU = sku,
                Size = size,
                Color = color,
                Price = price,
                StockQuantity = stockQuantity,
                MinimumStock = minimumStock,
                Weight = weight,
                Dimensions = dimensions,
                Description = description,
                Location = location,
                ShelfLifeYears = shelfLifeYears,
                VariantImgUrls = imageDataList.Count > 0 ? imageDataList : null, // ✅ Raw binary array
                CreatedAt = DateTime.UtcNow,
                Status = "Active",
                IsActive = true
            };

            // Save to database
            var collection = DatabaseHelper.GetProductVariantsCollection();
            collection.InsertOne(variant);

            context.Response.Write(serializer.Serialize(new
            {
                success = true,
                message = "Variant added successfully!",
                variantId = variant.Id,
                imageCount = imageDataList.Count
            }));
        }
        catch (Exception ex)
        {
            context.Response.Write(serializer.Serialize(new { success = false, error = ex.Message, stack = ex.StackTrace }));
        }
    }

    public bool IsReusable
    {
        get { return false; }
    }
}