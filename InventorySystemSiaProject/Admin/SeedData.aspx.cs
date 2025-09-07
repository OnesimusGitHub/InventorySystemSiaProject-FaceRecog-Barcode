using System;
using System.Threading.Tasks;
using System.Web.UI;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.Admin
{
    public partial class SeedData : System.Web.UI.Page
    {
        private ProductService _productService;

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                // Check if user is logged in
                if (Session["UserId"] == null)
                {
                    Response.Redirect("~/WebPages/Login.aspx");
                    return;
                }

                _productService = new ProductService();

                if (!Page.IsPostBack)
                {
                    // Register async task for page load
                    RegisterAsyncTask(new PageAsyncTask(LoadExistingDataAsync));
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Page load error: {ex.Message}", "error");
            }
        }

        protected async void btnSeedProducts_Click(object sender, EventArgs e)
        {
            try
            {
                ShowMessage("Seeding beauty products data... Please wait.", "info");
                
                // Disable button to prevent multiple clicks
                btnSeedProducts.Enabled = false;
                btnSeedProducts.Text = "🔄 Seeding Products...";

                await _productService.SeedBeautyProductsAsync();

                ShowMessage("✅ Beauty products data has been successfully seeded! Your inventory now includes premium skincare and makeup products.", "success");
                
                // Load the new products
                await LoadExistingProductsAsync();
                productsList.Visible = true;

                btnSeedProducts.Text = "✅ Products Seeded";
            }
            catch (Exception ex)
            {
                ShowMessage($"❌ Error seeding products: {ex.Message}", "error");
                
                // Re-enable button
                btnSeedProducts.Enabled = true;
                btnSeedProducts.Text = "🌸 Seed Beauty Products";
            }
        }

        protected async void btnSeedSales_Click(object sender, EventArgs e)
        {
            try
            {
                ShowMessage("Seeding comprehensive sales data (daily, weekly, monthly, yearly)... Please wait.", "info");
                
                // Disable button to prevent multiple clicks
                btnSeedSales.Enabled = false;
                btnSeedSales.Text = "🔄 Seeding Sales...";

                await _productService.SeedSalesDataAsync();

                ShowMessage("✅ Comprehensive sales data has been successfully seeded! Your system now includes realistic sales transactions across daily, weekly, monthly, and yearly periods with seasonal variations and automatic stock updates.", "success");
                
                // Load the new sales
                await LoadExistingSalesAsync();
                salesList.Visible = true;

                btnSeedSales.Text = "✅ Sales Seeded";
            }
            catch (Exception ex)
            {
                ShowMessage($"❌ Error seeding sales: {ex.Message}", "error");
                
                // Re-enable button
                btnSeedSales.Enabled = true;
                btnSeedSales.Text = "💳 Seed Sales Data";
            }
        }

        protected async void btnSeedAllData_Click(object sender, EventArgs e)
        {
            try
            {
                ShowMessage("Seeding all data (products + comprehensive sales across all time periods)... Please wait.", "info");
                
                // Disable all seed buttons to prevent conflicts
                btnSeedProducts.Enabled = false;
                btnSeedSales.Enabled = false;
                btnSeedAllData.Enabled = false;
                btnSeedAllData.Text = "🔄 Seeding Everything...";

                await _productService.SeedAllDataAsync();

                ShowMessage("🎉 ALL DATA SEEDED SUCCESSFULLY! Your inventory system is now fully populated with beauty products, variants, ingredients, and comprehensive sales transactions spanning daily, weekly, monthly, and yearly periods. Stock levels have been automatically adjusted based on sales. Perfect for dashboard analytics!", "success");
                
                // Load both products and sales
                await LoadExistingProductsAsync();
                await LoadExistingSalesAsync();
                productsList.Visible = true;
                salesList.Visible = true;

                btnSeedAllData.Text = "🎉 Everything Seeded!";
            }
            catch (Exception ex)
            {
                ShowMessage($"❌ Error seeding all data: {ex.Message}", "error");
                
                // Re-enable buttons
                btnSeedProducts.Enabled = true;
                btnSeedSales.Enabled = true;
                btnSeedAllData.Enabled = true;
                btnSeedAllData.Text = "🎁 Seed Everything";
            }
        }

        protected async void btnViewProducts_Click(object sender, EventArgs e)
        {
            try
            {
                await LoadExistingProductsAsync();
                productsList.Visible = true;
                salesList.Visible = false;
                ShowMessage("👀 Displaying current products in database.", "info");
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading products: {ex.Message}", "error");
            }
        }

        protected async void btnViewSales_Click(object sender, EventArgs e)
        {
            try
            {
                await LoadExistingSalesAsync();
                salesList.Visible = true;
                productsList.Visible = false;
                ShowMessage("👀 Displaying current sales in database.", "info");
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading sales: {ex.Message}", "error");
            }
        }

        protected void btnBackToDashboard_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/WebPages/Dashboard.aspx");
        }

        // Changed from async void to async Task and made it a separate method
        private async Task LoadExistingDataAsync()
        {
            try
            {
                await LoadExistingProductsAsync();
                await LoadExistingSalesAsync();
            }
            catch (Exception)
            {
                // Don't show error on page load - just log it silently
                // Error handling is done in individual methods
            }
        }

        private async Task LoadExistingProductsAsync()
        {
            try
            {
                var products = await _productService.GetAllProductsAsync();
                
                if (products.Count > 0)
                {
                    rptProducts.DataSource = products;
                    rptProducts.DataBind();
                    // Keep hidden unless explicitly requested
                    productsList.Visible = false;
                }
                else
                {
                    productsList.Visible = false;
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading existing products: {ex.Message}", "error");
                throw;
            }
        }

        private async Task LoadExistingSalesAsync()
        {
            try
            {
                var sales = await _productService.GetAllSalesAsync();
                
                if (sales.Count > 0)
                {
                    rptSales.DataSource = sales;
                    rptSales.DataBind();
                    // Keep hidden unless explicitly requested
                    salesList.Visible = false;
                }
                else
                {
                    salesList.Visible = false;
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading existing sales: {ex.Message}", "error");
                throw;
            }
        }

        private void ShowMessage(string message, string type)
        {
            pnlMessage.Visible = true;
            lblMessage.Text = message;
            
            // Set CSS class based on message type
            switch (type.ToLower())
            {
                case "success":
                    pnlMessage.CssClass = "message success";
                    break;
                case "error":
                    pnlMessage.CssClass = "message error";
                    break;
                case "info":
                    pnlMessage.CssClass = "message info";
                    break;
                default:
                    pnlMessage.CssClass = "message";
                    break;
            }
        }
    }
}