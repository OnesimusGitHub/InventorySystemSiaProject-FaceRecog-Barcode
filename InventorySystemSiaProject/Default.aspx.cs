using System;
using System.Web.UI;

namespace InventorySystemSiaProject
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Check if user is logged in
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }

            if (!Page.IsPostBack)
            {
                LoadUserInfo();
            }
        }

        private void LoadUserInfo()
        {
            try
            {
                // Get user info from session
                string userName = Session["UserName"]?.ToString() ?? "Unknown User";
                string userEmail = Session["UserEmail"]?.ToString() ?? "No Email";
                string userRole = Session["UserRole"]?.ToString() ?? "User";
                DateTime loginTime = Session["LoginTime"] != null ? (DateTime)Session["LoginTime"] : DateTime.Now;

                // Display user information
                lblUserName.Text = userName;
                lblName.Text = userName;
                lblEmail.Text = userEmail;
                lblRole.Text = userRole;
                lblLoginTime.Text = loginTime.ToString("yyyy-MM-dd HH:mm:ss");
                lblSessionId.Text = Session.SessionID.Substring(0, 8) + "...";
                lblLastActivity.Text = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            }
            catch (Exception ex)
            {
                // Handle any errors
                lblUserName.Text = "Error loading user info";
                System.Diagnostics.Debug.WriteLine($"Error loading user info: {ex.Message}");
            }
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            try
            {
                // Clear session
                Session.Clear();
                Session.Abandon();

                // Clear any authentication cookies if they exist
                Response.Cookies.Clear();

                // Redirect to login page
                Response.Redirect("~/WebPages/Login.aspx");
            }
            catch (Exception ex)
            {
                // Handle logout error
                System.Diagnostics.Debug.WriteLine($"Logout error: {ex.Message}");
                Response.Redirect("~/WebPages/Login.aspx");
            }
        }
    }
}