using System;
using System.Web.UI;

namespace InventorySystemSiaProject.Admin
{
    public partial class Dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                // Check if user is logged in and is admin
                if (Session["UserId"] == null)
                {
                    Response.Redirect("~/WebPages/Login.aspx");
                    return;
                }

                // Check if user has admin role
                string userRole = Session["UserRole"]?.ToString() ?? "User";
                if (userRole != "Admin")
                {
                    // Redirect non-admin users to regular dashboard
                    Response.Redirect("~/Default.aspx");
                    return;
                }

                if (!Page.IsPostBack)
                {
                    LoadUserInfo();
                    LoadDashboardData();
                }
            }
            catch (Exception ex)
            {
                // Log error and set default values
                System.Diagnostics.Debug.WriteLine($"Dashboard Page_Load error: {ex.Message}");
                SetDefaultValues();
            }
        }

        private void LoadUserInfo()
        {
            try
            {
                // Load user information from session
                string userName = Session["UserName"]?.ToString() ?? "Admin User";
                lblUserName.Text = userName;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading user info: {ex.Message}");
                lblUserName.Text = "Admin User";
            }
        }

        private void LoadDashboardData()
        {
            try
            {
                // Set sample data for now - replace with actual database calls later
                lblTotalProducts.Text = "150";
                lblTotalSales.Text = "$12,456.78";
                lblLowStockItems.Text = "8";
                lblActiveUsers.Text = "25";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading dashboard data: {ex.Message}");
                SetDefaultValues();
            }
        }

        private void SetDefaultValues()
        {
            lblTotalProducts.Text = "0";
            lblTotalSales.Text = "$0.00";
            lblLowStockItems.Text = "0";
            lblActiveUsers.Text = "0";
        }

        // Event handlers for Quick Actions
        protected void lnkAddProduct_Click(object sender, EventArgs e)
        {
            try
            {
                ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('Add Product page will be available soon!');", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Add Product error: {ex.Message}");
            }
        }

        protected void lnkManageInventory_Click(object sender, EventArgs e)
        {
            try
            {
                ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('Inventory Management page will be available soon!');", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Manage Inventory error: {ex.Message}");
            }
        }

        protected void lnkViewReports_Click(object sender, EventArgs e)
        {
            try
            {
                ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('Reports page will be available soon!');", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"View Reports error: {ex.Message}");
            }
        }

        protected void lnkManageUsers_Click(object sender, EventArgs e)
        {
            try
            {
                ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('User Management page will be available soon!');", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Manage Users error: {ex.Message}");
            }
        }

        protected void btnViewAllOrders_Click(object sender, EventArgs e)
        {
            try
            {
                ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('Orders page will be available soon!');", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"View All Orders error: {ex.Message}");
            }
        }

        protected void lnkLogout_Click(object sender, EventArgs e)
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