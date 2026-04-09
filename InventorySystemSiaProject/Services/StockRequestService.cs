using System;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Bson;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Services
{
    /// <summary>
    /// Central service for inserting stock request documents into the shared StockRequests collection.
    /// Used by product, ingredient, and equipment stock request flows.
    /// </summary>
    public class StockRequestService
    {
        private readonly IMongoCollection<BsonDocument> _collection;

        public StockRequestService()
        {
            // Reuse the main MongoDB connection and collection naming from DatabaseHelper
            var database       = DatabaseHelper.Database;
            var collectionName = DatabaseHelper.GetStockRequestsCollectionName(); // defaults to "StockRequests"

            _collection = database.GetCollection<BsonDocument>(collectionName);
        }

        /// <summary>
        /// Inserts a StockRequest document for an equipment stock request and returns the new _id as string.
        /// The schema mirrors IngredientStockRequest / product stock request documents.
        /// </summary>
        public string InsertEquipmentStockRequest(Equipment equipment, EquipmentStockRequest request)
        {
            if (equipment == null) throw new ArgumentNullException(nameof(equipment));
            if (request   == null) throw new ArgumentNullException(nameof(request));

            var now = DateTime.UtcNow;

            var doc = new BsonDocument
            {
                // equipment specific identifiers
                { "equipmentID", equipment.Id },
                { "equipmentName", equipment.EquipmentName ?? string.Empty },
                { "equipmentCode", equipment.EquipmentCode ?? string.Empty },

                // request core
                { "quantityRequested", request.QuantityRequested },
                { "requestDate", request.RequestDate == default(DateTime) ? now : request.RequestDate },
                { "requestedBy", request.RequestedBy ?? string.Empty },
                { "requestedByUserId", string.IsNullOrEmpty(request.RequestedByUserId)
                    ? BsonNull.Value
                    : (BsonValue)new BsonString(request.RequestedByUserId) },
                { "requestStatus", "Pending" },
                { "instructions", request.Purpose ?? string.Empty },

                { "expectedDeliveryDate", request.ExpectedDeliveryDate.HasValue
                    ? (BsonValue)request.ExpectedDeliveryDate.Value : BsonNull.Value },

                // processing fields
                { "actualDeliveryDate", BsonNull.Value },
                { "statusUpdatedDate", BsonNull.Value },
                { "processedBy", string.Empty },
                { "processedByUserId", BsonNull.Value },
                { "rejectionReason", string.Empty },

                // cost / stock snapshot
                { "totalCost", request.EstimatedCost.HasValue ? (BsonValue)request.EstimatedCost.Value : BsonNull.Value },
                { "unitPrice", equipment.UnitCost },
                { "currentStockAtRequest", equipment.StockQuantity },
                { "minimumStockLevel", equipment.MinimumStock },

                { "emailSent", false },
                { "emailSentDate", BsonNull.Value },
                { "priority", request.Priority ?? "Normal" },

                { "createdAt", now },
                { "updatedAt", now },
                { "isActive", true },

                // discriminator so dashboards can distinguish
                { "requestType", "Equipment" }
            };

            _collection.InsertOne(doc);
            return doc["_id"].AsObjectId.ToString();
        }
    }
}
