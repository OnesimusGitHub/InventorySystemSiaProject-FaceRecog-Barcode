using System;
using System.Web;
using System.Web.Script.Serialization;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
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

                // Get stock request from database
                System.Diagnostics.Debug.WriteLine("Fetching stock request from database...");
                var stockRequestsCollection = DatabaseHelper.GetStockRequestsCollection();
                
                StockRequest request = null;
                try
                {
                    // Try to parse as ObjectId first
                    ObjectId objectId;
                    if (ObjectId.TryParse(requestId, out objectId))
                    {
                        var filter = new BsonDocument("_id", objectId);
                        request = stockRequestsCollection.Find(filter).FirstOrDefault();
                    }
                    
                    // If not found, try as string ID
                    if (request == null)
                    {
                        var filter = new BsonDocument("_id", requestId);
                        request = stockRequestsCollection.Find(filter).FirstOrDefault();
                    }
                    
                    if (request != null)
                    {
                        System.Diagnostics.Debug.WriteLine($"? Stock request found with ID: {request.RequestID}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("? Stock request not found");
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
                catch (MongoDB.Driver.MongoCommandException mongoEx)
                {
                    System.Diagnostics.Debug.WriteLine($"MongoDB Command Error: {mongoEx.Message}");
                    throw new Exception($"Database command error: {mongoEx.Message}", mongoEx);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error fetching stock request: {ex.Message}");
                    throw;
                }

                if (request == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Stock request not found with ID: {requestId}");
                    context.Response.StatusCode = 404;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Stock request not found"
                    }));
                    return;
                }

                // Get product variant details
                System.Diagnostics.Debug.WriteLine($"Fetching product variant with ID: {request.ProductVariantID}");
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
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("?? Product variant not found");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error fetching variant: {ex.Message}");
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
                        StockQuantity = currentStock
                    }
                };

                System.Diagnostics.Debug.WriteLine("Sending success response");
                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                // Log the full exception details
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

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
