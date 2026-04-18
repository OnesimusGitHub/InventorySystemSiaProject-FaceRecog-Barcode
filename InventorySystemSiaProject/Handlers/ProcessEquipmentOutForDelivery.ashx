<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.ProcessEquipmentOutForDelivery" %>

using System;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Marks an equipment stock request as "Out for Delivery" and shows a confirmation page.
    /// This handler is intentionally public (no session required) so suppliers can click the email link.
    /// </summary>
    public class ProcessEquipmentOutForDelivery : IHttpHandler
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
                if (string.IsNullOrWhiteSpace(requestId))
                {
                    WriteHtml(context, "Invalid Request", "Missing requestId.");
                    return;
                }

                var svc = new EquipmentService();

                // Load request
                var req = await svc.GetRequestByIdAsync(requestId).ConfigureAwait(false);
                if (req == null)
                {
                    WriteHtml(context, "Request Not Found", "The equipment stock request could not be found.");
                    return;
                }

                // If already out for delivery
                if (string.Equals(req.Status, "Out for Delivery", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(req.Status, "OutForDelivery", StringComparison.OrdinalIgnoreCase))
                {
                    WriteAlreadyProcessed(context, req);
                    return;
                }

                // Update status
                var ok = await svc.MarkAsOutForDeliveryAsync(requestId).ConfigureAwait(false);
                if (!ok)
                {
                    WriteHtml(context, "Update Failed", "Could not mark request as out for delivery. Please contact support.");
                    return;
                }

                // Reload request to show updated info
                req = await svc.GetRequestByIdAsync(requestId).ConfigureAwait(false);

                WriteSuccess(context, req);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ProcessEquipmentOutForDelivery] ERROR: " + ex);
                WriteHtml(context, "Error", "An error occurred: " + HttpUtility.HtmlEncode(ex.Message));
            }
            finally
            {
                try
                {
                    context.Response.Flush();
                    context.ApplicationInstance.CompleteRequest();
                }
                catch { }
            }
        }

        private void WriteSuccess(HttpContext ctx, EquipmentStockRequest req)
        {
            string title = "Request Marked as out for delivery!";
            string html = $@"<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width, initial-scale=1' />
    <title>{HttpUtility.HtmlEncode(title)}</title>
    <style>
        body {{ font-family: Arial, sans-serif; background: linear-gradient(135deg,#6a55d6 0%,#8b62d9 100%); margin:0; padding:40px; }}
        .card {{ max-width:720px; margin:40px auto; background:#fff; border-radius:12px; box-shadow:0 10px 30px rgba(0,0,0,0.15); overflow:hidden; }}
        .hero {{ background:#e74c3c; color:#fff; padding:40px; text-align:center; }}
        .hero h1 {{ margin:0; font-size:28px; }}
        .content {{ padding:28px; color:#333; }}
        .details {{ background:#f8f9fb; border-radius:6px; padding:16px; margin-top:14px; }}
        .row {{ display:flex; padding:8px 0; border-bottom:1px solid #eee; }}
        .label {{ width:160px; font-weight:700; color:#555; }}
        .value {{ flex:1; }}
        .badge {{ display:inline-block; padding:8px 14px; background:#e9f7ef; color:#2e7d32; border-radius:20px; font-weight:700; }}
        .footer {{ padding:18px; color:#666; font-size:13px; }}
    </style>
</head>
<body>
    <div class='card'>
        <div class='hero'>
            <h1>Request Marked as out for delivery!</h1>
            <p style='opacity:0.9; margin-top:8px;'>Thank you for your prompt response</p>
        </div>
        <div class='content'>
            <p>You have successfully <strong>marked as out for delivery</strong> the following stock request:</p>
            <div class='details'>
                <div class='row'><div class='label'>Request ID:</div><div class='value'><strong>{HttpUtility.HtmlEncode(req.DisplayId)}</strong></div></div>
                <div class='row'><div class='label'>Package ID:</div><div class='value'>{HttpUtility.HtmlEncode(req.PackageId ?? "N/A")}</div></div>
                <div class='row'><div class='label'>New Status:</div><div class='value'><span class='badge'>Out for Delivery</span></div></div>
                <div class='row'><div class='label'>Quantity Requested:</div><div class='value'>{req.QuantityRequested}</div></div>
                <div class='row'><div class='label'>Updated On:</div><div class='value'>{req.UpdatedAt.ToString("dddd, MMMM dd, yyyy HH:mm (UTC)")}</div></div>
            </div>

            <div style='margin-top:16px;'>
                <div style='background:#e9f8ef;border-left:6px solid #2e7d32;padding:12px;border-radius:6px;color:#2d6b3e;'>
                    <strong>? Confirmation:</strong> Our team has been notified of your decision.
                </div>
            </div>
        </div>
        <div class='footer'>
            You can now safely close this window. If you have any questions, please contact our team directly.
        </div>
    </div>
</body>
</html>";
            ctx.Response.Write(html);
        }

        private void WriteAlreadyProcessed(HttpContext ctx, EquipmentStockRequest req)
        {
            string title = "Already Processed";
            string html = $@"<!DOCTYPE html>
<html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width, initial-scale=1' /><title>{HttpUtility.HtmlEncode(title)}</title>
<style>body{{font-family:Arial, sans-serif;background:linear-gradient(135deg,#6a55d6 0%,#8b62d9 100%);margin:0;padding:60px}}.card{{max-width:520px;margin:0 auto;background:#fff;border-radius:12px;box-shadow:0 8px 24px rgba(0,0,0,0.12);overflow:hidden}}.hero{{background:#17a2b8;color:#fff;padding:34px;text-align:center}}.hero h1{{margin:0;font-size:24px}}.content{{padding:24px}}.badge{{display:inline-block;padding:8px 14px;background:#eafaf1;color:#1e7e34;border-radius:20px;font-weight:700}}</style></head>
<body><div class='card'><div class='hero'><h1>Already Processed</h1></div><div class='content'><p>This request has already been marked as out for delivery.</p><p style='margin-top:14px'>Status: <span class='badge'>Out for Delivery</span></p></div></div></body></html>";
            ctx.Response.Write(html);
        }

        private void WriteHtml(HttpContext ctx, string title, string message)
        {
            string html = "<!DOCTYPE html><html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width, initial-scale=1' /><title>"
                + HttpUtility.HtmlEncode(title) + "</title></head><body style='font-family:Arial,sans-serif;padding:40px;background:#f5f5f7;'><div style='max-width:700px;margin:20px auto;background:#fff;padding:20px;border-radius:8px;box-shadow:0 6px 18px rgba(0,0,0,0.08);'><h2>"
                + HttpUtility.HtmlEncode(title) + "</h2><p>" + HttpUtility.HtmlEncode(message) + "</p></div></body></html>";
            ctx.Response.Write(html);
        }

        public bool IsReusable => false;
    }
}
