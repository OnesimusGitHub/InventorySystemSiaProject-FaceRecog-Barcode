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

            // Build main activity list
            var list = docs.Select(doc => {
                // Build a merged details JSON string that includes employeeActivity fields when present
                string detailsStr = null;
                if (doc.Contains("details") && doc["details"].IsString)
                    detailsStr = doc["details"].AsString;
                else if (doc.Contains("Details") && doc["Details"].IsString)
                    detailsStr = doc["Details"].AsString;

                BsonDocument eaDoc = null;
                if (doc.Contains("employeeActivity") && doc["employeeActivity"].IsBsonDocument)
                    eaDoc = doc["employeeActivity"].AsBsonDocument;
                else if (doc.Contains("EmployeeActivity") && doc["EmployeeActivity"].IsBsonDocument)
                    eaDoc = doc["EmployeeActivity"].AsBsonDocument;

                if (eaDoc != null)
                {
                    var eaJson = eaDoc.ToJson();
                    if (string.IsNullOrWhiteSpace(detailsStr))
                    {
                        detailsStr = eaJson;
                    }
                    else
                    {
                        // Try merging both JSON objects so FormatActivityDetails can display both sets of fields
                        try
                        {
                            var baseObj = JObject.Parse(detailsStr);
                            var eaObj = JObject.Parse(eaJson);
                            foreach (var p in eaObj.Properties())
                            {
                                if (baseObj[p.Name] == null)
                                {
                                    baseObj[p.Name] = p.Value;
                                }
                                else
                                {
                                    // Avoid overwriting: add with employee prefix
                                    var prefixed = "employee" + char.ToUpper(p.Name[0]) + p.Name.Substring(1);
                                    if (baseObj[prefixed] == null)
                                        baseObj[prefixed] = p.Value;
                                }
                            }
                            detailsStr = baseObj.ToString(Formatting.None);
                        }
                        catch
                        {
                            // Fallback envelope
                            var env = new JObject();
                            env["details"] = detailsStr;
                            env["employeeActivity"] = JObject.Parse(eaJson);
                            detailsStr = env.ToString(Formatting.None);
                        }
                    }
                }

                // Prefer top-level fields, but fall back to employeeActivity when missing
                string userName = null;
                if (doc.Contains("userName") && doc["userName"].IsString) userName = doc["userName"].AsString;
                else if (doc.Contains("UserName") && doc["UserName"].IsString) userName = doc["UserName"].AsString;
                else if (eaDoc != null && eaDoc.Contains("username") && eaDoc["username"].IsString) userName = eaDoc["username"].AsString;

                string entityType = null;
                if (doc.Contains("entityType") && doc["entityType"].IsString) entityType = doc["entityType"].AsString;
                else if (doc.Contains("EntityType") && doc["EntityType"].IsString) entityType = doc["EntityType"].AsString;
                else if (eaDoc != null && eaDoc.Contains("itemType") && eaDoc["itemType"].IsString) entityType = eaDoc["itemType"].AsString;

                string entityId = null;
                if (doc.Contains("entityId") && doc["entityId"].IsString) entityId = doc["entityId"].AsString;
                else if (doc.Contains("EntityId") && doc["EntityId"].IsString) entityId = doc["EntityId"].AsString;
                else if (eaDoc != null && eaDoc.Contains("itemId"))
                {
                    var v = eaDoc["itemId"];
                    if (v.IsObjectId) entityId = v.AsObjectId.ToString();
                    else if (v.IsString) entityId = v.AsString;
                    else entityId = v.ToString();
                }

                string actionVal = null;
                if (doc.Contains("action") && doc["action"].IsString) actionVal = doc["action"].AsString;
                else if (doc.Contains("Action") && doc["Action"].IsString) actionVal = doc["Action"].AsString;

                return new
                {
                    Timestamp =
                        (doc.Contains("Timestamp") && doc["Timestamp"].IsValidDateTime) ? doc["Timestamp"].ToUniversalTime() :
                        (doc.Contains("timestamp") && doc["timestamp"].IsValidDateTime) ? doc["timestamp"].ToUniversalTime() :
                        (DateTime?)null,
                    UserName = userName,
                    Action = actionVal,
                    EntityType = entityType,
                    EntityId = entityId,
                    Details = detailsStr,
                    Id = doc.Contains("_id") ? doc["_id"].ToString() : null
                };
            })
    .Where(x => x.Timestamp != null)
    .OrderByDescending(x => x.Timestamp)
    .ThenByDescending(x => x.Id)
    .ToList();

            gvActivity.DataSource = list;
            gvActivity.DataBind();

            // Build and bind separate EmployeeActivity table from its own collection
            try
            {
                var eaColl = DatabaseHelper.GetCollection<BsonDocument>("EmployeeActivities");
                var ebuilder = Builders<BsonDocument>.Filter;
                var efilter = ebuilder.Empty;
                if (startDate.HasValue || endDate.HasValue)
                {
                    var start = startDate.HasValue ? startDate.Value.Date : DateTime.MinValue;
                    var end = endDate.HasValue ? endDate.Value.Date.AddDays(1).AddTicks(-1) : DateTime.MaxValue;
                    efilter = ebuilder.And(ebuilder.Gte("createdAt", start), ebuilder.Lte("createdAt", end));
                }

                var eaDocs = eaColl.Find(efilter).Limit(200).ToList();

                var employeeList = eaDocs.Select(eaDoc => {
                    DateTime? createdAt = null;
                    if (eaDoc.Contains("createdAt") && eaDoc["createdAt"].IsValidDateTime) createdAt = eaDoc["createdAt"].ToUniversalTime();

                    string username = eaDoc.Contains("username") && eaDoc["username"].IsString ? eaDoc["username"].AsString : null;

                    string employeeId = null;
                    if (eaDoc.Contains("employeeId"))
                    {
                        var v = eaDoc["employeeId"];
                        if (v.IsObjectId) employeeId = v.AsObjectId.ToString();
                        else if (v.IsString) employeeId = v.AsString;
                        else employeeId = v.ToString();
                    }

                    string actionType = eaDoc.Contains("actionType") && eaDoc["actionType"].IsString ? eaDoc["actionType"].AsString : (eaDoc.Contains("action") && eaDoc["action"].IsString ? eaDoc["action"].AsString : null);

                    string itemType = eaDoc.Contains("itemType") && eaDoc["itemType"].IsString ? eaDoc["itemType"].AsString : null;

                    string itemId = null;
                    if (eaDoc.Contains("itemId"))
                    {
                        var v = eaDoc["itemId"];
                        if (v.IsObjectId) itemId = v.AsObjectId.ToString();
                        else if (v.IsString) itemId = v.AsString;
                        else itemId = v.ToString();
                    }

                    string sku = eaDoc.Contains("sku") && eaDoc["sku"].IsString ? eaDoc["sku"].AsString : null;

                    // Use robust helper to extract quantity from various shapes and nests
                    int? quantity = null;
                    try
                    {
                        quantity = GetQuantityFromBson(eaDoc);
                    }
                    catch { /* swallow - quantity remains null */ }

                    string details = eaDoc.Contains("details") && eaDoc["details"].IsString ? eaDoc["details"].AsString : null;

                    return new
                    {
                        CreatedAt = createdAt,
                        Username = username,
                        EmployeeId = employeeId,
                        ActionType = actionType,
                        ItemType = itemType,
                        ItemId = itemId,
                        SKU = sku,
                        Quantity = quantity,
                        Details = details,
                        Id = eaDoc.Contains("_id") ? eaDoc["_id"].ToString() : null
                    };
                })
                .Where(x => x != null && x.CreatedAt != null)
                .OrderByDescending(x => x.CreatedAt)
                .ThenByDescending(x => x.Id)
                .ToList();

                gvEmployeeActivity.DataSource = employeeList;
                gvEmployeeActivity.DataBind();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Failed to load EmployeeActivities collection: " + ex.Message);
                gvEmployeeActivity.DataSource = null;
                gvEmployeeActivity.DataBind();
            }
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

        // New helper: robust quantity lookup in BsonDocument (top-level, nested, arrays, details JSON)
        private int? GetQuantityFromBson(BsonDocument doc)
        {
            if (doc == null) return null;

            // Try common top-level names first
            string[] names = new[] { "quantity", "Quantity", "qty", "Qty", "amount", "Amount", "count", "Count" };
            foreach (var name in names)
            {
                if (doc.Contains(name))
                {
                    var v = doc[name];
                    var parsed = ParseBsonNumeric(v);
                    if (parsed.HasValue) return parsed;
                }
            }

            // Recursively search nested documents/arrays
            int? recursiveResult = SearchBsonForQuantity(doc);
            if (recursiveResult.HasValue) return recursiveResult;

            // Fallback: parse details JSON if present
            string detailsStr = null;
            if (doc.Contains("details") && doc["details"].IsString) detailsStr = doc["details"].AsString;
            else if (doc.Contains("Details") && doc["Details"].IsString) detailsStr = doc["Details"].AsString;

            if (!string.IsNullOrWhiteSpace(detailsStr))
            {
                try
                {
                    var detObj = JObject.Parse(detailsStr);
                    var qtyProp = detObj.Descendants().OfType<JProperty>()
                        .FirstOrDefault(p => string.Equals(p.Name, "quantity", StringComparison.OrdinalIgnoreCase)
                                          || string.Equals(p.Name, "qty", StringComparison.OrdinalIgnoreCase)
                                          || string.Equals(p.Name, "amount", StringComparison.OrdinalIgnoreCase)
                                          || string.Equals(p.Name, "count", StringComparison.OrdinalIgnoreCase));
                    if (qtyProp != null)
                    {
                        var token = qtyProp.Value;
                        if (token.Type == JTokenType.Integer) return token.ToObject<int>();
                        if (token.Type == JTokenType.Float) return Convert.ToInt32(token.ToObject<double>());
                        if (token.Type == JTokenType.String && int.TryParse(token.ToString(), out int q)) return q;
                    }
                }
                catch { /* ignore parse errors */ }
            }

            return null;
        }

        private int? SearchBsonForQuantity(BsonValue val)
        {
            if (val == null || val.IsBsonNull) return null;

            if (val.IsBsonDocument)
            {
                var bd = val.AsBsonDocument;
                foreach (var el in bd)
                {
                    if (el.Name.Equals("quantity", StringComparison.OrdinalIgnoreCase)
                        || el.Name.Equals("qty", StringComparison.OrdinalIgnoreCase)
                        || el.Name.Equals("amount", StringComparison.OrdinalIgnoreCase)
                        || el.Name.Equals("count", StringComparison.OrdinalIgnoreCase))
                    {
                        var parsed = ParseBsonNumeric(el.Value);
                        if (parsed.HasValue) return parsed;
                    }

                    // recurse
                    var rec = SearchBsonForQuantity(el.Value);
                    if (rec.HasValue) return rec;
                }
            }
            else if (val.IsBsonArray)
            {
                var arr = val.AsBsonArray;
                foreach (var item in arr)
                {
                    var rec = SearchBsonForQuantity(item);
                    if (rec.HasValue) return rec;
                }
            }
            else
            {
                // atomic value: attempt parse if name not available (rare here)
                var parsed = ParseBsonNumeric(val);
                if (parsed.HasValue) return parsed;
            }

            return null;
        }

        private int? ParseBsonNumeric(BsonValue v)
        {
            if (v == null || v.IsBsonNull) return null;
            try
            {
                if (v.IsInt32) return v.AsInt32;
                if (v.IsInt64) return (int?)v.AsInt64;
                if (v.IsDouble) return Convert.ToInt32(v.AsDouble);
                if (v.IsDecimal128) return Convert.ToInt32(Decimal128.ToDecimal(v.AsDecimal128));
                if (v.IsString && int.TryParse(v.AsString, out int q)) return q;
            }
            catch { /* ignore conversion errors */ }
            return null;
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