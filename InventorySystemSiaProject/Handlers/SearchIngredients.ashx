<%@ WebHandler Language="C#" Class="SearchIngredients" %>

using System;
using System.Web;
using System.Linq;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;

public class SearchIngredients : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        
        try
        {
            // ? FIX: Accept both "query" and "term" parameters for compatibility
            string searchTerm = context.Request.QueryString["query"] ?? context.Request.QueryString["term"];
            
            if (string.IsNullOrEmpty(searchTerm))
            {
                // Return empty success response instead of empty array
                context.Response.Write(new JavaScriptSerializer().Serialize(new
                {
                    success = false,
                    ingredients = new List<object>(),
                    message = "Search term is required"
                }));
                return;
            }

            var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
            
            // Search for active ingredients that match the search term
            var filter = Builders<Ingredient>.Filter.And(
                Builders<Ingredient>.Filter.Eq(i => i.IsActive, true),
                Builders<Ingredient>.Filter.Regex(i => i.IngredientName, 
                    new MongoDB.Bson.BsonRegularExpression(searchTerm, "i"))
            );
            
            var ingredients = ingredientsCollection.Find(filter)
                .Limit(10)
                .ToList();
            
            // ? Return response in the format expected by ProductPage.aspx
            var results = ingredients.Select(i => new
            {
                id = i.Id,
                name = i.IngredientName,
                label = i.IngredientName,
                value = i.IngredientName,
                unit = i.Unit,
                costPerUnit = i.CostPerUnit
            }).ToList();
            
            var response = new
            {
                success = true,
                ingredients = results,
                count = results.Count
            };
            
            var serializer = new JavaScriptSerializer();
            context.Response.Write(serializer.Serialize(response));
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            context.Response.Write(new JavaScriptSerializer().Serialize(new
            {
                success = false,
                error = ex.Message,
                ingredients = new List<object>()
            }));
        }
    }

    public bool IsReusable
    {
        get { return false; }
    }
}
