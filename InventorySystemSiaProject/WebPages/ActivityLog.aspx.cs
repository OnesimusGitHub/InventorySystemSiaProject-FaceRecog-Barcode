using System;
using System.Linq;
using System.Web.UI;
using System.Text;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ActivityLogPage : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
            if (!IsPostBack)
            {
                BindData();
            }
        }

        private void BindData(DateTime? startDate = null, DateTime? endDate = null)
        {
            var coll = DatabaseHelper.GetActivityLogCollection();
            var filter = Builders<Models.ActivityLog>.Filter.Empty;

            if (startDate.HasValue || endDate.HasValue)
            {
                var builder = Builders<Models.ActivityLog>.Filter;
                if (startDate.HasValue && endDate.HasValue)
                {
                    filter = builder.Gte("Timestamp", startDate.Value.Date)
                        & builder.Lte("Timestamp", endDate.Value.Date.AddDays(1).AddTicks(-1));
                }
                else if (startDate.HasValue)
                {
                    filter = builder.Gte("Timestamp", startDate.Value.Date);
                }
                else if (endDate.HasValue)
                {
                    filter = builder.Lte("Timestamp", endDate.Value.Date.AddDays(1).AddTicks(-1));
                }
            }

            var list = coll.Find(filter)
                           .SortByDescending(a => a.Timestamp)
                           .Limit(200)
                           .ToList();
            gvActivity.DataSource = list;
            gvActivity.DataBind();
        }

        protected void btnFilterDate_Click(object sender, EventArgs e)
        {
            DateTime? startDate = null;
            DateTime? endDate = null;
            DateTime temp;
            if (DateTime.TryParse(txtStartDate.Text, out temp))
                startDate = temp;
            if (DateTime.TryParse(txtEndDate.Text, out temp))
                endDate = temp;
            BindData(startDate, endDate);
        }

        protected string FormatActivityDetails(object details, object action)
        {
            if (details == null || string.IsNullOrWhiteSpace(details.ToString()))
            {
                return "<div class='details-container'>No details available</div>";
            }

            try
            {
                string detailsJson = details.ToString();
                string actionText = action?.ToString() ?? "";
                var jsonObj = JObject.Parse(detailsJson);
                var sb = new StringBuilder();
                sb.Append("<div class='details-container'>");
                // Only show the main action and its fields
                if (actionText.ToLower().Contains("create") || (jsonObj["action"] != null && jsonObj["action"].ToString().ToLower() == "create"))
                {
                    sb.Append("<div class='action-badge badge-create'>Add Ingredient</div>");
                    if (jsonObj["ingredientName"] != null)
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Ingredient:</span> <span class='detail-value'>{0}</span></div>", jsonObj["ingredientName"]);
                    foreach (var prop in jsonObj.Properties())
                    {
                        if (prop.Name == "action" || prop.Name == "ingredientName" || prop.Name == "timestamp") continue;
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                    }
                }
                else if (actionText.ToLower().Contains("update") || (jsonObj["action"] != null && jsonObj["action"].ToString().ToLower() == "update"))
                {
                    sb.Append("<div class='action-badge badge-update'>Update Ingredient</div>");
                    if (jsonObj["ingredientName"] != null)
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Ingredient:</span> <span class='detail-value'>{0}</span></div>", jsonObj["ingredientName"]);
                    if (jsonObj["changes"] != null)
                    {
                        var changes = jsonObj["changes"];
                        var before = changes["before"];
                        var after = changes["after"];
                        sb.Append("<div class='detail-section'><div class='detail-section-title'>Changes</div><div class='changes-grid'>");
                        sb.Append("<div class='before-after before-column'><div class='column-title'>Before</div>");
                        if (before != null)
                        {
                            foreach (var prop in before.Children<JProperty>())
                            {
                                sb.AppendFormat("<div class='change-item'><span class='change-label'>{0}:</span> {1}</div>", FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                            }
                        }
                        sb.Append("</div>");
                        sb.Append("<div class='before-after after-column'><div class='column-title'>After</div>");
                        if (after != null)
                        {
                            foreach (var prop in after.Children<JProperty>())
                            {
                                sb.AppendFormat("<div class='change-item'><span class='change-label'>{0}:</span> {1}</div>", FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                            }
                        }
                        sb.Append("</div></div></div>");
                    }
                }
                else if (actionText.ToLower().Contains("delete") || (jsonObj["action"] != null && jsonObj["action"].ToString().ToLower() == "delete"))
                {
                    sb.Append("<div class='action-badge badge-delete'>Delete Ingredient</div>");
                    if (jsonObj["ingredientName"] != null)
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Ingredient:</span> <span class='detail-value'>{0}</span></div>", jsonObj["ingredientName"]);
                    foreach (var prop in jsonObj.Properties())
                    {
                        if (prop.Name == "action" || prop.Name == "ingredientName" || prop.Name == "timestamp") continue;
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                    }
                }
                else
                {
                    // Fallback: just show all fields
                    foreach (var prop in jsonObj.Properties())
                    {
                        if (prop.Name == "timestamp") continue;
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                    }
                }
                sb.Append("</div>");
                return sb.ToString();
            }
            catch (JsonException)
            {
                return $"<div class='details-container'><div class='detail-item'>{System.Web.HttpUtility.HtmlEncode(details.ToString())}</div></div>";
            }
        }

        private string FormatPropertyName(string name)
        {
            // Convert camelCase to Title Case with spaces
            if (string.IsNullOrEmpty(name)) return name;
            
            var sb = new StringBuilder();
            sb.Append(char.ToUpper(name[0]));
            
            for (int i = 1; i < name.Length; i++)
            {
                if (char.IsUpper(name[i]))
                {
                    sb.Append(' ');
                }
                sb.Append(name[i]);
            }
            
            return sb.ToString();
        }

        private string FormatPropertyValue(JToken value)
        {
            if (value == null || value.Type == JTokenType.Null)
            {
                return "<em>Not set</em>";
            }
            
            string strValue = value.ToString();
            
            // Format currency values
            if (decimal.TryParse(strValue, out decimal decValue) && 
                (value.Path.Contains("cost") || value.Path.Contains("price") || value.Path.Contains("value")))
            {
                return $"?{decValue:N2}";
            }
            
            // Format numbers
            if (decimal.TryParse(strValue, out decValue))
            {
                return decValue.ToString("N2");
            }
            
            // Format dates
            if (DateTime.TryParse(strValue, out DateTime dateValue))
            {
                return dateValue.ToString("yyyy-MM-dd HH:mm:ss");
            }
            
            return System.Web.HttpUtility.HtmlEncode(strValue);
        }
    }
}
