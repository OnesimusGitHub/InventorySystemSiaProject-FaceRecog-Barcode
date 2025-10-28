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
        public string Action { get; set; } 

        [BsonElement("entityType")]
        public string EntityType { get; set; }

        [BsonElement("entityId")]
        public string EntityId { get; set; }

        [BsonElement("details")]
        public string Details { get; set; } 

        [BsonElement("revertedFromId")]
        public string RevertedFromId { get; set; }
    }
}
