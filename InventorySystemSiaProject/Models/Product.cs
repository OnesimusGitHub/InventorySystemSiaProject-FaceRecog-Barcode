using System;
using System.Collections.Generic;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class Product
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("productName")]
        public string ProductName { get; set; }

        [BsonElement("productDesc")]
        public string ProductDesc { get; set; }

        [BsonElement("productCategory")]
        public string ProductCategory { get; set; }

        [BsonElement("baseIngredients")]
        public string BaseIngredients { get; set; }

        [BsonElement("productImg")]
        public string ProductImg { get; set; }

        [BsonElement("productVal")]
        public decimal ProductVal { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        // Navigation property (not stored in MongoDB but useful for application logic)
        [BsonIgnore]
        public List<ProductIngredient> ProductIngredients { get; set; } = new List<ProductIngredient>();
    }
}