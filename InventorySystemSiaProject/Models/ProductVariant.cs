using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class ProductVariant
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("productId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductId { get; set; }

        [BsonElement("variantName")]
        public string VariantName { get; set; }

        [BsonElement("size")]
        public string Size { get; set; }

        [BsonElement("color")]
        public string Color { get; set; }

        [BsonElement("sku")]
        public string SKU { get; set; }

        [BsonElement("price")]
        public decimal Price { get; set; }

        [BsonElement("stockQuantity")]
        public int StockQuantity { get; set; }

        [BsonElement("minimumStock")]
        public int MinimumStock { get; set; }

        [BsonElement("weight")]
        public decimal? Weight { get; set; }

        [BsonElement("dimensions")]
        public string Dimensions { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Navigation property (not stored in MongoDB)
        [BsonIgnore]
        public Product Product { get; set; }

        // Calculated properties
        [BsonIgnore]
        public bool IsLowStock => StockQuantity <= MinimumStock;

        [BsonIgnore]
        public decimal TotalValue => StockQuantity * Price;
    }
}