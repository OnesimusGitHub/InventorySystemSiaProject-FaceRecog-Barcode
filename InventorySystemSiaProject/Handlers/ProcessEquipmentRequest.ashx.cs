using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Handles Finance approval, rejection, and completion of equipment stock requests.
    /// POST body: { requestId, action: "approve"|"reject"|"complete", approvedBy, approvedCost, notes, reason, quantityAdded }
    /// </summary>
    public class ProcessEquipmentRequest : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            try
            {
                context.Request.InputStream.Position = 0;
                string body;
                using (var sr = new StreamReader(context.Request.InputStream))
                    body = sr.ReadToEnd();

                var d = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                if (d == null)
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Invalid body" }));
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
                        ok = svc.ApproveByFinanceAsync(requestId, approvedBy,
                            approvedCost > 0 ? (decimal?)approvedCost : null, notes)
                            .GetAwaiter().GetResult();
                        msg = ok ? "Request approved by Finance." : "Failed to approve request.";
                        break;

                    case "reject":
                        ok = svc.RejectRequestAsync(requestId, approvedBy, reason ?? "Rejected by Finance")
                            .GetAwaiter().GetResult();
                        msg = ok ? "Request rejected." : "Failed to reject request.";
                        break;

                    case "complete":
                        ok = svc.CompleteRequestAsync(requestId, qtyAdded > 0 ? qtyAdded : 0)
                            .GetAwaiter().GetResult();
                        msg = ok ? "Request completed and stock updated." : "Failed to complete request.";
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

        public bool IsReusable => false;
    }
}
