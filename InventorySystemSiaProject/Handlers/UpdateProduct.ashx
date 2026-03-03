<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateProduct" %>

using System;
using System.Web;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;
using System.IO;
using System.Linq;

namespace InventorySystemSiaProject.Handlers
{
    public class UpdateProduct : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("========== UPDATE PRODUCT REQUEST ==========");
                System.Diagnostics.Debug.WriteLine(string.Format("Content-Type: {0}", context.Request.ContentType));
                System.Diagnostics.Debug.WriteLine(string.Format("Files.Count: {0}", context.Request.Files.Count));

                // Get form data
                string productId = context.Request.Form["productId"];
                string productName = context.Request.Form["productName"];
                string category = context.Request.Form["category"];
                string description = context.Request.Form["description"];
                string ingredientsJson = context.Request.Form["ingredients"];

                if (string.IsNullOrEmpty(productId))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Product ID is required" }));
                    return;
                }

                var productsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("Products");
                ObjectId productObjectId = ObjectId.Parse(productId);

                // Check if product exists
                var productFilter = Builders<BsonDocument>.Filter.Eq("_id", productObjectId);
                var existingProduct = productsCollection.Find(productFilter).FirstOrDefault();

                if (existingProduct == null)
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "Product not found" }));
                    return;
                }

                // Build update
                var updateBuilder = Builders<BsonDocument>.Update
                    .Set("productName", productName)
                    .Set("productCategory", category)
                    .Set("productDesc", description)
                    .Set("updatedAt", DateTime.UtcNow);

                // ✅ CRITICAL FIX: Handle file upload
                bool imageUpdated = false;
                HttpPostedFile uploadedFile = null;

                // Try to get file from request
                string[] possibleKeys = { "productImage", "file", "image" };
                
                foreach (string key in possibleKeys)
                {
                    if (context.Request.Files[key] != null && context.Request.Files[key].ContentLength > 0)
                    {
                        uploadedFile = context.Request.Files[key];
                        System.Diagnostics.Debug.WriteLine(string.Format("✅ Found file with key: {0}", key));
                        break;
                    }
                }

                // Also try index-based access
                if (uploadedFile == null && context.Request.Files.Count > 0)
                {
                    uploadedFile = context.Request.Files[0];
                    System.Diagnostics.Debug.WriteLine("✅ Using first file from Files collection");
                }

                if (uploadedFile != null && uploadedFile.ContentLength > 0)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("📷 Processing file: {0} ({1} bytes, type: {2})", 
                        uploadedFile.FileName, uploadedFile.ContentLength, uploadedFile.ContentType));

                    // Validate file
                    string fileExtension = Path.GetExtension(uploadedFile.FileName).ToLower();
                    string[] allowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

                    if (!Array.Exists(allowedExtensions, ext => ext == fileExtension))
                    {
                        context.Response.Write(serializer.Serialize(new { success = false, error = "Invalid image format" }));
                        return;
                    }

                    if (uploadedFile.ContentLength > 5 * 1024 * 1024)
                    {
                        context.Response.Write(serializer.Serialize(new { success = false, error = "Image must be less than 5MB" }));
                        return;
                    }

                    // Convert to byte array
                    byte[] imageBlob;
                    using (var binaryReader = new BinaryReader(uploadedFile.InputStream))
                    {
                        imageBlob = binaryReader.ReadBytes(uploadedFile.ContentLength);
                    }

                    // ✅ CRITICAL: Store as BsonBinaryData with CORRECT field name: productImg
                    var bsonBinaryData = new BsonBinaryData(imageBlob, BsonBinarySubType.Binary);

                    updateBuilder = updateBuilder
                        .Set("productImg", bsonBinaryData)  // ✅ Changed from productImage to productImg
                        .Set("ProductImgContentType", uploadedFile.ContentType);

                    imageUpdated = true;
                    System.Diagnostics.Debug.WriteLine(string.Format("✅ Image added to update builder as productImg ({0} bytes)", imageBlob.Length));
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("⚠️ No file uploaded or file is empty");
                }

                // Update ingredients if provided
                if (!string.IsNullOrEmpty(ingredientsJson))
                {
                    try
                    {
                        var ingredientsList = serializer.Deserialize<System.Collections.ArrayList>(ingredientsJson);
                        var productIngredientsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("ProductIngredients");
                        
                        var deleteFilter = Builders<BsonDocument>.Filter.Eq("productId", productObjectId);
                        productIngredientsCollection.DeleteMany(deleteFilter);

                        if (ingredientsList != null && ingredientsList.Count > 0)
                        {
                            foreach (var item in ingredientsList)
                            {
                                var ingredient = item as System.Collections.Generic.Dictionary<string, object>;
                                if (ingredient == null) continue;

                                string ingredientId = ingredient.ContainsKey("id") ? ingredient["id"].ToString() : "";
                                decimal quantity = 0;
                                if (ingredient.ContainsKey("quantity"))
                                {
                                    try { quantity = Convert.ToDecimal(ingredient["quantity"]); }
                                    catch { continue; }
                                }

                                if (string.IsNullOrEmpty(ingredientId)) continue;

                                ObjectId ingredientObjectId = ObjectId.Parse(ingredientId);

                                var productIngredientDoc = new BsonDocument
                                {
                                    { "productId", productObjectId },
                                    { "ingredientId", ingredientObjectId },
                                    { "quantityRequired", quantity },
                                    { "unit", ingredient.ContainsKey("unit") ? ingredient["unit"].ToString() : "" },
                                    { "isActive", true },
                                    { "createdAt", DateTime.UtcNow }
                                };

                                productIngredientsCollection.InsertOne(productIngredientDoc);
                            }
                        }
                    }
                    catch (Exception ingEx)
                    {
                        System.Diagnostics.Debug.WriteLine(string.Format("Error updating ingredients: {0}", ingEx.Message));
                    }
                }

                // Perform update
                System.Diagnostics.Debug.WriteLine("Executing MongoDB update...");
                var updateResult = productsCollection.UpdateOne(productFilter, updateBuilder);

                System.Diagnostics.Debug.WriteLine(string.Format("Update result - Matched: {0}, Modified: {1}", 
                    updateResult.MatchedCount, updateResult.ModifiedCount));

                if (updateResult.ModifiedCount > 0 || updateResult.MatchedCount > 0)
                {
                    string message = "Product updated successfully";
                    if (imageUpdated)
                    {
                        message += " (image updated)";
                    }
                    
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = true,
                        message = message,
                        imageUpdated = imageUpdated
                    }));
                }
                else
                {
                    context.Response.Write(serializer.Serialize(new { success = false, error = "No changes were made" }));
                }

                System.Diagnostics.Debug.WriteLine("========== UPDATE COMPLETE ==========");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("EXCEPTION: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("Stack trace: {0}", ex.StackTrace));

                context.Response.Write(serializer.Serialize(new { success = false, error = "Update failed: " + ex.Message }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}