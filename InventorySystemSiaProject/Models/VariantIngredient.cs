using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class VariantIngredient
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("variantId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string VariantId { get; set; }

        [BsonElement("ingredientId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string IngredientId { get; set; }

        [BsonElement("quantityRequired")]
        public decimal QuantityRequired { get; set; }

        [BsonElement("unit")]
        public string Unit { get; set; }

        [BsonElement("costPerUnit")]
        public decimal CostPerUnit { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Navigation properties (not stored in MongoDB)
        [BsonIgnore]
        public ProductVariant Variant { get; set; }

        [BsonIgnore]
        public Ingredient Ingredient { get; set; }

        // Calculated properties
        [BsonIgnore]
        public decimal TotalCost => QuantityRequired * CostPerUnit;

        [BsonIgnore]
        public decimal TotalIngredientCost => QuantityRequired * (Ingredient?.CostPerUnit ?? CostPerUnit);
    }

    // New collection: StockRequest
    [BsonIgnoreExtraElements]
    public class StockRequest
    {
        // Acts as RequestID
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string RequestID { get; set; }

        // Foreign key to ProductVariants collection
        [BsonElement("productVariantID")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductVariantID { get; set; }

        [BsonElement("quantityRequested")]
        public int QuantityRequested { get; set; }

        [BsonElement("requestDate")]
        public DateTime RequestDate { get; set; } = DateTime.UtcNow;

        [BsonElement("requestStatus")]
        public string RequestStatus { get; set; } = "Pending"; // Pending | Approved | Rejected | Fulfilled

        [BsonElement("instructions")]
        public string Instructions { get; set; }

        [BsonElement("requestedBy")]
        public string RequestedBy { get; set; }
    }
}