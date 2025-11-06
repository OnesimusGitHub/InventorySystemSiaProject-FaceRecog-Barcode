<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetProductIngredients" %>

using System;
using System.Web;
using System.Linq;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;

namespace InventorySystemSiaProject.Handlers
{
    public class GetProductIngredients : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                // Get productId from query string or POST
                string productId = context.Request.QueryString["productId"];
                
                if (string.IsNullOrEmpty(productId) && context.Request.HttpMethod == "POST")
                {
                    try
                    {
                        context.Request.InputStream.Position = 0;
                        using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                        {
                            var body = reader.ReadToEnd();
                            var dict = serializer.Deserialize<Dictionary<string, object>>(body);
                            if (dict != null && dict.ContainsKey("productId") && dict["productId"] != null)
                            {
                                productId = dict["productId"].ToString();
                            }
                        }
                    }
                    catch { }
                }

                if (string.IsNullOrEmpty(productId))
                {
                    context.Response.Write(serializer.Serialize(new { 
                        success = false, 
                        error = "Missing productId parameter"
                    }));
                    return;
                }

                // Get ProductIngredients collection directly
                var productIngredientsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("ProductIngredients");
                var ingredientsCollection = DatabaseHelper.Database.GetCollection<BsonDocument>("Ingredients");

                // Try to parse productId as ObjectId, fallback to string comparison
                FilterDefinition<BsonDocument> filter;
                try
                {
                    var productObjectId = ObjectId.Parse(productId);
                    filter = Builders<BsonDocument>.Filter.And(
                        Builders<BsonDocument>.Filter.Eq("productId", productObjectId),
                        Builders<BsonDocument>.Filter.Eq("isActive", true)
                    );
                }
                catch
                {
                    // If parsing fails, try string comparison
                    filter = Builders<BsonDocument>.Filter.And(
                        Builders<BsonDocument>.Filter.Eq("productId", productId),
                        Builders<BsonDocument>.Filter.Eq("isActive", true)
                    );
                }

                var productIngredients = productIngredientsCollection.Find(filter).ToList();

                var result = new List<object>();

                foreach (var pi in productIngredients)
                {
                    try
                    {
                        // Get ingredientId as ObjectId
                        var ingredientIdValue = pi.GetValue("ingredientId");
                        ObjectId ingredientObjectId;
                        
                        if (ingredientIdValue.IsObjectId)
                        {
                            ingredientObjectId = ingredientIdValue.AsObjectId;
                        }
                        else
                        {
                            ingredientObjectId = ObjectId.Parse(ingredientIdValue.AsString);
                        }

                        var quantity = pi.GetValue("quantityRequired", BsonValue.Create(0)).ToDecimal();
                        var unit = pi.GetValue("unit", "").AsString;

                        // Get ingredient details from Ingredients collection
                        var ingredientFilter = Builders<BsonDocument>.Filter.Eq("_id", ingredientObjectId);
                        var ingredient = ingredientsCollection.Find(ingredientFilter).FirstOrDefault();

                        var name = "Unknown";
                        if (ingredient != null)
                        {
                            name = ingredient.GetValue("ingredientName", "Unknown").AsString;
                            
                            // Use ingredient's unit if not specified in ProductIngredient
                            if (string.IsNullOrEmpty(unit))
                            {
                                unit = ingredient.GetValue("unit", "").AsString;
                            }
                        }

                        result.Add(new
                        {
                            id = ingredientObjectId.ToString(),
                            name = name,
                            unit = unit,
                            quantity = quantity
                        });
                    }
                    catch (Exception itemEx)
                    {
                        // Skip this ingredient if there's an error processing it
                        System.Diagnostics.Debug.WriteLine("Error processing ingredient: " + itemEx.Message);
                    }
                }

                context.Response.Write(serializer.Serialize(new { 
                    success = true, 
                    ingredients = result 
                }));
            }
            catch (Exception ex)
            {
                context.Response.Write(serializer.Serialize(new { 
                    success = false, 
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
