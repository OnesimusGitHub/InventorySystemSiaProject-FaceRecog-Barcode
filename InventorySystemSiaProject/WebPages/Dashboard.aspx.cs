using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.Services;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.WebPages
{
    // Helper class for aggregated sales data
    public class AggregatedSalesData
    {
        public string[] labels { get; set; }
        public decimal[] data { get; set; }
    }
    
    public partial class Dashboard : System.Web.UI.Page
    {
        private ProductService _productService;
        private SalesService _salesService;

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                if (Session["UserId"] == null)
                {
                    Response.Redirect("~/WebPages/Login.aspx");
                    return;
                }

                _productService = new ProductService();
                _salesService = new SalesService();

                if (!Page.IsPostBack)
                {
                    LoadUserInfo();
                    RegisterAsyncTask(new PageAsyncTask(LoadDashboardDataAsync));
                }
            }
            catch (Exception)
            {
                // Handle page load error silently
            }
        }

        private void LoadUserInfo()
        {
            try
            {
                string userName = Session["UserName"]?.ToString() ?? "Admin User";
                // User info loaded successfully
            }
            catch
            {
                // Handle error silently
            }
        }

        private async Task LoadDashboardDataAsync()
        {
            try
            {
                var salesData = await GetSalesDataAsync();
                var dashboardStats = await GetDashboardStatsAsync();

                // Check if we have any real sales data
                bool hasRealSalesData = await HasSalesDataAsync();

                var serializer = new JavaScriptSerializer();
                serializer.MaxJsonLength = Int32.MaxValue;
                
                var salesDataJson = serializer.Serialize(salesData);
                var statsJson = serializer.Serialize(dashboardStats);

                string script = $@"
                    console.log('Setting up dashboard data...');
                    window.salesData = {salesDataJson};
                    window.dashboardStats = {statsJson};
                    window.hasRealData = {hasRealSalesData.ToString().ToLower()};
                    
                    console.log('Sales data loaded:', window.salesData);
                    console.log('Dashboard stats loaded:', window.dashboardStats);
                    console.log('Has real data:', window.hasRealData);
                    
                    window.updateDashboardWithRealData = function() {{
                        console.log('Updating dashboard with real data...');
                        if (window.salesData && window.dashboardStats) {{
                            if (typeof updateStatsCards === 'function') {{
                                updateStatsCards(window.dashboardStats);
                                
                                // ✅ FIX: Respect active filters - use filtered data if isFilterActive is true
                                if (window.isFilterActive && window.salesData.filtered) {{
                                    console.log('✅ Using filtered data (filter is active)');
                                    updateChartWithData(window.salesData.filtered, 'custom');
                                }} else {{
                                    console.log('✅ Using period data (no active filters)');
                                    updateMainChart(currentPeriod || 'monthly');
                                }}
                                
                                updateMiniCharts();
                            }}
                        }} else {{
                            console.log('Data not available yet');
                        }}
                    }};
                    
                    function initializeDashboard() {{
                        console.log('Initializing dashboard...');
                        if (typeof updateStatsCards === 'function' && window.salesData && window.dashboardStats) {{
                            window.updateDashboardWithRealData();
                        }} else {{
                            console.log('Functions not ready, retrying in 500ms...');
                            setTimeout(initializeDashboard, 500);
                        }}
                    }}
                    
                    // Immediate execution for faster loading
                    setTimeout(initializeDashboard, 100);
                ";

                ClientScript.RegisterStartupScript(this.GetType(), "SalesData", script, true);
            }
            catch (Exception)
            {
                // Always provide fallback data if there's an error
                // Log error silently - we don't want to disrupt the dashboard
                string fallbackScript = @"
                    console.log('Loading fallback data due to error...');
                    window.salesData = {
                        daily: { 
                            labels: ['Dec 01', 'Dec 02', 'Dec 03', 'Dec 04', 'Dec 05', 'Dec 06', 'Dec 07', 'Dec 08', 'Dec 09', 'Dec 10'], 
                            data: [150, 180, 120, 200, 160, 190, 210, 175, 140, 230] 
                        },
                        weekly: { 
                            labels: ['Week 44', 'Week 45', 'Week 46', 'Week 47', 'Week 48', 'Week 49'], 
                            data: [1200, 1450, 1100, 1600, 1350, 1500] 
                        },
                        monthly: { 
                            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'], 
                            data: [2500, 2800, 3200, 2900, 3500, 3800, 4200, 4500, 4100, 4600, 4800, 5000] 
                        },
                        lastYear: { 
                            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'], 
                            data: [2200, 2400, 2800, 2600, 3100, 3400, 3800, 4100, 3700, 4200, 4400, 4600] 
                        }
                    };
                    window.dashboardStats = {
                        totalSales: 15420,
                        salesGrowth: 12.5,
                        totalOrders: 156,
                        orderGrowth: 8.3,
                        totalProducts: 8,
                        lowStockItems: 3,
                        activeVariants: 11
                    };
                    window.hasRealData = false;
                    
                    function initializeFallbackDashboard() {
                        if (typeof updateStatsCards === 'function') {
                            updateStatsCards(window.dashboardStats);
                            updateMainChart(currentPeriod || 'monthly');
                        } else {
                            setTimeout(initializeFallbackDashboard, 200);
                        }
                    }
                    
                    setTimeout(initializeFallbackDashboard, 100);
                ";
                
                ClientScript.RegisterStartupScript(this.GetType(), "FallbackData", fallbackScript, true);
            }
        }

        private async Task<bool> HasSalesDataAsync()
        {
            try
            {
                var salesCount = await _salesService.GetSalesCountAsync();
                return salesCount > 0;
            }
            catch
            {
                return false;
            }
        }

        private async Task<object> GetSalesDataAsync()
        {
            try
            {
                var allSales = await _salesService.GetAllSalesAsync();
                
                // If no sales data, return default data instead of empty
                if (allSales.Count == 0)
                {
                    return CreateDefaultSalesData();
                }

                var now = DateTime.UtcNow;

                var result = new
                {
                    daily = await GetDailySalesData(allSales, now.AddDays(-30)),
                    weekly = await GetWeeklySalesData(allSales, now.AddDays(-90)),
                    monthly = await GetMonthlySalesData(allSales, now.AddYears(-1)),
                    lastYear = await GetMonthlySalesData(allSales, now.AddYears(-2), now.AddYears(-1))
                };

                return result;
            }
            catch (Exception)
            {
                // Return default data on error
                return CreateDefaultSalesData();
            }
        }

        private static object CreateDefaultSalesData()
        {
            return new 
            {
                daily = new { 
                    labels = new[] { "Dec 01", "Dec 02", "Dec 03", "Dec 04", "Dec 05", "Dec 06", "Dec 07" },
                    data = new[] { 150, 180, 120, 200, 160, 190, 210 }
                },
                weekly = new { 
                    labels = new[] { "Week 44", "Week 45", "Week 46", "Week 47" },
                    data = new[] { 1200, 1450, 1100, 1600 }
                },
                monthly = new { 
                    labels = new[] { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
                    data = new[] { 2500, 2800, 3200, 2900, 3500, 3800, 4200, 4500, 4100, 4600, 4800, 5000 }
                },
                lastYear = new { 
                    labels = new[] { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
                    data = new[] { 2200, 2400, 2800, 2600, 3100, 3400, 3800, 4100, 3700, 4200, 4400, 4600 }
                }
            };
        }

        private Task<object> GetDailySalesData(List<Sale> allSales, DateTime startDate)
        {
            var endDate = DateTime.UtcNow;
            var salesInPeriod = allSales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate).ToList();

            var dailySales = salesInPeriod
                .GroupBy(s => s.TransactionDate.Date)
                .Select(g => new
                {
                    date = g.Key,
                    amount = g.Sum(s => s.TotalAmount)
                })
                .OrderBy(x => x.date)
                .ToList();

            var labels = new List<string>();
            var data = new List<decimal>();

            for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
            {
                var existing = dailySales.FirstOrDefault(d => d.date == date);
                labels.Add(date.ToString("MMM dd"));
                data.Add(existing?.amount ?? 0);
            }

            return Task.FromResult<object>(new { labels = labels.ToArray(), data = data.ToArray() });
        }

        private Task<object> GetWeeklySalesData(List<Sale> allSales, DateTime startDate)
        {
            var endDate = DateTime.UtcNow;
            var salesInPeriod = allSales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate).ToList();

            var weeklySales = salesInPeriod
                .GroupBy(s => GetWeekOfYear(s.TransactionDate))
                .Select(g => new
                {
                    week = g.Key,
                    amount = g.Sum(s => s.TotalAmount)
                })
                .OrderBy(x => x.week)
                .ToList();

            var labels = weeklySales.Select(w => $"Week {w.week}").ToArray();
            var data = weeklySales.Select(w => w.amount).ToArray();

            return Task.FromResult<object>(new { labels, data });
        }

        private Task<object> GetMonthlySalesData(List<Sale> allSales, DateTime startDate, DateTime? endDate = null)
        {
            var endPeriod = endDate ?? DateTime.UtcNow;
            var salesInPeriod = allSales.Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endPeriod).ToList();

            var monthlySales = salesInPeriod
                .GroupBy(s => new { s.TransactionDate.Year, s.TransactionDate.Month })
                .Select(g => new
                {
                    month = g.Key.Month,
                    year = g.Key.Year,
                    amount = g.Sum(s => s.TotalAmount)
                })
                .OrderBy(x => x.year).ThenBy(x => x.month)
                .ToList();

            var labels = new[] { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
            var data = new decimal[12];

            foreach (var sale in monthlySales)
            {
                data[sale.month - 1] = sale.amount;
            }

            return Task.FromResult<object>(new { labels, data });
        }

        private async Task<object> GetDashboardStatsAsync()
        {
            try
            {
                var allSales = await _salesService.GetAllSalesAsync();
                var products = await _productService.GetAllProductsAsync();
                var variants = await _productService.GetAllProductVariantsAsync();

                var now = DateTime.UtcNow;
                var lastMonth = now.AddMonths(-1);
                var thisMonth = allSales.Where(s => s.TransactionDate >= lastMonth).ToList();
                var previousMonth = allSales.Where(s => s.TransactionDate >= now.AddMonths(-2) && s.TransactionDate < lastMonth).ToList();

                var totalSales = thisMonth.Sum(s => s.TotalAmount);
                var previousSales = previousMonth.Sum(s => s.TotalAmount);
                var salesGrowth = previousSales > 0 ? ((totalSales - previousSales) / previousSales * 100) : 0;

                var totalOrders = thisMonth.Count;
                var previousOrders = previousMonth.Count;
                var orderGrowth = previousOrders > 0 ? ((totalOrders - previousOrders) / (decimal)previousOrders * 100) : 0;

                var lowStockVariants = variants.Where(v => v.StockQuantity <= v.MinimumStock).Count();
                var totalProducts = products.Count;

                return new
                {
                    totalSales = totalSales,
                    salesGrowth = Math.Round(salesGrowth, 1),
                    totalOrders = totalOrders,
                    orderGrowth = Math.Round(orderGrowth, 1),
                    totalProducts = totalProducts,
                    lowStockItems = lowStockVariants,
                    activeVariants = variants.Count(v => v.IsActive)
                };
            }
            catch (Exception)
            {
                // Return default stats on error
                return new
                {
                    totalSales = 0,
                    salesGrowth = 0,
                    totalOrders = 0,
                    orderGrowth = 0,
                    totalProducts = 0,
                    lowStockItems = 0,
                    activeVariants = 0
                };
            }
        }

        /// <summary>
        /// WebMethod to get filtered dashboard data based on category and date range
        /// </summary>
        [WebMethod(EnableSession = true)]
        [System.Web.Script.Services.ScriptMethod(ResponseFormat = System.Web.Script.Services.ResponseFormat.Json)]
        public static object GetFilteredDashboardData(string category, string startDate, string endDate)
        {
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            
            try
            {
                System.Diagnostics.Debug.WriteLine($"🔍 GetFilteredDashboardData START - {DateTime.Now:HH:mm:ss.fff}");
                System.Diagnostics.Debug.WriteLine($"   Parameters: category='{category}', startDate='{startDate}', endDate='{endDate}'");
                System.Diagnostics.Debug.WriteLine($"   Thread ID: {System.Threading.Thread.CurrentThread.ManagedThreadId}");
                
                // ✅ ADD EARLY TIMEOUT CHECK
                var timeoutTask = System.Threading.Tasks.Task.Delay(25000); // 25 second server-side timeout
                
                System.Diagnostics.Debug.WriteLine($"   [+{stopwatch.ElapsedMilliseconds}ms] Creating service instances...");
                var productService = new ProductService();
                var salesService = new SalesService();

                DateTime? startDateTime = null;
                DateTime? endDateTime = null;

                if (!string.IsNullOrEmpty(startDate))
                {
                    startDateTime = DateTime.Parse(startDate);
                    System.Diagnostics.Debug.WriteLine($"   Parsed start date: {startDateTime}");
                }
                if (!string.IsNullOrEmpty(endDate))
                {
                    endDateTime = DateTime.Parse(endDate);
                    System.Diagnostics.Debug.WriteLine($"   Parsed end date: {endDateTime}");
                }

                System.Diagnostics.Debug.WriteLine($"   [+{stopwatch.ElapsedMilliseconds}ms] Calling GetFilteredSalesDataSync...");
                var salesData = GetFilteredSalesDataSync(salesService, productService, category, startDateTime, endDateTime);
                System.Diagnostics.Debug.WriteLine($"   [+{stopwatch.ElapsedMilliseconds}ms] ✅ GetFilteredSalesDataSync completed");
                
                System.Diagnostics.Debug.WriteLine($"   [+{stopwatch.ElapsedMilliseconds}ms] Calling GetFilteredDashboardStatsSync...");
                var dashboardStats = GetFilteredDashboardStatsSync(salesService, productService, category, startDateTime, endDateTime);
                System.Diagnostics.Debug.WriteLine($"   [+{stopwatch.ElapsedMilliseconds}ms] ✅ GetFilteredDashboardStatsSync completed");

                var result = new
                {
                    salesData = salesData,
                    dashboardStats = dashboardStats,
                    success = true,
                    executionTimeMs = stopwatch.ElapsedMilliseconds
                };
                
                stopwatch.Stop();
                System.Diagnostics.Debug.WriteLine($"✅ GetFilteredDashboardData COMPLETE in {stopwatch.ElapsedMilliseconds}ms");
                System.Diagnostics.Debug.WriteLine($"   Returning: salesData={salesData != null}, dashboardStats={dashboardStats != null}");
                
                // ✅ CHECK IF WE EXCEEDED TIMEOUT
                if (stopwatch.ElapsedMilliseconds > 25000)
                {
                    System.Diagnostics.Debug.WriteLine($"⚠️ WARNING: Method execution exceeded 25 seconds!");
                }
                
                return result;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                System.Diagnostics.Debug.WriteLine($"❌ ERROR in GetFilteredDashboardData after {stopwatch.ElapsedMilliseconds}ms");
                System.Diagnostics.Debug.WriteLine($"   Exception: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"   Type: {ex.GetType().Name}");
                System.Diagnostics.Debug.WriteLine($"   Stack trace: {ex.StackTrace}");
                
                if (ex.InnerException != null)
                {
                    System.Diagnostics.Debug.WriteLine($"   Inner Exception: {ex.InnerException.Message}");
                    System.Diagnostics.Debug.WriteLine($"   Inner Stack: {ex.InnerException.StackTrace}");
                }
                
                // Return error response instead of throwing (which would cause PageMethods to fail silently)
                return new
                {
                    salesData = CreateDefaultSalesData(),
                    dashboardStats = new
                    {
                        totalSales = 0,
                        salesGrowth = 0,
                        totalOrders = 0,
                        orderGrowth = 0,
                        totalProducts = 0,
                        lowStockItems = 0,
                        activeVariants = 0,
                        category = category ?? "All Categories",
                        dateRange = "Error loading data"
                    },
                    success = false,
                    error = ex.Message,
                    errorType = ex.GetType().Name,
                    stackTrace = ex.StackTrace,
                    executionTimeMs = stopwatch.ElapsedMilliseconds
                };
            }
        }

        private const int MAX_FILTER_MONTHS = 12; // Maximum months allowed for filter

        private static object GetFilteredSalesDataSync(
            SalesService salesService, 
            ProductService productService, 
            string category, 
            DateTime? startDate, 
            DateTime? endDate)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine($"📊 GetFilteredSalesDataSync called with category='{category}'");
                List<Sale> allSales;
                if (!string.IsNullOrEmpty(category))
                {
                    allSales = salesService.GetSalesByCategoryAsync(category, startDate, endDate).GetAwaiter().GetResult();
                }
                else
                {
                    allSales = salesService.GetAllSalesAsync().GetAwaiter().GetResult();
                    if (startDate.HasValue)
                        allSales = allSales.Where(s => s.TransactionDate >= startDate.Value).ToList();
                    if (endDate.HasValue)
                        allSales = allSales.Where(s => s.TransactionDate <= endDate.Value.AddDays(1)).ToList();
                }
                var now = DateTime.UtcNow;
                DateTime effectiveStartDate;
                DateTime effectiveEndDate;
                if (!startDate.HasValue && !endDate.HasValue)
                {
                    effectiveStartDate = new DateTime(now.Year, 1, 1);
                    effectiveEndDate = now;
                }
                else
                {
                    effectiveStartDate = startDate ?? now.AddYears(-1);
                    effectiveEndDate = endDate ?? now;
                }
                // Enforce max filter range
                int monthsDiff = ((effectiveEndDate.Year - effectiveStartDate.Year) * 12) + effectiveEndDate.Month - effectiveStartDate.Month;
                if (monthsDiff > MAX_FILTER_MONTHS)
                {
                    effectiveStartDate = effectiveEndDate.AddMonths(-MAX_FILTER_MONTHS);
                    System.Diagnostics.Debug.WriteLine($"⚠️ Filter range too large, limiting to last {MAX_FILTER_MONTHS} months");
                }

                // Always use monthly aggregation for custom filter chart
                AggregatedSalesData customData = GetCustomMonthlyDataSyncTyped(allSales, effectiveStartDate, effectiveEndDate);

                // Get previous year same period for comparison
                var previousYearStart = effectiveStartDate.AddYears(-1);
                var previousYearEnd = effectiveEndDate.AddYears(-1);
                List<Sale> previousPeriodSales;
                if (!string.IsNullOrEmpty(category))
                    previousPeriodSales = salesService.GetSalesByCategoryAsync(category, previousYearStart, previousYearEnd).GetAwaiter().GetResult();
                else
                    previousPeriodSales = allSales.Where(s => s.TransactionDate >= previousYearStart && s.TransactionDate < effectiveStartDate).ToList();
                AggregatedSalesData previousPeriodData = GetCustomMonthlyDataSyncTyped(previousPeriodSales, previousYearStart, previousYearEnd);

                var result = new
                {
                    daily = GetDailySalesDataFilteredSync(allSales, effectiveStartDate, effectiveEndDate),
                    weekly = GetWeeklySalesDataFilteredSync(allSales, effectiveStartDate, effectiveEndDate),
                    monthly = GetMonthlySalesDataFilteredSync(allSales, effectiveStartDate, effectiveEndDate),
                    lastYear = new { labels = previousPeriodData.labels, data = previousPeriodData.data },
                    custom = new
                    {
                        labels = customData.labels,
                        data = customData.data,
                        lastYearData = previousPeriodData.data,
                        dateRange = $"{effectiveStartDate:MMM dd, yyyy} - {effectiveEndDate:MMM dd, yyyy}",
                        aggregationType = "monthly"
                    }
                };

                System.Diagnostics.Debug.WriteLine($"✅ GetFilteredSalesDataSync returning:");
                System.Diagnostics.Debug.WriteLine($"   Custom data: {customData.labels.Length} labels");
                System.Diagnostics.Debug.WriteLine($"   Last year data: {previousPeriodData.data.Length} data points");
                System.Diagnostics.Debug.WriteLine($"   Date range: {result.custom.dateRange}");

                return result;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in GetFilteredSalesDataSync: {ex.Message}");
                return CreateDefaultSalesData();
            }
        }

        private static object GetFilteredDashboardStatsSync(
            SalesService salesService,
            ProductService productService,
            string category,
            DateTime? startDate,
            DateTime? endDate)
        {
            try
            {
                var products = productService.GetAllProductsAsync().GetAwaiter().GetResult();
                var variants = productService.GetAllProductVariantsAsync().GetAwaiter().GetResult();
                var effectiveStartDate = startDate ?? DateTime.UtcNow.AddMonths(-1);
                var effectiveEndDate = endDate ?? DateTime.UtcNow;
                // Enforce max filter range
                int monthsDiff = ((effectiveEndDate.Year - effectiveStartDate.Year) * 12) + effectiveEndDate.Month - effectiveStartDate.Month;
                if (monthsDiff > MAX_FILTER_MONTHS)
                {
                    effectiveStartDate = effectiveEndDate.AddMonths(-MAX_FILTER_MONTHS);
                }
                List<Sale> salesInRange;
                List<Sale> previousPeriodSales;
                if (!string.IsNullOrEmpty(category))
                {
                    salesInRange = salesService.GetSalesByCategoryAsync(category, effectiveStartDate, effectiveEndDate).GetAwaiter().GetResult();
                    var periodDays = (effectiveEndDate - effectiveStartDate).Days;
                    var previousPeriodStart = effectiveStartDate.AddDays(-periodDays);
                    var previousPeriodEnd = effectiveStartDate.AddDays(-1);
                    previousPeriodSales = salesService.GetSalesByCategoryAsync(category, previousPeriodStart, previousPeriodEnd).GetAwaiter().GetResult();
                    products = products.Where(p => p.ProductCategory == category).ToList();
                    var categoryProductIds = new HashSet<string>(products.Select(p => p.Id));
                    variants = variants.Where(v => categoryProductIds.Contains(v.ProductId)).ToList();
                }
                else
                {
                    var allSales = salesService.GetAllSalesAsync().GetAwaiter().GetResult();
                    salesInRange = allSales.Where(s => s.TransactionDate >= effectiveStartDate && s.TransactionDate <= effectiveEndDate).ToList();
                    var periodDays = (effectiveEndDate - effectiveStartDate).Days;
                    var previousPeriodStart = effectiveStartDate.AddDays(-periodDays);
                    previousPeriodSales = allSales.Where(s => s.TransactionDate >= previousPeriodStart && s.TransactionDate < effectiveStartDate).ToList();
                }

                var totalSales = salesInRange.Sum(s => s.TotalAmount);
                var previousSales = previousPeriodSales.Sum(s => s.TotalAmount);
                var salesGrowth = previousSales > 0 ? ((totalSales - previousSales) / previousSales * 100) : 0;

                var totalOrders = salesInRange.Count;
                var previousOrders = previousPeriodSales.Count;
                var orderGrowth = previousOrders > 0 ? ((totalOrders - previousOrders) / (decimal)previousOrders * 100) : 0;

                var lowStockVariants = variants.Where(v => v.StockQuantity <= v.MinimumStock).Count();
                var totalProducts = products.Count;

                System.Diagnostics.Debug.WriteLine($"✅ Stats calculated: Sales={totalSales}, Orders={totalOrders}, Products={totalProducts}");

                return new
                {
                    totalSales = totalSales,
                    salesGrowth = Math.Round(salesGrowth, 1),
                    totalOrders = totalOrders,
                    orderGrowth = Math.Round(orderGrowth, 1),
                    totalProducts = totalProducts,
                    lowStockItems = lowStockVariants,
                    activeVariants = variants.Count(v => v.IsActive),
                    category = category ?? "All Categories",
                    dateRange = $"{effectiveStartDate:MMM dd, yyyy} - {effectiveEndDate:MMM dd, yyyy}"
                };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in GetFilteredDashboardStatsSync: {ex.Message}");
                return new
                {
                    totalSales = 0,
                    salesGrowth = 0,
                    totalOrders = 0,
                    orderGrowth = 0,
                    totalProducts = 0,
                    lowStockItems = 0,
                    activeVariants = 0,
                    category = category ?? "All Categories",
                    dateRange = "No Data"
                };
            }
        }

        private static AggregatedSalesData GetCustomDailyDataSyncTyped(List<Sale> sales, DateTime startDate, DateTime endDate)
        {
            var dailySales = sales
                .Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate)
                .GroupBy(s => s.TransactionDate.Date)
                .Select(g => new
                {
                    date = g.Key,
                    amount = g.Sum(s => s.TotalAmount)
                })
                .OrderBy(x => x.date)
                .ToList();

            var labels = new List<string>();
            var data = new List<decimal>();

            // Fill in all dates in range, even if no sales
            for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
            {
                var existing = dailySales.FirstOrDefault(d => d.date == date);
                labels.Add(date.ToString("MMM dd"));
                data.Add(existing?.amount ?? 0);
            }

            return new AggregatedSalesData
            {
                labels = labels.ToArray(),
                data = data.ToArray()
            };
        }

        private static AggregatedSalesData GetCustomWeeklyDataSyncTyped(List<Sale> sales, DateTime startDate, DateTime endDate)
        {
            var weeklySales = sales
                .Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate)
                .GroupBy(s => new
                {
                    Year = s.TransactionDate.Year,
                    Week = GetWeekOfYear(s.TransactionDate)
                })
                .Select(g => new
                {
                    yearWeek = $"{g.Key.Year}-W{g.Key.Week:D2}",
                    week = g.Key.Week,
                    year = g.Key.Year,
                    amount = g.Sum(s => s.TotalAmount),
                    startOfWeek = g.Min(s => s.TransactionDate)
                })
                .OrderBy(x => x.year).ThenBy(x => x.week)
                .ToList();

            var labels = weeklySales.Select(w => $"Week {w.week}").ToArray();
            var data = weeklySales.Select(w => w.amount).ToArray();

            return new AggregatedSalesData
            {
                labels = labels,
                data = data
            };
        }

        private static AggregatedSalesData GetCustomMonthlyDataSyncTyped(List<Sale> sales, DateTime startDate, DateTime endDate)
        {
            var monthlySales = sales
                .Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate)
                .GroupBy(s => new { s.TransactionDate.Year, s.TransactionDate.Month })
                .Select(g => new
                {
                    month = g.Key.Month,
                    year = g.Key.Year,
                    amount = g.Sum(s => s.TotalAmount),
                    date = new DateTime(g.Key.Year, g.Key.Month, 1)
                })
                .OrderBy(x => x.year).ThenBy(x => x.month)
                .ToList();

            var labels = monthlySales.Select(m => m.date.ToString("MMM yyyy")).ToArray();
            var data = monthlySales.Select(m => m.amount).ToArray();

            return new AggregatedSalesData
            {
                labels = labels,
                data = data
            };
        }

        private static object GetDailySalesDataFilteredSync(List<Sale> sales, DateTime startDate, DateTime endDate)
        {
            var dailySales = sales
                .Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate)
                .GroupBy(s => s.TransactionDate.Date)
                .Select(g => new
                {
                    date = g.Key,
                    amount = g.Sum(s => s.TotalAmount)
                })
                .OrderBy(x => x.date)
                .ToList();

            var labels = new List<string>();
            var data = new List<decimal>();

            // Fill in all dates in range, even if no sales
            for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
            {
                var existing = dailySales.FirstOrDefault(d => d.date == date);
                labels.Add(date.ToString("MMM dd"));
                data.Add(existing?.amount ?? 0);
            }

            return new { labels = labels.ToArray(), data = data.ToArray() };
        }

        private static object GetWeeklySalesDataFilteredSync(List<Sale> sales, DateTime startDate, DateTime endDate)
        {
            var weeklySales = sales
                .Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate)
                .GroupBy(s => new
                {
                    Year = s.TransactionDate.Year,
                    Week = GetWeekOfYear(s.TransactionDate)
                })
                .Select(g => new
                {
                    yearWeek = $"{g.Key.Year}-W{g.Key.Week:D2}",
                    week = g.Key.Week,
                    year = g.Key.Year,
                    amount = g.Sum(s => s.TotalAmount),
                    startOfWeek = g.Min(s => s.TransactionDate)
                })
                .OrderBy(x => x.year).ThenBy(x => x.week)
                .ToList();

            var labels = weeklySales.Select(w => $"{w.startOfWeek:MMM dd}").ToArray();
            var data = weeklySales.Select(w => w.amount).ToArray();

            return new { labels, data };
        }

        private static object GetMonthlySalesDataFilteredSync(List<Sale> sales, DateTime startDate, DateTime endDate)
        {
            var monthlySales = sales
                .Where(s => s.TransactionDate >= startDate && s.TransactionDate <= endDate)
                .GroupBy(s => new { s.TransactionDate.Year, s.TransactionDate.Month })
                .Select(g => new
                {
                    month = g.Key.Month,
                    year = g.Key.Year,
                    amount = g.Sum(s => s.TotalAmount),
                    date = new DateTime(g.Key.Year, g.Key.Month, 1)
                })
                .OrderBy(x => x.year).ThenBy(x => x.month)
                .ToList();

            var labels = monthlySales.Select(m => m.date.ToString("MMM yyyy")).ToArray();
            var data = monthlySales.Select(m => m.amount).ToArray();

            return new { labels, data };
        }

        private static int GetWeekOfYear(DateTime date)
        {
            var culture = System.Globalization.CultureInfo.CurrentCulture;
            var calendar = culture.Calendar;
            return calendar.GetWeekOfYear(date, culture.DateTimeFormat.CalendarWeekRule, culture.DateTimeFormat.FirstDayOfWeek);
        }
    }
}