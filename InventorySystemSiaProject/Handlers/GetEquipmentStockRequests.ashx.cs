using System;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class GetEquipmentStockRequests : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            try
            {
                var svc = new EquipmentService();
                var list = svc.GetAllRequestsAsync().GetAwaiter().GetResult();
                var result = new System.Collections.Generic.List<object>();
                foreach (var r in list)
                {
                    result.Add(new
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
                        status = r.Status,
                        statusBadgeClass = r.StatusBadgeClass,
                        priority = r.Priority,
                        estimatedCost = r.EstimatedCost,
                        approvedCost = r.ApprovedCost,
                        financeApprovedBy = r.FinanceApprovedBy,
                        financeApprovedAt = r.FinanceApprovedAt.HasValue ? r.FinanceApprovedAt.Value.ToString("yyyy-MM-dd HH:mm") : null,
                        financeNotes = r.FinanceNotes,
                        rejectionReason = r.RejectionReason,
                        notes = r.Notes,
                        expectedDeliveryDate = r.ExpectedDeliveryDate.HasValue ? r.ExpectedDeliveryDate.Value.ToString("yyyy-MM-dd") : null,
                        createdAt = r.CreatedAt.ToString("yyyy-MM-dd HH:mm")
                    });
                }
                context.Response.Write(js.Serialize(new { success = true, requests = result }));
            }
            catch (Exception ex)
            {
                context.Response.Write(js.Serialize(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable => false;
    }
}
