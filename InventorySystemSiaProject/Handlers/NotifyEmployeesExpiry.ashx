
<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.NotifyEmployeesExpiry" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.SessionState;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Handlers
{
    // Requires session so we can inspect authentication/session safely
    public class NotifyEmployeesExpiry : IHttpHandler, IRequiresSessionState
    {
        public void ProcessRequest(HttpContext context)
        {
            // Always return JSON from this handler
            context.Response.ContentType = "application/json";

            // Prevent FormsAuthenticationModule from converting a 401 into an HTML redirect to the login page.
            // This ensures callers receive JSON (401) instead of an HTML login page.
            try
            {
                context.Response.SuppressFormsAuthenticationRedirect = true;
                context.Response.TrySkipIisCustomErrors = true;
            }
            catch
            {
                // ignore if not available for some reason
            }

            try
            {
                // Quick auth/session check — return JSON 401 rather than an HTML redirect
                bool isAuthenticated = false;
                try
                {
                    isAuthenticated = context.Request.IsAuthenticated || (context.User != null && context.User.Identity != null && context.User.Identity.IsAuthenticated);
                }
                catch { /* ignore */ }

                // If your app stores auth in Session (UserId etc.) also check it
                try
                {
                    if (!isAuthenticated)
                    {
                        if (context.Session != null && context.Session["UserId"] != null)
                        {
                            isAuthenticated = true;
                        }
                    }
                }
                catch { /* ignore */ }

                if (!isAuthenticated)
                {
                    context.Response.StatusCode = 401;
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "Not authenticated or session expired." }));
                    return;
                }

                // Read request body (expect JSON with { type: 'ingredients'|'packages', items: [...] })
                string raw;
                using (var sr = new StreamReader(context.Request.InputStream))
                    raw = sr.ReadToEnd();

                if (string.IsNullOrWhiteSpace(raw))
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "POST JSON expected (type + items)." }));
                    return;
                }

                JObject payload = null;
                try
                {
                    payload = JObject.Parse(raw);
                }
                catch (Exception)
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "Invalid JSON payload." }));
                    return;
                }

                var type = (payload.Value<string>("type") ?? "ingredients").ToLowerInvariant();
                var items = payload["items"] as JArray ?? new JArray();

                if (items.Count == 0)
                {
                    context.Response.StatusCode = 400;
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "No items provided." }));
                    return;
                }

                // fetch active employees with emails
                var employeesCol = DatabaseHelper.GetUsersCollection();

                var countFilter = Builders<InventorySystemSiaProject.Models.User>.Filter.And(
                    Builders<InventorySystemSiaProject.Models.User>.Filter.Eq(u => u.IsActive, true),
                    Builders<InventorySystemSiaProject.Models.User>.Filter.Ne(u => u.Email, null),
                    Builders<InventorySystemSiaProject.Models.User>.Filter.Ne(u => u.Email, "")
                );

                long matchedCount = 0;
                try
                {
                    matchedCount = employeesCol.CountDocuments(countFilter);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[NotifyExpiry] CountDocuments failed: " + ex.Message);
                }

                System.Diagnostics.Debug.WriteLine("[NotifyExpiry] Matched employee count (driver filter): " + matchedCount);

                // actual query used for building emails
                var filter = countFilter;
                var employees = employeesCol.Find(countFilter).ToList();
                var emails = employees
                    .Select(u => u.Email != null ? u.Email.Trim() : null)
                    .Where(s => !string.IsNullOrWhiteSpace(s))
                    .Distinct()
                    .ToList();

                if (emails.Count == 0)
                {
                    var debug = new {
                        success = false,
                        error = "No employee emails found.",
                        collection = DatabaseHelper.GetEmployeesCollectionName(),
                        matchedCount = matchedCount
                    };
                    context.Response.Write(JsonConvert.SerializeObject(debug));
                    return;
                }

                // Build HTML email
                var sb = new System.Text.StringBuilder();
                sb.Append("<html><body>");
                sb.Append("<h2>Inventory Expiry Notification</h2>");
                sb.Append("<p>The following items are expired or near-expiry and must be inspected/discarded in storage:</p>");
                sb.Append("<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse;'>");

                bool showPackageColumn = !(type == "packages");

                if (showPackageColumn)
                    sb.Append("<tr><th>Package</th><th>Item</th><th>Qty</th><th>Manufactured</th><th>Expires</th></tr>");
                else
                    sb.Append("<tr><th>Item</th><th>Qty</th><th>Manufactured</th><th>Expires</th></tr>");


    foreach (var it in items)
    {
        // DEBUG: dump exact item shape so you can inspect incoming fields
        try
        {
            System.Diagnostics.Debug.WriteLine("[NotifyExpiry] item json: " + it.ToString(Newtonsoft.Json.Formatting.None));
        }
        catch { /* ignore debug failures */ }

        // package
        var pkgToken = it["packageId"] ?? it["package"];
        string pkg = (pkgToken != null && pkgToken.Type != JTokenType.Null) ? pkgToken.ToString() : string.Empty;
        if (!string.IsNullOrWhiteSpace(pkg) && pkg.IndexOf("BsonNull", StringComparison.OrdinalIgnoreCase) >= 0)
            pkg = string.Empty;

        // name
        var nameToken = it["ingredientName"] ?? it["itemName"] ?? it["ingredient"] ?? it["item"];
        string name = (nameToken != null && nameToken.Type != JTokenType.Null) ? nameToken.ToString() : "-";

        // quantity
        var qtyToken = it["quantity"];
        string qty = (qtyToken != null && qtyToken.Type != JTokenType.Null) ? qtyToken.ToString() : "-";

        // --- ADDED DEBUG: inspect raw manufactured/expiration tokens as received ---
        try
        {
            var rawMfgToken = it["manufacturedAt"] ?? it["manufactured"] ?? it["mfgDate"] ?? it["manufacturedAtUtc"];
            var rawExpToken = it["expirationAt"] ?? it["expires"] ?? it["expiration"];
            System.Diagnostics.Debug.WriteLine("[NotifyExpiry] raw manufactured token type/value: " +
                (rawMfgToken != null ? rawMfgToken.Type.ToString() + " -> " + rawMfgToken.ToString(Newtonsoft.Json.Formatting.None) : "<null>"));
            System.Diagnostics.Debug.WriteLine("[NotifyExpiry] raw expiration  token type/value: " +
                (rawExpToken != null ? rawExpToken.Type.ToString() + " -> " + rawExpToken.ToString(Newtonsoft.Json.Formatting.None) : "<null>"));
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine("[NotifyExpiry] debug token dump failed: " + ex.Message);
        }
        // --- end debug ---

        // manufactured date (robust parsing)
        string mfg = "-";
        var mfgToken = it["manufacturedAt"] ?? it["manufactured"] ?? it["mfgDate"] ?? it["manufacturedAtUtc"];
        if (mfgToken != null && mfgToken.Type != JTokenType.Null)
        {
            // If the token is a direct date type, use it
            if (mfgToken.Type == JTokenType.Date)
            {
                DateTime dt = mfgToken.Value<DateTime>();
                mfg = dt.ToString("MM/dd/yyyy");
            }
            else if (mfgToken.Type == JTokenType.Object)
            {
                // Handle {"$date": "..."} or {"$date": { "$numberLong": "..." }}
                var dateChild = mfgToken["$date"];
                if (dateChild != null)
                {
                    // $date may be string or object/number
                    if (dateChild.Type == JTokenType.String)
                    {
                        DateTimeOffset dto;
                        if (DateTimeOffset.TryParse(dateChild.ToString(), out dto))
                            mfg = dto.UtcDateTime.ToString("MM/dd/yyyy");
                        else
                            mfg = dateChild.ToString();
                    }
                    else if (dateChild.Type == JTokenType.Object)
                    {
                        var num = dateChild["$numberLong"] ?? dateChild["$numberLong"];
                        long msEpoch;
                        if (num != null && long.TryParse(num.ToString(), out msEpoch))
                        {
                            try
                            {
                                var dt = DateTimeOffset.FromUnixTimeMilliseconds(msEpoch).UtcDateTime;
                                mfg = dt.ToString("MM/dd/yyyy");
                            }
                            catch { /* ignore */ }
                        }
                    }
                    else if (dateChild.Type == JTokenType.Integer || dateChild.Type == JTokenType.Float)
                    {
                        long val;
                        if (long.TryParse(dateChild.ToString(), out val))
                        {
                            try
                            {
                                // numeric could be seconds or milliseconds: check magnitude
                                DateTimeOffset dto;
                                if (val > 9999999999L) // milliseconds
                                    dto = DateTimeOffset.FromUnixTimeMilliseconds(val);
                                else
                                    dto = DateTimeOffset.FromUnixTimeSeconds(val);
                                mfg = dto.UtcDateTime.ToString("MM/dd/yyyy");
                            }
                            catch { /* ignore */ }
                        }
                    }
                }
                else
                {
                    // fallback: stringify object then try parsing as ISO
                    var s = mfgToken.ToString();
                    DateTimeOffset dto2;
                    DateTime parsed;
                    if (DateTimeOffset.TryParse(s, out dto2))
                        mfg = dto2.UtcDateTime.ToString("MM/dd/yyyy");
                    else if (DateTime.TryParse(s, out parsed))
                        mfg = parsed.ToString("MM/dd/yyyy");
                    else if (!string.IsNullOrWhiteSpace(s) && s.IndexOf("BsonNull", StringComparison.OrdinalIgnoreCase) < 0)
                        mfg = s;
                }
            }
            else
            {
                // string or numeric
                var mfgRaw = mfgToken.ToString();
                // if it's purely numeric consider epoch, otherwise try ISO parse first
                long numeric;
                if (long.TryParse(mfgRaw, out numeric))
                {
                    try
                    {
                        DateTimeOffset dto;
                        // prefer milliseconds when magnitude indicates so
                        if (numeric > 9999999999L)
                            dto = DateTimeOffset.FromUnixTimeMilliseconds(numeric);
                        else
                            dto = DateTimeOffset.FromUnixTimeSeconds(numeric);
                        mfg = dto.UtcDateTime.ToString("MM/dd/yyyy");
                    }
                    catch
                    {
                        mfg = mfgRaw;
                    }
                }
                else
                {
                    DateTimeOffset dto3;
                    DateTime parsed2;
                    // Prefer DateTimeOffset for ISO strings (keeps correct offset info)
                    if (DateTimeOffset.TryParse(mfgRaw, out dto3))
                    {
                        mfg = dto3.UtcDateTime.ToString("MM/dd/yyyy");
                    }
                    else if (DateTime.TryParse(mfgRaw, out parsed2))
                    {
                        mfg = parsed2.ToString("MM/dd/yyyy");
                    }
                    else if (!string.IsNullOrWhiteSpace(mfgRaw) && mfgRaw.IndexOf("BsonNull", StringComparison.OrdinalIgnoreCase) < 0)
                    {
                        mfg = mfgRaw;
                    }
                }
            }
        }

        // expiration date (robust parsing)
        string exp = "-";
        var expToken = it["expirationAt"] ?? it["expires"] ?? it["expiration"];
        if (expToken != null && expToken.Type != JTokenType.Null)
        {
            if (expToken.Type == JTokenType.Date)
            {
                DateTime dt = expToken.Value<DateTime>();
                exp = dt.ToString("MM/dd/yyyy");
            }
            else if (expToken.Type == JTokenType.Object)
            {
                var dateChild = expToken["$date"];
                if (dateChild != null)
                {
                    if (dateChild.Type == JTokenType.String)
                    {
                        DateTimeOffset dtoE;
                        if (DateTimeOffset.TryParse(dateChild.ToString(), out dtoE))
                            exp = dtoE.UtcDateTime.ToString("MM/dd/yyyy");
                        else
                            exp = dateChild.ToString();
                    }
                    else if (dateChild.Type == JTokenType.Object)
                    {
                        var num = dateChild["$numberLong"] ?? dateChild["$numberLong"];
                        long msEpoch;
                        if (num != null && long.TryParse(num.ToString(), out msEpoch))
                        {
                            try
                            {
                                var dt = DateTimeOffset.FromUnixTimeMilliseconds(msEpoch).UtcDateTime;
                                exp = dt.ToString("MM/dd/yyyy");
                            }
                            catch { }
                        }
                    }
                    else if (dateChild.Type == JTokenType.Integer || dateChild.Type == JTokenType.Float)
                    {
                        long vnum;
                        if (long.TryParse(dateChild.ToString(), out vnum))
                        {
                            try
                            {
                                DateTimeOffset dtoE2;
                                if (vnum > 9999999999L) dtoE2 = DateTimeOffset.FromUnixTimeMilliseconds(vnum);
                                else dtoE2 = DateTimeOffset.FromUnixTimeSeconds(vnum);
                                exp = dtoE2.UtcDateTime.ToString("MM/dd/yyyy");
                            }
                            catch { }
                        }
                    }
                }
                else
                {
                    var s = expToken.ToString();
                    DateTimeOffset dtoE3;
                    DateTime parsedE;
                    if (DateTimeOffset.TryParse(s, out dtoE3))
                        exp = dtoE3.UtcDateTime.ToString("MM/dd/yyyy");
                    else if (DateTime.TryParse(s, out parsedE))
                        exp = parsedE.ToString("MM/dd/yyyy");
                    else if (!string.IsNullOrWhiteSpace(s) && s.IndexOf("BsonNull", StringComparison.OrdinalIgnoreCase) < 0)
                        exp = s;
                }
            }
            else
            {
                var expRaw = expToken.ToString();
                long numericE;
                if (long.TryParse(expRaw, out numericE))
                {
                    try
                    {
                        DateTimeOffset dtoE;
                        if (numericE > 9999999999L)
                            dtoE = DateTimeOffset.FromUnixTimeMilliseconds(numericE);
                        else
                            dtoE = DateTimeOffset.FromUnixTimeSeconds(numericE);
                        exp = dtoE.UtcDateTime.ToString("MM/dd/yyyy");
                    }
                    catch { exp = expRaw; }
                }
                else
                {
                    DateTimeOffset dtoE2;
                    DateTime parsedE2;
                    if (DateTimeOffset.TryParse(expRaw, out dtoE2))
                        exp = dtoE2.UtcDateTime.ToString("MM/dd/yyyy");
                    else if (DateTime.TryParse(expRaw, out parsedE2))
                        exp = parsedE2.ToString("MM/dd/yyyy");
                    else if (!string.IsNullOrWhiteSpace(expRaw) && expRaw.IndexOf("BsonNull", StringComparison.OrdinalIgnoreCase) < 0)
                        exp = expRaw;
                }
            }
        }

        sb.Append("<tr>");
        if (showPackageColumn)
            sb.Append("<td>" + HttpUtility.HtmlEncode(pkg) + "</td>");
        sb.Append("<td>" + HttpUtility.HtmlEncode(name) + "</td>");
        sb.Append("<td>" + HttpUtility.HtmlEncode(qty) + "</td>");
        sb.Append("<td>" + HttpUtility.HtmlEncode(mfg) + "</td>");
        sb.Append("<td>" + HttpUtility.HtmlEncode(exp) + "</td>");
        sb.Append("</tr>");
    }

                sb.Append("</table>");
                sb.Append("<p style='color:#dc3545;font-weight:bold;'>Action required: Please discard expired items immediately and update the inventory accordingly.</p>");
                sb.Append("<p>Regards,<br/>Inventory Management System</p>");
                sb.Append("</body></html>");

                string subject = type == "packages"
                    ? "Expired / Near-Expiry Packages — Action Required"
                    : "Expired / Near-Expiry Ingredients — Action Required";

                // Send emails (returns list of failed addresses)
                var failed = SendEmaikService.SendBulkEmail(emails, subject, sb.ToString());

                // Log action
                var logDetails = new
                {
                    type = type,
                    itemsCount = items.Count,
                    employeesNotified = emails.Count - failed.Count,
                    failed = failed
                };

                ActivityLogger.Log("Notify Expiry", "Notification", null, JsonConvert.SerializeObject(logDetails));

                context.Response.Write(JsonConvert.SerializeObject(new
                {
                    success = true,
                    totalEmployees = emails.Count,
                    sentTo = emails.Count - failed.Count,
                    failed = failed
                }));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                // Always return JSON on error
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = ex.Message }));
            }
        }

       public bool IsReusable
        {
            get { return false; }
        }
    }
}