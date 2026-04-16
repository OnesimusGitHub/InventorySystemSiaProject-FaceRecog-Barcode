InventorySystemSiaProject\Handlers\ProcessStockRequestAction.ashx
<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ProcessStockRequestAction" %>

using System;
using System.Web;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;
using System.Security.Cryptography;
using System.Text;
using MongoDB.Bson;
using System.Configuration;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Handles stock request approval/rejection from email links
    /// </summary>
    public class ProcessStockRequestAction : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            // Run async method synchronously
            ProcessRequestAsync(context).GetAwaiter().GetResult();
        }

        private async Task ProcessRequestAsync(HttpContext context)
        {
            System.Diagnostics.Debug.WriteLine("=== Handler start ===");
            System.Diagnostics.Debug.WriteLine("RAW URL: " + context.Request.Url);
            System.Diagnostics.Debug.WriteLine("RAW QUERY: " + context.Request.Url.Query);
            System.Diagnostics.Debug.WriteLine("QS requestId=" + context.Request.QueryString["requestId"]);
            System.Diagnostics.Debug.WriteLine("QS action=" + context.Request.QueryString["action"]);
            System.Diagnostics.Debug.WriteLine("QS token=" + context.Request.QueryString["token"]);

            context.Response.ContentType = "text/html";

            try
            {
                System.Diagnostics.Debug.WriteLine("Step 1: Reading query params");
                string requestId = context.Request.QueryString["requestId"];
                string action = context.Request.QueryString["action"];
                string token = context.Request.QueryString["token"];

                System.Diagnostics.Debug.WriteLine(
                    "Email action received: RequestID=" + requestId + ", Action=" + action);

                if (string.IsNullOrWhiteSpace(requestId) ||
                    string.IsNullOrWhiteSpace(action) ||
                    string.IsNullOrWhiteSpace(token))
                {
                    System.Diagnostics.Debug.WriteLine("Step 2: Missing parameters -> ShowErrorPage");
                    ShowErrorPage(
                        context,
                        "Invalid Request",
                        "Missing parameters. requestId='" + requestId +
                        "', action='" + action +
                        "', token='" + token + "'.");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("Step 3: Before lookup");

                // Robust lookup: try ObjectId, then RequestID field, then PackageId
                var productService = new ProductService();
                StockRequest stockRequest = null;

                // First attempt: try existing service if it expects the same type
                try
                {
                    stockRequest = await productService.GetStockRequestByIdAsync(requestId).ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine("ProductService.GetStockRequestByIdAsync returned: " + (stockRequest != null));
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("ProductService.GetStockRequestByIdAsync threw: " + ex.ToString());
                    stockRequest = null;
                }

                // Fallbacks if not found
                if (stockRequest == null)
                {
                    System.Diagnostics.Debug.WriteLine("Fallback: direct DB lookups");
                    var coll = DatabaseHelper.GetStockRequestsCollection();

                    // Try parse as ObjectId
                    FilterDefinition<StockRequest> filter = null;
                    try
                    {
                        // Predeclare ObjectId for older C# language versions (no inline out var)
                        ObjectId oid;
                        if (ObjectId.TryParse(requestId, out oid))
                        {
                            filter = Builders<StockRequest>.Filter.Eq("_id", oid);
                            stockRequest = await coll.Find(filter).FirstOrDefaultAsync().ConfigureAwait(false);
                            System.Diagnostics.Debug.WriteLine("Lookup by _id (ObjectId) returned: " + (stockRequest != null));
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Error parsing ObjectId or querying by _id: " + ex.ToString());
                    }

                    // Try search by RequestID field (string) if still null
                    if (stockRequest == null)
                    {
                        try
                        {
                            filter = Builders<StockRequest>.Filter.Eq(r => r.RequestID, requestId);
                            stockRequest = await coll.Find(filter).FirstOrDefaultAsync().ConfigureAwait(false);
                            System.Diagnostics.Debug.WriteLine("Lookup by RequestID returned: " + (stockRequest != null));
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine("Lookup by RequestID threw: " + ex.ToString());
                        }
                    }

                    // Try PackageId or other possible fields
                    if (stockRequest == null)
                    {
                        try
                        {
                            filter = Builders<StockRequest>.Filter.Eq("packageId", requestId);
                            stockRequest = await coll.Find(filter).FirstOrDefaultAsync().ConfigureAwait(false);
                            System.Diagnostics.Debug.WriteLine("Lookup by packageId returned: " + (stockRequest != null));
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine("Lookup by packageId threw: " + ex.ToString());
                        }
                    }
                }

                // NEW: If not in StockRequests, check EquipmentStockRequests and redirect to equipment handler if found
                if (stockRequest == null)
                {
                    System.Diagnostics.Debug.WriteLine("Step 4: stockRequest == null -> checking EquipmentStockRequests as fallback");
                    try
                    {
                        ObjectId eqOid;
                        if (ObjectId.TryParse(requestId, out eqOid))
                        {
                            var eqColl = DatabaseHelper.GetEquipmentStockRequestsCollection();
                            var eqFilter = Builders<EquipmentStockRequest>.Filter.Eq("_id", eqOid);
                            var eqReq = await eqColl.Find(eqFilter).FirstOrDefaultAsync().ConfigureAwait(false);
                            if (eqReq != null)
                            {
                                System.Diagnostics.Debug.WriteLine("Found document in EquipmentStockRequests -> redirecting to equipment handler");
                                string redirectUrl = "/Handlers/ProcessEquipmentEmailAction.ashx?requestId=" + HttpUtility.UrlEncode(requestId) + "&action=" + HttpUtility.UrlEncode(action) + "&token=" + HttpUtility.UrlEncode(token);                                // Use non-blocking redirect and complete request
                                context.Response.Redirect(redirectUrl, false);
                                context.ApplicationInstance.CompleteRequest();
                                return;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Equipment fallback lookup threw: " + ex.ToString());
                    }
                }

                if (stockRequest == null)
                {
                        try
{
    System.Diagnostics.Debug.WriteLine("Step 4b: checking IngredientStockRequests as fallback");
    ObjectId ingOid;
    if (ObjectId.TryParse(requestId, out ingOid))
    {
        var ingColl = DatabaseHelper.GetIngredientStockRequestsCollection();
        var ingFilter = Builders<InventorySystemSiaProject.Models.IngredientStockRequest>.Filter.Eq("_id", ingOid);
        var ingReq = await ingColl.Find(ingFilter).FirstOrDefaultAsync().ConfigureAwait(false);
        if (ingReq != null)
        {
            System.Diagnostics.Debug.WriteLine("Found document in IngredientStockRequests -> redirecting to ingredient email handler");
            string redirectUrl = "/Handlers/ProcessIngredientStockRequestAction.ashx?requestId=" + HttpUtility.UrlEncode(requestId)
                                 + "&action=" + HttpUtility.UrlEncode(action)
                                 + "&token=" + HttpUtility.UrlEncode(token);
            context.Response.Redirect(redirectUrl, false);
            context.ApplicationInstance.CompleteRequest();
            return;
        }
    }
}
catch (Exception ex)
{
    System.Diagnostics.Debug.WriteLine("Ingredient fallback lookup threw: " + ex.ToString());
}

                    System.Diagnostics.Debug.WriteLine("Step 4b: stockRequest == null -> ShowErrorPage");
                    ShowErrorPage(context, "Request Not Found", "The stock request could not be found for id: " + HttpUtility.HtmlEncode(requestId));
                    return;

                      

                }

                System.Diagnostics.Debug.WriteLine("Step 5: Before GenerateToken");
                string expectedToken = GenerateToken(requestId, stockRequest.RequestDate);
                System.Diagnostics.Debug.WriteLine("Step 5: After GenerateToken");

                if (token != expectedToken)
                {
                    System.Diagnostics.Debug.WriteLine("Step 6: Invalid token -> ShowErrorPage");
                    ShowErrorPage(context, "Invalid Token", "The security token is invalid or has expired.");
                    return;
                }

                if (stockRequest.RequestStatus != "Pending")
                {
                    System.Diagnostics.Debug.WriteLine("Step 7: Already processed -> ShowInfoPage");
                    ShowInfoPage(
                        context,
                        "Already Processed",
                        "This request has already been " + stockRequest.RequestStatus.ToLower() + ".",
                        stockRequest);
                    return;
                }

                System.Diagnostics.Debug.WriteLine("Step 8: Before GetSupplierByIdAsync");
                var supplierService = new SupplierService();
                var supplier = await supplierService.GetSupplierByIdAsync(stockRequest.SupplierID).ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine("Step 8: After GetSupplierByIdAsync");

                string supplierName = supplier != null && !string.IsNullOrEmpty(supplier.SupName)
                    ? supplier.SupName
                    : "Supplier";

                string normalizedAction = (action ?? string.Empty).ToLowerInvariant();
                System.Diagnostics.Debug.WriteLine("Step 9: normalizedAction = " + normalizedAction);

                if (normalizedAction == "approve")
                {
                    System.Diagnostics.Debug.WriteLine("Step 10a: Approve start");
                    stockRequest.Approve(supplierName, stockRequest.SupplierID);
                    await productService.UpdateStockRequestAsync(stockRequest).ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine("Step 10a: Approve after UpdateStockRequestAsync");

                    ShowSuccessPage(
                        context,
                        "Request Approved",
                        "Thank you! The stock request has been approved successfully.",
                        stockRequest);
                }
                else if (normalizedAction == "reject")
                {
                    System.Diagnostics.Debug.WriteLine("Step 10b: Reject start");
                    string reason = "Rejected via email by supplier";
                    stockRequest.Reject(supplierName, stockRequest.SupplierID, reason);
                    await productService.UpdateStockRequestAsync(stockRequest).ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine("Step 10b: Reject after UpdateStockRequestAsync");

                    ShowSuccessPage(
                        context,
                        "Request Rejected",
                        "The stock request has been rejected.",
                        stockRequest);
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("Step 10c: Invalid action -> ShowErrorPage");
                    ShowErrorPage(context, "Invalid Action", "The specified action is not valid.");
                }

                System.Diagnostics.Debug.WriteLine("=== Handler end (normal) ===");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("=== Handler exception ===");
                System.Diagnostics.Debug.WriteLine("Error processing email action: " + ex.ToString());

                ShowErrorPage(
                    context,
                    "Error",
                    "An error occurred: " + ex.Message);
            }
        }

        /// <summary>
        /// Generates a security token for email links (SHA256) — must match SendEmaikService.GenerateSecureToken
        /// </summary>
        public static string GenerateToken(string requestId, DateTime requestDate)
        {
            try
            {
                // Use concatenation / ToString instead of interpolated string for C#5 compatibility
                string input = requestId + "_" + requestDate.ToString("yyyyMMddHHmmss") + "_SecretKey123";
                using (var sha256 = SHA256.Create())
                {
                    byte[] bytes = Encoding.UTF8.GetBytes(input);
                    byte[] hash = sha256.ComputeHash(bytes);
                    return Convert.ToBase64String(hash).Replace("+", "-").Replace("/", "_").Replace("=", "");
                }
            }
            catch
            {
                // Fallback: simple stable encoding (no interpolation)
                return Convert.ToBase64String(Encoding.UTF8.GetBytes(requestId + "_" + requestDate.Ticks.ToString())).Replace("+", "-").Replace("/", "_").Replace("=", "");
            }
        }

        private void ShowSuccessPage(HttpContext context, string title, string message, StockRequest request)
        {
            // (unchanged: same HTML rendering as before)
            string html = string.Format(@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width, initial-scale=1.0' />
    <title>{0}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }}
        .container {{
            background: white;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.2);
            max-width: 600px;
            width: 100%;
            padding: 40px;
            text-align: center;
        }}
        .success-icon {{
            width: 80px;
            height: 80px;
            background: #28a745;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 48px;
            color: white;
        }}
        h1 {{
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }}
        p {{
            color: #666;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 20px;
        }}
        .details {{
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
        }}
        .details-row {{
            display: flex;
            padding: 8px 0;
            border-bottom: 1px solid #dee2e6;
        }}
        .details-row:last-child {{
            border-bottom: none;
        }}
        .details-label {{
            font-weight: bold;
            width: 140px;
            color: #495057;
        }}
        .details-value {{
            flex: 1;
            color: #212529;
        }}
        .status-badge {{
            display: inline-block;
            padding: 6px 16px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 14px;
            background: #28a745;
            color: white;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='success-icon'>✔</div>
        <h1>{0}</h1>
        <p>{1}</p>
        
        <div class='details'>
            <div class='details-row'>
                <div class='details-label'>Request ID:</div>
                <div class='details-value'><strong>{2}</strong></div>
            </div>
            <div class='details-row'>
                <div class='details-label'>Quantity:</div>
                <div class='details-value'>{3} units</div>
            </div>
            <div class='details-row'>
                <div class='details-label'>Status:</div>
                <div class='details-value'>
                    <span class='status-badge'>{4}</span>
                </div>
            </div>
            <div class='details-row'>
                <div class='details-label'>Processed:</div>
                <div class='details-value'>{5}</div>
            </div>
        </div>

        <p style='font-size: 14px; color: #999; margin-top: 30px;'>
            You can close this window. The inventory system has been updated automatically.
        </p>
    </div>
</body>
</html>",
                HttpUtility.HtmlEncode(title),
                HttpUtility.HtmlEncode(message),
                HttpUtility.HtmlEncode(request.DisplayRequestID),
                request.QuantityRequested,
                HttpUtility.HtmlEncode(request.RequestStatus),
                DateTime.Now.ToString("MMM dd, yyyy HH:mm"));

            context.Response.Write(html);
            context.Response.Flush();
            context.ApplicationInstance.CompleteRequest();
        }

        private void ShowInfoPage(HttpContext context, string title, string message, StockRequest request)
        {
            // (unchanged)
            string html = string.Format(@"
<!DOCTYPE html>
<html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width, initial-scale=1.0' /><title>{0}</title>
<style>body{{font-family:Arial,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0;padding:20px}}.container{{background:white;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.2);max-width:600px;width:100%;padding:40px;text-align:center}}.info-icon{{width:80px;height:80px;background:#17a2b8;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 20px;font-size:48px;color:white}}h1{{color:#333;margin-bottom:10px;font-size:28px}}p{{color:#666;font-size:16px;line-height:1.6}}</style></head><body><div class='container'><div class='info-icon'>ℹ</div><h1>{0}</h1><p>{1}</p><div class='status-badge' style='display:inline-block;padding:6px 16px;border-radius:20px;font-weight:600;font-size:14px;background:#17a2b8;color:white;margin-top:15px;'>Current Status: {2}</div><p style='font-size:14px;color:#999;margin-top:30px;'>Request ID: {3}</p></div></body></html>",
                HttpUtility.HtmlEncode(title),
                HttpUtility.HtmlEncode(message),
                HttpUtility.HtmlEncode(request.RequestStatus),
                HttpUtility.HtmlEncode(request.DisplayRequestID));

            context.Response.Write(html);
            context.Response.Flush();
            context.ApplicationInstance.CompleteRequest();
        }

        private void ShowErrorPage(HttpContext context, string title, string message)
        {
            // compute and encode the base URL separately so the HTML literal stays well-formed
            string appBase = ConfigurationManager.AppSettings["AppBaseUrl"];
            if (string.IsNullOrEmpty(appBase))
            {
                appBase = "/WebPages/ProductStock.aspx";
            }

            string encodedAppBase = HttpUtility.HtmlEncode(appBase);

            string html = string.Format(@"
<!DOCTYPE html><html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width, initial-scale=1.0' /><title>{0}</title>
<style>body{{font-family:Arial,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0;padding:20px}}.container{{background:white;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,0.2);max-width:700px;width:100%;padding:40px;text-align:center}}.error-icon{{width:80px;height:80px;background:#dc3545;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 20px;font-size:48px;color:white}}h1{{color:#333;margin-bottom:10px;font-size:28px}}p{{color:#666;font-size:16px;line-height:1.6}}</style></head><body><div class='container'><div class='error-icon'>!</div><h1>{0}</h1><p>{1}</p><p style='font-size:14px;color:#999;margin-top:30px;'>If you think this is an error, please contact the inventory team or open the system directly: <a href='{2}' target='_blank'>Open Inventory System</a></p></div></body></html>",
                HttpUtility.HtmlEncode(title),
                HttpUtility.HtmlEncode(message),
                encodedAppBase);

            context.Response.Write(html);
            context.Response.Flush();
            context.ApplicationInstance.CompleteRequest();
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}