<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetIngredientStockRequest" %>

using System;
using System.Web;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using Newtonsoft.Json;

namespace InventorySystemSiaProject.Handlers
{
    public class GetIngredientStockRequest : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            string requestId = context.Request["id"];
            if (string.IsNullOrWhiteSpace(requestId))
            {
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = "Missing request ID." }));
                return;
            }

            try
            {
                var collection = DatabaseHelper.GetIngredientStockRequestsCollection();
                var request = collection.Find(x => x.RequestID == requestId).FirstOrDefault();
                if (request == null)
                {
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = "Request not found." }));
                    return;
                }

                // Get ingredient name
                var ingredient = DatabaseHelper.GetIngredientsCollection().Find(x => x.Id == request.IngredientID).FirstOrDefault();
                var supplier = DatabaseHelper.GetSuppliersCollection().Find(x => x.SupplierID == request.SupplierID).FirstOrDefault();

                var result = new
                {
                    success = true,
                    data = new
                    {
                        requestId = request.RequestID,
                        ingredientName = (ingredient != null) ? ingredient.IngredientName : "N/A",
                        supplierName = (supplier != null) ? supplier.SupName : "N/A",
                        quantityRequested = request.QuantityRequested,
                        unit = request.Unit,
                        requestDate = request.RequestDate,
                        requestedBy = request.RequestedBy,
                        requestStatus = request.RequestStatus,
                        instructions = request.Instructions,
                        expectedDeliveryDate = request.ExpectedDeliveryDate,
                        actualDeliveryDate = request.ActualDeliveryDate,
                        statusUpdatedDate = request.StatusUpdatedDate,
                        processedBy = request.ProcessedBy,
                        rejectionReason = request.RejectionReason,
                        totalCost = request.TotalCost,
                        unitPrice = request.UnitPrice,
                        currentStockAtRequest = request.CurrentStockAtRequest,
                        minimumStockLevel = request.MinimumStockLevel,
                        priority = request.Priority
                    }
                };
                context.Response.Write(JsonConvert.SerializeObject(result));
            }
            catch (Exception ex)
            {
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, message = ex.Message }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
