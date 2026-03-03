using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class SaveEquipmentStockRequest : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            try
            {
                context.Request.InputStream.Position = 0;
                using (var sr = new StreamReader(context.Request.InputStream))
                {
                    var body = sr.ReadToEnd();
                    var d = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                    if (d == null)
                    {
                        context.Response.Write(js.Serialize(new { success = false, error = "Invalid request body" }));
                        return;
                    }

                    string equipmentId = d.ContainsKey("equipmentId") ? d["equipmentId"]?.ToString() : null;
                    string equipmentName = d.ContainsKey("equipmentName") ? d["equipmentName"]?.ToString() : null;
                    string equipmentCode = d.ContainsKey("equipmentCode") ? d["equipmentCode"]?.ToString() : null;
                    int qty = 0;
                    if (d.ContainsKey("quantityRequested")) int.TryParse(d["quantityRequested"]?.ToString(), out qty);
                    string purpose = d.ContainsKey("purpose") ? d["purpose"]?.ToString()?.Trim() : null;
                    string requestedBy = d.ContainsKey("requestedBy") ? d["requestedBy"]?.ToString()?.Trim() : "Admin";
                    string priority = d.ContainsKey("priority") ? d["priority"]?.ToString() ?? "Normal" : "Normal";
                    string notes = d.ContainsKey("notes") ? d["notes"]?.ToString()?.Trim() : null;
                    decimal estimatedCost = 0;
                    if (d.ContainsKey("estimatedCost")) decimal.TryParse(d["estimatedCost"]?.ToString(), out estimatedCost);
                    DateTime? deliveryDate = null;
                    if (d.ContainsKey("expectedDeliveryDate"))
                    {
                        DateTime dt;
                        if (DateTime.TryParse(d["expectedDeliveryDate"]?.ToString(), out dt))
                            deliveryDate = dt;
                    }

                    if (string.IsNullOrEmpty(equipmentId) || qty <= 0)
                    {
                        context.Response.Write(js.Serialize(new { success = false, error = "Equipment and quantity are required." }));
                        return;
                    }

                    var request = new EquipmentStockRequest
                    {
                        EquipmentId = equipmentId,
                        EquipmentName = equipmentName,
                        EquipmentCode = equipmentCode,
                        QuantityRequested = qty,
                        Purpose = purpose,
                        RequestedBy = requestedBy,
                        Priority = priority,
                        Notes = notes,
                        EstimatedCost = estimatedCost > 0 ? (decimal?)estimatedCost : null,
                        ExpectedDeliveryDate = deliveryDate
                    };

                    var svc = new EquipmentService();
                    string newId = svc.CreateRequestAsync(request).GetAwaiter().GetResult();
                    context.Response.Write(js.Serialize(new { success = true, message = "Stock request submitted successfully.", id = newId }));
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(js.Serialize(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable => false;
    }
}
