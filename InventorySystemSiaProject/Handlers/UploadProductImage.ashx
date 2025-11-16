<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.UploadProductImage" %>

using System;
using System.Web;
using System.IO;
using Newtonsoft.Json;

namespace InventorySystemSiaProject.Handlers
{
    public class UploadProductImage : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            try
            {
                if (context.Request.Files.Count == 0)
                {
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "No file uploaded." }));
                    return;
                }
                var file = context.Request.Files[0];
                if (file == null || file.ContentLength == 0)
                {
                    context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "Empty file." }));
                    return;
                }
                using (var ms = new MemoryStream())
                {
                    file.InputStream.CopyTo(ms);
                    var bytes = ms.ToArray();
                    // Return base64 string for preview and saving
                    string base64 = Convert.ToBase64String(bytes);
                    context.Response.Write(JsonConvert.SerializeObject(new { success = true, base64 = base64 }));
                }
            }
            catch (Exception ex)
            {
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = ex.Message }));
            }
        }
        public bool IsReusable { get { return false; } }
    }
}
