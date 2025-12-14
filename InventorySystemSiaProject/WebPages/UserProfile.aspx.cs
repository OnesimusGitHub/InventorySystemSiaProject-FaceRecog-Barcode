using System;
using System.Web.UI;
using InventorySystemSiaProject.Models;
using System.Collections.Generic;
using MongoDB.Driver;
using System.Configuration;
using Newtonsoft.Json.Linq;
using System.Text;

namespace InventorySystemSiaProject.WebPages
{
    public partial class UserProfile : Page
    {
        private string MongoConnectionString => ConfigurationManager.ConnectionStrings["MongoDBConnection"].ConnectionString;
        private string DatabaseName => ConfigurationManager.AppSettings["MongoDBDatabase"];
        private string UsersCollectionName => ConfigurationManager.AppSettings["UsersCollection"];
        private string ActivityLogCollectionName => ConfigurationManager.AppSettings["ActivityLogCollection"];

        protected void Page_Load(object sender, EventArgs e)
        {
            var userId = Session["UserId"] != null ? Session["UserId"].ToString() : null;
            if (userId == null)
            {
                Response.Redirect("/WebPages/Login.aspx");
                return;
            }

            var user = GetUserById(userId);
            if (user != null)
            {
                lblAvatar.Text = user.FirstName.Length > 0 ? user.FirstName.Substring(0, 1).ToUpper() : "U";
                lblFullName.Text = user.Name;
                lblEmail.Text = user.Email;
                lblEmail2.Text = user.Email;
                lblFirstName.Text = user.FirstName;
                lblLastName.Text = user.LastName;
                lblAge.Text = ""; // Age not in User model, leave blank or calculate if you add DOB
                lblAddress.Text = ""; // Address not in User model, leave blank or add property
                lblMemberSince.Text = user.CreatedAt.ToLocalTime().ToString("MMMM dd, yyyy");
            }

            var logs = GetActivityLogsByUserId(userId);
            if (logs != null && logs.Count > 0)
            {
                rptActivityLog.DataSource = logs;
                rptActivityLog.DataBind();
                lblNoActivity.Visible = false;
            }
            else
            {
                lblNoActivity.Visible = true;
            }
        }

        private User GetUserById(string userId)
        {
            var client = new MongoClient(MongoConnectionString);
            var database = client.GetDatabase(DatabaseName);
            var users = database.GetCollection<User>(UsersCollectionName);
            return users.Find(u => u.Id == userId).FirstOrDefault();
        }

        private List<ActivityLogDisplay> GetActivityLogsByUserId(string userId)
        {
            var client = new MongoClient(MongoConnectionString);
            var database = client.GetDatabase(DatabaseName);
            var logsCollection = database.GetCollection<ActivityLog>(ActivityLogCollectionName);
            var logs = logsCollection.Find(l => l.UserId == userId)
                .SortByDescending(l => l.Timestamp)
                .Limit(20)
                .ToList();
            var displayLogs = new List<ActivityLogDisplay>();
            foreach (var log in logs)
            {
                displayLogs.Add(new ActivityLogDisplay
                {
                    Date = log.Timestamp.ToLocalTime().ToString("MMMM dd, yyyy HH:mm"),
                    Description = FormatActivityLog(log)
                });
            }
            return displayLogs;
        }

        private string FormatActivityLog(ActivityLog log)
        {
            if (string.IsNullOrWhiteSpace(log.Details))
                return $"<span class='activity-badge'>{log.Action}</span>";

            try
            {
                if (log.Action != null && log.Action.ToLower().Contains("create"))
                {
                    var detailsObj = JObject.Parse(log.Details);
                    var sb = new StringBuilder();
                    sb.Append("<div class='activity-add-card'>");
                    sb.Append("<span class='activity-badge add'>Add Ingredient</span>");
                    sb.Append("<div class='activity-add-title'>" + (detailsObj["ingredientName"] ?? "") + "</div>");
                    sb.Append("<div class='activity-add-fields'>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Unit:</span><span class='activity-value'>" + (detailsObj["unit"] ?? "") + "</span></div>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Cost Per Unit:</span><span class='activity-value'>₱" + (detailsObj["costPerUnit"] ?? "") + "</span></div>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Current Stock:</span><span class='activity-value'>" + (detailsObj["currentStock"] ?? "") + "</span></div>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Minimum Stock:</span><span class='activity-value'>" + (detailsObj["minimumStock"] ?? "") + "</span></div>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Supplier Id:</span><span class='activity-value'>" + (detailsObj["supplierId"] ?? "<i>Not set</i>") + "</span></div>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Supplier Name:</span><span class='activity-value'>" + (detailsObj["supplierName"] ?? "") + "</span></div>");
                    sb.Append("<div class='activity-row'><span class='activity-label'>Total Value:</span><span class='activity-value'>" + (detailsObj["totalValue"] ?? "") + "</span></div>");
                    sb.Append("</div></div>");
                    return sb.ToString();
                }
                else if (log.Action != null && log.Action.ToLower().Contains("update"))
                {
                    var detailsObj = JObject.Parse(log.Details);
                    var sb = new StringBuilder();
                    sb.Append("<span class='activity-badge update'>Update Ingredient</span>");
                    sb.Append("<div class='activity-fields'><span class='activity-label'>Item:</span> " + (detailsObj["ingredientName"] ?? "") + "</div>");
                    sb.Append("<span class='activity-label' style='color:#b04a6a;'>CHANGES</span>");
                    sb.Append("<div class='activity-changes'>");

                    // Prefer explicit changes diff if present
                    var changes = detailsObj["changes"] as JObject;
                    var before = changes != null ? changes["before"] as JObject : detailsObj["before"] as JObject;
                    var after = changes != null ? changes["after"] as JObject : detailsObj["after"] as JObject;

                    if (before != null && after != null)
                    {
                        var diffHtml = BuildChangesDiff(before, after);
                        sb.Append(diffHtml);
                    }
                    else
                    {
                        // Fallback to generic rendering
                        sb.Append("<div class='activity-before'><b>Before</b><br/>" + FormatIngredientDetails(detailsObj["before"]) + "</div>");
                        sb.Append("<div class='activity-after'><b>After</b><br/>" + FormatIngredientDetails(detailsObj["after"]) + "</div>");
                    }

                    sb.Append("</div>");
                    sb.Append("<div class='activity-fields'><span class='activity-label'>Supplier:</span> " + (detailsObj["supplierName"] ?? "") + "</div>");
                    return sb.ToString();
                }
                else if (log.Action != null && log.Action.ToLower().Contains("delete"))
                {
                    var detailsObj = JObject.Parse(log.Details);
                    var sb = new StringBuilder();
                    sb.Append("<span class='activity-badge delete'>Delete</span>");
                    sb.Append("<div class='activity-delete'>");
                    if (detailsObj["before"] != null)
                    {
                        sb.Append("<span class='activity-label'>Before:</span> " + detailsObj["before"].ToString() + "<br/>");
                    }
                    sb.Append("<span class='activity-label'>Action:</span> " + (detailsObj["action"] != null ? detailsObj["action"].ToString() : "HardDelete") + "<br/>");
                    sb.Append("</div>");
                    return sb.ToString();
                }
                else
                {
                    // Try to parse as JSON and display key-value pairs
                    var detailsObj = JObject.Parse(log.Details);
                    var sb = new StringBuilder();
                    sb.Append($"<div class='activity-add-card'><span class='activity-badge'>{log.Action}</span>");
                    sb.Append("<div class='activity-add-fields'>");
                    foreach (var prop in detailsObj)
                    {
                        sb.Append($"<div class='activity-row'><span class='activity-label'>{prop.Key}:</span> <span class='activity-value'>{prop.Value}</span></div>");
                    }
                    sb.Append("</div></div>");
                    return sb.ToString();
                }
            }
            catch
            {
                // If not JSON, fallback to simple message
                return $"<div class='activity-add-card'><span class='activity-badge'>{log.Action}</span><div class='activity-row'><span class='activity-label'>Details:</span> <span class='activity-value'>Unavailable</span></div></div>";
            }
        }

        // Build an HTML diff of fields that actually changed
        private string BuildChangesDiff(JObject before, JObject after)
        {
            var beforeHtml = new StringBuilder();
            var afterHtml = new StringBuilder();

            foreach (var prop in after.Properties())
            {
                var key = prop.Name;
                var beforeVal = before.ContainsKey(key) ? before[key]?.ToString() : string.Empty;
                var afterVal = after[key]?.ToString();
                if (!string.Equals(beforeVal, afterVal, StringComparison.Ordinal))
                {
                    beforeHtml.Append($"<div><span class='activity-label'>{key}:</span> {beforeVal}</div>");
                    afterHtml.Append($"<div><span class='activity-label'>{key}:</span> {afterVal}</div>");
                }
            }

            var wrapper = new StringBuilder();
            wrapper.Append("<div class='activity-before'><b>Before</b><br/>");
            wrapper.Append(beforeHtml.Length > 0 ? beforeHtml.ToString() : "<i>No differences detected</i>");
            wrapper.Append("</div>");
            wrapper.Append("<div class='activity-after'><b>After</b><br/>");
            wrapper.Append(afterHtml.Length > 0 ? afterHtml.ToString() : "<i>No differences detected</i>");
            wrapper.Append("</div>");
            return wrapper.ToString();
        }

        private string FormatIngredientDetails(JToken details)
        {
            if (details == null) return "";
            var sb = new StringBuilder();
            sb.Append("<span class='activity-label'>Ingredient Name:</span> " + (details["ingredientName"] != null ? details["ingredientName"].ToString() : "") + "<br/>");
            sb.Append("<span class='activity-label'>Unit:</span> " + (details["unit"] != null ? details["unit"].ToString() : "") + "<br/>");
            sb.Append("<span class='activity-label'>Cost Per Unit:</span> ₱" + (details["costPerUnit"] != null ? details["costPerUnit"].ToString() : "") + "<br/>");
            sb.Append("<span class='activity-label'>Current Stock:</span> " + (details["currentStock"] != null ? details["currentStock"].ToString() : "") + "<br/>");
            sb.Append("<span class='activity-label'>Minimum Stock:</span> " + (details["minimumStock"] != null ? details["minimumStock"].ToString() : "") + "<br/>");
            sb.Append("<span class='activity-label'>Supplier Id:</span> " + (details["supplierId"] != null ? details["supplierId"].ToString() : "<i>Not set</i>") + "<br/>");
            sb.Append("<span class='activity-label'>Total Value:</span> " + (details["totalValue"] != null ? details["totalValue"].ToString() : "") + "<br/>");
            return sb.ToString();
        }

        public class ActivityLogDisplay
        {
            public string Date { get; set; }
            public string Description { get; set; }
        }
    }
}
