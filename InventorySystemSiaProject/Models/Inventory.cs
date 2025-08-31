using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class Inventory
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("itemName")]
        public string ItemName { get; set; }

        [BsonElement("description")]
        public string Description { get; set; }

        [BsonElement("category")]
        public string Category { get; set; }

        [BsonElement("quantity")]
        public int Quantity { get; set; }

        [BsonElement("unitPrice")]
        public decimal UnitPrice { get; set; }

        [BsonElement("totalValue")]
        public decimal TotalValue { get; set; }

        [BsonElement("supplier")]
        public string Supplier { get; set; }

        [BsonElement("location")]
        public string Location { get; set; }

        [BsonElement("minimumStock")]
        public int MinimumStock { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("createdBy")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string CreatedBy { get; set; }

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Calculated property
        [BsonIgnore]
        public bool IsLowStock => Quantity <= MinimumStock;
    }
}