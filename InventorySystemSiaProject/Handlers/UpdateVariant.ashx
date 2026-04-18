InventorySystemSiaProject\Handlers\UpdateVariant.ashx
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
                string variantSize = null;
                string variantColor = null;
                string variantDimensions = null;
                string description = null;
                string location = null;
                decimal? variantWeight = null;
                int? shelfLifeYears = null;

                // presence flags (to allow empty string -> explicit clear)
                bool hasVariantName = false;
                bool hasVariantSKU = false;
                bool hasVariantPrice = false;
                bool hasVariantStock = false;
                bool hasVariantMinStock = false;
                bool hasVariantSize = false;
                bool hasVariantColor = false;
                bool hasVariantDimensions = false;
                bool hasDescription = false;
                bool hasLocation = false;
                bool hasVariantWeight = false;
                bool hasShelfLifeYears = false;

                List<byte[]> replacementImages = null;
                bool clearImagesRequested = false;

                Dictionary<string, object> jsonData = null;

                if (isFormData)
                {
                    var form = context.Request.Form;
                    // Id
                    variantId = form["variantId"];

                    // use same keys as AddProductVariant: VariantName, SKU, Description, Location etc.
                    // support both PascalCase and lowercase names
                    if (form.AllKeys != null)
                    {
                        // variant name
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "variantName", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "VariantName", StringComparison.OrdinalIgnoreCase)))
                        {
                            variantName = form["variantName"] ?? form["VariantName"];
                            hasVariantName = true;
                        }
                        // sku
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "sku", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "SKU", StringComparison.OrdinalIgnoreCase)))
                        {
                            variantSKU = form["sku"] ?? form["SKU"];
                            hasVariantSKU = true;
                        }
                        // size
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "size", StringComparison.OrdinalIgnoreCase)))
                        {
                            variantSize = form["size"];
                            hasVariantSize = true;
                        }
                        // color
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "color", StringComparison.OrdinalIgnoreCase)))
                        {
                            variantColor = form["color"];
                            hasVariantColor = true;
                        }
                        // dimensions
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "dimensions", StringComparison.OrdinalIgnoreCase)))
                        {
                            variantDimensions = form["dimensions"];
                            hasVariantDimensions = true;
                        }
                        // description - accept "Description" (Add handler style) or "description"
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "Description", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "description", StringComparison.OrdinalIgnoreCase)))
                        {
                            // prefer PascalCase form key first to match AddProductVariant usage
                            description = form["Description"] ?? form["description"];
                            hasDescription = true;
                        }
                        // location
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "Location", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "location", StringComparison.OrdinalIgnoreCase)))
                        {
                            location = form["Location"] ?? form["location"];
                            hasLocation = true;
                        }
                        // price
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "variantPrice", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "Price", StringComparison.OrdinalIgnoreCase)))
                        {
                            string priceRaw = form["variantPrice"] ?? form["Price"];
                            if (!string.IsNullOrWhiteSpace(priceRaw))
                            {
                                decimal parsed;
                                if (TryParseDecimalLoose(priceRaw, out parsed))
                                {
                                    variantPrice = parsed;
                                    variantPriceProvided = true;
                                }
                            }
                            hasVariantPrice = true;
                        }
                        // stock
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "variantStock", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "StockQuantity", StringComparison.OrdinalIgnoreCase)))
                        {
                            string s = form["variantStock"] ?? form["StockQuantity"];
                            int stockVal;
                            if (int.TryParse(s, out stockVal))
                            {
                                variantStock = stockVal;
                            }
                            hasVariantStock = true;
                        }
                        // min stock
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "variantMinStock", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "MinimumStock", StringComparison.OrdinalIgnoreCase)))
                        {
                            string m = form["variantMinStock"] ?? form["MinimumStock"];
                            int minVal;
                            if (int.TryParse(m, out minVal))
                            {
                                variantMinStock = minVal;
                            }
                            hasVariantMinStock = true;
                        }
                        // weight
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "variantWeight", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "Weight", StringComparison.OrdinalIgnoreCase)))
                        {
                            string wStr = form["variantWeight"] ?? form["Weight"];
                            decimal w;
                            if (!string.IsNullOrEmpty(wStr) && decimal.TryParse(wStr, out w))
                            {
                                variantWeight = w;
                            }
                            hasVariantWeight = true;
                        }
                        // shelf life
                        if (Array.Exists(form.AllKeys, k => string.Equals(k, "shelfLifeYears", StringComparison.OrdinalIgnoreCase) || string.Equals(k, "ShelfLifeYears", StringComparison.OrdinalIgnoreCase)))
                        {
                            string sly = form["shelfLifeYears"] ?? form["ShelfLifeYears"];
                            int slyv;
                            if (!string.IsNullOrEmpty(sly) && int.TryParse(sly, out slyv))
                            {
                                shelfLifeYears = slyv;
                            }
                            hasShelfLifeYears = true;
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

                                using (var ms = new MemoryStream())
                                {
                                    file.InputStream.CopyTo(ms);
                                    replacementImages.Add(ms.ToArray());
                                }
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

                    if (jsonData.ContainsKey("variantName"))
                    {
                        hasVariantName = true;
                        variantName = jsonData["variantName"] != null ? jsonData["variantName"].ToString() : "";
                    }
                    if (jsonData.ContainsKey("VariantName"))
                    {
                        hasVariantName = true;
                        variantName = jsonData["VariantName"] != null ? jsonData["VariantName"].ToString() : variantName;
                    }

                    if (jsonData.ContainsKey("variantSKU"))
                    {
                        hasVariantSKU = true;
                        variantSKU = jsonData["variantSKU"] != null ? jsonData["variantSKU"].ToString() : "";
                    }
                    if (jsonData.ContainsKey("SKU"))
                    {
                        hasVariantSKU = true;
                        variantSKU = jsonData["SKU"] != null ? jsonData["SKU"].ToString() : variantSKU;
                    }

                    if (jsonData.ContainsKey("variantSize"))
                    {
                        hasVariantSize = true;
                        variantSize = jsonData["variantSize"] != null ? jsonData["variantSize"].ToString() : "";
                    }
                    if (jsonData.ContainsKey("variantColor"))
                    {
                        hasVariantColor = true;
                        variantColor = jsonData["variantColor"] != null ? jsonData["variantColor"].ToString() : "";
                    }
                    if (jsonData.ContainsKey("variantDimensions"))
                    {
                        hasVariantDimensions = true;
                        variantDimensions = jsonData["variantDimensions"] != null ? jsonData["variantDimensions"].ToString() : "";
                    }

                    // description: check both keys
                    if (jsonData.ContainsKey("description"))
                    {
                        hasDescription = true;
                        description = jsonData["description"] != null ? jsonData["description"].ToString() : "";
                    }
                    else if (jsonData.ContainsKey("Description"))
                    {
                        hasDescription = true;
                        description = jsonData["Description"] != null ? jsonData["Description"].ToString() : "";
                    }

                    // location
                    if (jsonData.ContainsKey("location"))
                    {
                        hasLocation = true;
                        location = jsonData["location"] != null ? jsonData["location"].ToString() : "";
                    }
                    else if (jsonData.ContainsKey("Location"))
                    {
                        hasLocation = true;
                        location = jsonData["Location"] != null ? jsonData["Location"].ToString() : "";
                    }

                    // price
                    if (jsonData.ContainsKey("variantPrice") || jsonData.ContainsKey("Price"))
                    {
                        object raw = jsonData.ContainsKey("variantPrice") ? jsonData["variantPrice"] : jsonData["Price"];
                        hasVariantPrice = true;
                        try
                        {
                            if (raw is double || raw is float || raw is int || raw is long || raw is decimal)
                            {
                                variantPrice = Convert.ToDecimal(raw);
                                variantPriceProvided = true;
                            }
                            else if (raw != null)
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

                    if (jsonData.ContainsKey("variantStock") || jsonData.ContainsKey("StockQuantity"))
                    {
                        hasVariantStock = true;
                        object raw = jsonData.ContainsKey("variantStock") ? jsonData["variantStock"] : jsonData["StockQuantity"];
                        try { variantStock = Convert.ToInt32(raw); } catch { }
                    }

                    if (jsonData.ContainsKey("variantMinStock") || jsonData.ContainsKey("MinimumStock"))
                    {
                        hasVariantMinStock = true;
                        object raw = jsonData.ContainsKey("variantMinStock") ? jsonData["variantMinStock"] : jsonData["MinimumStock"];
                        try { variantMinStock = Convert.ToInt32(raw); } catch { }
                    }

                    if (jsonData.ContainsKey("variantWeight") || jsonData.ContainsKey("Weight"))
                    {
                        hasVariantWeight = true;
                        object raw = jsonData.ContainsKey("variantWeight") ? jsonData["variantWeight"] : jsonData["Weight"];
                        try { variantWeight = Convert.ToDecimal(raw); } catch { }
                    }

                    if (jsonData.ContainsKey("shelfLifeYears") || jsonData.ContainsKey("ShelfLifeYears"))
                    {
                        hasShelfLifeYears = true;
                        object raw = jsonData.ContainsKey("shelfLifeYears") ? jsonData["shelfLifeYears"] : jsonData["ShelfLifeYears"];
                        try { shelfLifeYears = Convert.ToInt32(raw); } catch { }
                    }

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

                // validation: variantId required
                if (string.IsNullOrEmpty(variantId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Variant ID is missing or empty" }));
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

                // prepare update: only set fields that were actually provided
                var db = _variantsCollection.Database;
                string collName = _variantsCollection.CollectionNamespace.CollectionName;
                var bsonColl = db.GetCollection<BsonDocument>(collName);
                var filterDoc = Builders<BsonDocument>.Filter.Eq("_id", new ObjectId(variantId));
                var updatesList = new List<UpdateDefinition<BsonDocument>>();

                if (hasVariantName)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("variantName", variantName ?? ""));
                if (hasVariantSKU)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("sku", variantSKU ?? ""));
                if (hasVariantSize)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("size", variantSize ?? ""));
                if (hasVariantColor)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("color", variantColor ?? ""));
                if (hasVariantStock)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("stockQuantity", variantStock));
                if (hasVariantMinStock)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("minimumStock", variantMinStock));

                if (hasVariantWeight)
                {
                    if (variantWeight.HasValue)
                        updatesList.Add(Builders<BsonDocument>.Update.Set("weight", BsonDecimal128.Create(variantWeight.Value)));
                    else
                        updatesList.Add(Builders<BsonDocument>.Update.Unset("weight"));
                }

                if (hasVariantDimensions)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("dimensions", variantDimensions ?? ""));

                // description: IMPORTANT - use only lowercase 'description'
                if (hasDescription)
                {
                    // set to provided value (may be empty string to clear)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("description", description ?? ""));
                    // remove legacy PascalCase field if present
                    updatesList.Add(Builders<BsonDocument>.Update.Unset("Description"));
                }

                if (hasLocation)
                    updatesList.Add(Builders<BsonDocument>.Update.Set("location", location ?? ""));

                if (hasShelfLifeYears)
                {
                    if (shelfLifeYears.HasValue)
                        updatesList.Add(Builders<BsonDocument>.Update.Set("shelfLifeYears", shelfLifeYears.Value));
                    else
                        updatesList.Add(Builders<BsonDocument>.Update.Unset("shelfLifeYears"));
                }

                // always update UpdatedAt
                updatesList.Add(Builders<BsonDocument>.Update.Set("UpdatedAt", DateTime.UtcNow));

                if (hasVariantPrice && variantPriceProvided)
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

                if (updatesList.Count == 0)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "No updatable fields provided" }));
                    return;
                }

                var combinedUpdate = Builders<BsonDocument>.Update.Combine(updatesList);

                // Log attempt
                int imageCount = (replacementImages != null) ? replacementImages.Count : 0;
                Debug.WriteLine(string.Format("[UpdateVariant] Attempt: variantId={0} providedFields={1} imagesCount={2}",
                    variantId,
                    string.Join(",", new string[] {
                        hasVariantName ? "variantName":null,
                        hasVariantSKU ? "sku":null,
                        hasDescription ? "description":null
                    }),
                    imageCount));

                var updateResult = bsonColl.UpdateOne(filterDoc, combinedUpdate);

                // Fetch the updated document to verify stored description and other fields
                var updatedDoc = bsonColl.Find(filterDoc).FirstOrDefault();
                string updatedDescription = "";

                if (updatedDoc != null && updatedDoc.Contains("description") && !updatedDoc["description"].IsBsonNull)
                {
                    try { updatedDescription = updatedDoc["description"].AsString; }
                    catch { updatedDescription = updatedDoc["description"].ToString(); }
                }

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
                    imagesCount = imagesCount,
                    // diagnostics
                    modifiedCount = updateResult.ModifiedCount,
                    descriptionSent = (hasDescription ? (description ?? "") : null),
                    descriptionInDb = updatedDescription
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