using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Models
{
    [BsonIgnoreExtraElements] // ✅ Ignore any fields in MongoDB that aren't in this class
    public class Product
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("productName")]
        public string productName { get; set; }

        [BsonElement("productCategory")]
        public string productCategory { get; set; }

        [BsonElement("productDesc")]
        public string productDesc { get; set; }

        // ✅ BLOB STORAGE: Product image as binary data
        [BsonElement("productImg")]
        public byte[] productImg { get; set; }

        [BsonElement("ProductImgContentType")]
        public string ProductImgContentType { get; set; } // e.g., "image/jpeg"

        [BsonElement("productVal")]
        public decimal productVal { get; set; }

        [BsonElement("createdAt")]
        public DateTime createdAt { get; set; }

        [BsonElement("updatedAt")]
        public DateTime? updatedAt { get; set; }

        [BsonElement("status")]
        public string status { get; set; } = "Active";

        // ✅ ADDED: Supplier as string (supplier name or ID)
        [BsonElement("Supplier")]
        public string Supplier { get; set; }

        // ✅ ADDED: BaseIngredients for backward compatibility
        // This can store ingredient IDs or names as a comma-separated string
        [BsonElement("baseIngredients")]
        public string baseIngredients { get; set; }

        [BsonElement("isApprove")]
        [BsonIgnoreIfNull]
        public bool? isApprove { get; set; }

        // ✅ Property to check if product data is valid
        [BsonIgnore]
        public bool IsValid =>
            !string.IsNullOrWhiteSpace(productName) &&
            !string.IsNullOrWhiteSpace(productCategory) &&
            productVal >= 0;

        // ✅ Method to prepare product for database insertion
        public void PrepareForInsertion()
        {
            if (createdAt == default(DateTime))
                createdAt = DateTime.UtcNow;

            updatedAt = DateTime.UtcNow;

            if (string.IsNullOrWhiteSpace(status))
                status = "Active";
        }

        // ✅ Helper property to get ProductImg as base64 string (for display purposes)
        [BsonIgnore]
        public string ProductImgBase64
        {
            get
            {
                if (productImg == null || productImg.Length == 0)
                    return null;
                return "data:" + (ProductImgContentType ?? "image/jpeg") + ";base64," + Convert.ToBase64String(productImg);
            }
        }
    }
}