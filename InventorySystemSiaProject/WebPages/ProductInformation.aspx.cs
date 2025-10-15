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
                var productFilter = Builders<Models.Product>.Filter.Eq(p => p.IsActive, true);
                var products = productsCollection.Find(productFilter).ToList();

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

                // Build product cards
                var bestSelling = products.Select(p => new
                {
                    ProductId = p.Id,
                    p.ProductName,
                    SupplierName = p.Supplier?.SupName ?? string.Empty,
                    ProductImg = string.IsNullOrWhiteSpace(p.ProductImg) ? "/Content/images/sample-generic.png" : p.ProductImg,
                    PriceDisplay = "₱" + p.ProductVal.ToString("N2"),
                    SoldCount = productSales.ContainsKey(p.Id) ? productSales[p.Id] : 0,
                    p.CreatedAt
                })
                .OrderByDescending(p => p.SoldCount)
                .ThenByDescending(p => p.CreatedAt)
                .Take(12)
                .ToList();

                var sb = new StringBuilder();
                foreach (var p in bestSelling)
                {
                    var profileUrl = ResolveUrl("~/WebPages/ProductProfile.aspx?productId=" + p.ProductId + "&supplier=" + HttpUtility.UrlEncode(p.SupplierName));
                    var pdfUrl = ResolveUrl("~/Handlers/DownloadProductReportPdf.ashx?productId=" + p.ProductId);
                    sb.Append("<div class='product-card-wrapper'>");
                    sb.Append("<a class='product-card-link' href='" + profileUrl + "' onclick=\"window.location.href='" + profileUrl + "';return true;\" target='_blank' rel='noopener'>");
                    sb.Append("<div class='product-card'>");
                    sb.Append("<div class='product-image-wrapper'>");
                    sb.Append("<img src='" + p.ProductImg + "' alt='" + Server.HtmlEncode(p.ProductName) + "' class='product-image' />");
                    sb.Append("</div>");
                    sb.Append("<div class='product-body'>");
                    sb.Append("<div class='product-badges primary'><span class='badge badge-preferred'>Preferred</span></div>");
                    sb.Append("<div class='product-name multiline-ellipsis'>" + Server.HtmlEncode(p.ProductName) + "</div>");
                    sb.Append("<div class='product-footer'><span class='product-price'>" + p.PriceDisplay + "</span><span class='sold-count'>" + p.SoldCount + " sold</span></div>");
                    sb.Append("</div></div></a>");
                    // PDF download button
                    sb.Append("<div class='product-actions'><a class='pdf-link' href='" + pdfUrl + "' target='_blank' title='Download PDF report'>PDF Report</a></div>");
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