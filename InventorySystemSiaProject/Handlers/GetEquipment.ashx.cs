using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class GetEquipment : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            try
            {
                // Support both GET (list) and POST (single by id)
                if (context.Request.HttpMethod == "GET" &&
                    string.IsNullOrEmpty(context.Request.QueryString["equipmentId"]))
                {
                    bool includeArchived = context.Request.QueryString["includeArchived"] == "true";
                    var svc = new EquipmentService();
                    var list = svc.GetAllEquipmentAsync(includeArchived).GetAwaiter().GetResult();
                    var result = new System.Collections.Generic.List<object>();
                    foreach (var e in list)
                    {
                        result.Add(new
                        {
                            id = e.Id,
                            equipmentName = e.EquipmentName,
                            equipmentType = e.EquipmentType,
                            equipmentCode = e.EquipmentCode,
                            brand = e.Brand,
                            model = e.Model,
                            description = e.Description,
                            location = e.Location,
                            stockQuantity = e.StockQuantity,
                            minimumStock = e.MinimumStock,
                            unitCost = e.UnitCost,
                            serialNumber = e.SerialNumber,
                            condition = e.Condition,
                            status = e.Status,
                            stockStatus = e.StockStatus,
                            isLowStock = e.IsLowStock,
                            purchaseDate = e.PurchaseDate.HasValue ? e.PurchaseDate.Value.ToString("yyyy-MM-dd") : null,
                            warrantyExpiry = e.WarrantyExpiry.HasValue ? e.WarrantyExpiry.Value.ToString("yyyy-MM-dd") : null,
                            createdAt = e.CreatedAt.ToString("yyyy-MM-dd HH:mm")
                        });
                    }
                    context.Response.Write(js.Serialize(new { success = true, equipment = result }));
                    return;
                }

                // GET single by id
                string equipmentId = context.Request.QueryString["equipmentId"]
                    ?? context.Request.Form["equipmentId"];

                if (context.Request.HttpMethod == "POST")
                {
                    context.Request.InputStream.Position = 0;
                    using (var sr = new StreamReader(context.Request.InputStream))
                    {
                        var body = sr.ReadToEnd();
                        if (!string.IsNullOrWhiteSpace(body))
                        {
                            var dict = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                            if (dict != null && dict.ContainsKey("equipmentId"))
                                equipmentId = dict["equipmentId"]?.ToString();
                        }
                    }
                }

                if (string.IsNullOrEmpty(equipmentId))
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Equipment ID required" }));
                    return;
                }

                var service = new EquipmentService();
                var eq = service.GetEquipmentByIdAsync(equipmentId).GetAwaiter().GetResult();
                if (eq == null)
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Equipment not found" }));
                    return;
                }

                context.Response.Write(js.Serialize(new
                {
                    success = true,
                    equipment = new
                    {
                        id = eq.Id,
                        equipmentName = eq.EquipmentName,
                        equipmentType = eq.EquipmentType,
                        equipmentCode = eq.EquipmentCode,
                        brand = eq.Brand,
                        model = eq.Model,
                        description = eq.Description,
                        location = eq.Location,
                        stockQuantity = eq.StockQuantity,
                        minimumStock = eq.MinimumStock,
                        unitCost = eq.UnitCost,
                        serialNumber = eq.SerialNumber,
                        condition = eq.Condition,
                        status = eq.Status,
                        stockStatus = eq.StockStatus,
                        isLowStock = eq.IsLowStock,
                        purchaseDate = eq.PurchaseDate.HasValue ? eq.PurchaseDate.Value.ToString("yyyy-MM-dd") : null,
                        warrantyExpiry = eq.WarrantyExpiry.HasValue ? eq.WarrantyExpiry.Value.ToString("yyyy-MM-dd") : null,
                        createdAt = eq.CreatedAt.ToString("yyyy-MM-dd HH:mm")
                    }
                }));
            }
            catch (Exception ex)
            {
                context.Response.Write(js.Serialize(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable => false;
    }
}
