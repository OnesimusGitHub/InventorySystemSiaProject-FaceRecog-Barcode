<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetUsers" %>
using System;
using System.Web;
using System.Collections.Generic;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    public class GetUsers : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var users = new List<object>();
            try
            {
                // MongoDB connection setup
                var mongoConnStr = System.Configuration.ConfigurationManager.ConnectionStrings["MongoDBConnection"].ConnectionString;
                var mongoDbName = System.Configuration.ConfigurationManager.AppSettings["MongoDBDatabase"];
                var client = new MongoClient(mongoConnStr);
                var db = client.GetDatabase(mongoDbName);
                var collection = db.GetCollection<User>("Users");
                var userList = collection.Find(Builders<User>.Filter.Empty).ToList();
                foreach (var u in userList)
                {
                    users.Add(new {
                        Name = u.Name,
                        Email = u.Email,
                        Role = u.Role
                    });
                }
                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(new { success = true, users = users }));
            }
            catch (Exception ex)
            {
                var serializer = new JavaScriptSerializer();
                context.Response.Write(serializer.Serialize(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
