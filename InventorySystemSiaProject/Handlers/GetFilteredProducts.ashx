<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetFilteredProducts" %>

using System;
using System.Web;
using System.Text;
using System.Linq;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Handlers
{
    public class GetFilteredProducts : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/html";
            var search = (context.Request["search"] ?? "").Trim().ToLower();
            var category = (context.Request["category"] ?? "").Trim();

            var productsCollection = DatabaseHelper.GetProductsCollection();
            var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
            var salesCollection = DatabaseHelper.GetSalesCollection();

            var filterBuilder = Builders<Product>.Filter;
            var filter = filterBuilder.Eq(p => p.IsActive, true);
            if (!string.IsNullOrEmpty(category))
            {
                filter &= filterBuilder.Eq(p => p.ProductCategory, category);
            }
            if (!string.IsNullOrEmpty(search))
            {
                filter &= filterBuilder.Regex(p => p.ProductName, new MongoDB.Bson.BsonRegularExpression(search, "i"));
            }

            var products = productsCollection.Find(filter).ToList();
            if (products == null || products.Count == 0)
            {
                context.Response.Write("");
                return;
            }

            var productIds = products.Select(p => p.Id).ToList();
            var variantFilter = Builders<ProductVariant>.Filter.In(v => v.ProductId, productIds) & Builders<ProductVariant>.Filter.Eq(v => v.IsActive, true);
            var variants = variantsCollection.Find(variantFilter).ToList();
            var variantIds = variants.Select(v => v.Id).ToList();

            var productSales = new Dictionary<string, int>();
            if (variantIds.Count > 0)
            {
                var salesFilter = Builders<Sale>.Filter.In(s => s.VariantId, variantIds);
                var sales = salesCollection.Find(salesFilter).ToList();
                var variantSales = sales.GroupBy(s => s.VariantId).ToDictionary(g => g.Key, g => g.Sum(s => s.Quantity));
                foreach (var variant in variants)
                {
                    int sold;
                    if (variantSales.TryGetValue(variant.Id, out sold))
                        productSales[variant.ProductId] = (productSales.ContainsKey(variant.ProductId) ? productSales[variant.ProductId] : 0) + sold;
                }
            }

            var bestSelling = products.Select(p =>
            {
                var productVariants = variants.Where(v => v.ProductId == p.Id).ToList();
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
                else if (p.ProductVal > 0)
                {
                    priceDisplay = "&#8369;" + p.ProductVal.ToString("N2");
                }
                string supplierName = (p.Supplier != null && p.Supplier.SupName != null) ? p.Supplier.SupName : string.Empty;
                string productImg = (!string.IsNullOrWhiteSpace(p.ProductImg)) ? p.ProductImg : "/Content/images/sample-generic.png";
                return new
                {
                    ProductId = p.Id,
                    p.ProductName,
                    SupplierName = supplierName,
                    ProductImg = productImg,
                    PriceDisplay = priceDisplay,
                    SoldCount = productSales.ContainsKey(p.Id) ? productSales[p.Id] : 0,
                    p.CreatedAt,
                    p.ProductCategory
                };
            })
            .OrderByDescending(p => p.SoldCount)
            .ThenByDescending(p => p.CreatedAt)
            .Take(12)
            .ToList();

            var sb = new StringBuilder();
            foreach (var p in bestSelling)
            {
                var profileUrl = "/WebPages/ProductProfile.aspx?productId=" + p.ProductId + "&supplier=" + HttpUtility.UrlEncode(p.SupplierName);
                var categoryAttr = p.ProductCategory ?? "";
                sb.Append("<div class='product-card-wrapper'>");
                sb.Append("<a class='product-card-link' href='" + profileUrl + "' onclick=\"window.location.href='" + profileUrl + "';return true;\" target='_blank' rel='noopener'>");
                sb.Append("<div class='product-card' data-category='" + HttpUtility.HtmlAttributeEncode(categoryAttr) + "' data-name='" + HttpUtility.HtmlAttributeEncode(p.ProductName) + "'>");
                sb.Append("<div class='product-image-wrapper'>");
                sb.Append("<img src='" + p.ProductImg + "' alt='" + HttpUtility.HtmlAttributeEncode(p.ProductName) + "' class='product-image' />");
                sb.Append("</div>");
                sb.Append("<div class='product-body'>");
                sb.Append("<div class='product-badges primary'><span class='badge badge-preferred'>Preferred</span></div>");
                sb.Append("<div class='product-name multiline-ellipsis'>" + HttpUtility.HtmlEncode(p.ProductName) + "</div>");
                sb.Append("<div class='product-footer'><span class='product-price'>" + p.PriceDisplay + "</span><span class='sold-count'>" + p.SoldCount + " sold</span></div>");
                sb.Append("</div></div></a>");
                sb.Append("</div>");
            }
            context.Response.Write(sb.ToString());
        }

        public bool IsReusable { get { return false; } }
    }
}
