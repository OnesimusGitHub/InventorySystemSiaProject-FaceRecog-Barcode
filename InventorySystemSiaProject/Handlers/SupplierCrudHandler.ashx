<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.SupplierCrudHandler" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Handlers
{
    public class SupplierCrudHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var action = context.Request["action"];
            var serializer = new JavaScriptSerializer();
            var service = new SupplierService();
            try
            {
                if (action == "get")
                {
                    var suppliers = service.GetAllSuppliersAsync().Result;
                    context.Response.Write(serializer.Serialize(new { success = true, suppliers }));
                }
                else if (action == "add")
                {
                    var supplier = new Supplier
                    {
                        SupName = context.Request["SupName"],
                        SupContactPer = context.Request["SupContactPer"],
                        SupContactNo = context.Request["SupContactNo"],
                        SupEmail = context.Request["SupEmail"],
                        SupAddress = context.Request["SupAddress"],
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow
                    };
                    supplier.PrepareForInsertion();
                    var id = service.CreateSupplierAsync(supplier).Result;
                    context.Response.Write(serializer.Serialize(new { success = !string.IsNullOrEmpty(id), id }));
                }
                else if (action == "update")
                {
                    var supplier = new Supplier
                    {
                        SupName = context.Request["SupName"],
                        SupContactPer = context.Request["SupContactPer"],
                        SupContactNo = context.Request["SupContactNo"],
                        SupEmail = context.Request["SupEmail"],
                        SupAddress = context.Request["SupAddress"],
                        IsActive = true,
                        UpdatedAt = DateTime.UtcNow
                    };
                    supplier.PrepareForUpdate();
                    var id = context.Request["SupplierID"];
                    var success = service.UpdateSupplierAsync(id, supplier).Result;
                    context.Response.Write(serializer.Serialize(new { success }));
                }
                else if (action == "delete")
                {
                    var id = context.Request["SupplierID"];
                    var success = service.DeleteSupplierAsync(id).Result;
                    context.Response.Write(serializer.Serialize(new { success }));
                }
                else
                {
                    context.Response.Write(serializer.Serialize(new { success = false, message = "Invalid action." }));
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(serializer.Serialize(new { success = false, message = ex.Message }));
            }
        }
        public bool IsReusable { get { return false; } }
    }
}
