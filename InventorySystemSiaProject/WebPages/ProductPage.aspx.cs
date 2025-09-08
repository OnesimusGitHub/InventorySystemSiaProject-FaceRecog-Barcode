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
                // Return a better placeholder SVG for preview
                return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y4ZjlmYSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEyIiBmaWxsPSIjNjY3ZWVhIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+UHJvZHVjdDwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNjAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+U2VydW08L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjcwIiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SW1hZ2U8L3RleHQ+CiAgPC9zdmc+";
            }

            // Define all the problematic image paths that cause 404 errors
            var problematicImages = new Dictionary<string, string>
            {
                // Skincare products - Green theme
                { "hydrating-serum.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U4ZjVlOSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjMjU3ZTMyIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+SHlkcmF0aW5nPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI1NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjMjU3ZTMyIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+U2VydW08L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjcwIiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SW1hZ2U8L3RleHQ+CiAgPC9zdmc+" },
                { "vitamin-c-cream.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZjNjZCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjODU2NDA0IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+Vml0YW1pbiBDPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI1NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjODU2NDA0IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+Q3JlYW08L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjcwIiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SW1hZ2U8L3RleHQ+CiAgPC9zdmc+" },
                { "anti-aging-serum.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U4ZjVlOSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjMjU3ZTMyIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+QW50aS1BZ2luZzwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNTUiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMCIgZmlsbD0iIzI1N2UzMiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC13ZWlnaHQ9ImJvbGQiPlNlcnVtPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI3MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjgiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==" },
                { "acne-treatment.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZkZWNlYSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjYzYyODI4IiB0ZXh0LWFuY2hvcj0 ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+QWNuZTwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNTUiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMCIgZmlsbD0iI2M2MjgyOCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC13ZWlnaHQ9ImJvbGQiPlRyZWF0bWVudDwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNzAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },
                { "exfoliating-toner.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZjNjZCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjODU2NDA0IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RXhmb2xpYXRpbmc8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjU1IiBmb250LWZhbWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },
                { "face-mask-set.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y1ZTZmZiIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RmFjZSBNYXNrPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI1NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+U2V0PC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI3MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjgiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==" },

                // Makeup products - Purple/Pink theme
                { "eyeshadow-palette.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y1ZTZmZiIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RXlleGFtPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI1NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+UGFsZXR0ZTwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNzAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },
                { "matte-lipstick.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZTRlMSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjZGMzNTQ1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+TWF0dGU8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjU1IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiNkYzM1NDUiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtd2VpZ2h0PSJib2xkIj5MaXBzdGljakwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNzAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },

                // Handle variations with numbers (like 557993/Content/...)
                { "557993/Content/image_atte_lipstick.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZTRlMSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjZGMzNTQ1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+TGlwc3RpY2s8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjU1IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiNkYzM1NDUiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==" }
            };

            // Check if this is one of the problematic images
            foreach (var problematicImage in problematicImages)
            {
                if (!string.IsNullOrEmpty(imageUrl) &&
                    (imageUrl.Contains(problematicImage.Key) ||
                     imageUrl.EndsWith(problematicImage.Key) ||
                     imageUrl.EndsWith("/" + problematicImage.Key)))
                {
                    return problematicImage.Value;
                }
            }

            // General pattern matching for any missing cosmetic images
            var imageFileName = System.IO.Path.GetFileName(imageUrl);
            if (!string.IsNullOrEmpty(imageFileName))
            {
                // Skincare patterns
                if (imageFileName.Contains("serum") || imageFileName.Contains("cream") || imageFileName.Contains("moisturizer"))
                    return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U4ZjVlOSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjMjU3ZTMyIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+U2tpbmNhcmU8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjYwIiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SW1hZ2U8L3RleHQ+CiAgPC9zdmc+";

                // Makeup patterns
                if (imageFileName.Contains("lipstick") || imageFileName.Contains("eyeshadow") || imageFileName.Contains("palette") || imageFileName.Contains("makeup"))
                    return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y1ZTZmZiIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+TWFrZXVwPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI2MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjgiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==";

                // Fragrance patterns
                if (imageFileName.Contains("perfume") || imageFileName.Contains("fragrance") || imageFileName.Contains("cologne"))
                    return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZjNjZCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjODU2NDA0IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RnJhZ3JhbmNlPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI2MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjgiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==";

                // Haircare patterns
                if (imageFileName.Contains("shampoo") || imageFileName.Contains("conditioner") || imageFileName.Contains("hair"))
                    return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2U3ZjNmZiIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNGY0NmU1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+SGFpcmNhcmU8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjYwIiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SW1hZ2U8L3RleHQ+CiAgPC9zdmc+";
            }

            // If it's a relative path, make sure it starts with /
            if (!imageUrl.StartsWith("http") && !imageUrl.StartsWith("data:") && !imageUrl.StartsWith("/"))
            {
                imageUrl = "/" + imageUrl;
            }

            return imageUrl;
        }

        // NEW: Simple test method that just returns a basic response
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string TestBasicConnection()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🧪 TestBasicConnection called");

                // Just return a simple response without touching the database
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
                System.Diagnostics.Debug.WriteLine($"💥 TestBasicConnection error: {ex.Message}");
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        // NEW: Test database connection only
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string TestDatabaseConnectionOnly()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🧪 TestDatabaseConnectionOnly called");

                // Test database connection with short timeout
                var isConnected = DatabaseHelper.TestConnectionAsync().Result;

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new
                {
                    success = true,
                    databaseConnected = isConnected,
                    message = isConnected ? "Database connected successfully" : "Database connection failed",
                    timestamp = DateTime.Now.ToString()
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"💥 TestDatabaseConnectionOnly error: {ex.Message}");
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new
                {
                    success = false,
                    error = ex.Message,
                    timestamp = DateTime.Now.ToString()
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
                System.Diagnostics.Debug.WriteLine($"🔍 GetProductVariants called with productId='{productId}'");

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

                System.Diagnostics.Debug.WriteLine($"📊 Found {variants?.Count ?? 0} variants");

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

                System.Diagnostics.Debug.WriteLine($"✅ GetProductVariants returning {variantData.Count} items");
                System.Diagnostics.Debug.WriteLine($"📊 JSON: {(json.Length > 200 ? json.Substring(0, 200) + "..." : json)}");

                return json;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"💥 GetProductVariants error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"💥 Stack trace: {ex.StackTrace}");

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { error = ex.Message, details = ex.StackTrace });
            }
        }

        // NEW: Add a test method to check if we have any variants at all
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string TestGetAllVariants()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🧪 TestGetAllVariants called");
                var productService = new ProductService();

                var allVariants = productService.GetAllProductVariantsAsync()
                                               .GetAwaiter()
                                               .GetResult();

                System.Diagnostics.Debug.WriteLine($"🧪 Found {allVariants?.Count ?? 0} total variants in database");

                if (allVariants != null && allVariants.Count > 0)
                {
                    var sample = allVariants.Take(3).Select(v => new
                    {
                        Id = v.Id,
                        ProductId = v.ProductId,
                        VariantName = v.VariantName,
                        SKU = v.SKU
                    }).ToList();

                    var serializer = new JavaScriptSerializer();
                    return serializer.Serialize(new
                    {
                        totalCount = allVariants.Count,
                        sampleVariants = sample
                    });
                }
                else
                {
                    var serializer = new JavaScriptSerializer();
                    return serializer.Serialize(new
                    {
                        totalCount = 0,
                        message = "No variants found in database"
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"💥 TestGetAllVariants error: {ex.Message}");
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { error = ex.Message });
            }
        }

        // SIMPLE: Just get ALL variants from database and show them
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetAllVariantsSimple()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🔍 GetAllVariantsSimple called");

                // Get the variants collection directly
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();

                // Get ALL variants from database
                var allVariants = variantsCollection.Find(_ => true).ToList();

                System.Diagnostics.Debug.WriteLine($"Found {allVariants.Count} total variants");

                // Convert to simple objects
                var result = allVariants.Select(v => new
                {
                    Id = v.Id ?? "",
                    ProductId = v.ProductId ?? "",
                    VariantName = v.VariantName ?? "",
                    SKU = v.SKU ?? "",
                    Size = v.Size ?? "",
                    Color = v.Color ?? "",
                    Price = v.Price,
                    StockQuantity = v.StockQuantity,
                    MinimumStock = v.MinimumStock,
                    IsLowStock = v.IsLowStock
                }).ToList();

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(result);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error: {ex.Message}");
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { error = ex.Message });
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
                product.ProductVal = 0;
                if (!string.IsNullOrEmpty(txtProductValue?.Text) && decimal.TryParse(txtProductValue.Text, out decimal value))
                {
                    product.ProductVal = value;
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

        // Add test variant creation method referenced in JavaScript
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string CreateTestVariantsForProduct(string productId)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine($"🧪 CreateTestVariantsForProduct called with productId: {productId}");

                if (string.IsNullOrEmpty(productId))
                {
                    var serializer1 = new JavaScriptSerializer();
                    return serializer1.Serialize(new { error = "Product ID is required" });
                }

                var productService = new ProductService();

                // Get the product first to verify it exists
                var allProducts = productService.GetAllProductsAsync().GetAwaiter().GetResult();
                var product = allProducts.FirstOrDefault(p => p.Id == productId);

                if (product == null)
                {
                    var serializer2 = new JavaScriptSerializer();
                    return serializer2.Serialize(new { error = "Product not found" });
                }

                // Create test variants
                var testVariants = new List<ProductVariant>
                {
                    new ProductVariant
                    {
                        ProductId = productId,
                        VariantName = "Rose Gold Edition",
                        SKU = $"RG-{DateTime.Now:MMddHHmm}",
                        Size = "50ml",
                        Color = "Rose Gold",
                        Price = 29.99m,
                        StockQuantity = 15,
                        MinimumStock = 5,
                        Weight = 75.0m,
                        Dimensions = "5cm x 5cm x 8cm"
                    },
                    new ProductVariant
                    {
                        ProductId = productId,
                        VariantName = "Natural Glow",
                        SKU = $"NG-{DateTime.Now:MMddHHmm}",
                        Size = "30ml",
                        Color = "Natural",
                        Price = 24.99m,
                        StockQuantity = 8,
                        MinimumStock = 3,
                        Weight = 45.0m,
                        Dimensions = "4cm x 4cm x 6cm"
                    },
                    new ProductVariant
                    {
                        ProductId = productId,
                        VariantName = "Deep Essence",
                        SKU = $"DE-{DateTime.Now:MMddHHmm}",
                        Size = "100ml",
                        Color = "Deep",
                        Price = 39.99m,
                        StockQuantity =  0, // Out of stock for testing
                        MinimumStock = 2,
                        Weight = 120.0m,
                        Dimensions = "6cm x 6cm x 10cm"
                    }
                };

                var createdVariants = new List<object>();
                int successCount = 0;

                foreach (var variant in testVariants)
                {
                    try
                    {
                        var variantId = productService.CreateProductVariantAsync(variant).GetAwaiter().GetResult();
                        if (!string.IsNullOrEmpty(variantId))
                        {
                            successCount++;
                            createdVariants.Add(new
                            {
                                Id = variantId,
                                VariantName = variant.VariantName,
                                SKU = variant.SKU,
                                Size = variant.Size,
                                Color = variant.Color,
                                Price = variant.Price,
                                StockQuantity = variant.StockQuantity
                            });
                        }
                    }
                    catch (Exception variantEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"Failed to create variant {variant.VariantName}: {variantEx.Message}");
                    }
                }

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new
                {
                    success = true,
                    productName = product.ProductName,
                    variantsCreated = successCount,
                    variants = createdVariants,
                    message = $"Created {successCount} test variants for {product.ProductName}"
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"CreateTestVariantsForProduct error: {ex.Message}");
                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { error = ex.Message });
            }
        }

        // NEW: Enhanced WebMethod using MongoDB Aggregation with $lookup
        [System.Web.Services.WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static string GetProductWithVariantsAggregation(string productId)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine($"🔍 GetProductWithVariantsAggregation called with productId='{productId}'");

                if (string.IsNullOrEmpty(productId))
                {
                    var serializer1 = new JavaScriptSerializer();
                    return serializer1.Serialize(new { error = "Product ID is required" });
                }

                // Get MongoDB collections
                var productsCollection = DatabaseHelper.GetProductsCollection();
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();

                if (productsCollection == null || variantsCollection == null)
                {
                    var serializer2 = new JavaScriptSerializer();
                    return serializer2.Serialize(new { error = "Database collections not available" });
                }

                // Create MongoDB aggregation pipeline equivalent to:
                // db.Products.aggregate([
                //   {
                //     $lookup: {
                //       from: "ProductVariants",
                //       localField: "_id", 
                //       foreignField: "ProductId",
                //       as: "variants"
                //     }
                //   },
                //   {
                //     $match: { _id: ObjectId("productId") }
                //   }
                // ])

                var pipeline = new BsonDocument[]
                {
                    new BsonDocument("$lookup", new BsonDocument
                    {
                        { "from", "ProductVariants" },
                        { "localField", "_id" },
                        { "foreignField", "ProductId" },
                        { "as", "variants" }
                    }),
                    new BsonDocument("$match", new BsonDocument
                    {
                        { "_id", new ObjectId(productId) }
                    })
                };

                System.Diagnostics.Debug.WriteLine("📊 Executing MongoDB aggregation pipeline...");
                
                // Execute aggregation
                var aggregationResult = productsCollection.Aggregate<BsonDocument>(pipeline).ToList();
                
                System.Diagnostics.Debug.WriteLine($"📊 Aggregation returned {aggregationResult.Count} results");

                if (aggregationResult.Count == 0)
                {
                    var serializer3 = new JavaScriptSerializer();
                    return serializer3.Serialize(new { 
                        error = "Product not found",
                        productId = productId 
                    });
                }

                var productWithVariants = aggregationResult.First();
                var variantsArray = productWithVariants["variants"].AsBsonArray;
                
                System.Diagnostics.Debug.WriteLine($"📊 Found {variantsArray.Count} variants for product");

                // Convert variants to simplified objects for JSON serialization
                var variantsList = new List<object>();
                
                foreach (var variantDoc in variantsArray)
                {
                    var variant = variantDoc.AsBsonDocument;
                    
                    variantsList.Add(new
                    {
                        Id = variant.GetValue("_id", "").ToString(),
                        VariantName = variant.GetValue("VariantName", "").AsString,
                        SKU = variant.GetValue("SKU", "").AsString,
                        Size = variant.GetValue("Size", "").AsString,
                        Color = variant.GetValue("Color", "").AsString,
                        Price = variant.GetValue("Price", 0.0).ToDecimal(),
                        StockQuantity = variant.GetValue("StockQuantity", 0).ToInt32(),
                        MinimumStock = variant.GetValue("MinimumStock", 0).ToInt32(),
                        Weight = variant.GetValue("Weight", 0.0).ToDecimal(),
                        Dimensions = variant.GetValue("Dimensions", "").AsString,
                        IsActive = variant.GetValue("IsActive", true).ToBoolean(),
                        CreatedAt = variant.GetValue("CreatedAt", DateTime.Now).ToUniversalTime(),
                        UpdatedAt = variant.GetValue("UpdatedAt", DateTime.Now).ToUniversalTime()
                    });
                }

                // Also get product information
                var productInfo = new
                {
                    Id = productWithVariants.GetValue("_id", "").ToString(),
                    ProductName = productWithVariants.GetValue("ProductName", "").AsString,
                    ProductDesc = productWithVariants.GetValue("ProductDesc", "").AsString,
                    ProductCategory = productWithVariants.GetValue("ProductCategory", "").AsString,
                    ProductImg = productWithVariants.GetValue("ProductImg", "").AsString,
                    Supplier = productWithVariants.GetValue("Supplier", "").AsString,
                    BaseIngredients = productWithVariants.GetValue("BaseIngredients", "").AsString,
                    ProductVal = productWithVariants.GetValue("ProductVal", 0.0).ToDecimal(),
                    IsActive = productWithVariants.GetValue("IsActive", true).ToBoolean(),
                    CreatedAt = productWithVariants.GetValue("CreatedAt", DateTime.Now).ToUniversalTime()
                };

                var result = new
                {
                    success = true,
                    product = productInfo,
                    variants = variantsList,
                    variantCount = variantsList.Count,
                    message = $"Found {variantsList.Count} variants for {productInfo.ProductName}",
                    aggregationUsed = true
                };

                var serializer = new JavaScriptSerializer();
                var json = serializer.Serialize(result);

                System.Diagnostics.Debug.WriteLine($"✅ GetProductWithVariantsAggregation returning data for {variantsList.Count} variants");
                return json;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"💥 GetProductWithVariantsAggregation error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"💥 Stack trace: {ex.StackTrace}");

                var serializer = new JavaScriptSerializer();
                return serializer.Serialize(new { 
                    error = ex.Message, 
                    details = ex.StackTrace,
                    aggregationUsed = false
                });
            }
        }

        // ULTRA-RESILIENT: accepts both JSON and form payloads and validates productId before DB calls
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
                    Supplier = product.Supplier,
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
    }
}