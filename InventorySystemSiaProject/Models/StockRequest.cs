using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    /// <summary>
    /// Represents a stock request for product replenishment from suppliers
    /// </summary>
    [BsonIgnoreExtraElements]
    public class StockRequest
    {
        /// <summary>
        /// Unique auto-generated identifier (e.g., SR-0001 format will be generated from ObjectId)
        /// </summary>
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string RequestID { get; set; }

        /// <summary>
        /// Foreign key to ProductVariants collection
        /// </summary>
        [BsonElement("productVariantID")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductVariantID { get; set; }

        /// <summary>
        /// Foreign key to Products collection (denormalized for easier queries)
        /// </summary>
        [BsonElement("productID")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductID { get; set; }

        /// <summary>
        /// Foreign key to Suppliers collection
        /// </summary>
        [BsonElement("supplierID")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string SupplierID { get; set; }

        /// <summary>
        /// Quantity requested for stock replenishment
        /// </summary>
        [BsonElement("quantityRequested")]
        public int QuantityRequested { get; set; }

        /// <summary>
        /// Date when the request was made
        /// </summary>
        [BsonElement("requestDate")]
        public DateTime RequestDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Name of the employee/staff making the request
        /// </summary>
        [BsonElement("requestedBy")]
        public string RequestedBy { get; set; }

        /// <summary>
        /// User ID of the employee making the request
        /// </summary>
        [BsonElement("requestedByUserId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string RequestedByUserId { get; set; }

        /// <summary>
        /// Current status of the request: Pending, Approved, Rejected, Completed
        /// </summary>
        [BsonElement("requestStatus")]
        public string RequestStatus { get; set; } = "Pending";

        /// <summary>
        /// Additional notes or instructions for the stock request
        /// </summary>
        [BsonElement("instructions")]
        public string Instructions { get; set; }

        /// <summary>
        /// Expected delivery date (optional)
        /// </summary>
        [BsonElement("expectedDeliveryDate")]
        public DateTime? ExpectedDeliveryDate { get; set; }

        /// <summary>
        /// Actual delivery date (set when status is Completed)
        /// </summary>
        [BsonElement("actualDeliveryDate")]
        public DateTime? ActualDeliveryDate { get; set; }

        /// <summary>
        /// Date when the request status was last updated
        /// </summary>
        [BsonElement("statusUpdatedDate")]
        public DateTime? StatusUpdatedDate { get; set; }

        /// <summary>
        /// User who approved/rejected the request
        /// </summary>
        [BsonElement("processedBy")]
        public string ProcessedBy { get; set; }

        /// <summary>
        /// User ID who approved/rejected the request
        /// </summary>
        [BsonElement("processedByUserId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProcessedByUserId { get; set; }

        /// <summary>
        /// Reason for rejection (if status is Rejected)
        /// </summary>
        [BsonElement("rejectionReason")]
        public string RejectionReason { get; set; }

        /// <summary>
        /// Total cost of the stock request (quantity * unit price)
        /// </summary>
        [BsonElement("totalCost")]
        [BsonRepresentation(BsonType.Decimal128)]
        public decimal? TotalCost { get; set; }

        /// <summary>
        /// Unit price at the time of request
        /// </summary>
        [BsonElement("unitPrice")]
        [BsonRepresentation(BsonType.Decimal128)]
        public decimal? UnitPrice { get; set; }

        /// <summary>
        /// Current stock quantity at the time of request
        /// </summary>
        [BsonElement("currentStockAtRequest")]
        public int CurrentStockAtRequest { get; set; }

        /// <summary>
        /// Minimum stock level that triggered the request
        /// </summary>
        [BsonElement("minimumStockLevel")]
        public int MinimumStockLevel { get; set; }

        /// <summary>
        /// Email confirmation sent to supplier
        /// </summary>
        [BsonElement("emailSent")]
        public bool EmailSent { get; set; } = false;

        /// <summary>
        /// Date when email was sent to supplier
        /// </summary>
        [BsonElement("emailSentDate")]
        public DateTime? EmailSentDate { get; set; }

        /// <summary>
        /// Priority level: Low, Normal, High, Urgent
        /// </summary>
        [BsonElement("priority")]
        public string Priority { get; set; } = "Normal";

        /// <summary>
        /// Timestamp when the record was created
        /// </summary>
        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Timestamp when the record was last updated
        /// </summary>
        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Soft delete flag
        /// </summary>
        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Navigation properties (not stored in MongoDB)
        [BsonIgnore]
        public ProductVariant ProductVariant { get; set; }

        [BsonIgnore]
        public Product Product { get; set; }

        [BsonIgnore]
        public Supplier Supplier { get; set; }

        // Calculated properties
        /// <summary>
        /// Gets a human-readable request ID (e.g., SR-0001)
        /// </summary>
        [BsonIgnore]
        public string DisplayRequestID
        {
            get
            {
                if (string.IsNullOrEmpty(RequestID))
                    return "SR-PENDING";

                // Take last 4 characters of ObjectId and format as SR-XXXX
                var suffix = RequestID.Length >= 4 ? RequestID.Substring(RequestID.Length - 4) : RequestID;
                return $"SR-{suffix.ToUpper()}";
            }
        }

        /// <summary>
        /// Gets the status badge color class
        /// </summary>
        [BsonIgnore]
        public string StatusBadgeClass
        {
            get
            {
                switch (RequestStatus?.ToLower())
                {
                    case "pending":
                        return "badge-warning";
                    case "approved":
                        return "badge-info";
                    case "completed":
                        return "badge-success";
                    case "rejected":
                        return "badge-danger";
                    default:
                        return "badge-secondary";
                }
            }
        }

        /// <summary>
        /// Gets the priority badge color class
        /// </summary>
        [BsonIgnore]
        public string PriorityBadgeClass
        {
            get
            {
                switch (Priority?.ToLower())
                {
                    case "urgent":
                        return "badge-danger";
                    case "high":
                        return "badge-warning";
                    case "normal":
                        return "badge-info";
                    case "low":
                        return "badge-secondary";
                    default:
                        return "badge-secondary";
                }
            }
        }

        /// <summary>
        /// Checks if the request is overdue (more than 7 days in Pending status)
        /// </summary>
        [BsonIgnore]
        public bool IsOverdue
        {
            get
            {
                if (RequestStatus != "Pending")
                    return false;

                return (DateTime.UtcNow - RequestDate).TotalDays > 7;
            }
        }

        /// <summary>
        /// Checks if the request was recently created (within last 24 hours)
        /// </summary>
        [BsonIgnore]
        public bool IsRecent
        {
            get
            {
                return (DateTime.UtcNow - CreatedAt).TotalHours <= 24;
            }
        }

        /// <summary>
        /// Calculates the total cost if not already set
        /// </summary>
        [BsonIgnore]
        public decimal CalculatedTotalCost
        {
            get
            {
                if (TotalCost.HasValue)
                    return TotalCost.Value;

                if (UnitPrice.HasValue)
                    return UnitPrice.Value * QuantityRequested;

                return 0;
            }
        }

        // Constructor
        public StockRequest()
        {
            RequestDate = DateTime.UtcNow;
            CreatedAt = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
            RequestStatus = "Pending";
            Priority = "Normal";
            IsActive = true;
            EmailSent = false;
        }

        /// <summary>
        /// Validates the stock request before insertion
        /// </summary>
        public bool IsValid()
        {
            return !string.IsNullOrWhiteSpace(ProductVariantID) &&
                   !string.IsNullOrWhiteSpace(SupplierID) &&
                   QuantityRequested > 0 &&
                   !string.IsNullOrWhiteSpace(RequestedBy);
        }

        /// <summary>
        /// Prepares the stock request for MongoDB insertion
        /// </summary>
        public void PrepareForInsertion()
        {
            RequestDate = DateTime.UtcNow;
            CreatedAt = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
            IsActive = true;

            if (string.IsNullOrWhiteSpace(RequestStatus))
                RequestStatus = "Pending";

            if (string.IsNullOrWhiteSpace(Priority))
                Priority = "Normal";

            // Trim string properties
            RequestedBy = RequestedBy?.Trim() ?? string.Empty;
            Instructions = Instructions?.Trim() ?? string.Empty;
            ProcessedBy = ProcessedBy?.Trim() ?? string.Empty;
            RejectionReason = RejectionReason?.Trim() ?? string.Empty;
        }

        /// <summary>
        /// Prepares the stock request for MongoDB update
        /// </summary>
        public void PrepareForUpdate()
        {
            UpdatedAt = DateTime.UtcNow;

            // Trim string properties
            RequestedBy = RequestedBy?.Trim() ?? string.Empty;
            Instructions = Instructions?.Trim() ?? string.Empty;
            ProcessedBy = ProcessedBy?.Trim() ?? string.Empty;
            RejectionReason = RejectionReason?.Trim() ?? string.Empty;
        }

        /// <summary>
        /// Approves the stock request
        /// </summary>
        public void Approve(string processedBy, string processedByUserId)
        {
            RequestStatus = "Approved";
            ProcessedBy = processedBy;
            ProcessedByUserId = processedByUserId;
            StatusUpdatedDate = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Rejects the stock request
        /// </summary>
        public void Reject(string processedBy, string processedByUserId, string reason)
        {
            RequestStatus = "Rejected";
            ProcessedBy = processedBy;
            ProcessedByUserId = processedByUserId;
            RejectionReason = reason;
            StatusUpdatedDate = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Marks the stock request as completed
        /// </summary>
        public void Complete(DateTime? deliveryDate = null)
        {
            RequestStatus = "Completed";
            ActualDeliveryDate = deliveryDate ?? DateTime.UtcNow;
            StatusUpdatedDate = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Marks that email was sent to supplier
        /// </summary>
        public void MarkEmailSent()
        {
            EmailSent = true;
            EmailSentDate = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
        }
    }
}
