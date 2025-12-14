using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;

namespace InventorySystemSiaProject.Models
{
    public class Employee
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        [BsonElement("employeeId")]
        public string EmployeeId { get; set; }

        [BsonElement("firstName")]
        public string FirstName { get; set; }

        [BsonElement("middleName")]
        public string MiddleName { get; set; }

        [BsonElement("lastName")]
        public string LastName { get; set; }

        [BsonElement("email")]
        public string Email { get; set; }

        [BsonElement("contactNo")]
        public string ContactNo { get; set; }

        [BsonElement("address")]
        public string Address { get; set; }

        [BsonElement("age")]
        public int Age { get; set; }

        [BsonElement("birthDate")]
        public DateTime BirthDate { get; set; }

        [BsonElement("gender")]
        public string Gender { get; set; }

        [BsonElement("department")]
        public string Department { get; set; }

        [BsonElement("role")]
        public string Role { get; set; }

        [BsonElement("hireDate")]
        public DateTime HireDate { get; set; }

        [BsonElement("applicantId")]
        public string ApplicantId { get; set; }

        [BsonElement("contractType")]
        public string ContractType { get; set; }

        [BsonElement("isActive")]
        public bool IsActive { get; set; }

        // For login purposes - these might be in a separate auth collection
        [BsonElement("password")]
        public string Password { get; set; }

        [BsonElement("shortPass")]
        public string ShortPass { get; set; }

        [BsonElement("faceEncoding")]
        public string FaceEncoding { get; set; }

        // Computed property for full name
        [BsonIgnore]
        public string FullName => $"{FirstName} {MiddleName} {LastName}".Trim();

        // Computed property to determine if user is admin
        [BsonIgnore]
        public bool IsAdmin => Role?.Contains("Admin") == true || 
                               Department?.Contains("Admin") == true;
    }
}
