using System;
using System.Threading.Tasks;
using System.Web;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Handlers
{
    public class GetEquipmentImage : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            string id = context.Request.QueryString["equipmentId"];
            if (string.IsNullOrEmpty(id))
            {
                ServePlaceholder(context); return;
            }
            try
            {
                var svc = new EquipmentService();
                // ✅ Task.Run prevents deadlock on ASP.NET sync context
                var eq = Task.Run(() => svc.GetEquipmentByIdAsync(id)).GetAwaiter().GetResult();
                if (eq?.EquipmentImg != null && eq.EquipmentImg.Length > 0)
                {
                    context.Response.ContentType = eq.EquipmentImgContentType ?? "image/jpeg";
                    context.Response.Cache.SetCacheability(HttpCacheability.Public);
                    context.Response.Cache.SetMaxAge(TimeSpan.FromHours(1));
                    context.Response.BinaryWrite(eq.EquipmentImg);
                    return;
                }
            }
            catch { }
            ServePlaceholder(context);
        }

        private void ServePlaceholder(HttpContext context)
        {
            // 1×1 transparent PNG
            byte[] png = Convert.FromBase64String(
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=");
            context.Response.ContentType = "image/png";
            context.Response.BinaryWrite(png);
        }

        public bool IsReusable => false;
    }
}