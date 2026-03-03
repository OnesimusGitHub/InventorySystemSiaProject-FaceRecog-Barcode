using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;

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

        [BsonElement("sku")]
        public string SKU { get; set; }

        [BsonElement("size")]
        public string Size { get; set; }

        [BsonElement("color")]
        public string Color { get; set; }

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

        [BsonElement("description")]
        public string Description { get; set; }

        [BsonElement("location")]
        public string Location { get; set; }

        [BsonElement("shelfLifeYears")]
        public int? ShelfLifeYears { get; set; }

        // ✅ CHANGED: Store images as raw binary data array
        [BsonElement("variantImgUrls")]
        [BsonIgnoreIfNull]
        public List<byte[]> VariantImgUrls { get; set; }

        [BsonElement("CreatedAt")]
        public DateTime CreatedAt { get; set; }

        [BsonElement("UpdatedAt")]
        public DateTime? UpdatedAt { get; set; }

        [BsonElement("Status")]
        public string Status { get; set; } = "Active";

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        [BsonElement("variantImg")]
        public string VariantImg { get; set; }

        [BsonIgnore]
        public bool IsLowStock => StockQuantity <= MinimumStock;

        [BsonIgnore]
        public decimal TotalValue => Price * StockQuantity;
    }

    // ✅ REMOVE: No longer needed
    // public class VariantImage { ... }

    public class VariantImage
    {
        [BsonElement("imageData")]
        public byte[] ImageData { get; set; }

        [BsonElement("contentType")]
        public string ContentType { get; set; }

        [BsonElement("fileName")]
        public string FileName { get; set; }

        [BsonElement("uploadedAt")]
        public DateTime UploadedAt { get; set; }
    }
}