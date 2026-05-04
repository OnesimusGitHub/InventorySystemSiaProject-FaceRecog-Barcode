using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class EmployeeActivity
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("username")]
        public string Username { get; set; }

        [BsonElement("employeeId")]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonIgnoreIfNull]
        public string EmployeeId { get; set; }

        [BsonElement("actionType")]
        public string ActionType { get; set; }

        [BsonElement("itemType")]
        public string ItemType { get; set; }

        [BsonElement("itemId")]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonIgnoreIfNull]
        public string ItemId { get; set; }

        [BsonElement("sku")]
        [BsonIgnoreIfNull]
        public string SKU { get; set; }

        [BsonElement("quantity")]
        [BsonIgnoreIfNull]
        public int? Quantity { get; set; }

        [BsonElement("packageId")]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonIgnoreIfNull]
        public string PackageId { get; set; }

        [BsonElement("details")]
        [BsonIgnoreIfNull]
        public string Details { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
