using System;
using System.Web;
using System.Collections.Generic;
using System.Linq;
using System.Web.Script.Serialization;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using System.Text.RegularExpressions;

namespace InventorySystemSiaProject.Handlers
{
    public class SearchInventoryEmployees : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Charset = "utf-8";
            var serializer = new JavaScriptSerializer();
            
            try
            {
                string q = (context.Request["q"] ?? "").Trim();
                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] Query: '{q}'");
                
                if (string.IsNullOrWhiteSpace(q) || q.Length < 2)
                {
                    context.Response.StatusCode = 200;
                    context.Response.Write(serializer.Serialize(new { error = "Query too short", results = new List<object>() }));
                    return;
                }

                // Get HR connection string directly
                var hrConnString = System.Configuration.ConfigurationManager.ConnectionStrings["HumanResourcesConnection"]?.ConnectionString;
                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] HR Connection configured: {!string.IsNullOrEmpty(hrConnString)}");
                
                if (string.IsNullOrEmpty(hrConnString))
                {
                    System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] ERROR: Connection string not found");
                    context.Response.StatusCode = 500;
                    context.Response.Write(serializer.Serialize(new { error = "Database connection not configured", results = new List<object>() }));
                    return;
                }

                // Create direct connection
                var settings = MongoClientSettings.FromConnectionString(hrConnString);
                settings.ConnectTimeout = TimeSpan.FromSeconds(10);
                settings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
                var client = new MongoClient(settings);
                var db = client.GetDatabase("HumanResourcesDB");
                var col = db.GetCollection<Employee>("Employees");

                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] Connected to HumanResourcesDB.Employees");

                // Count total
                var totalCount = col.CountDocuments(FilterDefinition<Employee>.Empty);
                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] Total employees: {totalCount}");

                // Search: OR (FirstName, LastName, Email) AND Inventory department
                var nameFilter = Builders<Employee>.Filter.Or(
                    Builders<Employee>.Filter.Regex(e => e.FirstName, new BsonRegularExpression(q, "i")),
                    Builders<Employee>.Filter.Regex(e => e.LastName, new BsonRegularExpression(q, "i")),
                    Builders<Employee>.Filter.Regex(e => e.Email, new BsonRegularExpression(q, "i"))
                );

                var deptFilter = Builders<Employee>.Filter.Eq(e => e.Department, "Inventory");
                var combinedFilter = Builders<Employee>.Filter.And(deptFilter, nameFilter);

                var employees = col.Find(combinedFilter)
                    .SortBy(e => e.FirstName)
                    .Limit(20)
                    .ToList();

                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] Found {employees.Count} matching employees");

                var results = new List<object>();
                foreach (var emp in employees)
                {
                    System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] Match: {emp.FirstName} {emp.LastName} - {emp.Email} ({emp.Department})");
                    
                    results.Add(new
                    {
                        id = emp.Id ?? "",
                        firstName = emp.FirstName ?? "",
                        lastName = emp.LastName ?? "",
                        name = string.Join(" ", new[] { emp.FirstName, emp.MiddleName, emp.LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim(),
                        email = emp.Email ?? "",
                        role = emp.Role ?? "",
                        department = emp.Department ?? "",
                        isEmailVerified = false
                    });
                }

                context.Response.StatusCode = 200;
                context.Response.Write(serializer.Serialize(new { success = true, results = results, count = results.Count }));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] ERROR: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[SearchInventoryEmployees] STACK: {ex.StackTrace}");
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { error = ex.Message, results = new List<object>() }));
            }
        }

        public bool IsReusable => false;
    }
}
