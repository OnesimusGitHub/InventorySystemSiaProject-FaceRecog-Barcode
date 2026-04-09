using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using System.Linq;

namespace InventorySystemSiaProject.Handlers
{
    public class GetEquipmentStockRequests : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";

            var serializer = new JavaScriptSerializer();
            try
            {
                var collection = DatabaseHelper.GetEquipmentStockRequestsCollection(); // ensure this exists
                var list = collection.Find(FilterDefinition<EquipmentStockRequest>.Empty)
                                     .SortByDescending(r => r.RequestDate)
                                     .ToList();

                // project to what JS expects
                var data = list.Select(r => new
                {
                    id = r.Id,
                    displayId = r.DisplayId,
                    equipmentId = r.EquipmentId,
                    equipmentName = r.EquipmentName,
                    equipmentCode = r.EquipmentCode,
                    quantityRequested = r.QuantityRequested,
                    purpose = r.Purpose,
                    requestedBy = r.RequestedBy,
                    requestDate = r.RequestDate.ToString("yyyy-MM-dd HH:mm"),
                    priority = r.Priority,
                    status = r.Status,
                    estimatedCost = r.EstimatedCost,
                    approvedCost = r.ApprovedCost,
                    financeApprovedBy = r.FinanceApprovedBy,
                    statusBadgeClass = r.StatusBadgeClass
                }).ToList();

                var payload = new { success = true, requests = data };
                context.Response.Write(serializer.Serialize(payload));
            }
            catch (Exception ex)
            {
                // temporary: log and send error so front‑end can show it
                System.Diagnostics.Debug.WriteLine("GetEquipmentStockRequests error: " + ex);
                var errorPayload = new { success = false, error = ex.Message };
                context.Response.Write(serializer.Serialize(errorPayload));
            }
        }

        public bool IsReusable => false;
    }
}