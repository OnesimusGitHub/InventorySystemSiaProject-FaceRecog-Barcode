<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="ProductProfile.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductProfile" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Product Profile</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href="../Content/productprofile.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script id="jsPdfScript" src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.5.31/jspdf.plugin.autotable.min.js" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        /* Charts section styling - Updated to match Dashboard */
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

        .print-btn { margin-left:10px; background:#ff5722; color:#fff; border:none; padding:6px 14px; border-radius:6px; cursor:pointer; font-size:.8rem; }
        .print-btn:hover { background:#e64a19; }
        
        /* PDF Report Buttons */
        .btn-pdf-report {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            color: white;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-pdf-report:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2) !important;
        }
        
        .btn-pdf-report:active {
            transform: translateY(0);
        }
        
        .btn-pdf-report i {
            font-size: 16px;
        }
        
        /* 🖨️ Print Options Modal Styles */
        .print-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.6);
            backdrop-filter: blur(8px);
            z-index: 10000;
            display: none;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: all 0.3s ease;
        }
        
        .print-modal-overlay.show {
            display: flex;
            opacity: 1;
        }
        
        .print-modal-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            max-width: 550px;
            width: 90%;
            overflow: hidden;
            transform: scale(0.8) translateY(30px);
            transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        
        .print-modal-overlay.show .print-modal-container {
            transform: scale(1) translateY(0);
        }
        
        .print-modal-header {
            background: linear-gradient(135deg, #ff5722 0%, #e64a19 100%);
            color: white;
            padding: 25px 30px;
            position: relative;
        }
        
        .print-modal-title {
            font-size: 24px;
            font-weight: 600;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .print-modal-title i {
            font-size: 28px;
        }
        
        .print-modal-close {
            position: absolute;
            top: 20px;
            right: 25px;
            background: rgba(255,255,255,0.2);
            border: none;
            color: white;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            transition: all 0.3s ease;
        }
        
        .print-modal-close:hover {
            background: rgba(255,255,255,0.3);
            transform: rotate(90deg) scale(1.1);
        }
        
        .print-modal-body {
            padding: 30px;
        }
        
        .print-option-section {
            margin-bottom: 30px;
        }
        
        .print-option-title {
            font-size: 14px;
            font-weight: 600;
            color: #666;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .print-option-card {
            background: #f8f9fa;
            border: 2px solid #e9ecef;
            border-radius: 12px;
            padding: 20px;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-bottom: 15px;
            position: relative;
        }
        
        .print-option-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
            border-color: #ff5722;
        }
        
        .print-option-card.selected {
            border-color: #ff5722;
            background: #fff3e0;
        }
        
        .print-option-card.selected::before {
            content: '✓';
            position: absolute;
            top: 15px;
            right: 15px;
            width: 24px;
            height: 24px;
            background: #ff5722;
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }
        
        .print-option-label {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .print-option-description {
            font-size: 13px;
            color: #666;
            margin: 0;
        }
        
        .date-range-inputs {
            display: none;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e9ecef;
        }
        
        .date-range-inputs.show {
            display: block;
            animation: slideDown 0.3s ease;
        }
        
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .date-input-group {
            margin-bottom: 15px;
        }
        
        .date-input-label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
        }
        
        .date-input {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s ease;
        }
        
        .date-input:focus {
            outline: none;
            border-color: #ff5722;
            box-shadow: 0 0 0 3px rgba(255, 87, 34, 0.1);
        }
        
        .print-modal-footer {
            background: #f8f9fa;
            padding: 20px 30px;
            border-top: 1px solid #e9ecef;
            display: flex;
            gap: 15px;
            justify-content: flex-end;
        }
        
        .print-modal-btn {
            padding: 12px 30px;
            border-radius: 25px;
            border: none;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
        }
        
        .print-modal-btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .print-modal-btn-secondary:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }
        
        .print-modal-btn-primary {
            background: linear-gradient(135deg, #ff5722 0%, #e64a19 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(255, 87, 34, 0.3);
        }
        
        .print-modal-btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(255, 87, 34, 0.4);
        }
        
        .print-modal-btn-primary:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        /* Sales tables */
        #salesTables { background:#fff; border-radius:15px; padding:1.5rem 2rem; margin-top:20px; box-shadow:0 2px 10px rgba(0,0,0,.08); }
        #salesTables h3 { margin:0 0 1rem; font-size:1.1rem; font-weight:600; }
        .tables-flex { display:flex; flex-wrap:wrap; gap:1.5rem; }
        .sales-table-wrap { flex:1 1 280px; min-width:260px; }
        table.sales-table { width:100%; border-collapse:collapse; font-size:.8rem; }
        table.sales-table caption { text-align:left; font-weight:600; margin-bottom:.4rem; }
        table.sales-table th, table.sales-table td { padding:4px 6px; border:1px solid #e0e0e0; text-align:right; }
        table.sales-table th:first-child, table.sales-table td:first-child { text-align:left; }
        table.sales-table thead { background:#f5f5f5; }
        table.sales-table tfoot td { font-weight:600; background:#fafafa; }
        .variant-active-label { background:#2196F3; color:#fff; padding:2px 6px; border-radius:4px; font-size:.65rem; margin-left:6px; }
        .variant-btn.active { outline:2px solid #2196F3; }
#ingredientsContainer {
    margin-top: 18px;
    background: transparent;
    padding: 0;
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    max-width: 100%;
    overflow-x: visible;
}
.ingredient-pill {
    display: inline-flex;
    align-items: center;
    border: 2px solid #5c7cfa;
    border-radius: 14px;
    background: #f8f9fa;
    padding: 8px 12px;
    font-size: 13px;
    color: #333;
    box-shadow: 0 2px 8px rgba(92,124,250,0.04);
    gap: 4px;
    transition: box-shadow 0.2s;
    margin-bottom: 0;
    white-space: nowrap;
    flex-shrink: 0;
}

.ingredient-pill:hover {
    box-shadow: 0 4px 12px rgba(92,124,250,0.15);
}

.ingredient-icon {
    color: #5c7cfa;
    font-size: 15px;
    margin-right: 4px;
}

.ingredient-name {
    font-weight: 700;
    color: #4263eb;
    margin-right: 4px;
    font-family: inherit;
}

.ingredient-qty {
    font-size: 13px;
    color: #222;
    margin-left: 1px;
}

.ingredient-remove {
    color: #e03131;
    font-size: 15px;
    margin-left: 8px;
    cursor: pointer;
    transition: color 0.2s;
    font-weight: bold;
}

.ingredient-remove:hover {
    color: #c92a2a;
}

.ingredients-section {
    margin-top: 18px;
    width: 100%;
}

.ingredients-header {
    font-size: 17px;
    font-weight: 700;
    color: #a86d6a;
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 12px;
    padding-left: 2px;
    letter-spacing: 0.5px;
}

.ingredients-header i {
    color: #5c7cfa;
    font-size: 20px;
}

        /* Lightbox styles */
        #imgLightboxModal {
            display: none;
            position: fixed;
            z-index: 99999;
            left: 0;
            top: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(0, 0, 0, 0.85);
            align-items: center;
            justify-content: center;
        }
        
        #imgLightboxClose {
            position: absolute;
            top: 30px;
            right: 40px;
            color: #fff;
            font-size: 2.5rem;
            cursor: pointer;
            z-index: 1001;
        }
        
        #imgLightboxImg {
            max-width: 90vw;
            max-height: 90vh;
            border-radius: 12px;
            box-shadow: 0 8px 32px #0008;
            display: block;
            margin: auto;
        }

        /* Back button styling */
.back-button-container {
    max-width: 1200px;
    margin: 20px auto 0;
    padding: 0 20px;
}

.btn-back {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 12px 24px;
    background: #a86d6a;
    color: white;
    border: none;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    text-decoration: none;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.btn-back:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
}

.btn-back:active {
    transform: translateY(0);
}

.btn-back i {
    font-size: 16px;
}
body {
    background-color: #e2cdca;
}

.options {
    max-height: 180px; /* or any height you want */
    overflow-y: auto;
}

/* Gallery overlay indicators */
.gallery .main-image { position: relative; }
.gallery-overlay { position: absolute; left: 12px; right: 12px; bottom: 12px; display:flex; align-items:center; justify-content:space-between; gap:12px; pointer-events:none; }
.image-counter { background: rgba(0,0,0,0.55); color: #fff; padding:6px 10px; border-radius:12px; font-size:13px; pointer-events:auto; }
.variant-label { background: rgba(0,0,0,0.55); color:#fff; padding:6px 10px; border-radius:12px; font-size:13px; pointer-events:auto; white-space:nowrap; max-width:60%; overflow:hidden; text-overflow:ellipsis; }
.image-dots { display:flex; gap:6px; align-items:center; pointer-events:auto; }
.image-dots .dot { width:8px; height:8px; border-radius:50%; background: rgba(255,255,255,0.5); transition: all 0.18s; }
.image-dots .dot.active { background: #fff; transform: scale(1.2); }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="back-button-container">
    <a href="ProductPage.aspx" class="btn-back">
        <i class="fas fa-arrow-left"></i>
        <span>Back to Product Page</span>
    </a>
</div>
        
        <!-- Hidden fields to store chart data -->
        <asp:HiddenField ID="hfChartData" runat="server" />
       <asp:HiddenField ID="hfProductId" runat="server" ClientIDMode="Static" />

        <div class="page">
            <div class="product-profile">
                <!-- Left: Gallery -->
                <section class="gallery">
                    <div class="main-image">
                        <asp:Image ID="mainImage" runat="server" ClientIDMode="Static" AlternateText="Product image" CssClass="mainImage" />
                        <div class="gallery-overlay" aria-hidden="false">
                            <div class="variant-label" id="galleryVariantLabel">&nbsp;</div>
                            <div style="display:flex; align-items:center; gap:8px;">
                                <div class="image-dots" id="galleryImageDots"></div>
                                <div class="image-counter" id="galleryImageCounter">&nbsp;</div>
                            </div>
                        </div>
                    </div>
                    <div class="thumbs" id="thumbs">
                        <asp:PlaceHolder ID="phThumbs" runat="server" />
                    </div>
                    
                </section>

                <!-- Right: Info -->
                <section class="info">
                    <h1 class="title"><asp:Literal ID="litTitle" runat="server" /></h1>

                   
                    <div class="rating-row">
                        <span class="sold"><asp:Literal ID="litSold" runat="server" /> Sold</span>
                        <asp:Literal ID="litSoldDebug" runat="server" Visible="false" />
                    </div>

                    <div class="price-box">
                        <div class="price-current"><asp:Literal ID="litPrice" runat="server" /></div>
                        
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

                  <div class="ingredients-section">
    <div class="ingredients-header">
        <i class="fas fa-flask"></i>
        <span>Ingredients</span>
    </div>
    <div id="ingredientsContainer"></div>
</div>
                </section>
            </div>

            <!-- Seller panel -->
           

            <!-- Charts Section - Moved below supplier section -->
            <div class="charts">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
                    <h2 class="section-title" style="margin: 0;">Sales Analytics</h2>
                    <div style="display: flex; gap: 10px;">
                        <button type="button" class="btn-pdf-report" onclick="generateAllVariantsPdf()" style="background-color: #a86d6a; box-shadow: 0 4px 12px rgba(33, 150, 243, 0.3); margin: 0;">
                            <i class="fas fa-file-pdf"></i>
                            <span>Print All Variants</span>
                        </button>
                        
                    </div>
                </div>
                
                <!-- Main Sales Chart -->
                <div class="chart-container">

                    <div class="chart-header">
                        <div class="chart-title-section">
                            <h3 class="chart-title">Sales Overview <span id="variantFocus" class="variant-active-label" style="display:none;"></span></h3>
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

                <!-- Sales Tables -->
                <div id="salesTables">
                    <h3>Sales Data Tables (<span id="tablesVariantLabel">All Variants</span>)</h3>
                    <div class="tables-flex">
                        <div class="sales-table-wrap"><table id="dailyTable" class="sales-table"></table></div>
                        <div class="sales-table-wrap"><table id="weeklyTable" class="sales-table"></table></div>
                        <div class="sales-table-wrap"><table id="monthlyTable" class="sales-table"></table></div>
                    </div>
                    
                    <!-- Weekly Breakdown Table -->
                    <div style="margin-top: 2rem;">
                        <h3 style="margin-bottom: 1rem;">Weekly Activity Breakdown</h3>
                        <div class="sales-table-wrap" style="max-width: 500px;">
                            <table class="sales-table">
                                <caption>Period Activity Summary</caption>
                                <thead>
                                    <tr>
                                        <th>Period</th>
                                        <th>Current</th>
                                        <th>Previous</th>
                                        <th>Diff</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>Mon</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                    <tr>
                                        <td>Tue</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                    <tr>
                                        <td>Wed</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                    <tr>
                                        <td>Thu</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                    <tr>
                                        <td>Fri</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                    <tr>
                                        <td>Sat</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                    <tr>
                                        <td>Sun</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td style="color:#666">0</td>
                                    </tr>
                                </tbody>
                                <tfoot>
                                    <tr>
                                        <td>Totals:</td>
                                        <td>0</td>
                                        <td>0</td>
                                        <td>0</td>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>
                    </div>



                    <!-- Package stock entries -->
<div class="package-stock-section" style="margin-top:18px;">
    <div class="ingredients-header">
        <i class="fas fa-box"></i>
        <span>Package Stock Entries</span>
    </div>
    <asp:Literal ID="litPackageStockEntries" runat="server" />
</div>
                </div>
            </div>
        </div>
        
        <!-- 🖨️ Print Options Modal -->
        <div id="printOptionsModal" class="print-modal-overlay">
            <div class="print-modal-container">
                <div class="print-modal-header">
                    <h2 class="print-modal-title">
                        <i class="fas fa-file-pdf"></i>
                        Print PDF Report
                    </h2>
                    <button class="print-modal-close" onclick="closePrintModal()">
                        <i class="fa fa-times"></i>
                    </button>
                </div>
                
                <div class="print-modal-body">
                    <div class="print-option-section">
                        <div class="print-option-title">Select Report Type</div>
                        
                        <!-- Option 1: Standard Periods -->
                        <div class="print-option-card" id="standardPeriodsOption" onclick="selectPrintOption('standard')">
                            <div class="print-option-label">
                                <i class="fas fa-calendar-alt" style="color: #ff5722;"></i>
                                Standard Periods
                            </div>
                            <p class="print-option-description">
                                Generate PDF with Daily, Weekly, and Monthly reports
                            </p>
                        </div>
                        
                        <!-- Option 2: Custom Date Range -->
                        <div class="print-option-card" id="customDateOption" onclick="selectPrintOption('custom')">
                            <div class="print-option-label">
                                <i class="fas fa-calendar-week" style="color: #ff5722;"></i>
                                Custom Date Range
                            </div>
                            <p class="print-option-description">
                                Generate PDF for a specific date range
                            </p>
                            
                            <!-- Date Range Inputs -->
                            <div id="dateRangeInputs" class="date-range-inputs">
                                <div class="date-input-group">
                                    <label class="date-input-label" for="startDate">
                                        <i class="fas fa-calendar-day"></i> Start Date
                                    </label>
                                    <input type="date" id="startDate" class="date-input" />
                                </div>
                                
                                <div class="date-input-group">
                                    <label class="date-input-label" for="endDate">
                                        <i class="fas fa-calendar-check"></i> End Date
                                    </label>
                                    <input type="date" id="endDate" class="date-input" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="print-modal-footer">
                    <button type="button" class="print-modal-btn print-modal-btn-secondary" onclick="closePrintModal()">
                        <i class="fa fa-times"></i>
                        <span>Cancel</span>
                    </button>
                    <button type="button" class="print-modal-btn print-modal-btn-primary" id="btnGeneratePDF" onclick="generatePdfFromModal()">
                        <i class="fas fa-file-pdf"></i>
                        <span>Generate PDF</span>
                    </button>
                </div>
            </div>
        </div>


        <!-- 🖨️ Print All Variants Modal -->
<!-- 🖨️ Print All Variants Modal -->
<div id="printAllVariantsModal" class="print-modal-overlay">
    <div class="print-modal-container">
        <div class="print-modal-header" style="background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);">
            <h2 class="print-modal-title">
                <i class="fas fa-file-pdf"></i>
                Print All Variants Report
            </h2>
            <button class="print-modal-close" onclick="closeAllVariantsModal()">
                <i class="fa fa-times"></i>
            </button>
        </div>
        
        <div class="print-modal-body">
            <div class="print-option-section">
                <div class="print-option-title">Select Report Type</div>
                
                <!-- Option 1: Standard Periods -->
                <div class="print-option-card selected" id="allVariantsStandardOption" onclick="selectAllVariantsPrintOption('standard')">
                    <div class="print-option-label">
                        <i class="fas fa-calendar-alt" style="color: #2196F3;"></i>
                        Standard Periods
                    </div>
                    <p class="print-option-description">
                        Generate PDF with Daily, Weekly, and Monthly reports for all variants
                    </p>
                </div>
                
                <!-- Option 2: Custom Date Range -->
                <div class="print-option-card" id="allVariantsCustomOption" onclick="selectAllVariantsPrintOption('custom')">
                    <div class="print-option-label">
                        <i class="fas fa-calendar-week" style="color: #2196F3;"></i>
                        Custom Date Range
                    </div>
                    <p class="print-option-description">
                        Generate PDF for all variants in a specific date range
                    </p>
                    
                    <!-- Date Range Inputs -->
                    <div id="allVariantsDateRangeInputs" class="date-range-inputs">
                        <div class="date-input-group">
                            <label class="date-input-label" for="allVariantsStartDate">
                                <i class="fas fa-calendar-day"></i> Start Date
                            </label>
                            <input type="date" id="allVariantsStartDate" class="date-input" />
                        </div>
                        
                        <div class="date-input-group">
                            <label class="date-input-label" for="allVariantsEndDate">
                                <i class="fas fa-calendar-check"></i> End Date
                            </label>
                            <input type="date" id="allVariantsEndDate" class="date-input" />
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="print-modal-footer">
            <button type="button" class="print-modal-btn print-modal-btn-secondary" onclick="closeAllVariantsModal()">
                <i class="fa fa-times"></i>
                <span>Cancel</span>
            </button>
            <button type="button" class="print-modal-btn print-modal-btn-primary" id="btnGenerateAllVariantsPDF" onclick="generateAllVariantsPdfFromModal()" style="background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%); box-shadow: 0 4px 15px rgba(33, 150, 243, 0.3);">
                <i class="fas fa-file-pdf"></i>
                <span>Generate PDF</span>
            </button>
        </div>
    </div>
</div>
    </form>



    <!-- Image Lightbox Modal -->
    <div id="imgLightboxModal" style="display:none; position:fixed; z-index:99999; left:0; top:0; width:100vw; height:100vh; background:rgba(0,0,0,0.85); align-items:center; justify-content:center;">
        <span id="imgLightboxClose" style="position:absolute; top:30px; right:40px; color:#fff; font-size:2.5rem; cursor:pointer; z-index:1001;">&times;</span>
        <img id="imgLightboxImg" src="" alt="Preview" style="max-width:90vw; max-height:90vh; border-radius:12px; box-shadow:0 8px 32px #0008; display:block; margin:auto;" />
    </div>

    <script type="text/javascript">
    // ===== BEGIN SAFE (ES5) SCRIPT BLOCK =====
    (function(){
        var salesChartInstance = null;
        var variantChartInstance = null;
        var currentPeriod = 'daily';
        var chartData = null;
        var currentVariantId = null;
        var currentVariantName = '';

        function log(){ try{ if(window.console && console.log) console.log.apply(console, arguments);}catch(_){} }

        document.addEventListener('DOMContentLoaded', function(){
            log('[ProductProfile] DOMContentLoaded');
            loadChartData();
            setupPeriodSelectors();
            setTimeout(initializeCharts, 120);
            var printBtn = document.getElementById('btnPrintReport');
            if(printBtn){ printBtn.addEventListener('click', function(e){ e.preventDefault(); generateProductSalesPdf(); }); }
            document.addEventListener('click', onVariantClick, false);
        });

        function onVariantClick(e){
            var t = e.target || e.srcElement;
            if(!t || !('className' in t)) return;
            if((' '+t.className+' ').indexOf(' variant-btn ') === -1) return;
            var btns = document.querySelectorAll('.variant-btn');
            for(var i=0;i<btns.length;i++) btns[i].classList.remove('active');
            t.classList.add('active');
            currentVariantId = t.getAttribute('data-variant-id');
            currentVariantName = (t.textContent || t.innerText || '').replace(/\s+/g,' ').trim();
            updateVariantFocusLabel();
            refreshAll();
            rebuildAllTables();
        }

        // New function to generate PDF for a specific variant - EXPOSE GLOBALLY
        function generateVariantPdf(variantId, variantName){
            log('[generateVariantPdf]', variantId, variantName);
            
            // Set current variant context
            currentVariantId = variantId;
            currentVariantName = variantName;
            
            // Update UI to show this variant is selected
            var btns = document.querySelectorAll('.variant-btn');
            for(var i=0;i<btns.length;i++){
                var btn = btns[i];
                if(btn.getAttribute('data-variant-id') === variantId){
                    btn.classList.add('active');
                } else {
                    btn.classList.remove('active');
                }
            }
            
            updateVariantFocusLabel();
            refreshAll();
            rebuildAllTables();
            
            // Wait a moment for charts to render, then generate PDF
            setTimeout(function(){
                generateProductSalesPdf();
            }, 500);
        }
        
        // ⭐ EXPOSE generateVariantPdf GLOBALLY so inline onclick handlers can call it
        window.generateVariantPdf = generateVariantPdf;

        function updateVariantFocusLabel(){
            var span = document.getElementById('variantFocus');
            if(span){
                if(currentVariantId){ span.style.display='inline-block'; span.innerHTML = escapeHtml(currentVariantName); }
                else { span.style.display='none'; span.innerHTML=''; }
            }
            var label = document.getElementById('tablesVariantLabel');
            if(label) label.innerHTML = currentVariantId? escapeHtml(currentVariantName) : 'All Variants';
        }

        function escapeHtml(s){ if(!s) return ''; return s.replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\'':'&#39;'}[c]; }); }

        function loadChartData(){
            try {
                var hf = document.getElementById('<%= hfChartData.ClientID %>');
                if(hf && hf.value){ chartData = JSON.parse(hf.value); }
            } catch(ex){ log('chartData parse failed', ex); }
            if(!chartData) chartData = getFallbackData();
        }

        function getFallbackData(){
            return { daily:{labels:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],current:[5,8,6,12,15,9,7],previous:[4,6,5,9,11,7,5]}, weekly:{labels:['Week 1','Week 2','Week 3','Week 4'],current:[45,52,38,61],previous:[38,44,32,48]}, monthly:{labels:['Jan','Feb','Mar'],current:[180,220,195],previous:[165,190,175]}, variants:{labels:['Standard','Premium','Deluxe'],data:[45,30,25]}, variantDetails:{} };
        }

        function normalizeChartDataStructure(){
            if(!chartData) return; 
            function norm(p){
                if(!p) return {labels:[],current:[],previous:[]};
                return { labels: p.labels||p.Labels||[], current: p.current||p.Current||[], previous: p.previous||p.Previous||[] };
            }
            chartData.daily = norm(chartData.daily);
            chartData.weekly = norm(chartData.weekly);
            chartData.monthly = norm(chartData.monthly);
            var v = chartData.variants || {};
            chartData.variants = { labels: v.labels||v.Labels||[], data: v.data||v.Data||[] };
            if(chartData.variantDetails){
                var vd = {}; var k;
                for(k in chartData.variantDetails){ if(!chartData.variantDetails.hasOwnProperty(k)) continue; var it = chartData.variantDetails[k]; vd[k] = { daily: norm(it.daily||it.Daily), weekly: norm(it.weekly||it.Weekly), monthly: norm(it.monthly||it.Monthly) }; }
                chartData.variantDetails = vd;
            } else { chartData.variantDetails = {}; }
        }

        function getActiveData(){
            if(currentVariantId && chartData.variantDetails && chartData.variantDetails[currentVariantId]) return chartData.variantDetails[currentVariantId];
            return { daily:chartData.daily, weekly:chartData.weekly, monthly:chartData.monthly };
        }

        function initializeCharts(){ if(!chartData) return; normalizeChartDataStructure(); initializeSalesChart(); initializeVariantChart(); updateGrowthIndicator(); rebuildAllTables(); }

        function initializeSalesChart(){
            var ctx = document.getElementById('salesChart'); if(!ctx) return;
            var active = getActiveData(); var data = active[currentPeriod]; if(!data) return;
            if(salesChartInstance){ try{ salesChartInstance.destroy(); }catch(ex){} }
            salesChartInstance = new Chart(ctx, {
                type:'line',
                data:{ labels:data.labels, datasets:[
                    { label:'Last Year', data:data.previous, borderColor:'#4CAF50', backgroundColor:'rgba(76,175,80,.1)', tension:0.4, fill:true, pointBackgroundColor:'#4CAF50', pointBorderColor:'#fff', pointBorderWidth:2, pointRadius:4, pointHoverRadius:6 },
                    { label:'Current Period', data:data.current, borderColor:'#2196F3', backgroundColor:'rgba(33,150,243,.1)', tension:0.4, fill:true, pointBackgroundColor:'#2196F3', pointBorderColor:'#fff', pointBorderWidth:2, pointRadius:4, pointHoverRadius:6 }
                ]},
                options:{ responsive:true, maintainAspectRatio:false, interaction:{ intersect:false, mode:'index' }, scales:{ y:{ beginAtZero:true, grid:{color:'#f0f0f0'}, ticks:{ callback:function(v){ return formatNumber(v); } } }, x:{ grid:{display:false} } }, plugins:{ legend:{display:false}, tooltip:{ callbacks:{ label:function(c){ return c.dataset.label+': '+formatNumber(c.parsed.y); } } } } }
            });
        }

        function initializeVariantChart(){
            var canvas = document.getElementById('variantChart'); if(!canvas) return;
            var vRaw = chartData.variants || {}; var labels = vRaw.labels||[]; var values = vRaw.data||[]; if(!labels.length || !values.length) return;
            if(variantChartInstance){ try{ variantChartInstance.destroy(); }catch(ex){} }
            variantChartInstance = new Chart(canvas.getContext('2d'), {
                type:'doughnut',
                data:{ labels:labels, datasets:[{ data:values, backgroundColor:['#2196F3','#4CAF50','#FF9800','#9C27B0','#F44336','#607D8B'], borderWidth:0, hoverOffset:4 }]},
                options:{ responsive:true, maintainAspectRatio:false, cutout:'60%', plugins:{ legend:{ position:'bottom', labels:{ usePointStyle:true, padding:16 } }, tooltip:{ callbacks:{ label:function(c){ var total=0; for(var i=0;i<c.chart.data.datasets[0].data.length;i++) total+=c.chart.data.datasets[0].data[i]; var val=c.parsed; var pct = total? ((val/total)*100).toFixed(1):'0.0'; return (c.label||'')+': '+val+' ('+pct+'%)'; } } } } }
            });
        }

        function setupPeriodSelectors(){
            var btns = document.querySelectorAll('.period-btn');
            for(var i=0;i<btns.length;i++) (function(b){ b.addEventListener('click', function(e){ e.preventDefault(); var p = b.getAttribute('data-period'); if(!p || p===currentPeriod) return; for(var j=0;j<btns.length;j++) btns[j].classList.remove('active'); b.classList.add('active'); currentPeriod=p; refreshAll(); }); })(btns[i]);
        }

        function updateGrowthIndicator(){ normalizeChartDataStructure(); var active=getActiveData(); var d=active[currentPeriod]; if(!d) return; var cur=sumArray(d.current); var prev=sumArray(d.previous); var growth=0; if(prev>0) growth=((cur-prev)/prev*100); else if(prev===0 && cur>0) growth=100; var indicator=document.getElementById('growthIndicator'); if(!indicator) return; var positive=growth>=0; indicator.style.color=positive?'#4CAF50':'#f44336'; var text=(cur===0 && prev===0)?'No recent data':Math.abs(growth).toFixed(1)+'%'; indicator.innerHTML='<i class="fas fa-arrow-'+(positive?'up':'down')+'"></i> <span id="growthPercentage">'+text+'</span> vs last period'; }

        function sumArray(arr){ var t=0; if(!arr) return 0; for(var i=0;i<arr.length;i++) t+= Number(arr[i]||0); return t; }

        function refreshAll(){ initializeSalesChart(); updateGrowthIndicator(); }

        function formatNumber(n){ n=Number(n)||0; if(n>=1000000) return (n/1000000).toFixed(1)+'M'; if(n>=1000) return (n/1000).toFixed(1)+'K'; return ''+n; }

        function rebuildAllTables(){
            var active=getActiveData();
            buildTable('dailyTable','Daily (7 days)', active.daily);
            buildTable('weeklyTable','Weekly (4 weeks)', active.weekly);
            buildTable('monthlyTable','Monthly (3 months)', active.monthly);
        }

        function buildTable(id, caption, period){
            var tbl=document.getElementById(id); if(!tbl) return;
            var labels=period.labels||[]; var cur=period.current||[]; var prev=period.previous||[];
            var html='<caption>'+caption+'</caption><thead><tr><th>Period</th><th>Current</th><th>Previous</th><th>&#916;</th></tr></thead><tbody>';
            var totalC=0,totalP=0;
            for(var i=0;i<labels.length;i++){
                var c=Number(cur[i]||0); var p=Number(prev[i]||0); totalC+=c; totalP+=p;
                var diff=c-p;
                html+='<tr><td>'+labels[i]+'</td><td>'+c+'</td><td>'+p+'</td><td style="color:'+(diff>0?'#4CAF50':(diff<0?'#f44336':'#666'))+'">'+(diff>0?'+':'')+diff+'</td></tr>';
            }
            html+='</tbody><tfoot><tr><td>Total</td><td>'+totalC+'</td><td>'+totalP+'</td><td>'+(totalC-totalP>0?'+':'')+(totalC-totalP)+'</td></tr></tfoot>';
            tbl.innerHTML=html;
        }

        function ensureJsPdfLoaded(){ return new Promise(function(resolve,reject){ if(window.jspdf && window.jspdf.jsPDF){ resolve(window.jspdf.jsPDF); return;} var s=document.getElementById('jsPdfScript'); if(!s){ s=document.createElement('script'); s.id='jsPdfScript'; s.src='https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js'; document.head.appendChild(s);} s.addEventListener('load', function(){ if(window.jspdf && window.jspdf.jsPDF) resolve(window.jspdf.jsPDF); else reject('jsPDF not available after load');}); s.addEventListener('error', function(){ reject('jsPDF load error');}); setTimeout(function(){ if(window.jspdf && window.jspdf.jsPDF) resolve(window.jspdf.jsPDF); }, 2000); }); }

        function generateProductSalesPdf(){
            ensureJsPdfLoaded().then(function(JS){
                try {
                    // Capture product name once (from page title literal)
                    var productNameEl = document.querySelector('.title');
                    var productName = productNameEl ? (productNameEl.textContent||'').trim() : '';
                    if(!productName){ try{ productName = document.getElementById('variantFocus')?.textContent.trim() || ''; }catch(_){} }

                    normalizeChartDataStructure(); var active = getActiveData(); var doc = new JS('p','pt','a4'); var periods=[{k:'daily',title:'Daily'},{k:'weekly',title:'Weekly'},{k:'monthly',title:'Monthly'}]; var first=true; var i;
                    function sleep(ms){ return new Promise(function(r){ setTimeout(r,ms);}); }
                    var seq = Promise.resolve();
                    periods.forEach(function(pr){
                        seq = seq.then(function(){ 
                            currentPeriod=pr.k; 
                            initializeSalesChart(); 
                            updateGrowthIndicator(); 
                            return sleep(200).then(function(){ 
                                var img; 
                                try{ img=salesChartInstance.toBase64Image(); }catch(ex){ log('toBase64Image fail', ex); }
                                
                                if(!first) doc.addPage(); 
                                first=false; 
                                
                                // Product name header
                                doc.setFontSize(14); 
                                if(productName){ doc.text(productName,40,30); }
                                
                                // Period title
                                doc.setFontSize(16); 
                                var headingY = productName?50:40; 
                                doc.text('Product Sales - '+pr.title + (currentVariantName? (' ('+currentVariantName+')') : ''),40,headingY); 
                                
                                // Chart image
                                if(img) doc.addImage(img,'PNG',40,headingY+15,515,250); 
                                
                                // Prepare table data
                                var d=active[pr.k]; 
                                var labels=d.labels||[], cur=d.current||[], prev=d.previous||[];
                                var tableData = [];
                                var totalC=0, totalP=0;
                                
                                for(i=0;i<labels.length;i++){ 
                                    var c=Number(cur[i]||0), p=Number(prev[i]||0), diff=c-p; 
                                    totalC+=c; 
                                    totalP+=p;
                                    tableData.push([
                                        labels[i], 
                                        c.toString(), 
                                        p.toString(), 
                                        (diff>0?'+':'')+diff.toString()
                                    ]);
                                }
                                
                                var totalDiff=totalC-totalP;
                                
                                // Add totals row
                                tableData.push([
                                    'Totals:', 
                                    totalC.toString(), 
                                    totalP.toString(), 
                                    (totalDiff>0?'+':'')+totalDiff.toString()
                                ]);
                                
                                // Generate table using autoTable if available, otherwise fall back to basic text
                                var tableY = (img?(headingY+280):(headingY+40));
                                
                                if(typeof doc.autoTable === 'function'){
                                    // Use autoTable plugin for professional table
                                    doc.autoTable({
                                        head: [['Period', 'Current', 'Previous', 'Diff']],
                                        body: tableData,
                                        startY: tableY,
                                        margin: { left: 40 },
                                        theme: 'grid',
                                        styles: { 
                                            fontSize: 10,
                                            cellPadding: 3
                                        },
                                        headStyles: { 
                                            fillColor: [245, 245, 245],
                                            textColor: [0, 0, 0],
                                            fontStyle: 'bold',
                                            lineWidth: 0.5,
                                            lineColor: [224, 224, 224]
                                        },
                                        bodyStyles: {
                                            lineWidth: 0.5,
                                            lineColor: [224, 224, 224]
                                        },
                                        columnStyles: {
                                            0: { cellWidth: 80 },  // Period column
                                            1: { cellWidth: 60, halign: 'right' },  // Current column
                                            2: { cellWidth: 60, halign: 'right' },  // Previous column
                                            3: { cellWidth: 60, halign: 'right' }   // Diff column
                                        },
                                        didParseCell: function(data) {
                                            // Style the totals row
                                            if (data.row.index === tableData.length - 1) {
                                                data.cell.styles.fillColor = [250, 250, 250];
                                                data.cell.styles.fontStyle = 'bold';
                                            }
                                            
                                            // Color code the diff column
                                            if (data.column.index === 3 && data.row.index < tableData.length - 1) {
                                                var diffValue = parseInt(data.cell.text[0]);
                                                if (diffValue > 0) {
                                                    data.cell.styles.textColor = [76, 175, 80]; // Green
                                                } else if (diffValue < 0) {
                                                    data.cell.styles.textColor = [244, 67, 54]; // Red
                                                } else {
                                                    data.cell.styles.textColor = [102, 102, 102]; // Gray
                                                }
                                            }
                                        }
                                    });
                                } else {
                                    // Fallback to basic text rendering
                                    doc.setFontSize(10); 
                                    doc.text('Period  Current  Previous  Diff',40,tableY); 
                                    tableY+=12; 
                                    for(i=0;i<tableData.length;i++){ 
                                        var row = tableData[i];
                                        doc.text(row[0]+padSpaces(row[0],12)+'  '+row[1]+'  '+row[2]+'  '+row[3],40,tableY); 
                                        tableY+=12; 
                                    }
                                }
                            }); 
                        });
                    });
                    seq.then(function(){ 
                        var safeName = productName? productName.replace(/[^A-Za-z0-9 _-]/g,'').replace(/\s+/g,'_')+'_' : ''; 
                        var fileName='ProductSalesReport_'+ safeName +(currentVariantName?currentVariantName.replace(/\s+/g,'_')+'_':'')+new Date().toISOString().slice(0,10)+'.pdf'; 
                        doc.save(fileName); 
                    }).catch(function(e){ alert('PDF build error: '+e); });
                } catch(err){ alert('PDF error: '+err); }
            }).catch(function(err){ alert('Unable to load PDF library: '+err); });
        }

        function padSpaces(str, target){ // naive padding for PDF alignment
            var s=''; var needed = Math.max(0, target - (str?str.length:0)); for(var i=0;i<needed;i++) s+=' '; return s; }
        
        // ===== PRINT MODAL FUNCTIONS =====
        var selectedPrintOption = 'standard';
        
        window.openPrintModal = function(){
            var modal = document.getElementById('printOptionsModal');
            if(modal){
                modal.classList.add('show');
                document.body.style.overflow = 'hidden';
                
                // Set default option
                selectPrintOption('standard');
                
                // Set default dates (last 30 days)
                var today = new Date();
                var thirtyDaysAgo = new Date();
                thirtyDaysAgo.setDate(today.getDate() - 30);
                
                document.getElementById('endDate').valueAsDate = today;
                document.getElementById('startDate').valueAsDate = thirtyDaysAgo;
            }
        };
        
        window.closePrintModal = function(){
            var modal = document.getElementById('printOptionsModal');
            if(modal){
                modal.classList.remove('show');
                document.body.style.overflow = '';
            }
        };
        
        window.selectPrintOption = function(option){
            selectedPrintOption = option;
            
            var standardCard = document.getElementById('standardPeriodsOption');
            var customCard = document.getElementById('customDateOption');
            var dateInputs = document.getElementById('dateRangeInputs');
            
            if(standardCard) standardCard.classList.remove('selected');
            if(customCard) customCard.classList.remove('selected');
            if(dateInputs) dateInputs.classList.remove('show');
            
            if(option === 'standard' && standardCard){
                standardCard.classList.add('selected');
            } else if(option === 'custom'){
                if(customCard) customCard.classList.add('selected');
                if(dateInputs) dateInputs.classList.add('show');
            }
        };
        
        window.generatePdfFromModal = function(){
            var btn = document.getElementById('btnGeneratePDF');
            if(!btn) return;
            
            // Validate custom date range if selected
            if(selectedPrintOption === 'custom'){
                var startDate = document.getElementById('startDate').value;
                var endDate = document.getElementById('endDate').value;
                
                if(!startDate || !endDate){
                    alert('Please select both start and end dates.');
                    return;
                }
                
                var start = new Date(startDate);
                var end = new Date(endDate);
                
                if(start > end){
                    alert('Start date must be before end date.');
                    return;
                }
                
                // Show loading state
                btn.disabled = true;
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span> Generating...</span>';
                
                // Generate custom date range PDF
                setTimeout(function(){
                    generateCustomDateRangePdf(start, end);
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-file-pdf"></i><span>Generate PDF</span>';
                    closePrintModal();
                }, 500);
            } else {
                // Generate standard periods PDF
                btn.disabled = true;
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span> Generating...</span>';
                
                setTimeout(function(){
                    generateProductSalesPdf();
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-file-pdf"></i><span>Generate PDF</span>';
                    closePrintModal();
                }, 500);
            }
        };
        
        function generateCustomDateRangePdf(startDate, endDate){
            ensureJsPdfLoaded().then(function(JS){
                try {
                    var productNameEl = document.querySelector('.title');
                    var productName = productNameEl ? (productNameEl.textContent||'').trim() : '';
                    
                    var doc = new JS('p','pt','a4');
                    var pageHeight = doc.internal.pageSize.height;
                    var pageWidth = doc.internal.pageSize.width;
                    var margin = 40;
                    
                    // Format dates for display
                    var startStr = formatDate(startDate);
                    var endStr = formatDate(endDate);
                    
                    // ========== PAGE 1: Overview with Chart ==========
                    // Product name header
                    doc.setFontSize(14);
                    if(productName){ doc.text(productName, margin, 30); }
                    
                    // Date range title
                    doc.setFontSize(16);
                    var headingY = productName ? 50 : 40;
                    doc.text('Sales Report: ' + startStr + ' to ' + endStr, margin, headingY);
                    if(currentVariantName){
                        doc.setFontSize(12);
                        doc.text('Variant: ' + currentVariantName, margin, headingY + 15);
                        headingY += 15;
                    }
                    
                    // Get sales data for the date range
                    var tableData = generateCustomRangeTableData(startDate, endDate);
                    
                    // Calculate statistics
                    var totalSales = 0;
                    var maxSales = 0;
                    var minSales = 999999;
                    var avgSales = 0;
                    var goodDaysCount = 0;
                    
                    for(var i = 0; i < tableData.length; i++){
                        var sales = parseInt(tableData[i][1]);
                        totalSales += sales;
                        if(sales > maxSales) maxSales = sales;
                        if(sales < minSales) minSales = sales;
                        if(sales > 50) goodDaysCount++;
                    }
                    avgSales = tableData.length > 0 ? Math.round(totalSales / tableData.length) : 0;
                    
                    // Create a temporary canvas for the chart
                    var chartCanvas = document.createElement('canvas');
                    chartCanvas.width = 800;
                    chartCanvas.height = 400;
                    chartCanvas.style.display = 'none';
                    document.body.appendChild(chartCanvas);
                    
                    // Prepare chart data (group by weeks if more than 30 days)
                    var daysDiff = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
                    var chartLabels = [];
                    var chartValues = [];
                    
                    if(daysDiff <= 30){
                        // Show daily data
                        for(var i = 0; i < tableData.length; i++){
                            var dateStr = tableData[i][0];
                            // Shorten date format for chart
                            var dateParts = dateStr.split('/');
                            chartLabels.push(dateParts[0] + '/' + dateParts[1]);
                            chartValues.push(parseInt(tableData[i][1]));
                        }
                    } else {
                        // Group by weeks
                        var weekData = {};
                        for(var i = 0; i < tableData.length; i++){
                            var dateStr = tableData[i][0];
                            var weekNum = Math.floor(i / 7) + 1;
                            var weekKey = 'Week ' + weekNum;
                            if(!weekData[weekKey]) weekData[weekKey] = 0;
                            weekData[weekKey] += parseInt(tableData[i][1]);
                        }
                        for(var week in weekData){
                            if(weekData.hasOwnProperty(week)){
                                chartLabels.push(week);
                                chartValues.push(weekData[week]);
                            }
                        }
                    }
                    
                    // Create chart
                    var tempChart = new Chart(chartCanvas.getContext('2d'), {
                        type: 'bar',
                        data: {
                            labels: chartLabels,
                            datasets: [{
                                label: 'Sales',
                                data: chartValues,
                                backgroundColor: '#2196F3',
                                borderColor: '#1976D2',
                                borderWidth: 1
                            }]
                        },
                        options: {
                            responsive: false,
                            animation: false,
                            plugins: {
                                legend: { display: false },
                                title: {
                                    display: true,
                                    text: 'Sales Trend',
                                    font: { size: 16, weight: 'bold' }
                                }
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    grid: { color: '#f0f0f0' }
                                },
                                x: {
                                    grid: { display: false }
                                }
                            }
                        }
                    });
                    
                    // Wait for chart to render then add to PDF
                    setTimeout(function(){
                        try {
                            var chartImg = tempChart.toBase64Image();
                            
                            // Add chart to PDF
                            var chartY = headingY + 30;
                            doc.addImage(chartImg, 'PNG', margin, chartY, pageWidth - (margin * 2), 200);
                            
                            // Add summary statistics below chart
                            var statsY = chartY + 220;
                            doc.setFontSize(14);
                            doc.setFont(undefined, 'bold');
                            doc.text('Summary Statistics', margin, statsY);
                            
                            doc.setFontSize(10);
                            doc.setFont(undefined, 'normal');
                            statsY += 20;
                            
                            // Create summary box
                            doc.setFillColor(245, 245, 245);
                            doc.rect(margin, statsY - 8, pageWidth - (margin * 2), 80, 'F');
                            
                            doc.text('Total Days: ' + daysDiff, margin + 10, statsY + 5);
                            doc.text('Total Sales: ' + totalSales, margin + 10, statsY + 20);
                            doc.text('Average Sales/Day: ' + avgSales, margin + 10, statsY + 35);
                            doc.text('Highest Sales: ' + maxSales, margin + 10, statsY + 50);
                            doc.text('Lowest Sales: ' + minSales, margin + 10, statsY + 65);
                            
                            doc.text('Good Sales Days: ' + goodDaysCount + ' (' + Math.round((goodDaysCount/daysDiff)*100) + '%)', margin + 200, statsY + 5);
                            doc.text('Low Sales Days: ' + (daysDiff - goodDaysCount) + ' (' + Math.round(((daysDiff - goodDaysCount)/daysDiff)*100) + '%)', margin + 200, statsY + 20);
                            doc.text('Generated: ' + new Date().toLocaleString(), margin + 200, statsY + 50);
                            
                            // ========== PAGE 2+: Detailed Table ==========
                            doc.addPage();
                            
                            doc.setFontSize(14);
                            doc.setFont(undefined, 'bold');
                            doc.text('Detailed Daily Sales Data', margin, 40);
                            
                            if(typeof doc.autoTable === 'function'){
                                doc.autoTable({
                                    head: [['Date', 'Sales', 'Notes']],
                                    body: tableData,
                                    startY: 55,
                                    margin: { left: margin, right: margin },
                                    theme: 'grid',
                                    styles: { 
                                        fontSize: 9,
                                        cellPadding: 4
                                    },
                                    headStyles: { 
                                        fillColor: [33, 150, 243],
                                        textColor: [255, 255, 255],
                                        fontStyle: 'bold',
                                        lineWidth: 0.5,
                                        lineColor: [224, 224, 224]
                                    },
                                    bodyStyles: {
                                        lineWidth: 0.5,
                                        lineColor: [224, 224, 224]
                                    },
                                    columnStyles: {
                                        0: { cellWidth: 80 },
                                        1: { cellWidth: 60, halign: 'right' },
                                        2: { cellWidth: 'auto' }
                                    },
                                    didParseCell: function(data) {
                                        // Color code the sales column
                                        if (data.column.index === 1 && data.section === 'body') {
                                            var salesValue = parseInt(data.cell.text[0]);
                                            if (salesValue > 50) {
                                                data.cell.styles.textColor = [76, 175, 80]; // Green
                                                data.cell.styles.fontStyle = 'bold';
                                            } else {
                                                data.cell.styles.textColor = [244, 67, 54]; // Red
                                            }
                                        }
                                    },
                                    didDrawPage: function(data) {
                                        // Add footer with page numbers
                                        doc.setFontSize(8);
                                        doc.setTextColor(150);
                                        doc.text('Page ' + doc.internal.getNumberOfPages(), pageWidth - margin - 30, pageHeight - 20);
                                    }
                                });
                                
                                // Add totals summary after table
                                var finalY = doc.lastAutoTable.finalY + 20;
                                
                                // Check if we need a new page for totals
                                if(finalY > pageHeight - 100){
                                    doc.addPage();
                                    finalY = 50;
                                }
                                
                                doc.setFontSize(12);
                                doc.setFont(undefined, 'bold');
                                doc.text('Report Totals', margin, finalY);
                                
                                doc.setFontSize(10);
                                doc.setFont(undefined, 'normal');
                                finalY += 15;
                                
                                doc.setFillColor(255, 243, 224);
                                doc.rect(margin, finalY - 5, pageWidth - (margin * 2), 50, 'F');
                                doc.setDrawColor(255, 87, 34);
                                doc.setLineWidth(2);
                                doc.rect(margin, finalY - 5, pageWidth - (margin * 2), 50);
                                
                                doc.setFontSize(11);
                                doc.setFont(undefined, 'bold');
                                doc.text('Total Sales for Period: ' + totalSales, margin + 15, finalY + 10);
                                doc.text('Average per Day: ' + avgSales, margin + 15, finalY + 25);
                                doc.text('Performance: ' + (goodDaysCount > (daysDiff/2) ? 'Good ✓' : 'Needs Improvement'), margin + 15, finalY + 40);
                            }
                            
                            // Clean up
                            document.body.removeChild(chartCanvas);
                            if(tempChart) tempChart.destroy();
                            
                            var safeName = productName ? productName.replace(/[^A-Za-z0-9 _-]/g,'').replace(/\s+/g,'_')+'_' : '';
                            var fileName = 'CustomReport_' + safeName + startStr.replace(/\//g,'-') + '_to_' + endStr.replace(/\//g,'-') + '.pdf';
                            doc.save(fileName);
                            
                        } catch(chartErr){
                            log('Chart rendering error:', chartErr);
                            // Clean up on error
                            if(chartCanvas && chartCanvas.parentNode) document.body.removeChild(chartCanvas);
                            if(tempChart) tempChart.destroy();
                            alert('Chart generation error: ' + chartErr);
                        }
                    }, 500);
                    
                } catch(err){
                    alert('PDF generation error: ' + err);
                    log('PDF error:', err);
                }
            }).catch(function(err){
                alert('Unable to load PDF library: ' + err);
            });
        }
        
        function formatDate(date){
            var mm = String(date.getMonth() + 1).padStart(2, '0');
            var dd = String(date.getDate()).padStart(2, '0');
            var yyyy = date.getFullYear();
            return mm + '/' + dd + '/' + yyyy;
        }
        
        function generateCustomRangeTableData(startDate, endDate){
            // This is a placeholder. In production, you would fetch actual sales data from the server
            // for the specified date range via AJAX
            var tableData = [];
            var currentDate = new Date(startDate);
            
            while(currentDate <= endDate){
                var dateStr = formatDate(currentDate);
                var salesAmount = Math.floor(Math.random() * 100); // Random placeholder data
                tableData.push([
                    dateStr,
                    salesAmount.toString(),
                    salesAmount > 50 ? 'Good sales' : 'Low sales'
                ]);
                currentDate.setDate(currentDate.getDate() + 1);
            }
            
            return tableData;
        }
        
        // Update generateVariantPdf to use modal
        var originalGenerateVariantPdf = window.generateVariantPdf;
        window.generateVariantPdf = function(variantId, variantName){
            log('[generateVariantPdf] Opening print modal for variant:', variantId, variantName);
            
            // Set current variant context
            currentVariantId = variantId;
            currentVariantName = variantName;
            
            // Update UI to show this variant is selected
            var btns = document.querySelectorAll('.variant-btn');
            for(var i=0;i<btns.length;i++){
                var btn = btns[i];
                if(btn.getAttribute('data-variant-id') === variantId){
                    btn.classList.add('active');
                } else {
                    btn.classList.remove('active');
                }
            }
            
            updateVariantFocusLabel();
            refreshAll();
            rebuildAllTables();
            
            // Open print options modal instead of directly generating PDF
            setTimeout(function(){
                openPrintModal();
            }, 300);
        };

        // Lightbox logic
        function showLightbox(src) {
            var modal = document.getElementById('imgLightboxModal');
            var img = document.getElementById('imgLightboxImg');
            if (modal && img && src) {
                img.src = src;
                modal.style.display = 'flex';
            }
        }
        function hideLightbox() {
            var modal = document.getElementById('imgLightboxModal');
            if (modal) modal.style.display = 'none';
        }
        document.getElementById('imgLightboxClose').onclick = hideLightbox;
        document.getElementById('imgLightboxModal').onclick = function(e) {
            if (e.target === this) hideLightbox();
        };
        // Main image click
        var mainImg = document.getElementById('mainImage');
        if (mainImg) {
            mainImg.style.cursor = 'zoom-in';
            mainImg.onclick = function() {
                if (mainImg.src) showLightbox(mainImg.src);
            };
        }
        // Thumbnails click (variant images)
        var thumbs = document.getElementById('thumbs');
        if (thumbs) {
            thumbs.addEventListener('click', function(e) {
                var t = e.target;
                if (t && t.tagName && t.tagName.toLowerCase() === 'img' && t.src) {
                    e.preventDefault();
                    e.stopPropagation();
                    // Update main image src
                    var mainImg = document.getElementById('mainImage');
                    if (mainImg) {
                        mainImg.src = t.src;
                    }
                }
            });
        }

        function getProductIdFromPage() {
            console.log('🔍 getProductIdFromPage called');

            // Method 1: Get from hidden field (most reliable)
            var hfProductId = document.getElementById('hfProductId');
            if (hfProductId && hfProductId.value) {
                console.log('✅ Product ID from hidden field:', hfProductId.value);
                return hfProductId.value;
            }

            // Method 2: Parse from URL (fallback)
            var urlParams = new URLSearchParams(window.location.search);
            var productId = urlParams.get('productId') || urlParams.get('productid') || urlParams.get('id') || '';

            if (productId) {
                console.log('✅ Product ID from URL params:', productId);
                return productId;
            }

            // Method 3: Manual extraction from query string (last resort)
            var queryString = window.location.search;
            console.log('🔍 Full query string:', queryString);

            var match = queryString.match(/[?&]product[iI]d=([^&]+)/i);
            if (match && match[1]) {
                console.log('✅ Product ID from regex match:', match[1]);
                return match[1];
            }

            console.error('❌ Product ID not found anywhere!');
            return '';
        }
        
        // ===== GENERATE ALL VARIANTS PDF FUNCTION =====
        window.generateAllVariantsPdf = function () {
            console.log('🔍 generateAllVariantsPdf - Opening modal');

            // Open the modal instead of directly redirecting
            openAllVariantsModal();
        };

        // ===== GENERATE OVERALL PRODUCT PERFORMANCE PDF FUNCTION =====
        window.openOverallProductPerformanceModal = function () {
            var productId = getProductIdFromPage();

            console.log('🔍 openOverallProductPerformanceModal called');
            console.log('🔍 Product ID:', productId);

            if (!productId) {
                alert('Product ID not found. Please make sure you are viewing a product page.');
                console.error('❌ Product ID is empty!');
                return;
            }

            console.log('✅ Redirecting to Overall Performance PDF handler with product ID:', productId);

            // Redirect to the Overall Performance PDF handler
            window.location.href = '../Handlers/GenerateOverallProductPerformancePDF.ashx?productId=' + encodeURIComponent(productId);
        };

        var selectedAllVariantsPrintOption = 'standard';

        window.openAllVariantsModal = function () {
            var modal = document.getElementById('printAllVariantsModal');
            if (modal) {
                modal.classList.add('show');
                document.body.style.overflow = 'hidden';

                // Set default option
                selectAllVariantsPrintOption('standard');

                // Set default dates (last 30 days)
                var today = new Date();
                var thirtyDaysAgo = new Date();
                thirtyDaysAgo.setDate(today.getDate() - 30);

                var endDateInput = document.getElementById('allVariantsEndDate');
                var startDateInput = document.getElementById('allVariantsStartDate');

                if (endDateInput) endDateInput.valueAsDate = today;
                if (startDateInput) startDateInput.valueAsDate = thirtyDaysAgo;
            }
        };

        window.closeAllVariantsModal = function () {
            var modal = document.getElementById('printAllVariantsModal');
            if (modal) {
                modal.classList.remove('show');
                document.body.style.overflow = '';
            }
        };

        window.selectAllVariantsPrintOption = function (option) {
            selectedAllVariantsPrintOption = option;

            var standardCard = document.getElementById('allVariantsStandardOption');
            var customCard = document.getElementById('allVariantsCustomOption');
            var dateInputs = document.getElementById('allVariantsDateRangeInputs');

            if (standardCard) standardCard.classList.remove('selected');
            if (customCard) customCard.classList.remove('selected');
            if (dateInputs) dateInputs.classList.remove('show');

            if (option === 'standard' && standardCard) {
                standardCard.classList.add('selected');
            } else if (option === 'custom') {
                if (customCard) customCard.classList.add('selected');
                if (dateInputs) dateInputs.classList.add('show');
            }
        };

        window.generateAllVariantsPdfFromModal = function () {
            var btn = document.getElementById('btnGenerateAllVariantsPDF');
            if (!btn) return;

            var productId = getProductIdFromPage();

            if (!productId) {
                alert('Product ID not found. Please make sure you are viewing a product page.');
                console.error('❌ Product ID is empty!');
                return;
            }

            // Validate custom date range if selected
            if (selectedAllVariantsPrintOption === 'custom') {
                var startDate = document.getElementById('allVariantsStartDate').value;
                var endDate = document.getElementById('allVariantsEndDate').value;

                if (!startDate || !endDate) {
                    alert('Please select both start and end dates.');
                    return;
                }

                var start = new Date(startDate);
                var end = new Date(endDate);

                if (start > end) {
                    alert('Start date must be before end date.');
                    return;
                }

                // Show loading state
                btn.disabled = true;
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span> Generating...</span>';

                // Redirect with custom date range parameters
                var url = '../Handlers/GenerateAllVariantsPDF.ashx?productId=' + encodeURIComponent(productId) +
                    '&reportType=custom' +
                    '&startDate=' + encodeURIComponent(startDate) +
                    '&endDate=' + encodeURIComponent(endDate);

                console.log('✅ Redirecting to All Variants PDF handler (custom range):', url);

                setTimeout(function () {
                    window.location.href = url;
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-file-pdf"></i><span>Generate PDF</span>';
                    closeAllVariantsModal();
                }, 500);
            } else {
                // Show loading state
                btn.disabled = true;
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span> Generating...</span>';
                
                // Redirect with standard periods
                var url = '../Handlers/GenerateAllVariantsPDF.ashx?productId=' + encodeURIComponent(productId) +
                    '&reportType=standard';

                console.log('✅ Redirecting to All Variants PDF handler (standard periods):', url);

                setTimeout(function () {
                    window.location.href = url;
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-file-pdf"></i><span>Generate PDF</span>';
                    closeAllVariantsModal();
                }, 500);
            }
        };

        // ===== PRINT ALL VARIANTS MODAL FUNCTIONS =====
        function loadProductIngredients() {
            var productId = getProductIdFromPage();
            if (!productId) return;
            $.ajax({
                type: "POST",
                url: "../Handlers/GetProductIngredients.ashx",
                data: JSON.stringify({ productId: productId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    var container = document.getElementById('ingredientsContainer');
                    if (container) {
                        if (response.success && Array.isArray(response.ingredients)) {
                            container.innerHTML = response.ingredients.map(function (ing) {
                                return '<div class="ingredient-pill">' +
                                    '<span class="ingredient-name">' + ing.name + '</span>' +
                                    '<span>:</span>' +
                                    '<span class="ingredient-qty">' + ing.quantity + ' ' + ing.unit + '</span>' +
                                    '</div>';
                            }).join('');
                        } else {
                            container.textContent = 'No ingredients found.';
                        }
                    }
                },
                error: function () {
                    var container = document.getElementById('ingredientsContainer');
                    if (container) container.textContent = 'Error loading ingredients.';
                }
            });
        }

        document.addEventListener('DOMContentLoaded', function () { 
            loadProductIngredients(); 
        });
    })();
    </script>

    <!-- Replaced thumbnail click handler with slideshow-capable handler -->
<script type="text/javascript">
    (function(){
        // Slideshow state
        var slideshowTimer = null;
        var slideshowIndex = 0;
        var slideshowImages = [];
        var slideshowIntervalMs = 2500; // change image every 2.5s

        function stopSlideshow() {
            if (slideshowTimer) {
                clearInterval(slideshowTimer);
                slideshowTimer = null;
            }
            slideshowImages = [];
            slideshowIndex = 0;
        }

        function startSlideshowOnMain(images) {
            stopSlideshow();
            if (!images || !images.length) return;
            slideshowImages = images;
            slideshowIndex = 0;
            var mainImg = document.getElementById('mainImage');
            if (!mainImg) return;
            // show first immediately
            mainImg.src = resolveImageUrl(images[0]);
            if (images.length > 1) {
                slideshowTimer = setInterval(function(){
                    slideshowIndex = (slideshowIndex + 1) % slideshowImages.length;
                    mainImg.src = resolveImageUrl(slideshowImages[slideshowIndex]);
                }, slideshowIntervalMs);
            }
        }

        function resolveImageUrl(u){
            if(!u) return '';
            if(u.indexOf('data:')===0 || u.indexOf('http://')===0 || u.indexOf('https://')===0 || u.indexOf('//')===0) return u;
            return '/' + u.replace(/^\/+/, '');
        }

        // Helper to decode HTML entities then parse JSON safely
        function parseDataImagesAttr(attr) {
            if (!attr) return null;
            // decode HTML entities
            var ta = document.createElement('textarea');
            ta.innerHTML = attr;
            var decoded = ta.value;
            try {
                var parsed = JSON.parse(decoded);
                if (Array.isArray(parsed)) return parsed;
                return null;
            } catch (e) {
                // try fallback: attribute may already be a JS-looking array without quotes
                try { return eval(decoded); } catch(_) { return null; }
            }
        }

        var thumbs = document.getElementById('thumbs');
        if (thumbs) {
            thumbs.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();

                // Find the closest button thumb (may be the button or inside it an img)
                var btn = e.target.closest('button.thumb, button.variant-thumb');
                if (!btn) return;

                // Manage active styling
                var all = thumbs.querySelectorAll('button.thumb, button.variant-thumb');
                Array.prototype.forEach.call(all, function(b){ b.classList.remove('active'); });
                btn.classList.add('active');

                var data = btn.getAttribute('data-images');
                var images = parseDataImagesAttr(data);
                if (images && images.length > 0) {
                    // start slideshow using images array
                    startSlideshowOnMain(images);
                    return;
                }

                // Fallback: look for data-primary or an img child
                var primary = btn.getAttribute('data-primary');
                var mainImg = document.getElementById('mainImage');
                if (primary && mainImg) {
                    stopSlideshow();
                    mainImg.src = resolveImageUrl(primary);
                    return;
                }

                var img = btn.querySelector('img');
                if (img && img.src && mainImg) {
                    stopSlideshow();
                    mainImg.src = img.src;
                    return;
                }
            }, false);
        }
    })();
</script>
    <script type="text/javascript">
        document.addEventListener('DOMContentLoaded', function () {
            var firstThumb = document.querySelector('#thumbs button.thumb');
            if (firstThumb) {
                firstThumb.click();
            }
        });
</script>
</body>
</html>
