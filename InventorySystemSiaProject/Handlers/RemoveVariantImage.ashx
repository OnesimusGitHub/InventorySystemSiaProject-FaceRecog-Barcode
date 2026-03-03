<%@ WebHandler Language="C#" Class="RemoveVariantImage" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

public class RemoveVariantImage : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        var serializer = new JavaScriptSerializer();

        try
        {
            string json;
            using (var reader = new StreamReader(context.Request.InputStream))
            {
                json = reader.ReadToEnd();
            }

            System.Diagnostics.Debug.WriteLine("Received JSON: " + json);

            var data = serializer.Deserialize<Dictionary<string, object>>(json);
            
            string variantId = null;
            int imageIndex = -1;

            if (data != null)
            {
                if (data.ContainsKey("variantId") && data["variantId"] != null)
                {
                    variantId = data["variantId"].ToString();
                }
                
                // Instead of imageUrl, get the index directly
                if (data.ContainsKey("index") && data["index"] != null)
                {
                    int.TryParse(data["index"].ToString(), out imageIndex);
                }
                else if (data.ContainsKey("imageIndex") && data["imageIndex"] != null)
                {
                    int.TryParse(data["imageIndex"].ToString(), out imageIndex);
                }
                else if (data.ContainsKey("imageUrl") && data["imageUrl"] != null)
                {
                    // If imageUrl is provided, try to extract index from it
                    var imageUrlObj = data["imageUrl"];
                    
                    if (imageUrlObj is string)
                    {
                        string imageUrl = imageUrlObj as string;
                        imageIndex = ExtractImageIndex(imageUrl);
                    }
                    else if (imageUrlObj is ArrayList || imageUrlObj is object[])
                    {
                        // Image data was sent instead of URL - return error
                        context.Response.Write(serializer.Serialize(new
                        {
                            success = false,
                            error = "Invalid request format. Please send image index or URL, not image data."
                        }));
                        return;
                    }
                    else
                    {
                        // Try to convert to string
                        imageIndex = ExtractImageIndex(imageUrlObj.ToString());
                    }
                }
            }

            if (string.IsNullOrEmpty(variantId) || imageIndex < 0)
            {
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = "Variant ID and valid image index are required. Received: variantId=" + variantId + ", imageIndex=" + imageIndex
                }));
                return;
            }

            System.Diagnostics.Debug.WriteLine("Removing image at index: " + imageIndex + " from variant: " + variantId);

            var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
            var filter = Builders<ProductVariant>.Filter.Eq(v => v.Id, variantId);
            var variant = variantsCollection.Find(filter).FirstOrDefault();

            if (variant == null)
            {
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = "Variant not found in database"
                }));
                return;
            }

            if (variant.VariantImgUrls == null || variant.VariantImgUrls.Count == 0)
            {
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = "No images found for this variant"
                }));
                return;
            }

            if (imageIndex >= variant.VariantImgUrls.Count)
            {
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = "Image index " + imageIndex + " out of range (0-" + (variant.VariantImgUrls.Count - 1) + ")"
                }));
                return;
            }

            System.Diagnostics.Debug.WriteLine("Variant has " + variant.VariantImgUrls.Count + " images before removal");

            variant.VariantImgUrls.RemoveAt(imageIndex);
            variant.UpdatedAt = DateTime.UtcNow;

            System.Diagnostics.Debug.WriteLine("Variant has " + variant.VariantImgUrls.Count + " images after removal");

            var update = Builders<ProductVariant>.Update
                .Set(v => v.VariantImgUrls, variant.VariantImgUrls)
                .Set(v => v.UpdatedAt, variant.UpdatedAt);

            var updateResult = variantsCollection.UpdateOne(filter, update);

            if (updateResult.ModifiedCount > 0)
            {
                System.Diagnostics.Debug.WriteLine("Image removed successfully from variant " + variantId + " (index: " + imageIndex + ")");

                context.Response.Write(serializer.Serialize(new
                {
                    success = true,
                    message = "Image removed successfully",
                    remainingImages = variant.VariantImgUrls.Count
                }));
            }
            else
            {
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = "Failed to update database. No documents modified."
                }));
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine("RemoveVariantImage error: " + ex.Message + "\n" + ex.StackTrace);
            context.Response.Write(serializer.Serialize(new
            {
                success = false,
                error = "Server error: " + ex.Message,
                stackTrace = ex.StackTrace
            }));
        }
    }

    private int ExtractImageIndex(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl)) return -1;

            System.Diagnostics.Debug.WriteLine("Extracting index from URL: " + imageUrl);

            Uri uri;
            if (imageUrl.StartsWith("http://") || imageUrl.StartsWith("https://"))
            {
                uri = new Uri(imageUrl);
            }
            else if (imageUrl.StartsWith("/"))
            {
                uri = new Uri("http://dummy.com" + imageUrl);
            }
            else
            {
                uri = new Uri("http://dummy.com/" + imageUrl);
            }
            
            var query = HttpUtility.ParseQueryString(uri.Query);
            string indexStr = query["index"];
            
            System.Diagnostics.Debug.WriteLine("Index query parameter: " + indexStr);
            
            if (string.IsNullOrEmpty(indexStr)) return -1;

            int index;
            if (int.TryParse(indexStr, out index))
            {
                return index;
            }

            return -1;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine("Error extracting index from URL: " + ex.Message);
            return -1;
        }
    }

    public bool IsReusable
    {
        get { return false; }
    }
}