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
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.Script.Serialization;
using System.IO;
using System.Web;

namespace InventorySystemSiaProject.WebPages
{

    public partial class ProductPage : System.Web.UI.Page
    {
        private ProductService _productService;
        private SupplierService _supplierService;

        // Small inline SVG placeholder to avoid 404s for missing images
        private const string DefaultImageDataUri = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjgwIiB2aWV3Qm94PSIwIDAgMTAwIDgwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxyZWN0IHdpZHRoPSIxMDAiIGhlaWdodD0iODAiIHJ4PSIxMiIgZmlsbD0iI2YwZjBmMCIvPjxwYXRoIGQ9Ik0yMCA2MEwzOCA0MGEyIDIgMCAwMTMgMGwxOSAyMGgyMCIgc3Ryb2tlPSIjZWVlIiBzdHJva2Utd2lkdGg9IjIiIGZpbGw9IiNmZmYiLz48Y2lyY2xlIGN4PSI0NSIgY3k9IjMwIiByPSIxMSIgZmlsbD0iI2ZmZiIgc3Ryb2tlPSIjZWVlIi8+PHRleHQgeD0iNTAiIHk9IjQ0IiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPk5vIEltYWdlPC90ZXh0Pjwvc3ZnPiI=";

        protected void Page_Load(object sender, EventArgs e)
        {
            // Check if user is logged in
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }

            _productService = new ProductService();
            _supplierService = new SupplierService();

            if (!IsPostBack)
            {
                // Load suppliers into dropdown
                RegisterAsyncTask(new PageAsyncTask(LoadSuppliersAsync));
            }

            // Always refresh the list on any load/postback so CRUD reflects immediately
            RegisterAsyncTask(new PageAsyncTask(LoadProductsAsync));
        }

        private async Task LoadSuppliersAsync()
        {
            try
            {
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                
                // Populate the Add Product modal supplier dropdown
                ddlSupplier.Items.Clear();
                ddlSupplier.Items.Add(new ListItem("Select Supplier", ""));
                
                foreach (var supplier in suppliers)
                {
                    ddlSupplier.Items.Add(new ListItem(supplier.SupName, supplier.SupplierID));
                }
                
                // Also prepare suppliers list for JavaScript (for Update modal)
                var suppliersJson = new System.Web.Script.Serialization.JavaScriptSerializer()
                    .Serialize(suppliers.Select(s => new { id = s.SupplierID, name = s.SupName }).ToList());
                
                ClientScript.RegisterStartupScript(this.GetType(), "LoadSuppliers", 
                    $"window.suppliersList = {suppliersJson};", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error loading suppliers: {ex.Message}");
                // Add a default item if loading fails
                ddlSupplier.Items.Clear();
                ddlSupplier.Items.Add(new ListItem("Select Supplier", ""));
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

                // Get all suppliers and create a lookup dictionary
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                var supplierLookup = suppliers.ToDictionary(s => s.SupplierID, s => s);

                // Populate Supplier navigation property for each product
                foreach (var product in products)
                {
                    if (!string.IsNullOrEmpty(product.SupplierId) && supplierLookup.ContainsKey(product.SupplierId))
                    {
                        product.Supplier = supplierLookup[product.SupplierId];
                    }
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
                        SupplierId = product.SupplierId,
                        Supplier = product.Supplier?.SupName ?? "N/A", // Add Supplier name
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
                        PriceRange = lowestPrice == highestPrice ? string.Format("₱{0:F2}", lowestPrice) : string.Format("₱{0:F2} - ₱{1:F2}", lowestPrice, highestPrice),

                        // Display information
                        DisplayName = variantCount > 1 ? string.Format("{0} ({1} variants)", product.ProductName, variantCount) : product.ProductName,
                        StockDisplay = variantCount > 1 ? string.Format("{0} total", totalStock) : totalStock.ToString()
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

                ShowMessage(string.Format("❌ Error loading data: {0}", ex.Message), "error");
            }
        }

        private string GenerateProductSKU(string productName)
        {
            // Generate a SKU based on product name
            var prefix = productName.Length >= 3 ? productName.Substring(0, 3).ToUpper() : productName.ToUpper();
            var timestamp = DateTime.Now.ToString("MMdd");
            return string.Format("{0}-{1}", prefix, timestamp);
        }

        private string GetProductStockStatus(int totalStock, int totalMinStock, int lowStockVariants)
        {
            if (totalStock <= 0)
                return "Out of Stock";
            else if (lowStockVariants > 0)
                return string.Format("Low Stock ({0} variants)", lowStockVariants);
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
            return count > 1 ? string.Format("{0} ({1} variants)", productName, count) : productName;
        }

        protected string GetStockDisplay(object stockQuantity, object minimumStock)
        {
            try
            {
                int stock = Convert.ToInt32(stockQuantity);
                return stock.ToString();
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

        // Safe overload for nullable/object types from Eval
        protected string GetStockCssClass(object stockQuantity, object minimumStock)
        {
            try
            {
                int stock = stockQuantity != null ? Convert.ToInt32(stockQuantity) : 0;
                int minStock = minimumStock != null ? Convert.ToInt32(minimumStock) : 0;
                return GetStockCssClass(stock, minStock);
            }
            catch
            {
                return "ready-stock"; // Default safe fallback
            }
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

        // Safe overload for nullable/object types from Eval
        protected string GetStockStatusForDisplay(object stockQuantity, object minimumStock)
        {
            try
            {
                int stock = stockQuantity != null ? Convert.ToInt32(stockQuantity) : 0;
                int minStock = minimumStock != null ? Convert.ToInt32(minimumStock) : 0;
                return GetStockStatusForDisplay(stock, minStock);
            }
            catch
            {
                return "Unknown"; // Default safe fallback
            }
        }

        protected string GetProductImage(string imageUrl)
        {
            if (string.IsNullOrWhiteSpace(imageUrl) || imageUrl == "/Content/images/sample-generic.png")
            {
                return DefaultImageDataUri;
            }

            imageUrl = imageUrl.Trim();

            // Remove wrapping quotes
            if ((imageUrl.StartsWith("\"") && imageUrl.EndsWith("\"")) || (imageUrl.StartsWith("'") && imageUrl.EndsWith("'")))
            {
                imageUrl = imageUrl.Substring(1, imageUrl.Length - 2).Trim();
            }

            // Fix legacy leading slash before schemes and malformed single-slash schemes
            if (imageUrl.StartsWith("/data:", StringComparison.OrdinalIgnoreCase)) imageUrl = imageUrl.Substring(1);
            if (imageUrl.StartsWith("/http://", StringComparison.OrdinalIgnoreCase)) imageUrl = imageUrl.Substring(1);
            if (imageUrl.StartsWith("/https://", StringComparison.OrdinalIgnoreCase)) imageUrl = imageUrl.Substring(1);
            if (imageUrl.StartsWith("http:/") && !imageUrl.StartsWith("http://")) imageUrl = imageUrl.Replace("http:/", "http://");
            if (imageUrl.StartsWith("https:/") && !imageUrl.StartsWith("https://")) imageUrl = imageUrl.Replace("https:/", "https://");

            // If the string contains an embedded valid URL, extract it (guards mixed values like "prefix https://... suffix")
            try
            {
                var httpIdx = imageUrl.IndexOf("http://", StringComparison.OrdinalIgnoreCase);
                var httpsIdx = imageUrl.IndexOf("https://", StringComparison.OrdinalIgnoreCase);
                int idx = (httpsIdx >= 0 && (httpIdx < 0 || httpsIdx < httpIdx)) ? httpsIdx : httpIdx;
                if (idx >= 0)
                {
                    var fragment = imageUrl.Substring(idx);
                    // stop at first space or quote
                    int end = fragment.IndexOf(' ');
                    if (end < 0) end = fragment.IndexOf('\"');
                    if (end < 0) end = fragment.IndexOf('\'');
                    if (end > 0) fragment = fragment.Substring(0, end);
                    imageUrl = fragment.Trim();
                }
            }
            catch { }

            // Accept absolute and data URIs
            if (imageUrl.StartsWith("data:", StringComparison.OrdinalIgnoreCase) ||
                imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
                imageUrl.StartsWith("//"))
            {
                return imageUrl;
            }

            // If appears to be a data URI but with a stray leading slash once again
            if (imageUrl.StartsWith("data%3A", StringComparison.OrdinalIgnoreCase))
            {
                // url-encoded data: scheme -> decode minimal
                try { return Uri.UnescapeDataString(imageUrl); } catch { return DefaultImageDataUri; }
            }

            // For relative paths, do not try to prefix if they look like schemes (avoid '/data:')
            if (!imageUrl.Contains(":"))
            {
                if (!imageUrl.StartsWith("/")) imageUrl = "/" + imageUrl;
                return imageUrl;
            }

            // Fallback
            return DefaultImageDataUri;
        }

        // NEW: Simple test method that just returns a basic response
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string TestBasicConnection()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🧪 TestBasicConnection called");

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new
                {
                    success = true,
                    message = "WebMethod is working",
                    timestamp = DateTime.Now.ToString(),
                    serverTime = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("💥 TestBasicConnection error: {0}", ex.Message));
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        // Method to handle viewing variants for a specific product
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetProductVariants(string productId)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine(string.Format("🔍 GetProductVariants called with productId='{0}'", productId));

                // Validate input
                if (string.IsNullOrEmpty(productId))
                {
                    System.Diagnostics.Debug.WriteLine("❌ ProductId is null or empty");
                    var serializer1 = new JavaScriptSerializer();
                    return serializer1.Serialize(new { error = "Product ID is required" });
                }

                var productService = new ProductService();

                // Get variants for the specific product
                System.Diagnostics.Debug.WriteLine("📊 Calling GetProductVariantsByProductIdAsync...");
                var variants = productService.GetProductVariantsByProductIdAsync(productId)
                                             .GetAwaiter()
                                             .GetResult();

                System.Diagnostics.Debug.WriteLine(string.Format("📊 Found {0} variants", variants != null ? variants.Count : 0));

                if (variants == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Variants is null");
                    var serializer2 = new JavaScriptSerializer();
                    return serializer2.Serialize(new List<object>());
                }

                // Transform to simple objects for JSON serialization
                var variantData = variants.Where(v => v.IsActive).Select(v => new
                {
                    Id = v.Id ?? "",
                    VariantName = v.VariantName ?? "",
                    SKU = v.SKU ?? "",
                    Size = v.Size ?? "",
                    Color = v.Color ?? "",
                    Price = v.Price,
                    StockQuantity = v.StockQuantity,
                    MinimumStock = v.MinimumStock,
                    IsLowStock = v.IsLowStock,
                    Weight = v.Weight,
                    Dimensions = v.Dimensions ?? ""
                }).ToList();

                // Use JavaScriptSerializer for WebForms compatibility
                var serializer = new JavaScriptSerializer();
                var json = serializer.Serialize(variantData);

                System.Diagnostics.Debug.WriteLine(string.Format("✅ GetProductVariants returning {0} items", variantData.Count));
                System.Diagnostics.Debug.WriteLine(string.Format("📊 JSON: {0}", json.Length > 200 ? json.Substring(0, 200) + "..." : json));

                return json;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("💥 GetProductVariants error: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("💥 Stack trace: {0}", ex.StackTrace));

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { error = ex.Message, details = ex.StackTrace });
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
                // Server-side double-submit guard using a token timestamp
                var lastSubmit = Session["LastProductSubmitAt"] as DateTime?;
                var now = DateTime.UtcNow;
                if (lastSubmit.HasValue && (now - lastSubmit.Value).TotalSeconds < 3)
                {
                    ShowMessage("⏳ Duplicate submit ignored.", "info");
                    return;
                }
                Session["LastProductSubmitAt"] = now;

                // Basic validation
                if (string.IsNullOrWhiteSpace(txtProductName?.Text))
                {
                    ShowMessage("❌ Product name is required!", "error");
                    return;
                }
                if (string.IsNullOrWhiteSpace(ddlCategory?.SelectedValue))
                {
                    ShowMessage("❌ Category is required!", "error");
                    return;
                }

                var product = new Product();
                product.ProductName = txtProductName.Text.Trim();
                product.ProductDesc = txtDescription?.Text?.Trim() ?? "";
                product.ProductCategory = ddlCategory.SelectedValue;
                product.BaseIngredients = txtBaseIngredients?.Text?.Trim() ?? "";
                var url = txtProductImageUrl?.Text?.Trim();
                if (string.IsNullOrWhiteSpace(url))
                {
                    product.ProductImg = "/Content/images/sample-generic.png";
                }
                else
                {
                    // Accept data URIs, http(s), protocol-relative (//), and relative paths
                    if (url.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
                    {
                        product.ProductImg = url; // keep inline data image
                    }
                    else if (url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) || url.StartsWith("https://", StringComparison.OrdinalIgnoreCase) || url.StartsWith("//"))
                    {
                        product.ProductImg = url;
                    }
                    else
                    {
                        // Coerce to app-root relative path
                        if (!url.StartsWith("/")) url = "/" + url;
                        product.ProductImg = url;
                    }
                }
                // Use the supplier dropdown instead of textbox
                product.SupplierId = ddlSupplier?.SelectedValue ?? "";

                var productService = new ProductService();

                // Idempotency guard: if user double-clicks save, prevent duplicate by checking recent same name+category
                var existing = await productService.FindRecentDuplicateAsync(product.ProductName, product.ProductCategory, TimeSpan.FromMinutes(2)).ConfigureAwait(false);
                if (existing != null)
                {
                    Session["NewProductId"] = existing.Id;
                    Session["NewProductName"] = existing.ProductName;
                    ViewState["NewProductId"] = existing.Id;
                    ViewState["NewProductName"] = existing.ProductName;

                    ShowMessage($"ℹ️ Product '{existing.ProductName}' already exists (recent). Using existing record.", "info");
                    ClearProductForm();

                    // Rebind the list so it reflects immediately
                    await LoadProductsAsync();

                    // Reset client saving guard
                    ClientScript.RegisterStartupScript(this.GetType(), "ResetSavingGuard", "window.__savingProduct=false;", true);
                    return;
                }

                var productId = await productService.CreateProductAsync(product).ConfigureAwait(false);
                if (string.IsNullOrEmpty(productId))
                {
                    ShowMessage("❌ Failed to create product.", "error");
                    return;
                }

                Session["NewProductId"] = productId;
                Session["NewProductName"] = product.ProductName;
                ViewState["NewProductId"] = productId;
                ViewState["NewProductName"] = product.ProductName;

                ShowMessage(string.Format("✅ Product '{0}' saved successfully!", product.ProductName), "success");
                ClearProductForm();

                // Rebind list after create
                await LoadProductsAsync();

                // Reset client saving guard
                ClientScript.RegisterStartupScript(this.GetType(), "ResetSavingGuard", "window.__savingProduct=false;", true);
            }
            catch (Exception ex)
            {
                ShowMessage(string.Format("❌ Error saving product: {0}", ex.Message), "error");
                ClientScript.RegisterStartupScript(this.GetType(), "ResetSavingGuardErr", "window.__savingProduct=false;", true);
            }
        }

        private void ClearProductForm()
        {
            txtProductName.Text = string.Empty;
            txtDescription.Text = string.Empty;
            ddlCategory.SelectedIndex = 0;
            txtBaseIngredients.Text = string.Empty;
            ddlSupplier.SelectedIndex = 0; // Clear supplier dropdown
            if (txtProductImageUrl != null) txtProductImageUrl.Text = string.Empty;
        }

        protected async void btnSaveVariant_Click(object sender, EventArgs e)
        {
            try
            {
                // Check multiple possible sources for Product ID
                string productId = Session["NewProductId"]?.ToString();
                if (string.IsNullOrEmpty(productId)) productId = Session["ProductId"]?.ToString();
                if (string.IsNullOrEmpty(productId)) productId = ViewState["NewProductId"]?.ToString();
                if (string.IsNullOrEmpty(productId)) productId = Request.QueryString["ProductId"];

                if (string.IsNullOrEmpty(productId))
                {
                    try
                    {
                        var variantProductService = new ProductService();
                        var allProducts = await variantProductService.GetAllProductsAsync().ConfigureAwait(false);
                        var mostRecentProduct = allProducts.OrderByDescending(p => p.CreatedAt).FirstOrDefault();
                        if (mostRecentProduct != null)
                        {
                            productId = mostRecentProduct.Id;
                            Session["NewProductId"] = productId;
                            Session["NewProductName"] = mostRecentProduct.ProductName;
                            ShowMessage(string.Format("🔧 Using most recent product: {0}", mostRecentProduct.ProductName), "info");
                        }
                        else
                        {
                            ShowMessage("❌ No products found. Please create a product first before adding variants.", "error");
                            return;
                        }
                    }
                    catch (Exception)
                    {
                        ShowMessage("❌ Error: Product ID not found. Please create a product first, then add variants.", "error");
                        return;
                    }
                }

                // Basic validation
                if (string.IsNullOrWhiteSpace(txtVariantName?.Text)) { ShowMessage("❌ Variant name is required!", "error"); return; }
                if (string.IsNullOrWhiteSpace(txtVariantSKU?.Text)) { ShowMessage("❌ SKU is required!", "error"); return; }
                if (string.IsNullOrWhiteSpace(txtVariantPrice?.Text) || !decimal.TryParse(txtVariantPrice.Text, out decimal price) || price <= 0) { ShowMessage("❌ Valid price is required!", "error"); return; }
                if (string.IsNullOrWhiteSpace(txtVariantStock?.Text) || !int.TryParse(txtVariantStock.Text, out int stock) || stock < 0) { ShowMessage("❌ Valid stock quantity is required!", "error"); return; }

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
                    Dimensions = txtVariantDimensions?.Text?.Trim() ?? "",
                    VariantImg = txtVariantImageUrl?.Text?.Trim() ?? string.Empty
                };

                // Cloudinary upload for variant image
                if (fuVariantImage != null && fuVariantImage.HasFile)
                {
                    try
                    {
                        var vUrl = CloudinaryHelper.UploadImage(fuVariantImage.PostedFile, "variants");
                        if (!string.IsNullOrWhiteSpace(vUrl)) { variant.VariantImg = vUrl; }
                    }
                    catch { }
                }

                // Save the variant
                var variantService = new ProductService();
                string variantId = await variantService.CreateProductVariantAsync(variant).ConfigureAwait(false);
                if (string.IsNullOrEmpty(variantId)) { ShowMessage("❌ Failed to create variant.", "error"); return; }

                ShowMessage(string.Format("✅ Product variant '{0}' saved successfully!", variant.VariantName), "success");

                // Clear variant form
                ClearVariantForm();

                // Rebind list to reflect variant stock/price changes
                await LoadProductsAsync();
            }
            catch (Exception ex)
            {
                ShowMessage(string.Format("❌ Error saving variant: {0}", ex.Message), "error");
            }
        }

        [System.Web.Services.WebMethod(EnableSession = false)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetProductWithVariantsAggregationSafeCompat()
        {
            var serializer = new JavaScriptSerializer();
            try
            {
                // Parse productId from either standard ASP.NET AJAX (response.d) or raw body
                string productId = null;

                try
                {
                    // If called through ASP.NET ScriptManager, parameters are bound automatically.
                    // But to be safe, read raw body and parse manually if needed.
                    using (var reader = new StreamReader(HttpContext.Current.Request.InputStream))
                    {
                        HttpContext.Current.Request.InputStream.Position = 0;
                        var raw = reader.ReadToEnd();
                        if (!string.IsNullOrWhiteSpace(raw))
                        {
                            // payload like: {"productId":"..."}
                            var dict = serializer.Deserialize<Dictionary<string, object>>(raw);
                            if (dict != null && dict.ContainsKey("productId") && dict["productId"] != null)
                            {
                                productId = dict["productId"].ToString();
                            }
                        }
                    }
                }
                catch { /* ignore body parse errors */ }

                // Fallback: also try query string to ease manual testing
                if (string.IsNullOrWhiteSpace(productId))
                {
                    productId = HttpContext.Current.Request.QueryString["productId"];
                }

                if (string.IsNullOrWhiteSpace(productId))
                {
                    return serializer.Serialize(new { error = "Product ID is required" });
                }

                // Quick sanity check for Mongo ObjectId format to avoid 500
                if (productId.Length != 24 || !System.Text.RegularExpressions.Regex.IsMatch(productId, "^[0-9a-fA-F]{24}$"))
                {
                    return serializer.Serialize(new { error = "Invalid productId format (expected 24-hex ObjectId)" });
                }

                var productService = new ProductService();

                var products = productService.GetAllProductsAsync().GetAwaiter().GetResult();
                var product = products.FirstOrDefault(p => p.Id == productId && p.IsActive);
                if (product == null)
                {
                    return serializer.Serialize(new { error = "Product not found" });
                }

                var allVariants = productService.GetAllProductVariantsAsync().GetAwaiter().GetResult();
                var productVariants = allVariants.Where(v => v.ProductId == productId && v.IsActive).ToList();

                var variantsList = productVariants.Select(v => new
                {
                    Id = v.Id ?? string.Empty,
                    VariantName = v.VariantName ?? string.Empty,
                    SKU = v.SKU ?? string.Empty,
                    Size = v.Size ?? string.Empty,
                    Color = v.Color ?? string.Empty,
                    Price = v.Price,
                    StockQuantity = v.StockQuantity,
                    MinimumStock = v.MinimumStock,
                    Weight = v.Weight,
                    Dimensions = v.Dimensions ?? string.Empty,
                    IsActive = v.IsActive,
                    CreatedAt = v.CreatedAt,
                    UpdatedAt = v.UpdatedAt
                }).ToList();

                var productInfo = new
                {
                    Id = product.Id,
                    ProductName = product.ProductName,
                    ProductDesc = product.ProductDesc,
                    ProductCategory = product.ProductCategory,
                    ProductImg = product.ProductImg,
                    SupplierId = product.SupplierId,
                    BaseIngredients = product.BaseIngredients,
                    ProductVal = product.ProductVal,
                    IsActive = product.IsActive,
                    CreatedAt = product.CreatedAt
                };

                return serializer.Serialize(new
                {
                    success = true,
                    product = productInfo,
                    variants = variantsList,
                    variantCount = variantsList.Count,
                    message = "Compat method used",
                    aggregationUsed = false
                });
            }
            catch (Exception ex)
            {
                return serializer.Serialize(new { error = ex.Message });
            }
        }
        private void ClearVariantForm()
        {
            if (txtVariantName != null) txtVariantName.Text = string.Empty;
            if (txtVariantSKU != null) txtVariantSKU.Text = string.Empty;
            if (txtVariantSize != null) txtVariantSize.Text = string.Empty;
            if (txtVariantColor != null) txtVariantColor.Text = string.Empty;
            if (txtVariantPrice != null) txtVariantPrice.Text = string.Empty;
            if (txtVariantStock != null) txtVariantStock.Text = string.Empty;
            if (txtVariantMinStock != null) txtVariantMinStock.Text = string.Empty;
            if (txtVariantWeight != null) txtVariantWeight.Text = string.Empty;
            if (txtVariantDimensions != null) txtVariantDimensions.Text = string.Empty;
            if (txtVariantImageUrl != null) txtVariantImageUrl.Text = string.Empty;
        }
    }
}