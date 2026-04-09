<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.SupplierCrudHandler" %>

using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class SupplierCrudHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            context.Response.Cache.SetNoStore();

            var action = context.Request["action"];
            var serializer = new JavaScriptSerializer();
            var service = new SupplierService();

            try
            {
                if (string.IsNullOrEmpty(action))
                {
                    context.Response.Write(serializer.Serialize(new { success = false, message = "Action parameter is required." }));
                    return;
                }

                switch (action)
                {
                    case "get":
                        {
                            // Use synchronous service method to avoid ASP.NET async deadlocks
                            var suppliers = service.GetAllSuppliers();
                            context.Response.Write(serializer.Serialize(new { success = true, suppliers }));
                            break;
                        }

                    case "add":
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
                            var id = service.CreateSupplier(supplier);
                            context.Response.Write(serializer.Serialize(new { success = !string.IsNullOrEmpty(id), id }));
                            break;
                        }

                    case "update":
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
                            var success = service.UpdateSupplier(id, supplier);
                            context.Response.Write(serializer.Serialize(new { success }));
                            break;
                        }

                    case "delete":
                        {
                            var id = context.Request["SupplierID"];
                            var success = service.DeleteSupplier(id);
                            context.Response.Write(serializer.Serialize(new { success }));
                            break;
                        }

                    default:
                        {
                            context.Response.Write(serializer.Serialize(new { success = false, message = "Invalid action." }));
                            break;
                        }
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(serializer.Serialize(new { success = false, message = ex.Message, stackTrace = ex.StackTrace }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
