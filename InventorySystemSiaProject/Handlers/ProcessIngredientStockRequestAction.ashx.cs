using System;
using System.Web;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services; // ⬅ add this

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Handles supplier approval/rejection actions from email links
    /// </summary>
    public class ProcessIngredientStockRequestAction : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("=== ProcessIngredientStockRequestAction handler called ===");
                
                // Get parameters from URL
                string requestId = context.Request.QueryString["requestId"];
                string action = context.Request.QueryString["action"]?.ToLower();
                string token = context.Request.QueryString["token"];
                
                System.Diagnostics.Debug.WriteLine($"RequestId: {requestId}, Action: {action}, Token: {token}");

                // Validate parameters
                if (string.IsNullOrWhiteSpace(requestId))
                {
                    ShowErrorPage(context, "Invalid Request", "Request ID is missing.");
                    return;
                }

                if (string.IsNullOrWhiteSpace(action) || 
                    (action != "approve" && action != "reject" && action != "outfordelivery"))
                {
                    ShowErrorPage(context, "Invalid Action", "Action must be 'approve', 'reject' or 'outfordelivery'.");
                    return;
                }

                if (string.IsNullOrWhiteSpace(token))
                {
                    ShowErrorPage(context, "Invalid Token", "Security token is missing.");
                    return;
                }

                // Get the stock request from database
                var collection = DatabaseHelper.GetIngredientStockRequestsCollection();
                IngredientStockRequest request = null;

                try
                {
                    ObjectId objectId;
                    if (ObjectId.TryParse(requestId, out objectId))
                    {
                        var filter = new BsonDocument("_id", objectId);
                        request = collection.Find(filter).FirstOrDefault();
                    }
                    
                    if (request == null)
                    {
                        var filter = new BsonDocument("_id", requestId);
                        request = collection.Find(filter).FirstOrDefault();
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error fetching request: {ex.Message}");
                    ShowErrorPage(context, "Database Error", "Failed to retrieve the stock request.");
                    return;
                }

                if (request == null)
                {
                    ShowErrorPage(context, "Request Not Found", "The stock request could not be found in our system.");
                    return;
                }

                // Verify token
                string expectedToken = GenerateSecureToken(request.RequestID, request.RequestDate);
                if (token != expectedToken)
                {
                    System.Diagnostics.Debug.WriteLine($"Token mismatch. Expected: {expectedToken}, Got: {token}");
                    ShowErrorPage(context, "Invalid Security Token", "The security token is invalid or has expired. Please contact us directly.");
                    return;
                }





                // Allow supplier to act when status is Pending, Approved, Approved by Admin, or Approved by Supplier
                if (request.RequestStatus != "Pending" &&
                    request.RequestStatus != "Approved" &&
                    request.RequestStatus != "Approved by Admin" &&
                    request.RequestStatus != "Approved by Supplier")
                {
                    ShowInfoPage(context, "Already Processed",
                        $"This request has already been {request.RequestStatus.ToLower()}.",
                        request.RequestStatus);
                    return;
                }






                // Process the action
                string newStatus = "";
                string actionText = "";
                
                if (action == "approve")
                {
                    request.RequestStatus = "Approved by Supplier";
                    newStatus = "Approved by Supplier";
                    actionText = "approved";
                }
                else if (action == "reject")
                {
                    request.RequestStatus = "Rejected by Supplier";
                    newStatus = "Rejected by Supplier";
                    actionText = "rejected";
                    request.RejectionReason = "Rejected by supplier via email";
                }
                else if (action == "outfordelivery")
                {
                    request.RequestStatus = "Out for Delivery";
                    newStatus = "Out for Delivery";
                    actionText = "marked as out for delivery";
                    request.ActualDeliveryDate = null; // still on the way
                }

                request.StatusUpdatedDate = DateTime.UtcNow;
                request.UpdatedAt = DateTime.UtcNow;
                request.ProcessedBy = "Supplier";

                // Update in database
                try
                {
                    ObjectId updateObjId;
                    FilterDefinition<IngredientStockRequest> updateFilter;
                    
                    if (ObjectId.TryParse(request.RequestID, out updateObjId))
                    {
                        updateFilter = Builders<IngredientStockRequest>.Filter.Eq("_id", updateObjId);
                    }
                    else
                    {
                        updateFilter = Builders<IngredientStockRequest>.Filter.Eq("_id", request.RequestID);
                    }

                    var update = Builders<IngredientStockRequest>.Update
                        .Set(r => r.RequestStatus, request.RequestStatus)
                        .Set(r => r.StatusUpdatedDate, request.StatusUpdatedDate)
                        .Set(r => r.UpdatedAt, request.UpdatedAt)
                        .Set(r => r.ProcessedBy, request.ProcessedBy);

                    if (action == "reject")
                    {
                        update = update.Set(r => r.RejectionReason, request.RejectionReason);
                    }

                    var result = collection.UpdateOne(updateFilter, update);

                    if (result.ModifiedCount > 0)
                    {
                        System.Diagnostics.Debug.WriteLine($"✔ Request {actionText} successfully");
                        
                        // OPTIONAL: send confirmation email to supplier
                        try
                        {
                            SendSupplierConfirmationEmail(request, actionText);
                        }
                        catch (Exception ex)
                        {
                            // Do not block the flow if email fails
                            System.Diagnostics.Debug.WriteLine($"❌ Failed to send supplier confirmation email: {ex.Message}");
                        }

                        // Log activity (if you re‑enable ActivityLog elsewhere)
                        System.Diagnostics.Debug.WriteLine(
                            $"ℹ Activity: Ingredient Stock Request {actionText.ToUpper()} - Request ID: {request.DisplayRequestID} - {newStatus}");
                        
                        ShowSuccessPage(context, actionText, newStatus, request);
                    }
                    else
                    {
                        ShowErrorPage(context, "Update Failed", "Failed to update the request status in the database.");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error updating request: {ex.Message}");
                    ShowErrorPage(context, "Database Error", "Failed to update the stock request.");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"✖ Fatal error: {ex.Message}");
                ShowErrorPage(context, "System Error", "An unexpected error occurred. Please try again or contact us directly.");
            }
        }

        // NEW: send confirmation email to supplier after approve/reject
        private void SendSupplierConfirmationEmail(IngredientStockRequest request, string action)
        {
            try
            {
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                Supplier supplier = null;

                if (!string.IsNullOrWhiteSpace(request.SupplierID))
                {
                    ObjectId supId;
                    FilterDefinition<Supplier> supFilter;

                    if (ObjectId.TryParse(request.SupplierID, out supId))
                    {
                        supFilter = Builders<Supplier>.Filter.Eq("_id", supId);
                    }
                    else
                    {
                        supFilter = Builders<Supplier>.Filter.Eq("_id", request.SupplierID);
                    }

                    supplier = suppliersCollection.Find(supFilter).FirstOrDefault();
                }

                if (supplier == null || string.IsNullOrWhiteSpace(supplier.SupEmail))
                {
                    System.Diagnostics.Debug.WriteLine("No supplier email found for confirmation.");
                    return;
                }

                var statusText = action == "approve" ? "APPROVED" :
                                 action == "reject" ? "REJECTED" :
                                 request.RequestStatus.ToUpperInvariant();

                // Build Out-for-Delivery link (same handler, new action)
                // Build Out-for-Delivery link (same handler, new action)
                string outForDeliveryButtonHtml = "";
                if (request.RequestStatus == "Approved by Supplier")
                {
                    // Generate the same secure token used in the first email
                    string token = GenerateSecureToken(request.RequestID, request.RequestDate);

                    // Base URL from current request (https://domain/app)
                    var httpContext = HttpContext.Current;
                    string baseUrl = string.Empty;
                    if (httpContext != null)
                    {
                        var req = httpContext.Request;
                        baseUrl = req.Url.Scheme + "://" + req.Url.Authority + req.ApplicationPath.TrimEnd('/');
                    }

                    string outForDeliveryUrl =
                        $"{baseUrl}/Handlers/ProcessIngredientStockRequestAction.ashx" +
                        $"?requestId={request.RequestID}&action=outfordelivery&token={token}";

                    outForDeliveryButtonHtml = $@"
        <p>You can also let us know when this order is on the way:</p>
        <div style='text-align: left; margin: 20px 0;'>
            <a href='{outForDeliveryUrl}'
               style='display: inline-block; padding: 10px 28px;
                      background: #17a2b8; color: white; text-decoration: none;
                      border-radius: 4px; font-weight: bold;'>
                🚚 Mark as OUT FOR DELIVERY
            </a>
        </div>";
                }

                string subject = $"Confirmation: Ingredient Request {statusText} - {request.DisplayRequestID}";
                string body = $@"
            <html>
            <body style='font-family: Arial, sans-serif;'>
                <p>Dear {supplier.SupName},</p>
                <p>This is a confirmation that you have <strong>{action}</strong> the ingredient stock request:</p>
                <ul>
                    <li><strong>Request ID:</strong> {request.DisplayRequestID}</li>
                    <li><strong>Ingredient:</strong> {request.IngredientName}</li>
                    <li><strong>Quantity:</strong> {request.QuantityRequested:N2} {request.Unit}</li>
                    <li><strong>Status:</strong> {request.RequestStatus}</li>
                    {(string.IsNullOrWhiteSpace(request.PackageId) ? "" : $"<li><strong>Package ID:</strong> {request.PackageId}</li>")}
                    <li><strong>Updated On:</strong> {DateTime.UtcNow:dddd, MMMM dd, yyyy HH:mm} (UTC)</li>
                </ul>
                {outForDeliveryButtonHtml}
                <p>If this action was not performed by you, please contact us immediately.</p>
                <p>Best regards,<br/><strong>Inventory Management Team</strong></p>
            </body>
            </html>";

                var fromAddress = new System.Net.Mail.MailAddress("chashtagsendemail123@gmail.com", "Inventory System");
                var toAddress = new System.Net.Mail.MailAddress(supplier.SupEmail);

                var smtp = new System.Net.Mail.SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = System.Net.Mail.SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new System.Net.NetworkCredential(fromAddress.Address, "pimfpxahhsnfhoga")
                };

                using (var message = new System.Net.Mail.MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                })
                {
                    smtp.Send(message);
                    System.Diagnostics.Debug.WriteLine($"✅ Supplier confirmation email sent to {supplier.SupEmail} for {request.DisplayRequestID}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error sending supplier confirmation email: {ex.Message}");
            }
        }

        /// <summary>
        /// Generates a secure token matching the email service
        /// </summary>
        private string GenerateSecureToken(string requestId, DateTime requestDate)
        {
            try
            {
                string input = $"{requestId}_{requestDate:yyyyMMddHHmmss}_SecretKey123";
                using (var sha256 = System.Security.Cryptography.SHA256.Create())
                {
                    byte[] bytes = System.Text.Encoding.UTF8.GetBytes(input);
                    byte[] hash = sha256.ComputeHash(bytes);
                    return Convert.ToBase64String(hash).Replace("+", "-").Replace("/", "_").Replace("=", "");
                }
            }
            catch
            {
                return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{requestId}_{requestDate.Ticks}"));
            }
        }

        private void ShowSuccessPage(HttpContext context, string action, string status, IngredientStockRequest request)
        {
            context.Response.ContentType = "text/html";

            string iconColor = action == "approved" ? "#28a745" : "#dc3545";
            string icon = action == "approved" ? "?" : "?";
            string actionCapitalized = char.ToUpper(action[0]) + action.Substring(1);

            string html = $@"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Request {actionCapitalized}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{ 
            background: white; 
            border-radius: 12px; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 600px; 
            width: 100%;
            overflow: hidden;
        }}
        .header {{ 
            background: {iconColor}; 
            color: white; 
            padding: 30px; 
            text-align: center; 
        }}
        .header .icon {{ 
            font-size: 72px; 
            margin-bottom: 10px;
            animation: scaleIn 0.5s ease-out;
        }}
        .header h1 {{ 
            font-size: 28px; 
            margin: 10px 0; 
        }}
        .content {{ 
            padding: 30px; 
        }}
        .info-box {{ 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin: 20px 0;
            border-left: 4px solid {iconColor};
        }}
        .info-row {{ 
            display: flex; 
            padding: 8px 0; 
            border-bottom: 1px solid #e9ecef; 
        }}
        .info-row:last-child {{ 
            border-bottom: none; 
        }}
        .info-label {{ 
            font-weight: bold; 
            width: 180px; 
            color: #495057; 
        }}
        .info-value {{ 
            flex: 1; 
            color: #212529; 
        }}
        .message {{ 
            text-align: center; 
            color: #6c757d; 
            margin-top: 20px;
            font-size: 14px;
        }}
        .button {{ 
            display: inline-block; 
            padding: 12px 30px; 
            background: {iconColor}; 
            color: white; 
            text-decoration: none; 
            border-radius: 6px; 
            margin: 20px 0;
            font-weight: bold;
        }}
        .button:hover {{ 
            opacity: 0.9; 
        }}
        @keyframes scaleIn {{
            from {{ transform: scale(0); opacity: 0; }}
            to {{ transform: scale(1); opacity: 1; }}
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <div class='icon'>{icon}</div>
            <h1>Request {actionCapitalized}!</h1>
            <p>Thank you for your prompt response</p>
        </div>
        <div class='content'>
            <p style='font-size: 18px; color: #212529; margin-bottom: 15px;'>
                You have successfully <strong>{action}</strong> the following stock request:
            </p>
            
            <div class='info-box'>
                <div class='info-row'>
                    <div class='info-label'>Request ID:</div>
                    <div class='info-value'><strong>{request.DisplayRequestID}</strong></div>
                </div>
                <!-- ✅ NEW: Package ID row -->
                <div class='info-row'>
                    <div class='info-label'>Package ID:</div>
                    <div class='info-value'><strong>{(string.IsNullOrWhiteSpace(request.PackageId) ? "N/A" : request.PackageId)}</strong></div>
                </div>
                <div class='info-row'>
                    <div class='info-label'>New Status:</div>
                    <div class='info-value'><strong style='color:{iconColor};'>{status}</strong></div>
                </div>
                <div class='info-row'>
                    <div class='info-label'>Quantity Requested:</div>
                    <div class='info-value'>{request.QuantityRequested:N2} {request.Unit}</div>
                </div>
                <div class='info-row'>
                    <div class='info-label'>Updated On:</div>
                    <div class='info-value'>{DateTime.Now:dddd, MMMM dd, yyyy HH:mm}</div>
                </div>
            </div>

            <div style='background: #e8f5e9; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745; margin: 20px 0;'>
                <p style='margin: 0; color: #155724; font-size: 14px;'>
                    <strong>? Confirmation:</strong> Our team has been notified of your decision. 
                    {(action == "approved" ? "We will proceed with the order accordingly." : "The request has been cancelled.")}
                </p>
            </div>

            <p class='message'>
                You can now safely close this window. If you have any questions, please contact our team directly.
            </p>
        </div>
    </div>
</body>
</html>";

            context.Response.Write(html);
            context.Response.Flush();
            context.ApplicationInstance.CompleteRequest();
        }
        private void ShowErrorPage(HttpContext context, string title, string message)
        {
            context.Response.ContentType = "text/html";
            
            string html = $@"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>{title}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{ 
            background: white; 
            border-radius: 12px; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px; 
            width: 100%;
            overflow: hidden;
        }}
        .header {{ 
            background: #dc3545; 
            color: white; 
            padding: 30px; 
            text-align: center; 
        }}
        .header .icon {{ 
            font-size: 72px; 
            margin-bottom: 10px; 
        }}
        .content {{ 
            padding: 30px; 
            text-align: center;
        }}
        .message {{ 
            color: #6c757d; 
            margin: 20px 0;
            line-height: 1.6;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <div class='icon'>?</div>
            <h1>{title}</h1>
        </div>
        <div class='content'>
            <p class='message' style='font-size: 16px; color: #212529;'>{message}</p>
            <p class='message' style='font-size: 14px;'>
                If you believe this is an error, please contact our support team.
            </p>
        </div>
    </div>
</body>
</html>";

            context.Response.Write(html);
            context.Response.Flush();
            context.ApplicationInstance.CompleteRequest();
        }

        private void ShowInfoPage(HttpContext context, string title, string message, string status)
        {
            context.Response.ContentType = "text/html";
            
            string html = $@"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>{title}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{ 
            background: white; 
            border-radius: 12px; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px; 
            width: 100%;
            overflow: hidden;
        }}
        .header {{ 
            background: #17a2b8; 
            color: white; 
            padding: 30px; 
            text-align: center; 
        }}
        .header .icon {{ 
            font-size: 72px; 
            margin-bottom: 10px; 
        }}
        .content {{ 
            padding: 30px; 
            text-align: center;
        }}
        .message {{ 
            color: #6c757d; 
            margin: 20px 0;
            line-height: 1.6;
        }}
        .status-badge {{
            display: inline-block;
            padding: 8px 20px;
            background: #e8f5e9;
            color: #155724;
            border-radius: 20px;
            font-weight: bold;
            margin: 15px 0;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <div class='icon'>?</div>
            <h1>{title}</h1>
        </div>
        <div class='content'>
            <p class='message' style='font-size: 16px; color: #212529;'>{message}</p>
            <div class='status-badge'>Status: {status}</div>
            <p class='message' style='font-size: 14px;'>
                You can safely close this window.
            </p>
        </div>
    </div>
</body>
</html>";

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
