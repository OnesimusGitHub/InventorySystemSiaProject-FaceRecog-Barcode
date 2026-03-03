using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Bson;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Services
{
    public class EquipmentService
    {
        private readonly IMongoCollection<Equipment> _equipmentCollection;
        private readonly IMongoCollection<EquipmentStockRequest> _requestsCollection;

        public EquipmentService()
        {
            _equipmentCollection = DatabaseHelper.GetCollection<Equipment>(
                DatabaseHelper.GetEquipmentCollectionName());
            _requestsCollection = DatabaseHelper.GetCollection<EquipmentStockRequest>(
                DatabaseHelper.GetEquipmentStockRequestsCollectionName());
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
            if (!ObjectId.TryParse(id, out _)) return null;
            return await _equipmentCollection.Find(e => e.Id == id).FirstOrDefaultAsync();
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
            if (!ObjectId.TryParse(id, out _)) return null;
            return await _requestsCollection.Find(r => r.Id == id).FirstOrDefaultAsync();
        }

        public async Task<string> CreateRequestAsync(EquipmentStockRequest request)
        {
            request.CreatedAt = DateTime.UtcNow;
            request.UpdatedAt = DateTime.UtcNow;
            request.Status = "Pending";
            request.IsActive = true;
            await _requestsCollection.InsertOneAsync(request);
            return request.Id;
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
            return result.ModifiedCount > 0;
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
            if (request == null) return false;

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
