<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateVariant" %>

using MongoDB.Driver;
using MongoDB.Bson;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Diagnostics;
using System.Collections;
using System.Globalization;
using System.Text.RegularExpressions;

namespace InventorySystemSiaProject.Handlers
{
    public class UpdateVariant : IHttpHandler
    {
        private readonly IMongoCollection<ProductVariant> _variantsCollection;

        public UpdateVariant()
        {
            _variantsCollection = DatabaseHelper.GetProductVariantsCollection();
        }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                bool isFormData = false;
                if (context.Request.ContentType != null)
                {
                    isFormData = context.Request.ContentType.IndexOf("multipart/form-data", StringComparison.OrdinalIgnoreCase) >= 0;
                }

                string variantId = null;
                string variantName = null;
                string variantSKU = null;
                decimal variantPrice = 0m;
                bool variantPriceProvided = false;
                int variantStock = 0;
                int variantMinStock = 1000;
                string variantSize = "";
                string variantColor = "";
                string variantDimensions = "";
                string description = "";
                string location = "";
                decimal? variantWeight = null;
                int? shelfLifeYears = null;

                List<byte[]> replacementImages = null;
                bool clearImagesRequested = false;

                Dictionary<string, object> jsonData = null;

                if (isFormData)
                {
                    variantId = context.Request.Form["variantId"];
                    variantName = context.Request.Form["variantName"];
                    variantSKU = context.Request.Form["variantSKU"];
                    variantSize = context.Request.Form["variantSize"];
                    variantColor = context.Request.Form["variantColor"];
                    variantDimensions = context.Request.Form["variantDimensions"];
                    description = context.Request.Form["description"];
                    location = context.Request.Form["location"];

                    string priceRaw = context.Request.Form["variantPrice"];
                    if (!string.IsNullOrWhiteSpace(priceRaw))
                    {
                        decimal parsed;
                        if (TryParseDecimalLoose(priceRaw, out parsed))
                        {
                            variantPrice = parsed;
                            variantPriceProvided = true;
                            Debug.WriteLine("[FORM] Parsed variantPrice: " + variantPrice.ToString(CultureInfo.InvariantCulture));
                        }
                    }

                    int stock;
                    if (int.TryParse(context.Request.Form["variantStock"], out stock))
                    {
                        variantStock = stock;
                    }

                    int minStock;
                    if (int.TryParse(context.Request.Form["variantMinStock"], out minStock))
                    {
                        variantMinStock = minStock;
                    }

                    if (!string.IsNullOrEmpty(context.Request.Form["variantWeight"]))
                    {
                        decimal w;
                        if (decimal.TryParse(context.Request.Form["variantWeight"], out w))
                        {
                            variantWeight = w;
                        }
                    }

                    if (!string.IsNullOrEmpty(context.Request.Form["shelfLifeYears"]))
                    {
                        int sly;
                        if (int.TryParse(context.Request.Form["shelfLifeYears"], out sly))
                        {
                            shelfLifeYears = sly;
                        }
                    }

                    // gather files (if any)
                    if (context.Request.Files != null && context.Request.Files.Count > 0)
                    {
                        replacementImages = new List<byte[]>();
                        for (int i = 0; i < context.Request.Files.Count; i++)
                        {
                            HttpPostedFile file = context.Request.Files[i];
                            if (file != null && file.ContentLength > 0 && file.ContentType.StartsWith("image/"))
                            {
                                if (file.ContentLength > 5 * 1024 * 1024)
                                {
                                    continue;
                                }

                                byte[] compressedImage = CompressImage(file.InputStream, 1024, 85);
                                replacementImages.Add(compressedImage);
                            }
                        }
                    }
                }
                else
                {
                    string requestBody = new StreamReader(context.Request.InputStream).ReadToEnd();

                    if (string.IsNullOrWhiteSpace(requestBody))
                    {
                        context.Response.Write(serializer.Serialize(new { success = false, error = "Request body is empty" }));
                        return;
                    }

                    jsonData = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(requestBody);

                    if (jsonData.ContainsKey("variantId") && jsonData["variantId"] != null)
                        variantId = jsonData["variantId"].ToString();

                    if (jsonData.ContainsKey("variantName") && jsonData["variantName"] != null)
                        variantName = jsonData["variantName"].ToString();

                    if (jsonData.ContainsKey("variantSKU") && jsonData["variantSKU"] != null)
                        variantSKU = jsonData["variantSKU"].ToString();

                    if (jsonData.ContainsKey("variantSize") && jsonData["variantSize"] != null)
                        variantSize = jsonData["variantSize"].ToString();

                    if (jsonData.ContainsKey("variantColor") && jsonData["variantColor"] != null)
                        variantColor = jsonData["variantColor"].ToString();

                    if (jsonData.ContainsKey("variantDimensions") && jsonData["variantDimensions"] != null)
                        variantDimensions = jsonData["variantDimensions"].ToString();

                    if (jsonData.ContainsKey("description") && jsonData["description"] != null)
                        description = jsonData["description"].ToString();

                    if (jsonData.ContainsKey("location") && jsonData["location"] != null)
                        location = jsonData["location"].ToString();

                    // handle variantPrice (number or string)
                    if (jsonData.ContainsKey("variantPrice") && jsonData["variantPrice"] != null)
                    {
                        object raw = jsonData["variantPrice"];
                        try
                        {
                            if (raw is double || raw is float || raw is int || raw is long || raw is decimal)
                            {
                                variantPrice = Convert.ToDecimal(raw);
                                variantPriceProvided = true;
                            }
                            else
                            {
                                string rawStr = raw.ToString();
                                decimal parsed;
                                if (TryParseDecimalLoose(rawStr, out parsed))
                                {
                                    variantPrice = parsed;
                                    variantPriceProvided = true;
                                }
                            }
                        }
                        catch { }
                    }

                    if (jsonData.ContainsKey("variantStock") && jsonData["variantStock"] != null)
                        variantStock = Convert.ToInt32(jsonData["variantStock"]);

                    if (jsonData.ContainsKey("variantMinStock") && jsonData["variantMinStock"] != null)
                        variantMinStock = Convert.ToInt32(jsonData["variantMinStock"]);

                    if (jsonData.ContainsKey("variantWeight") && jsonData["variantWeight"] != null)
                        variantWeight = Convert.ToDecimal(jsonData["variantWeight"]);

                    if (jsonData.ContainsKey("shelfLifeYears") && jsonData["shelfLifeYears"] != null)
                        shelfLifeYears = Convert.ToInt32(jsonData["shelfLifeYears"]);

                    if (jsonData.ContainsKey("clearImages"))
                    {
                        try
                        {
                            object obj = jsonData["clearImages"];
                            if (obj != null && obj.ToString().Equals("true", StringComparison.OrdinalIgnoreCase))
                            {
                                clearImagesRequested = true;
                            }
                        }
                        catch { }
                    }

                    if (jsonData.ContainsKey("variantImgBase64") && !clearImagesRequested)
                    {
                        replacementImages = new List<byte[]>();
                        object imgsObj = jsonData["variantImgBase64"];
                        if (imgsObj != null)
                        {
                            if (imgsObj is string)
                            {
                                TryAddBase64Image(replacementImages, imgsObj.ToString());
                            }
                            else if (imgsObj is ArrayList)
                            {
                                ArrayList arr = (ArrayList)imgsObj;
                                for (int i = 0; i < arr.Count; i++)
                                {
                                    if (arr[i] == null) continue;
                                    TryAddBase64Image(replacementImages, arr[i].ToString());
                                }
                            }
                            else if (imgsObj is object[])
                            {
                                object[] arr = (object[])imgsObj;
                                for (int i = 0; i < arr.Length; i++)
                                {
                                    if (arr[i] == null) continue;
                                    TryAddBase64Image(replacementImages, arr[i].ToString());
                                }
                            }
                            else
                            {
                                TryAddBase64Image(replacementImages, imgsObj.ToString());
                            }
                        }
                    }
                }

                // validation
                if (string.IsNullOrEmpty(variantId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant ID is missing or empty" }));
                    return;
                }

                if (string.IsNullOrEmpty(variantName))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant name is required" }));
                    return;
                }

                if (string.IsNullOrEmpty(variantSKU))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant SKU is required" }));
                    return;
                }

                variantId = variantId.Trim();

                if (variantId.Length != 24 || !Regex.IsMatch(variantId, "^[0-9a-fA-F]{24}$"))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid variant ID format" }));
                    return;
                }

                // fetch existing variant
                ProductVariant variant = _variantsCollection.Find(Builders<ProductVariant>.Filter.Eq(v => v.Id, variantId)).FirstOrDefault();
                if (variant == null)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant not found" }));
                    return;
                }

                // prepare update: explicit $set uses native BSON types (ensure price becomes Decimal128)
                var db = _variantsCollection.Database;
                string collName = _variantsCollection.CollectionNamespace.CollectionName;
                var bsonColl = db.GetCollection<BsonDocument>(collName);
                var filterDoc = Builders<BsonDocument>.Filter.Eq("_id", new ObjectId(variantId));
                var updatesList = new List<UpdateDefinition<BsonDocument>>();

                updatesList.Add(Builders<BsonDocument>.Update.Set("variantName", variantName ?? ""));
                updatesList.Add(Builders<BsonDocument>.Update.Set("sku", variantSKU ?? ""));
                updatesList.Add(Builders<BsonDocument>.Update.Set("size", variantSize ?? ""));
                updatesList.Add(Builders<BsonDocument>.Update.Set("color", variantColor ?? ""));
                updatesList.Add(Builders<BsonDocument>.Update.Set("stockQuantity", variantStock));
                updatesList.Add(Builders<BsonDocument>.Update.Set("minimumStock", variantMinStock));

                if (variantWeight.HasValue)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("weight", BsonDecimal128.Create(variantWeight.Value)));
                else
                    updatesList.Add(Builders<BsonDocument>.Update.Unset("weight"));

                updatesList.Add(Builders<BsonDocument>.Update.Set("dimensions", variantDimensions ?? ""));
                updatesList.Add(Builders<BsonDocument>.Update.Set("description", description ?? ""));
                updatesList.Add(Builders<BsonDocument>.Update.Set("location", location ?? ""));

                if (shelfLifeYears.HasValue)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("shelfLifeYears", shelfLifeYears.Value));
                else
                    updatesList.Add(Builders<BsonDocument>.Update.Unset("shelfLifeYears"));

                updatesList.Add(Builders<BsonDocument>.Update.Set("UpdatedAt", DateTime.UtcNow));

                if (variantPriceProvided)
                {
                    updatesList.Add(Builders<BsonDocument>.Update.Set("price", BsonDecimal128.Create(variantPrice)));
                }

                if (clearImagesRequested)
                {
                    updatesList.Add(Builders<BsonDocument>.Update.Unset("variantImgUrls"));
                }
                else if (replacementImages != null)
                {
                    var imgArray = new BsonArray();
                    for (int i = 0; i < replacementImages.Count; i++)
                    {
                        imgArray.Add(new BsonBinaryData(replacementImages[i], BsonBinarySubType.Binary));
                    }
                    updatesList.Add(Builders<BsonDocument>.Update.Set("variantImgUrls", imgArray));
                }

                var combinedUpdate = Builders<BsonDocument>.Update.Combine(updatesList);
                var updateResult = bsonColl.UpdateOne(filterDoc, combinedUpdate);

                // Build response
                string updatedAtIso = DateTime.UtcNow.ToString("o");
                int imagesCount = (replacementImages != null) ? replacementImages.Count : (variant.VariantImgUrls != null ? variant.VariantImgUrls.Count : 0);

                context.Response.Write(serializer.Serialize(new
                {
                    success = true,
                    message = (updateResult.ModifiedCount > 0) ? "Variant updated successfully" : "No changes made",
                    variantId = variant.Id,
                    price = variantPriceProvided ? variantPrice : variant.Price,
                    updatedAt = updatedAtIso,
                    imagesCount = imagesCount
                }));
            }
            catch (Exception ex)
            {
                context.Response.Write(new JavaScriptSerializer().Serialize(new { success = false, error = ex.Message }));
            }
        }

        private static void TryAddBase64Image(List<byte[]> list, string b64)
        {
            if (string.IsNullOrWhiteSpace(b64)) return;
            try
            {
                list.Add(Convert.FromBase64String(b64));
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[ERROR] invalid base64 image entry: " + ex.Message);
            }
        }

        private byte[] CompressImage(Stream imageStream, int maxWidth, int quality)
        {
            using (var image = Image.FromStream(imageStream))
            {
                int newWidth = maxWidth;
                int newHeight = (int)(image.Height * ((float)maxWidth / image.Width));

                if (image.Width <= maxWidth)
                {
                    newWidth = image.Width;
                    newHeight = image.Height;
                }

                using (var newImage = new Bitmap(newWidth, newHeight))
                {
                    using (var graphics = Graphics.FromImage(newImage))
                    {
                        graphics.CompositingQuality = CompositingQuality.HighQuality;
                        graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        graphics.SmoothingMode = SmoothingMode.HighQuality;
                        graphics.DrawImage(image, 0, 0, newWidth, newHeight);
                    }

                    using (var ms = new MemoryStream())
                    {
                        ImageCodecInfo encoder = ImageCodecInfo.GetImageEncoders()[1];
                        EncoderParameters encoderParams = new EncoderParameters(1);
                        encoderParams.Param[0] = new EncoderParameter(Encoder.Quality, quality);
                        newImage.Save(ms, encoder, encoderParams);
                        return ms.ToArray();
                    }
                }
            }
        }

        private static bool TryParseDecimalLoose(string input, out decimal value)
        {
            value = 0m;
            if (string.IsNullOrWhiteSpace(input)) return false;

            string cleaned = Regex.Replace(input, @"[^\d\-\.,]", "");
            cleaned = cleaned.Trim();

            if (cleaned.IndexOf('.') >= 0 && cleaned.IndexOf(',') >= 0)
            {
                cleaned = cleaned.Replace(",", "");
            }
            else if (cleaned.IndexOf(',') >= 0 && cleaned.IndexOf('.') == -1)
            {
                cleaned = cleaned.Replace(",", ".");
            }

            if (decimal.TryParse(cleaned, NumberStyles.Number | NumberStyles.AllowLeadingSign | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out value))
            {
                return true;
            }

            return decimal.TryParse(cleaned, NumberStyles.Number | NumberStyles.AllowLeadingSign | NumberStyles.AllowDecimalPoint, CultureInfo.CurrentCulture, out value);
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}