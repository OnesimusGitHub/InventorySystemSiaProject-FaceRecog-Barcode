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
                        <span class="sold"><asp:Literal ID="litSold" runat="server" /> Sold</span>
                        <asp:Literal ID="litSoldDebug" runat="server" Visible="false" />
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
                </div>
            </div>
        </div>
    </form>

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
    })();
    // ===== END SAFE SCRIPT BLOCK =====
    </script>
</body>
</html>
