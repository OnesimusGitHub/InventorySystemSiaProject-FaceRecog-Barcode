using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using MongoDB.Bson;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ProductProfile : Page
    {
        #region DTOs
        private class ChartPeriodData
        {
            public string[] Labels { get; set; }
            public int[] Current { get; set; }
            public int[] Previous { get; set; }
        }
        private class VariantData
        {
            public string[] Labels { get; set; }
            public int[] Data { get; set; }
        }
        private class VariantDetailData
        {
            public ChartPeriodData Daily { get; set; }
            public ChartPeriodData Weekly { get; set; }
            public ChartPeriodData Monthly { get; set; }
        }
        private class ChartData
        {
            public ChartPeriodData Daily { get; set; }
            public ChartPeriodData Weekly { get; set; }
            public ChartPeriodData Monthly { get; set; }
            public VariantData Variants { get; set; }
            public Dictionary<string, VariantDetailData> VariantDetails { get; set; }
        }
        private class OrderRow
        {
            public DateTime Date { get; set; }
            public decimal Amount { get; set; }
            public int Quantity { get; set; }
            public List<string> ProductIds { get; set; }
            public OrderRow() { ProductIds = new List<string>(); }
        }

        /// <summary>Safe DTO — avoids byte[] / List&lt;byte[]&gt; deserialisation crash on the Product model.</summary>
        private class SafeProduct
        {
            public string Id { get; set; }
            public string Name { get; set; }
            public decimal Price { get; set; }
            public string Category { get; set; }
            public string Supplier { get; set; }
            public bool HasImage { get; set; }
        }

        /// <summary>Safe variant DTO — carries only scalar fields we actually need.</summary>
        private class SafeVariant
        {
            public string Id { get; set; }
            public string ProductId { get; set; }
            public string VariantName { get; set; }
            public decimal Price { get; set; }
            public int StockQuantity { get; set; }
            public bool IsActive { get; set; }
            /// <summary>True when VariantImgUrls has at least one non-empty byte[].</summary>
            public bool HasBinaryImage { get; set; }
            /// <summary>String URL field stored directly on the document (if any).</summary>
            public string VariantImg { get; set; }
        }
        #endregion

        // =====================================================================
        #region Page_Load
        protected void Page_Load(object sender, EventArgs e)
        {
            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
            { Response.Redirect("~/WebPages/Login.aspx"); return; }
            if (Session["UserId"] == null)
            { Response.Redirect("~/WebPages/Login.aspx"); return; }

            if (!IsPostBack)
            {
                string productId = Request.QueryString["productId"]
                                ?? Request.QueryString["productid"]
                                ?? Request.QueryString["id"]
                                ?? "";
                hfProductId.Value = productId;
                System.Diagnostics.Debug.WriteLine("[ProductProfile] Product ID: '" + productId + "'");
            }

            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));
            if (IsPostBack) return;

            // Blank controls — async task will fill them in
            litTitle.Text = "";
            litPrice.Text = "";
            litStock.Text = "";
            litOverallStock.Text = "";
            litSold.Text = "";

            RegisterAsyncTask(new PageAsyncTask(InitializeAsync));
        }
        #endregion

        // =====================================================================
        #region Fallback
        private void InitializeFallback()
        {
            litTitle.Text = "Sample Product";
            litPrice.Text = "₱0.00";
            litStock.Text = "N/A";
            litOverallStock.Text = "0";
            litSold.Text = "0";
            mainImage.ImageUrl = "../Content/images/sample-generic.png";
            hfChartData.Value = SerializeChartData(BuildEmptyChartData());
        }

        private void ShowFallback(string msg)
        {
            litTitle.Text = "Product";
            litPrice.Text = "₱0.00";
            litStock.Text = msg;
            litOverallStock.Text = "0";
            mainImage.ImageUrl = "../Content/images/sample-generic.png";
        }
        #endregion

        // =====================================================================
        #region InitializeAsync  (orchestrator)
        private async Task InitializeAsync()
        {
            try
            {
                // Read productId — covers all common query-string key spellings
                var productId = Request.QueryString["productId"]
                                 ?? Request.QueryString["productid"]
                                 ?? Request.QueryString["id"]
                                 ?? "";
                var supplierParam = Request.QueryString["supplier"];

                System.Diagnostics.Debug.WriteLine("[ProductProfile] InitializeAsync started, productId='" + productId + "'");

                // ── Supplier fallback ─────────────────────────────────────────
                if (string.IsNullOrWhiteSpace(productId) && !string.IsNullOrWhiteSpace(supplierParam))
                {
                    try
                    {
                        var rawCol = DatabaseHelper.Database.GetCollection<BsonDocument>(
                            DatabaseHelper.GetProductsCollectionName());
                        var doc = await rawCol.Find(
                            Builders<BsonDocument>.Filter.Or(
                                Builders<BsonDocument>.Filter.Eq("supplier", supplierParam),
                                Builders<BsonDocument>.Filter.Eq("Supplier", supplierParam)
                            )).FirstOrDefaultAsync();
                        if (doc != null) productId = doc["_id"].ToString();
                    }
                    catch { /* swallow — non-critical path */ }
                }

                if (string.IsNullOrWhiteSpace(productId))
                {
                    System.Diagnostics.Debug.WriteLine("[ProductProfile] No productId — fallback");
                    InitializeFallback(); return;
                }

                if (!await DatabaseHelper.TestConnectionAsync())
                {
                    ShowFallback("DB offline"); InitializeFallback(); return;
                }

                // ── Data from InventorySystemDB ───────────────────────────────
                var safeProduct = await LoadSafeProductAsync(productId);
                if (safeProduct == null)
                {
                    System.Diagnostics.Debug.WriteLine("[ProductProfile] Product not found: " + productId);
                    ShowFallback("Not found"); InitializeFallback(); return;
                }

                System.Diagnostics.Debug.WriteLine("[ProductProfile] Product loaded: " + safeProduct.Name);

                var variants = await LoadSafeVariantsAsync(productId);
                System.Diagnostics.Debug.WriteLine("[ProductProfile] Variants loaded: " + variants.Count);

                // ── Bind UI (product info + variants from InventorySystemDB) ──
                BindHeaderSafe(safeProduct, variants);
                BuildThumbsSafe(safeProduct, variants);
                BuildVariantButtons(variants);

                // ── Chart data from db_shessentials ───────────────────────────
                await GenerateChartDataAsync(productId, variants);

                System.Diagnostics.Debug.WriteLine("[ProductProfile] InitializeAsync completed successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ProductProfile] InitializeAsync ERROR: " + ex.Message);
                System.Diagnostics.Debug.WriteLine("[ProductProfile] Stack: " + ex.StackTrace);
                InitializeFallback();
            }
        }
        #endregion

        // =====================================================================
        #region Safe loaders — InventorySystemDB via BsonDocument (no deserialisation crash)

        private async Task<SafeProduct> LoadSafeProductAsync(string productId)
        {
            try
            {
                var col = DatabaseHelper.Database.GetCollection<BsonDocument>(
                    DatabaseHelper.GetProductsCollectionName());

                BsonDocument doc = null;
                try
                {
                    var oid = new ObjectId(productId);
                    doc = await col.Find(Builders<BsonDocument>.Filter.Eq("_id", oid))
                                   .FirstOrDefaultAsync();
                }
                catch { /* not a valid ObjectId */ }

                if (doc == null)
                    doc = await col.Find(Builders<BsonDocument>.Filter.Eq("_id", productId))
                                   .FirstOrDefaultAsync();

                if (doc == null) return null;

                // Check whether productImg contains real binary data
                bool hasImage = false;
                BsonValue imgVal;
                if (doc.TryGetValue("productImg", out imgVal))
                    hasImage = imgVal.BsonType == BsonType.Binary
                               && imgVal.AsBsonBinaryData.Bytes.Length > 0;

                return new SafeProduct
                {
                    Id = doc["_id"].ToString(),
                    Name = BsonSafeString(doc, "productName") ?? BsonSafeString(doc, "ProductName") ?? "Product",
                    Price = BsonSafeDecimal(doc, "productVal") ?? BsonSafeDecimal(doc, "ProductVal") ?? 0m,
                    Category = BsonSafeString(doc, "productCategory") ?? BsonSafeString(doc, "ProductCategory") ?? "",
                    Supplier = BsonSafeString(doc, "supplier") ?? BsonSafeString(doc, "Supplier") ?? "",
                    HasImage = hasImage
                };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ProductProfile] LoadSafeProductAsync ERROR: " + ex.Message);
                return null;
            }
        }

        /// <summary>
        /// Loads variants from InventorySystemDB.product_variants using BsonDocument
        /// projection so that VariantImgUrls (List&lt;byte[]&gt;) is never deserialised
        /// — it crashes the MongoDB driver when the DB stores strings there.
        /// The image is served via GetVariantImage.ashx which reads VariantImgUrls
        /// directly; we just flag <see cref="SafeVariant.HasBinaryImage"/> here.
        /// </summary>
        private async Task<List<SafeVariant>> LoadSafeVariantsAsync(string productId)
        {
            var result = new List<SafeVariant>();
            try
            {
                var col = DatabaseHelper.Database.GetCollection<BsonDocument>(
                    DatabaseHelper.GetProductVariantsCollectionName());

                // productId is stored as ObjectId in the variants collection
                FilterDefinition<BsonDocument> filter;
                try
                {
                    var oid = new ObjectId(productId);
                    filter = Builders<BsonDocument>.Filter.Or(
                        Builders<BsonDocument>.Filter.Eq("productId", oid),
                        Builders<BsonDocument>.Filter.Eq("ProductId", oid),
                        Builders<BsonDocument>.Filter.Eq("productId", productId),
                        Builders<BsonDocument>.Filter.Eq("ProductId", productId)
                    );
                }
                catch
                {
                    filter = Builders<BsonDocument>.Filter.Or(
                        Builders<BsonDocument>.Filter.Eq("productId", productId),
                        Builders<BsonDocument>.Filter.Eq("ProductId", productId)
                    );
                }

                // Project only safe scalar fields + variantImgUrls for existence check
                // We intentionally do NOT let the typed deserialiser touch variantImgUrls
                var projection = Builders<BsonDocument>.Projection
                    .Include("_id")
                    .Include("productId").Include("ProductId")
                    .Include("variantName").Include("VariantName")
                    .Include("price").Include("Price")
                    .Include("stockQuantity").Include("StockQuantity")
                    .Include("isActive").Include("IsActive")
                    .Include("variantImg").Include("VariantImg")
                    .Include("variantImgUrls");   // read raw to check existence

                var docs = await col.Find(filter).Project(projection).ToListAsync();

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[ProductProfile] LoadSafeVariantsAsync: {0} docs for productId '{1}'",
                    docs.Count, productId));

                foreach (var d in docs)
                {
                    bool isActive = true;
                    BsonValue av;
                    if (d.TryGetValue("isActive", out av) || d.TryGetValue("IsActive", out av))
                        if (av.BsonType == BsonType.Boolean) isActive = av.AsBoolean;

                    // Detect whether variantImgUrls has usable binary entries
                    bool hasBinaryImage = false;
                    BsonValue iuv;
                    if (d.TryGetValue("variantImgUrls", out iuv) && iuv.IsBsonArray)
                    {
                        foreach (BsonValue entry in iuv.AsBsonArray)
                        {
                            if (entry.BsonType == BsonType.Binary && entry.AsBsonBinaryData.Bytes.Length > 0)
                            { hasBinaryImage = true; break; }
                        }
                    }

                    result.Add(new SafeVariant
                    {
                        Id = d["_id"].ToString(),
                        ProductId = BsonSafeString(d, "productId") ?? BsonSafeString(d, "ProductId") ?? productId,
                        VariantName = BsonSafeString(d, "variantName") ?? BsonSafeString(d, "VariantName") ?? "Variant",
                        Price = BsonSafeDecimal(d, "price") ?? BsonSafeDecimal(d, "Price") ?? 0m,
                        StockQuantity = (int)(BsonSafeDecimal(d, "stockQuantity") ?? BsonSafeDecimal(d, "StockQuantity") ?? 0m),
                        IsActive = isActive,
                        HasBinaryImage = hasBinaryImage,
                        VariantImg = BsonSafeString(d, "variantImg") ?? BsonSafeString(d, "VariantImg")
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ProductProfile] LoadSafeVariantsAsync ERROR: " + ex.Message);
            }
            return result;
        }
        #endregion

        // =====================================================================
        #region BsonDocument safe field readers
        private static string BsonSafeString(BsonDocument doc, string field)
        {
            BsonValue v;
            if (!doc.TryGetValue(field, out v) || v.IsBsonNull) return null;
            try { return v.AsString; }
            catch { return v.ToString(); }
        }

        private static decimal? BsonSafeDecimal(BsonDocument doc, string field)
        {
            BsonValue v;
            if (!doc.TryGetValue(field, out v) || v.IsBsonNull) return null;
            try
            {
                if (v.IsNumeric) return (decimal)v.ToDouble();
                if (v.BsonType == BsonType.String)
                { decimal d; if (decimal.TryParse(v.AsString, out d)) return d; }
            }
            catch { }
            return null;
        }
        #endregion

        // =====================================================================
        #region UI Binding

        private void BindHeaderSafe(SafeProduct product, List<SafeVariant> variants)
        {
            litTitle.Text = product.Name;
            var totalStock = variants.Sum(v => v.StockQuantity);
            litOverallStock.Text = totalStock.ToString();
            litStock.Text = totalStock > 0 ? "IN STOCK" : "OUT OF STOCK";

            var lowest = variants.Count > 0 ? variants.Min(v => v.Price) : product.Price;
            var highest = variants.Count > 0 ? variants.Max(v => v.Price) : product.Price;
            litPrice.Text = lowest == highest
                ? string.Format("₱{0:N2}", lowest)
                : string.Format("₱{0:N2} - ₱{1:N2}", lowest, highest);

            // Main image: prefer first active variant image, else product image
            mainImage.ImageUrl = ResolveMainImageUrl(product, variants);
            litSold.Text = "0";
        }

        /// <summary>
        /// Image priority:
        ///  1. First active variant that has a binary image  → GetVariantImage.ashx
        ///  2. First active variant that has a string URL    → that URL
        ///  3. Product has a binary image                    → GetProductImage.ashx
        ///  4. Generic placeholder
        /// </summary>
        private string ResolveMainImageUrl(SafeProduct product, List<SafeVariant> variants)
        {
            foreach (var v in variants.Where(x => x.IsActive))
            {
                if (v.HasBinaryImage)
                    return "/Handlers/GetVariantImage.ashx?variantId=" +
                           System.Web.HttpUtility.UrlEncode(v.Id) + "&index=0";
                if (!string.IsNullOrWhiteSpace(v.VariantImg))
                    return v.VariantImg;
            }
            if (product.HasImage)
                return "/Handlers/GetProductImage.ashx?productId=" + product.Id;
            return "../Content/images/sample-generic.png";
        }

        private void BuildThumbsSafe(SafeProduct product, List<SafeVariant> variants)
        {
            var productImgUrl = product.HasImage
                ? "/Handlers/GetProductImage.ashx?productId=" + product.Id
                : "../Content/images/sample-generic.png";

            phThumbs.Controls.Clear();

            // First thumb = product image (always shown)
            phThumbs.Controls.Add(new Literal
            {
                Text = string.Format(
                    "<button class='thumb active' data-images='[\"{0}\"]'><img src='{1}' alt='Product' /></button>",
                    System.Web.HttpUtility.JavaScriptStringEncode(productImgUrl),
                    System.Web.HttpUtility.HtmlAttributeEncode(productImgUrl))
            });

            if (variants == null) return;

            var added = new HashSet<string> { productImgUrl };
            var serializer = new JavaScriptSerializer();

            foreach (var v in variants)
            {
                string primaryUrl;

                if (v.HasBinaryImage)
                    primaryUrl = "/Handlers/GetVariantImage.ashx?variantId=" +
                                 System.Web.HttpUtility.UrlEncode(v.Id) + "&index=0";
                else if (!string.IsNullOrWhiteSpace(v.VariantImg))
                    primaryUrl = v.VariantImg;
                else
                    primaryUrl = productImgUrl;   // fall back to product image

                // Skip if this URL is already shown
                if (added.Contains(primaryUrl)) continue;
                added.Add(primaryUrl);

                var imagesList = new List<string> { primaryUrl };
                var encoded = System.Web.HttpUtility.HtmlAttributeEncode(serializer.Serialize(imagesList));
                var safeId = System.Web.HttpUtility.HtmlAttributeEncode(v.Id);
                var safePrimary = System.Web.HttpUtility.HtmlAttributeEncode(primaryUrl);

                phThumbs.Controls.Add(new Literal
                {
                    Text = string.Format(
                        "<button class='thumb variant-thumb' data-variant-id='{0}' data-images='{1}' data-primary='{2}'>" +
                        "<img src='{3}' alt='{4}' /></button>",
                        safeId, encoded, safePrimary, safePrimary,
                        System.Web.HttpUtility.HtmlAttributeEncode(v.VariantName))
                });
            }
        }

        private void BuildVariantButtons(List<SafeVariant> variants)
        {
            phVariants.Controls.Clear();
            foreach (var v in variants.Take(50))
            {
                var label = string.IsNullOrWhiteSpace(v.VariantName) ? "Variant" : v.VariantName;
                var safeLabel = System.Web.HttpUtility.HtmlEncode(label);
                var safeId = System.Web.HttpUtility.HtmlAttributeEncode(v.Id);
                phVariants.Controls.Add(new Literal
                {
                    Text = string.Format(
                        "<div style='display:inline-block; margin:4px; padding:8px 12px; background:#f5f5f5; border-radius:6px;'>" +
                        "<button type='button' class='option variant-btn' data-variant-id='{0}' style='border:none; background:transparent; padding:0; margin-right:8px; cursor:pointer; font-size:14px;'>{1}</button>" +
                        "<button type='button' class='print-btn' onclick='generateVariantPdf(\"{0}\", \"{1}\"); event.stopPropagation();' title='Download PDF for {1}' style='background:#ff5722; color:#fff; border:none; padding:4px 10px; border-radius:4px; cursor:pointer; font-size:11px;'>" +
                        "<i class='fas fa-file-pdf'></i> Print PDF</button></div>",
                        safeId, safeLabel)
                });
            }
            if (variants.Count == 0)
                phVariants.Controls.Add(new Literal { Text = "<span style='opacity:.6'>No active variants</span>" });
        }
        #endregion

        // =====================================================================
        #region Chart Data — reads from db_shessentials.tbl_order

        private async Task GenerateChartDataAsync(string productId, List<SafeVariant> variants)
        {
            try
            {
                // Build a set of this product's variant IDs (as strings)
                var variantIdSet = new HashSet<string>(variants.Select(v => v.Id));

                // Also accept the productId itself in case items reference the product directly
                variantIdSet.Add(productId);

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[ProductProfile] Matching against {0} variant IDs: {1}",
                    variantIdSet.Count, string.Join(", ", variantIdSet)));

                // ── Paid orders from db_shessentials.tbl_order ────────────────
                var ordersCol = DatabaseHelper.GetOrdersCollection();
                var since = DateTime.UtcNow.AddDays(-400);

                // Match on payment_status only — date field name varies (created_at vs createdAt)
                var orderFilter = Builders<BsonDocument>.Filter.In(
                    "payment_status", new[] { "Paid", "paid", "PAID" }
                );

                var paidOrders = await ordersCol.Find(orderFilter).ToListAsync();

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[ProductProfile] Loaded {0} paid orders from tbl_order", paidOrders.Count));

                var productRows = new List<OrderRow>();

                foreach (var order in paidOrders)
                {
                    // ── Parse order date — try both field name spellings ──────
                    DateTime orderDate;
                    BsonValue dv;
                    bool hasDate = false;

                    if (order.TryGetValue("created_at", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else if (order.TryGetValue("createdAt", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else if (order.TryGetValue("updated_at", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else if (order.TryGetValue("updatedAt", out dv) && TryParseDate(dv, out orderDate)) hasDate = true;
                    else { orderDate = DateTime.MinValue; }

                    // Skip orders older than the window (400 days)
                    if (hasDate && orderDate < DateTime.UtcNow.AddDays(-400)) continue;

                    // ── Parse total amount ────────────────────────────────────
                    decimal amount = 0;
                    BsonValue av;
                    if (order.TryGetValue("total_amount", out av)) amount = BsonToDecimal(av);
                    else if (order.TryGetValue("totalAmount", out av)) amount = BsonToDecimal(av);
                    else if (order.TryGetValue("total", out av)) amount = BsonToDecimal(av);

                    // ── Walk items array and match product_id to our variant IDs ──
                    var matchedVariantIds = new List<string>();
                    int quantity = 0;

                    BsonValue iv;
                    if (order.TryGetValue("items", out iv) && iv.IsBsonArray)
                    {
                        foreach (BsonValue item in iv.AsBsonArray)
                        {
                            if (!item.IsBsonDocument) continue;
                            var itemDoc = item.AsBsonDocument;

                            // product_id in tbl_order.items stores the variant's _id
                            BsonValue pidVal;
                            string pid = null;
                            if (itemDoc.TryGetValue("product_id", out pidVal))
                                pid = pidVal.ToString();
                            else if (itemDoc.TryGetValue("variant_id", out pidVal))
                                pid = pidVal.ToString();
                            else if (itemDoc.TryGetValue("productId", out pidVal))
                                pid = pidVal.ToString();

                            if (string.IsNullOrWhiteSpace(pid)) continue;

                            // Only count items whose product_id matches one of this product's variants
                            if (!variantIdSet.Contains(pid)) continue;

                            matchedVariantIds.Add(pid);

                            BsonValue qv;
                            int itemQty = 1;
                            if (itemDoc.TryGetValue("quantity", out qv))
                                itemQty = Math.Max(1, (int)BsonToDecimal(qv));

                            quantity += itemQty;
                        }
                    }

                    if (matchedVariantIds.Count == 0) continue;

                    // Use current time as fallback date if none found
                    if (!hasDate) orderDate = DateTime.UtcNow;

                    productRows.Add(new OrderRow
                    {
                        Date = orderDate.ToLocalTime(),
                        Amount = amount,
                        Quantity = quantity,
                        ProductIds = matchedVariantIds
                    });
                }

                System.Diagnostics.Debug.WriteLine(string.Format(
                    "[ProductProfile] Product '{0}' matched {1} orders, total qty = {2}",
                    productId, productRows.Count, productRows.Sum(r => r.Quantity)));

                // ── Per-variant row map ───────────────────────────────────────
                var variantRowMap = new Dictionary<string, List<OrderRow>>();
                foreach (var v in variants) variantRowMap[v.Id] = new List<OrderRow>();

                foreach (var row in productRows)
                    foreach (var vid in row.ProductIds)
                    {
                        List<OrderRow> list;
                        if (variantRowMap.TryGetValue(vid, out list))
                            list.Add(row);
                    }

                var data = BuildChartDataFromOrderRows(productRows, variants, variantRowMap);
                hfChartData.Value = SerializeChartData(data);

                int totalSold = productRows.Sum(r => r.Quantity);
                litSold.Text = totalSold >= 1000
                    ? (totalSold / 1000.0).ToString("0.#") + "K"
                    : totalSold.ToString();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[ProductProfile] GenerateChartDataAsync ERROR: " + ex.Message);
                hfChartData.Value = SerializeChartData(BuildEmptyChartData());
                if (string.IsNullOrEmpty(litSold.Text)) litSold.Text = "0";
            }
        } 

        private ChartData BuildChartDataFromOrderRows(
            List<OrderRow> rows,
            List<SafeVariant> variants,
            Dictionary<string, List<OrderRow>> variantRowMap)
        {
            var now = DateTime.Now.Date;

            // Daily — last 7 days
            var dailyLabels = new List<string>(); var dailyCurrent = new List<int>(); var dailyPrevious = new List<int>();
            for (int i = 6; i >= 0; i--)
            {
                var day = now.AddDays(-i);
                dailyLabels.Add(day.ToString("ddd"));
                dailyCurrent.Add(rows.Where(r => r.Date.Date == day).Sum(r => r.Quantity));
                dailyPrevious.Add(rows.Where(r => r.Date.Date == day.AddDays(-7)).Sum(r => r.Quantity));
            }

            // Weekly — last 4 weeks
            var weeklyLabels = new List<string>(); var weeklyCurrent = new List<int>(); var weeklyPrevious = new List<int>();
            var weekStartRef = now.AddDays(-(int)now.DayOfWeek);
            for (int i = 3; i >= 0; i--)
            {
                var start = weekStartRef.AddDays(-7 * i);
                weeklyLabels.Add(string.Format("Week {0}", 4 - i));
                weeklyCurrent.Add(rows.Where(r => r.Date.Date >= start && r.Date.Date <= start.AddDays(6)).Sum(r => r.Quantity));
                var ps = start.AddDays(-28);
                weeklyPrevious.Add(rows.Where(r => r.Date.Date >= ps && r.Date.Date <= ps.AddDays(6)).Sum(r => r.Quantity));
            }

            // Monthly — last 3 months
            var monthlyLabels = new List<string>(); var monthlyCurrent = new List<int>(); var monthlyPrevious = new List<int>();
            for (int i = 2; i >= 0; i--)
            {
                var month = new DateTime(now.Year, now.Month, 1).AddMonths(-i);
                var monthEnd = month.AddMonths(1).AddDays(-1);
                monthlyLabels.Add(month.ToString("MMM"));
                monthlyCurrent.Add(rows.Where(r => r.Date.Date >= month && r.Date.Date <= monthEnd).Sum(r => r.Quantity));
                var ps = month.AddYears(-1);
                monthlyPrevious.Add(rows.Where(r => r.Date.Date >= ps && r.Date.Date <= ps.AddMonths(1).AddDays(-1)).Sum(r => r.Quantity));
            }

            // Variant donut
            var variantLabels = new List<string>(); var variantData = new List<int>();
            foreach (var v in variants.Take(5))
            {
                List<OrderRow> vRows;
                var qty = variantRowMap.TryGetValue(v.Id, out vRows) ? vRows.Sum(r => r.Quantity) : 0;
                if (qty > 0)
                {
                    variantLabels.Add(string.IsNullOrWhiteSpace(v.VariantName) ? "Variant" : v.VariantName);
                    variantData.Add(qty);
                }
            }

            // Per-variant detail
            var variantDetails = new Dictionary<string, VariantDetailData>();
            foreach (var v in variants.Take(50))
            {
                List<OrderRow> vRows;
                variantDetails[v.Id] = BuildVariantDetailFromOrderRows(
                    variantRowMap.TryGetValue(v.Id, out vRows) ? vRows : new List<OrderRow>(), now);
            }

            return new ChartData
            {
                Daily = new ChartPeriodData { Labels = dailyLabels.ToArray(), Current = dailyCurrent.ToArray(), Previous = dailyPrevious.ToArray() },
                Weekly = new ChartPeriodData { Labels = weeklyLabels.ToArray(), Current = weeklyCurrent.ToArray(), Previous = weeklyPrevious.ToArray() },
                Monthly = new ChartPeriodData { Labels = monthlyLabels.ToArray(), Current = monthlyCurrent.ToArray(), Previous = monthlyPrevious.ToArray() },
                Variants = new VariantData { Labels = variantLabels.ToArray(), Data = variantData.ToArray() },
                VariantDetails = variantDetails
            };
        }

        private VariantDetailData BuildVariantDetailFromOrderRows(List<OrderRow> rows, DateTime now)
        {
            var dl = new List<string>(); var dc = new List<int>(); var dp = new List<int>();
            for (int i = 6; i >= 0; i--)
            {
                var day = now.AddDays(-i);
                dl.Add(day.ToString("ddd"));
                dc.Add(rows.Where(r => r.Date.Date == day).Sum(r => r.Quantity));
                dp.Add(rows.Where(r => r.Date.Date == day.AddDays(-7)).Sum(r => r.Quantity));
            }
            var wl = new List<string>(); var wc = new List<int>(); var wp = new List<int>();
            var wsr = now.AddDays(-(int)now.DayOfWeek);
            for (int i = 3; i >= 0; i--)
            {
                var start = wsr.AddDays(-7 * i);
                wl.Add(string.Format("Week {0}", 4 - i));
                wc.Add(rows.Where(r => r.Date.Date >= start && r.Date.Date <= start.AddDays(6)).Sum(r => r.Quantity));
                var ps = start.AddDays(-28);
                wp.Add(rows.Where(r => r.Date.Date >= ps && r.Date.Date <= ps.AddDays(6)).Sum(r => r.Quantity));
            }
            var ml = new List<string>(); var mc = new List<int>(); var mp = new List<int>();
            for (int i = 2; i >= 0; i--)
            {
                var month = new DateTime(now.Year, now.Month, 1).AddMonths(-i);
                var monthEnd = month.AddMonths(1).AddDays(-1);
                ml.Add(month.ToString("MMM"));
                mc.Add(rows.Where(r => r.Date.Date >= month && r.Date.Date <= monthEnd).Sum(r => r.Quantity));
                var ps = month.AddYears(-1);
                mp.Add(rows.Where(r => r.Date.Date >= ps && r.Date.Date <= ps.AddMonths(1).AddDays(-1)).Sum(r => r.Quantity));
            }
            return new VariantDetailData
            {
                Daily = new ChartPeriodData { Labels = dl.ToArray(), Current = dc.ToArray(), Previous = dp.ToArray() },
                Weekly = new ChartPeriodData { Labels = wl.ToArray(), Current = wc.ToArray(), Previous = wp.ToArray() },
                Monthly = new ChartPeriodData { Labels = ml.ToArray(), Current = mc.ToArray(), Previous = mp.ToArray() }
            };
        }

        private ChartData BuildEmptyChartData()
        {
            var now = DateTime.Now.Date;
            var dl = new List<string>(); for (int i = 6; i >= 0; i--) dl.Add(now.AddDays(-i).ToString("ddd"));
            var ml = new List<string>(); for (int i = 2; i >= 0; i--) ml.Add(new DateTime(now.Year, now.Month, 1).AddMonths(-i).ToString("MMM"));
            return new ChartData
            {
                Daily = new ChartPeriodData { Labels = dl.ToArray(), Current = new int[7], Previous = new int[7] },
                Weekly = new ChartPeriodData { Labels = new[] { "Week 1", "Week 2", "Week 3", "Week 4" }, Current = new int[4], Previous = new int[4] },
                Monthly = new ChartPeriodData { Labels = ml.ToArray(), Current = new int[3], Previous = new int[3] },
                Variants = new VariantData { Labels = new string[0], Data = new int[0] },
                VariantDetails = new Dictionary<string, VariantDetailData>()
            };
        }

        private string SerializeChartData(ChartData data)
        {
            var serializer = new JavaScriptSerializer();
            var variantDetailsDict = new Dictionary<string, object>();
            if (data.VariantDetails != null)
                foreach (var kvp in data.VariantDetails)
                {
                    if (kvp.Value == null) continue;
                    variantDetailsDict[kvp.Key] = new
                    {
                        daily = new { labels = kvp.Value.Daily.Labels, current = kvp.Value.Daily.Current, previous = kvp.Value.Daily.Previous },
                        weekly = new { labels = kvp.Value.Weekly.Labels, current = kvp.Value.Weekly.Current, previous = kvp.Value.Weekly.Previous },
                        monthly = new { labels = kvp.Value.Monthly.Labels, current = kvp.Value.Monthly.Current, previous = kvp.Value.Monthly.Previous }
                    };
                }
            return serializer.Serialize(new
            {
                daily = new { labels = data.Daily.Labels, current = data.Daily.Current, previous = data.Daily.Previous },
                weekly = new { labels = data.Weekly.Labels, current = data.Weekly.Current, previous = data.Weekly.Previous },
                monthly = new { labels = data.Monthly.Labels, current = data.Monthly.Current, previous = data.Monthly.Previous },
                variants = new { labels = data.Variants.Labels, data = data.Variants.Data },
                variantDetails = variantDetailsDict
            });
        }
        #endregion

        // =====================================================================
        #region BsonValue / date helpers
        private static bool TryParseDate(BsonValue val, out DateTime result)
        {
            result = DateTime.MinValue;
            if (val == null || val.IsBsonNull) return false;
            try
            {
                if (val.BsonType == BsonType.DateTime) { result = val.ToUniversalTime(); return true; }
                if (val.BsonType == BsonType.String) return DateTime.TryParse(val.AsString, out result);
            }
            catch { }
            return false;
        }

        private static decimal BsonToDecimal(BsonValue val)
        {
            if (val == null || val.IsBsonNull) return 0;
            try
            {
                if (val.IsNumeric) return (decimal)val.ToDouble();
                if (val.BsonType == BsonType.String) { decimal d; if (decimal.TryParse(val.AsString, out d)) return d; }
            }
            catch { }
            return 0;
        }
        #endregion
    }
}