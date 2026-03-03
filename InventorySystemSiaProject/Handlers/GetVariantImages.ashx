<%@ WebHandler Language="C#" Class="GetVariantImages" %>

using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;

public class GetVariantImages : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        var serializer = new JavaScriptSerializer();

        try
        {
            var requestBody = new System.IO.StreamReader(context.Request.InputStream).ReadToEnd();
            var data = serializer.Deserialize<Dictionary<string, string>>(requestBody);

            if (!data.ContainsKey("variantId"))
            {
                context.Response.Write(serializer.Serialize(new { success = false, error = "Variant ID is required" }));
                return;
            }

            string variantId = data["variantId"];

            var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
            var filter = Builders<ProductVariant>.Filter.Or(
                Builders<ProductVariant>.Filter.Eq("_id", ObjectId.Parse(variantId)),
                Builders<ProductVariant>.Filter.Eq(v => v.Id, variantId)
            );

            var variant = variantsCollection.Find(filter).FirstOrDefault();

            if (variant == null)
            {
                context.Response.Write(serializer.Serialize(new { success = false, error = "Variant not found" }));
                return;
            }

            // ✅ Return image URLs (handler endpoints, not file paths)
            var imageUrls = new List<string>();
            if (variant.VariantImgUrls != null && variant.VariantImgUrls.Count > 0)
            {
                for (int i = 0; i < variant.VariantImgUrls.Count; i++)
                {
                    // ✅ Each image is accessed via the handler with an index
                    imageUrls.Add(string.Format("/Handlers/GetVariantImage.ashx?variantId={0}&index={1}", variantId, i));
                }
            }

            context.Response.Write(serializer.Serialize(new
            {
                success = true,
                images = imageUrls
            }));
        }
        catch (Exception ex)
        {
            context.Response.Write(serializer.Serialize(new
            {
                success = false,
                error = ex.Message,
                stack = ex.StackTrace
            }));
        }
    }

    public bool IsReusable
    {
        get { return false; }
    }
}