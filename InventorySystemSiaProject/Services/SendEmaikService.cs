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

        // Compatibility wrappers to match existing call sites (fixes CS0117 errors)
        // These provide the historically expected method names and signatures and delegate to SendStockRequestEmail.

        /// <summary>
        /// Backwards-compatible wrapper used by Equipment flows.
        /// Existing code calls SendEquipmentStockRequestEmail(..., packageId).
        /// This method appends packageId to additional notes (if provided) then calls SendStockRequestEmail.
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
            // If packageId is provided append it to the additional notes so it appears in the email body.
            var notes = additionalNotes ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(packageId))
            {
                if (!string.IsNullOrWhiteSpace(notes))
                    notes = notes + Environment.NewLine + $"Package ID: {packageId}";
                else
                    notes = $"Package ID: {packageId}";
            }

            SendStockRequestEmail(
                supplierEmail: supplierEmail,
                supplierName: supplierName,
                productName: equipmentName,
                currentStock: currentQuantity,
                minimumStock: minimumQuantity,
                requestedQuantity: requestedQuantity,
                additionalNotes: notes,
                expectedDeliveryDate: expectedDeliveryDate,
                requestId: equipmentRequestId,
                requestDate: requestDate
            );
        }

        /// <summary>
        /// Backwards-compatible wrapper used by Ingredient flows.
        /// Delegates to SendStockRequestEmail.
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
            // Build notes including unit and package id (if provided)
            var notes = additionalNotes ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(unit))
            {
                if (!string.IsNullOrWhiteSpace(notes)) notes += Environment.NewLine;
                notes += $"Unit: {unit}";
            }
            if (!string.IsNullOrWhiteSpace(packageId))
            {
                if (!string.IsNullOrWhiteSpace(notes)) notes += Environment.NewLine;
                notes += $"Package ID: {packageId}";
            }

            // SendStockRequestEmail expects ints for stock/quantities — convert safely
            int curr = (int)Math.Round(currentStock);
            int min = (int)Math.Round(minimumStock);
            int req = (int)Math.Round(requestedQuantity);

            SendStockRequestEmail(
                supplierEmail: supplierEmail,
                supplierName: supplierName,
                productName: ingredientName,
                currentStock: curr,
                minimumStock: min,
                requestedQuantity: req,
                additionalNotes: notes,
                expectedDeliveryDate: expectedDeliveryDate,
                requestId: requestId,
                requestDate: requestDate
            );
        }

        /// <summary>
        /// Sends a confirmation email to the supplier after they approve an equipment stock request.
        /// </summary>
        public static void SendEquipmentApprovalConfirmationEmail(
            string supplierEmail,
            string supplierName,
            string equipmentName,
            string displayRequestId,
            int quantityRequested,
            string status,
            string packageId,
            DateTime updatedOn,
            string requestId,
            string outForDeliveryUrl = null)
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(supplierEmail);

                string subject = $"Confirmation: Equipment Request APPROVED BY SUPPLIER - {displayRequestId}";

                string packageHtml = string.IsNullOrWhiteSpace(packageId)
                    ? ""
                    : $@"<div class='detail-row'>
                    <div class='detail-label'>Package ID:</div>
                    <div class='detail-value'>{HttpUtility.HtmlEncode(packageId)}</div>
                 </div>";

                string outForDeliveryButton = "";
                if (!string.IsNullOrWhiteSpace(outForDeliveryUrl))
                {
                    outForDeliveryButton = $@"
                <div style='text-align:center; margin-top:20px;'>
                    <a href='{outForDeliveryUrl}'
                        style='display:inline-block; padding:12px 24px; background:#17a2b8; color:#fff; border-radius:6px; text-decoration:none; font-weight:bold;'>
                        🚚 Mark as OUT FOR DELIVERY
                    </a>
                </div>";
                }

                string body = $@"
            <html>
              <head>
                <style>body {{ font-family: Arial, sans-serif; color:#333; line-height:1.5; }} .header {{ background:#f5f7fb; padding:18px; text-align:left; border-bottom:1px solid #eee; }} .content {{ padding:18px; }} .details {{ background:#fff; padding:14px; border-radius:6px; border-left:4px solid #28a745; }} .detail-row {{ display:flex; padding:8px 0; border-bottom:1px solid #f0f0f0; }} .detail-label {{ width:160px; font-weight:700; color:#555; }} .detail-value {{ flex:1; color:#222; }} .footer {{ margin-top:18px; color:#666; font-size:13px; }}</style>
              </head>
              <body>
                <div class='header'>
                  <h2 style='margin:0;'>Confirmation: Equipment Request APPROVED</h2>
                </div>
                <div class='content'>
                  <p>Dear {HttpUtility.HtmlEncode(supplierName)},</p>
                  <p>This is a confirmation that you have <strong>approved</strong> the equipment stock request:</p>

                  <div class='details'>
                    <div class='detail-row'>
                      <div class='detail-label'>Request ID:</div>
                      <div class='detail-value'><strong>{HttpUtility.HtmlEncode(displayRequestId)}</strong></div>
                    </div>
                    <div class='detail-row'>
                      <div class='detail-label'>Equipment:</div>
                      <div class='detail-value'>{HttpUtility.HtmlEncode(equipmentName)}</div>
                    </div>
                    <div class='detail-row'>
                      <div class='detail-label'>Quantity:</div>
                      <div class='detail-value'>{quantityRequested}</div>
                    </div>
                    <div class='detail-row'>
                      <div class='detail-label'>Status:</div>
                      <div class='detail-value'>{HttpUtility.HtmlEncode(status)}</div>
                    </div>
                    {packageHtml}
                    <div class='detail-row'>
                      <div class='detail-label'>Updated On:</div>
                      <div class='detail-value'>{updatedOn.ToString("dddd, MMMM dd, yyyy HH:mm (UTC)")}</div>
                    </div>
                  </div>

                  <p>You can also let us know when this order is on the way:</p>

                  {outForDeliveryButton}

                  <p class='footer'>
                    If this action was not performed by you, please contact us immediately.<br/><br/>
                    Best regards,<br/>
                    <strong>Inventory Management Team</strong>
                  </p>
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
                    System.Diagnostics.Debug.WriteLine($"✅ Equipment approval confirmation sent to {supplierEmail} for request {displayRequestId}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Failed to send equipment approval confirmation: {ex.Message}");
            }
        }

        /// <summary>
        /// Sends a bulk HTML email to multiple recipients. Returns list of addresses that failed.
        /// </summary>
        public static List<string> SendBulkEmail(IEnumerable<string> toEmails, string subject, string bodyHtml)
        {
            var failures = new List<string>();
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);

                using (var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, FromPassword)
                })
                {
                    var recipients = toEmails?.Where(e => !string.IsNullOrWhiteSpace(e)).Select(e => e.Trim()).Distinct().ToList() ?? new List<string>();
                    foreach (var email in recipients)
                    {
                        try
                        {
                            var toAddress = new MailAddress(email);
                            using (var message = new MailMessage(fromAddress, toAddress)
                            {
                                Subject = subject,
                                Body = bodyHtml,
                                IsBodyHtml = true
                            })
                            {
                                smtp.Send(message);
                            }
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine($"Failed to send email to {email}: {ex.Message}");
                            failures.Add(email);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"SendBulkEmail failed overall: {ex.Message}");
            }
            return failures;
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

        /// <summary>
        /// Sends user credentials email when a new user is added to the system
        /// </summary>
        public static void SendUserCredentialsEmail(
            string userEmail,
            string userName,
            string password,
            string role)
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(userEmail);

                string subject = "👤 Your Inventory System Account Created";

                string body = $@"
                    <html>
                    <head>
                        <style>
                            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                            .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
                            .content {{ padding: 20px; background: #f9f9f9; }}
                            .credentials {{ background: white; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #667eea; }}
                            .credential-row {{ display: flex; padding: 12px 0; border-bottom: 1px solid #eee; }}
                            .credential-label {{ font-weight: bold; width: 150px; color: #555; }}
                            .credential-value {{ flex: 1; color: #333; font-family: 'Courier New', monospace; }}
                            .role-badge {{ display: inline-block; background: #28a745; color: white; padding: 6px 12px; border-radius: 20px; font-weight: bold; font-size: 14px; }}
                            .warning {{ background: #fff3cd; padding: 15px; border-radius: 8px; border-left: 4px solid #ffc107; margin: 20px 0; }}
                            .footer {{ text-align: center; padding: 20px; color: #888; font-size: 12px; }}
                        </style>
                    </head>
                    <body>
                        <div class='header'>
                            <h1>Welcome to Inventory System!</h1>
                        </div>
                        <div class='content'>
                            <p>Dear {HttpUtility.HtmlEncode(userName)},</p>
                            <p>Your account has been successfully created in the Inventory Management System. Below are your login credentials:</p>
                            
                            <div class='credentials'>
                                <div class='credential-row'>
                                    <div class='credential-label'>Email:</div>
                                    <div class='credential-value'>{HttpUtility.HtmlEncode(userEmail)}</div>
                                </div>
                                <div class='credential-row'>
                                    <div class='credential-label'>Password:</div>
                                    <div class='credential-value'>{HttpUtility.HtmlEncode(password)}</div>
                                </div>
                                <div class='credential-row'>
                                    <div class='credential-label'>Role:</div>
                                    <div style='flex: 1;'><span class='role-badge'>{HttpUtility.HtmlEncode(role)}</span></div>
                                </div>
                            </div>

                            <div class='warning'>
                                <p style='margin: 0;'><strong>⚠️ Important Security Notice:</strong></p>
                                <ul style='margin: 8px 0; padding-left: 20px;'>
                                    <li>Please keep your password confidential and do not share it with anyone.</li>
                                    <li>We recommend changing your password on first login.</li>
                                    <li>Do not reply to this email with sensitive information.</li>
                                </ul>
                            </div>

                            <p>To access the system, please visit the login page and use your email and password.</p>
                            <p>If you did not request this account or have any questions, please contact your administrator immediately.</p>
                            
                            <p>Best regards,<br><strong>Inventory Management Team</strong></p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated email from the Inventory Management System. Please do not reply to this email.</p>
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
                    System.Diagnostics.Debug.WriteLine($"✅ User credentials email sent to {userEmail} for user {userName}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Failed to send user credentials email: {ex.Message}");
                throw;
            }
        }
    }
}