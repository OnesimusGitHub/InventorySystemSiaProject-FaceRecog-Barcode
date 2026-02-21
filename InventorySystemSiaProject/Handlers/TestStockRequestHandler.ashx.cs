using System;
using System.Web;
using System.Web.Script.Serialization;

namespace InventorySystemSiaProject.Handlers
{
    /// <summary>
    /// Simple test handler to verify .ashx routing works
    /// </summary>
    public class TestStockRequestHandler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                var requestId = context.Request.QueryString["id"];
                
                var response = new
                {
                    success = true,
                    message = "? Handler is working correctly!",
                    timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    requestId = requestId ?? "No ID provided",
                    url = context.Request.Url.ToString(),
                    method = context.Request.HttpMethod,
                    handlerPath = context.Request.Path,
                    diagnostics = new
                    {
                        isLocal = context.Request.IsLocal,
                        userHostAddress = context.Request.UserHostAddress,
                        serverName = context.Request.ServerVariables["SERVER_NAME"]
                    }
                };

                context.Response.Write(serializer.Serialize(response));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                }));
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
