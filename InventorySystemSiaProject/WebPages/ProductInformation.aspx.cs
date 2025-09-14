using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Helpers;
using MongoDB.Bson;
using MongoDB.Driver;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ProductInformation : System.Web.UI.Page
    {
        private ProductService _productService;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Admin-only guard
            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
            {
                Session["ReturnUrl"] = Request.RawUrl;
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }

            _productService = new ProductService();

            if (!IsPostBack)
            {
                BindProducts();
            }
        }

        private void BindProducts()
        {
            try
            {
                var collection = DatabaseHelper.GetProductsCollection();
                // Basic filter: only active products
                var filter = Builders<Models.Product>.Filter.Eq(p => p.IsActive, true);
                var products = collection.Find(filter).ToList();

                if (products == null || products.Count == 0)
                {
                    pnlNoProducts.Visible = true;
                    return;
                }

                // Simple transformation (placeholder for real best-selling logic)
                var bestSelling = products
                    .OrderByDescending(p => p.CreatedAt) // newest first (replace with sales aggregation later)
                    .Take(12)
                    .Select(p => new
                    {
                        p.ProductName,
                        ProductImg = string.IsNullOrWhiteSpace(p.ProductImg) ? "/Content/images/sample-generic.png" : p.ProductImg,
                        PriceDisplay = "₱" + p.ProductVal.ToString("N2")
                    })
                    .ToList();

                rptBestSelling.DataSource = bestSelling;
                rptBestSelling.DataBind();
            }
            catch (Exception ex)
            {
                pnlNoProducts.Visible = true;
                pnlNoProducts.Controls.Add(new System.Web.UI.LiteralControl($"Error loading products: {ex.Message}"));
            }
        }
    }
}