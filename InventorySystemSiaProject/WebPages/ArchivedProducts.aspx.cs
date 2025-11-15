using System;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ArchivedProducts : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                hdnUserId.Value = Session["UserId"] != null ? Session["UserId"].ToString() : string.Empty;
            }
            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
        }
    }
}
