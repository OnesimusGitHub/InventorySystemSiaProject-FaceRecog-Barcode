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
        public static void SendLowStockEmail(string toEmail, string productName, int stock, int minStock)
        {
            try
            {
                var fromAddress = new MailAddress("chashtagsendemail123@gmail.com", "Inventory System");
                var toAddress = new MailAddress(toEmail);
                string fromPassword = "pimfpxahhsnfhoga"; // Gmail app password

                string subject = $"⚠ Low Stock Alert: {productName}";
                string body = $"The product '{productName}' has only {stock} left (Minimum Stock: {minStock}).";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, fromPassword)
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
            }
        }
    }
}
