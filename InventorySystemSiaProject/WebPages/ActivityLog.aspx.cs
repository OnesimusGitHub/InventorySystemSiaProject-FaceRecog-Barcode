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
                
                // Parse JSON
                var jsonObj = JObject.Parse(detailsJson);
                
                var sb = new StringBuilder();
                sb.Append("<div class='details-container'>");
                
                // Add action badge
                string badgeClass = "badge-create";
                if (actionText.Contains("Update")) badgeClass = "badge-update";
                else if (actionText.Contains("Delete")) badgeClass = "badge-delete";
                
                sb.AppendFormat("<div class='action-badge {0}'>{1}</div>", badgeClass, actionText);
                
                // Check if this is an update action with before/after
                if (jsonObj["changes"] != null)
                {
                    FormatUpdateDetails(jsonObj, sb);
                }
                else if (jsonObj["action"] != null && jsonObj["action"].ToString() == "Create")
                {
                    FormatCreateDetails(jsonObj, sb);
                }
                else if (jsonObj["action"] != null && jsonObj["action"].ToString() == "Delete")
                {
                    FormatDeleteDetails(jsonObj, sb);
                }
                else
                {
                    // Generic format for other types
                    FormatGenericDetails(jsonObj, sb);
                }
                
                sb.Append("</div>");
                return sb.ToString();
            }
            catch (JsonException)
            {
                // If not valid JSON, return formatted plain text
                return $"<div class='details-container'><div class='detail-item'>{System.Web.HttpUtility.HtmlEncode(details.ToString())}</div></div>";
            }
        }

        private void FormatUpdateDetails(JObject jsonObj, StringBuilder sb)
        {
            var changes = jsonObj["changes"];
            var before = changes["before"];
            var after = changes["after"];
            
            // Add entity name if available
            if (jsonObj["ingredientName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Item:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["ingredientName"]);
            }
            else if (jsonObj["productName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Item:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["productName"]);
            }
            
            sb.Append("<div class='detail-section'>");
            sb.Append("<div class='detail-section-title'>Changes</div>");
            sb.Append("<div class='changes-grid'>");
            
            // Before column
            sb.Append("<div class='before-after before-column'>");
            sb.Append("<div class='column-title'>?? Before</div>");
            if (before != null)
            {
                foreach (var prop in before.Children<JProperty>())
                {
                    sb.AppendFormat("<div class='change-item'><span class='change-label'>{0}:</span> {1}</div>", 
                        FormatPropertyName(prop.Name), 
                        FormatPropertyValue(prop.Value));
                }
            }
            sb.Append("</div>");
            
            // After column
            sb.Append("<div class='before-after after-column'>");
            sb.Append("<div class='column-title'>? After</div>");
            if (after != null)
            {
                foreach (var prop in after.Children<JProperty>())
                {
                    sb.AppendFormat("<div class='change-item'><span class='change-label'>{0}:</span> {1}</div>", 
                        FormatPropertyName(prop.Name), 
                        FormatPropertyValue(prop.Value));
                }
            }
            sb.Append("</div>");
            
            sb.Append("</div>"); // close changes-grid
            sb.Append("</div>"); // close detail-section
            
            // Add supplier name if available
            if (jsonObj["supplierName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Supplier:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["supplierName"]);
            }
        }

        private void FormatCreateDetails(JObject jsonObj, StringBuilder sb)
        {
            // Add entity name
            if (jsonObj["ingredientName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Ingredient:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["ingredientName"]);
            }
            else if (jsonObj["productName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Product:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["productName"]);
            }
            
            sb.Append("<div class='detail-section'>");
            
            // Display all properties except action and timestamp
            foreach (var prop in jsonObj.Properties())
            {
                if (prop.Name != "action" && prop.Name != "timestamp")
                {
                    sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", 
                        FormatPropertyName(prop.Name), 
                        FormatPropertyValue(prop.Value));
                }
            }
            
            sb.Append("</div>");
        }

        private void FormatDeleteDetails(JObject jsonObj, StringBuilder sb)
        {
            // Add entity name
            if (jsonObj["ingredientName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Ingredient:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["ingredientName"]);
            }
            else if (jsonObj["productName"] != null)
            {
                sb.AppendFormat("<div class='detail-item'><span class='detail-label'>Product:</span> <span class='detail-value'>{0}</span></div>", 
                    jsonObj["productName"]);
            }
            
            sb.Append("<div class='detail-section'>");
            sb.Append("<div class='detail-section-title'>Deleted Information</div>");
            
            // Display all properties except action and timestamp
            foreach (var prop in jsonObj.Properties())
            {
                if (prop.Name != "action" && prop.Name != "timestamp")
                {
                    sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", 
                        FormatPropertyName(prop.Name), 
                        FormatPropertyValue(prop.Value));
                }
            }
            
            sb.Append("</div>");
        }

        private void FormatGenericDetails(JObject jsonObj, StringBuilder sb)
        {
            foreach (var prop in jsonObj.Properties())
            {
                if (prop.Name != "timestamp")
                {
                    sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", 
                        FormatPropertyName(prop.Name), 
                        FormatPropertyValue(prop.Value));
                }
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
