using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Models
{
    [BsonIgnoreExtraElements]
    public class Equipment
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("equipmentName")]
        public string EquipmentName { get; set; }

        [BsonElement("equipmentType")]
        public string EquipmentType { get; set; }

        [BsonElement("equipmentCode")]
        public string EquipmentCode { get; set; }

        [BsonElement("brand")]
        public string Brand { get; set; }

        [BsonElement("model")]
        public string Model { get; set; }

        [BsonElement("description")]
        public string Description { get; set; }

        [BsonElement("location")]
        public string Location { get; set; }

        [BsonElement("stockQuantity")]
        public int StockQuantity { get; set; }

        [BsonElement("minimumStock")]
        public int MinimumStock { get; set; } = 5;

        [BsonElement("unitCost")]
        [BsonRepresentation(BsonType.Decimal128)]
        public decimal UnitCost { get; set; }

        [BsonElement("serialNumber")]
        public string SerialNumber { get; set; }

        [BsonElement("purchaseDate")]
        public DateTime? PurchaseDate { get; set; }

        [BsonElement("warrantyExpiry")]
        public DateTime? WarrantyExpiry { get; set; }

        [BsonElement("condition")]
        public string Condition { get; set; } = "Good";

        [BsonElement("status")]
        public string Status { get; set; } = "Active";

        [BsonElement("equipmentImg")]
        public byte[] EquipmentImg { get; set; }

        [BsonElement("equipmentImgContentType")]
        public string EquipmentImgContentType { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime? UpdatedAt { get; set; }

        [BsonIgnore]
        public bool IsLowStock => StockQuantity <= MinimumStock;

        [BsonIgnore]
        public string StockStatus
        {
            get
            {
                if (StockQuantity <= 0) return "Out of Stock";
                if (StockQuantity <= MinimumStock) return "Low Stock";
                if (StockQuantity <= MinimumStock * 2) return "Moderate";
                return "Adequate";
            }
        }

        [BsonIgnore]
        public string EquipmentImgBase64
        {
            get
            {
                if (EquipmentImg == null || EquipmentImg.Length == 0) return null;
                return "data:" + (EquipmentImgContentType ?? "image/jpeg") + ";base64," + Convert.ToBase64String(EquipmentImg);
            }
        }
    }
}
