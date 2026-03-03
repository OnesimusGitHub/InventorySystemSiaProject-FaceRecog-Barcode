using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using InventorySystemSiaProject.Models; // added for model access
using System.Text;
using System.Web; // for HttpUtility

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
                Response.Redirect("~/WebPages/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            _productService = new ProductService();

            if (!IsPostBack)
            {
                BindProducts();
            }
        }

        public Dictionary<string, int> CategoryCounts { get; private set; } = new Dictionary<string, int>();

        private void BindProducts()
        {
            try
            {
                // Quick connection probe to avoid navigating to a page that will hang
                bool dbOk = DatabaseHelper.TestConnectionAsync().GetAwaiter().GetResult();
                if (!dbOk)
                {
                    pnlNoProducts.Visible = true;
                    pnlNoProducts.Controls.Add(new LiteralControl("Database not reachable."));
                    return;
                }

                var productsCollection = DatabaseHelper.GetProductsCollection();
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var salesCollection = DatabaseHelper.GetSalesCollection();

                // Only active products
                var productFilter = Builders<Models.Product>.Filter.Or(
                    Builders<Models.Product>.Filter.Eq(p => p.status, null),
                    Builders<Models.Product>.Filter.Eq(p => p.status, "Active")
                );
                var products = productsCollection.Find(productFilter).ToList();

                // --- CATEGORY COUNTS ---
                CategoryCounts = products
                    .GroupBy(p => (p.productCategory ?? "Unknown"))
                    .ToDictionary(g => g.Key, g => g.Count());

                if (products == null || products.Count == 0)
                {
                    pnlNoProducts.Visible = true;
                    return;
                }

                // Active variants for these products
                var productIds = products.Select(p => p.Id).ToList();
                var variantFilter = Builders<ProductVariant>.Filter.In(v => v.ProductId, productIds) & Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true);
                var variants = variantsCollection.Find(variantFilter).ToList();
                var variantIds = variants.Select(v => v.Id).ToList();

                // Sales aggregation
                var productSales = new Dictionary<string, int>();
                if (variantIds.Count > 0)
                {
                    var salesFilter = Builders<Sale>.Filter.In(s => s.VariantId, variantIds);
                    var sales = salesCollection.Find(salesFilter).ToList();
                    var variantSales = sales.GroupBy(s => s.VariantId).ToDictionary(g => g.Key, g => g.Sum(s => s.Quantity));
                    foreach (var variant in variants)
                    {
                        if (variantSales.TryGetValue(variant.Id, out int sold))
                            productSales[variant.ProductId] = (productSales.ContainsKey(variant.ProductId) ? productSales[variant.ProductId] : 0) + sold;
                    }
                }

                // Build product cards with variant price info
                var bestSelling = products.Select(p =>
                {
                    // Get all variants for this product
                    var productVariants = variants.Where(v => v.ProductId == p.Id).ToList();

                    // Calculate price range or single price
                    decimal minPrice = 0;
                    decimal maxPrice = 0;
                    string priceDisplay = "&#8369;0.00";

                    if (productVariants.Any())
                    {
                        minPrice = productVariants.Min(v => v.Price);
                        maxPrice = productVariants.Max(v => v.Price);

                        if (minPrice == maxPrice)
                        {
                            priceDisplay = "&#8369;" + minPrice.ToString("N2");
                        }
                        else
                        {
                            priceDisplay = "&#8369;" + minPrice.ToString("N2") + " - &#8369;" + maxPrice.ToString("N2");
                        }
                    }
                    else if (p.productVal > 0)
                    {
                        // Fallback to product base price if no variants
                        priceDisplay = "&#8369;" + p.productVal.ToString("N2");
                    }

                    // ✅ FIXED: Handle ProductImg as byte[] (blob)
                    string productImageUrl;
                    if (p.productImg != null && p.productImg.Length > 0)
                    {
                        // Product has blob image - use handler to serve it
                        productImageUrl = "/Handlers/GetProductImage.ashx?productId=" + p.Id;
                    }
                    else
                    {
                        // No image - use default
                        productImageUrl = "/Content/images/sample-generic.png";
                    }

                    return new
                    {
                        ProductId = p.Id,
                        p.productName,
                        SupplierName = p.Supplier ?? string.Empty, // ✅ FIXED: Supplier is now a string
                        ProductImg = productImageUrl, // ✅ FIXED: Use blob handler URL
                        PriceDisplay = priceDisplay,
                        SoldCount = productSales.ContainsKey(p.Id) ? productSales[p.Id] : 0,
                        p.createdAt
                    };
                })
                .OrderByDescending(p => p.SoldCount)
                .ThenByDescending(p => p.createdAt)
                .Take(12)
                .ToList();

                var sb = new StringBuilder();
                foreach (var p in bestSelling)
                {
                    var profileUrl = ResolveUrl("~/WebPages/ProductProfile.aspx?productId=" + p.ProductId + "&supplier=" + HttpUtility.UrlEncode(p.SupplierName));
                    var pdfUrl = ResolveUrl("~/Handlers/DownloadProductReportPdf.ashx?productId=" + p.ProductId);
                    // Fetch the product's category for filtering
                    var product = products.FirstOrDefault(x => x.Id == p.ProductId);
                    var category = product != null ? (product.productCategory ?? "") : "";
                    sb.Append(string.Format("<div class='product-card-wrapper'>"));
                    sb.Append(string.Format("<a class='product-card-link' href='{0}' onclick=\"window.location.href='{0}';return true;\" target='_blank' rel='noopener'>", profileUrl));
                    sb.Append(string.Format("<div class='product-card' data-category='{0}' data-name='{1}'>", HttpUtility.HtmlAttributeEncode(category), Server.HtmlEncode(p.productName)));
                    sb.Append("<div class='product-image-wrapper'>");
                    sb.Append(string.Format("<img src='{0}' alt='{1}' class='product-image' />", p.ProductImg, Server.HtmlEncode(p.productName)));
                    sb.Append("</div>");
                    sb.Append("<div class='product-body'>");
                    sb.Append("<div class='product-badges primary'><span class='badge badge-preferred'>Preferred</span></div>");
                    sb.Append(string.Format("<div class='product-name multiline-ellipsis'>{0}</div>", Server.HtmlEncode(p.productName)));
                    sb.Append(string.Format("<div class='product-footer'><span class='product-price'>{0}</span><span class='sold-count'>{1} sold</span></div>", p.PriceDisplay, p.SoldCount));
                    sb.Append("</div></div></a>");
                    // PDF download button
                    sb.Append(string.Format("<div class='product-actions'><a class='pdf-link' href='{0}' target='_blank' title='Download PDF report'>PDF Report</a></div>", pdfUrl));
                    sb.Append("</div>");
                }

                phProducts.Controls.Add(new LiteralControl(sb.ToString()));
            }
            catch (Exception ex)
            {
                pnlNoProducts.Visible = true;
                pnlNoProducts.Controls.Add(new LiteralControl("Error loading products: " + ex.Message));
            }
        }
    }
}