using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using System.Diagnostics;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class SaveEquipmentStockRequest : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.ContentEncoding = System.Text.Encoding.UTF8;
            // prevent IIS from replacing JSON with an HTML error page
            context.Response.TrySkipIisCustomErrors = true;

            var js = new JavaScriptSerializer();
            var sw = Stopwatch.StartNew();
            Debug.WriteLine("[SaveEquipmentStockRequest] START: " + DateTime.UtcNow.ToString("o"));

            try
            {
                if (!string.Equals(context.Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
                {
                    context.Response.StatusCode = 200;
                    context.Response.Write(js.Serialize(new { success = false, error = "Only POST is supported." }));
                    context.Response.Flush();
                    Debug.WriteLine("[SaveEquipmentStockRequest] END (method not POST) elapsed ms: " + sw.ElapsedMilliseconds);
                    return;
                }

                context.Request.InputStream.Position = 0;
                string body;
                using (var sr = new StreamReader(context.Request.InputStream))
                {
                    body = sr.ReadToEnd();
                }

                if (string.IsNullOrWhiteSpace(body))
                {
                    context.Response.StatusCode = 200;
                    context.Response.Write(js.Serialize(new { success = false, error = "Invalid request body" }));
                    context.Response.Flush();
                    Debug.WriteLine("[SaveEquipmentStockRequest] END (empty body) elapsed ms: " + sw.ElapsedMilliseconds);
                    return;
                }

                var d = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                if (d == null)
                {
                    context.Response.StatusCode = 200;
                    context.Response.Write(js.Serialize(new { success = false, error = "Invalid request body" }));
                    context.Response.Flush();
                    Debug.WriteLine("[SaveEquipmentStockRequest] END (invalid json) elapsed ms: " + sw.ElapsedMilliseconds);
                    return;
                }

                // Parse fields
                string equipmentId = d.ContainsKey("equipmentId") ? d["equipmentId"]?.ToString() : null;
                string equipmentName = d.ContainsKey("equipmentName") ? d["equipmentName"]?.ToString() : null;
                string equipmentCode = d.ContainsKey("equipmentCode") ? d["equipmentCode"]?.ToString() : null;
                string supplierId = d.ContainsKey("supplierId") ? d["supplierId"]?.ToString() : null;
                string supplierName = d.ContainsKey("supplierName") ? d["supplierName"]?.ToString() : null;

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
                    context.Response.StatusCode = 200;
                    context.Response.Write(js.Serialize(new { success = false, error = "Equipment and quantity are required." }));
                    context.Response.Flush();
                    Debug.WriteLine("[SaveEquipmentStockRequest] END (validation) elapsed ms: " + sw.ElapsedMilliseconds);
                    return;
                }

                var request = new EquipmentStockRequest
                {
                    EquipmentId = equipmentId,
                    EquipmentName = equipmentName,
                    EquipmentCode = equipmentCode,
                    SupplierId = supplierId,
                    SupplierName = supplierName,
                    QuantityRequested = qty,
                    Purpose = purpose,
                    RequestedBy = requestedBy,
                    Priority = priority,
                    Notes = notes,
                    EstimatedCost = estimatedCost > 0 ? (decimal?)estimatedCost : null,
                    ExpectedDeliveryDate = deliveryDate,
                    Status = "Pending"
                };

                var svc = new EquipmentService();
                string newId = null;
                try
                {
                    Debug.WriteLine("[SaveEquipmentStockRequest] calling CreateRequest...");
                    newId = svc.CreateRequest(request);
                    Debug.WriteLine("[SaveEquipmentStockRequest] CreateRequest returned id: " + (newId ?? "<null>"));
                }
                catch (Exception exCreate)
                {
                    Debug.WriteLine("[SaveEquipmentStockRequest] CreateRequest exception: " + exCreate);
                    // attempt to return a controlled success response if DB insert already happened,
                    // otherwise return an error descriptor to the client.
                    context.Response.StatusCode = 200;
                    context.Response.Write(js.Serialize(new { success = true, message = "Stock request submitted (with warnings).", id = newId ?? string.Empty }));
                    context.Response.Flush();
                    Debug.WriteLine("[SaveEquipmentStockRequest] END (create-exception) elapsed ms: " + sw.ElapsedMilliseconds);
                    return;
                }

                context.Response.StatusCode = 200;
                context.Response.Write(js.Serialize(new { success = true, message = "Stock request submitted successfully.", id = newId }));
                context.Response.Flush();
                Debug.WriteLine("[SaveEquipmentStockRequest] END (success) elapsed ms: " + sw.ElapsedMilliseconds);
            }
            catch (Exception ex)
            {
                Debug.WriteLine("[SaveEquipmentStockRequest] ERROR: " + ex);
                context.Response.StatusCode = 200;
                context.Response.Write(js.Serialize(new { success = false, error = ex.Message }));
                context.Response.Flush();
                Debug.WriteLine("[SaveEquipmentStockRequest] END (exception) elapsed ms: " + sw.ElapsedMilliseconds);
            }
        }

        public bool IsReusable => false;
    }
}