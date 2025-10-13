using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    /// <summary>
    /// Represents a supplier in the inventory system
    /// </summary>
    [BsonIgnoreExtraElements]
    public class Supplier
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string SupplierID { get; set; }

        [BsonElement("supName")]
        public string SupName { get; set; }

        [BsonElement("supContactPer")]
        public string SupContactPer { get; set; }

        [BsonElement("supAddress")]
        public string SupAddress { get; set; }

        [BsonElement("supContactNo")]
        public string SupContactNo { get; set; }

        [BsonElement("supEmail")]
        public string SupEmail { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("updatedAt")]
        public DateTime? UpdatedAt { get; set; }

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// Constructor to ensure proper initialization
        /// </summary>
        public Supplier()
        {
            CreatedAt = DateTime.UtcNow;
            IsActive = true;
            SupName = string.Empty;
            SupContactPer = string.Empty;
            SupAddress = string.Empty;
            SupContactNo = string.Empty;
            SupEmail = string.Empty;
        }

        /// <summary>
        /// Validates the supplier data before insertion or update
        /// </summary>
        /// <returns>True if valid, false otherwise</returns>
        public bool IsValid()
        {
            return !string.IsNullOrWhiteSpace(SupName) &&
                   !string.IsNullOrWhiteSpace(SupContactNo);
        }

        /// <summary>
        /// Validates email format
        /// </summary>
        /// <returns>True if valid email format, false otherwise</returns>
        public bool IsValidEmail()
        {
            if (string.IsNullOrWhiteSpace(SupEmail))
                return false;

            try
            {
                var addr = new System.Net.Mail.MailAddress(SupEmail);
                return addr.Address == SupEmail;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Prepares the supplier object for MongoDB insertion
        /// </summary>
        public void PrepareForInsertion()
        {
            CreatedAt = DateTime.UtcNow;
            IsActive = true;

            // Trim whitespace from all string properties
            SupName = SupName?.Trim() ?? string.Empty;
            SupContactPer = SupContactPer?.Trim() ?? string.Empty;
            SupAddress = SupAddress?.Trim() ?? string.Empty;
            SupContactNo = SupContactNo?.Trim() ?? string.Empty;
            SupEmail = SupEmail?.Trim() ?? string.Empty;
        }

        /// <summary>
        /// Prepares the supplier object for MongoDB update
        /// </summary>
        public void PrepareForUpdate()
        {
            UpdatedAt = DateTime.UtcNow;

            // Trim whitespace from all string properties
            SupName = SupName?.Trim() ?? string.Empty;
            SupContactPer = SupContactPer?.Trim() ?? string.Empty;
            SupAddress = SupAddress?.Trim() ?? string.Empty;
            SupContactNo = SupContactNo?.Trim() ?? string.Empty;
            SupEmail = SupEmail?.Trim() ?? string.Empty;
        }

        /// <summary>
        /// Returns a formatted display string for the supplier
        /// </summary>
        /// <returns>Formatted supplier display string</returns>
        public override string ToString()
        {
            return $"{SupName} ({SupContactNo})";
        }
    }
}
