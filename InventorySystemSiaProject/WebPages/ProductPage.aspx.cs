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
using Newtonsoft.Json;

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

            _productService = new ProductService();
            _supplierService = new SupplierService();

            // ✅ FIX: Always load suppliers on every page load (including postbacks)
            // This ensures the dropdown persists after updates
            RegisterAsyncTask(new PageAsyncTask(LoadSuppliersAsync));

            // Always refresh the list on any load/postback so CRUD reflects immediately
            RegisterAsyncTask(new PageAsyncTask(LoadProductsAsync));
        }

        private async Task LoadSuppliersAsync()
        {
            try
            {
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                
                // ✅ FIX: Preserve selected value during postbacks
             
                
                // Populate the Add Product modal supplier dropdown
              
                
              
                
                // ✅ FIX: Restore previously selected value if it exists
            
                
                // Also prepare suppliers list for JavaScript (for Update modal)
                var suppliersJson = new System.Web.Script.Serialization.JavaScriptSerializer()
                    .Serialize(suppliers.Select(s => new { id = s.SupplierID, name = s.SupName }).ToList());
                
                ClientScript.RegisterStartupScript(this.GetType(), "LoadSuppliers", 
                    $"window.suppliersList = {suppliersJson};", true);
                
                System.Diagnostics.Debug.WriteLine($"✅ Loaded {suppliers.Count} suppliers into dropdown");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error loading suppliers: {ex.Message}");
                // Add a default item if loading fails
              
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

                // ✅ FIX: Use ProductService methods instead of direct collection access
                var products = await _productService.GetAllProductsAsync();
                var variants = await _productService.GetAllProductVariantsAsync();

                if (products.Count == 0)
                {
                    if (pnlLoading != null) pnlLoading.Visible = false;
                    if (pnlNoData != null) pnlNoData.Visible = true;
                    if (rptProductVariants != null) rptProductVariants.Visible = false;
                    return;
                }

                // Group variants by product
                var variantsByProduct = variants.Where(v => v.IsActive)
                    .GroupBy(v => v.ProductId)
                    .ToDictionary(g => g.Key, g => g.ToList());

                var productData = products
                    .Where(p => p.status == null || p.status == "Active")
                    .Select(product => {
                        var productVariants = variantsByProduct.ContainsKey(product.Id)
                            ? variantsByProduct[product.Id]
                            : new List<ProductVariant>();

                        var totalStock = productVariants.Sum(v => v.StockQuantity);
                        var totalMinStock = productVariants.Sum(v => v.MinimumStock);
                        var lowestPrice = productVariants.Any() ? productVariants.Min(v => v.Price) : product.productVal;
                        var highestPrice = productVariants.Any() ? productVariants.Max(v => v.Price) : product.productVal;
                        var variantCount = productVariants.Count;
                        var lowStockVariants = productVariants.Count(v => v.IsLowStock);
                        var mainSKU = productVariants.FirstOrDefault()?.SKU ?? GenerateProductSKU(product.productName);

                        return new
                        {
                            ProductId = product.Id,
                            productName = product.productName,
                            ProductDesc = product.productDesc,
                            ProductCategory = product.productCategory,
                            ProductImg = "", // ✅ Leave empty - use handler to load images
                            baseIngredients = product.baseIngredients,
                            ProductVal = product.productVal,
                            CreatedAt = product.createdAt,
                            MainSKU = mainSKU,
                            DisplayPrice = productVariants.FirstOrDefault()?.Price ?? product.productVal,
                            TotalStock = totalStock,
                            TotalMinStock = totalMinStock,
                            VariantCount = variantCount,
                            LowStockVariants = lowStockVariants,
                            StockQuantity = totalStock,
                            MinimumStock = totalMinStock,
                            Price = lowestPrice,
                            SKU = mainSKU,
                            IsLowStock = lowStockVariants > 0 || totalStock <= totalMinStock,
                            StockStatus = GetProductStockStatus(totalStock, totalMinStock, lowStockVariants),
                            PriceRange = lowestPrice == highestPrice
                                ? string.Format("₱{0:F2}", lowestPrice)
                                : string.Format("₱{0:F2} - ₱{1:F2}", lowestPrice, highestPrice),
                            DisplayName = variantCount > 1
                                ? string.Format("{0} ({1} variants)", product.productName, variantCount)
                                : product.productName,
                            StockDisplay = variantCount > 1
                                ? string.Format("{0} total", totalStock)
                                : totalStock.ToString()
                        };
                    })
                    .OrderBy(x => x.CreatedAt)
                    .ToList();

                if (productData.Count == 0)
                {
                    if (pnlLoading != null) pnlLoading.Visible = false;
                    if (pnlNoData != null) pnlNoData.Visible = true;
                    if (rptProductVariants != null) rptProductVariants.Visible = false;
                    return;
                }

                // Update UI
                if (pnlLoading != null) pnlLoading.Visible = false;
                if (pnlNoData != null) pnlNoData.Visible = false;
                if (rptProductVariants != null) rptProductVariants.Visible = true;

                // ✅ DataBind is CORRECT - keep it
                if (rptProductVariants != null)
                {
                    rptProductVariants.DataSource = productData;
                    rptProductVariants.DataBind();
                }
            }
            catch (Exception ex)
            {
                if (pnlLoading != null) pnlLoading.Visible = false;
                if (pnlNoData != null) pnlNoData.Visible = true;
                if (rptProductVariants != null) rptProductVariants.Visible = false;

                ShowMessage(string.Format("❌ Error loading data: {0}", ex.Message), "error");
                System.Diagnostics.Debug.WriteLine($"❌ LoadProductsAsync error: {ex.Message}\n{ex.StackTrace}");
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

        protected string GetProductImage(string productId)
        {
            if (string.IsNullOrWhiteSpace(productId))
            {
                return DefaultImageDataUri;
            }

            // ✅ Return handler URL that will fetch the blob from MongoDB
            return ResolveUrl($"~/Handlers/GetProductImage.ashx?productId={productId}");
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
                string productName = txtProductName.Text.Trim();
                string category = ddlCategory.SelectedValue;
                string description = txtDescription.Text.Trim();

                if (string.IsNullOrEmpty(productName) || string.IsNullOrEmpty(category))
                {
                    lblMessage.Text = "Product name and category are required.";
                    pnlMessage.Visible = true;
                    return;
                }

                // ✅ Get ingredients from hidden field
                var ingredientsJson = hdnSelectedIngredients.Value;
                List<ProductIngredient> ingredients = new List<ProductIngredient>();

                System.Diagnostics.Debug.WriteLine($"📦 Raw ingredients JSON: {ingredientsJson}");

                if (!string.IsNullOrEmpty(ingredientsJson))
                {
                    try
                    {
                        var ingredientsList = JsonConvert.DeserializeObject<List<dynamic>>(ingredientsJson);
                        foreach (var ing in ingredientsList)
                        {
                            ingredients.Add(new ProductIngredient
                            {
                                IngredientId = ing.id.ToString(),
                                QuantityRequired = Convert.ToDecimal(ing.quantity),
                                Unit = ing.unit.ToString()
                            });
                        }

                        System.Diagnostics.Debug.WriteLine($"✅ Parsed {ingredients.Count} ingredients");
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"❌ Error parsing ingredients: {ex.Message}");
                        lblMessage.Text = $"Error parsing ingredients: {ex.Message}";
                        pnlMessage.Visible = true;
                        return; // Stop if ingredient parsing fails
                    }
                }

                // Create Product object
                var product = new Product
                {
                    productName = productName,
                    productCategory = category,
                    productDesc = description,
                    productVal = 0,
                    baseIngredients = string.Empty,
                    createdAt = DateTime.UtcNow,
                    updatedAt = DateTime.UtcNow
                };

                // ✅ Handle Product Image Upload as BLOB
                if (fuProductImage.HasFile)
                {
                    try
                    {
                        string fileExtension = Path.GetExtension(fuProductImage.FileName).ToLower();
                        string[] allowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

                        if (!allowedExtensions.Contains(fileExtension))
                        {
                            lblMessage.Text = "Invalid image format. Allowed: JPG, PNG, GIF, WEBP";
                            pnlMessage.Visible = true;
                            return;
                        }

                        if (fuProductImage.PostedFile.ContentLength > 5 * 1024 * 1024)
                        {
                            lblMessage.Text = "Image file must be less than 5MB";
                            pnlMessage.Visible = true;
                            return;
                        }

                        using (var binaryReader = new BinaryReader(fuProductImage.PostedFile.InputStream))
                        {
                            product.productImg = binaryReader.ReadBytes(fuProductImage.PostedFile.ContentLength);
                            product.ProductImgContentType = fuProductImage.PostedFile.ContentType;
                        }

                        System.Diagnostics.Debug.WriteLine($"✅ Product image converted to blob ({product.productImg.Length} bytes)");
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"❌ Error uploading product image: {ex.Message}");
                        lblMessage.Text = "Error uploading product image: " + ex.Message;
                        pnlMessage.Visible = true;
                        return;
                    }
                }
                else
                {
                    product.productImg = null;
                    product.ProductImgContentType = null;
                }

                // ✅ Save product to database
                var productService = new ProductService();
                string productId = await productService.CreateProductAsync(product);

                System.Diagnostics.Debug.WriteLine($"✅ Product created with ID: {productId}");

                // ✅ CRITICAL FIX: Save ingredient relationships to ProductIngredients collection
                if (ingredients.Count > 0)
                {
                    System.Diagnostics.Debug.WriteLine($"📝 Saving {ingredients.Count} ingredient relationships...");

                    foreach (var ingredient in ingredients)
                    {
                        ingredient.ProductId = productId; // Link to the newly created product
                        ingredient.CreatedAt = DateTime.UtcNow;

                        try
                        {
                            string relationshipId = await productService.CreateProductIngredientAsync(ingredient);
                            System.Diagnostics.Debug.WriteLine($"✅ Saved ingredient relationship: {relationshipId} (IngredientId: {ingredient.IngredientId}, Qty: {ingredient.QuantityRequired} {ingredient.Unit})");
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine($"❌ Failed to save ingredient {ingredient.IngredientId}: {ex.Message}");
                        }
                    }

                    System.Diagnostics.Debug.WriteLine($"✅ Successfully saved {ingredients.Count} ingredient relationships");
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("⚠️ No ingredients to save");
                }

                lblMessage.Text = $"✅ Product created successfully with {ingredients.Count} ingredient(s)!";
                pnlMessage.CssClass = "success-container";
                pnlMessage.Visible = true;

                // Clear form
                ClearForm();

                // Refresh page after 2 seconds
                Response.AddHeader("Refresh", "2;URL=" + Request.RawUrl);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error saving product: {ex.Message}\n{ex.StackTrace}");
                lblMessage.Text = "Error: " + ex.Message;
                pnlMessage.CssClass = "error-container";
                pnlMessage.Visible = true;
            }
        }
        // ✅ ADD THIS METHOD
        private void ClearForm()
        {
            try
            {
                // Clear product fields
                txtProductName.Text = string.Empty;
                ddlCategory.SelectedIndex = 0;
                txtDescription.Text = string.Empty;
                hdnSelectedIngredients.Value = string.Empty;

                // Clear file upload
                // Note: You cannot programmatically clear file upload control for security reasons
                // But you can reset the form

                Console.WriteLine("✅ Form cleared successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error clearing form: {ex.Message}");
            }
        }


        protected async void btnSaveVariant_Click(object sender, EventArgs e)
        {
            try
            {
                string variantName = txtVariantName.Text.Trim();
                string sku = txtVariantSKU.Text.Trim();
                decimal price = 0;
                int stock = 0;

                if (string.IsNullOrEmpty(variantName) || string.IsNullOrEmpty(sku))
                {
                    lblMessage.Text = "Variant name and SKU are required.";
                    pnlMessage.Visible = true;
                    return;
                }

                if (!decimal.TryParse(txtVariantPrice.Text, out price) || price <= 0)
                {
                    lblMessage.Text = "Please enter a valid price.";
                    pnlMessage.Visible = true;
                    return;
                }

                if (!int.TryParse(txtVariantStock.Text, out stock) || stock < 0)
                {
                    lblMessage.Text = "Please enter a valid stock quantity.";
                    pnlMessage.Visible = true;
                    return;
                }

                string productId = Session["CurrentProductId"]?.ToString();

                if (string.IsNullOrEmpty(productId))
                {
                    lblMessage.Text = "Product ID not found. Please try again.";
                    pnlMessage.Visible = true;
                    return;
                }

                decimal variantWeight = 0;
                if (!string.IsNullOrEmpty(txtVariantWeight.Text))
                {
                    decimal.TryParse(txtVariantWeight.Text, out variantWeight);
                }

                int shelfLifeYears = 0;
                if (!string.IsNullOrEmpty(txtShelfLifeYears.Text))
                {
                    int.TryParse(txtShelfLifeYears.Text, out shelfLifeYears);
                }

                var variant = new ProductVariant
                {
                    ProductId = productId,
                    VariantName = variantName,
                    SKU = sku,
                    Size = txtVariantSize.Text.Trim(),
                    Color = txtVariantColor.Text.Trim(),
                    Price = price,
                    StockQuantity = stock,
                    MinimumStock = 1000,
                    Weight = string.IsNullOrEmpty(txtVariantWeight.Text) ? (decimal?)null : variantWeight,
                    Dimensions = txtVariantDimensions.Text.Trim(),
                    ShelfLifeYears = string.IsNullOrEmpty(txtShelfLifeYears.Text) ? (int?)null : shelfLifeYears,
                    Location = ddlVariantLocation.SelectedValue,
                    VariantImg = "/Content/images/sample-variant.png",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // ✅ FIXED: Initialize as List<byte[]> instead of List<VariantImage>
                variant.VariantImgUrls = new List<byte[]>();

                if (fuVariantImages.HasFile)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("📷 Processing variant images upload..."));
                    System.Diagnostics.Debug.WriteLine(string.Format("📦 Control ID: {0}, UniqueID: {1}", fuVariantImages.ID, fuVariantImages.UniqueID));

                    try
                    {
                        HttpFileCollection allFiles = Request.Files;
                        string controlUniqueId = fuVariantImages.UniqueID;

                        if (allFiles != null && allFiles.Count > 0)
                        {
                            System.Diagnostics.Debug.WriteLine(string.Format("📦 Total files in Request.Files: {0}", allFiles.Count));

                            // ✅ CRITICAL FIX: Track processed filenames to avoid duplicates
                            HashSet<string> processedFileNames = new HashSet<string>();
                            int fileIndex = 0;

                            // ✅ Iterate through ALL files in Request.Files
                            for (int i = 0; i < allFiles.Count; i++)
                            {
                                string fileKey = allFiles.GetKey(i);
                                HttpPostedFile uploadedFile = allFiles[i];

                                // ✅ Only process files from fuVariantImages control
                                if (fileKey != controlUniqueId)
                                {
                                    System.Diagnostics.Debug.WriteLine(string.Format("⚠️ Skipping file from different control: {0}", fileKey));
                                    continue;
                                }

                                // ✅ Skip empty files
                                if (uploadedFile == null || uploadedFile.ContentLength == 0)
                                {
                                    System.Diagnostics.Debug.WriteLine(string.Format("⚠️ Skipping empty file at index {0}", i));
                                    continue;
                                }

                                // ✅ Skip files with no name
                                if (string.IsNullOrWhiteSpace(uploadedFile.FileName))
                                {
                                    System.Diagnostics.Debug.WriteLine(string.Format("⚠️ Skipping file with no filename at index {0}", i));
                                    continue;
                                }

                                // ✅ Create unique key for this file (filename + size + position)
                                string fileKey2 = string.Format("{0}_{1}_{2}", uploadedFile.FileName, uploadedFile.ContentLength, fileIndex);

                                // ✅ Skip if we've already processed this exact file
                                if (processedFileNames.Contains(fileKey2))
                                {
                                    System.Diagnostics.Debug.WriteLine(string.Format("⚠️ Duplicate file detected: {0} - SKIPPING", uploadedFile.FileName));
                                    continue;
                                }

                                processedFileNames.Add(fileKey2);
                                fileIndex++;

                                System.Diagnostics.Debug.WriteLine(string.Format("📄 Processing file {0}: FileName='{1}', Size={2}, Key={3}", fileIndex, uploadedFile.FileName, uploadedFile.ContentLength, fileKey));

                                string fileExtension = Path.GetExtension(uploadedFile.FileName).ToLower();
                                string[] allowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

                                if (!allowedExtensions.Contains(fileExtension))
                                {
                                    System.Diagnostics.Debug.WriteLine(string.Format("⚠️ Invalid file extension: {0} for file: {1}", fileExtension, uploadedFile.FileName));
                                    continue;
                                }

                                if (uploadedFile.ContentLength > 5 * 1024 * 1024)
                                {
                                    System.Diagnostics.Debug.WriteLine(string.Format("⚠️ File too large: {0} bytes for file: {1}", uploadedFile.ContentLength, uploadedFile.FileName));
                                    continue;
                                }

                                // ✅ Read file data
                                byte[] fileData;
                                using (var binaryReader = new BinaryReader(uploadedFile.InputStream))
                                {
                                    fileData = binaryReader.ReadBytes(uploadedFile.ContentLength);
                                }

                                // ✅ FIXED: Add raw byte array directly
                                variant.VariantImgUrls.Add(fileData);

                                System.Diagnostics.Debug.WriteLine(string.Format("✅ Added image {0}: {1} ({2} bytes)", variant.VariantImgUrls.Count, uploadedFile.FileName, fileData.Length));
                            }

                            System.Diagnostics.Debug.WriteLine(string.Format("✅ Total UNIQUE images processed: {0}", variant.VariantImgUrls.Count));
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine("⚠️ No files found in Request.Files");
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine(string.Format("❌ Error uploading variant images: {0}", ex.Message));
                        System.Diagnostics.Debug.WriteLine(string.Format("Stack trace: {0}", ex.StackTrace));

                        lblMessage.Text = "⚠️ Warning: Some images failed to upload. Variant created without images.";
                        pnlMessage.CssClass = "success-container";
                        pnlMessage.Visible = true;
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("ℹ️ No images selected for upload (fuVariantImages.HasFile = false)");
                }

                var productService = new ProductService();
                string variantId = await productService.CreateProductVariantAsync(variant);

                System.Diagnostics.Debug.WriteLine(string.Format("✅ Variant created: {0} with {1} image(s)", variantId, variant.VariantImgUrls.Count));

                lblMessage.Text = string.Format("✅ Variant created successfully with {0} image(s)!", variant.VariantImgUrls.Count);
                pnlMessage.CssClass = "success-container";
                pnlMessage.Visible = true;

                ClearVariantForm();
                Response.AddHeader("Refresh", "2;URL=" + Request.RawUrl);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ Error saving variant: {0}\n{1}", ex.Message, ex.StackTrace));
                lblMessage.Text = "Error: " + ex.Message;
                pnlMessage.CssClass = "error-container";
                pnlMessage.Visible = true;
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
                var product = products.FirstOrDefault(p => p.Id == productId && (p.status == null || p.status == "Active"));
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
                    productName = product.productName,
                    ProductDesc = product.productDesc,
                    ProductCategory = product.productCategory,
                    ProductImg = product.productImg,
             
                    baseIngredients = product.baseIngredients,
                    ProductVal = product.productVal,
                    Status = product.status,
                    CreatedAt = product.createdAt
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



        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetProductIngredients(string productId)
        {
            try
            {
                var productService = new ProductService();
                var ingredients = productService.GetAllIngredientsAsync().GetAwaiter().GetResult();
                var productIngredients = productService.GetProductIngredientsByProductIdAsync(productId).GetAwaiter().GetResult();

                var ingredientList = productIngredients
                    .Where(pi => pi.IsActive)
                    .Select(pi => {
                        var ingredient = ingredients.FirstOrDefault(i => i.Id == pi.IngredientId);
                        return new
                        {
                            id = pi.IngredientId,
                            name = ingredient?.IngredientName ?? "",
                            unit = pi.Unit ?? ingredient?.Unit ?? "",
                            quantity = pi.QuantityRequired
                        };
                    }).ToList();

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { success = true, ingredients = ingredientList });
            }
            catch (Exception ex)
            {
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { success = false, error = ex.Message });
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
     

            // ✅ Clear shelf life field
            if (txtShelfLifeYears != null) txtShelfLifeYears.Text = string.Empty;

            // ✅ Clear location dropdown
            if (ddlVariantLocation != null) ddlVariantLocation.SelectedIndex = 0;
        }


    }


}