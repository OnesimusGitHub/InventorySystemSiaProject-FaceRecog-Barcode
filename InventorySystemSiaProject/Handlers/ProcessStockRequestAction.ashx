<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ProcessStockRequestAction" %>

using System;
using System.Web;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;

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
            context.Response.ContentType = "text/html";

            try
            {
                // Get parameters from query string
                string requestId = context.Request.QueryString["requestId"];
                string action = context.Request.QueryString["action"]; // "approve" or "reject"
                string token = context.Request.QueryString["token"];

                System.Diagnostics.Debug.WriteLine($"?? Email action received: RequestID={requestId}, Action={action}");

                // Validate parameters
                if (string.IsNullOrWhiteSpace(requestId) || 
                    string.IsNullOrWhiteSpace(action) || 
                    string.IsNullOrWhiteSpace(token))
                {
                    ShowErrorPage(context, "Invalid Request", "Missing required parameters.");
                    return;
                }

                // Get stock request from database
                var productService = new ProductService();
                var stockRequest = await productService.GetStockRequestByIdAsync(requestId);

                if (stockRequest == null)
                {
                    ShowErrorPage(context, "Request Not Found", "The stock request could not be found.");
                    return;
                }

                // Verify token
                string expectedToken = GenerateToken(requestId, stockRequest.RequestDate);
                if (token != expectedToken)
                {
                    ShowErrorPage(context, "Invalid Token", "The security token is invalid or has expired.");
                    return;
                }

                // Check if request is already processed
                if (stockRequest.RequestStatus != "Pending")
                {
                    ShowInfoPage(context, "Already Processed", 
                        $"This request has already been {stockRequest.RequestStatus.ToLower()}.",
                        stockRequest);
                    return;
                }

                // Get supplier information
                var supplierService = new SupplierService();
                var supplier = await supplierService.GetSupplierByIdAsync(stockRequest.SupplierID);
                string supplierName = supplier?.SupName ?? "Supplier";

                // Process action
                if (action.ToLower() == "approve")
                {
                    // Approve the request
                    stockRequest.Approve(supplierName, stockRequest.SupplierID);
                    await productService.UpdateStockRequestAsync(stockRequest);

                    System.Diagnostics.Debug.WriteLine($"? Request {requestId} approved by supplier");

                    ShowSuccessPage(context, "Request Approved", 
                        "Thank you! The stock request has been approved successfully.",
                        stockRequest);
                }
                else if (action.ToLower() == "reject")
                {
                    // Reject the request with default reason
                    string reason = "Rejected via email by supplier";
                    stockRequest.Reject(supplierName, stockRequest.SupplierID, reason);
                    await productService.UpdateStockRequestAsync(stockRequest);

                    System.Diagnostics.Debug.WriteLine($"? Request {requestId} rejected by supplier");

                    ShowSuccessPage(context, "Request Rejected", 
                        "The stock request has been rejected.",
                        stockRequest);
                }
                else
                {
                    ShowErrorPage(context, "Invalid Action", "The specified action is not valid.");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? Error processing email action: {ex.Message}");
                ShowErrorPage(context, "Error", $"An error occurred: {ex.Message}");
            }
        }

        /// <summary>
        /// Generates a security token for email links
        /// </summary>
        public static string GenerateToken(string requestId, DateTime requestDate)
        {
            // Simple token generation - in production, use more secure method
            string data = $"{requestId}:{requestDate:yyyyMMddHHmmss}:InventorySystem2024";
            return Convert.ToBase64String(
                System.Text.Encoding.UTF8.GetBytes(
                    data.GetHashCode().ToString()
                )
            ).Replace("+", "-").Replace("/", "_").Replace("=", "");
        }

        private void ShowSuccessPage(HttpContext context, string title, string message, StockRequest request)
        {
            string html = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width, initial-scale=1.0' />
    <title>{title}</title>
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
        <div class='success-icon'>?</div>
        <h1>{title}</h1>
        <p>{message}</p>
        
        <div class='details'>
            <div class='details-row'>
                <div class='details-label'>Request ID:</div>
                <div class='details-value'><strong>{request.DisplayRequestID}</strong></div>
            </div>
            <div class='details-row'>
                <div class='details-label'>Quantity:</div>
                <div class='details-value'>{request.QuantityRequested} units</div>
            </div>
            <div class='details-row'>
                <div class='details-label'>Status:</div>
                <div class='details-value'>
                    <span class='status-badge'>{request.RequestStatus}</span>
                </div>
            </div>
            <div class='details-row'>
                <div class='details-label'>Processed:</div>
                <div class='details-value'>{DateTime.Now:MMM dd, yyyy HH:mm}</div>
            </div>
        </div>

        <p style='font-size: 14px; color: #999; margin-top: 30px;'>
            You can close this window. The inventory system has been updated automatically.
        </p>
    </div>
</body>
</html>";

            context.Response.Write(html);
        }

        private void ShowInfoPage(HttpContext context, string title, string message, StockRequest request)
        {
            string html = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width, initial-scale=1.0' />
    <title>{title}</title>
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
        .info-icon {{
            width: 80px;
            height: 80px;
            background: #17a2b8;
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
        }}
        .status-badge {{
            display: inline-block;
            padding: 6px 16px;
            border-radius: 20px;
            font-weight: 600;
            font-size: 14px;
            background: #17a2b8;
            color: white;
            margin-top: 15px;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='info-icon'>?</div>
        <h1>{title}</h1>
        <p>{message}</p>
        <div class='status-badge'>Current Status: {request.RequestStatus}</div>
        <p style='font-size: 14px; color: #999; margin-top: 30px;'>
            Request ID: {request.DisplayRequestID}
        </p>
    </div>
</body>
</html>";

            context.Response.Write(html);
        }

        private void ShowErrorPage(HttpContext context, string title, string message)
        {
            string html = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width, initial-scale=1.0' />
    <title>{title}</title>
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
        .error-icon {{
            width: 80px;
            height: 80px;
            background: #dc3545;
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
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='error-icon'>?</div>
        <h1>{title}</h1>
        <p>{message}</p>
        <p style='font-size: 14px; color: #999; margin-top: 30px;'>
            If you believe this is an error, please contact the inventory management team.
        </p>
    </div>
</body>
</html>";

            context.Response.Write(html);
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
