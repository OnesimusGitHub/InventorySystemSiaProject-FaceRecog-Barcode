using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Net;
using System.Net.Mail;

namespace InventorySystemSiaProject.Services
{
    public static class SendEmaikService
    {
        private static readonly string FromEmail = "chashtagsendemail123@gmail.com";
        private static readonly string FromPassword = "pimfpxahhsnfhoga"; // Gmail app password
        private static readonly string FromName = "Inventory System";

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
        /// Sends a stock request email to the supplier with detailed order information
        /// </summary>
        public static void SendStockRequestEmail(
            string supplierEmail,
            string supplierName,
            string productName,
            int currentStock,
            int minimumStock,
            int requestedQuantity,
            string additionalNotes = "")
        {
            try
            {
                var fromAddress = new MailAddress(FromEmail, FromName);
                var toAddress = new MailAddress(supplierEmail);

                string subject = $"📦 Stock Request: {productName}";
                
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
                                {(!string.IsNullOrWhiteSpace(additionalNotes) ? $@"
                                <div class='detail-row'>
                                    <div class='detail-label'>Additional Notes:</div>
                                    <div class='detail-value'>{additionalNotes}</div>
                                </div>" : "")}
                            </div>
                            
                            <p>Please confirm the availability and estimated delivery time at your earliest convenience.</p>
                            <p>Thank you for your continued partnership.</p>
                            
                            <p>Best regards,<br><strong>Inventory Management Team</strong></p>
                        </div>
                        <div class='footer'>
                            <p>This is an automated email from the Inventory Management System.</p>
                            <p>Please do not reply directly to this email.</p>
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
    }
}
