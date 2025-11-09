using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetIngredientStockRequests : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();
            try
            {
                var collection = DatabaseHelper.GetIngredientStockRequestsCollection();
                var requests = collection.Find(Builders<IngredientStockRequest>.Filter.Empty).ToList();
                var ingredientsColl = DatabaseHelper.GetIngredientsCollection();
                var suppliersColl = DatabaseHelper.GetSuppliersCollection();

                var result = new List<object>();
                foreach (var req in requests)
                {
                    string ingredientName = "N/A";
                    string supplierName = "N/A";
                    if (!string.IsNullOrEmpty(req.IngredientID))
                    {
                        var ingredient = ingredientsColl.Find(Builders<Ingredient>.Filter.Eq("_id", req.IngredientID)).FirstOrDefault();
                        if (ingredient != null)
                            ingredientName = ingredient.IngredientName ?? "N/A";
                    }
                    if (!string.IsNullOrEmpty(req.SupplierID))
                    {
                        var supplier = suppliersColl.Find(Builders<Supplier>.Filter.Eq("_id", req.SupplierID)).FirstOrDefault();
                        if (supplier != null)
                            supplierName = supplier.SupName ?? "N/A";
                    }
                    result.Add(new {
                        RequestID = req.RequestID,
                        DisplayRequestID = req.DisplayRequestID,
                        IngredientName = ingredientName,
                        SupplierName = supplierName,
                        QuantityRequested = req.QuantityRequested,
                        Unit = req.Unit,
                        RequestDate = req.RequestDate,
                        ExpectedDeliveryDate = req.ExpectedDeliveryDate,
                        RequestedBy = req.RequestedBy,
                        RequestStatus = req.RequestStatus,
                        Priority = req.Priority,
                        Instructions = req.Instructions
                    });
                }
                context.Response.Write(serializer.Serialize(new { success = true, requests = result }));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { success = false, message = ex.Message }));
            }
        }
        public bool IsReusable { get { return false; } }
    }
}
