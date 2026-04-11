using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Net;
using System.Net.Mail;
using System.Configuration;

namespace InventorySystemSiaProject.Services
{
    public static class SendEmaikService
    {
        private static readonly string FromEmail = "chashtagsendemail123@gmail.com";
        private static readonly string FromPassword = "pimfpxahhsnfhoga"; // Gmail app password
        private static readonly string FromName = "Inventory System";

        // Base URL used in email links (ngrok / production / localhost)
        private static readonly string _baseUrl =
            (ConfigurationManager.AppSettings["AppBaseUrl"] ?? "http://localhost:57993").TrimEnd('/');

        public static void SendLowStockEmail(string toEmail, string productName, int stock, int minStock)
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(toEmail);

                string subject = $"⚠ Low Stock Alert: {productName}";
                string body = $"The product '{productName}' has only {stock} left (Minimum Stock: {minStock}).";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, FromPassword)
                };

                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body
                })
                {
                    smtp.Send(message);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Email send failed: " + ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Sends a stock request email to the supplier with detailed order information and approval links
        /// (PRODUCT stock, uses ProcessStockRequestAction.ashx)
        /// </summary>
        /// 

        public static void SendStockRequestEmail(
            string supplierEmail,
            string supplierName,
            string productName,
            int currentStock,
            int minimumStock,
            int requestedQuantity,
            string additionalNotes = "",
            DateTime? expectedDeliveryDate = null,
            string requestId = null,
            DateTime? requestDate = null)
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(supplierEmail);

                string subject = $"📦 Stock Request: {productName}";

                // Format expected delivery date
                string expectedDeliveryHtml = "";
                if (expectedDeliveryDate.HasValue)
                {
                    expectedDeliveryHtml = $@"
                                <div class='detail-row'>
                                    <div class='detail-label'>Expected Delivery:</div>
                                    <div class='detail-value' style='color: #28a745; font-weight: bold;'>{expectedDeliveryDate.Value:dddd, MMMM dd, yyyy}</div>
                                </div>";
                }

                // Generate approval/rejection links if requestId is provided
                string actionButtonsHtml = "";
                if (!string.IsNullOrEmpty(requestId) && requestDate.HasValue)
                {
                    // Generate secure token using simple hash
                    string token = GenerateSecureToken(requestId, requestDate.Value);

                    // Product stock handler
                    var approveUrl = $"{_baseUrl}/Handlers/ProcessStockRequestAction.ashx?requestId={requestId}&action=approve&token={token}";
                    var rejectUrl = $"{_baseUrl}/Handlers/ProcessStockRequestAction.ashx?requestId={requestId}&action=reject&token={token}";

                    actionButtonsHtml = $@"
                            <div style='text-align: center; margin: 30px 0;'>
                                <p style='color: #333; font-size: 16px; margin-bottom: 20px;'>
                                    <strong>Quick Response:</strong> Click a button below to respond instantly
                                </p>
                                <a href='{approveUrl}' style='display: inline-block; margin: 10px; padding: 15px 40px; background: #28a745; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 8px rgba(40,167,69,0.3);'>
                                    ✓ APPROVE REQUEST
                                </a>
                                <a href='{rejectUrl}' style='display: inline-block; margin: 10px; padding: 15px 40px; background: #dc3545; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 8px rgba(220,53,69,0.3);'>
                                    ✕ REJECT REQUEST
                                </a>
                            </div>
                            <div style='background: #e8f5e9; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745; margin: 20px 0;'>
                                <p style='margin: 0; color: #155724; font-size: 14px;'>
                                    <strong>💡 Tip:</strong> Clicking a button will instantly update the request status in our system. You'll see a confirmation page.
                                </p>
                            </div>";
                }

                // Create HTML email body
                string body = $@"
                    <html>
                    <head>
                        <style>
                            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                            .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
                            .content {{ padding: 20px; background: #f9f9f9; }}
                            .details {{ background: white; padding: 15px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #667eea; }}
                            .detail-row {{ display: flex; padding: 8px 0; border-bottom: 1px solid #eee; }}
                            .detail-label {{ font-weight: bold; width: 180px; color: #555; }}
                            .detail-value {{ flex: 1; color: #333; }}
                            .urgent {{ color: #dc3545; font-weight: bold; }}
                            .footer {{ text-align: center; padding: 20px; color: #888; font-size: 12px; }}
                        </style>
                    </head>
                    <body>
                        <div class='header'>
                            <h1>🏢 Stock Replenishment Request</h1>
                        </div>
                        <div class='content'>
                            <p>Dear {supplierName},</p>
                            <p>We would like to request the following product for stock replenishment:</p>
                            
                            <div class='details'>
                                <div class='detail-row'>
                                    <div class='detail-label'>Product Name:</div>
                                    <div class='detail-value'><strong>{productName}</strong></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Current Stock:</div>
                                    <div class='detail-value'><span class='urgent'>{currentStock} units</span></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Minimum Stock Level:</div>
                                    <div class='detail-value'>{minimumStock} units</div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Requested Quantity:</div>
                                    <div class='detail-value'><strong>{requestedQuantity} units</strong></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Request Date:</div>
                                    <div class='detail-value'>{DateTime.Now:dddd, MMMM dd, yyyy HH:mm}</div>
                                </div>
                                {expectedDeliveryHtml}
                                {(!string.IsNullOrWhiteSpace(additionalNotes) ? $@"
                                <div class='detail-row'>
                                    <div class='detail-label'>Additional Notes:</div>
                                    <div class='detail-value'>{additionalNotes}</div>
                                </div>" : "")}
                            </div>

                            {actionButtonsHtml}
                            
                            <p>Please confirm the availability{(expectedDeliveryDate.HasValue ? " and ensure delivery by the specified date" : " and estimated delivery time")} at your earliest convenience.</p>
                            <p>Thank you for your continued partnership.</p>
                            
                            <p>Best regards,<br><strong>Inventory Management Team</strong></p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated email from the Inventory Management System.</p>
                            <p>If the buttons above don't work, please contact us directly.</p>
                        </div>
                    </body>
                    </html>";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, FromPassword)
                };

                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                })
                {
                    smtp.Send(message);
                    System.Diagnostics.Debug.WriteLine($"✅ Stock request email sent to {supplierEmail} for {productName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Email send failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Sends an EQUIPMENT stock request email to the supplier, with approve/reject links
        /// pointing to ProcessEquipmentEmailAction.ashx
        /// </summary>
        public static void SendEquipmentStockRequestEmail(
            string supplierEmail,
            string supplierName,
            string equipmentName,
            int currentQuantity,
            int minimumQuantity,
            int requestedQuantity,
            string additionalNotes = "",
            DateTime? expectedDeliveryDate = null,
            string equipmentRequestId = null,
            DateTime? requestDate = null,
            string packageId = null)   
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(supplierEmail);

                string subject = $"🛠 Equipment Stock Request: {equipmentName}";

                string expectedDeliveryHtml = "";
                if (expectedDeliveryDate.HasValue)
                {
                    expectedDeliveryHtml = $@"
                                <div class='detail-row'>
                                    <div class='detail-label'>Expected Delivery:</div>
                                    <div class='detail-value' style='color: #28a745; font-weight: bold;'>{expectedDeliveryDate.Value:dddd, MMMM dd, yyyy}</div>
                                </div>";
                }

                string actionButtonsHtml = "";
                if (!string.IsNullOrEmpty(equipmentRequestId) && requestDate.HasValue)
                {
                    string token = GenerateSecureToken(equipmentRequestId, requestDate.Value);

                    var approveUrl = $"{_baseUrl}/Handlers/ProcessEquipmentEmailAction.ashx"
                                     + $"?requestId={equipmentRequestId}"
                                     + $"&action=approve"
                                     + $"&token={token}";

                    var rejectUrl = $"{_baseUrl}/Handlers/ProcessEquipmentEmailAction.ashx"
                                    + $"?requestId={equipmentRequestId}"
                                    + $"&action=reject"
                                    + $"&token={token}";

                    actionButtonsHtml = $@"
                            <div style='text-align: center; margin: 30px 0;'>
                                <p style='color: #333; font-size: 16px; margin-bottom: 20px;'>
                                    <strong>Quick Response:</strong> Click a button below to respond instantly
                                </p>
                                <a href='{approveUrl}' style='display: inline-block; margin: 10px; padding: 15px 40px; background: #28a745; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 8px rgba(40,167,69,0.3);'>
                                    ✓ APPROVE REQUEST
                                </a>
                                <a href='{rejectUrl}' style='display: inline-block; margin: 10px; padding: 15px 40px; background: #dc3545; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 8px rgba(220,53,69,0.3);'>
                                    ✕ REJECT REQUEST
                                </a>
                            </div>
                            <div style='background: #e8f5e9; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745; margin: 20px 0;'>
                                <p style='margin: 0; color: #155724; font-size: 14px;'>
                                    <strong>💡 Tip:</strong> Clicking a button will instantly update the request status in our system. You'll see a confirmation page.
                                </p>
                            </div>";
                }

                string body = $@"
                    <html>
                    <head>
                        <style>
                            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                            .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
                            .content {{ padding: 20px; background: #f9f9f9; }}
                            .details {{ background: white; padding: 15px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #667eea; }}
                            .detail-row {{ display: flex; padding: 8px 0; border-bottom: 1px solid #eee; }}
                            .detail-label {{ font-weight: bold; width: 180px; color: #555; }}
                            .detail-value {{ flex: 1; color: #333; }}
                            .urgent {{ color: #dc3545; font-weight: bold; }}
                            .footer {{ text-align: center; padding: 20px; color: #888; font-size: 12px; }}
                        </style>
                    </head>
                    <body>
                        <div class='header'>
                            <h1>🛠 Equipment Stock Replenishment Request</h1>
                        </div>
                        <div class='content'>
                            <p>Dear {supplierName},</p>
                            <p>We would like to request the following equipment for stock replenishment:</p>
                            
                            <div class='details'>
                                <div class='detail-row'>
                                    <div class='detail-label'>Equipment Name:</div>
                                    <div class='detail-value'><strong>{equipmentName}</strong></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Current Quantity:</div>
                                    <div class='detail-value'><span class='urgent'>{currentQuantity} units</span></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Minimum Quantity Level:</div>
                                    <div class='detail-value'>{minimumQuantity} units</div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Requested Quantity:</div>
                                    <div class='detail-value'><strong>{requestedQuantity} units</strong></div>
                                </div>
                                <div class='detail-row'>
    <div class='detail-label'>Request Date:</div>
    <div class='detail-value'>{DateTime.Now:dddd, MMMM dd, yyyy HH:mm}</div>
</div>
{expectedDeliveryHtml}
{(!string.IsNullOrWhiteSpace(packageId) ? $@"
<div class='detail-row'>
    <div class='detail-label'>Package ID:</div>
    <div class='detail-value'><strong>{packageId}</strong></div>
</div>" : "")}
{(!string.IsNullOrWhiteSpace(additionalNotes) ? $@"
<div class='detail-row'>
    <div class='detail-label'>Additional Notes:</div>
    <div class='detail-value'>{additionalNotes}</div>
</div>" : "")}
                            </div>

                            {actionButtonsHtml}
                            
                            <p>Please confirm the availability{(expectedDeliveryDate.HasValue ? " and ensure delivery by the specified date" : " and estimated delivery time")} at your earliest convenience.</p>
                            <p>Thank you for your continued partnership.</p>
                            
                            <p>Best regards,<br><strong>Inventory Management Team</strong></p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated email from the Inventory Management System.</p>
                            <p>If the buttons above don't work, please contact us directly.</p>
                        </div>
                    </body>
                    </html>";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, FromPassword)
                };

                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                })
                {
                    smtp.Send(message);
                    System.Diagnostics.Debug.WriteLine($"✅ Equipment stock request email sent to {supplierEmail} for {equipmentName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Equipment email send failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Sends an ingredient stock request email to the supplier with detailed order information
        /// </summary>
        public static void SendIngredientStockRequestEmail(
            string supplierEmail,
            string supplierName,
            string ingredientName,
            string unit,
            decimal currentStock,
            decimal minimumStock,
            decimal requestedQuantity,
            string additionalNotes = "",
            DateTime? expectedDeliveryDate = null,
            string requestId = null,
            DateTime? requestDate = null,
             string packageId = null)
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(supplierEmail);

                string subject = $"🧪 Ingredient Stock Request: {ingredientName}";

                // Format expected delivery date
                string expectedDeliveryHtml = "";
                if (expectedDeliveryDate.HasValue)
                {
                    expectedDeliveryHtml = $@"
                                <div class='detail-row'>
                                    <div class='detail-label'>Expected Delivery:</div>
                                    <div class='detail-value' style='color: #28a745; font-weight: bold;'>{expectedDeliveryDate.Value:dddd, MMMM dd, yyyy}</div>
                                </div>";
                }

                // Generate approval/rejection links if requestId is provided
                string actionButtonsHtml = "";
                if (!string.IsNullOrEmpty(requestId) && requestDate.HasValue)
                {
                    // Generate secure token using simple hash
                    string token = GenerateSecureToken(requestId, requestDate.Value);

                    string approveUrl = $"{_baseUrl}/Handlers/ProcessIngredientStockRequestAction.ashx?requestId={requestId}&action=approve&token={token}";
                    string rejectUrl = $"{_baseUrl}/Handlers/ProcessIngredientStockRequestAction.ashx?requestId={requestId}&action=reject&token={token}";

                    actionButtonsHtml = $@"
                            <div style='text-align: center; margin: 30px 0;'>
                                <p style='color: #333; font-size: 16px; margin-bottom: 20px;'>
                                    <strong>Quick Response:</strong> Click a button below to respond instantly
                                </p>
                                <a href='{approveUrl}' style='display: inline-block; margin: 10px; padding: 15px 40px; background: #28a745; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 8px rgba(40,167,69,0.3);'>
                                    ✓ APPROVE REQUEST
                                </a>
                                <a href='{rejectUrl}' style='display: inline-block; margin: 10px; padding: 15px 40px; background: #dc3545; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; box-shadow: 0 4px 8px rgba(220,53,69,0.3);'>
                                    ✕ REJECT REQUEST
                                </a>
                            </div>
                            <div style='background: #e8f5e9; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745; margin: 20px 0;'>
                                <p style='margin: 0; color: #155724; font-size: 14px;'>
                                    <strong>💡 Tip:</strong> Clicking a button will instantly update the request status in our system. You'll see a confirmation page.
                                </p>
                            </div>";
                }

                string body = $@"
                    <html>
                    <head>
                        <style>
                            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                            .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
                            .content {{ padding: 20px; background: #f9f9f9; }}
                            .details {{ background: white; padding: 15px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #667eea; }}
                            .detail-row {{ display: flex; padding: 8px 0; border-bottom: 1px solid #eee; }}
                            .detail-label {{ font-weight: bold; width: 180px; color: #555; }}
                            .detail-value {{ flex: 1; color: #333; }}
                            .urgent {{ color: #dc3545; font-weight: bold; }}
                            .footer {{ text-align: center; padding: 20px; color: #888; font-size: 12px; }}
                        </style>
                    </head>
                    <body>
                        <div class='header'>
                            <h1>🧪 Ingredient Stock Replenishment Request</h1>
                        </div>
                        <div class='content'>
                            <p>Dear {supplierName},</p>
                            <p>We would like to request the following ingredient for stock replenishment:</p>
                            
                            <div class='details'>
                                <div class='detail-row'>
                                    <div class='detail-label'>Ingredient Name:</div>
                                    <div class='detail-value'><strong>{ingredientName}</strong></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Unit:</div>
                                    <div class='detail-value'>{unit}</div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Current Stock:</div>
                                    <div class='detail-value'><span class='urgent'>{currentStock:N2} {unit}</span></div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Minimum Stock Level:</div>
                                    <div class='detail-value'>{minimumStock:N2} {unit}</div>
                                </div>
                                <div class='detail-row'>
                                    <div class='detail-label'>Requested Quantity:</div>
                                    <div class='detail-value'><strong>{requestedQuantity:N2} {unit}</strong></div>
                                </div>
                                
<div class='detail-row'>
    <div class='detail-label'>Request Date:</div>
    <div class='detail-value'>{DateTime.Now:dddd, MMMM dd, yyyy HH:mm}</div>
</div>
{expectedDeliveryHtml}
{(!string.IsNullOrWhiteSpace(packageId) ? $@"
<div class='detail-row'>
    <div class='detail-label'>Package ID:</div>
    <div class='detail-value'><strong>{packageId}</strong></div>
</div>" : "")}
{(!string.IsNullOrWhiteSpace(additionalNotes) ? $@"
<div class='detail-row'>
    <div class='detail-label'>Additional Notes:</div>
    <div class='detail-value'>{additionalNotes}</div>
</div>" : "")}
                            </div>

                            {actionButtonsHtml}
                            
                            <p>Please confirm the availability{(expectedDeliveryDate.HasValue ? " and ensure delivery by the specified date" : " and estimated delivery time")} at your earliest convenience.</p>
                            <p>Thank you for your continued partnership.</p>
                            
                            <p>Best regards,<br><strong>Inventory Management Team</strong></p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated email from the Inventory Management System.</p>
                            <p>{(string.IsNullOrEmpty(requestId) ? "For any questions, please contact us directly." : "You can respond instantly using the buttons above, or contact us directly.")}</p>
                        </div>
                    </body>
                    </html>";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, FromPassword)
                };

                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                })
                {
                    smtp.Send(message);
                    System.Diagnostics.Debug.WriteLine($"✅ Ingredient stock request email sent to {supplierEmail} for {ingredientName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Email send failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Generates a secure token for email approval links
        /// </summary>
        private static string GenerateSecureToken(string requestId, DateTime requestDate)
        {
            try
            {
                // Create a simple hash using the request ID and date
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
                // Fallback to simple token
                return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{requestId}_{requestDate.Ticks}"));
            }
        }
    }
}