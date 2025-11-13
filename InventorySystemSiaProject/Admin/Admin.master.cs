using System;
using System.Web.UI.HtmlControls;

namespace InventorySystemSiaProject.Admin
{
    public partial class AdminMaster : System.Web.UI.MasterPage
    {
        // Public properties to expose user session data
        public string LoggedInUserName
        {
            get { return Session["UserName"] != null ? Session["UserName"].ToString() : "Guest"; }
        }

        public string LoggedInUserEmail
        {
            get { return Session["UserEmail"] != null ? Session["UserEmail"].ToString() : ""; }
        }

        public string LoggedInUserRole
        {
            get { return Session["UserRole"] != null ? Session["UserRole"].ToString() : ""; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Check if user is logged in
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            // Set active navigation based on current page
            SetActiveNavigation();
        }

        private void SetActiveNavigation()
        {
            string currentPage = System.IO.Path.GetFileName(Request.Path);
            string tabParam = Request.QueryString["tab"];
            
            // Add active class to current page navigation
            string script = $@"
                document.addEventListener('DOMContentLoaded', function() {{{{
                    console.log('Setting up navigation for page: {currentPage}, tab: {tabParam}');
                    
                    // Remove all active classes first
                    document.querySelectorAll('.nav-link, .sidebar .nav-link').forEach(link => {{{{
                        link.classList.remove('active');
                        link.style.background = '';
                        link.style.boxShadow = '';
                        link.style.transform = '';
                    }}}});
                    
                    // Add active class to current page with specific tab handling
                    const currentPage = '{currentPage}';
                    const tabParam = '{tabParam}';
                    const navLinks = document.querySelectorAll('.nav-link, .sidebar .nav-link');
                    
                    navLinks.forEach(link => {{{{
                        const href = link.getAttribute('href');
                        if (href) {{{{
                            // Check if the link matches the current page and tab
                            if (tabParam) {{{{
                                // If we have a tab parameter, match it exactly
                                if (href.includes(currentPage) && href.includes('tab=' + tabParam)) {{{{
                                    link.classList.add('active');
                                }}}}
                            }}}} else {{{{
                                // If no tab parameter, match the page without any tab query
                                if (href.includes(currentPage) && !href.includes('tab=')) {{{{
                                    link.classList.add('active');
                                }}}}
                            }}}}
                        }}}}
                    }}}});
                    
                    console.log('Navigation setup complete - CSS styles will control appearance');
                }}}});";
            
            Page.ClientScript.RegisterStartupScript(this.GetType(), "setActiveNav", script, true);
        }

        protected void btnHome_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/Dashboard.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnProduct_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/ProductPage.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnProductInfo_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/ProductInformation.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnPayment_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("Payment.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnStock_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/ProductStock.aspx?tab=stock", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnIngredients_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/IngredientsPage.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnShipping_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("Shipping.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnManageUser_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/UserPrivilege.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnSeedData_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("SeedData.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnSetting_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("Setting.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnLogout_Click(object sender, EventArgs e) 
        { 
            // Clear session
            Session.Clear();
            Session.Abandon();
            
            Response.Redirect("~/WebPages/Login.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnActivityLog_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/ActivityLog.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
        
        protected void btnArchivedProducts_Click(object sender, EventArgs e) 
        { 
            Response.Redirect("~/WebPages/ArchivedProducts.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}