<%@ WebHandler Language="C#" Class="ValidateIngredient" %>

using System;
using System.Web;
using System.Linq;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;

public class ValidateIngredient : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        
        try
        {
            string ingredientName = context.Request.QueryString["name"];
            
            if (string.IsNullOrEmpty(ingredientName))
            {
                context.Response.Write(new JavaScriptSerializer().Serialize(new
                {
                    exists = false,
                    message = "Ingredient name is required"
                }));
                return;
            }

            var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
            
            // Search for exact match (case insensitive)
            var filter = Builders<Ingredient>.Filter.And(
                Builders<Ingredient>.Filter.Eq(i => i.IsActive, true),
                Builders<Ingredient>.Filter.Regex(i => i.IngredientName, 
                    new MongoDB.Bson.BsonRegularExpression("^" + ingredientName + "$", "i"))
            );
            
            var ingredient = ingredientsCollection.Find(filter).FirstOrDefault();
            
            if (ingredient != null)
            {
                context.Response.Write(new JavaScriptSerializer().Serialize(new
                {
                    exists = true,
                    ingredient = new
                    {
                        id = ingredient.Id,
                        name = ingredient.IngredientName,
                        unit = ingredient.Unit,
                        costPerUnit = ingredient.CostPerUnit
                    }
                }));
            }
            else
            {
                context.Response.Write(new JavaScriptSerializer().Serialize(new
                {
                    exists = false,
                    message = "Ingredient '" + ingredientName + "' does not exist in the database"
                }));
            }
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            context.Response.Write(new JavaScriptSerializer().Serialize(new
            {
                exists = false,
                error = ex.Message
            }));
        }
    }

    public bool IsReusable
    {
        get { return false; }
    }
}
