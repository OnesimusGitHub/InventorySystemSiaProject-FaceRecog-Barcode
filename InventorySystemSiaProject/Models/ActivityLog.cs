using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class ActivityLog
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("timestamp")]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        [BsonElement("userId")]
        public string UserId { get; set; }

        [BsonElement("userName")]
        public string UserName { get; set; }

        [BsonElement("action")]
        public string Action { get; set; } // Create, Update, Delete, Revert

        [BsonElement("entityType")]
        public string EntityType { get; set; } // Product, ProductVariant, User, etc.

        [BsonElement("entityId")]
        public string EntityId { get; set; }

        [BsonElement("details")]
        public string Details { get; set; } // JSON string of before/after or summary

        [BsonElement("revertedFromId")]
        public string RevertedFromId { get; set; }
    }
}
