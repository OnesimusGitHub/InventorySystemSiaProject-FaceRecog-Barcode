using System;
using System.Linq;
using System.Web.UI;
using System.Text;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;
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
            var coll = DatabaseHelper.GetActivityLogCollectionRaw();
            var builder = Builders<BsonDocument>.Filter;
            var filter = builder.Empty;

            // Date filter: support both 'Timestamp' and 'timestamp' fields
            if (startDate.HasValue || endDate.HasValue)
            {
                var start = startDate.HasValue ? startDate.Value.Date : DateTime.MinValue;
                var end = endDate.HasValue ? endDate.Value.Date.AddDays(1).AddTicks(-1) : DateTime.MaxValue;
                // Filter for both possible timestamp fields
                var timestampFilter = builder.And(
                    builder.Gte("Timestamp", start),
                    builder.Lte("Timestamp", end)
                );
                var altTimestampFilter = builder.And(
                    builder.Gte("timestamp", start),
                    builder.Lte("timestamp", end)
                );
                filter = builder.Or(timestampFilter, altTimestampFilter);
            }

            var docs = coll.Find(filter)
                 .Limit(200)
                 .ToList();

            var list = docs.Select(doc => new {
                Timestamp =
(doc.Contains("Timestamp") && doc["Timestamp"].IsValidDateTime) ? doc["Timestamp"].ToUniversalTime() :
(doc.Contains("timestamp") && doc["timestamp"].IsValidDateTime) ? doc["timestamp"].ToUniversalTime() :
(DateTime?)null,
                UserName = doc.Contains("userName") && doc["userName"].IsString ? doc["userName"].AsString
    : doc.Contains("UserName") && doc["UserName"].IsString ? doc["UserName"].AsString : null,
                Action = doc.Contains("action") && doc["action"].IsString ? doc["action"].AsString
    : doc.Contains("Action") && doc["Action"].IsString ? doc["Action"].AsString : null,
                EntityType = doc.Contains("entityType") && doc["entityType"].IsString ? doc["entityType"].AsString
    : doc.Contains("EntityType") && doc["EntityType"].IsString ? doc["EntityType"].AsString : null,
                EntityId = doc.Contains("entityId") && doc["entityId"].IsString ? doc["entityId"].AsString
    : doc.Contains("EntityId") && doc["EntityId"].IsString ? doc["EntityId"].AsString : null,
                Details = doc.Contains("details") && doc["details"].IsString ? doc["details"].AsString
    : doc.Contains("Details") && doc["Details"].IsString ? doc["Details"].AsString : null,
                Id = doc.Contains("_id") ? doc["_id"].ToString() : null
    })
    .Where(x => x.Timestamp != null)
    .OrderByDescending(x => x.Timestamp)
    .ThenByDescending(x => x.Id)
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

        public string FormatActivityDetails(object details, object action, object entityTypeObj)
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

                // Get entity type from details JSON, grid column, or fallback
                string entityType = jsonObj["entityType"]?.ToString() ?? jsonObj["EntityType"]?.ToString();
                if (string.IsNullOrEmpty(entityType) && entityTypeObj != null)
                {
                    entityType = entityTypeObj.ToString();
                }
                string entityTypeLabel = FormatEntityTypeLabel(entityType);

                // Find the main label field for the entity (try common names, else first string property)
                string mainLabel = null;
                string mainLabelDisplay = null;
                string[] possibleLabels = { "ingredientName", "ProductName", "VariantName", "Name", "Product", "Variant" };
                foreach (var label in possibleLabels)
                {
                    if (jsonObj[label] != null && jsonObj[label].Type == JTokenType.String)
                    {
                        mainLabel = label;
                        mainLabelDisplay = $"<span style='color:#a64d79;font-weight:700;'>" + FormatPropertyName(label) + ":</span> <span style='color:#333;font-weight:400;'>" + System.Web.HttpUtility.HtmlEncode(jsonObj[label].ToString()) + "</span>";
                        break;
                    }
                }
                // If no common label found, use first string property
                if (mainLabelDisplay == null)
                {
                    var firstStringProp = jsonObj.Properties().FirstOrDefault(p => p.Value.Type == JTokenType.String && p.Name != "action" && p.Name != "timestamp");
                    if (firstStringProp != null)
                    {
                        mainLabel = firstStringProp.Name;
                        mainLabelDisplay = $"<span style='color:#a64d79;font-weight:700;'>" + FormatPropertyName(firstStringProp.Name) + ":</span> <span style='color:#333;font-weight:400;'>" + System.Web.HttpUtility.HtmlEncode(firstStringProp.Value.ToString()) + "</span>";
                    }
                }

                // Action badge
                string badgeClass = actionText.ToLower().Contains("create") ? "badge-create" :
                                    actionText.ToLower().Contains("update") ? "badge-update" :
                                    actionText.ToLower().Contains("delete") ? "badge-delete" : "";
                sb.Append($"<div class='action-badge {badgeClass}' style='background:#e3f2fd;padding:8px 12px;font-weight:600;font-size:16px;color:#155724;border-radius:6px;margin-bottom:6px;'>");
                sb.Append(System.Web.HttpUtility.HtmlEncode(FormatPropertyName(actionText)) + " " + entityTypeLabel);
                sb.Append("</div>");

                // Main label
                if (mainLabelDisplay != null)
                {
                    sb.Append($"<div style='margin:8px 0 12px 0;font-size:17px;'>{mainLabelDisplay}</div>");
                }

                // Changes section for updates
                if ((actionText.ToLower().Contains("update") || (jsonObj["action"] != null && jsonObj["action"].ToString().ToLower() == "update")) && jsonObj["changes"] != null)
                {
                    var changes = jsonObj["changes"];
                    var before = changes["before"];
                    var after = changes["after"];
                    sb.Append("<div style='font-weight:700;color:#a64d79;margin-bottom:6px;font-size:15px;'>CHANGES</div>");
                    sb.Append("<div style='display:flex;gap:16px;'>");
                    // Before column
                    sb.Append("<div style='background:#fff3cd;border-radius:8px;padding:16px 18px;flex:1;border-left:4px solid #ffc107;'>");
                    sb.Append("<div style='font-weight:700;font-size:14px;margin-bottom:8px;'>BEFORE</div>");
                    if (before != null)
                    {
                        foreach (var prop in before.Children<JProperty>())
                        {
                            sb.AppendFormat("<div style='margin-bottom:8px;'><span style='font-weight:700;'>{0}:</span> <span style='font-weight:400;'>{1}</span></div>",
                                FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                        }
                    }
                    sb.Append("</div>");
                    // After column
                    sb.Append("<div style='background:#d4edda;border-radius:8px;padding:16px 18px;flex:1;border-left:4px solid #28a745;'>");
                    sb.Append("<div style='font-weight:700;font-size:14px;margin-bottom:8px;'>AFTER</div>");
                    if (after != null)
                    {
                        foreach (var prop in after.Children<JProperty>())
                        {
                            sb.AppendFormat("<div style='margin-bottom:8px;'><span style='font-weight:700;'>{0}:</span> <span style='font-weight:400;'>{1}</span></div>",
                                FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                        }
                    }
                    sb.Append("</div>");
                    sb.Append("</div>");
                }
                else
                {
                    // Fallback: just show all fields
                    sb.Append("<div style='margin-top:10px;'>");
                    foreach (var prop in jsonObj.Properties())
                    {
                        if (prop.Name == "action" || prop.Name == "timestamp") continue;
                        sb.AppendFormat("<div class='detail-item'><span class='detail-label'>{0}:</span> <span class='detail-value'>{1}</span></div>", FormatPropertyName(prop.Name), FormatPropertyValue(prop.Value));
                    }
                    sb.Append("</div>");
                }
                return sb.ToString();
            }
            catch (JsonException)
            {
                return $"<div class='details-container'><div class='detail-item'>{System.Web.HttpUtility.HtmlEncode(details.ToString())}</div></div>";
            }
        }

        private string FormatEntityTypeLabel(string entityType)
        {
            if (string.IsNullOrEmpty(entityType)) return "Ingredient";
            // Convert camelCase or PascalCase to spaced Title Case
            var sb = new StringBuilder();
            sb.Append(char.ToUpper(entityType[0]));
            for (int i = 1; i < entityType.Length; i++)
            {
                if (char.IsUpper(entityType[i])) sb.Append(' ');
                sb.Append(entityType[i]);
            }
            return sb.ToString();
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
