
using System;
using System.IO;
using System.Threading.Tasks;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class ProcessEquipmentRequest : IHttpAsyncHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            // not used with async pattern
            throw new NotSupportedException("Synchronous processing is not supported.");
        }

        public IAsyncResult BeginProcessRequest(HttpContext context, AsyncCallback cb, object extraData)
        {
            var task = ProcessRequestAsync(context);
            if (cb != null)
                task.ContinueWith(t => cb(t));
            return task;
        }

        public void EndProcessRequest(IAsyncResult result)
        {
            // nothing to do; response already written
        }

        public bool IsReusable => false;

        private async Task ProcessRequestAsync(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();

            try
            {
                context.Request.InputStream.Position = 0;
                string body;
                using (var sr = new StreamReader(context.Request.InputStream))
                    body = await sr.ReadToEndAsync().ConfigureAwait(false);

                if (string.IsNullOrWhiteSpace(body))
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Empty request body." }));
                    return;
                }

                var d = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                if (d == null)
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Invalid JSON body." }));
                    return;
                }

                string requestId = d.ContainsKey("requestId") ? d["requestId"]?.ToString() : null;
                string action = d.ContainsKey("action") ? d["action"]?.ToString() : null;

                if (string.IsNullOrEmpty(requestId) || string.IsNullOrEmpty(action))
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "requestId and action are required." }));
                    return;
                }

                string approvedBy = d.ContainsKey("approvedBy") ? d["approvedBy"]?.ToString() ?? "Finance" : "Finance";
                string notes = d.ContainsKey("notes") ? d["notes"]?.ToString() : null;
                string reason = d.ContainsKey("reason") ? d["reason"]?.ToString() : null;
                decimal approvedCost = 0;
                if (d.ContainsKey("approvedCost")) decimal.TryParse(d["approvedCost"]?.ToString(), out approvedCost);
                int qtyAdded = 0;
                if (d.ContainsKey("quantityAdded")) int.TryParse(d["quantityAdded"]?.ToString(), out qtyAdded);

                var svc = new EquipmentService();
                bool ok;
                string msg;

                switch (action.ToLower())
                {
                    case "approve":
                        ok = await svc.ApproveByFinanceAsync(
                                requestId,
                                approvedBy,
                                approvedCost > 0 ? (decimal?)approvedCost : null,
                                notes
                             ).ConfigureAwait(false);
                        msg = ok ? "Request approved by Finance." : "Failed to approve request.";
                        break;

                    case "reject":
                        ok = await svc.RejectRequestAsync(
                                requestId,
                                approvedBy,
                                reason ?? "Rejected by Finance"
                             ).ConfigureAwait(false);
                        msg = ok ? "Request rejected." : "Failed to reject request.";
                        break;

                    case "complete":
                        ok = await svc.CompleteRequestAsync(
                                requestId,
                                qtyAdded > 0 ? qtyAdded : 0
                             ).ConfigureAwait(false);
                        msg = ok ? "Request completed and stock updated." : "Failed to complete request.";
                        break;

                    case "adminapprove":
                        ok = await svc.ApproveByAdminAsync(requestId)
                                      .ConfigureAwait(false);
                        msg = ok ? "Request approved by Admin and supplier notified."
                                 : "Failed to approve request by Admin.";
                        break;

                    default:
                        context.Response.Write(js.Serialize(new { success = false, error = "Unknown action: " + action }));
                        return;
                }

                context.Response.Write(js.Serialize(new { success = ok, message = msg }));
            }
            catch (Exception ex)
            {
                context.Response.Write(js.Serialize(new { success = false, error = ex.Message }));
            }
        }
    }
}