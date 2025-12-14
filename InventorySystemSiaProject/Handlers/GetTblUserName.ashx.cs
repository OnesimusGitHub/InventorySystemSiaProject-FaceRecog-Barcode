using System;
using System.Web;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using System.Text.RegularExpressions;
using System.Linq;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    public class GetTblUserName : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                context.Response.ContentType = "application/json";
                var q = (context.Request["q"] ?? string.Empty).Trim();
                if (string.IsNullOrWhiteSpace(q))
                {
                    context.Response.Write("[]");
                    return;
                }

                var col = DatabaseHelper.GetTblUserCollection();
                var escaped = Regex.Escape(q);

                // starts-with on first_name, then fill with contains across first/middle/last/email
                var startsWith = col
                    .Find(Builders<TblUser>.Filter.Regex(u => u.FirstName, new MongoDB.Bson.BsonRegularExpression("^" + escaped, "i")))
                    .SortBy(u => u.FirstName)
                    .Limit(20)
                    .ToList();

                var results = startsWith;
                if (results.Count < 20)
                {
                    var remaining = 20 - results.Count;
                    var containsFilter = Builders<TblUser>.Filter.Or(
                        Builders<TblUser>.Filter.Regex(u => u.FirstName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                        Builders<TblUser>.Filter.Regex(u => u.MiddleName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                        Builders<TblUser>.Filter.Regex(u => u.LastName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                        Builders<TblUser>.Filter.Regex(u => u.Email, new MongoDB.Bson.BsonRegularExpression(q, "i"))
                    );
                    var excludeIds = results.Select(r => r.Id).ToList();
                    if (excludeIds.Count > 0)
                    {
                        containsFilter &= Builders<TblUser>.Filter.Nin(u => u.Id, excludeIds);
                    }
                    var contains = col
                        .Find(containsFilter)
                        .SortBy(u => u.FirstName)
                        .Limit(remaining)
                        .ToList();
                    results.AddRange(contains);
                }

                var payload = results.Select(u => new
                {
                    u.Id,
                    Name = string.Join(" ", new[] { u.FirstName, u.MiddleName, u.LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim(),
                    Email = u.Email ?? string.Empty,
                    IsEmailVerified = u.IsEmailVerified,
                    Role = u.Role ?? string.Empty
                }).ToList();

                var json = new JavaScriptSerializer().Serialize(payload);
                context.Response.Write(json);
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.ContentType = "application/json";
                context.Response.Write(new JavaScriptSerializer().Serialize(new { error = ex.Message }));
            }
        }

        public bool IsReusable => true;
    }
}
