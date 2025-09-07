using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Text.Json;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;

namespace InventorySystemSiaProject.WebPages
{

    public partial class ProductPage : System.Web.UI.Page
    {
        private ProductService _productService;

        protected void Page_Load(object sender, EventArgs e)
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
                // Load products asynchronously
                RegisterAsyncTask(new PageAsyncTask(LoadProductsAsync));
            }
        }

        private async Task LoadProductsAsync()
        {
            try
            {
                bool isConnected = await DatabaseHelper.TestConnectionAsync();

                if (!isConnected)
                {
                    throw new Exception("Cannot establish connection to MongoDB");
                }

                // Get all products and variants
                var products = await _productService.GetAllProductsAsync();
                var variants = await _productService.GetAllProductVariantsAsync();

                if (products.Count == 0)
                {
                    if (pnlLoading != null) pnlLoading.Visible = false;
                    if (pnlNoData != null) pnlNoData.Visible = true;
                    if (rptProductVariants != null) rptProductVariants.Visible = false;

                    if (lblProductCount != null) lblProductCount.Text = "0";
                    if (lblLowStockCount != null) lblLowStockCount.Text = "0";
                    if (lblCategoryCount != null) lblCategoryCount.Text = "0";
                    return;
                }

                // Group variants by product and create aggregated product data
                var variantsByProduct = variants.Where(v => v.IsActive).GroupBy(v => v.ProductId).ToDictionary(g => g.Key, g => g.ToList());

                var productData = products.Where(p => p.IsActive).Select(product => {
                    var productVariants = variantsByProduct.ContainsKey(product.Id) ? variantsByProduct[product.Id] : new List<ProductVariant>();
                    
                    // Calculate aggregated values
                    var totalStock = productVariants.Sum(v => v.StockQuantity);
                    var totalMinStock = productVariants.Sum(v => v.MinimumStock);
                    var lowestPrice = productVariants.Any() ? productVariants.Min(v => v.Price) : product.ProductVal;
                    var highestPrice = productVariants.Any() ? productVariants.Max(v => v.Price) : product.ProductVal;
                    var variantCount = productVariants.Count;
                    var lowStockVariants = productVariants.Count(v => v.IsLowStock);
                    var mainSKU = productVariants.FirstOrDefault()?.SKU ?? GenerateProductSKU(product.ProductName);

                    // Determine main variant for display (use the first variant or create a summary)
                    var displayVariant = productVariants.FirstOrDefault();
                    var displayPrice = displayVariant?.Price ?? product.ProductVal;
                    var displayStock = totalStock;
                    var displayMinStock = totalMinStock;

                    return new
                    {
                        // Product data
                        ProductId = product.Id,
                        ProductName = product.ProductName,
                        ProductDesc = product.ProductDesc,
                        ProductCategory = product.ProductCategory,
                        ProductImg = product.ProductImg,
                        Supplier = product.Supplier,
                        BaseIngredients = product.BaseIngredients,
                        ProductVal = product.ProductVal,
                        CreatedAt = product.CreatedAt,
                        
                        // Aggregated variant data for display
                        MainSKU = mainSKU,
                        DisplayPrice = displayPrice,
                        TotalStock = displayStock,
                        TotalMinStock = displayMinStock,
                        VariantCount = variantCount,
                        LowStockVariants = lowStockVariants,
                        
                        // For compatibility with existing display methods
                        StockQuantity = displayStock,
                        MinimumStock = displayMinStock,
                        Price = displayPrice,
                        SKU = mainSKU,
                        
                        // Status indicators
                        IsLowStock = lowStockVariants > 0 || totalStock <= totalMinStock,
                        StockStatus = GetProductStockStatus(totalStock, totalMinStock, lowStockVariants),
                        PriceRange = lowestPrice == highestPrice ? $"₱{lowestPrice:F2}" : $"₱{lowestPrice:F2} - ₱{highestPrice:F2}",
                        
                        // Display information
                        DisplayName = variantCount > 1 ? $"{product.ProductName} ({variantCount} variants)" : product.ProductName,
                        StockDisplay = variantCount > 1 ? $"{totalStock} total" : totalStock.ToString()
                    };
                }).OrderBy(x => x.CreatedAt).ToList();

                if (productData.Count == 0)
                {
                    if (pnlLoading != null) pnlLoading.Visible = false;
                    if (pnlNoData != null) pnlNoData.Visible = true;
                    if (rptProductVariants != null) rptProductVariants.Visible = false;
                    return;
                }

                // Calculate stats
                var activeProductCount = productData.Count;
                var lowStockProductCount = productData.Count(p => p.IsLowStock);
                var categories = productData.Where(p => !string.IsNullOrEmpty(p.ProductCategory))
                                          .Select(p => p.ProductCategory).Distinct().Count();

                // Update UI
                if (pnlLoading != null) pnlLoading.Visible = false;
                if (pnlNoData != null) pnlNoData.Visible = false;
                if (rptProductVariants != null) rptProductVariants.Visible = true;

                // Bind data to repeater (reusing the same repeater but with product data)
                if (rptProductVariants != null)
                {
                    rptProductVariants.DataSource = productData;
                    rptProductVariants.DataBind();
                }

                // Update stats
                if (lblProductCount != null) lblProductCount.Text = activeProductCount.ToString();
                if (lblLowStockCount != null) lblLowStockCount.Text = lowStockProductCount.ToString();
                if (lblCategoryCount != null) lblCategoryCount.Text = categories.ToString();

            }
            catch (Exception ex)
            {
                if (pnlLoading != null) pnlLoading.Visible = false;
                if (pnlNoData != null) pnlNoData.Visible = true;
                if (rptProductVariants != null) rptProductVariants.Visible = false;

                if (lblProductCount != null) lblProductCount.Text = "Error";
                if (lblLowStockCount != null) lblLowStockCount.Text = "Error";
                if (lblCategoryCount != null) lblCategoryCount.Text = "Error";

                ShowMessage($"❌ Error loading data: {ex.Message}", "error");
            }
        }

        private string GenerateProductSKU(string productName)
        {
            // Generate a SKU based on product name
            var prefix = productName.Length >= 3 ? productName.Substring(0, 3).ToUpper() : productName.ToUpper();
            var timestamp = DateTime.Now.ToString("MMdd");
            return $"{prefix}-{timestamp}";
        }

        private string GetProductStockStatus(int totalStock, int totalMinStock, int lowStockVariants)
        {
            if (totalStock <= 0)
                return "Out of Stock";
            else if (lowStockVariants > 0)
                return $"Low Stock ({lowStockVariants} variants)";
            else if (totalStock <= totalMinStock)
                return "Low Stock";
            else if (totalStock <= totalMinStock * 2)
                return "Moderate Stock";
            else
                return "Ready Stock";
        }

        protected void rptProductVariants_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                // Any additional item binding logic can go here
            }
        }

        protected string GetDisplayName(string productName, object variantCount)
        {
            int count = Convert.ToInt32(variantCount);
            return count > 1 ? $"{productName} ({count} variants)" : productName;
        }

        protected string GetStockDisplay(object stockQuantity, object minimumStock)
        {
            try
            {
                int stock = Convert.ToInt32(stockQuantity);
                return $"{stock}";
            }
            catch
            {
                return "0";
            }
        }

        protected string GetStockCssClass(int stockQuantity, int minimumStock)
        {
            if (stockQuantity <= 0)
                return "low-stock";
            else if (stockQuantity <= minimumStock)
                return "low-stock";
            else if (stockQuantity <= minimumStock * 2)
                return "moderate-stock";
            else
                return "ready-stock";
        }

        protected string GetStockStatusForDisplay(int stockQuantity, int minimumStock)
        {
            if (stockQuantity <= 0)
                return "Out of Stock";
            else if (stockQuantity <= minimumStock)
                return "Low Stock";
            else if (stockQuantity <= minimumStock * 2)
                return "Moderate Stock";
            else
                return "Ready Stock";
        }

        protected string GetProductImage(string imageUrl)
        {
            if (string.IsNullOrEmpty(imageUrl) || imageUrl == "/Content/images/sample-generic.png")
            {
                return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAiIGhlaWdodD0iMzAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjMwIiBoZWlnaHQ9IjMwIiBmaWxsPSIjZjBmMGYwIi8+PHRleHQgeD0iMTUiIHk9IjE4IiBmb250LXNpemU9IjYiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPklNRzwvdGV4dD48L3N2Zz4K";
            }
            return imageUrl;
        }

        // Method to handle viewing variants for a specific product
        [System.Web.Services.WebMethod]
        public static string GetProductVariants(string productId)
        {
            try
            {
                var productService = new ProductService();
                var variants = productService.GetProductVariantsByProductIdAsync(productId).Result;
                
                var variantData = variants.Select(v => new
                {
                    Id = v.Id,
                    VariantName = v.VariantName,
                    SKU = v.SKU,
                    Size = v.Size,
                    Color = v.Color,
                    Price = v.Price,
                    StockQuantity = v.StockQuantity,
                    MinimumStock = v.MinimumStock,
                    IsLowStock = v.IsLowStock
                }).ToList();

                return JsonSerializer.Serialize(variantData);
            }
            catch (Exception ex)
            {
                return $"{{\"error\": \"{ex.Message}\"}}";
            }
        }

        private void ShowMessage(string message, string type)
        {
            if (pnlMessage != null && lblMessage != null)
            {
                pnlMessage.Visible = true;
                lblMessage.Text = message;

                switch (type.ToLower())
                {
                    case "success":
                        pnlMessage.CssClass = "success-container";
                        break;
                    case "error":
                        pnlMessage.CssClass = "error-container";
                        break;
                    case "info":
                        pnlMessage.CssClass = "success-container";
                        break;
                    default:
                        pnlMessage.CssClass = "error-container";
                        break;
                }
            }
        }

        // 🔄 Keep all existing product and variant creation methods unchanged
        protected async void btnSaveProduct_Click(object sender, EventArgs e)
        {
            try
            {
                // IMMEDIATE DEBUG OUTPUT
                System.Diagnostics.Debug.WriteLine("🚨🚨🚨 SERVER-SIDE CODE REACHED! 🚨🚨🚨");
                System.Diagnostics.Debug.WriteLine("🚨 btnSaveProduct_Click method is executing!");
                System.Diagnostics.Debug.WriteLine($"🚨 Current Time: {DateTime.Now}");
                System.Diagnostics.Debug.WriteLine($"🚨 IsPostBack: {Page.IsPostBack}");

                // Show immediate user feedback
                ShowMessage("🔄 Server processing started! Product is being saved...", "info");

                // Log form values immediately
                System.Diagnostics.Debug.WriteLine($"📝 Form Data Received:");
                System.Diagnostics.Debug.WriteLine($"  ➤ Product Name: '{txtProductName?.Text ?? "NULL"}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Category: '{ddlCategory?.SelectedValue ?? "NULL"}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Description: '{txtDescription?.Text ?? "NULL"}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Product Value: '{txtProductValue?.Text ?? "NULL"}'");

                // Basic validation
                if (string.IsNullOrWhiteSpace(txtProductName?.Text))
                {
                    System.Diagnostics.Debug.WriteLine("❌ VALIDATION FAILED: Product name is required!");
                    ShowMessage("❌ Product name is required!", "error");
                    return;
                }

                if (string.IsNullOrWhiteSpace(ddlCategory?.SelectedValue))
                {
                    System.Diagnostics.Debug.WriteLine("❌ VALIDATION FAILED: Category is required!");
                    ShowMessage("❌ Category is required!", "error");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("✅ VALIDATION PASSED - Creating product...");

                // Test database connection
                System.Diagnostics.Debug.WriteLine("🔗 Testing database connection...");
                try
                {
                    // Use shorter timeout for connection test
                    var connectionTask = DatabaseHelper.TestConnectionAsync();
                    bool isConnected = await connectionTask.ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"🔗 Database connection result: {isConnected}");

                    if (!isConnected)
                    {
                        System.Diagnostics.Debug.WriteLine("❌ DATABASE CONNECTION FAILED!");
                        ShowMessage("❌ Cannot connect to database. Please check your connection.", "error");
                        return;
                    }
                }
                catch (Exception connEx)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ Database connection exception: {connEx.Message}");
                    ShowMessage("❌ Database connection timeout. Proceeding with product creation...", "info");
                    // Don't return - try to continue anyway
                }

                // Create the product
                System.Diagnostics.Debug.WriteLine("📦 Creating product object...");
                var product = new Product();
                product.ProductName = txtProductName.Text.Trim();
                product.ProductDesc = txtDescription?.Text?.Trim() ?? "";
                product.ProductCategory = ddlCategory.SelectedValue;
                product.BaseIngredients = txtBaseIngredients?.Text?.Trim() ?? "";
                product.ProductImg = string.IsNullOrEmpty(txtImageUrl?.Text?.Trim()) ?
                    "/Content/images/sample-generic.png" : txtImageUrl.Text.Trim();
                product.Supplier = txtSupplier?.Text?.Trim() ?? "";

                // Handle ProductVal
                if (!string.IsNullOrEmpty(txtProductValue?.Text) && decimal.TryParse(txtProductValue.Text, out decimal value))
                {
                    product.ProductVal = value;
                }
                else
                {
                    product.ProductVal = 0;
                }

                System.Diagnostics.Debug.WriteLine($"📦 Product object created:");
                System.Diagnostics.Debug.WriteLine($"  ➤ Name: '{product.ProductName}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Category: '{product.ProductCategory}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Value: {product.ProductVal}");

                // Validate the product
                if (!product.IsValid())
                {
                    System.Diagnostics.Debug.WriteLine("❌ PRODUCT VALIDATION FAILED!");
                    ShowMessage("❌ Product validation failed. Please ensure name and category are provided.", "error");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("✅ PRODUCT VALIDATION PASSED");

                // Create ProductService and save with timeout handling
                System.Diagnostics.Debug.WriteLine("💾 Creating ProductService...");
                var productService = new ProductService();

                System.Diagnostics.Debug.WriteLine("💾 Calling CreateProductAsync...");
                try
                {
                    string productId = await productService.CreateProductAsync(product).ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"🆔 PRODUCT ID RECEIVED: '{productId}'");

                    if (string.IsNullOrEmpty(productId))
                    {
                        System.Diagnostics.Debug.WriteLine("❌ PRODUCT ID IS EMPTY!");
                        ShowMessage("❌ Failed to create product. Product ID is empty.", "error");
                        return;
                    }

                    // SUCCESS!
                    System.Diagnostics.Debug.WriteLine($"🎉🎉🎉 PRODUCT SAVED SUCCESSFULLY! 🎉🎉🎉");
                    System.Diagnostics.Debug.WriteLine($"🎉 Product: '{product.ProductName}'");
                    System.Diagnostics.Debug.WriteLine($"🎉 ID: '{productId}'");

                    // Store product info for variant creation with multiple methods
                    System.Diagnostics.Debug.WriteLine("💾 Storing product info in multiple places...");
                    Session["NewProductId"] = productId;
                    Session["NewProductName"] = product.ProductName;
                    Session["ProductId"] = productId; // Alternative key
                    Session["LastCreatedProductId"] = productId; // Another alternative

                    // Also store in ViewState as backup
                    ViewState["NewProductId"] = productId;
                    ViewState["NewProductName"] = product.ProductName;

                    System.Diagnostics.Debug.WriteLine($"💾 Session data stored:");
                    System.Diagnostics.Debug.WriteLine($"  ➤ NewProductId: '{Session["NewProductId"]}'");
                    System.Diagnostics.Debug.WriteLine($"  ➤ ProductId: '{Session["ProductId"]}'");
                    System.Diagnostics.Debug.WriteLine($"  ➤ ViewState NewProductId: '{ViewState["NewProductId"]}'");

                    ShowMessage($"✅ Product '{product.ProductName}' saved successfully! You can now add variants or save is complete.", "success");

                    // Clear the form
                    ClearProductForm();

                    // Use client-side script to show success and offer variant creation
                    string script = $@"
                        if (confirm('✅ Product saved successfully!\nProduct: {product.ProductName}\nID: {productId}\n\nWould you like to add product variants now?')) {{
                            // Close current modal and switch to variant modal
                            closeModal();
                            setTimeout(function() {{
                                showVariantModal('{productId}', '{product.ProductName}');
                            }}, 500);
                        }} else {{
                            // Just refresh to show the new product
                            setTimeout(function() {{ window.location.reload(); }}, 2000);
                        }}";

                    ClientScript.RegisterStartupScript(this.GetType(), "ProductSaved", script, true);
                }
                catch (Exception createEx)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ CREATE PRODUCT EXCEPTION: {createEx.Message}");
                    System.Diagnostics.Debug.WriteLine($"❌ Exception Details: {createEx}");
                    ShowMessage($"❌ Database error: {createEx.Message}", "error");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("🎉 === btnSaveProduct_Click COMPLETED SUCCESSFULLY ===");
            }
            catch (Exception ex)
            {
                // Log the full exception for debugging
                System.Diagnostics.Debug.WriteLine($"💥💥💥 FATAL ERROR in btnSaveProduct_Click 💥💥💥");
                System.Diagnostics.Debug.WriteLine($"💥 Exception: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"💥 Type: {ex.GetType().Name}");
                System.Diagnostics.Debug.WriteLine($"💥 Stack: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine($"💥 Inner: {ex.InnerException.Message}");
                }
                ShowMessage($"❌ Error saving product: {ex.Message}", "error");
            }
        }

        private string ValidateProductForm()
        {
            var errors = new List<string>();

            if (string.IsNullOrWhiteSpace(txtProductName.Text))
                errors.Add("Product name is required");

            if (string.IsNullOrWhiteSpace(ddlCategory.SelectedValue))
                errors.Add("Category is required");

            if (!string.IsNullOrWhiteSpace(txtProductValue.Text))
            {
                if (!decimal.TryParse(txtProductValue.Text, out decimal value) || value < 0)
                    errors.Add("Product value must be a valid positive number");
            }

            return string.Join(", ", errors);
        }

        private void ClearProductForm()
        {
            txtProductName.Text = string.Empty;
            txtDescription.Text = string.Empty;
            ddlCategory.SelectedIndex = 0;
            txtBaseIngredients.Text = string.Empty;
            txtImageUrl.Text = string.Empty;
            txtSupplier.Text = string.Empty;
            txtProductValue.Text = string.Empty;
        }

        protected async void btnSaveVariant_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🚨🚨🚨 SAVE VARIANT BUTTON CLICKED! 🚨🚨🚨");
                System.Diagnostics.Debug.WriteLine("🚨 btnSaveVariant_Click method is executing!");
                System.Diagnostics.Debug.WriteLine($"🚨 Current Time: {DateTime.Now}");

                // Enhanced session debugging
                System.Diagnostics.Debug.WriteLine("🔍 SESSION DEBUG:");
                System.Diagnostics.Debug.WriteLine($"  ➤ Session ID: {Session.SessionID}");
                System.Diagnostics.Debug.WriteLine($"  ➤ Session Count: {Session.Count}");
                System.Diagnostics.Debug.WriteLine($"  ➤ Session Keys: {string.Join(", ", Session.Keys.Cast<string>())}");

                // Check multiple possible sources for Product ID
                string productId = Session["NewProductId"]?.ToString();
                System.Diagnostics.Debug.WriteLine($"🔍 Session NewProductId: '{productId}'");

                if (string.IsNullOrEmpty(productId))
                {
                    // Try alternative session keys
                    productId = Session["ProductId"]?.ToString();
                    System.Diagnostics.Debug.WriteLine($"🔍 Session ProductId: '{productId}'");
                }

                if (string.IsNullOrEmpty(productId))
                {
                    // Try ViewState
                    productId = ViewState["NewProductId"]?.ToString();
                    System.Diagnostics.Debug.WriteLine($"🔍 ViewState NewProductId: '{productId}'");
                }

                if (string.IsNullOrEmpty(productId))
                {
                    // Try to get from hidden field or query string
                    productId = Request.QueryString["ProductId"];
                    System.Diagnostics.Debug.WriteLine($"🔍 QueryString ProductId: '{productId}'");
                }

                // For testing purposes, create a test product ID if none found
                if (string.IsNullOrEmpty(productId))
                {
                    System.Diagnostics.Debug.WriteLine("❌ NO PRODUCT ID FOUND IN ANY SOURCE!");
                    System.Diagnostics.Debug.WriteLine("🧪 ATTEMPTING TO FIND MOST RECENT PRODUCT...");

                    try
                    {
                        // Try to get the most recently created product
                        var variantProductService = new ProductService();
                        var allProducts = await variantProductService.GetAllProductsAsync().ConfigureAwait(false);
                        var mostRecentProduct = allProducts.OrderByDescending(p => p.CreatedAt).FirstOrDefault();

                        if (mostRecentProduct != null)
                        {
                            productId = mostRecentProduct.Id;
                            System.Diagnostics.Debug.WriteLine($"🎯 Using most recent product ID: '{productId}'");

                            // Store it in session for future use
                            Session["NewProductId"] = productId;
                            Session["NewProductName"] = mostRecentProduct.ProductName;

                            ShowMessage($"🔧 Using most recent product: {mostRecentProduct.ProductName}", "info");
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("❌ No products found in database!");
                            ShowMessage("❌ No products found. Please create a product first before adding variants.", "error");
                            return;
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"❌ Error finding recent product: {ex.Message}");
                        ShowMessage("❌ Error: Product ID not found. Please create a product first, then add variants.", "error");
                        return;
                    }
                }

                System.Diagnostics.Debug.WriteLine($"🔸 Creating variant for Product ID: {productId}");

                // Show immediate user feedback
                ShowMessage("🔄 Server processing variant... Please wait!", "info");

                // Log form values immediately
                System.Diagnostics.Debug.WriteLine($"📝 Variant Form Data Received:");
                System.Diagnostics.Debug.WriteLine($"  ➤ Variant Name: '{txtVariantName?.Text ?? "NULL"}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ SKU: '{txtVariantSKU?.Text ?? "NULL"}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Price: '{txtVariantPrice?.Text ?? "NULL"}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Stock: '{txtVariantStock?.Text ?? "NULL"}'");

                // Basic validation
                if (string.IsNullOrWhiteSpace(txtVariantName?.Text))
                {
                    System.Diagnostics.Debug.WriteLine("❌ VARIANT VALIDATION FAILED: Variant name is required!");
                    ShowMessage("❌ Variant name is required!", "error");
                    return;
                }

                if (string.IsNullOrWhiteSpace(txtVariantSKU?.Text))
                {
                    System.Diagnostics.Debug.WriteLine("❌ VARIANT VALIDATION FAILED: SKU is required!");
                    ShowMessage("❌ SKU is required!", "error");
                    return;
                }

                if (string.IsNullOrWhiteSpace(txtVariantPrice?.Text) || !decimal.TryParse(txtVariantPrice.Text, out decimal price) || price <= 0)
                {
                    System.Diagnostics.Debug.WriteLine("❌ VARIANT VALIDATION FAILED: Valid price is required!");
                    ShowMessage("❌ Valid price is required!", "error");
                    return;
                }

                if (string.IsNullOrWhiteSpace(txtVariantStock?.Text) || !int.TryParse(txtVariantStock.Text, out int stock) || stock < 0)
                {
                    System.Diagnostics.Debug.WriteLine("❌ VARIANT VALIDATION FAILED: Valid stock quantity is required!");
                    ShowMessage("❌ Valid stock quantity is required!", "error");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("✅ VARIANT VALIDATION PASSED");

                // Create variant using the constructor and form data
                var variant = new ProductVariant
                {
                    ProductId = productId,
                    VariantName = txtVariantName.Text.Trim(),
                    SKU = txtVariantSKU.Text.Trim(),
                    Size = txtVariantSize?.Text?.Trim() ?? "",
                    Color = txtVariantColor?.Text?.Trim() ?? "",
                    Price = price,
                    StockQuantity = stock,
                    MinimumStock = string.IsNullOrEmpty(txtVariantMinStock?.Text) ? 5 : int.Parse(txtVariantMinStock.Text),
                    Weight = string.IsNullOrEmpty(txtVariantWeight?.Text) ? (decimal?)null : decimal.Parse(txtVariantWeight.Text),
                    Dimensions = txtVariantDimensions?.Text?.Trim() ?? ""
                    // CreatedAt, UpdatedAt, and IsActive are set in constructor
                };

                System.Diagnostics.Debug.WriteLine($"🔸 Variant object created:");
                System.Diagnostics.Debug.WriteLine($"  ➤ Product ID: '{variant.ProductId}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Name: '{variant.VariantName}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ SKU: '{variant.SKU}'");
                System.Diagnostics.Debug.WriteLine($"  ➤ Price: {variant.Price}");
                System.Diagnostics.Debug.WriteLine($"  ➤ Stock: {variant.StockQuantity}");
                System.Diagnostics.Debug.WriteLine($"  ➤ Min Stock: {variant.MinimumStock}");

                // Test database connection with timeout handling
                System.Diagnostics.Debug.WriteLine("🔗 Testing database connection for variant...");
                try
                {
                    // Use shorter timeout for connection test
                    var connectionTask = DatabaseHelper.TestConnectionAsync();
                    bool isConnected = await connectionTask.ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"🔗 Database connection result: {isConnected}");

                    if (!isConnected)
                    {
                        System.Diagnostics.Debug.WriteLine("❌ DATABASE CONNECTION FAILED!");
                        ShowMessage("❌ Cannot connect to database. Please check your connection.", "error");
                        return;
                    }
                }
                catch (Exception connEx)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ Database connection exception: {connEx.Message}");
                    ShowMessage("❌ Database connection timeout. Proceeding with variant creation...", "info");
                    // Don't return - try to continue anyway
                }

                // Save the variant with timeout handling
                System.Diagnostics.Debug.WriteLine("💾 Creating ProductService for variant...");
                var variantService = new ProductService();

                System.Diagnostics.Debug.WriteLine("💾 Calling CreateProductVariantAsync...");
                try
                {
                    string variantId = await variantService.CreateProductVariantAsync(variant).ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"🔸 VARIANT ID RECEIVED: '{variantId}'");

                    if (string.IsNullOrEmpty(variantId))
                    {
                        System.Diagnostics.Debug.WriteLine("❌ VARIANT ID IS EMPTY!");
                        ShowMessage("❌ Failed to create variant. Variant ID is empty.", "error");
                        return;
                    }

                    // SUCCESS!
                    System.Diagnostics.Debug.WriteLine($"🎉🎉🎉 VARIANT SAVED SUCCESSFULLY! 🎉🎉🎉");
                    System.Diagnostics.Debug.WriteLine($"🎉 Variant: '{variant.VariantName}'");
                    System.Diagnostics.Debug.WriteLine($"🎉 ID: '{variantId}'");
                    System.Diagnostics.Debug.WriteLine($"🎉 SKU: '{variant.SKU}'");

                    ShowMessage($"✅ Product variant '{variant.VariantName}' saved successfully!", "success");

                    // Keep session data for potential additional variants
                    System.Diagnostics.Debug.WriteLine("🔄 Keeping session data for additional variants");

                    // Clear variant form
                    ClearVariantForm();

                    // Use client-side script to show success and refresh
                    string script = $@"
                        alert('✅ Product variant saved successfully!\nVariant: {variant.VariantName}\nSKU: {variant.SKU}\nID: {variantId}\n\nThe page will refresh to show your new variant.');
                        setTimeout(function() {{ window.location.reload(); }}, 2000);";

                    ClientScript.RegisterStartupScript(this.GetType(), "VariantSaved", script, true);
                }
                catch (Exception createEx)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ CREATE VARIANT EXCEPTION: {createEx.Message}");
                    System.Diagnostics.Debug.WriteLine($"❌ Exception Details: {createEx}");
                    ShowMessage($"❌ Variant save error: {createEx.Message}", "error");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("🎉 === btnSaveVariant_Click COMPLETED SUCCESSFULLY ===");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"💥💥💥 FATAL ERROR in btnSaveVariant_Click 💥💥💥");
                System.Diagnostics.Debug.WriteLine($"💥 Exception: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"💥 Type: {ex.GetType().Name}");
                System.Diagnostics.Debug.WriteLine($"💥 Stack: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine($"💥 Inner: {ex.InnerException.Message}");
                }
                ShowMessage($"❌ Error saving variant: {ex.Message}", "error");
            }
        }

        private string GenerateUniqueSKU()
        {
            // Generate a unique SKU based on timestamp and random number
            var timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
            var random = new Random().Next(100, 999);
            return $"SKU{timestamp}{random}";
        }

        // Enhanced database test method with detailed debugging
        private void TestDatabaseInsertion()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🧪 === STARTING DIRECT DATABASE INSERTION TEST ===");

                // Create a test product with the enhanced constructor
                var testProduct = new Product();
                testProduct.ProductName = "DIRECT TEST PRODUCT " + DateTime.Now.Ticks;
                testProduct.ProductDesc = "This is a direct test product for database insertion debugging";
                testProduct.ProductCategory = "Skincare";
                testProduct.BaseIngredients = "Test ingredients for validation";
                testProduct.ProductImg = "/Content/images/sample-generic.png";
                testProduct.Supplier = "Direct Test Supplier Inc.";
                testProduct.ProductVal = 99.99m;

                System.Diagnostics.Debug.WriteLine($"🧪 Test product created with values:");
                System.Diagnostics.Debug.WriteLine($"  - Name: '{testProduct.ProductName}'");
                System.Diagnostics.Debug.WriteLine($"  - Category: '{testProduct.ProductCategory}'");
                System.Diagnostics.Debug.WriteLine($"  - Description: '{testProduct.ProductDesc}'");
                System.Diagnostics.Debug.WriteLine($"  - Value: {testProduct.ProductVal}");
                System.Diagnostics.Debug.WriteLine($"  - Is Valid: {testProduct.IsValid()}");

                if (!testProduct.IsValid())
                {
                    System.Diagnostics.Debug.WriteLine("❌ Test product validation failed!");
                    return;
                }

                // Test database connection first
                System.Diagnostics.Debug.WriteLine("🧪 Testing database connection...");
                bool isConnected = DatabaseHelper.TestConnectionAsync().Result;
                if (!isConnected)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Database connection test FAILED!");
                    return;
                }
                System.Diagnostics.Debug.WriteLine("✅ Database connection verified");

                // Get collection and test access
                System.Diagnostics.Debug.WriteLine("🧪 Testing collection access...");
                var collection = DatabaseHelper.GetProductsCollection();
                if (collection == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Products collection is NULL!");
                    return;
                }

                var countBefore = collection.CountDocuments(FilterDefinition<Product>.Empty);
                System.Diagnostics.Debug.WriteLine($"🧪 Products in database before insert: {countBefore}");

                // Create ProductService and insert
                System.Diagnostics.Debug.WriteLine("🧪 Creating ProductService...");
                var productService = new ProductService();

                System.Diagnostics.Debug.WriteLine("🧪 Calling CreateProductAsync...");
                var result = productService.CreateProductAsync(testProduct).Result;

                System.Diagnostics.Debug.WriteLine($"🧪 CreateProductAsync returned: '{result}'");

                if (!string.IsNullOrEmpty(result))
                {
                    System.Diagnostics.Debug.WriteLine("✅ Database insertion test PASSED!");

                    // Verify count increased
                    var countAfter = collection.CountDocuments(FilterDefinition<Product>.Empty);
                    System.Diagnostics.Debug.WriteLine($"🧪 Products in database after insert: {countAfter}");
                    System.Diagnostics.Debug.WriteLine($"🧪 Count increased by: {countAfter - countBefore}");

                    // Try to retrieve the product to verify
                    var allProducts = productService.GetAllProductsAsync().Result;
                    var foundProduct = allProducts.FirstOrDefault(p => p.Id == result);

                    if (foundProduct != null)
                    {
                        System.Diagnostics.Debug.WriteLine($"✅ Product verified in database:");
                        System.Diagnostics.Debug.WriteLine($"  - ID: '{foundProduct.Id}'");
                        System.Diagnostics.Debug.WriteLine($"  - Name: '{foundProduct.ProductName}'");
                        System.Diagnostics.Debug.WriteLine($"  - Category: '{foundProduct.ProductCategory}'");
                        System.Diagnostics.Debug.WriteLine($"  - CreatedAt: {foundProduct.CreatedAt}");
                        System.Diagnostics.Debug.WriteLine($"✅ Total products in database: {allProducts.Count}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine("❌ Product not found during verification");
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("❌ Database insertion test FAILED - No ID returned");
                }

                System.Diagnostics.Debug.WriteLine("🧪 === DATABASE INSERTION TEST COMPLETED ===");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Database insertion test ERROR: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"❌ Exception type: {ex.GetType().Name}");
                System.Diagnostics.Debug.WriteLine($"❌ Stack trace: {ex.StackTrace}");

                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ Inner exception: {ex.InnerException.Message}");
                    System.Diagnostics.Debug.WriteLine($"❌ Inner exception type: {ex.InnerException.GetType().Name}");
                }
            }
        }

        // Add a button click event to test database insertion from UI
        protected void btnTestDatabase_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🚨🚨🚨 TEST DATABASE BUTTON CLICKED! 🚨🚨🚨");
                System.Diagnostics.Debug.WriteLine("🚨 Server-side test method is executing!");
                System.Diagnostics.Debug.WriteLine($"🚨 Current Time: {DateTime.Now}");

                // Show immediate feedback
                ShowMessage("🔄 Running database test... Server-side code is working!", "info");

                // Simple test first - just show we reached the server
                System.Diagnostics.Debug.WriteLine("✅ SERVER-SIDE CODE IS WORKING!");

                // Test basic database connection
                System.Diagnostics.Debug.WriteLine("🧪 Testing basic database connection...");
                bool isConnected = DatabaseHelper.TestConnectionAsync().Result;
                System.Diagnostics.Debug.WriteLine($"🧪 Database connection result: {isConnected}");

                if (!isConnected)
                {
                    ShowMessage("❌ Database connection failed! Check your MongoDB connection.", "error");
                    return;
                }

                // Test collection access
                System.Diagnostics.Debug.WriteLine("🧪 Testing collection access...");
                var collection = DatabaseHelper.GetProductsCollection();
                if (collection == null)
                {
                    ShowMessage("❌ Cannot access Products collection!", "error");
                    return;
                }

                // Count existing products
                var currentCount = collection.CountDocuments(FilterDefinition<Product>.Empty);
                System.Diagnostics.Debug.WriteLine($"🧪 Current products in database: {currentCount}");

                // Run the full test
                TestDatabaseInsertion();

                ShowMessage($"✅ Database test completed! Found {currentCount} products. Check Visual Studio Debug Output for detailed results.", "success");

                System.Diagnostics.Debug.WriteLine("🎯 === btnTestDatabase_Click COMPLETED ===");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"💥 btnTestDatabase_Click failed: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"💥 Stack trace: {ex.StackTrace}");
                ShowMessage($"❌ Database test failed: {ex.Message}", "error");
            }
        }

        private void ClearVariantForm()
        {
            txtVariantName.Text = string.Empty;
            txtVariantSKU.Text = string.Empty;
            txtVariantSize.Text = string.Empty;
            txtVariantColor.Text = string.Empty;
            txtVariantPrice.Text = string.Empty;
            txtVariantStock.Text = string.Empty;
            txtVariantMinStock.Text = string.Empty;
            txtVariantWeight.Text = string.Empty;
            txtVariantDimensions.Text = string.Empty;
        }
    }
}