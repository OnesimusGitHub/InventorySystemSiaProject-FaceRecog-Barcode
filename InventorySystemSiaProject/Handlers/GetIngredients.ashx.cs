using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using Newtonsoft.Json;

namespace InventorySystemSiaProject.Handlers
{
    public class GetIngredients : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            
            try
            {
                System.Diagnostics.Debug.WriteLine("?? GetIngredients handler called");
                
                // Get ingredients collection
                var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
                
                // Get only active ingredients
                var filter = Builders<Ingredient>.Filter.Eq(i => i.IsActive, true);
                var ingredients = ingredientsCollection.Find(filter).ToList();
                
                System.Diagnostics.Debug.WriteLine($"?? Found {ingredients.Count} active ingredients");
                
                // Get all suppliers for enrichment
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                var allSuppliers = suppliersCollection.Find(FilterDefinition<Supplier>.Empty).ToList();
                var supplierDict = allSuppliers.ToDictionary(s => s.SupplierID, s => s.SupName);
                
                System.Diagnostics.Debug.WriteLine($"?? Found {allSuppliers.Count} suppliers");
                
                // Create result list with enriched data
                var result = ingredients.Select(ing => new
                {
                    Id = ing.Id,
                    IngredientName = ing.IngredientName,
                    Unit = ing.Unit,
                    CurrentStock = ing.CurrentStock,
                    MinimumStock = ing.MinimumStock,
                    CostPerUnit = ing.CostPerUnit,
                    TotalValue = ing.TotalValue,
                    SupplierId = ing.SupplierId,
                    SupplierName = !string.IsNullOrEmpty(ing.SupplierId) && supplierDict.ContainsKey(ing.SupplierId) 
                        ? supplierDict[ing.SupplierId] 
                        : "N/A",
                    IsLowStock = ing.IsLowStock,
                    IsActive = ing.IsActive
                }).ToList();
                
                System.Diagnostics.Debug.WriteLine($"? GetIngredients: Returning {result.Count} enriched ingredients");
                
                // Return JSON
                var json = JsonConvert.SerializeObject(result, Formatting.Indented);
                context.Response.Write(json);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? GetIngredients error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
                
                context.Response.StatusCode = 500;
                var errorJson = JsonConvert.SerializeObject(new
                {
                    success = false,
                    error = "Failed to fetch ingredients",
                    message = ex.Message,
                    stackTrace = ex.StackTrace
                }, Formatting.Indented);
                
                context.Response.Write(errorJson);
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
