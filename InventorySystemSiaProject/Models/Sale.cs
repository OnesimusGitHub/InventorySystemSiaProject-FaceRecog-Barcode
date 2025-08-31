using System;
using System.Collections.Generic;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class Sale
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("variantId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string VariantId { get; set; }

        [BsonElement("quantity")]
        public int Quantity { get; set; }

        [BsonElement("salePrice")]
        public decimal SalePrice { get; set; }

        [BsonElement("transactionDate")]
        public DateTime TransactionDate { get; set; } = DateTime.UtcNow;

        [BsonElement("customerId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string CustomerId { get; set; }

        [BsonElement("customerName")]
        public string CustomerName { get; set; }

        [BsonElement("customerContact")]
        public string CustomerContact { get; set; }

        [BsonElement("paymentMethod")]
        public string PaymentMethod { get; set; }

        [BsonElement("paymentStatus")]
        public string PaymentStatus { get; set; } = "Pending";

        [BsonElement("notes")]
        public string Notes { get; set; }

        [BsonElement("soldBy")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string SoldBy { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        [BsonElement("stockDecrementProcessed")]
        public bool StockDecrementProcessed { get; set; } = false;

        // Calculated properties
        [BsonElement("totalAmount")]
        public decimal TotalAmount => Quantity * SalePrice;

        // Navigation properties (not stored in MongoDB)
        [BsonIgnore]
        public ProductVariant Variant { get; set; }

        [BsonIgnore]
        public User SoldByUser { get; set; }

        // Backward compatibility
        [BsonIgnore]
        public DateTime SaleDate 
        { 
            get => TransactionDate; 
            set => TransactionDate = value; 
        }
    }
}