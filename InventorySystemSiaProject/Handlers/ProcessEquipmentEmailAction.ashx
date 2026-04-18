<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ProcessEquipmentEmailAction" %>

using System;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;
using System.Configuration;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Handles equipment stock request approval / rejection from email links.
    /// This is a simple GET-based handler designed specifically for email.
    /// </summary>
    public class ProcessEquipmentEmailAction : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            // Run async pipeline synchronously for IHttpHandler
            ProcessRequestAsync(context).GetAwaiter().GetResult();
        }

        private async Task ProcessRequestAsync(HttpContext context)
        {
            context.Response.ContentType = "text/html";

            try
            {
                string requestId = context.Request.QueryString["requestId"];
                string action = context.Request.QueryString["action"]; // approve / reject / outfordelivery
                string token  = context.Request.QueryString["token"];  // optional

                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] RAW URL: " + context.Request.Url);
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] requestId=" + requestId);
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] action=" + action);
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] token=" + token);

                if (string.IsNullOrWhiteSpace(requestId) || string.IsNullOrWhiteSpace(action))
                {
                    WriteSimpleHtml(context, "Invalid Request", "Missing requestId or action in the email link.");
                    return;
                }


                // create service instance once and reuse it
                var equipmentService = new EquipmentService();
                var supplierService = new SupplierService();

                string normalizedAction = (action ?? string.Empty).ToLowerInvariant();
                bool ok;

                if (normalizedAction == "approve")
                {
                    System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Approving request (sync) " + requestId);

                    ok = await equipmentService.ApproveBySupplierAsync(requestId).ConfigureAwait(false);


                    WriteSimpleHtml(
                        context,
                        ok ? "Request Approved" : "Approval Failed",
                        ok
                            ? "Thank you! The equipment request has been approved."
                            : "The system could not approve this request. Please contact the inventory administrator.");

                    // If approval succeeded, send a confirmation email to the supplier
                    if (ok)
                    {
                        try
                        {
                            var req = await equipmentService.GetRequestByIdAsync(requestId).ConfigureAwait(false);
                            if (req != null)
                            {
                                // resolve supplier
                                string supplierId = req.SupplierId;
                                InventorySystemSiaProject.Models.Supplier supplier = null;
                                if (!string.IsNullOrWhiteSpace(supplierId))
                                {
                                    try
                                    {
                                        supplier = await supplierService.GetSupplierByIdAsync(supplierId).ConfigureAwait(false);
                                    }
                                    catch (Exception exSup)
                                    {
                                        System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Failed to load supplier: " + exSup);
                                    }
                                }

                                // attempt to load equipment for name
                                var equipment = !string.IsNullOrWhiteSpace(req.EquipmentId)
                                    ? await equipmentService.GetEquipmentByIdAsync(req.EquipmentId).ConfigureAwait(false)
                                    : null;

                                string supplierEmail = supplier != null ? supplier.SupEmail : null;
                                string supplierName = supplier != null ? (supplier.SupName ?? "Supplier") : (req.SupplierName ?? "Supplier");
                                string equipmentName = equipment != null ? equipment.EquipmentName : (req.EquipmentName ?? "Equipment");

                                if (!string.IsNullOrWhiteSpace(supplierEmail))
                                {
                                    // Build out-for-delivery URL pointing back to this handler with action=outfordelivery
                                    string appBase = ConfigurationManager.AppSettings["AppBaseUrl"];
                                    if (string.IsNullOrWhiteSpace(appBase))
                                    {
                                        appBase = context.Request.Url.Scheme + "://" + context.Request.Url.Authority;
                                    }
                                    appBase = appBase.TrimEnd('/');

                                    string outForDeliveryUrl = appBase + "/Handlers/ProcessEquipmentEmailAction.ashx?requestId=" + HttpUtility.UrlEncode(requestId) + "&action=outfordelivery";

                                    SendEmaikService.SendEquipmentApprovalConfirmationEmail(
                                        supplierEmail: supplierEmail,
                                        supplierName: supplierName,
                                        equipmentName: equipmentName,
                                        displayRequestId: req.DisplayId,
                                        quantityRequested: req.QuantityRequested,
                                        status: req.Status,
                                        packageId: req.PackageId,
                                        updatedOn: req.UpdatedAt,
                                        requestId: requestId,
                                        outForDeliveryUrl: outForDeliveryUrl
                                    );
                                }
                                else
                                {
                                    System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Supplier email not available, skipping confirmation email");
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Failed to send approval confirmation: " + ex);
                        }
                    }
                }
                else if (normalizedAction == "reject")
                {
                    System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Rejecting request " + requestId);

                    ok = await equipmentService
                        .RejectRequestAsync(
                            requestId,
                            "Supplier",
                            "Rejected via email by supplier")
                        .ConfigureAwait(false);

                    WriteSimpleHtml(
                        context,
                        ok ? "Request Rejected" : "Rejection Failed",
                        ok
                            ? "The equipment request has been rejected."
                            : "The system could not reject this request. Please contact the inventory administrator.");
                }
                else if (normalizedAction == "outfordelivery")
                {
                    System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Marking as Out for Delivery " + requestId);

                    // Attempt to mark request as out for delivery
                    ok = await equipmentService.MarkAsOutForDeliveryAsync(requestId).ConfigureAwait(false);

                    WriteSimpleHtml(
                        context,
                        ok ? "Marked as Out for Delivery" : "Operation Failed",
                        ok
                            ? "Thank you! The request has been marked as out for delivery."
                            : "The system could not mark this request as out for delivery. Please contact the inventory administrator.");

                    if (ok)
                    {
                        try
                        {
                            // optionally notify supplier/admin or log as needed
                            System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Out for delivery processed for " + requestId);
                        }
                        catch (Exception exNotify)
                        {
                            System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Notification after out for delivery failed: " + exNotify);
                        }
                    }
                }
                else
                {
                    WriteSimpleHtml(context, "Invalid Action", "The specified action in the email link is not valid.");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] ERROR: " + ex);
                WriteSimpleHtml(context, "Error", "An error occurred while processing your request: " + ex.Message);
            }
            finally
            {
                try
                {
                    context.Response.Flush();
                    context.ApplicationInstance.CompleteRequest();
                }
                catch { }
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] Completed response.");
            }
        }

        private void WriteSimpleHtml(HttpContext ctx, string title, string message)
        {
            string safeTitle   = HttpUtility.HtmlEncode(title ?? string.Empty);
            string safeMessage = HttpUtility.HtmlEncode(message ?? string.Empty);

            string html = "<!DOCTYPE html>" +
                          "<html><head>" +
                          "<meta charset='utf-8' />" +
                          "<meta name='viewport' content='width=device-width, initial-scale=1.0' />" +
                          "<title>" + safeTitle + "</title>" +
                          "</head><body style='font-family:Arial, sans-serif; padding:40px; background:#f5f5f5;'>" +
                          "<div style='max-width:600px;margin:40px auto;background:#fff;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1);padding:30px;'>" +
                          "<h1 style='margin-top:0;font-size:24px;color:#333;'>" + safeTitle + "</h1>" +
                          "<p style='font-size:14px;color:#555;line-height:1.6;'>" + safeMessage + "</p>" +
                          "<p style='font-size:12px;color:#999;margin-top:30px;'>You can now close this window. The equipment inventory system has been updated automatically.</p>" +
                          "</div></body></html>";

            ctx.Response.Write(html);
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}