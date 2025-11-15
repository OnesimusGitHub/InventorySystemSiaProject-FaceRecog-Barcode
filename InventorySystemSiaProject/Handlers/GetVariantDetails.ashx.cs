using System;
using System.Web;
using System.Web.Script.Serialization;
using System.Linq;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class GetVariantDetails : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                System.Diagnostics.Debug.WriteLine("=== GetVariantDetails handler called ===");
                
                string variantId = context.Request.QueryString["variantId"];
                System.Diagnostics.Debug.WriteLine($"Received variantId: {variantId}");

                if (string.IsNullOrWhiteSpace(variantId))
                {
                    System.Diagnostics.Debug.WriteLine("Variant ID is empty");
                    context.Response.StatusCode = 400;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Variant ID is required"
                    }));
                    return;
                }

                // Get variant using simple BSON filter
                System.Diagnostics.Debug.WriteLine("Fetching variant from database...");
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                
                ProductVariant variant = null;
                try
                {
                    // Use simple BsonDocument filter
                    var filter = new BsonDocument("_id", new ObjectId(variantId));
                    variant = variantsCollection.Find(filter).FirstOrDefault();
                    
                    if (variant != null)
                    {
                        System.Diagnostics.Debug.WriteLine($"? Variant found: {variant.VariantName}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("? Variant not found");
                    }
                }
                catch (FormatException fex)
                {
                    System.Diagnostics.Debug.WriteLine($"Invalid ObjectId format: {fex.Message}");
                    context.Response.StatusCode = 400;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Invalid variant ID format"
                    }));
                    return;
                }
                catch (MongoDB.Driver.MongoCommandException mongoEx)
                {
                    System.Diagnostics.Debug.WriteLine($"MongoDB Command Error: {mongoEx.Message}");
                    System.Diagnostics.Debug.WriteLine($"Error Code: {mongoEx.Code}");
                    System.Diagnostics.Debug.WriteLine($"Error CodeName: {mongoEx.CodeName}");
                    throw new Exception($"Database command error (code {mongoEx.Code}): {mongoEx.Message}", mongoEx);
                }
                catch (System.TimeoutException timeoutEx)
                {
                    System.Diagnostics.Debug.WriteLine($"Timeout Error: {timeoutEx.Message}");
                    throw new Exception("Database query timed out. Please try again.", timeoutEx);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Unexpected error fetching variant: {ex.GetType().Name} - {ex.Message}");
                    throw;
                }

                if (variant == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Variant not found with ID: {variantId}");
                    context.Response.StatusCode = 404;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Variant not found"
                    }));
                    return;
                }

                System.Diagnostics.Debug.WriteLine($"Variant found: {variant.VariantName}, ProductId: {variant.ProductId}");

                // Get product using simple BSON filter
                System.Diagnostics.Debug.WriteLine("Fetching product from database...");
                var productsCollection = DatabaseHelper.GetProductsCollection();
                
                Product product = null;
                try
                {
                    var productFilter = new BsonDocument("_id", new ObjectId(variant.ProductId));
                    product = productsCollection.Find(productFilter).FirstOrDefault();
                    
                    if (product != null)
                    {
                        System.Diagnostics.Debug.WriteLine($"? Product found: {product.ProductName}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("? Product not found");
                    }
                }
                catch (MongoDB.Driver.MongoCommandException mongoEx)
                {
                    System.Diagnostics.Debug.WriteLine($"MongoDB Command Error fetching product: {mongoEx.Message}");
                    System.Diagnostics.Debug.WriteLine($"Error Code: {mongoEx.Code}");
                    throw new Exception($"Database command error (code {mongoEx.Code}): {mongoEx.Message}", mongoEx);
                }
                catch (System.TimeoutException timeoutEx)
                {
                    System.Diagnostics.Debug.WriteLine($"Timeout Error fetching product: {timeoutEx.Message}");
                    throw new Exception("Database query timed out. Please try again.", timeoutEx);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Unexpected error fetching product: {ex.GetType().Name} - {ex.Message}");
                    throw;
                }

                if (product == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Product not found with ID: {variant.ProductId}");
                    context.Response.StatusCode = 404;
                    context.Response.Write(serializer.Serialize(new
                    {
                        success = false,
                        message = "Product not found"
                    }));
                    return;
                }


               

                // Get supplier using simple BSON filter
                System.Diagnostics.Debug.WriteLine("Fetching supplier from database...");
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                
              

                System.Diagnostics.Debug.WriteLine($"? All data retrieved successfully");

                // Return success response
                var response = new
                {
                    success = true,
                    variant = new
                    {
                        id = variant.Id ?? "",
                        variantName = variant.VariantName ?? "Unknown Product",
                        stockQuantity = variant.StockQuantity,
                        minimumStock = variant.MinimumStock
                    },
                    product = new
                    {
                        id = product.Id ?? "",
                        productName = product.ProductName ?? "Unknown Product"
                    },

                };

                System.Diagnostics.Debug.WriteLine("Sending success response");
                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                // Log the full exception details
                System.Diagnostics.Debug.WriteLine($"??? FATAL ERROR in GetVariantDetails ???");
                System.Diagnostics.Debug.WriteLine($"Exception Type: {ex.GetType().FullName}");
                System.Diagnostics.Debug.WriteLine($"Message: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Stack trace: {ex.StackTrace}");
                
                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine($"Inner Exception Type: {ex.InnerException.GetType().FullName}");
                    System.Diagnostics.Debug.WriteLine($"Inner Exception Message: {ex.InnerException.Message}");
                    System.Diagnostics.Debug.WriteLine($"Inner Stack trace: {ex.InnerException.StackTrace}");
                }
                
                context.Response.StatusCode = 500;
                
                // Create detailed error response
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
                    // If serialization fails, send a simple error message
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
