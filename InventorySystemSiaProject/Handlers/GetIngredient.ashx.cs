using System;
using System.Web;
using System.Threading.Tasks;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using Newtonsoft.Json;

namespace InventorySystemSiaProject.Handlers
{
    public class GetIngredient : HttpTaskAsyncHandler
    {
        public override async Task ProcessRequestAsync(HttpContext context)
        {


            context.Response.ContentType = "application/json";
            
            try
            {
                System.Diagnostics.Debug.WriteLine("?? GetIngredient handler called");
                
                string ingredientId = context.Request.QueryString["id"];
                
                System.Diagnostics.Debug.WriteLine($"?? Ingredient ID requested: {ingredientId}");
                
                if (string.IsNullOrEmpty(ingredientId))
                {
                    System.Diagnostics.Debug.WriteLine("? Ingredient ID is missing");
                    context.Response.StatusCode = 400;
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = "Ingredient ID is required" }));
                    return;
                }
                
                // Get ingredient
                var ingredientsColl = DatabaseHelper.GetIngredientsCollection();
                var ingredient = await ingredientsColl.Find(i => i.Id == ingredientId && i.IsActive).FirstOrDefaultAsync();
                
                if (ingredient == null)
                {
                    System.Diagnostics.Debug.WriteLine($"? Ingredient not found: {ingredientId}");
                    context.Response.StatusCode = 404;
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = "Ingredient not found" }));
                    return;
                }
                
                System.Diagnostics.Debug.WriteLine($"? Ingredient found: {ingredient.IngredientName}");
                
                // Get supplier name if supplier ID exists
                string supplierName = "N/A";
                if (!string.IsNullOrEmpty(ingredient.SupplierId))
                {
                    var suppliersColl = DatabaseHelper.GetSuppliersCollection();
                    var supplier = await suppliersColl.Find(s => s.SupplierID == ingredient.SupplierId).FirstOrDefaultAsync();
                    
                    if (supplier != null)
                    {
                        supplierName = supplier.SupName;
                        System.Diagnostics.Debug.WriteLine($"?? Supplier found: {supplierName}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"?? Supplier not found for ID: {ingredient.SupplierId}");
                    }
                }
                
                var result = new
                {
                    success = true,
                    data = new
                    {
                        id = ingredient.Id,
                        SKU = ingredient.SKU,
                        ingredientName = ingredient.IngredientName,
                        unit = ingredient.Unit,
                        costPerUnit = ingredient.CostPerUnit,
                        currentStock = ingredient.CurrentStock,
                        minimumStock = ingredient.MinimumStock,
                        supplierId = ingredient.SupplierId ?? "",
                        supplierName = supplierName
                    }
                };
                
                System.Diagnostics.Debug.WriteLine("? Returning ingredient data with supplier name");
                
                context.Response.Write(JsonConvert.SerializeObject(result, Formatting.Indented));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? GetIngredient error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
                
                context.Response.StatusCode = 500;
                context.Response.Write(JsonConvert.SerializeObject(new 
                { 
                    success = false, 
                    message = ex.Message,
                    details = ex.StackTrace
                }, Formatting.Indented));
            }
        }
    }
}
