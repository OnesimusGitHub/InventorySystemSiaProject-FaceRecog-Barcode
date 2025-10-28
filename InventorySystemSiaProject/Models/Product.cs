using System;
using System.Collections.Generic;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    [BsonIgnoreExtraElements]
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
        [BsonRepresentation(BsonType.Decimal128)]
        public decimal ProductVal { get; set; }

        [BsonElement("supplierId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string SupplierId { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;


        [BsonIgnore]
        public List<ProductIngredient> ProductIngredients { get; set; } = new List<ProductIngredient>();

        [BsonIgnore]
        public Supplier Supplier { get; set; }

        
        public Product()
        {
          
            CreatedAt = DateTime.UtcNow;
            IsActive = true;
            ProductIngredients = new List<ProductIngredient>();
            
            // Ensure these are not null
            ProductName = string.Empty;
            ProductDesc = string.Empty;
            ProductCategory = string.Empty;
            BaseIngredients = string.Empty;
            ProductImg = "/Content/images/sample-generic.png";
            SupplierId = string.Empty;
            ProductVal = 0m;
        }

       
        public bool IsValid()
        {
            return !string.IsNullOrWhiteSpace(ProductName) && 
                   !string.IsNullOrWhiteSpace(ProductCategory);
        }


        public void PrepareForInsertion()
        {
           
            CreatedAt = DateTime.UtcNow;
            IsActive = true;
            
           
            if (string.IsNullOrWhiteSpace(ProductImg))
                ProductImg = "/Content/images/sample-generic.png";
            
            if (string.IsNullOrWhiteSpace(ProductDesc))
                ProductDesc = string.Empty;
            
            if (string.IsNullOrWhiteSpace(BaseIngredients))
                BaseIngredients = string.Empty;
            
            if (string.IsNullOrWhiteSpace(SupplierId))
                SupplierId = string.Empty;
        }
    }
}