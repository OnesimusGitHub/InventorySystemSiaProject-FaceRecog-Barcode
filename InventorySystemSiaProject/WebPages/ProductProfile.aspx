<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="ProductProfile.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductProfile" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Product Profile</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href="../Content/productprofile.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        /* Charts section styling - Updated to match Dashboard styling */
        .charts {
            overflow: hidden;
            clear: both;
            margin: 20px auto;
            max-width: 1200px;
            padding: 0 20px;
        }
        
        /* Sales Analytics header layout fix */
        .charts .section-title {
            margin-bottom: 24px;
            clear: both;
            font-size: 24px;
            font-weight: 600;
            color: #333;
            text-align: center;
        }
        
        /* Main chart container to match Dashboard */
        .chart-container { 
            width: 100%; 
            background: white;
            border: none;
            border-radius: 15px;
            position: relative; 
            margin: 16px 0; 
            display: block !important; 
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .chart-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
            position: relative;
        }
        
        .chart-title-section {
            flex: 1;
        }
        
        .chart-title { 
            font-size: 1.2rem; 
            font-weight: 600; 
            color: #333; 
            margin: 0 0 8px 0;
        }
        
        .chart-period-change {
            font-size: 1.1rem;
            color: #4CAF50;
            font-weight: 500;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .chart-period-change.negative {
            color: #f44336;
        }
        
        .chart-canvas {
            position: relative;
            height: 300px;
            width: 100%;
            margin-bottom: 1rem;
        }
        
        .chart-legend {
            display: flex;
            gap: 2rem;
            justify-content: center;
            margin-top: 1rem;
            font-size: 0.9rem;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .legend-color {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }
        
        .variant-chart { 
            height: auto;
            padding: 2rem;
        }
        
        .variant-chart .chart-canvas { 
            height: 250px; 
        }

        /* Pills style for timeframe toggle buttons - Match Dashboard */
        .chart-period-selector {
            display: flex;
            background: #333;
            border-radius: 25px;
            overflow: hidden;
            gap: 0;
            padding: 0;
            width: fit-content;
            position: absolute;
            top: 0;
            right: 0;
        }
        
        .period-btn {
            background: transparent;
            color: white;
            border: none;
            border-radius: 0;
            padding: 0.5rem 1rem;
            font-size: 0.85rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            white-space: nowrap;
            user-select: none;
            -webkit-user-select: none;
            -moz-user-select: none;
        }
        
        .period-btn:hover:not(.active) {
            background: rgba(255,255,255,0.1);
        }
        
        .period-btn.active {
            background: #666;
        }
        
        .period-btn:active {
            transform: none;
        }
        
        .period-btn:focus {
            outline: none;
        }
        
        /* Debug info styling */
        #debugInfo { 
            background: #f0f0f0; 
            padding: 4px 8px; 
            border-radius: 3px; 
            font-family: monospace; 
            font-size: 10px;
            display: none;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:HiddenField ID="hfSupplier" runat="server" />
        
        <!-- Hidden fields to store chart data -->
        <asp:HiddenField ID="hfChartData" runat="server" />

        <div class="page">
            <div class="product-profile">
                <!-- Left: Gallery -->
                <section class="gallery">
                    <div class="main-image">
                        <asp:Image ID="mainImage" runat="server" ClientIDMode="Static" AlternateText="Product image" CssClass="mainImage" />
                    </div>
                    <div class="thumbs" id="thumbs">
                        <asp:PlaceHolder ID="phThumbs" runat="server" />
                    </div>
                    <div class="share-fav">
                        <div class="share">Share: <a href="#">FB</a> <a href="#">TW</a> <a href="#">Share</a></div>
                        <button type="button" class="favorite">❤ Favorite</button>
                    </div>
                </section>

                <!-- Right: Info -->
                <section class="info">
                    <h1 class="title"><asp:Literal ID="litTitle" runat="server" /></h1>

                    <div class="supplier-banner"><span class="cap">Supplier:</span><span id="supplierBannerSpan"><asp:Literal ID="litSupplierBanner" runat="server" /></span></div>

                    <div class="rating-row">
                        <span class="rating">4.9 ★</span>
                        <span class="divider">|</span>
                        <span class="reviews">530 Ratings</span>
                        <span class="divider">|</span>
                        <span class="sold">5K+ Sold</span>
                    </div>

                    <div class="price-box">
                        <div class="price-current"><asp:Literal ID="litPrice" runat="server" /></div>
                        <div class="price-old">₱167 - ₱269</div>
                        <div class="price-off">-37%</div>
                    </div>

                    <div class="row">
                        <div class="label">Variation</div>
                        <div class="value options">
                            <asp:PlaceHolder ID="phVariants" runat="server" />
                        </div>
                    </div>

                    <div class="row stock-row">
                        <div class="label">Overall Stocks</div>
                        <div class="value">
                            <span class="stock-count"><asp:Literal ID="litOverallStock" runat="server" /></span>
                            <span class="stock-status"><asp:Literal ID="litStock" runat="server" /></span>
                        </div>
                    </div>

                    <div class="actions">
                        <button type="button" class="btn add">Add To Cart</button>
                        <button type="button" class="btn buy">Buy Now</button>
                    </div>
                </section>
            </div>

            <!-- Seller panel -->
            <section class="seller">
                <div class="seller-avatar" id="sellerAvatar"><asp:Literal ID="litSupplierInitials" runat="server" /></div>
                <div class="seller-meta">
                    <div class="seller-name" id="sellerNameDiv"><asp:Literal ID="litSupplierName" runat="server" /></div>
                </div>
                <div class="seller-actions">
                    <button type="button" class="btn chat">Chat Now</button>
                    <button type="button" class="btn visit">View Shop</button>
                </div>
            </section>

            <!-- Charts Section - Moved below supplier section -->
            <div class="charts">
                <h2 class="section-title">Sales Analytics</h2>
                
                <!-- Main Sales Chart -->
                <div class="chart-container">
                    <div class="chart-header">
                        <div class="chart-title-section">
                            <h3 class="chart-title">Sales Overview</h3>
                            <div class="chart-period-change" id="growthIndicator">
                                <i class="fas fa-arrow-up"></i> <span id="growthPercentage">Loading...</span> vs last period
                            </div>
                        </div>
                        <div class="chart-period-selector">
                            <button class="period-btn active" data-period="daily">Daily</button>
                            <button class="period-btn" data-period="weekly">Weekly</button>
                            <button class="period-btn" data-period="monthly">Monthly</button>
                        </div>
                    </div>
                    <div class="chart-canvas">
                        <canvas id="salesChart"></canvas>
                    </div>
                    <div class="chart-legend">
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #4CAF50;"></div>
                            <span>Last Year</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #2196F3;"></div>
                            <span>Current Period</span>
                        </div>
                    </div>
                </div>

                <!-- Variant Sales Chart -->
                <div class="chart-container variant-chart">
                    <div class="chart-header">
                        <div class="chart-title-section">
                            <h3 class="chart-title">Sales by Variant</h3>
                            <div class="chart-period-change" id="variantGrowthIndicator">
                                <i class="fas fa-chart-bar"></i> <span>Product variants breakdown</span>
                            </div>
                        </div>
                    </div>
                    <div class="chart-canvas">
                        <canvas id="variantChart"></canvas>
                    </div>
                </div>
                
                <!-- Debug info -->
                <div id="debugInfo">
                    Debug: Charts loaded = <span id="debugChartCount">0</span>
                </div>
            </div>
        </div>
    </form>

    <script type="text/javascript">
        let salesChartInstance = null;
        let variantChartInstance = null;
        let currentPeriod = 'daily';
        let chartData = null;

        document.addEventListener('DOMContentLoaded', function() {
            console.log('ProductProfile loading...');
            
            // Load chart data from server
            loadChartData();
            
            // Setup period selectors
            setupPeriodSelectors();
            
            // Initialize charts after data is loaded
            setTimeout(initializeCharts, 100);
        });

        function loadChartData() {
            try {
                const hfChartData = document.getElementById('<%= hfChartData.ClientID %>');
                if (hfChartData && hfChartData.value) {
                    chartData = JSON.parse(hfChartData.value);
                    console.log('Chart data loaded:', chartData);
                } else {
                    console.warn('No chart data available, using fallback');
                    chartData = getFallbackData();
                }
            } catch (error) {
                console.error('Error loading chart data:', error);
                chartData = getFallbackData();
            }
        }

        function getFallbackData() {
            return {
                daily: {
                    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    current: [5, 8, 6, 12, 15, 9, 7],
                    previous: [4, 6, 5, 9, 11, 7, 5]
                },
                weekly: {
                    labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
                    current: [45, 52, 38, 61],
                    previous: [38, 44, 32, 48]
                },
                monthly: {
                    labels: ['Jan', 'Feb', 'Mar'],
                    current: [180, 220, 195],
                    previous: [165, 190, 175]
                },
                variants: {
                    labels: ['Standard', 'Premium', 'Deluxe'],
                    data: [45, 30, 25]
                }
            };
        }

        // Normalize chartData in case server sent PascalCase keys (backward compatibility)
        function normalizeChartDataStructure() {
            if (!chartData) return;
            function normPeriod(periodObj) {
                if (!periodObj) return { labels: [], current: [], previous: [] };
                return {
                    labels: periodObj.labels || periodObj.Labels || [],
                    current: periodObj.current || periodObj.Current || [],
                    previous: periodObj.previous || periodObj.Previous || []
                };
            }
            chartData.daily = normPeriod(chartData.daily);
            chartData.weekly = normPeriod(chartData.weekly);
            chartData.monthly = normPeriod(chartData.monthly);
            var v = chartData.variants || {};
            chartData.variants = {
                labels: v.labels || v.Labels || [],
                data: v.data || v.Data || []
            };
        }

        function initializeCharts() {
            if (!chartData) {
                console.error('No chart data available for initialization');
                return;
            }
            normalizeChartDataStructure();

            // Auto-select a period that actually has data (>0) if daily is all zeros
            if (currentPeriod === 'daily' && isAllZero(chartData.daily.current) && !isAllZero(chartData.weekly.current)) {
                currentPeriod = 'weekly';
                document.querySelectorAll('.period-btn').forEach(b=>b.classList.remove('active'));
                const btn = document.querySelector('.period-btn[data-period="weekly"]');
                if (btn) btn.classList.add('active');
            }
            if (currentPeriod === 'daily' && isAllZero(chartData.daily.current) && isAllZero(chartData.weekly.current) && !isAllZero(chartData.monthly.current)) {
                currentPeriod = 'monthly';
                document.querySelectorAll('.period-btn').forEach(b=>b.classList.remove('active'));
                const btn2 = document.querySelector('.period-btn[data-period="monthly"]');
                if (btn2) btn2.classList.add('active');
            }

            initializeSalesChart();
            initializeVariantChart();
            updateGrowthIndicator();
            document.getElementById('debugChartCount').textContent = '2';
        }

        function isAllZero(arr) {
            if (!arr || !arr.length) return true;
            for (var i=0;i<arr.length;i++) if (Number(arr[i]) !== 0) return false; return true;
        }

        function initializeSalesChart() {
            const ctx = document.getElementById('salesChart');
            if (!ctx) {
                console.error('Sales chart canvas not found');
                return;
            }

            const data = chartData[currentPeriod];
            if (!data) {
                console.error('No data for period:', currentPeriod);
                return;
            }

            if (salesChartInstance) {
                salesChartInstance.destroy();
            }

            salesChartInstance = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: 'Last Year',
                        data: data.previous,
                        borderColor: '#4CAF50',
                        backgroundColor: 'rgba(76, 175, 80, 0.1)',
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: '#4CAF50',
                        pointBorderColor: '#ffffff',
                        pointBorderWidth: 2,
                        pointRadius: 4,
                        pointHoverRadius: 6
                    }, {
                        label: 'Current Period',
                        data: data.current,
                        borderColor: '#2196F3',
                        backgroundColor: 'rgba(33, 150, 243, 0.1)',
                        tension: 0.4,
                        fill: true,
                        pointBackgroundColor: '#2196F3',
                        pointBorderColor: '#ffffff',
                        pointBorderWidth: 2,
                        pointRadius: 4,
                        pointHoverRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: {
                        intersect: false,
                        mode: 'index'
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            grid: {
                                color: '#f0f0f0'
                            },
                            ticks: {
                                callback: function(value) {
                                    return formatNumber(value);
                                }
                            }
                        },
                        x: {
                            grid: {
                                display: false
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return context.dataset.label + ': ' + formatNumber(context.parsed.y);
                                }
                            }
                        }
                    }
                }
            });
        }

        function initializeVariantChart() {
            const canvas = document.getElementById('variantChart');
            if (!canvas) { console.error('Variant chart canvas not found'); return; }

            const vDataRaw = chartData && chartData.variants ? chartData.variants : null;
            const labels = vDataRaw ? (vDataRaw.labels || []) : [];
            const dataVals = vDataRaw ? (vDataRaw.data || []) : [];

            if (!labels.length || !dataVals.length) {
                console.warn('Variant chart fallback data used');
                return;
            }

            if (variantChartInstance) {
                try { variantChartInstance.destroy(); } catch (e) { console.warn('Destroy variant chart failed', e); }
            }

            try {
                variantChartInstance = new Chart(canvas.getContext('2d'), {
                    type: 'doughnut',
                    data: {
                        labels: labels,
                        datasets: [{
                            data: dataVals,
                            backgroundColor: ['#2196F3','#4CAF50','#FF9800','#9C27B0','#F44336','#607D8B'],
                            borderWidth: 0,
                            hoverOffset: 4
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        cutout: '60%',
                        plugins: {
                            legend: { position: 'bottom', labels: { usePointStyle: true, padding: 16 } },
                            tooltip: { callbacks: { label: function(ctx){ const label = ctx.label || ''; const value = ctx.parsed; const total = ctx.chart.data.datasets[0].data.reduce(function(s,v){return s+v;},0); const pct = total?((value/total)*100).toFixed(1):'0.0'; return label+': '+value+' ('+pct+'%)'; } } }
                        }
                    }
                });
            } catch (err) { console.error('Variant chart init error', err); }
        }

        // Period selector wiring (re-added after accidental removal)
        function setupPeriodSelectors() {
            const buttons = document.querySelectorAll('.period-btn');
            buttons.forEach(btn => {
                btn.addEventListener('click', function (e) {
                    e.preventDefault();
                    const selected = this.getAttribute('data-period');
                    if (!selected || selected === currentPeriod) return;
                    buttons.forEach(b => b.classList.remove('active'));
                    this.classList.add('active');
                    currentPeriod = selected;
                    refreshAll();
                });
            });
        }

        // Update growth indicator (re-added)
        function updateGrowthIndicator() {
            normalizeChartDataStructure();
            if (!chartData || !chartData[currentPeriod]) return;
            const d = chartData[currentPeriod];
            const currentTotal = d.current.reduce((a,b)=>a + (parseFloat(b)||0),0);
            const previousTotal = d.previous.reduce((a,b)=>a + (parseFloat(b)||0),0);
            let growth = 0;
            if (previousTotal > 0) growth = ((currentTotal - previousTotal)/previousTotal*100);
            else if (previousTotal === 0 && currentTotal > 0) growth = 100; // from zero base
            const indicator = document.getElementById('growthIndicator');
            if (!indicator) return;
            const positive = growth >= 0;
            indicator.style.color = positive ? '#4CAF50' : '#f44336';
            const text = (currentTotal===0 && previousTotal===0)? 'No recent data' : Math.abs(growth).toFixed(1)+'%';
            indicator.innerHTML = '<i class="fas fa-arrow-' + (positive ? 'up' : 'down') + '"></i> <span id="growthPercentage">' + text + '</span> vs last period';
        }

        // Ensure growth indicator updates again after chart creation when switching period
        function refreshAll() {
            initializeSalesChart();
            updateGrowthIndicator();
        }

        // Number formatting helper (restored)
        function formatNumber(num) {
            var n = Number(num) || 0;
            if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M';
            if (n >= 1000) return (n / 1000).toFixed(1) + 'K';
            return n.toString();
        }
    </script>
</body>
</html>
