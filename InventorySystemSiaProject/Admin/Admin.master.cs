using System;
using System.Web.UI.HtmlControls;

namespace InventorySystemSiaProject.Admin
{
    public partial class AdminMaster : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Set active navigation based on current page
            SetActiveNavigation();
        }

        private void SetActiveNavigation()
        {
            string currentPage = System.IO.Path.GetFileName(Request.Path);
            
            // Add active class to current page navigation with maximum specificity
            string script = $@"
                document.addEventListener('DOMContentLoaded', function() {{
                    console.log('Setting up navigation for page: {currentPage}');
                    
                    // Remove all active classes first with maximum specificity
                    document.querySelectorAll('.nav-link, .sidebar .nav-link').forEach(link => {{
                        link.classList.remove('active');
                        link.style.background = '';
                        link.style.boxShadow = '';
                        link.style.transform = '';
                    }});
                    
                    // Add active class to current page
                    const currentPage = '{currentPage}';
                    const navLinks = document.querySelectorAll('.nav-link, .sidebar .nav-link');
                    
                    navLinks.forEach(link => {{
                        const href = link.getAttribute('href');
                        if (href && href.includes(currentPage)) {{
                            link.classList.add('active');
                            
                            // Force active styling with maximum specificity
                            link.style.setProperty('background-color', 'rgba(255,255,255,0.2)', 'important');
                            link.style.setProperty('color', 'white', 'important');
                            link.style.setProperty('transform', 'translateX(5px)', 'important');
                            link.style.setProperty('box-shadow', '0 4px 12px rgba(0,0,0,0.2)', 'important');
                            link.style.setProperty('backdrop-filter', 'blur(10px)', 'important');
                            
                            console.log('Active navigation set for:', href);
                        }}
                    }});
                    
                    // Force hover effects with maximum specificity
                    navLinks.forEach(link => {{
                        link.addEventListener('mouseenter', function() {{
                            if (!this.classList.contains('active')) {{
                                this.style.setProperty('background-color', 'rgba(255,255,255,0.1)', 'important');
                                this.style.setProperty('color', 'white', 'important');
                                this.style.setProperty('transform', 'translateX(3px)', 'important');
                            }}
                        }});
                        
                        link.addEventListener('mouseleave', function() {{
                            if (!this.classList.contains('active')) {{
                                this.style.removeProperty('background-color');
                                this.style.removeProperty('transform');
                                this.style.setProperty('color', 'rgba(255,255,255,0.9)', 'important');
                            }}
                        }});
                    }});
                    
                    // Force sidebar background with maximum specificity
                    const sidebars = document.querySelectorAll('.sidebar, nav.sidebar, .dashboard-container .sidebar');
                    sidebars.forEach(sidebar => {{
                        sidebar.style.setProperty('background', 'linear-gradient(180deg, #a64d79 0%, #8b4267 100%)', 'important');
                        sidebar.style.setProperty('width', '240px', 'important');
                        sidebar.style.setProperty('position', 'fixed', 'important');
                        sidebar.style.setProperty('height', '100vh', 'important');
                        sidebar.style.setProperty('color', 'white', 'important');
                        sidebar.style.setProperty('z-index', '1000', 'important');
                    }});
                    
                    console.log('Navigation setup complete');
                }});";
            
            Page.ClientScript.RegisterStartupScript(this.GetType(), "setActiveNav", script, true);
        }

        protected void btnHome_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/Dashboard.aspx"); }
        protected void btnProduct_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/ProductPage.aspx"); }
        protected void btnProductInfo_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/ProductInformation.aspx"); }
        protected void btnPayment_Click(object sender, EventArgs e) { Response.Redirect("Payment.aspx"); }
        protected void btnStock_Click(object sender, EventArgs e) { Response.Redirect("Stock.aspx"); }
        protected void btnShipping_Click(object sender, EventArgs e) { Response.Redirect("Shipping.aspx"); }
        protected void btnManageUser_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/UserPrivilege.aspx"); }
        protected void btnSeedData_Click(object sender, EventArgs e) { Response.Redirect("SeedData.aspx"); }
        protected void btnSetting_Click(object sender, EventArgs e) { Response.Redirect("Setting.aspx"); }
        protected void btnLogout_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/Login.aspx"); }
    }
}