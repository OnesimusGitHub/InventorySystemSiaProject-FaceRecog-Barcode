using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace InventorySystemSiaProject.Masterwebpage
{
    public partial class Admin : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
         
        }

        protected void btnHome_Click(object sender, EventArgs e) { Response.Redirect("../Admin/Dashboard.aspx"); }
        protected void btnProduct_Click(object sender, EventArgs e) { Response.Redirect("../Admin/ProductPage.aspx"); }
        protected void btnOrder_Click(object sender, EventArgs e) { Response.Redirect("../Admin/Order.aspx"); }
        protected void btnPayment_Click(object sender, EventArgs e) { Response.Redirect("../Admin/Payment.aspx"); }
        protected void btnStock_Click(object sender, EventArgs e) { Response.Redirect("../Admin/Stock.aspx"); }
        protected void btnShipping_Click(object sender, EventArgs e) { Response.Redirect("../Admin/Shipping.aspx"); }
        protected void btnManageUser_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/UserPrivilege.aspx"); }
        protected void btnSeedData_Click(object sender, EventArgs e) { Response.Redirect("../Admin/SeedData.aspx"); }
        protected void btnSetting_Click(object sender, EventArgs e) { Response.Redirect("../Admin/Setting.aspx"); }
        protected void btnLogout_Click(object sender, EventArgs e) { Response.Redirect("../WebPages/Login.aspx"); }

    }
}