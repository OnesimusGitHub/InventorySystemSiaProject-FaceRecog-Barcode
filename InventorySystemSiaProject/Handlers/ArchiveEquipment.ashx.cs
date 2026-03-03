using System;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class ArchiveEquipment : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var js = new JavaScriptSerializer();
            try
            {
                string equipmentId = null;
                string action = "archive";

                context.Request.InputStream.Position = 0;
                using (var sr = new StreamReader(context.Request.InputStream))
                {
                    var body = sr.ReadToEnd();
                    if (!string.IsNullOrWhiteSpace(body))
                    {
                        var d = js.Deserialize<System.Collections.Generic.Dictionary<string, object>>(body);
                        if (d != null)
                        {
                            equipmentId = d.ContainsKey("equipmentId") ? d["equipmentId"]?.ToString() : null;
                            action = d.ContainsKey("action") ? d["action"]?.ToString() ?? "archive" : "archive";
                        }
                    }
                }

                if (string.IsNullOrEmpty(equipmentId))
                    equipmentId = context.Request.Form["equipmentId"] ?? context.Request.QueryString["equipmentId"];

                if (string.IsNullOrEmpty(equipmentId))
                {
                    context.Response.Write(js.Serialize(new { success = false, error = "Equipment ID required" }));
                    return;
                }

                var svc = new EquipmentService();
                bool ok;
                string msg;

                if (action == "restore")
                {
                    ok = svc.RestoreEquipmentAsync(equipmentId).GetAwaiter().GetResult();
                    msg = ok ? "Equipment restored." : "Failed to restore.";
                }
                else
                {
                    ok = svc.ArchiveEquipmentAsync(equipmentId).GetAwaiter().GetResult();
                    msg = ok ? "Equipment archived." : "Failed to archive.";
                }

                context.Response.Write(js.Serialize(new { success = ok, message = msg }));
            }
            catch (Exception ex)
            {
                context.Response.Write(js.Serialize(new { success = false, error = ex.Message }));
            }
        }

        public bool IsReusable => false;
    }
}
