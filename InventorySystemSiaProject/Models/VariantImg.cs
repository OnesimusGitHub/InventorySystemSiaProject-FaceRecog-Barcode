using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class VariantImg
    {
        [BsonId]
        public ObjectId Id { get; set; } // Primary key

        [BsonElement("productVariantId")]
        public ObjectId ProductVariantId { get; set; } // Foreign key to ProductVariant

        [BsonElement("imgUrl")]
        public string ImgUrl { get; set; } // Image URL
    }
}
