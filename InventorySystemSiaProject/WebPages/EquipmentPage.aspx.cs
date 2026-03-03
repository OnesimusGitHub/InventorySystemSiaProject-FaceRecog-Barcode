using System;
using System.Web.UI;

namespace InventorySystemSiaProject.WebPages
{
    public partial class EquipmentPage : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Auth guard
            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) ||
                !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
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
