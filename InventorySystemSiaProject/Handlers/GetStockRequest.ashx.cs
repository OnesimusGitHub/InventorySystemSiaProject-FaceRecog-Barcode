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
    /// Universal handler to get stock request details (Product or Ingredient)
    /// Automatically detects the type and returns appropriate data
    /// Usage: /Handlers/GetStockRequest.ashx?id={requestId}
    /// </summary>
    public class GetStockRequest : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("=== GetStockRequest handler called ===");
                
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

                // ? STEP 1: Try to find as Ingredient Stock Request first
                System.Diagnostics.Debug.WriteLine("?? Checking if this is an Ingredient Stock Request...");
                var ingredientRequestsCollection = DatabaseHelper.GetIngredientStockRequestsCollection();
                IngredientStockRequest ingredientRequest = null;

                try
                {
                    ObjectId objectId;
                    if (ObjectId.TryParse(requestId, out objectId))
                    {
                        var filter = Builders<IngredientStockRequest>.Filter.Eq("_id", objectId);
                        ingredientRequest = ingredientRequestsCollection.Find(filter).FirstOrDefault();
                    }
                }
                catch { }

                if (ingredientRequest != null)
                {
                    System.Diagnostics.Debug.WriteLine("? Found as Ingredient Stock Request - processing...");
                    ProcessIngredientStockRequest(context, ingredientRequest, serializer);
                    return;
                }

                // ? STEP 2: If not ingredient request, try as Product Stock Request
                System.Diagnostics.Debug.WriteLine("?? Checking if this is a Product Stock Request...");
                var stockRequestsCollection = DatabaseHelper.GetStockRequestsCollection();
                StockRequest productRequest = null;

                try
                {
                    ObjectId objectId;
                    if (ObjectId.TryParse(requestId, out objectId))
                    {
                        var filter = new BsonDocument("_id", objectId);
                        productRequest = stockRequestsCollection.Find(filter).FirstOrDefault();
                    }
                    
                    if (productRequest == null)
                    {
                        var filter = new BsonDocument("_id", requestId);
                        productRequest = stockRequestsCollection.Find(filter).FirstOrDefault();
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error fetching product stock request: {ex.Message}");
                }

                if (productRequest != null)
                {
                    System.Diagnostics.Debug.WriteLine("? Found as Product Stock Request - processing...");
                    ProcessProductStockRequest(context, productRequest, serializer);
                    return;
                }

                // ? STEP 3: Not found in either collection
                System.Diagnostics.Debug.WriteLine($"? Stock request not found with ID: {requestId}");
                context.Response.StatusCode = 404;
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    message = "Stock request not found in either Product or Ingredient collections"
                }));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"??? FATAL ERROR in GetStockRequest ???");
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

        /// <summary>
        /// Process and return Ingredient Stock Request details
        /// </summary>
        private void ProcessIngredientStockRequest(HttpContext context, IngredientStockRequest request, JavaScriptSerializer serializer)
        {
            // Get ingredient details
            var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
            Ingredient ingredient = null;
            string ingredientName = "N/A";
            string unit = "units";
            decimal currentStock = 0;

            try
            {
                ObjectId ingredientObjId;
                if (ObjectId.TryParse(request.IngredientID, out ingredientObjId))
                {
                    var ingredientFilter = Builders<Ingredient>.Filter.Eq("_id", ingredientObjId);
                    ingredient = ingredientsCollection.Find(ingredientFilter).FirstOrDefault();
                }

                if (ingredient != null)
                {
                    ingredientName = ingredient.IngredientName ?? "Unknown Ingredient";
                    unit = ingredient.Unit ?? "units";
                    currentStock = ingredient.CurrentStock;
                    System.Diagnostics.Debug.WriteLine($"? Ingredient found: {ingredientName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error fetching ingredient: {ex.Message}");
            }

            // Get supplier details
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

                if (supplier != null)
                {
                    supplierName = supplier.SupName ?? "Unknown Supplier";
                    System.Diagnostics.Debug.WriteLine($"? Supplier found: {supplierName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error fetching supplier: {ex.Message}");
            }

            // Return success response
            var response = new
            {
                success = true,
                requestType = "ingredient",
                request = new
                {
                    RequestID = request.RequestID ?? "",
                    DisplayRequestID = request.DisplayRequestID ?? "",
                    ProductName = $"{ingredientName} ({unit})", // For compatibility with frontend
                    IngredientName = ingredientName,
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

            System.Diagnostics.Debug.WriteLine("? Sending ingredient stock request response");
            context.Response.Write(serializer.Serialize(response));
        }

        /// <summary>
        /// Process and return Product Stock Request details
        /// </summary>
        private void ProcessProductStockRequest(HttpContext context, StockRequest request, JavaScriptSerializer serializer)
        {
            // Get product variant details
            var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
            ProductVariant variant = null;
            string productName = "N/A";
            int currentStock = 0;

            try
            {
                ObjectId variantObjId;
                if (ObjectId.TryParse(request.ProductVariantID, out variantObjId))
                {
                    var variantFilter = new BsonDocument("_id", variantObjId);
                    variant = variantsCollection.Find(variantFilter).FirstOrDefault();
                }
                
                if (variant == null && !string.IsNullOrEmpty(request.ProductVariantID))
                {
                    var variantFilter = new BsonDocument("_id", request.ProductVariantID);
                    variant = variantsCollection.Find(variantFilter).FirstOrDefault();
                }

                if (variant != null)
                {
                    productName = variant.VariantName ?? "Unknown Product";
                    currentStock = variant.StockQuantity;
                    System.Diagnostics.Debug.WriteLine($"? Product variant found: {productName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error fetching variant: {ex.Message}");
            }

            // Get supplier details
            var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
            Supplier supplier = null;
            string supplierName = "N/A";

            try
            {
                ObjectId supplierObjId;
                if (ObjectId.TryParse(request.SupplierID, out supplierObjId))
                {
                    var supplierFilter = new BsonDocument("_id", supplierObjId);
                    supplier = suppliersCollection.Find(supplierFilter).FirstOrDefault();
                }
                
                if (supplier == null && !string.IsNullOrEmpty(request.SupplierID))
                {
                    var supplierFilter = new BsonDocument("_id", request.SupplierID);
                    supplier = suppliersCollection.Find(supplierFilter).FirstOrDefault();
                }

                if (supplier != null)
                {
                    supplierName = supplier.SupName ?? "Unknown Supplier";
                    System.Diagnostics.Debug.WriteLine($"? Supplier found: {supplierName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error fetching supplier: {ex.Message}");
            }

            // Return success response
            var response = new
            {
                success = true,
                requestType = "product",
                request = new
                {
                    RequestID = request.RequestID ?? "",
                    DisplayRequestID = request.DisplayRequestID ?? "",
                    ProductName = productName,
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

            System.Diagnostics.Debug.WriteLine("? Sending product stock request response");
            context.Response.Write(serializer.Serialize(response));
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
