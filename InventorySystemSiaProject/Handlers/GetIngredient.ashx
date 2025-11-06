<%@ WebHandler Language="C#" CodeBehind="GetIngredient.ashx.cs" Class="InventorySystemSiaProject.Handlers.GetIngredient" %>

using System;
using System.Web;
using System.Threading.Tasks;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using Newtonsoft.Json;

public class GetIngredient : HttpTaskAsyncHandler
{
    public override async Task ProcessRequestAsync(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        
        try
        {
            string ingredientId = context.Request.QueryString["id"];
            
            if (string.IsNullOrEmpty(ingredientId))
            {
                context.Response.StatusCode = 400;
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = "Ingredient ID is required" }));
                return;
            }
            
            var ingredientsColl = InventorySystemSiaProject.Helpers.DatabaseHelper.GetIngredientsCollection();
            var ingredient = await ingredientsColl.Find(i => i.Id == ingredientId).FirstOrDefaultAsync();
            
            if (ingredient == null)
            {
                context.Response.StatusCode = 404;
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = "Ingredient not found" }));
                return;
            }
            
            var result = new
            {
                success = true,
                data = new
                {
                    id = ingredient.Id,
                    ingredientName = ingredient.IngredientName,
                    unit = ingredient.Unit,
                    costPerUnit = ingredient.CostPerUnit,
                    currentStock = ingredient.CurrentStock,
                    minimumStock = ingredient.MinimumStock,
                    supplierId = ingredient.SupplierId ?? ""
                }
            };
            
            context.Response.Write(JsonConvert.SerializeObject(result));
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = ex.Message }));
        }
    }
}
