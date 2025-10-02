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
                { "acne-treatment.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZkZWNlYSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjYzYyODI4IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+QWNuZTwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNTUiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxMCIgZmlsbD0iI2M2MjgyOCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC13ZWlnaHQ9ImJvbGQiPlRyZWF0bWVudDwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNzAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },
                { "exfoliating-toner.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZjNjZCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjODU2NDA0IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RXhmb2xpYXRpbmc8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjU1IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iOCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SW1hZ2U8L3RleHQ+CiAgPC9zdmc+" },
                { "face-mask-set.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y1ZTZmZiIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RmFjZSBNYXNrPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI1NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+U2V0PC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI3MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjgiIGZpbGw9IiM5OTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==" },

                // Makeup products - Purple/Pink theme
                { "eyeshadow-palette.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y1ZTZmZiIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+RXlleGFtPC90ZXh0PgogIDx0ZXh0IHg9IjUwIiB5PSI1NSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNzYzZGJkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+UGFsZXR0ZTwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNzAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },
                { "matte-lipstick.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZTRlMSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjZGMzNTQ1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+TWF0dGU8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjU1IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiNkYzM1NDUiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtd2VpZ2h0PSJib2xkIj5MaXBzdGljakwvdGV4dD4KICA8dGV4dCB4PSI1MCIgeT0iNzAiIGZvcnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSI4IiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj5JbWFnZTwvdGV4dD4KICA8L3N2Zz4=" },

                // Handle variations with numbers (like 557993/Content/...)
                { "557993/Content/image_atte_lipstick.jpg", "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2ZmZTRlMSIvPgogIDx0ZXh0IHg9IjUwIiB5PSI0MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEwIiBmaWxsPSIjZGMzNTQ1IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXdlaWdodD0iYm9sZCI+TGlpc3RpY2s8L3RleHQ+CiAgPHRleHQgeD0iNTAiIHk9IjU1IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiNkYzM1NDUiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkltYWdlPC90ZXh0PgogIDwvc3ZnPg==" }
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
                // Use default placeholder image since txtImageUrl is removed
                product.ProductImg = "/Content/images/sample-generic.png";
                product.Supplier = txtSupplier?.Text?.Trim() ?? "";

                // Cloudinary upload for product image if file provided
                if (fuProductImage != null && fuProductImage.HasFile)
                {
                    try
                    {
                        var uploadedUrl = CloudinaryHelper.UploadImage(fuProductImage.PostedFile, "products");
                        if (!string.IsNullOrWhiteSpace(uploadedUrl))
                        {
                            product.ProductImg = uploadedUrl;
                        }
                    }
                    catch { }
                }

                var productService = new ProductService();
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

                string script = "setTimeout(function(){ window.location.reload(); }, 1200);";
                ClientScript.RegisterStartupScript(this.GetType(), "ProductSaved", script, true);
            }
            catch (Exception ex)
            {
                ShowMessage(string.Format("❌ Error saving product: {0}", ex.Message), "error");
            }
        }

        private void ClearProductForm()
        {
            txtProductName.Text = string.Empty;
            txtDescription.Text = string.Empty;
            ddlCategory.SelectedIndex = 0;
            txtBaseIngredients.Text = string.Empty;
            txtSupplier.Text = string.Empty;
        }

        protected async void btnSaveVariant_Click(object sender, EventArgs e)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🚨🚨🚨 SAVE VARIANT BUTTON CLICKED! 🚨🚨🚨");
                System.Diagnostics.Debug.WriteLine("🚨 btnSaveVariant_Click method is executing!");
                System.Diagnostics.Debug.WriteLine(string.Format("🚨 Current Time: {0}", DateTime.Now));

                // Enhanced session debugging
                System.Diagnostics.Debug.WriteLine("🔍 SESSION DEBUG:");
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Session ID: {0}", Session.SessionID));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Session Count: {0}", Session.Count));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Session Keys: {0}", string.Join(", ", Session.Keys.Cast<string>())));

                // Check multiple possible sources for Product ID
                string productId = Session["NewProductId"]?.ToString();
                System.Diagnostics.Debug.WriteLine(string.Format("🔍 Session NewProductId: '{0}'", productId));

                if (string.IsNullOrEmpty(productId))
                {
                    // Try alternative session keys
                    productId = Session["ProductId"]?.ToString();
                    System.Diagnostics.Debug.WriteLine(string.Format("🔍 Session ProductId: '{0}'", productId));
                }

                if (string.IsNullOrEmpty(productId))
                {
                    // Try ViewState
                    productId = ViewState["NewProductId"]?.ToString();
                    System.Diagnostics.Debug.WriteLine(string.Format("🔍 ViewState NewProductId: '{0}'", productId));
                }

                if (string.IsNullOrEmpty(productId))
                {
                    // Try to get from hidden field or query string
                    productId = Request.QueryString["ProductId"];
                    System.Diagnostics.Debug.WriteLine(string.Format("🔍 QueryString ProductId: '{0}'", productId));
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
                            System.Diagnostics.Debug.WriteLine(string.Format("🎯 Using most recent product ID: '{0}'", productId));

                            // Store it in session for future use
                            Session["NewProductId"] = productId;
                            Session["NewProductName"] = mostRecentProduct.ProductName;

                            ShowMessage(string.Format("🔧 Using most recent product: {0}", mostRecentProduct.ProductName), "info");
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
                        System.Diagnostics.Debug.WriteLine(string.Format("❌ Error finding recent product: {0}", ex.Message));
                        ShowMessage("❌ Error: Product ID not found. Please create a product first, then add variants.", "error");
                        return;
                    }
                }

                System.Diagnostics.Debug.WriteLine(string.Format("🔸 Creating variant for Product ID: {0}", productId));

                // Show immediate user feedback
                ShowMessage("🔄 Server processing variant... Please wait!", "info");

                // Log form values immediately
                System.Diagnostics.Debug.WriteLine("📝 Variant Form Data Received:");
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Variant Name: '{0}'", txtVariantName?.Text ?? "NULL"));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ SKU: '{0}'", txtVariantSKU?.Text ?? "NULL"));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Price: '{0}'", txtVariantPrice?.Text ?? "NULL"));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Stock: '{0}'", txtVariantStock?.Text ?? "NULL"));

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
                    Dimensions = txtVariantDimensions?.Text?.Trim() ?? "",
                    VariantImg = txtVariantImageUrl?.Text?.Trim() ?? string.Empty
                };

                System.Diagnostics.Debug.WriteLine("🔸 Variant object created:");
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Product ID: '{0}'", variant.ProductId));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Name: '{0}'", variant.VariantName));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ SKU: '{0}'", variant.SKU));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Price: {0}", variant.Price));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Stock: {0}", variant.StockQuantity));
                System.Diagnostics.Debug.WriteLine(string.Format("  ➤ Min Stock: {0}", variant.MinimumStock));

                // Cloudinary upload for variant image
                if (fuVariantImage != null && fuVariantImage.HasFile)
                {
                    try
                    {
                        var vUrl = CloudinaryHelper.UploadImage(fuVariantImage.PostedFile, "variants");
                        if (!string.IsNullOrWhiteSpace(vUrl))
                        {
                            variant.VariantImg = vUrl;
                            System.Diagnostics.Debug.WriteLine("🌥️ Cloudinary variant image uploaded: " + vUrl);
                        }
                    }
                    catch (Exception vx)
                    {
                        System.Diagnostics.Debug.WriteLine("❌ Cloudinary variant upload failed: " + vx.Message);
                    }
                }

                // Test database connection with timeout handling
                System.Diagnostics.Debug.WriteLine("🔗 Testing database connection for variant...");
                try
                {
                    // Use shorter timeout for connection test
                    var connectionTask = DatabaseHelper.TestConnectionAsync();
                    bool isConnected = await connectionTask.ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine(string.Format("🔗 Database connection result: {0}", isConnected));

                    if (!isConnected)
                    {
                        System.Diagnostics.Debug.WriteLine("❌ DATABASE CONNECTION FAILED!");
                        ShowMessage("❌ Cannot connect to database. Please check your connection.", "error");
                        return;
                    }
                }
                catch (Exception connEx)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ Database connection exception: {0}", connEx.Message));
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
                    System.Diagnostics.Debug.WriteLine(string.Format("🔸 VARIANT ID RECEIVED: '{0}'", variantId));

                    if (string.IsNullOrEmpty(variantId))
                    {
                        System.Diagnostics.Debug.WriteLine("❌ VARIANT ID IS EMPTY!");
                        ShowMessage("❌ Failed to create variant. Variant ID is empty.", "error");
                        return;
                    }

                    // SUCCESS!
                    System.Diagnostics.Debug.WriteLine("🎉🎉🎉 VARIANT SAVED SUCCESSFULLY! 🎉🎉🎉");
                    System.Diagnostics.Debug.WriteLine(string.Format("🎉 Variant: '{0}'", variant.VariantName));
                    System.Diagnostics.Debug.WriteLine(string.Format("🎉 ID: '{0}'", variantId));
                    System.Diagnostics.Debug.WriteLine(string.Format("🎉 SKU: '{0}'", variant.SKU));

                    ShowMessage(string.Format("✅ Product variant '{0}' saved successfully!", variant.VariantName), "success");

                    // Keep session data for potential additional variants
                    System.Diagnostics.Debug.WriteLine("🔄 Keeping session data for additional variants");

                    // Clear variant form
                    ClearVariantForm();

                    // Use client-side script to show success and refresh
                    string script = string.Format(@"
                        alert('✅ Product variant saved successfully!\nVariant: {0}\nSKU: {1}\nID: {2}\n\nThe page will refresh to show your new variant.');
                        setTimeout(function() {{ window.location.reload(); }}, 2000);", 
                        variant.VariantName, variant.SKU, variantId);

                    ClientScript.RegisterStartupScript(this.GetType(), "VariantSaved", script, true);
                }
                catch (Exception createEx)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ CREATE VARIANT EXCEPTION: {0}", createEx.Message));
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ Exception Details: {0}", createEx));
                    ShowMessage(string.Format("❌ Variant save error: {0}", createEx.Message), "error");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("🎉 === btnSaveVariant_Click COMPLETED SUCCESSFULLY ===");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("💥💥💥 FATAL ERROR in btnSaveVariant_Click 💥💥💥");
                System.Diagnostics.Debug.WriteLine(string.Format("💥 Exception: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("💥 Type: {0}", ex.GetType().Name));
                System.Diagnostics.Debug.WriteLine(string.Format("💥 Stack: {0}", ex.StackTrace));
                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("💥 Inner: {0}", ex.InnerException.Message));
                }
                ShowMessage(string.Format("❌ Error saving variant: {0}", ex.Message), "error");
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