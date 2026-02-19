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
        
        /* Filter Section Styling */
        .filter-section {
            display: flex;
            flex-wrap: wrap;
            gap: 1.5rem;
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(33, 150, 243, 0.07);
            padding: 1.5rem 2rem;
            margin-bottom: 2rem;
            align-items: flex-end;
        }
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            min-width: 160px;
        }
        .filter-group label {
            font-size: 1rem;
            font-weight: 500;
            color: #333;
            margin-bottom: 0.2rem;
        }
        .filter-select, .filter-input {
            padding: 0.6rem 1rem;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1rem;
            background: #fafbfc;
            color: #333;
            transition: border-color 0.2s, box-shadow 0.2s;
            box-shadow: 0 1px 4px rgba(33, 150, 243, 0.04);
        }
        .filter-select:focus, .filter-input:focus {
            outline: none;
            border-color: #FF6B35;
            box-shadow: 0 0 0 2px rgba(255, 107, 53, 0.15);
        }
        .btn-reset-filter {
            padding: 0.6rem 1.2rem;
            background: linear-gradient(135deg, #e0e0e0 0%, #f9f9f9 100%);
            color: #666;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 2px 8px rgba(33, 150, 243, 0.05);
        }
        .btn-reset-filter:hover {
            background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%);
            color: #fff;
            box-shadow: 0 4px 16px rgba(255, 107, 53, 0.13);
        }
        @media (max-width: 700px) {
            .filter-section {
                flex-direction: column;
                gap: 1rem;
                padding: 1rem;
            }
            .filter-group {
                min-width: 0;
            }
        }

        /* Dashboard Indicators */
        .dashboard-indicators {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .indicator-card {
            background: #fff;
            border-radius: 12px;
            padding: 1.5rem;
            display: flex;
            align-items: center;
            gap: 1.25rem;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
            border: 1px solid #F0F0F0;
        }

        .indicator-icon {
            width: 60px;
            height: 60px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2.2rem;
            color: #fff;
        }

        .stocks-icon {
            background: linear-gradient(135deg, #A36A66, #B87B77);
        }

        .products-icon {
            background: linear-gradient(135deg, #A36A66, #B87B77);
        }

        .archive-icon {
            background: linear-gradient(135deg, #A36A66, #B87B77);
        }

        .indicator-content {
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }

        .indicator-value {
            font-size: 2rem;
            font-weight: 700;
            line-height: 1;
        }

        .indicator-label {
            font-size: 0.95rem;
            color: #666;
            font-weight: 400;
        }
        
        /* Stock product list styles */
        #stockProductList {
            border-top: 1px solid #f0f0f0;
            padding-top: 0.75rem;
            margin-top: 1rem;
        }
        
        .stock-product-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem;
            margin-bottom: 0.5rem;
            background: #fafafa;
            border-radius: 6px;
            border-left: 3px solid #ccc;
            font-size: 0.85rem;
            transition: all 0.2s ease;
        }
        
        .stock-product-item:hover {
            background: #f0f0f0;
            transform: translateX(3px);
        }
        
        .stock-product-item.normal-stock {
            border-left-color: #4CAF50;
        }
        
        .stock-product-item.low-stock {
            border-left-color: #ff9800;
        }
        
        .stock-product-item.out-stock {
            border-left-color: #f44336;
        }
        
        .stock-product-image {
            width: 32px;
            height: 32px;
            border-radius: 4px;
            object-fit: cover;
            background: #e0e0e0;
        }
        
        .stock-product-info {
            flex: 1;
            min-width: 0;
        }
        
        .stock-product-name {
            font-weight: 500;
            color: #333;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .stock-product-details {
            font-size: 0.75rem;
            color: #666;
        }
        
        .stock-badge {
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.7rem;
            font-weight: 600;
            white-space: nowrap;
        }
        
        .stock-badge.normal {
            background: #e8f5e9;
            color: #2e7d32;
        }
        
        .stock-badge.low {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .stock-badge.out {
            background: #ffebee;
            color: #c62828;
        }
        
        .stock-product-list-empty {
            text-align: center;
            padding: 2rem 1rem;
            color: #999;
            font-size: 0.85rem;
        }
        
        .stock-product-list-empty i {
            font-size: 2rem;
            display: block;
            margin-bottom: 0.5rem;
            color: #ddd;
        }
        
        /* Period Button Styles - Always Enabled */
        .period-btn {
            cursor: pointer;
            opacity: 1;
            transition: all 0.3s ease;
        }
        
        .period-btn:hover {
            transform: translateY(-1px);
        }
        
        /* Remove disabled state styling */
        .period-btn.disabled {
            opacity: 1 !important;
            cursor: pointer !important;
            pointer-events: auto !important;
        }
        
        /* Optional: Add subtle indicator when filters are active */
        .chart-period-selector.has-filters::before {
            content: "Filtered View";
            position: absolute;
            top: -20px;
            right: 0;
            font-size: 0.7rem;
            color: #FF6B35;
            font-weight: 600;
            background: #fff5f2;
            padding: 2px 8px;
            border-radius: 4px;
        }
        
        .chart-period-selector {
            position: relative;
        }
        
        /* Sales Breakdown Pie Chart Styles */
        .sales-breakdown-donut {
            width: 100%;
            height: 200px;
            margin: 1rem 0;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
        }
        
        .sales-breakdown-legend {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #f0f0f0;
        }
        
        .sales-breakdown-legend-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 0.875rem;
            padding: 0.5rem;
            border-radius: 6px;
            transition: background-color 0.2s ease;
        }
        
        .sales-breakdown-legend-item:hover {
            background-color: #f9f9f9;
        }
        
        .sales-breakdown-legend-left {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }
        
        .sales-breakdown-legend-item .legend-color {
            width: 16px;
            height: 16px;
            border-radius: 4px;
            flex-shrink: 0;
        }
        
        .sales-breakdown-legend-value {
            font-weight: 600;
            color: #333;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
       <!-- Dashboard Indicators -->
   <div class="dashboard-indicators">
       <div class="indicator-card">
           <div class="indicator-icon stocks-icon">
               <i class="fas fa-clipboard-list"></i>
           </div>
           <div class="indicator-content">
               <div class="indicator-value" id="dashboardTotalStocks">0</div>
               <div class="indicator-label">Total Stocks </div>
           </div>
       </div>
       <div class="indicator-card">
           <div class="indicator-icon products-icon">
               <i class="fas fa-shopping-cart"></i>
           </div>
           <div class="indicator-content">
               <div class="indicator-value" id="dashboardTotalProducts">0</div>
               <div class="indicator-label">Total Products </div>
           </div>
       </div>
       <div class="indicator-card">
           <div class="indicator-icon archive-icon">
               <i class="fas fa-archive"></i>
           </div>
           <div class="indicator-content">
               <div class="indicator-value" id="dashboardArchivedProducts">0</div>
               <div class="indicator-label">Archive Products </div>
           </div>
       </div>
   </div>
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

    <!-- Filter Controls moved above the main chart -->
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
            <div class="stat-value green" id="totalSalesValue">₱0</div>
            <div class="stat-change" id="salesChange">
                <i class="fas fa-arrow-up"></i>
                <span>Loading...</span>
            </div>
            
            <!-- Sales Breakdown Pie Chart -->
            <div class="sales-breakdown-donut">
                <canvas id="salesBreakdownChart"></canvas>
            </div>
            <div class="sales-breakdown-legend">
                <div class="sales-breakdown-legend-item">
                    <div class="sales-breakdown-legend-left">
                        <div class="legend-color" style="background-color: #4CAF50;"></div>
                        <span>Today</span>
                    </div>
                    <span class="sales-breakdown-legend-value" id="dailySalesLegend">₱0</span>
                </div>
                <div class="sales-breakdown-legend-item">
                    <div class="sales-breakdown-legend-left">
                        <div class="legend-color" style="background-color: #2196F3;"></div>
                        <span>Last 7 Days</span>
                    </div>
                    <span class="sales-breakdown-legend-value" id="weeklySalesLegend">₱0</span>
                </div>
                <div class="sales-breakdown-legend-item">
                    <div class="sales-breakdown-legend-left">
                        <div class="legend-color" style="background-color: #FF9800;"></div>
                        <span>This Month</span>
                    </div>
                    <span class="sales-breakdown-legend-value" id="monthlySalesLegend">₱0</span>
                </div>
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
            
            <!-- Product list for selected filter -->
            <div id="stockProductList"></div>
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
    
    // Initialize on DOM ready
    document.addEventListener('DOMContentLoaded', function() {
        
        document.getElementById('currentDate').textContent = new Date().toLocaleDateString('en-US', { 
            month: 'long', 
            day: 'numeric', 
            year: 'numeric' 
        });

        initializePlaceholderCharts();
        setupPeriodSelectors();
        
        // Immediate update with guaranteed data
        setTimeout(function() {
            updateDashboardWithRealData();
        }, 100);
        
        // Update dashboard indicators independently (not affected by filters)
        updateDashboardIndicators();
        
        // ✅ NEW: Load real stock stats for pie chart
        loadStockStats();
        
        // Check for server data and update if available
        let retryCount = 0;
        function checkForServerData() {
            retryCount++;
            
            if (retryCount >= 5) {
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
            location.reload();
        });
    });

    function updateDashboardWithRealData() {
        updateStatsCards(window.dashboardStats);
        updateMainChart(currentPeriod);
        updateMiniCharts();
    }

    function updateStatsCards(stats) {
        document.getElementById('totalSalesValue').textContent = '₱' + formatNumber(stats.totalSales);
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
        filterCategory = document.getElementById('categoryFilter').value;
        filterStartDate = document.getElementById('startDateFilter').value;
        filterEndDate = document.getElementById('endDateFilter').value;
        
        // ✅ NEW: Add visual indicator when filters are active
        const periodSelector = document.querySelector('.chart-period-selector');
        if (periodSelector) {
            if (filterCategory || filterStartDate || filterEndDate) {
                periodSelector.classList.add('has-filters');
            } else {
                periodSelector.classList.remove('has-filters');
            }
        }
        
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
                return;
            }

            const context = ctx.getContext('2d');
            
            const currentData = data.data || [];
            const lastYearData = window.salesData.lastYear?.data || [];
            
            const formattedCurrentData = currentData.map(val => parseFloat(val) || 0);
            const formattedLastYearData = lastYearData.map(val => parseFloat(val) || 0);
            
            overallSalesChartInstance = new Chart(context, {
                type: 'bar', // ✅ Changed from 'line' to 'bar'
                data: {
                    labels: data.labels || [],
                    datasets: [{
                        label: 'Last Year',
                        data: formattedLastYearData,
                        backgroundColor: 'rgba(76, 175, 80, 0.7)', // ✅ Solid color for bars
                        borderColor: '#4CAF50',
                        borderWidth: 2
                    }, {
                        label: 'Current Period',
                        data: formattedCurrentData,
                        backgroundColor: 'rgba(33, 150, 243, 0.7)', // ✅ Solid color for bars
                        borderColor: '#2196F3',
                        borderWidth: 2
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
                                    return '₱' + formatNumber(value);
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
                                    return context.dataset.label + ': ₱' + formatNumber(context.parsed.y);
                                }
                            }
                        }
                    }
                    // ✅ Removed elements.point configuration (not needed for bar charts)
                }
            });

            updateGrowthIndicator(formattedCurrentData, formattedLastYearData);
            
        } catch (error) {
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

        } catch (error) {
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
        initCustomerChart();
        initTotalOrderChart();
        initOrderReportChart();
        initSalesBreakdownChart(); // ✅ Keep: Initialize sales breakdown pie chart
    }

    function updateMiniCharts() {
        // Mini charts are placeholder charts that don't need updating
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
        // ✅ Store chart instance globally so we can update it later
        window.stockStatusChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                datasets: [{
                    data: [67, 23, 10],  // Placeholder data - will be replaced
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
    
    // ✅ NEW: Initialize sales breakdown pie chart
    function initSalesBreakdownChart() {
        const ctx = document.getElementById('salesBreakdownChart').getContext('2d');
        window.salesBreakdownChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Today', 'Last 7 Days', 'This Month'],
                datasets: [{
                    data: [0, 0, 0],  // Will be updated with real data
                    backgroundColor: ['#4CAF50', '#2196F3', '#FF9800'],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '65%',
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                var label = context.label || '';
                                var value = context.parsed || 0;
                                var total = context.dataset.data.reduce(function(a, b) { return a + b; }, 0);
                                var percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0;
                                return label + ': ₱' + formatNumber(value) + ' (' + percentage + '%)';
                            }
                        }
                    }
                }
            },
        });
        
        // Load real data
        updateSalesBreakdownChart();
    }
    
    // ✅ NEW: Function to fetch and update sales breakdown data
    function updateSalesBreakdownChart() {
        console.log('📊 Loading sales breakdown...');
        
        var today = new Date();
        var todayStr = today.toISOString().split('T')[0];
        
        // Calculate date 7 days ago
        var weekAgo = new Date(today);
        weekAgo.setDate(weekAgo.getDate() - 7);
        var weekAgoStr = weekAgo.toISOString().split('T')[0];
        
        // Calculate first day of current month
        var monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
        var monthStartStr = monthStart.toISOString().split('T')[0];
        
        // Fetch all three periods in parallel
        Promise.all([
            // Today's sales
            fetch('../Handlers/GetSalesByCategory.ashx?period=daily&startDate=' + todayStr + '&endDate=' + todayStr)
                .then(function(response) { return response.json(); }),
            // Last 7 days
            fetch('../Handlers/GetSalesByCategory.ashx?period=daily&startDate=' + weekAgoStr + '&endDate=' + todayStr)
                .then(function(response) { return response.json(); }),
            // Current month
            fetch('../Handlers/GetSalesByCategory.ashx?period=daily&startDate=' + monthStartStr + '&endDate=' + todayStr)
                .then(function(response) { return response.json(); })
        ])
        .then(function(results) {
            var dailyData = results[0];
            var weeklyData = results[1];
            var monthlyData = results[2];
            
            // Calculate totals
            var todaySales = 0;
            if (dailyData && dailyData.data && dailyData.data.length > 0) {
                todaySales = dailyData.data.reduce(function(sum, val) {
                    return sum + (parseFloat(val) || 0);
                }, 0);
            }
            
            var weeklySales = 0;
            if (weeklyData && weeklyData.data && weeklyData.data.length > 0) {
                weeklySales = weeklyData.data.reduce(function(sum, val) {
                    return sum + (parseFloat(val) || 0);
                }, 0);
            }
            
            var monthlySales = 0;
            if (monthlyData && monthlyData.data && monthlyData.data.length > 0) {
                monthlySales = monthlyData.data.reduce(function(sum, val) {
                    return sum + (parseFloat(val) || 0);
                }, 0);
            }
            
            console.log('✅ Sales breakdown loaded:', {
                today: todaySales,
                weekly: weeklySales,
                monthly: monthlySales
            });
            
            // Update pie chart
            if (window.salesBreakdownChart) {
                window.salesBreakdownChart.data.datasets[0].data = [todaySales, weeklySales, monthlySales];
                window.salesBreakdownChart.update();
            }
            
            // Update legend values
            document.getElementById('dailySalesLegend').textContent = '₱' + formatNumber(todaySales);
            document.getElementById('weeklySalesLegend').textContent = '₱' + formatNumber(weeklySales);
            document.getElementById('monthlySalesLegend').textContent = '₱' + formatNumber(monthlySales);
        })
        .catch(function(error) {
            console.error('❌ Error loading sales breakdown:', error);
            // Set default values on error
            document.getElementById('dailySalesLegend').textContent = '₱0';
            document.getElementById('weeklySalesLegend').textContent = '₱0';
            document.getElementById('monthlySalesLegend').textContent = '₱0';
        });
    }
    
    function setupPeriodSelectors() {
        document.querySelectorAll('.period-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                
                const selectedPeriod = this.getAttribute('data-period');
                
                document.querySelectorAll('.period-btn').forEach(sibling => {
                    sibling.classList.remove('active');
                });
                this.classList.add('active');
                
                currentPeriod = selectedPeriod;
                
                // ✅ NEW: Always update chart regardless of filters
                // Period buttons now work WITH date filters
                updateMainChart(currentPeriod);
            });
        });

        // ✅ Setup stock status filter buttons
        document.querySelectorAll('.report-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                
                document.querySelectorAll('.report-btn').forEach(sibling => {
                    sibling.classList.remove('active');
                });
                
                this.classList.add('active');
                
                // Reload stock stats when filter changes
                var filter = this.getAttribute('data-period'); // "Low", "Normal", or "All"
                console.log('📊 Stock filter changed to:', filter);
                loadStockStats(); // Reload the chart
            });
        });
    }
    
    // PDF Report Modal Functions
    let selectedReportType = 'standard';
    
    function openPdfReportModal() {
        document.getElementById('pdfReportModal').style.display = 'block';
        document.body.style.overflow = 'hidden';
        
        const today = new Date();
        const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, today.getDate());
        
        document.getElementById('endDate').valueAsDate = today;
        document.getElementById('startDate').valueAsDate = lastMonth;
        
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
        let url = '../Handlers/GenerateDashboardPDF.ashx?';
        
        if (selectedReportType === 'standard') {
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
        
        const generateBtn = document.querySelector('.btn-generate');
        const originalText = generateBtn.innerHTML;
        generateBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Generating...';
        generateBtn.disabled = true;
        
        window.open(url, '_blank');
        
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

    // Update dashboard indicators independently - NOT affected by chart filters
    function updateDashboardIndicators() {
        updateTotalStocksIndicator();
        updateTotalProductsIndicator();
        updateArchiveProductsIndicator();
    }

    function updateTotalStocksIndicator() {
        fetch('../Handlers/GetProductVariantsByCategory.ashx?category=')
            .then(response => response.json())
            .then(data => {
                var total = 0;
                if (Array.isArray(data)) {
                    total = data.reduce(function(sum, v) {
                        return sum + (parseInt(v.StockQuantity) || 0);
                    }, 0);
                }
                var stocks = document.getElementById('dashboardTotalStocks');
                if (stocks) stocks.textContent = total;
            })
            .catch(function() {
                var stocks = document.getElementById('dashboardTotalStocks');
                if (stocks) stocks.textContent = '0';
            });
    }

    function updateTotalProductsIndicator() {
        fetch('../Handlers/GetProductVariantsByCategory.ashx?category=')
            .then(response => response.json())
            .then(data => {
                var count = Array.isArray(data) ? data.length : 0;
                var products = document.getElementById('dashboardTotalProducts');
                if (products) products.textContent = count;
            })
            .catch(function() {
                var products = document.getElementById('dashboardTotalProducts');
                if (products) products.textContent = '0';
            });
    }

    function updateArchiveProductsIndicator() {
        fetch('../Handlers/GetArchivedProducts.ashx')
            .then(response => response.json())
            .then(data => {
                var count = 0;
                if (data && data.products && Array.isArray(data.products)) {
                    count = data.products.filter(function(p) {
                        var status = (p.Status || p.status || '').toLowerCase().trim();
                        return status === 'inactive';
                    }).length;
                }
                var archived = document.getElementById('dashboardArchivedProducts');
                if (archived) archived.textContent = count;
            })
            .catch(function() {
                var archived = document.getElementById('dashboardArchivedProducts');
                if (archived) archived.textContent = '0';
            });
    }

    // ✅ NEW FUNCTION: Load real stock statistics for the pie chart
    function loadStockStats() {
        console.log('📊 Loading stock statistics...');
        
        // ✅ Get the active filter from buttons
        var activeFilter = 'All';
        var activeBtn = document.querySelector('.report-btn.active');
        if (activeBtn) {
            activeFilter = activeBtn.getAttribute('data-period');
        }
        
        console.log('📊 Loading with filter:', activeFilter);
        
        fetch('../Handlers/GetStockStats.ashx?filter=' + encodeURIComponent(activeFilter))
            .then(response => {
                if (!response.ok) throw new Error('Network response was not ok');
                return response.json();
            })
            .then(data => {
                console.log('✅ Stock stats loaded:', data);
                
                if (data.success) {
                    // Update the pie chart with real data
                    updateStockStatusChart(data.normalStock, data.lowStock, data.outOfStock);
                    
                    // Update the stock status value and text
                    var needsAttention = data.lowStock + data.outOfStock;
                    document.getElementById('stockStatusValue').textContent = needsAttention;
                    
                    // ✅ Update info text based on filter
                    var infoText = needsAttention + ' items need attention';
                    if (activeFilter === 'Low') {
                        infoText = needsAttention + ' low/out of stock items';
                    } else if (activeFilter === 'Normal') {
                        infoText = data.normalStock + ' items in normal stock';
                    }
                    
                    document.getElementById('stockInfo').innerHTML = 
                        '<i class="fas fa-warehouse"></i>' +
                        '<span>' + infoText + '</span>';
                        
                    // ✅ Update product list if products data exists
                    if (data.products) {
                        updateStockProductList(data.products, activeFilter);
                    }
                    
                    console.log('✅ Stock status updated: Normal=' + data.normalStock + 
                                ', Low=' + data.lowStock + ', Out=' + data.outOfStock +
                                ', Filter=' + activeFilter);
                } else {
                    console.error('❌ Failed to load stock stats:', data.error);
                }
            })
            .catch(error => {
                console.error('❌ Error loading stock stats:', error);
            });
    }
    
    // ✅ NEW FUNCTION: Update the product list display
    function updateStockProductList(products, filter) {
        var container = document.getElementById('stockProductList');
        if (!container) return;
        
        if (!products || products.length === 0) {
            container.innerHTML = 
                '<div class="stock-product-list-empty">' +
                    '<i class="fas fa-inbox"></i>' +
                    '<div>No products in this category</div>' +
                '</div>';
            return;
        }
        
        var html = '';
        var filterText = filter === 'All' ? 'Products' : 
                        filter === 'Low' ? 'Low Stock' : 
                        'Normal Stock';
        
        html += '<div style="font-size: 0.75rem; font-weight: 600; color: #666; margin-bottom: 0.5rem; margin-top: 0.75rem; text-transform: uppercase; border-top: 1px solid #f0f0f0; padding-top: 0.75rem;">' + 
                filterText + ' (' + products.length + ')' +
                '</div>';
        
        products.forEach(function(product) {
            var statusClass = product.stockStatus === 'out' ? 'out-stock' : 
                             product.stockStatus === 'low' ? 'low-stock' : 'normal-stock';
            
            var badgeClass = product.stockStatus === 'out' ? 'out' : 
                            product.stockStatus === 'low' ? 'low' : 'normal';
            
            var statusText = product.stockStatus === 'out' ? 'Out' : 
                            product.stockStatus === 'low' ? 'Low' : 'Normal';
            
            html += '<div class="stock-product-item ' + statusClass + '">' +
                        '<img src="' + (product.productImage || '/Content/images/sample-generic.png') + '" ' +
                             'class="stock-product-image" ' +
                             'alt="' + (product.productName || 'Product') + '" ' +
                             'onerror="this.src=\'/Content/images/sample-generic.png\'">' +
                        '<div class="stock-product-info">' +
                            '<div class="stock-product-name" title="' + (product.productName || '') + ' - ' + (product.variantName || '') + '">' +
                                (product.variantName || 'Unknown Product') +
                            '</div>' +
                            '<div class="stock-product-details">' +
                                (product.stockQuantity || 0) + '/' + (product.minimumStock || 0) + ' units' +
                            '</div>' +
                        '</div>' +
                        '<span class="stock-badge ' + badgeClass + '">' + statusText + '</span>' +
                    '</div>';
        });
        
        container.innerHTML = html;
        console.log('✅ Product list updated with', products.length, 'items');
    }
    
    // ✅ NEW FUNCTION: Update the stock status pie chart
    function updateStockStatusChart(normalStock, lowStock, outOfStock) {
        if (window.stockStatusChart) {
            // ✅ Update chart based on which filter is active
            var activeBtn = document.querySelector('.report-btn.active');
            var activeFilter = activeBtn ? activeBtn.getAttribute('data-period') : 'All';
            
            // Update data based on filter
            if (activeFilter === 'Low') {
                // Show only low stock items in the chart
                window.stockStatusChart.data.datasets[0].data = [0, lowStock, outOfStock];
                window.stockStatusChart.data.datasets[0].backgroundColor = ['#e0e0e0', '#999', '#ccc'];
            } else if (activeFilter === 'Normal') {
                // Show only normal stock items in the chart
                window.stockStatusChart.data.datasets[0].data = [normalStock, 0, 0];
                window.stockStatusChart.data.datasets[0].backgroundColor = ['#333', '#e0e0e0', '#e0e0e0'];
            } else {
                // Show all items
                window.stockStatusChart.data.datasets[0].data = [normalStock, lowStock, outOfStock];
                window.stockStatusChart.data.datasets[0].backgroundColor = ['#333', '#999', '#ccc'];
            }
            
            window.stockStatusChart.update();
            console.log('✅ Stock status chart updated with filter:', activeFilter);
        } else {
            console.warn('⚠️ Stock status chart not initialized');
        }
    }

    // Apply filters to chart only - does NOT affect dashboard indicators
    function applyFilters() {
        filterCategory = document.getElementById('categoryFilter').value;
        filterStartDate = document.getElementById('startDateFilter').value;
        filterEndDate = document.getElementById('endDateFilter').value;
        
        // ✅ REMOVED: No longer disable period buttons when date filters are set
        // Period buttons are now always accessible
        
        // Only update the chart - DO NOT update dashboard indicators
        fetchSalesData(currentPeriod, filterCategory, filterStartDate, filterEndDate);
    }

    function fetchSalesData(period, category, startDate, endDate) {
        const params = new URLSearchParams();
        
        // ✅ NEW LOGIC: Period buttons work WITH filters
        // If date filters are set, they take precedence but period still determines aggregation
        if (period) params.append('period', period);
        if (category) params.append('category', category);
        if (startDate) params.append('startDate', startDate);
        if (endDate) params.append('endDate', endDate);

        console.log('📊 Fetching sales data with params:', {period, category, startDate, endDate});

        fetch('../Handlers/GetSalesByCategory.ashx?' + params.toString(), {
            method: 'GET',
            headers: { 'Accept': 'application/json' }
        })
        .then(response => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.json();
        })
        .then(data => {
            console.log('✅ Sales data received:', data);
            
            // Log debug info if available
            if (data.debug) {
                console.log('📊 Debug Info:');
                console.log('   Total sales in DB:', data.debug.totalSalesInDb);
                console.log('   Filtered sales count:', data.debug.filteredSalesCount);
                console.log('   Categories found:', data.debug.categoriesFound);
                console.log('   Requested category:', data.debug.requestedCategory);
            }
            
            if (data && data.labels && data.data) {
                // Check if data is empty
                if (data.labels.length === 0 || data.data.every(val => val === 0)) {
                    // Show helpful message about no data
                    const categoryText = category ? `for "${category}" category` : '';
                    const dateText = (startDate || endDate) ? ` in the selected date range` : '';
                    const periodText = period ? ` (${period} view)` : '';
                    console.warn(`⚠️ No sales data found ${categoryText}${dateText}${periodText}`);
                    
                    // Show debug info to user
                    if (data.debug) {
                        console.warn(`💡 Available categories: ${data.debug.categoriesFound.join(', ')}`);
                    }
                    
                    // Show a message to the user
                    const growthEl = document.getElementById('growthIndicator');
                    if (growthEl) {
                        growthEl.style.color = '#ff9800';
                        let message = `No sales data available ${categoryText}${dateText}`;
                        if (data.debug && data.debug.categoriesFound && data.debug.categoriesFound.length > 0) {
                            message += ` (Available: ${data.debug.categoriesFound.join(', ')})`;
                        }
                        growthEl.innerHTML = `
                            <i class="fas fa-info-circle"></i> 
                            <span>${message}</span>
                        `;
                    }
                    
                    // Still update the chart with empty data
                    window.salesData[period] = {
                        labels: data.labels.length > 0 ? data.labels : ['No Data'],
                        data: [0],
                        lastYearData: [0],
                        dateRange: data.dateRange || '',
                        aggregationType: period
                    };
                } else {
                    console.log('✅ Valid sales data received with', data.labels.length, 'data points');
                    window.salesData[period] = {
                        labels: data.labels,
                        data: data.data,
                        lastYearData: data.lastYearData || [],
                        dateRange: data.dateRange || '',
                        aggregationType: period
                    };
                }
                updateChartWithData(window.salesData[period], period);
            }
        })
        .catch(error => {
            console.error('❌ Error fetching sales data:', error);
            // Show error message
            const growthEl = document.getElementById('growthIndicator');
            if (growthEl) {
                growthEl.style.color = '#f44336';
                growthEl.innerHTML = `
                    <i class="fas fa-exclamation-triangle"></i> 
                    <span>Error loading sales data</span>
                `;
            }
        });
    }
</script>
</asp:Content>