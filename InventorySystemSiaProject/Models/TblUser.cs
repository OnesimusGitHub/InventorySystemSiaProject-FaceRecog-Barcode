using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;

namespace InventorySystemSiaProject.Models
{
    /// <summary>
    /// Model for tbl_user collection from db_shessentials database
    /// </summary>
    public class TblUser
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("first_name")]
        public string FirstName { get; set; }

        [BsonElement("middle_name")]
        public string MiddleName { get; set; }

        [BsonElement("last_name")]
        public string LastName { get; set; }

        [BsonElement("address")]
        public BsonDocument Address { get; set; }

        [BsonElement("zip_code")]
        public string ZipCode { get; set; }

        [BsonElement("email")]
        public string Email { get; set; }

        [BsonElement("phone")]
        public string Phone { get; set; }

        [BsonElement("password_hash")]
        public string PasswordHash { get; set; }

        [BsonElement("is_email_verified")]
        public bool IsEmailVerified { get; set; }

        [BsonElement("created_at")]
        public DateTime CreatedAt { get; set; }

        [BsonElement("updated_at")]
        public DateTime UpdatedAt { get; set; }

        [BsonElement("terms_accepted")]
        public bool TermsAccepted { get; set; }

        [BsonElement("role")]
        public string Role { get; set; }

        [BsonElement("employee_id")]
        public string EmployeeId { get; set; }

        [BsonElement("department")]
        public string Department { get; set; }

        // Computed property for full name
        [BsonIgnore]
        public string FullName
        {
            get
            {
                var parts = new[] { FirstName, MiddleName, LastName };
                return string.Join(" ", Array.FindAll(parts, s => !string.IsNullOrWhiteSpace(s)));
            }
        }

        // Computed property to determine if user is admin - MUST have [BsonIgnore]
        [BsonIgnore]
        public bool IsAdmin
        {
            get
            {
                return Role?.Equals("admin", StringComparison.OrdinalIgnoreCase) == true || 
                       Role?.Contains("Admin") == true;
            }
        }

        // Computed property for active status (based on email verification) - MUST have [BsonIgnore]
        [BsonIgnore]
        public bool IsActive
        {
            get
            {
                return IsEmailVerified;
            }
        }

        // Helper property to get address as string
        [BsonIgnore]
        public string AddressString
        {
            get
            {
                if (Address == null) return string.Empty;
                try
                {
                    return Address.ToString();
                }
                catch
                {
                    return string.Empty;
                }
            }
        }
    }
}
