using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;
using MongoDB.Bson;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ProductProfile : Page
    {
        #region DTOs used for Chart.js JSON
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
        #endregion

        private static bool _salesIndexesEnsured = false;

        protected void Page_Load(object sender, EventArgs e)
        {



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
            if (!IsPostBack)
            {
                // Check all possible variations of the parameter name
                string productId = Request.QueryString["productId"]
                                ?? Request.QueryString["productid"]
                                ?? Request.QueryString["id"]
                                ?? "";

                // Store in hidden field for JavaScript access
                hfProductId.Value = productId;

                // Debug logging
                System.Diagnostics.Debug.WriteLine($"📍 Product ID extracted: '{productId}'");
                System.Diagnostics.Debug.WriteLine($"📍 Full query string: '{Request.QueryString}'");

                if (string.IsNullOrEmpty(productId))
                {
                    Response.Write("<script>console.error('⚠️ Product ID is missing from query string');</script>");
                }
                else
                {
                    Response.Write($"<script>console.log('✅ Product ID loaded: {productId}');</script>");
                }
            }
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));

            if (IsPostBack) return;
            RegisterAsyncTask(new PageAsyncTask(InitializeAsync));
        }

        private void EnsureSalesIndexes()
        {
            if (_salesIndexesEnsured) return;
            try
            {
                var sales = DatabaseHelper.GetSalesCollection();
                var indexModels = new List<CreateIndexModel<Sale>>
                {
                    new CreateIndexModel<Sale>(Builders<Sale>.IndexKeys.Ascending(s => s.VariantId).Ascending(s => s.TransactionDate)),
                    new CreateIndexModel<Sale>(Builders<Sale>.IndexKeys.Ascending(s => s.ProductId).Ascending(s => s.TransactionDate)),
                    new CreateIndexModel<Sale>(Builders<Sale>.IndexKeys.Ascending(s => s.TransactionDate))
                };
                sales.Indexes.CreateMany(indexModels);
            }
            catch { /* ignore */ }
            _salesIndexesEnsured = true;
        }

        private void InitializeFallback()
        {
            ShowFallback("Loading...");
            hfChartData.Value = SerializeChartData(BuildEmptyChartData(new List<ProductVariant>()));
            litTitle.Text = "Sample Product";
            litPrice.Text = "₱99.99";
            mainImage.ImageUrl = "../Content/images/sample-generic.png";
        }

        private async Task InitializeAsync()
        {
            try
            {
                var productId = Request.QueryString["productId"];
                var supplierParam = Request.QueryString["supplier"];

                if (string.IsNullOrWhiteSpace(productId) && !string.IsNullOrWhiteSpace(supplierParam))
                {
                    try
                    {
                        var pc = DatabaseHelper.GetProductsCollection();
                        var prod = await pc.Find(p => p.Supplier != null && p.Supplier.SupName == supplierParam).FirstOrDefaultAsync();
                        if (prod != null) productId = prod.Id;
                    }
                    catch { /* ignore */ }
                }

                if (string.IsNullOrWhiteSpace(productId)) { InitializeFallback(); return; }
                if (!await DatabaseHelper.TestConnectionAsync()) { ShowFallback("DB offline"); InitializeFallback(); return; }

                var productService = new ProductService();
                var agg = await productService.GetProductWithVariantsAggregationAsync(productId);
                var productCol = DatabaseHelper.GetProductsCollection();
                var product = agg.Product ?? await productCol.Find(p => p.Id == productId).FirstOrDefaultAsync();
                if (product == null) { ShowFallback("Not found"); InitializeFallback(); return; }

                if (!string.IsNullOrEmpty(product.SupplierId))
                {
                    try
                    {
                        var supplierService = new SupplierService();
                        var supplier = await supplierService.GetSupplierByIdAsync(product.SupplierId);
                        if (supplier != null)
                        {
                            product.Supplier = supplier;
                            System.Diagnostics.Debug.WriteLine($"Supplier loaded: {supplier.SupName}");
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine($"Supplier not found with ID: {product.SupplierId}");
                        }
                    }
                    catch (Exception supEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"Error fetching supplier: {supEx.Message}");
                    }
                }

                var variantsCol = DatabaseHelper.GetProductVariantsCollection();
                var variants = await variantsCol.Find(v => v.ProductId == product.Id && v.IsActive).ToListAsync();
                if (variants.Count == 0)
                    variants = await variantsCol.Find(v => v.ProductId == product.Id).ToListAsync();

                foreach (var v in agg.Variants ?? new List<ProductVariant>())
                {
                    if (variants.All(x => x.Id != v.Id)) variants.Add(v);
                }

                BindHeader(product, variants);
                BuildThumbs(product, variants);
                BuildVariantButtons(variants);

                await GenerateChartDataAsync(product.Id, variants);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("ProductProfile InitializeAsync ERROR: " + ex.Message);
                InitializeFallback();
            }
        }

        #region UI Binding Helpers
        private void BindHeader(Product product, List<ProductVariant> variants)
        {
            litTitle.Text = string.IsNullOrWhiteSpace(product.ProductName) ? "Product" : product.ProductName;
            var totalStock = variants.Sum(v => v.StockQuantity);
            litOverallStock.Text = totalStock.ToString();
            litStock.Text = totalStock > 0 ? "IN STOCK" : "OUT OF STOCK";
            var lowest = variants.Count > 0 ? variants.Min(v => v.Price) : product.ProductVal;
            var highest = variants.Count > 0 ? variants.Max(v => v.Price) : product.ProductVal;
            litPrice.Text = lowest == highest ? $"₱{lowest:N2}" : $"₱{lowest:N2} - ₱{highest:N2}";
            mainImage.ImageUrl = string.IsNullOrWhiteSpace(product.ProductImg) ? "../Content/images/sample-generic.png" : product.ProductImg;
            litSold.Text = "0";
        }

        private void BuildThumbs(Product product, List<ProductVariant> variants = null)
        {
            var img = string.IsNullOrWhiteSpace(product.ProductImg) ? "../Content/images/sample-generic.png" : product.ProductImg;
            phThumbs.Controls.Clear();
            phThumbs.Controls.Add(new Literal
            {
                Text = $"<button class='thumb active' data-src='{img}'><img src='{img}' alt='thumb' /></button>"
            });
            if (variants != null)
            {
                var added = new HashSet<string> { img };
                foreach (var v in variants)
                {
                    var vImg = string.IsNullOrWhiteSpace(v.VariantImg) ? null : v.VariantImg;
                    if (!string.IsNullOrWhiteSpace(vImg) && !added.Contains(vImg))
                    {
                        phThumbs.Controls.Add(new Literal
                        {
                            Text = $"<button class='thumb' data-src='{vImg}'><img src='{vImg}' alt='variant thumb' /></button>"
                        });
                        added.Add(vImg);
                    }
                }
            }
        }

        private void BuildVariantButtons(List<ProductVariant> variants)
        {
            phVariants.Controls.Clear();
            foreach (var v in variants.Take(50))
            {
                var label = string.IsNullOrWhiteSpace(v.VariantName) ? "Variant" : v.VariantName;
                var safeLabel = System.Web.HttpUtility.HtmlEncode(label);
                var safeId = System.Web.HttpUtility.HtmlAttributeEncode(v.Id);

                phVariants.Controls.Add(new Literal
                {
                    Text = $@"<div style='display:inline-block; margin:4px; padding:8px 12px; background:#f5f5f5; border-radius:6px;'>
                        <button type='button' class='option variant-btn' data-variant-id='{safeId}' style='border:none; background:transparent; padding:0; margin-right:8px; cursor:pointer; font-size:14px;'>{safeLabel}</button>
                        <button type='button' class='print-btn' onclick='generateVariantPdf(""{safeId}"", ""{safeLabel}""); event.stopPropagation();' title='Download PDF for {safeLabel}' style='background:#ff5722; color:#fff; border:none; padding:4px 10px; border-radius:4px; cursor:pointer; font-size:11px;'>
                            <i class='fas fa-file-pdf'></i> Print PDF
                        </button>
                    </div>"
                });
            }
            if (variants.Count == 0)
            {
                phVariants.Controls.Add(new Literal { Text = "<span style='opacity:.6'>No active variants</span>" });
            }
        }
        #endregion

        #region Chart Data Generation
        private async Task GenerateChartDataAsync(string productId, List<ProductVariant> variants)
        {
            try
            {
                EnsureSalesIndexes();
                var salesService = new SalesService();
                var variantColl = DatabaseHelper.GetProductVariantsCollection();
                var allVariantIds = await variantColl.Find(v => v.ProductId == productId).Project(v => v.Id).ToListAsync();
                var since = DateTime.UtcNow.AddDays(-365);
                var sales = await salesService.GetCombinedSalesByProductIdAsync(productId, since);
                if (sales.Count == 0 && allVariantIds.Count > 0)
                    sales = await salesService.GetCombinedSalesByVariantIdsAsync(allVariantIds, since);

                ChartData data = BuildChartDataFromSales(sales, variants);

                data.VariantDetails = new Dictionary<string, VariantDetailData>();
                foreach (var variant in variants.Take(50))
                {
                    var vSales = sales.Where(s => s.VariantId == variant.Id).ToList();
                    var detail = BuildVariantDetailData(vSales);
                    data.VariantDetails[variant.Id] = detail;
                }

                hfChartData.Value = SerializeChartData(data);
                int totalSold = 0;
                try
                {
                    var salesCol = DatabaseHelper.GetSalesCollection();
                    var fBuilder = Builders<Sale>.Filter;
                    var filter = fBuilder.Or(
                        fBuilder.Eq(s => s.ProductId, productId),
                        allVariantIds.Count > 0 ? fBuilder.In(s => s.VariantId, allVariantIds) : fBuilder.Where(_ => false)
                    );
                    var aggResult = await salesCol.Aggregate()
                        .Match(filter)
                        .Group(new BsonDocument { { "_id", 1 }, { "qty", new BsonDocument("$sum", "$quantity") } })
                        .FirstOrDefaultAsync();
                    if (aggResult != null && aggResult.Contains("qty")) totalSold = aggResult["qty"].ToInt32();
                }
                catch { }
                litSold.Text = totalSold >= 1000 ? (totalSold / 1000.0).ToString("0.#") + "K" : totalSold.ToString();
            }
            catch
            {
                hfChartData.Value = SerializeChartData(BuildEmptyChartData(variants));
                if (string.IsNullOrEmpty(litSold.Text)) litSold.Text = "0";
            }
        }

        private ChartData BuildChartDataFromSales(List<Sale> sales, List<ProductVariant> variants)
        {
            var now = DateTime.UtcNow.Date;

            var dailyLabels = new List<string>();
            var dailyCurrent = new List<int>();
            var dailyPrevious = new List<int>();
            for (int i = 6; i >= 0; i--)
            {
                var day = now.AddDays(-i);
                dailyLabels.Add(day.ToString("ddd"));
                dailyCurrent.Add(sales.Where(s => s.TransactionDate.Date == day).Sum(s => s.Quantity));
                var prev = day.AddDays(-7);
                dailyPrevious.Add(sales.Where(s => s.TransactionDate.Date == prev).Sum(s => s.Quantity));
            }

            var weeklyLabels = new List<string>();
            var weeklyCurrent = new List<int>();
            var weeklyPrevious = new List<int>();
            var weekStartRef = now.AddDays(-(int)now.DayOfWeek);
            for (int i = 3; i >= 0; i--)
            {
                var start = weekStartRef.AddDays(-7 * i);
                var end = start.AddDays(6);
                weeklyLabels.Add($"Week {4 - i}");
                weeklyCurrent.Add(sales.Where(s => s.TransactionDate.Date >= start && s.TransactionDate.Date <= end).Sum(s => s.Quantity));
                var prevStart = start.AddDays(-28);
                var prevEnd = prevStart.AddDays(6);
                weeklyPrevious.Add(sales.Where(s => s.TransactionDate.Date >= prevStart && s.TransactionDate.Date <= prevEnd).Sum(s => s.Quantity));
            }

            var monthlyLabels = new List<string>();
            var monthlyCurrent = new List<int>();
            var monthlyPrevious = new List<int>();
            for (int i = 2; i >= 0; i--)
            {
                var month = new DateTime(now.Year, now.Month, 1).AddMonths(-i);
                var monthEnd = month.AddMonths(1).AddDays(-1);
                monthlyLabels.Add(month.ToString("MMM"));
                monthlyCurrent.Add(sales.Where(s => s.TransactionDate >= month && s.TransactionDate <= monthEnd).Sum(s => s.Quantity));
                var prevYearStart = month.AddYears(-1);
                var prevYearEnd = prevYearStart.AddMonths(1).AddDays(-1);
                monthlyPrevious.Add(sales.Where(s => s.TransactionDate >= prevYearStart && s.TransactionDate <= prevYearEnd).Sum(s => s.Quantity));
            }

            var variantGroups = sales.GroupBy(s => s.VariantId)
                                      .Select(g => new { Id = g.Key, Qty = g.Sum(x => x.Quantity) })
                                      .OrderByDescending(x => x.Qty)
                                      .Take(5)
                                      .ToList();
            var variantLabels = new List<string>();
            var variantData = new List<int>();

            if (variantGroups.Count > 0)
            {
                foreach (var g in variantGroups)
                {
                    var v = variants.FirstOrDefault(x => x.Id == g.Id);
                    variantLabels.Add(string.IsNullOrWhiteSpace(v?.VariantName) ? "Variant" : v.VariantName);
                    variantData.Add(g.Qty);
                }
            }

            return new ChartData
            {
                Daily = new ChartPeriodData { Labels = dailyLabels.ToArray(), Current = dailyCurrent.ToArray(), Previous = dailyPrevious.ToArray() },
                Weekly = new ChartPeriodData { Labels = weeklyLabels.ToArray(), Current = weeklyCurrent.ToArray(), Previous = weeklyPrevious.ToArray() },
                Monthly = new ChartPeriodData { Labels = monthlyLabels.ToArray(), Current = monthlyCurrent.ToArray(), Previous = monthlyPrevious.ToArray() },
                Variants = new VariantData { Labels = variantLabels.ToArray(), Data = variantData.ToArray() },
                VariantDetails = new Dictionary<string, VariantDetailData>()
            };
        }

        private VariantDetailData BuildVariantDetailData(List<Sale> variantSales)
        {
            var now = DateTime.UtcNow.Date;
            variantSales = variantSales ?? new List<Sale>();

            var dailyLabels = new List<string>();
            var dailyCurrent = new List<int>();
            var dailyPrevious = new List<int>();
            for (int i = 6; i >= 0; i--)
            {
                var day = now.AddDays(-i);
                dailyLabels.Add(day.ToString("ddd"));
                dailyCurrent.Add(variantSales.Where(s => s.TransactionDate.Date == day).Sum(s => s.Quantity));
                var prev = day.AddDays(-7);
                dailyPrevious.Add(variantSales.Where(s => s.TransactionDate.Date == prev).Sum(s => s.Quantity));
            }

            var weeklyLabels = new List<string>();
            var weeklyCurrent = new List<int>();
            var weeklyPrevious = new List<int>();
            var weekStartRef = now.AddDays(-(int)now.DayOfWeek);
            for (int i = 3; i >= 0; i--)
            {
                var start = weekStartRef.AddDays(-7 * i);
                var end = start.AddDays(6);
                weeklyLabels.Add($"Week {4 - i}");
                weeklyCurrent.Add(variantSales.Where(s => s.TransactionDate.Date >= start && s.TransactionDate.Date <= end).Sum(s => s.Quantity));
                var prevStart = start.AddDays(-28);
                var prevEnd = prevStart.AddDays(6);
                weeklyPrevious.Add(variantSales.Where(s => s.TransactionDate.Date >= prevStart && s.TransactionDate.Date <= prevEnd).Sum(s => s.Quantity));
            }

            var monthlyLabels = new List<string>();
            var monthlyCurrent = new List<int>();
            var monthlyPrevious = new List<int>();
            for (int i = 2; i >= 0; i--)
            {
                var month = new DateTime(now.Year, now.Month, 1).AddMonths(-i);
                var monthEnd = month.AddMonths(1).AddDays(-1);
                monthlyLabels.Add(month.ToString("MMM"));
                monthlyCurrent.Add(variantSales.Where(s => s.TransactionDate >= month && s.TransactionDate <= monthEnd).Sum(s => s.Quantity));
                var prevYearStart = month.AddYears(-1);
                var prevYearEnd = prevYearStart.AddMonths(1).AddDays(-1);
                monthlyPrevious.Add(variantSales.Where(s => s.TransactionDate >= prevYearStart && s.TransactionDate <= prevYearEnd).Sum(s => s.Quantity));
            }

            return new VariantDetailData
            {
                Daily = new ChartPeriodData { Labels = dailyLabels.ToArray(), Current = dailyCurrent.ToArray(), Previous = dailyPrevious.ToArray() },
                Weekly = new ChartPeriodData { Labels = weeklyLabels.ToArray(), Current = weeklyCurrent.ToArray(), Previous = weeklyPrevious.ToArray() },
                Monthly = new ChartPeriodData { Labels = monthlyLabels.ToArray(), Current = monthlyCurrent.ToArray(), Previous = monthlyPrevious.ToArray() }
            };
        }

        private ChartData BuildEmptyChartData(List<ProductVariant> variants)
        {
            var now = DateTime.UtcNow.Date;

            var dailyLabels = new List<string>();
            for (int i = 6; i >= 0; i--)
            {
                dailyLabels.Add(now.AddDays(-i).ToString("ddd"));
            }

            var weeklyLabels = new[] { "Week 1", "Week 2", "Week 3", "Week 4" };

            var monthlyLabels = new List<string>();
            for (int i = 2; i >= 0; i--)
            {
                monthlyLabels.Add(new DateTime(now.Year, now.Month, 1).AddMonths(-i).ToString("MMM"));
            }

            return new ChartData
            {
                Daily = new ChartPeriodData
                {
                    Labels = dailyLabels.ToArray(),
                    Current = new int[7],
                    Previous = new int[7]
                },
                Weekly = new ChartPeriodData
                {
                    Labels = weeklyLabels,
                    Current = new int[4],
                    Previous = new int[4]
                },
                Monthly = new ChartPeriodData
                {
                    Labels = monthlyLabels.ToArray(),
                    Current = new int[3],
                    Previous = new int[3]
                },
                Variants = new VariantData
                {
                    Labels = new string[0],
                    Data = new int[0]
                },
                VariantDetails = new Dictionary<string, VariantDetailData>()
            };
        }

        private string SerializeChartData(ChartData data)
        {
            var serializer = new JavaScriptSerializer();
            Dictionary<string, object> variantDetailsDict;
            if (data.VariantDetails != null)
            {
                variantDetailsDict = new Dictionary<string, object>();
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
            }
            else
            {
                variantDetailsDict = new Dictionary<string, object>();
            }
            var payload = new
            {
                daily = new { labels = data.Daily.Labels, current = data.Daily.Current, previous = data.Daily.Previous },
                weekly = new { labels = data.Weekly.Labels, current = data.Weekly.Current, previous = data.Weekly.Previous },
                monthly = new { labels = data.Monthly.Labels, current = data.Monthly.Current, previous = data.Monthly.Previous },
                variants = new { labels = data.Variants.Labels, data = data.Variants.Data },
                variantDetails = variantDetailsDict
            };
            return serializer.Serialize(payload);
        }
        #endregion

        #region Utility
        private string GetInitials(string name)
        {
            if (string.IsNullOrWhiteSpace(name)) return string.Empty;
            var parts = name.Trim().Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
            return parts.Length == 1 ? parts[0].Substring(0, 1).ToUpper() : (parts[0][0].ToString() + parts[parts.Length - 1][0]).ToUpper();
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
    }
}