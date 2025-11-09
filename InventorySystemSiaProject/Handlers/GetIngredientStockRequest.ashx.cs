using System;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetIngredientStockRequest : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                string id = context.Request.QueryString["id"];
                if (string.IsNullOrWhiteSpace(id))
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write(serializer.Serialize(new { success = false, message = "Request ID is required" }));
                    return;
                }

                var collection = DatabaseHelper.GetIngredientStockRequestsCollection();
                IngredientStockRequest request = null;
                // Try both ObjectId and string
                if (ObjectId.TryParse(id, out ObjectId objId))
                {
                    request = collection.Find(Builders<IngredientStockRequest>.Filter.Eq("_id", objId)).FirstOrDefault();
                }
                if (request == null)
                {
                    request = collection.Find(Builders<IngredientStockRequest>.Filter.Eq("_id", id)).FirstOrDefault();
                }
                if (request == null)
                {
                    context.Response.StatusCode = 404;
                    context.Response.Write(serializer.Serialize(new { success = false, message = "Ingredient stock request not found" }));
                    return;
                }

                // Fetch ingredient name
                string ingredientName = "";
                if (!string.IsNullOrEmpty(request.IngredientID))
                {
                    var ingredientColl = DatabaseHelper.GetIngredientsCollection();
                    var ingredient = ingredientColl.Find(Builders<Ingredient>.Filter.Eq("_id", request.IngredientID)).FirstOrDefault();
                    if (ingredient != null)
                        ingredientName = ingredient.IngredientName ?? "";
                }

                // Fetch supplier name
                string supplierName = "";
                if (!string.IsNullOrEmpty(request.SupplierID))
                {
                    var supplierColl = DatabaseHelper.GetSuppliersCollection();
                    var supplier = supplierColl.Find(Builders<Supplier>.Filter.Eq("_id", request.SupplierID)).FirstOrDefault();
                    if (supplier != null)
                        supplierName = supplier.SupName ?? "";
                }

                // Convert all ObjectId fields to string
                var response = new
                {
                    success = true,
                    request = new
                    {
                        RequestID = request.RequestID,
                        IngredientID = request.IngredientID,
                        SupplierID = request.SupplierID,
                        RequestedByUserId = request.RequestedByUserId,
                        ProcessedByUserId = request.ProcessedByUserId,
                        // Other fields
                        QuantityRequested = request.QuantityRequested,
                        Unit = request.Unit,
                        RequestDate = request.RequestDate,
                        RequestedBy = request.RequestedBy,
                        RequestStatus = request.RequestStatus,
                        Instructions = request.Instructions,
                        ExpectedDeliveryDate = request.ExpectedDeliveryDate,
                        ActualDeliveryDate = request.ActualDeliveryDate,
                        StatusUpdatedDate = request.StatusUpdatedDate,
                        ProcessedBy = request.ProcessedBy,
                        RejectionReason = request.RejectionReason,
                        TotalCost = request.TotalCost,
                        UnitPrice = request.UnitPrice,
                        CurrentStockAtRequest = request.CurrentStockAtRequest,
                        MinimumStockLevel = request.MinimumStockLevel,
                        EmailSent = request.EmailSent,
                        EmailSentDate = request.EmailSentDate,
                        Priority = request.Priority,
                        CreatedAt = request.CreatedAt,
                        UpdatedAt = request.UpdatedAt,
                        IsActive = request.IsActive,
                        DisplayRequestID = request.DisplayRequestID,
                        InstructionsText = request.Instructions,
                        IngredientName = ingredientName,
                        SupplierName = supplierName
                    }
                };
                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { success = false, message = "Server error: " + ex.Message }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
