using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    [BsonIgnoreExtraElements] 
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

        [BsonElement("description")]
        public string Description { get; set; }

        [BsonElement("size")]
        public string Size { get; set; }

        [BsonElement("color")]
        public string Color { get; set; }

        [BsonElement("sku")]
        public string SKU { get; set; }

        [BsonElement("price")]
        [BsonRepresentation(BsonType.Decimal128)] 
        public decimal Price { get; set; }

        [BsonElement("stockQuantity")]
        public int StockQuantity { get; set; }

        [BsonElement("minimumStock")]
        public int MinimumStock { get; set; }

        [BsonElement("weight")]
        [BsonRepresentation(BsonType.Decimal128)] 
        public decimal? Weight { get; set; }

        [BsonElement("dimensions")]
        public string Dimensions { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        [BsonElement("variantImg")]
        public string VariantImg { get; set; }

       
        [BsonElement("shelfLifeYears")]
        public int? ShelfLifeYears { get; set; }

    
        [BsonElement("location")]
        public string Location { get; set; }

        

        [BsonIgnore]
        public Product Product { get; set; }

      
        [BsonIgnore]
        public bool IsLowStock => StockQuantity <= MinimumStock;

        [BsonIgnore]
        public decimal TotalValue => StockQuantity * Price;

       
        public ProductVariant()
        {
           
            CreatedAt = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
            IsActive = true;
            StockQuantity = 0;
            MinimumStock = 5;
        }
    }
}