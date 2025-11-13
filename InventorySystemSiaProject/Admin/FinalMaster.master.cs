using System;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace InventorySystemSiaProject.Admin
{
    public partial class FinalMaster : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                SetActiveNavLink();
            }
        }

        private void SetActiveNavLink()
        {
            string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
            
            // Remove active class from all links
            btnDashboard.CssClass = "nav-link";
            btnProducts.CssClass = "nav-link";
            btnStocks.CssClass = "nav-link";
            btnAccount.CssClass = "nav-link";
            btnArchive.CssClass = "nav-link";
            
            // Set active class based on current page
            switch (currentPage.ToLower())
            {
                case "dashboard.aspx":
                    btnDashboard.CssClass = "nav-link active";
                    break;
                case "productpage.aspx":
                case "productprofile.aspx":
                    btnProducts.CssClass = "nav-link active";
                    break;
                case "productstock.aspx":
                case "ingredientspage.aspx":
                    btnStocks.CssClass = "nav-link active";
                    break;
                case "archivedproducts.aspx":
                    btnArchive.CssClass = "nav-link active";
                    break;
            }
        }

        protected void btnDashboard_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/WebPages/Dashboard.aspx");
        }

        protected void btnProducts_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/WebPages/ProductPage.aspx");
        }

        protected void btnStocks_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/WebPages/ProductStock.aspx");
        }

        protected void btnAccount_Click(object sender, EventArgs e)
        {
            // Add your account page redirect here
            // Response.Redirect("~/WebPages/Account.aspx");
        }

        protected void btnArchive_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/WebPages/ArchivedProducts.aspx");
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            Session.Clear();
            Session.Abandon();
            Response.Redirect("~/WebPages/Login.aspx");
        }
    }
}
