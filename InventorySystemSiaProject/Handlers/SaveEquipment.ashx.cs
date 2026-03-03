using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class SaveEquipment : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            try
            {
                string equipmentId = null;
                string name = null, type = null, code = null, brand = null, model = null,
                       desc = null, location = null, serialNo = null, condition = null;
                int stock = 0, minStock = 5;
                decimal unitCost = 0;
                DateTime? purchaseDate = null, warrantyExpiry = null;
                byte[] imgBytes = null;
                string imgContentType = null;

                bool isMultipart = context.Request.ContentType != null &&
                                   context.Request.ContentType.StartsWith("multipart/form-data");

                if (isMultipart)
                {
                    // FormData (supports file upload)
                    equipmentId = context.Request.Form["equipmentId"];
                    name = context.Request.Form["equipmentName"]?.Trim();
                    type = context.Request.Form["equipmentType"]?.Trim();
                    code = context.Request.Form["equipmentCode"]?.Trim();
                    brand = context.Request.Form["brand"]?.Trim();
                    model = context.Request.Form["model"]?.Trim();
                    desc = context.Request.Form["description"]?.Trim();
                    location = context.Request.Form["location"]?.Trim();
                    serialNo = context.Request.Form["serialNumber"]?.Trim();
                    condition = context.Request.Form["condition"]?.Trim() ?? "Good";
                    int.TryParse(context.Request.Form["stockQuantity"], out stock);
                    int.TryParse(context.Request.Form["minimumStock"], out minStock);
                    decimal.TryParse(context.Request.Form["unitCost"], out unitCost);

                    if (!string.IsNullOrEmpty(context.Request.Form["purchaseDate"]))
                        DateTime.TryParse(context.Request.Form["purchaseDate"], out var pd) ;
                    if (!string.IsNullOrEmpty(context.Request.Form["warrantyExpiry"]))
                        DateTime.TryParse(context.Request.Form["warrantyExpiry"], out var we);

                    DateTime pdt, wet;
                    if (DateTime.TryParse(context.Request.Form["purchaseDate"], out pdt)) purchaseDate = pdt;
                    if (DateTime.TryParse(context.Request.Form["warrantyExpiry"], out wet)) warrantyExpiry = wet;

                    // Handle image upload
                    var imgFile = context.Request.Files["equipmentImage"];
                    if (imgFile != null && imgFile.ContentLength > 0)
                    {
                        using (var br = new BinaryReader(imgFile.InputStream))
                            imgBytes = br.ReadBytes(imgFile.ContentLength);
                        imgContentType = imgFile.ContentType;
                    }
                }
                else
                {
                    // JSON body
                    context.Request.InputStream.Position = 0;
                    using (var sr = new StreamReader(context.Request.InputStream))
                    {
                        var body = sr.ReadToEnd();
                        var d = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                        if (d == null) { context.Response.Write(js.Serialize(new { success = false, error = "Invalid body" })); return; }
                        equipmentId = d.ContainsKey("equipmentId") ? d["equipmentId"]?.ToString() : null;
                        name = d.ContainsKey("equipmentName") ? d["equipmentName"]?.ToString()?.Trim() : null;
                        type = d.ContainsKey("equipmentType") ? d["equipmentType"]?.ToString()?.Trim() : null;
                        code = d.ContainsKey("equipmentCode") ? d["equipmentCode"]?.ToString()?.Trim() : null;
                        brand = d.ContainsKey("brand") ? d["brand"]?.ToString()?.Trim() : null;
                        model = d.ContainsKey("model") ? d["model"]?.ToString()?.Trim() : null;
                        desc = d.ContainsKey("description") ? d["description"]?.ToString()?.Trim() : null;
                        location = d.ContainsKey("location") ? d["location"]?.ToString()?.Trim() : null;
                        serialNo = d.ContainsKey("serialNumber") ? d["serialNumber"]?.ToString()?.Trim() : null;
                        condition = d.ContainsKey("condition") ? d["condition"]?.ToString()?.Trim() ?? "Good" : "Good";
                        if (d.ContainsKey("stockQuantity")) int.TryParse(d["stockQuantity"]?.ToString(), out stock);
                        if (d.ContainsKey("minimumStock")) int.TryParse(d["minimumStock"]?.ToString(), out minStock);
                        if (d.ContainsKey("unitCost")) decimal.TryParse(d["unitCost"]?.ToString(), out unitCost);
                        DateTime pdt, wet;
                        if (d.ContainsKey("purchaseDate") && DateTime.TryParse(d["purchaseDate"]?.ToString(), out pdt)) purchaseDate = pdt;
                        if (d.ContainsKey("warrantyExpiry") && DateTime.TryParse(d["warrantyExpiry"]?.ToString(), out wet)) warrantyExpiry = wet;
                    }
                }

                if (string.IsNullOrEmpty(name) || string.IsNullOrEmpty(type))
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Equipment name and type are required." }));
                    return;
                }

                var svc = new EquipmentService();
                bool isUpdate = !string.IsNullOrEmpty(equipmentId);

                if (isUpdate)
                {
                    var existing = svc.GetEquipmentByIdAsync(equipmentId).GetAwaiter().GetResult();
                    if (existing == null)
                    {
                        context.Response.Write(js.Serialize(new { success = false, error = "Equipment not found." }));
                        return;
                    }
                    existing.EquipmentName = name;
                    existing.EquipmentType = type;
                    existing.EquipmentCode = code;
                    existing.Brand = brand;
                    existing.Model = model;
                    existing.Description = desc;
                    existing.Location = location;
                    existing.SerialNumber = serialNo;
                    existing.Condition = condition;
                    existing.StockQuantity = stock;
                    existing.MinimumStock = minStock < 1 ? 1 : minStock;
                    existing.UnitCost = unitCost;
                    existing.PurchaseDate = purchaseDate;
                    existing.WarrantyExpiry = warrantyExpiry;
                    if (imgBytes != null) { existing.EquipmentImg = imgBytes; existing.EquipmentImgContentType = imgContentType; }

                    bool ok = svc.UpdateEquipmentAsync(existing).GetAwaiter().GetResult();
                    context.Response.Write(js.Serialize(new { success = ok, message = ok ? "Equipment updated successfully." : "No changes saved." }));
                }
                else
                {
                    var eq = new Equipment
                    {
                        EquipmentName = name,
                        EquipmentType = type,
                        EquipmentCode = code,
                        Brand = brand,
                        Model = model,
                        Description = desc,
                        Location = location,
                        SerialNumber = serialNo,
                        Condition = condition,
                        StockQuantity = stock,
                        MinimumStock = minStock < 1 ? 1 : minStock,
                        UnitCost = unitCost,
                        PurchaseDate = purchaseDate,
                        WarrantyExpiry = warrantyExpiry,
                        EquipmentImg = imgBytes,
                        EquipmentImgContentType = imgContentType
                    };
                    string newId = svc.CreateEquipmentAsync(eq).GetAwaiter().GetResult();
                    context.Response.Write(js.Serialize(new { success = true, message = "Equipment created successfully.", id = newId }));
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
