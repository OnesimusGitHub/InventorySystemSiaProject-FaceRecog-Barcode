using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Models
{
    public class VariantImg
    {
        [BsonId]
        public ObjectId Id { get; set; } // Primary key

        [BsonElement("productVariantId")]
        public ObjectId ProductVariantId { get; set; } // Foreign key to ProductVariant

        [BsonElement("variantImgUrls")]
        public List<string> VariantImgUrls { get; set; }
    }
}
