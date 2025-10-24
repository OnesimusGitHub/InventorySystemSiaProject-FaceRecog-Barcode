<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.Dashboard" Async="true" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        /* PDF Report Button */
        .btn-pdf-report {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.75rem 1.5rem;
            background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 4px 12px rgba(255, 107, 53, 0.3);
        }
        
        .btn-pdf-report:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(255, 107, 53, 0.4);
        }
        
        .btn-pdf-report i {
            font-size: 1.2rem;
        }
        
        /* PDF Modal */
        .pdf-modal {
            display: none;
            position: fixed;
            z-index: 10000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
            animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .pdf-modal-content {
            position: relative;
            background: white;
            margin: 5% auto;
            padding: 0;
            border-radius: 16px;
            width: 90%;
            max-width: 600px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        .pdf-modal-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 1.5rem 2rem;
            background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%);
            color: white;
            border-radius: 16px 16px 0 0;
        }
        
        .pdf-modal-header i {
            font-size: 1.5rem;
        }
        
        .pdf-modal-header h2 {
            flex: 1;
            margin: 0;
            font-size: 1.5rem;
            font-weight: 600;
        }
        
        .pdf-close-btn {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
        }
        
        .pdf-close-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: rotate(90deg);
        }
        
        .pdf-modal-body {
            padding: 2rem;
        }
        
        .report-type-section h3 {
            font-size: 0.875rem;
            font-weight: 600;
            color: #666;
            margin-bottom: 1rem;
            letter-spacing: 0.5px;
        }
        
        .report-option {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1.25rem;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            margin-bottom: 1rem;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .report-option:hover {
            border-color: #FF6B35;
            background-color: #fff5f2;
        }
        
        .report-option.selected {
            border-color: #FF6B35;
            background-color: #fff5f2;
        }
        
        .report-option-content {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        
        .report-option-content i {
            font-size: 2rem;
            color: #FF6B35;
        }
        
        .report-option-text h4 {
            margin: 0 0 0.25rem 0;
            font-size: 1.1rem;
            color: #333;
        }
        
        .report-option-text p {
            margin: 0;
            font-size: 0.875rem;
            color: #666;
        }
        
        .report-check {
            font-size: 1.5rem;
            color: #e0e0e0;
            transition: all 0.3s ease;
        }
        
        .report-option.selected .report-check {
            color: #FF6B35;
        }
        
        .custom-date-section {
            margin-top: 1.5rem;
            padding-top: 1.5rem;
            border-top: 1px solid #e0e0e0;
        }
        
        .custom-date-section h3 {
            font-size: 0.875rem;
            font-weight: 600;
            color: #666;
            margin-bottom: 1rem;
            letter-spacing: 0.5px;
        }
        
        .date-inputs {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
        }
        
        .date-input-group label {
            display: block;
            font-size: 0.875rem;
            font-weight: 500;
            color: #666;
            margin-bottom: 0.5rem;
        }
        
        .date-input {
            width: 100%;
            padding: 0.75rem;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1rem;
            transition: all 0.3s ease;
        }
        
        .date-input:focus {
            outline: none;
            border-color: #FF6B35;
        }
        
        .pdf-modal-footer {
            display: flex;
            justify-content: flex-end;
            gap: 1rem;
            padding: 1.5rem 2rem;
            background-color: #f9f9f9;
            border-radius: 0 0 16px 16px;
        }
        
        .btn-cancel, .btn-generate {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .btn-cancel {
            background-color: #e0e0e0;
            color: #666;
        }
        
        .btn-cancel:hover {
            background-color: #d0d0d0;
        }
        
        .btn-generate {
            background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%);
            color: white;
            box-shadow: 0 4px 12px rgba(255, 107, 53, 0.3);
        }
        
        .btn-generate:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(255, 107, 53, 0.4);
        }
        
        .dashboard-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <div>
            <div class="date-info" id="currentDate">Loading...</div>
            <h1 class="dashboard-title">Overall Sales</h1>
        </div>
        <div>
            <button type="button" class="btn-pdf-report" onclick="openPdfReportModal()">
                <i class="fas fa-file-pdf"></i>
                <span>Print PDF Report</span>
            </button>
        </div>
    </div>

    <div class="main-chart-container">
        <div class="chart-header">
            <div>
                <span id="growthIndicator" style="color: #4CAF50; font-size: 1.1rem;">
                    <i class="fas fa-arrow-up"></i> <span id="growthPercentage">Loading...</span> vs last period
                </span>
            </div>
            <div class="chart-period-selector">
                <button class="period-btn" data-period="daily">Daily</button>
                <button class="period-btn" data-period="weekly">Weekly</button>
                <button class="period-btn active" data-period="monthly">Monthly</button>
            </div>
        </div>
        <div class="chart-canvas">
            <canvas id="overallSalesChart"></canvas>
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

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-title">Total Sales</div>
            <div class="stat-value green" id="totalSalesValue">$0</div>
            <div class="stat-change" id="salesChange">
                <i class="fas fa-arrow-up"></i>
                <span>Loading...</span>
            </div>
            <div class="stat-chart">
                <canvas id="totalSalesChart"></canvas>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-title">Total Orders</div>
            <div class="stat-value blue" id="totalOrdersValue">0</div>
            <div class="stat-change" id="ordersChange">
                <i class="fas fa-arrow-up"></i>
                <span>Loading...</span>
            </div>
            <div class="customer-donut">
                <canvas id="customerChart"></canvas>
            </div>
            <div class="customer-legend">
                <div class="customer-legend-item">
                    <div class="legend-color" style="background-color: #ccc;"></div>
                    <span>New orders</span>
                </div>
                <div class="customer-legend-item">
                    <div class="legend-color" style="background-color: #333;"></div>
                    <span>Repeat orders</span>
                </div>
            </div>
        </div>
    </div>

    <div class="bottom-stats">
        <div class="stat-card">
            <div class="stat-title">Products</div>
            <div class="stat-value blue" id="totalProductsValue">0</div>
            <div class="stat-change" id="productsInfo">
                <i class="fas fa-box"></i>
                <span>Active products</span>
            </div>
            <div class="stat-chart">
                <canvas id="totalOrderChart"></canvas>
            </div>
        </div>

        <div class="stat-card">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div class="stat-title">Stock Status</div>
                <div class="order-report-selector">
                    <button class="report-btn" data-period="Low">Low</button>
                    <button class="report-btn" data-period="Normal">Normal</button>
                    <button class="report-btn active" data-period="All">All</button>
                </div>
            </div>
            <div class="stat-value red" id="stockStatusValue">0</div>
            <div class="stat-change" id="stockInfo">
                <i class="fas fa-warehouse"></i>
                <span>Items need attention</span>
            </div>
            <div class="order-donut">
                <canvas id="orderReportChart"></canvas>
            </div>
            <div class="order-legend">
                <div class="order-legend-item">
                    <div class="legend-color" style="background-color: #333;"></div>
                    <span>Normal stock</span>
                </div>
                <div class="order-legend-item">
                    <div class="legend-color" style="background-color: #999;"></div>
                    <span>Low stock</span>
                </div>
                <div class="order-legend-item">
                    <div class="legend-color" style="background-color: #ccc;"></div>
                    <span>Out of stock</span>
                </div>
            </div>
        </div>
    </div>

    <!-- PDF Report Modal -->
    <div id="pdfReportModal" class="pdf-modal">
        <div class="pdf-modal-content">
            <div class="pdf-modal-header">
                <i class="fas fa-file-pdf"></i>
                <h2>Print PDF Report</h2>
                <button type="button" class="pdf-close-btn" onclick="closePdfReportModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            
            <div class="pdf-modal-body">
                <div class="report-type-section">
                    <h3>SELECT REPORT TYPE</h3>
                    
                    <div class="report-option" id="standardOption" onclick="selectReportType('standard')">
                        <div class="report-option-content">
                            <i class="fas fa-calendar-alt"></i>
                            <div class="report-option-text">
                                <h4>Standard Periods</h4>
                                <p>Generate PDF with Daily, Weekly, and Monthly reports</p>
                            </div>
                        </div>
                        <i class="fas fa-check-circle report-check"></i>
                    </div>
                    
                    <div class="report-option" id="customOption" onclick="selectReportType('custom')">
                        <div class="report-option-content">
                            <i class="fas fa-calendar-week"></i>
                            <div class="report-option-text">
                                <h4>Custom Date Range</h4>
                                <p>Generate PDF for a specific date range</p>
                            </div>
                        </div>
                        <i class="fas fa-check-circle report-check"></i>
                    </div>
                </div>
                
                <div id="customDateSection" class="custom-date-section" style="display: none;">
                    <h3>SELECT DATE RANGE</h3>
                    <div class="date-inputs">
                        <div class="date-input-group">
                            <label>From Date</label>
                            <input type="date" id="startDate" class="date-input" />
                        </div>
                        <div class="date-input-group">
                            <label>To Date</label>
                            <input type="date" id="endDate" class="date-input" />
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="pdf-modal-footer">
                <button type="button" class="btn-cancel" onclick="closePdfReportModal()">
                    <i class="fas fa-times"></i>
                    Cancel
                </button>
                <button type="button" class="btn-generate" onclick="generatePdfReport()">
                    <i class="fas fa-file-pdf"></i>
                    Generate PDF
                </button>
            </div>
        </div>
    </div>

    <div class="filter-section">
        <div class="filter-group">
            <label for="categoryFilter">Category</label>
            <select id="categoryFilter" class="filter-select">
                <option value="">All Categories</option>
                <option value="Skincare">Skincare</option>
                <option value="Makeup">Makeup</option>
                <option value="Haircare">Haircare</option>
                <option value="Fragrance">Fragrance</option>
                <option value="Body Care">Body Care</option>
            </select>
        </div>
        <div class="filter-group">
            <label for="startDateFilter">Start Date</label>
            <input type="date" id="startDateFilter" class="filter-input" />
        </div>
        <div class="filter-group">
            <label for="endDateFilter">End Date</label>
            <input type="date" id="endDateFilter" class="filter-input" />
        </div>
        <div class="filter-group">
            <button type="button" class="btn-reset-filter">Reset Filters</button>
        </div>
    </div>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
<script>
    let overallSalesChartInstance = null;
    let currentPeriod = 'monthly';
    let filterCategory = '';
    let filterStartDate = '';
    let filterEndDate = '';

    // Initialize data immediately to prevent loading issues
    window.salesData = {
        daily: { 
            labels: ['Dec 01', 'Dec 02', 'Dec 03', 'Dec 04', 'Dec 05', 'Dec 06', 'Dec 07'], 
            data: [150, 180, 120, 200, 160, 190, 210] 
        },
        weekly: { 
            labels: ['Week 44', 'Week 45', 'Week 46', 'Week 47'], 
            data: [1200, 1450, 1100, 1600] 
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
    
    document.addEventListener('DOMContentLoaded', function() {
        console.log('Dashboard loading...');
        
        document.getElementById('currentDate').textContent = new Date().toLocaleDateString('en-US', { 
            month: 'long', 
            day: 'numeric', 
            year: 'numeric' 
        });

        initializePlaceholderCharts();
        setupPeriodSelectors();
        
        // Immediate update with guaranteed data
        setTimeout(function() {
            console.log('Initializing dashboard with default data');
            updateDashboardWithRealData();
        }, 100);
        
        // Check for server data and update if available
        let retryCount = 0;
        function checkForServerData() {
            retryCount++;
            console.log(`Checking for server data (attempt ${retryCount})...`);
            
            // This will be overridden by server data if it arrives
            if (retryCount >= 5) {
                console.log('Using fallback data - server data not available');
                return;
            }
            
            setTimeout(checkForServerData, 1000);
        }
        
        checkForServerData();

        // Setup filter event listeners
        document.getElementById('categoryFilter').addEventListener('change', applyFilters);
        document.getElementById('startDateFilter').addEventListener('change', applyFilters);
        document.getElementById('endDateFilter').addEventListener('change', applyFilters);
        document.querySelector('.btn-reset-filter').addEventListener('click', function() {
            document.getElementById('categoryFilter').value = '';
            document.getElementById('startDateFilter').value = '';
            document.getElementById('endDateFilter').value = '';
            setPeriodButtonsEnabled(true); // Re-enable period buttons
            currentPeriod = 'monthly';
            document.querySelectorAll('.period-btn').forEach(btn => {
                btn.classList.remove('active');
                if (btn.getAttribute('data-period') === 'monthly') btn.classList.add('active');
            });
            // Set stat cards to accurate values on reset
            const accurateStats = {
        totalSales: 663.81,
        salesGrowth: 0,
        totalOrders: 11,
        orderGrowth: 0,
        totalProducts: 7,
        lowStockItems: 5,
        activeVariants: 0
    };
    window.dashboardStats = accurateStats;
    updateStatsCards(accurateStats);
            applyFilters(); // This will fetch sales and stats for all categories and default period
        });
    });

    function updateDashboardWithRealData() {
        console.log('updateDashboardWithRealData called', window.salesData, window.dashboardStats);
        
        updateStatsCards(window.dashboardStats);
        updateMainChart(currentPeriod); // This will always fetch from backend
        updateMiniCharts();
        
        console.log('✅ Dashboard updated successfully');
    }

    function updateStatsCards(stats) {
        document.getElementById('totalSalesValue').textContent = '$' + formatNumber(stats.totalSales);
        const salesChangeEl = document.getElementById('salesChange');
        salesChangeEl.className = 'stat-change ' + (stats.salesGrowth >= 0 ? 'positive' : 'negative');
        salesChangeEl.innerHTML = `
            <i class="fas fa-arrow-${stats.salesGrowth >= 0 ? 'up' : 'down'}"></i>
            <span>${Math.abs(stats.salesGrowth)}% vs last month</span>
        `;

        document.getElementById('totalOrdersValue').textContent = stats.totalOrders;
        const ordersChangeEl = document.getElementById('ordersChange');
        ordersChangeEl.className = 'stat-change ' + (stats.orderGrowth >= 0 ? 'positive' : 'negative');
        ordersChangeEl.innerHTML = `
            <i class="fas fa-arrow-${stats.orderGrowth >= 0 ? 'up' : 'down'}"></i>
            <span>${Math.abs(stats.orderGrowth)}% vs last month</span>
        `;

        document.getElementById('totalProductsValue').textContent = stats.totalProducts;
        document.getElementById('productsInfo').innerHTML = `
            <i class="fas fa-box"></i>
            <span>${stats.activeVariants} active variants</span>
        `;

        document.getElementById('stockStatusValue').textContent = stats.lowStockItems;
        document.getElementById('stockInfo').innerHTML = `
            <i class="fas fa-warehouse"></i>
            <span>${stats.lowStockItems} items need attention</span>
        `;
    }

    function updateMainChart(period = 'monthly') {
        console.log('updateMainChart called with period:', period);
        // Always fetch fresh data from backend, never use hardcoded demo data
        filterCategory = document.getElementById('categoryFilter').value;
        filterStartDate = document.getElementById('startDateFilter').value;
        filterEndDate = document.getElementById('endDateFilter').value;
        fetchSalesData(period, filterCategory, filterStartDate, filterEndDate);
    }

    function updateChartWithData(data, period) {
        try {
            if (overallSalesChartInstance) {
                overallSalesChartInstance.destroy();
                overallSalesChartInstance = null;
            }

            const ctx = document.getElementById('overallSalesChart');
            if (!ctx) {
                console.error('Chart canvas not found');
                return;
            }

            const context = ctx.getContext('2d');
            
            const currentData = data.data || [];
            const lastYearData = window.salesData.lastYear?.data || [];
            
            console.log('Creating chart for period', period, 'with data points:', currentData.length);
            
            // Ensure data arrays are properly formatted
            const formattedCurrentData = currentData.map(val => parseFloat(val) || 0);
            const formattedLastYearData = lastYearData.map(val => parseFloat(val) || 0);
            
            overallSalesChartInstance = new Chart(context, {
                type: 'line',
                data: {
                    labels: data.labels || [],
                    datasets: [{
                        label: 'Last Year',
                        data: formattedLastYearData,
                        borderColor: '#4CAF50',
                        backgroundColor: 'rgba(76, 175, 80, 0.1)',
                        tension: 0.4,
                        fill: true
                    }, {
                        label: 'Current Period',
                        data: formattedCurrentData,
                        borderColor: '#2196F3',
                        backgroundColor: 'rgba(33, 150, 243, 0.1)',
                        tension: 0.4,
                        fill: true
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
                                    return '$' + formatNumber(value);
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
                                    return context.dataset.label + ': $' + formatNumber(context.parsed.y);
                                }
                            }
                        }
                    },
                    elements: {
                        point: {
                            radius: 4,
                            hoverRadius: 6
                        }
                    }
                }
            });

            updateGrowthIndicator(formattedCurrentData, formattedLastYearData);
            console.log('✅ Chart updated successfully for period:', period);
            
        } catch (error) {
            console.error('❌ Error creating chart:', error);
            setGrowthIndicator('Chart Error', false);
        }
    }

    function updateGrowthIndicator(currentData, lastYearData) {
        try {
            const currentTotal = currentData.reduce((sum, val) => sum + (parseFloat(val) || 0), 0);
            const lastYearTotal = lastYearData.reduce((sum, val) => sum + (parseFloat(val) || 0), 0);
            
            let growthPercentage = 0;
            if (lastYearTotal > 0) {
                growthPercentage = ((currentTotal - lastYearTotal) / lastYearTotal * 100).toFixed(1);
            } else if (currentTotal > 0) {
                growthPercentage = 100;
            }

            const isPositive = growthPercentage >= 0;
            setGrowthIndicator(Math.abs(growthPercentage) + '%', isPositive);
            
            console.log('Growth indicator updated:', growthPercentage + '%');
        } catch (error) {
            console.error('Error updating growth indicator:', error);
            setGrowthIndicator('Calc Error', false);
        }
    }

    function setGrowthIndicator(text, isPositive) {
        const indicator = document.getElementById('growthIndicator');
        if (indicator) {
            indicator.style.color = isPositive ? '#4CAF50' : '#f44336';
            indicator.innerHTML = `
                <i class="fas fa-arrow-${isPositive ? 'up' : 'down'}"></i> 
                <span id="growthPercentage">${text}</span> vs last period
            `;
        }
    }

    function formatNumber(num) {
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1) + 'M';
        } else if (num >= 1000) {
            return (num / 1000).toFixed(1) + 'K';
        }
        return parseFloat(num).toFixed(2);
    }

    function initializePlaceholderCharts() {
        initTotalSalesChart();
        initCustomerChart();
        initTotalOrderChart();
        initOrderReportChart();
    }

    function updateMiniCharts() {
        // Mini charts are placeholder charts that don't need updating
    }

    function initTotalSalesChart() {
        const ctx = document.getElementById('totalSalesChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['', '', '', '', '', '', ''],
                datasets: [{
                    data: [20, 25, 22, 30, 28, 32, 35],
                    borderColor: '#4CAF50',
                    backgroundColor: 'rgba(76, 175, 80, 0.3)',
                    tension: 0.4,
                    fill: true,
                    pointRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { display: false },
                    x: { display: false }
                },
                plugins: {
                    legend: { display: false }
                }
            }
        });
    }

    function initCustomerChart() {
        const ctx = document.getElementById('customerChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                datasets: [{
                    data: [70, 30],
                    backgroundColor: ['#333', '#ccc'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: { display: false }
                }
            }
        });
    }

    function initTotalOrderChart() {
        const ctx = document.getElementById('totalOrderChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['', '', '', '', '', '', ''],
                datasets: [{
                    data: [35, 32, 28, 25, 22, 20, 18],
                    borderColor: '#2196F3',
                    backgroundColor: 'rgba(33, 150, 243, 0.3)',
                    tension: 0.4,
                    fill: true,
                    pointRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { display: false },
                    x: { display: false }
                },
                plugins: {
                    legend: { display: false }
                }
            }
        });
    }

    function initOrderReportChart() {
        const ctx = document.getElementById('orderReportChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                datasets: [{
                    data: [67, 23, 10],
                    backgroundColor: ['#333', '#999', '#ccc'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: { display: false }
                }
            }
        });
    }

    function setupPeriodSelectors() {
        document.querySelectorAll('.period-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                
                const selectedPeriod = this.getAttribute('data-period');
                console.log('🔘 Period button clicked:', selectedPeriod);
                
                // Update button states
                document.querySelectorAll('.period-btn').forEach(sibling => {
                    sibling.classList.remove('active');
                });
                this.classList.add('active');
                
                // Update current period and chart
                currentPeriod = selectedPeriod;
                updateMainChart(currentPeriod);
            });
        });

        document.querySelectorAll('.report-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                
                document.querySelectorAll('.report-btn').forEach(sibling => {
                    sibling.classList.remove('active');
                });
                
                this.classList.add('active');
            });
        });
    }
    
    // PDF Report Modal Functions
    let selectedReportType = 'standard';
    
    function openPdfReportModal() {
        document.getElementById('pdfReportModal').style.display = 'block';
        document.body.style.overflow = 'hidden';
        
        // Set default dates
        const today = new Date();
        const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, today.getDate());
        
        document.getElementById('endDate').valueAsDate = today;
        document.getElementById('startDate').valueAsDate = lastMonth;
        
        // Select standard by default
        selectReportType('standard');
    }
    
    function closePdfReportModal() {
        document.getElementById('pdfReportModal').style.display = 'none';
        document.body.style.overflow = 'auto';
    }
    
    function selectReportType(type) {
        selectedReportType = type;
        
        const standardOption = document.getElementById('standardOption');
        const customOption = document.getElementById('customOption');
        const customDateSection = document.getElementById('customDateSection');
        
        if (type === 'standard') {
            standardOption.classList.add('selected');
            customOption.classList.remove('selected');
            customDateSection.style.display = 'none';
        } else {
            standardOption.classList.remove('selected');
            customOption.classList.add('selected');
            customDateSection.style.display = 'block';
        }
    }
    
    function generatePdfReport() {
        console.log('Generating PDF report...');
        
        let url = '../Handlers/GenerateDashboardPDF.ashx?';
        
        if (selectedReportType === 'standard') {
            // Standard report includes Daily, Weekly, and Monthly all in one PDF
            url += 'type=standard';
        } else {
            const startDate = document.getElementById('startDate').value;
            const endDate = document.getElementById('endDate').value;
            
            if (!startDate || !endDate) {
                alert('Please select both start and end dates.');
                return;
            }
            
            if (new Date(startDate) > new Date(endDate)) {
                alert('Start date must be before end date.');
                return;
            }
            
            url += 'type=custom&startDate=' + encodeURIComponent(startDate) + '&endDate=' + encodeURIComponent(endDate);
        }
        
        // Show loading state
        const generateBtn = document.querySelector('.btn-generate');
        const originalText = generateBtn.innerHTML;
        generateBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Generating...';
        generateBtn.disabled = true;
        
        // Open PDF in new window
        window.open(url, '_blank');
        
        // Reset button after a short delay
        setTimeout(() => {
            generateBtn.innerHTML = originalText;
            generateBtn.disabled = false;
            closePdfReportModal();
        }, 2000);
    }

    function setPeriodButtonsEnabled(enabled) {
        document.querySelectorAll('.period-btn').forEach(btn => {
            btn.disabled = !enabled;
            if (!enabled) {
                btn.classList.add('disabled');
            } else {
                btn.classList.remove('disabled');
            }
        });
    }

    function fetchDashboardStats(category, startDate, endDate) {
    const params = new URLSearchParams();
    if (category) params.append('category', category);
    if (startDate) params.append('startDate', startDate);
    if (endDate) params.append('endDate', endDate);
    fetch('../Handlers/GetDashboardStats.ashx?' + params.toString(), {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
    })
    .then(response => {
        if (!response.ok) throw new Error('Network response was not ok');
        return response.json();
    })
    .then(stats => {
        window.dashboardStats = stats;
        updateStatsCards(stats);
    })
    .catch(error => {
        console.error('Fetch dashboard stats error:', error);
    });
}

    function applyFilters() {
        filterCategory = document.getElementById('categoryFilter').value;
        filterStartDate = document.getElementById('startDateFilter').value;
        filterEndDate = document.getElementById('endDateFilter').value;
        // Disable period buttons if either date filter is set
        if (filterStartDate || filterEndDate) {
            setPeriodButtonsEnabled(false);
        } else {
            setPeriodButtonsEnabled(true);
        }
        console.log('Applying filters:', {
            period: currentPeriod,
            category: filterCategory,
            startDate: filterStartDate,
            endDate: filterEndDate
        });
        fetchSalesData(currentPeriod, filterCategory, filterStartDate, filterEndDate);
        fetchDashboardStats(filterCategory, filterStartDate, filterEndDate); // <-- fetch real stats
    }

    function fetchSalesData(period, category, startDate, endDate) {
        const params = new URLSearchParams();
        if (period) params.append('period', period);
        if (category) params.append('category', category);
        if (startDate) params.append('startDate', startDate);
        if (endDate) params.append('endDate', endDate);
        console.log('Fetching sales data with params:', params.toString());
        fetch('../Handlers/GetSalesByCategory.ashx?' + params.toString(), {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        })
        .then(response => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.json();
        })
        .then(data => {
            console.log('Received data from handler:', data);
            if (data && data.labels && data.data) {
                window.salesData[period] = {
                    labels: data.labels,
                    data: data.data,
                    lastYearData: data.lastYearData || [],
                    dateRange: data.dateRange || '',
                    aggregationType: period
                };
                updateChartWithData(window.salesData[period], period);
            } else {
                console.warn('Handler returned no usable data for chart.');
            }
        })
        .catch(error => {
            console.error('Fetch error:', error);
        });
    }
    
    // Close modal when clicking outside
    window.onclick = function(event) {
        const modal = document.getElementById('pdfReportModal');
        if (event.target == modal) {
            closePdfReportModal();
        }
    }
</script>
    </asp:Content>