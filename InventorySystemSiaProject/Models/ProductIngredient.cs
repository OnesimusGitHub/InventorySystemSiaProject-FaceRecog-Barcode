using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class ProductIngredient
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("productId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductId { get; set; }

        [BsonElement("ingredientId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string IngredientId { get; set; }

        [BsonElement("quantityRequired")]
        public decimal QuantityRequired { get; set; }

        [BsonElement("unit")]
        public string Unit { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Navigation properties (not stored in MongoDB)
        [BsonIgnore]
        public Product Product { get; set; }

        [BsonIgnore]
        public Ingredient Ingredient { get; set; }

        // Calculated property
        [BsonIgnore]
        public decimal TotalCost => QuantityRequired * (Ingredient?.CostPerUnit ?? 0);
    }
}