using System;
using System.Web;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject
{
    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            // Disable UnobtrusiveValidationMode to avoid jQuery requirement
            System.Web.UI.ValidationSettings.UnobtrusiveValidationMode = System.Web.UI.UnobtrusiveValidationMode.None;
            
            // Configure SSL/TLS settings for MongoDB Atlas compatibility
            System.Net.ServicePointManager.SecurityProtocol = 
                System.Net.SecurityProtocolType.Tls12 | 
                System.Net.SecurityProtocolType.Tls11 | 
                System.Net.SecurityProtocolType.Tls;
            
            // Disable SSL certificate validation for MongoDB Atlas (development only)
            System.Net.ServicePointManager.ServerCertificateValidationCallback = 
                (certSender, certificate, chain, sslPolicyErrors) => true;
            
            // Additional SSL settings for MongoDB Atlas
            System.Net.ServicePointManager.CheckCertificateRevocationList = false;
            System.Net.ServicePointManager.DefaultConnectionLimit = 100;
            System.Net.ServicePointManager.Expect100Continue = false;
            
            // Don't initialize database collections on startup to prevent blocking
            // This will be done lazily when first needed
        }

        protected void Session_Start(object sender, EventArgs e)
        {

        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {

        }

        protected void Application_AuthenticateRequest(object sender, EventArgs e)
        {

        }

        protected void Application_Error(object sender, EventArgs e)
        {

        }

        protected void Session_End(object sender, EventArgs e)
        {

        }

        protected void Application_End(object sender, EventArgs e)
        {

        }
    }
}