using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Bson;
using MongoDB.Driver;
using InventorySystemSiaProject.Services; // for SupplierService / SendEmaikService

namespace InventorySystemSiaProject.Services
{
    public class EquipmentService
    {
        private readonly IMongoCollection<Equipment> _equipmentCollection;
        private readonly IMongoCollection<EquipmentStockRequest> _requestsCollection;
        private readonly StockRequestService _stockRequestService;
        private readonly SupplierService _supplierService;

        public EquipmentService()
        {
            _equipmentCollection = DatabaseHelper.GetCollection<Equipment>(
                DatabaseHelper.GetEquipmentCollectionName());
            _requestsCollection = DatabaseHelper.GetCollection<EquipmentStockRequest>(
                DatabaseHelper.GetEquipmentStockRequestsCollectionName());
            _stockRequestService = new StockRequestService();
            _supplierService = new SupplierService();
        }

        // Synchronous wrapper for CreateRequest used by classic ASP.NET handlers
        public string CreateRequest(EquipmentStockRequest request)
        {
            // Reuse async logic but execute synchronously in a deadlock-safe way
            // by not capturing ASP.NET context (ConfigureAwait(false))
            return CreateRequestAsync(request)
                .ConfigureAwait(false)
                .GetAwaiter()
                .GetResult();
        }

        // ????????????? Equipment CRUD ?????????????

        public async Task<List<Equipment>> GetAllEquipmentAsync(bool includeArchived = false)
        {
            var filter = includeArchived
                ? Builders<Equipment>.Filter.Empty
                : Builders<Equipment>.Filter.Eq(e => e.Status, "Active");

            return await _equipmentCollection.Find(filter)
                .SortByDescending(e => e.CreatedAt)
                .ToListAsync();
        }

        public async Task<Equipment> GetEquipmentByIdAsync(string id)
        {
            if (!ObjectId.TryParse(id, out _))
                return null;

            return await _equipmentCollection
                .Find(e => e.Id == id)
                .FirstOrDefaultAsync();
        }

        public async Task<string> CreateEquipmentAsync(Equipment equipment)
        {
            equipment.CreatedAt = DateTime.UtcNow;
            equipment.UpdatedAt = DateTime.UtcNow;
            equipment.Status = "Active";

            await _equipmentCollection.InsertOneAsync(equipment);
            return equipment.Id;
        }

        public async Task<bool> UpdateEquipmentAsync(Equipment equipment)
        {
            equipment.UpdatedAt = DateTime.UtcNow;

            var result = await _equipmentCollection.ReplaceOneAsync(
                e => e.Id == equipment.Id, equipment);

            return result.ModifiedCount > 0;
        }

        public async Task<bool> ArchiveEquipmentAsync(string id)
        {
            var update = Builders<Equipment>.Update
                .Set(e => e.Status, "Archived")
                .Set(e => e.UpdatedAt, DateTime.UtcNow);

            var result = await _equipmentCollection.UpdateOneAsync(e => e.Id == id, update);
            return result.ModifiedCount > 0;
        }

        public async Task<bool> RestoreEquipmentAsync(string id)
        {
            var update = Builders<Equipment>.Update
                .Set(e => e.Status, "Active")
                .Set(e => e.UpdatedAt, DateTime.UtcNow);

            var result = await _equipmentCollection.UpdateOneAsync(e => e.Id == id, update);
            return result.ModifiedCount > 0;
        }

        public async Task<bool> UpdateStockAsync(string id, int newQuantity)
        {
            var update = Builders<Equipment>.Update
                .Set(e => e.StockQuantity, newQuantity)
                .Set(e => e.UpdatedAt, DateTime.UtcNow);

            var result = await _equipmentCollection.UpdateOneAsync(e => e.Id == id, update);
            return result.ModifiedCount > 0;
        }

        // ????????????? Stock Requests ?????????????

        public async Task<List<EquipmentStockRequest>> GetAllRequestsAsync(bool activeOnly = true)
        {
            var filter = activeOnly
                ? Builders<EquipmentStockRequest>.Filter.Eq(r => r.IsActive, true)
                : Builders<EquipmentStockRequest>.Filter.Empty;

            return await _requestsCollection.Find(filter)
                .SortByDescending(r => r.CreatedAt)
                .ToListAsync();
        }

        public async Task<EquipmentStockRequest> GetRequestByIdAsync(string id)
        {
           // if (!ObjectId.TryParse(id, out _))
             //   return null;

            return await _requestsCollection
                .Find(r => r.Id == id)
                .FirstOrDefaultAsync();
        }

        public async Task<string> CreateRequestAsync(EquipmentStockRequest request)
        {
            request.CreatedAt = DateTime.UtcNow;
            request.UpdatedAt = DateTime.UtcNow;

            // If caller did not explicitly set a status, default to Pending
            if (string.IsNullOrWhiteSpace(request.Status))
            {
                request.Status = "Pending";
            }

            request.IsActive = true;

            // insert main equipment request first
            await _requestsCollection.InsertOneAsync(request);

            // also create a document in the shared StockRequest collection for dashboards
            var equipment = await GetEquipmentByIdAsync(request.EquipmentId);
            if (equipment != null)
            {
                var stockRequestId = _stockRequestService.InsertEquipmentStockRequest(equipment, request);
                request.StockRequestId = stockRequestId;

                var update = Builders<EquipmentStockRequest>.Update
                    .Set(r => r.StockRequestId, stockRequestId)
                    .Set(r => r.UpdatedAt, DateTime.UtcNow);

                await _requestsCollection.UpdateOneAsync(r => r.Id == request.Id, update);
            }

            return request.Id;
        }

        public async Task<bool> ApproveByAdminAsync(string requestId)
        {
            try
            {
                // Get the request (so we can fetch equipment + supplier)
                var request = await GetRequestByIdAsync(requestId).ConfigureAwait(false);
                if (request == null)
                {
                    System.Diagnostics.Debug.WriteLine($"[ApproveByAdmin] Request not found: {requestId}");
                    return false;
                }

                if (string.IsNullOrWhiteSpace(request.EquipmentId))
                {
                    System.Diagnostics.Debug.WriteLine($"[ApproveByAdmin] Request {requestId} has no EquipmentId.");
                    return false;
                }

                // Update status to ApprovedByAdmin
                var update = Builders<EquipmentStockRequest>.Update
                    .Set(r => r.Status, "ApprovedByAdmin")
                    .Set(r => r.UpdatedAt, DateTime.UtcNow);

                var result = await _requestsCollection
                    .UpdateOneAsync(r => r.Id == requestId, update)
                    .ConfigureAwait(false);

                if (result.ModifiedCount <= 0)
                {
                    System.Diagnostics.Debug.WriteLine($"[ApproveByAdmin] UpdateOneAsync modified 0 docs for request {requestId}.");
                    return false;
                }

                // Send email to supplier (best effort)
                try
                {
                    var equipment = await GetEquipmentByIdAsync(request.EquipmentId)
                        .ConfigureAwait(false);
                    if (equipment == null)
                    {
                        System.Diagnostics.Debug.WriteLine($"[ApproveByAdmin] Equipment not found for request {requestId}, EquipmentId={request.EquipmentId}");
                        return true; // status already updated
                    }

                    var supplierId = !string.IsNullOrWhiteSpace(request.SupplierId)
                        ? request.SupplierId
                        : equipment.SupplierId;

                    var supplierName = !string.IsNullOrWhiteSpace(request.SupplierName)
                        ? request.SupplierName
                        : equipment.SupplierName;

                    if (string.IsNullOrWhiteSpace(supplierId))
                    {
                        System.Diagnostics.Debug.WriteLine($"[ApproveByAdmin] No supplierId for request {requestId}.");
                        return true;
                    }

                    var supplier = await _supplierService.GetSupplierByIdAsync(supplierId)
                        .ConfigureAwait(false);
                    if (supplier == null || string.IsNullOrWhiteSpace(supplier.SupEmail))
                    {
                        System.Diagnostics.Debug.WriteLine($"[ApproveByAdmin] Supplier not found or no email. SupplierId={supplierId}");
                        return true;
                    }

                    SendEmaikService.SendStockRequestEmail(
                        supplierEmail: supplier.SupEmail,
                        supplierName: supplierName ?? supplier.SupName ?? "Supplier",
                        productName: equipment.EquipmentName,
                        currentStock: equipment.StockQuantity,
                        minimumStock: equipment.MinimumStock,
                        requestedQuantity: request.QuantityRequested,
                        additionalNotes: request.Notes,
                        expectedDeliveryDate: request.ExpectedDeliveryDate,
                        requestId: request.Id,
                        requestDate: request.RequestDate
                    );
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[ApproveByAdmin] Email send failed: " + ex);
                }

                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ApproveByAdmin] Unexpected exception: " + ex);
                return false;
            }
        }
        public async Task<bool> ApproveByFinanceAsync(string requestId, string approvedBy,
            decimal? approvedCost, string notes)
        {
            var update = Builders<EquipmentStockRequest>.Update
                .Set(r => r.Status, "ApprovedByFinance")
                .Set(r => r.FinanceApprovedBy, approvedBy)
                .Set(r => r.FinanceApprovedAt, DateTime.UtcNow)
                .Set(r => r.ApprovedCost, approvedCost)
                .Set(r => r.FinanceNotes, notes)
                .Set(r => r.UpdatedAt, DateTime.UtcNow);

            var result = await _requestsCollection.UpdateOneAsync(r => r.Id == requestId, update);

            if (result.ModifiedCount <= 0)
            {
                return false;
            }

            // After finance approval, send email to supplier if possible
            try
            {
                var request = await GetRequestByIdAsync(requestId);
                if (request == null || string.IsNullOrWhiteSpace(request.EquipmentId))
                {
                    return true; // status already updated; nothing else to do
                }

                var equipment = await GetEquipmentByIdAsync(request.EquipmentId);
                if (equipment == null)
                {
                    return true;
                }

                // Resolve supplier information
                var supplierId = !string.IsNullOrWhiteSpace(request.SupplierId)
                    ? request.SupplierId
                    : equipment.SupplierId;

                var supplierName = !string.IsNullOrWhiteSpace(request.SupplierName)
                    ? request.SupplierName
                    : equipment.SupplierName;

                if (string.IsNullOrWhiteSpace(supplierId))
                {
                    return true; // no linked supplier
                }

                var supplier = await _supplierService.GetSupplierByIdAsync(supplierId);
                if (supplier == null || string.IsNullOrWhiteSpace(supplier.SupEmail))
                {
                    return true; // nothing to send to
                }

                // Use existing email service – treat equipment as "product"
                SendEmaikService.SendStockRequestEmail(
                    supplierEmail: supplier.SupEmail,
                    supplierName: supplierName ?? supplier.SupName ?? "Supplier",
                    productName: equipment.EquipmentName,
                    currentStock: equipment.StockQuantity,
                    minimumStock: equipment.MinimumStock,
                    requestedQuantity: request.QuantityRequested,
                    additionalNotes: notes,
                    expectedDeliveryDate: request.ExpectedDeliveryDate,
                    requestId: request.Id,
                    requestDate: request.RequestDate
                );
            }
            catch (Exception ex)
            {
                // Log but don't fail the approval operation because of email issues
                System.Diagnostics.Debug.WriteLine("Failed to send equipment stock request email: " + ex);
            }

            return true;
        }

        public async Task<bool> RejectRequestAsync(string requestId, string rejectedBy, string reason)
        {
            var update = Builders<EquipmentStockRequest>.Update
                .Set(r => r.Status, "Rejected")
                .Set(r => r.FinanceApprovedBy, rejectedBy)
                .Set(r => r.FinanceApprovedAt, DateTime.UtcNow)
                .Set(r => r.RejectionReason, reason)
                .Set(r => r.UpdatedAt, DateTime.UtcNow);

            var result = await _requestsCollection.UpdateOneAsync(r => r.Id == requestId, update);
            return result.ModifiedCount > 0;
        }

        public async Task<bool> CompleteRequestAsync(string requestId, int quantityAdded)
        {
            // Get request first to update equipment stock
            var request = await GetRequestByIdAsync(requestId);
            if (request == null)
                return false;

            var update = Builders<EquipmentStockRequest>.Update
                .Set(r => r.Status, "Completed")
                .Set(r => r.UpdatedAt, DateTime.UtcNow);

            var result = await _requestsCollection.UpdateOneAsync(r => r.Id == requestId, update);

            // Update equipment stock
            if (result.ModifiedCount > 0 && !string.IsNullOrEmpty(request.EquipmentId))
            {
                var equipment = await GetEquipmentByIdAsync(request.EquipmentId);
                if (equipment != null)
                {
                    await UpdateStockAsync(request.EquipmentId,
                        equipment.StockQuantity + quantityAdded);
                }
            }

            return result.ModifiedCount > 0;
        }
    }
}