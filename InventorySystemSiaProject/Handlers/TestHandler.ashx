<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.TestHandler" %>

using System;
using System.Web;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    public class TestHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                var response = new
                {
                    success = true,
                    message = "Handler configuration is working correctly!",
                    timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    handlerName = "TestHandler"
                };

                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { 
                    error = ex.Message,
                    success = false
                }));
            }
        }

        public bool IsReusable => false;
    }
}