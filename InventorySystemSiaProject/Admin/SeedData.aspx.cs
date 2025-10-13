using System;
using System.Threading.Tasks;
using System.Web.UI;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;

namespace InventorySystemSiaProject.Admin
{
    public partial class SeedData : System.Web.UI.Page
    {
        private ProductService _productService;
        private SupplierService _supplierService;

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
                _supplierService = new SupplierService();

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

        protected async void btnSeedSuppliers_Click(object sender, EventArgs e)
        {
            try
            {
                ShowMessage("Seeding suppliers data... Please wait.", "info");
                
                // Disable button to prevent multiple clicks
                btnSeedSuppliers.Enabled = false;
                btnSeedSuppliers.Text = "🔄 Seeding Suppliers...";

                await _supplierService.SeedSuppliersAsync();

                ShowMessage("✅ Suppliers data has been successfully seeded! Your system now includes 10 verified beauty product suppliers with complete contact information.", "success");
                
                // Load the new suppliers
                await LoadExistingSuppliersAsync();
                suppliersList.Visible = true;

                btnSeedSuppliers.Text = "✅ Suppliers Seeded";
            }
            catch (Exception ex)
            {
                ShowMessage($"❌ Error seeding suppliers: {ex.Message}", "error");
                
                // Re-enable button
                btnSeedSuppliers.Enabled = true;
                btnSeedSuppliers.Text = "🏢 Seed Suppliers";
            }
        }

        protected async void btnViewSuppliers_Click(object sender, EventArgs e)
        {
            try
            {
                await LoadExistingSuppliersAsync();
                suppliersList.Visible = true;
                productsList.Visible = false;
                salesList.Visible = false;
                ShowMessage("👀 Displaying current suppliers in database.", "info");
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading suppliers: {ex.Message}", "error");
            }
        }

        // NEW: Seed a tiny set of readable sample sales
        protected async void btnSeedSampleSales_Click(object sender, EventArgs e)
        {
            try
            {
                ShowMessage("Seeding a few sample sales...", "info");
                btnSeedSampleSales.Enabled = false;
                btnSeedSampleSales.Text = "🔄 Seeding Samples...";

                // Ensure we have products/variants
                var variants = await _productService.GetAllProductVariantsAsync();
                if (variants == null || variants.Count == 0)
                {
                    await _productService.SeedBeautyProductsAsync();
                    variants = await _productService.GetAllProductVariantsAsync();
                }

                if (variants == null || variants.Count == 0)
                {
                    ShowMessage("No variants found even after seeding products.", "error");
                    btnSeedSampleSales.Enabled = true;
                    btnSeedSampleSales.Text = "🧪 Seed Sample Sales";
                    return;
                }

                var salesService = new SalesService();

                // Use up to 5 variants to create 5 sample sales
                var max = Math.Min(5, variants.Count);
                for (int i = 0; i < max; i++)
                {
                    var v = variants[i];
                    var qty = (i % 3) + 1; // 1..3
                    var unitPrice = v.Price; // current variant price
                    var gross = unitPrice * qty;
                    var tax = Math.Round(gross * 0.12m, 2); // 12% VAT
                    var discount = (i % 2 == 0) ? Math.Round(gross * 0.05m, 2) : 0m; // 5% discount on every other item

                    await salesService.CreateSaleAsync(v.Id, qty, unitPrice, tax, discount);
                }

                ShowMessage($"✅ Seeded {max} sample sales (with tax/discounts).", "success");

                await LoadExistingSalesAsync();
                salesList.Visible = true;
                btnSeedSampleSales.Text = "✅ Samples Seeded";
            }
            catch (Exception ex)
            {
                ShowMessage($"❌ Error seeding sample sales: {ex.Message}", "error");
                btnSeedSampleSales.Enabled = true;
                btnSeedSampleSales.Text = "🧪 Seed Sample Sales";
            }
        }

        // NEW: Delete all sales data
        protected async void btnDeleteAllSales_Click(object sender, EventArgs e)
        {
            try
            {
                ShowMessage("Deleting all sales data... Please wait.", "info");
                btnDeleteAllSales.Enabled = false;
                btnDeleteAllSales.Text = "🔄 Deleting Sales...";

                // Get the sales collection
                var salesCollection = DatabaseHelper.GetSalesCollection();
                
                // Delete all sales documents
                var deleteResult = await salesCollection.DeleteManyAsync(FilterDefinition<Sale>.Empty);
                
                ShowMessage($"✅ Successfully deleted {deleteResult.DeletedCount} sales records from the database.", "success");
                
                // Refresh the sales list (should be empty now)
                await LoadExistingSalesAsync();
                salesList.Visible = false;
                
                // Re-enable buttons for re-seeding
                btnSeedSales.Enabled = true;
                btnSeedSales.Text = "💳 Seed Sales Data";
                btnSeedSampleSales.Enabled = true;
                btnSeedSampleSales.Text = "🧪 Seed Sample Sales";
                btnSeedAllData.Enabled = true;
                btnSeedAllData.Text = "🎁 Seed Everything";
                
                btnDeleteAllSales.Text = "🗑️ Delete All Sales";
                btnDeleteAllSales.Enabled = true;
            }
            catch (Exception ex)
            {
                ShowMessage($"❌ Error deleting sales data: {ex.Message}", "error");
                btnDeleteAllSales.Enabled = true;
                btnDeleteAllSales.Text = "🗑️ Delete All Sales";
            }
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

        private async Task LoadExistingSuppliersAsync()
        {
            try
            {
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                
                if (suppliers.Count > 0)
                {
                    rptSuppliers.DataSource = suppliers;
                    rptSuppliers.DataBind();
                    // Keep hidden unless explicitly requested
                    suppliersList.Visible = false;
                }
                else
                {
                    suppliersList.Visible = false;
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Error loading existing suppliers: {ex.Message}", "error");
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