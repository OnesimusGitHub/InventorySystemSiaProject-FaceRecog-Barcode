using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace InventorySystemSiaProject.Models
{
    public class User
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("name")]
        public string Name { get; set; }

        [BsonElement("email")]
        public string Email { get; set; }

        [BsonElement("passwordHash")]
        public string PasswordHash { get; set; }

        [BsonElement("role")]
        public string Role { get; set; } = "User"; // Default role

        [BsonElement("faceEncoding")]
        public string FaceEncoding { get; set; }

        [BsonElement("shortPass")]
        public string ShortPass { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [BsonElement("isActive")]
        public bool IsActive { get; set; } = true;

        [BsonElement("lastLogin")]
        public DateTime? LastLogin { get; set; }


        [BsonIgnore]
        public string FirstName 
        { 
            get => Name?.Split(' ')[0] ?? "";
            set => Name = string.IsNullOrEmpty(Name) ? value : $"{value} {LastName}";
        }

        [BsonIgnore]
        public string LastName 
        { 
            get => Name?.Contains(" ") == true ? Name.Split(' ')[1] : "";
            set => Name = string.IsNullOrEmpty(Name) ? $"{FirstName} {value}" : $"{FirstName} {value}";
        }

        [BsonIgnore]
        public string Password 
        { 
            get => PasswordHash;
            set => PasswordHash = value;
        }
    }
}