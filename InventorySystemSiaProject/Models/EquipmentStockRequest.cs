using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;

namespace InventorySystemSiaProject.Models
{
    [BsonIgnoreExtraElements]
    public class EquipmentStockRequest
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("equipmentId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string EquipmentId { get; set; }

        [BsonElement("equipmentName")]
        public string EquipmentName { get; set; }

        [BsonElement("equipmentCode")]
        public string EquipmentCode { get; set; }

        [BsonElement("quantityRequested")]
        public int QuantityRequested { get; set; }

        [BsonElement("purpose")]
        public string Purpose { get; set; }

        [BsonElement("requestedBy")]
        public string RequestedBy { get; set; }

        [BsonElement("requestedByUserId")]
        public string RequestedByUserId { get; set; }

        [BsonElement("requestDate")]
        public DateTime RequestDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Pending ? ApprovedByFinance ? Completed / Rejected
        /// </summary>
        [BsonElement("status")]
        public string Status { get; set; } = "Pending";

        [BsonElement("financeApprovedBy")]
        public string FinanceApprovedBy { get; set; }

        [BsonElement("financeApprovedAt")]
        public DateTime? FinanceApprovedAt { get; set; }

        [BsonElement("financeNotes")]
        public string FinanceNotes { get; set; }

        [BsonElement("estimatedCost")]
        [BsonRepresentation(BsonType.Decimal128)]
        public decimal? EstimatedCost { get; set; }

        [BsonElement("approvedCost")]
        [BsonRepresentation(BsonType.Decimal128)]
        public decimal? ApprovedCost { get; set; }

        [BsonElement("rejectionReason")]
        public string RejectionReason { get; set; }

        [BsonElement("priority")]
        public string Priority { get; set; } = "Normal";

        [BsonElement("expectedDeliveryDate")]
        public DateTime? ExpectedDeliveryDate { get; set; }

        [BsonElement("notes")]
        public string Notes { get; set; }

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Link to global StockRequest collection (Mongo _id)
        [BsonElement("stockRequestId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string StockRequestId { get; set; }

        [BsonIgnore]
        public string DisplayId => string.IsNullOrEmpty(Id) ? "ESR-PENDING"
            : "ESR-" + (Id.Length >= 6 ? Id.Substring(Id.Length - 6).ToUpper() : Id.ToUpper());

        [BsonIgnore]
        public string StatusBadgeClass
        {
            get
            {
                switch (Status)
                {
                    case "Pending": return "status-pending";
                    case "ApprovedByFinance": return "status-approved";
                    case "Completed": return "status-completed";
                    case "Rejected": return "status-rejected";
                    default: return "status-pending";
                }
            }
        }
    }
}
