using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    [BsonIgnoreExtraElements]
    public class PackageStockEntry
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        // Package identifier (e.g. PKG-20260410-ABC123)
        [BsonElement("packageId")]
        public string PackageId { get; set; }

        [BsonElement("packageName")]
        public string PackageName { get; set; }

        // Type of item stored in the package (e.g. "ProductVariant", "Ingredient")
        [BsonElement("itemType")]
        public string ItemType { get; set; }

        // References the product or variant id (stored as ObjectId or string in DB)
        [BsonElement("itemId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ItemId { get; set; }

        [BsonElement("sku")]
        public string SKU { get; set; }

        [BsonElement("quantity")]
        public int Quantity { get; set; }

        [BsonElement("manufacturedAt")]
        [BsonDateTimeOptions(Kind = DateTimeKind.Utc)]
        public DateTime? ManufacturedAt { get; set; }

        [BsonElement("expirationAt")]
        [BsonDateTimeOptions(Kind = DateTimeKind.Utc)]
        public DateTime? ExpirationAt { get; set; }

        [BsonElement("createdAt")]
        [BsonDateTimeOptions(Kind = DateTimeKind.Utc)]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("createdByUsername")]
        public string CreatedByUsername { get; set; }

        [BsonElement("isActive")]
        [BsonIgnoreIfNull]
        public bool? IsActive { get; set; } = true;

        // Convenience property (not stored)
        [BsonIgnore]
        public bool IsExpired => ExpirationAt.HasValue && ExpirationAt.Value.ToUniversalTime() < DateTime.UtcNow;
    }
}
