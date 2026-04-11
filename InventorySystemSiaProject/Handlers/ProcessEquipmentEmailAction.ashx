<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ProcessEquipmentEmailAction" %>

using System;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Services;
   using InventorySystemSiaProject.Models;

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
                string action = context.Request.QueryString["action"]; // approve / reject
                string token  = context.Request.QueryString["token"];  // currently informational only

                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] RAW URL: " + context.Request.Url);
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] requestId=" + requestId);
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] action=" + action);
                System.Diagnostics.Debug.WriteLine("[EquipmentEmail] token=" + token);

                if (string.IsNullOrWhiteSpace(requestId) || string.IsNullOrWhiteSpace(action))
                {
                    WriteSimpleHtml(context, "Invalid Request", "Missing requestId or action in the email link.");
                    return;
                }


// Try to load the equipment stock request by its Mongo _id (string)


// create service instance once and reuse it
var equipmentService = new EquipmentService();

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