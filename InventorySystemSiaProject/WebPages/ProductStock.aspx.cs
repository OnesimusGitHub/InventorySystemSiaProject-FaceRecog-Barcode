using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;
using System;
using System.Linq;
using System.Web.UI.WebControls;

namespace InventorySystemSiaProject.WebPages
{
    public partial class PstockForm : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadProducts();
            }
        }

        private void LoadProducts()
        {
            var collection = DatabaseHelper.GetProductVariantsCollection();
            var variants = collection.Find(FilterDefinition<ProductVariant>.Empty).ToList();

            gvProducts.DataSource = variants;
            gvProducts.DataBind();
        }

        protected void gvProducts_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "SendHelp")
            {
                string id = e.CommandArgument.ToString();

                var collection = DatabaseHelper.GetProductVariantsCollection();
                var product = collection.Find(x => x.Id == id).FirstOrDefault();

                if (product != null)
                {
                    try
                    {
                        SendEmaikService.SendLowStockEmail(
                            "salangsang.andrewjeremiah.castro@gmail.com",   // Change to real email
                            product.VariantName,
                            product.StockQuantity,
                            product.MinimumStock
                        );

                        lblMessage.Text = "✅ Email sent for product: " + product.VariantName;
                        lblMessage.ForeColor = System.Drawing.Color.Green;
                        lblMessage.Visible = true;
                    }
                    catch (Exception ex)
                    {
                        lblMessage.Text = "❌ Failed to send email: " + ex.Message;
                        lblMessage.ForeColor = System.Drawing.Color.Red;
                        lblMessage.Visible = true;
                    }
                }
            }
        }
    }
}
