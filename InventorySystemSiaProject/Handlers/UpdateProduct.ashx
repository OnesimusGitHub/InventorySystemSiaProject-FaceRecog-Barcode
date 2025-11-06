<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UpdateProduct" %>

using System;
using System.Web;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;

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
                // Read request body
                string body;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    body = reader.ReadToEnd();
                }

                System.Diagnostics.Debug.WriteLine("📦 Update request body: " + body);

                var data = serializer.Deserialize<Dictionary<string, object>>(body);

                if (data == null || !data.ContainsKey("productId") || string.IsNullOrEmpty(data["productId"].ToString()))
                {
                    context.Response.Write(serializer.Serialize(new { 
                        success = false, 
                        error = "Product ID is required" 
                    }));
                    return;
                }

                string productId = data["productId"].ToString();
                string productName = data.ContainsKey("productName") ? data["productName"].ToString() : "";
                string category = data.ContainsKey("category") ? data["category"].ToString() : "";
                string description = data.ContainsKey("description") ? data["description"].ToString() : "";
                string supplierId = data.ContainsKey("supplierId") ? data["supplierId"].ToString() : null;
                string imageUrl = data.ContainsKey("imageUrl") ? data["imageUrl"].ToString() : "";

                // Validation
                if (string.IsNullOrEmpty(productName))
                {
                    context.Response.Write(serializer.Serialize(new { 
                        success = false, 
                        error = "Product name is required" 
                    }));
                    return;
                }

                // Get collections
                var productsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("Products");
                var productIngredientsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("ProductIngredients");

                // Parse productId as ObjectId
                ObjectId productObjectId;
                try
                {
                    productObjectId = ObjectId.Parse(productId);
                }
                catch
                {
                    context.Response.Write(serializer.Serialize(new { 
                        success = false, 
                        error = "Invalid product ID format" 
                    }));
                    return;
                }

                // Check if product exists
                var productFilter = Builders<BsonDocument>.Filter.Eq("_id", productObjectId);
                var existingProduct = productsCollection.Find(productFilter).FirstOrDefault();

                if (existingProduct == null)
                {
                    context.Response.Write(serializer.Serialize(new { 
                        success = false, 
                        error = "Product not found" 
                    }));
                    return;
                }

                // ✅ UPDATE PRODUCT DOCUMENT
                var updateBuilder = Builders<BsonDocument>.Update
                    .Set("productName", productName)
                    .Set("productCategory", category)
                    .Set("productDesc", description)
                    .Set("productImg", imageUrl)
                    .Set("updatedAt", DateTime.UtcNow);

                // Add supplierId if provided
                if (!string.IsNullOrEmpty(supplierId))
                {
                    try
                    {
                        var supplierObjectId = ObjectId.Parse(supplierId);
                        updateBuilder = updateBuilder.Set("supplierId", supplierObjectId);
                    }
                    catch
                    {
                        updateBuilder = updateBuilder.Set("supplierId", supplierId);
                    }
                }

                var updateResult = productsCollection.UpdateOne(productFilter, updateBuilder);

                System.Diagnostics.Debug.WriteLine("✅ Product updated: " + updateResult.ModifiedCount);

                // ✅ UPDATE INGREDIENTS
                if (data.ContainsKey("ingredients") && data["ingredients"] != null)
                {
                    try
                    {
                        System.Diagnostics.Debug.WriteLine("🧪 Processing ingredients...");

                        // Delete existing product ingredients
                        var deleteFilter = Builders<BsonDocument>.Filter.Eq("productId", productObjectId);
                        var deleteResult = productIngredientsCollection.DeleteMany(deleteFilter);
                        
                        System.Diagnostics.Debug.WriteLine("🗑️ Deleted old ingredients: " + deleteResult.DeletedCount);

                        // Parse ingredients array
                        var ingredientsArray = data["ingredients"] as System.Collections.ArrayList;
                        
                        if (ingredientsArray != null && ingredientsArray.Count > 0)
                        {
                            System.Diagnostics.Debug.WriteLine("📋 Processing " + ingredientsArray.Count + " ingredients");

                            foreach (var item in ingredientsArray)
                            {
                                var ingredient = item as Dictionary<string, object>;
                                if (ingredient == null) continue;

                                string ingredientId = ingredient.ContainsKey("id") ? ingredient["id"].ToString() : "";
                                string name = ingredient.ContainsKey("name") ? ingredient["name"].ToString() : "";
                                string unit = ingredient.ContainsKey("unit") ? ingredient["unit"].ToString() : "";
                                
                                // Parse quantity safely
                                decimal quantity = 0;
                                if (ingredient.ContainsKey("quantity"))
                                {
                                    try
                                    {
                                        quantity = Convert.ToDecimal(ingredient["quantity"]);
                                    }
                                    catch
                                    {
                                        System.Diagnostics.Debug.WriteLine("⚠️ Failed to parse quantity for " + name);
                                        continue;
                                    }
                                }

                                if (string.IsNullOrEmpty(ingredientId))
                                {
                                    System.Diagnostics.Debug.WriteLine("⚠️ Skipping ingredient with empty ID");
                                    continue;
                                }

                                // Parse ingredientId as ObjectId
                                ObjectId ingredientObjectId;
                                try
                                {
                                    ingredientObjectId = ObjectId.Parse(ingredientId);
                                }
                                catch
                                {
                                    System.Diagnostics.Debug.WriteLine("⚠️ Invalid ingredient ID: " + ingredientId);
                                    continue; // Skip invalid ingredient IDs
                                }

                                // Insert new ProductIngredient document
                                var productIngredientDoc = new BsonDocument
                                {
                                    { "productId", productObjectId },
                                    { "ingredientId", ingredientObjectId },
                                    { "quantityRequired", quantity },
                                    { "unit", unit },
                                    { "isActive", true },
                                    { "createdAt", DateTime.UtcNow }
                                };

                                productIngredientsCollection.InsertOne(productIngredientDoc);
                                System.Diagnostics.Debug.WriteLine("✅ Inserted ingredient: " + name);
                            }

                            System.Diagnostics.Debug.WriteLine("✅ All ingredients processed successfully");
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("⚠️ No ingredients to add");
                        }
                    }
                    catch (Exception ingEx)
                    {
                        System.Diagnostics.Debug.WriteLine("❌ Error updating ingredients: " + ingEx.Message);
                        System.Diagnostics.Debug.WriteLine("Stack trace: " + ingEx.StackTrace);
                        
                        // Return error to client
                        context.Response.Write(serializer.Serialize(new
                        {
                            success = false,
                            error = "Failed to update ingredients: " + ingEx.Message
                        }));
                        return;
                    }
                }

                context.Response.Write(serializer.Serialize(new
                {
                    success = true,
                    message = "Product updated successfully"
                }));
                
                System.Diagnostics.Debug.WriteLine("✅ Update complete!");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("❌ Update failed: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("Stack trace: " + ex.StackTrace);
                
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = "Update failed: " + ex.Message,
                    stackTrace = ex.StackTrace
                }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}