using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class Ingredient
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("ingredientName")]
        public string IngredientName { get; set; }

        [BsonElement("unit")]
        public string Unit { get; set; }

        [BsonElement("costPerUnit")]
        public decimal CostPerUnit { get; set; }

        [BsonElement("currentStock")]
        public decimal CurrentStock { get; set; }

        [BsonElement("minimumStock")]
        public decimal MinimumStock { get; set; }

        [BsonElement("supplier")]
        public string Supplier { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Calculated property
        [BsonIgnore]
        public bool IsLowStock => CurrentStock <= MinimumStock;

        [BsonIgnore]
        public decimal TotalValue => CurrentStock * CostPerUnit;
    }
}