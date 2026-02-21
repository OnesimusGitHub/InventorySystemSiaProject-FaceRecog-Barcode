using System;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Handler to get ingredient stock request details by ID
    /// Usage: /Handlers/GetIngredientStockRequestDetails.ashx?id={requestId}
    /// </summary>
    public class GetIngredientStockRequestDetails : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("=== GetIngredientStockRequestDetails handler called ===");
                
                string requestId = context.Request.QueryString["id"];
                System.Diagnostics.Debug.WriteLine($"Received requestId: {requestId}");

                if (string.IsNullOrWhiteSpace(requestId))
                {
                    System.Diagnostics.Debug.WriteLine("Request ID is empty");
                    context.Response.StatusCode = 400;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Request ID is required"
                    }));
                    return;
                }

                // Get ingredient stock request from database
                System.Diagnostics.Debug.WriteLine("Fetching ingredient stock request from database...");
                var ingredientStockRequestsCollection = DatabaseHelper.GetIngredientStockRequestsCollection();
                
                IngredientStockRequest request = null;
                try
                {
                    // Try to parse as ObjectId first
                    ObjectId objectId;
                    if (ObjectId.TryParse(requestId, out objectId))
                    {
                        var filter = Builders<IngredientStockRequest>.Filter.Eq("_id", objectId);
                        request = ingredientStockRequestsCollection.Find(filter).FirstOrDefault();
                    }
                    
                    // If not found, try as string ID
                    if (request == null)
                    {
                        var filter = Builders<IngredientStockRequest>.Filter.Eq("_id", requestId);
                        request = ingredientStockRequestsCollection.Find(filter).FirstOrDefault();
                    }
                    
                    if (request != null)
                    {
                        System.Diagnostics.Debug.WriteLine($"? Ingredient stock request found with ID: {request.RequestID}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("? Ingredient stock request not found");
                    }
                }
                catch (FormatException fex)
                {
                    System.Diagnostics.Debug.WriteLine($"Invalid ObjectId format: {fex.Message}");
                    context.Response.StatusCode = 400;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Invalid request ID format"
                    }));
                    return;
                }

                if (request == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Ingredient stock request not found with ID: {requestId}");
                    context.Response.StatusCode = 404;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Ingredient stock request not found"
                    }));
                    return;
                }

                // Get ingredient details
                System.Diagnostics.Debug.WriteLine($"Fetching ingredient with ID: {request.IngredientID}");
                var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
                Ingredient ingredient = null;
                string ingredientName = "N/A";
                string unit = "";
                decimal currentStock = 0;

                try
                {
                    ObjectId ingredientObjId;
                    if (ObjectId.TryParse(request.IngredientID, out ingredientObjId))
                    {
                        var ingredientFilter = Builders<Ingredient>.Filter.Eq("_id", ingredientObjId);
                        ingredient = ingredientsCollection.Find(ingredientFilter).FirstOrDefault();
                    }
                    
                    if (ingredient == null && !string.IsNullOrEmpty(request.IngredientID))
                    {
                        var ingredientFilter = Builders<Ingredient>.Filter.Eq("_id", request.IngredientID);
                        ingredient = ingredientsCollection.Find(ingredientFilter).FirstOrDefault();
                    }

                    if (ingredient != null)
                    {
                        ingredientName = ingredient.IngredientName ?? "Unknown Ingredient";
                        unit = ingredient.Unit ?? "units";
                        currentStock = ingredient.CurrentStock;
                        System.Diagnostics.Debug.WriteLine($"? Ingredient found: {ingredientName}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("?? Ingredient not found");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error fetching ingredient: {ex.Message}");
                }

                // Get supplier details
                System.Diagnostics.Debug.WriteLine($"Fetching supplier with ID: {request.SupplierID}");
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                Supplier supplier = null;
                string supplierName = "N/A";

                try
                {
                    ObjectId supplierObjId;
                    if (ObjectId.TryParse(request.SupplierID, out supplierObjId))
                    {
                        var supplierFilter = Builders<Supplier>.Filter.Eq("_id", supplierObjId);
                        supplier = suppliersCollection.Find(supplierFilter).FirstOrDefault();
                    }
                    
                    if (supplier == null && !string.IsNullOrEmpty(request.SupplierID))
                    {
                        var supplierFilter = Builders<Supplier>.Filter.Eq("_id", request.SupplierID);
                        supplier = suppliersCollection.Find(supplierFilter).FirstOrDefault();
                    }

                    if (supplier != null)
                    {
                        supplierName = supplier.SupName ?? "Unknown Supplier";
                        System.Diagnostics.Debug.WriteLine($"? Supplier found: {supplierName}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("?? Supplier not found");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error fetching supplier: {ex.Message}");
                }

                System.Diagnostics.Debug.WriteLine("? All data retrieved successfully");

                // Return success response
                var response = new
                {
                    success = true,
                    request = new
                    {
                        RequestID = request.RequestID ?? "",
                        DisplayRequestID = request.DisplayRequestID ?? "",
                        IngredientName = ingredientName,
                        ProductName = ingredientName, // Alias for compatibility
                        Unit = unit,
                        SupplierName = supplierName,
                        QuantityRequested = request.QuantityRequested,
                        RequestStatus = request.RequestStatus ?? "",
                        RequestedBy = request.RequestedBy ?? "",
                        RequestDate = request.RequestDate,
                        ExpectedDeliveryDate = request.ExpectedDeliveryDate,
                        CurrentStockAtRequest = request.CurrentStockAtRequest,
                        MinimumStockLevel = request.MinimumStockLevel,
                        Instructions = request.Instructions ?? "No additional instructions",
                        StockQuantity = currentStock,
                        Priority = request.Priority ?? "Normal"
                    }
                };

                System.Diagnostics.Debug.WriteLine("Sending success response");
                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                // Log the full exception details
                System.Diagnostics.Debug.WriteLine($"??? FATAL ERROR in GetIngredientStockRequestDetails ???");
                System.Diagnostics.Debug.WriteLine($"Exception Type: {ex.GetType().FullName}");
                System.Diagnostics.Debug.WriteLine($"Message: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
                
                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine($"Inner Exception: {ex.InnerException.Message}");
                }
                
                context.Response.StatusCode = 500;
                
                var errorResponse = new
                {
                    success = false,
                    message = "Server error: " + ex.Message,
                    exceptionType = ex.GetType().Name,
                    details = ex.Message
                };
                
                try
                {
                    context.Response.Write(serializer.Serialize(errorResponse));
                }
                catch
                {
                    context.Response.Write("{\"success\":false,\"message\":\"Fatal error occurred\"}");
                }
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
