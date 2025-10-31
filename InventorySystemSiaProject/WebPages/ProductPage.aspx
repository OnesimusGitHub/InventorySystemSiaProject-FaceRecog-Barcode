<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ProductPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductPage" Async="true" %>

<asp:Content ID="HeadContentProduct" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/ProductPage.css" rel="stylesheet" />
    <!-- Add jQuery CDN -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        .low-stock { color: #f44336; font-weight: bold; }
        .ready-stock { color: #4CAF50; }
        .moderate-stock { color: #ff9800; }
        .text-center { text-align: center; padding: 20px; }
        .loading { opacity: 0.7; }
        .preview-extra { margin-top: 10px; font-size: 11px; color: #aaa; }
        .error-container { 
            background: #fff; 
            border: 1px solid #f44336; 
            border-radius: 8px; 
            padding: 20px; 
            margin: 20px 0; 
            text-align: center; 
        }
        .success-container { 
            background: #fff; 
            border: 1px solid #4CAF50; 
            border-radius: 8px; 
            padding: 20px; 
            margin: 20px 0; 
            text-align: center; 
        }
        .thumb {
            background: #f0f0f0;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #999;
            font-size: 10px;
            width: 30px;
            height: 30px;
        }
        .selected {
            background-color: #e3f2fd !important;
        }
        .row-select:hover {
            background-color: #f5f5f5;
            cursor: pointer;
        }

        /* 💖 Beautiful Modal Styles with Animations 💖 */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.6);
            backdrop-filter: blur(8px);
            z-index: 1000;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            visibility: hidden;
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .modal-overlay.show {
            opacity: 1;
            visibility: visible;
        }

        .modal-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.2);
            max-width: 800px;
            width: 90%;
            max-height: 90vh;
            overflow: hidden;
            transform: scale(0.7) translateY(50px);
            transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
            position: relative;
        }

        .modal-overlay.show .modal-container {
            transform: scale(1) translateY(0);
        }

        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px 30px;
            position: relative;
            overflow: hidden;
        }

        .modal-header::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: linear-gradient(45deg, transparent, rgba(255,255,255,0.1), transparent);
            transform: rotate(45deg);
            animation: shimmer 3s infinite;
        }

        @keyframes shimmer {
            0% { transform: translateX(-100%) rotate(45deg); }
            100% { transform: translateX(100%) rotate(45deg); }
        }

        .modal-title {
            font-size: 24px;
            font-weight: 600;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 12px;
            position: relative;
            z-index: 1;
        }

        .modal-title i {
            font-size: 28px;
            animation: bounce 2s infinite;
        }

        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-8px); }
            60% { transform: translateY(-4px); }
        }

        .modal-close {
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
            z-index: 2;
        }
        #previewPanel {
            max-height: 90vh;
            overflow-y: auto;
            }
        .table-wrapper {
             max-height: 90vh;
          overflow-y: auto;
            }
        .modal-close:hover {
            background: rgba(255,255,255,0.3);
            transform: rotate(90deg) scale(1.1);
        }

        .modal-body { padding: 0; max-height: calc(90vh - 100px); overflow-y: auto; }
        .modal-nav { display: flex; background: #f8f9fa; border-bottom: 1px solid #e9ecef; }
        .nav-tab { flex: 1; padding: 20px; text-align: center; background: none; border: none; cursor: pointer; font-weight: 600; color: #6c757d; transition: all 0.3s ease; position: relative; overflow: hidden; }
        .nav-tab::before { content: ''; position: absolute; bottom: 0; left: 50%; width: 0; height: 3px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); transition: all 0.3s ease; transform: translateX(-50%); }
        .nav-tab.active { color: #667eea; background: white; }
        .nav-tab.active::before { width: 100%; }
        .nav-tab:hover:not(.active) { background: #e9ecef; color: #495057; }
        .tab-content { padding: 30px; min-height: 400px; }
        .tab-pane { display: none; animation: fadeInUp 0.5s ease-out; }
        .tab-pane.active { display: block; }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

        .form-row { display: flex; gap: 20px; margin-bottom: 20px; }
        .form-group { flex: 1; margin-bottom: 20px; }
        .form-label { display: block; margin-bottom: 8px; font-weight: 600; color: #333; font-size: 14px; }
        .form-control { width: 100%; padding: 12px 16px; border: 2px solid #e9ecef; border-radius: 10px; font-size: 14px; transition: all 0.3s ease; background: #fff; }
        .form-control:focus { transform: translateY(-3px); box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15); border-color: #667eea; }
        .form-control:hover { border-color: #c7d2fe; }
        .textarea-field { min-height: 100px; resize: vertical; }
        .variant-section { border: 2px dashed #e9ecef; border-radius: 15px; padding: 25px; margin-top: 30px; transition: all 0.3s ease; position: relative; overflow: hidden; }
        .variant-section::before { content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(102, 126, 234, 0.05), transparent); transition: left 0.6s ease; }
        .variant-section:hover::before { left: 100%; }
        .variant-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; position: relative; z-index: 1; }
        .variant-title { font-size: 18px; font-weight: 600; color: #333; display: flex; align-items: center; gap: 10px; }
        .variant-title i { color: #667eea; animation: pulse 2s infinite; }
        @keyframes pulse { 0% { transform: scale(1); } 50% { transform: scale(1.1); } 100% { transform: scale(1); } }
        .add-variant-btn { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 10px 20px; border-radius: 25px; cursor: pointer; font-weight: 600; display: flex; align-items: center; gap: 8px; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3); }
        .add-variant-btn:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4); }
        .variant-card { background: #f8f9fa; border: 1px solid #e9ecef; border-radius: 15px; padding: 20px; margin-bottom: 15px; position: relative; transition: all 0.3s ease; animation: slideInRight 0.5s ease-out; }
        @keyframes slideInRight { from { opacity: 0; transform: translateX(30px); } to { opacity: 1; transform: translateX(0); } }
        .variant-card:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0,0,0,0.1); }
        .variant-remove { position: absolute; top: 15px; right: 15px; background: #dc3545; color: white; border: none; width: 30px; height: 30px; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.3s ease; }
        .variant-remove:hover { background: #c82333; transform: rotate(90deg) scale(1.1); }
        .modal-footer { background: #f8f9fa; padding: 25px 30px; border-top: 1px solid #e9ecef; display: flex; gap: 15px; justify-content: flex-end; }
        .btn-animated { padding: 12px 30px; border-radius: 25px; border: none; font-weight: 600; cursor: pointer; transition: all 0.3s ease; display: flex; align-items: center; gap: 8px; position: relative; overflow: hidden; }
        .btn-animated::before { content: ''; position: absolute; top: 50%; left: 50%; width: 0; height: 0; background: rgba(255,255,255,0.3); border-radius: 50%; transition: all 0.3s ease; transform: translate(-50%, -50%); }
        .btn-animated:hover::before { width: 300px; height: 300px; }
        .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3); }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4); }
        .btn-success { background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%); color: white; box-shadow: 0 4px 15px rgba(86, 171, 47, 0.3); }
        .btn-success:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(86, 171, 47, 0.4); }
        .btn-secondary { background: #6c757d; color: white; }
        .btn-secondary:hover { background: #5a6268; transform: translateY(-2px); }
        .btn-danger { background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); color: white; box-shadow: 0 4px 15px rgba(220, 53, 69, 0.3); }
        .btn-danger:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(220, 53, 69, 0.4); }
        .modal-body::-webkit-scrollbar { width: 8px; }
        .modal-body::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 10px; }
        .modal-body::-webkit-scrollbar-thumb { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; }
        .modal-body::-webkit-scrollbar-thumb:hover { background: linear-gradient(135deg, #5a67d8 0%, #6b46c1 100%); }
        .loading-spinner { display: none; width: 20px; height: 20px; border: 2px solid transparent; border-top: 2px solid currentColor; border-radius: 50%; animation: spin 1s linear infinite; }
        .preview-image { position: relative; margin-bottom: 15px; border-radius: 10px; overflow: hidden; background: #f8f9fa; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1); transition: all 0.3s ease; }
        .preview-image:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15); }
        .preview-image img { width: 100%; height: 150px; object-fit: cover; border-radius: 8px; transition: all 0.3s ease; background: #f0f0f0; }
        .preview-image img:hover { transform: scale(1.02); }
        .preview-image.loading::after { content: 'Loading...'; position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: rgba(0, 0, 0, 0.7); color: white; padding: 8px 12px; border-radius: 4px; font-size: 12px; }
        .variants-list-modal { max-width: 900px; }
        .variants-toolbar { display:flex; justify-content:space-between; align-items:center; padding:16px 24px; border-bottom:1px solid #e9ecef; background:#fff; }
        .variants-toolbar .meta { color:#6c757d; font-size:13px; }
        .variants-table { width:100%; border-collapse:collapse; }
        .variants-table th, .variants-table td { padding:10px 12px; border-bottom:1px solid #f1f3f5; font-size:13px; }
        .variants-table th { text-align:left; color:#6c757d; background:#f8f9fa; position:sticky; top:0; z-index:1; }
        .status-pill { display:inline-block; padding:4px 10px; border-radius:999px; font-size:12px; font-weight:600; }
        .status-ok { background:#e8f5e9; color:#2e7d32; }
        .status-warn { background:#fff3cd; color:#856404; }
        .status-out { background:#fdecea; color:#c62828; }
        .col-sku, .product-table th.col-sku, .product-table td.col-sku { display:none !important; }

        #updateVariantModalVariant .modal-container { display:flex; flex-direction:column; }
        #updateVariantModalVariant .modal-body { flex:1; overflow-y:auto; max-height:calc(90vh - 150px); padding:30px; }
        #updateVariantModalVariant .modal-body::-webkit-scrollbar { width:8px; }
        #updateVariantModalVariant .modal-body::-webkit-scrollbar-track { background:#f1f1f1; border-radius:10px; }
        #updateVariantModalVariant .modal-body::-webkit-scrollbar-thumb { background: linear-gradient(135deg,#667eea 0%, #764ba2 100%); border-radius:10px; }
        #updateVariantModalVariant .modal-body::-webkit-scrollbar-thumb:hover { background: linear-gradient(135deg,#5a67d8 0%, #6b46c1 100%); }

        /* Update Variant Modal Scrollbar */
        #updateVariantModal .modal-container { display:flex; flex-direction:column; max-height:90vh; }
        #updateVariantModal .modal-body { flex:1; overflow-y:auto; max-height:calc(90vh - 180px); padding:30px; }
        #updateVariantModal .modal-body::-webkit-scrollbar { width:8px; }
        #updateVariantModal .modal-body::-webkit-scrollbar-track { background:#f1f1f1; border-radius:10px; }
        #updateVariantModal .modal-body::-webkit-scrollbar-thumb { background: linear-gradient(135deg,#667eea 0%, #764ba2 100%); border-radius:10px; }
        #updateVariantModal .modal-body::-webkit-scrollbar-thumb:hover { background: linear-gradient(135deg,#5a67d8 0%, #6b46c1 100%); }
        #updateVariantModal .modal-footer { flex-shrink:0; }

        #addVariantModal .modal-container { display:flex; flex-direction:column; }
        #addVariantModal .modal-body { flex:1; overflow-y:auto; max-height:calc(90vh - 150px); padding:30px; }

        /* Ensure Add Product modal keeps footer visible and content scrolls */
        #addProductModal .modal-container { display:flex; flex-direction:column; max-height:90vh; }
        #addProductModal .modal-body { flex:1; overflow-y:auto; max-height:none; padding:0; }
        #addProductModal .tab-content { padding:30px; }
        #addProductModal .modal-footer { flex-shrink:0; }

        /* 🔥 Delete Modal Specific Styles */
        #deleteProductModal .modal-header,
        #deleteVariantModal .modal-header {
            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
        }

        #deleteProductModal .modal-title i,
        #deleteVariantModal .modal-title i {
            animation: shake 2s infinite;
        }

        /* Ensure delete modals appear on top */
        #deleteProductModal,
        #deleteVariantModal {
            z-index: 1500 !important;
        }

        #deleteProductModal.show,
        #deleteVariantModal.show {
            display: flex !important;
            visibility: visible !important;
            opacity: 1 !important;
        }

        /* Force show modal container when modal is active */
        #deleteProductModal.show .modal-container,
        #deleteVariantModal.show .modal-container {
            transform: scale(1) translateY(0) !important;
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            10%, 30%, 50%, 70%, 90% { transform: translateX(-2px); }
            20%, 40%, 60%, 80% { transform: translateX(2px); }
        }

        /* 🎨 Beautiful Notification System */
        .notification-modal {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.4);
            backdrop-filter: blur(4px);
            z-index: 2000;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s ease;
        }

        .notification-modal.show {
            opacity: 1;
            visibility: visible;
        }

        .notification-container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
            max-width: 400px;
            width: 90%;
            overflow: hidden;
            transform: scale(0.8) translateY(20px);
            transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
            position: relative;
        }

        .notification-modal.show .notification-container {
            transform: scale(1) translateY(0);
        }

        .notification-header {
            padding: 24px;
            display: flex;
            align-items: flex-start;
            gap: 16px;
        }

        .notification-icon {
            width: 48px;
            height: 48px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            flex-shrink: 0;
            background: #4CAF50;
            color: white;
        }

        .notification-icon.error {
            background: #f44336;
        }

        .notification-icon.warning {
            background: #ff9800;
        }

        .notification-icon.info {
            background: #2196F3;
        }

        .notification-content {
            flex: 1;
        }

        .notification-title {
            margin: 0 0 8px 0;
            font-size: 18px;
            font-weight: 600;
            color: #333;
        }

        .notification-message {
            margin: 0;
            color: #666;
            line-height: 1.4;
        }

        .notification-footer {
            padding: 0 24px 24px 24px;
            display: flex;
            justify-content: flex-end;
            gap: 12px;
        }

        .btn-notification {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .btn-notification.primary {
            background: #4CAF50;
            color: white;
        }

        .btn-notification.primary:hover {
            background: #45a049;
            transform: translateY(-1px);
        }

        .btn-notification.secondary {
            background: #f5f5f5;
            color: #666;
        }

        .btn-notification.secondary:hover {
            background: #e0e0e0;
        }

        .notification-progress {
            position: absolute;
            bottom: 0;
            left: 0;
            height: 3px;
            background: #4CAF50;
            width: 0%;
            transition: width linear;
        }

        /* Auto-hide animation */
        .notification-modal.auto-hide .notification-progress {
            animation: progress-countdown linear;
        }

        @keyframes progress-countdown {
            from { width: 100%; }
            to { width: 0%; }
        }

        /* Improved button spacing in variants table */
        .variants-table .btn-animated {
            padding: 8px 12px;
            font-size: 12px;
            margin-right: 5px;
        }

        .variants-table .btn-animated:last-child {
            margin-right: 0;
        }

        /* Stats Table Styles */
        .stats-summary-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            margin-top: 10px;
        }
        .stats-summary-table th, .stats-summary-table td {
            padding: 12px;
            text-align: center;
            border: 1px solid #e9ecef;
        }
        .stats-summary-table th {
            background: #f8f9fa;
            color: #333;
            font-weight: 600;
        }
        .stats-summary-table td {
            color: #666;
        }
    </style>
</asp:Content>

<asp:Content ID="MainContentProduct" ContentPlaceHolderID="MainContent" runat="server">
    <header class="page-header">
        <h1>Product Management</h1>
        <p>Manage your beauty product catalog and inventory</p>
    </header>

    <!-- Error/Success Messages -->
    <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="error-container">
        <asp:Label ID="lblMessage" runat="server" />
    </asp:Panel>

    <!-- Main Toolbar -->
    <div class="toolbar">
        <div class="toolbar-left">
            <div class="search-box">
                <i class="fa fa-search"></i>
                <asp:TextBox ID="txtSearch" runat="server" placeholder="Search products, SKU, or category..." />
            </div>
            <div class="toolbar-group">
                <button type="button" class="btn ghost" title="Sort / Tag">
                    <i class="fa fa-star"></i>
                    <span class="btn-text">Best Seller</span>
                    <i class="fa fa-chevron-down caret"></i>
                </button>
                <button type="button" class="btn ghost" title="Filter">
                    <i class="fa fa-filter"></i>
                    <span class="btn-text">Filter : All</span>
                    <i class="fa fa-chevron-down caret"></i>
                </button>

            </div>
        </div>
        <div class="toolbar-right">
            <div class="btn-group">
                <button type="button" class="btn primary" id="btnAddItem">
                    <i class="fa fa-plus"></i> Add Product
                </button>
                <button type="button" class="btn square" title="Refresh" onclick="location.reload()">
                    <i class="fa fa-rotate"></i>
                </button>
                <button type="button" class="btn square" title="Export">
                    <i class="fa fa-download"></i>
                </button>
                <button type="button" class="btn secondary" id="btnViewArchived" onclick="switchTab('archived', event)">
    <i class="fa fa-archive"></i> View Archived Products
</button>

            </div>
        </div>
    </div>

    <!-- Stats Bar -->
    <div class="stats-bar" style="background: white; padding: 10px 20px; border-radius: 8px; margin-bottom: 12px; display: flex; gap: 20px; align-items: center; font-size: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
        <span><strong>Total Products:</strong> 
            <asp:Label ID="lblProductCount" runat="server" Text="Loading..." />
        </span>
        <span><strong>Low Stock:</strong> 
            <asp:Label ID="lblLowStockCount" runat="server" Text="Loading..." style="color: #f44336;" />
        </span>
        <span><strong>Categories:</strong> 
            <asp:Label ID="lblCategoryCount" runat="server" Text="Loading..." />
        </span>
    </div>

  

    <!-- 💖 Beautiful Add Product Modal 💖 -->
    <div id="addProductModal" class="modal-overlay">
        <div class="modal-container">
            <div class="modal-header">
                <h2 class="modal-title">
                    <i class="fa fa-sparkles"></i>
                    Add New Product
                </h2>
                <button class="modal-close" onclick="closeModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <div class="modal-nav">
                    <button type="button" class="nav-tab active" onclick="switchTab('product', event)">
                        <i class="fa fa-box"></i> Product Details
                    </button>
                    <button type="button" class="nav-tab" onclick="switchTab('archived', event)">
    <i class="fa fa-archive"></i> Archived
</button>
                    <button type="button" class="nav-tab" onclick="switchTab('variants', event)">
                        <i class="fa fa-layer-group"></i> Product Variants
                    </button>

                </div>
                
                <div class="tab-content">
                    <!-- Product Details Tab -->
                    <div id="productTab" class="tab-pane active">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Product Name *</label>
                                <asp:TextBox ID="txtProductName" runat="server" CssClass="form-control" placeholder="Enter product name..." />
                            </div>
                            <div class="form-group">
                                <label class="form-label">Category *</label>
                                <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-control">
                                    <asp:ListItem Value="">Select Category</asp:ListItem>
                                    <asp:ListItem Value="Skincare">Skincare</asp:ListItem>
                                    <asp:ListItem Value="Makeup">Makeup</asp:ListItem>
                                    <asp:ListItem Value="Haircare">Haircare</asp:ListItem>
                                    <asp:ListItem Value="Fragrance">Fragrance</asp:ListItem>
                                    <asp:ListItem Value="Body Care">Body Care</asp:ListItem>
                                </asp:DropDownList>
                            </div>
                        </div>
                        
                        <div class="form-group">
                            <label class="form-label">Description</label>
                            <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" CssClass="form-control textarea-field" placeholder="Enter product description..." />
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Base Ingredients</label>
                                <asp:TextBox ID="txtBaseIngredients" runat="server" CssClass="form-control" placeholder="Enter base ingredients..." />
                            </div>
                            <div class="form-group">
                                <label class="form-label">Supplier</label>
                                <asp:DropDownList ID="ddlSupplier" runat="server" CssClass="form-control">
                                    <asp:ListItem Value="">Select Supplier</asp:ListItem>
                                </asp:DropDownList>
                            </div>
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Product Image URL</label>
                                <asp:TextBox ID="txtProductImageUrl" runat="server" CssClass="form-control" placeholder="https://example.com/image.jpg" />
                                <div class="preview-image" style="margin-top:10px;">
                                    <img id="productImagePreview" src="<%= ResolveUrl("~/Content/images/sample-generic.png") %>" alt="Product Image Preview" style="width:100%; height:150px; object-fit:cover; border-radius:8px;" />
                                </div>
                                <div class="preview-extra">Paste an image link to preview.</div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Product Variants Tab -->
                    <div id="variantsTab" class="tab-pane">
                        <div class="variant-section">
                            <div class="variant-header">
                                <div class="variant-title">
                                    <i class="fa fa-magic"></i>
                                    Product Variants
                                </div>
                                <button type="button" class="add-variant-btn" onclick="addVariant()">
                                    <i class="fa fa-plus"></i>
                                    Add Variant
                                </button>
                            </div>
                            
                            <div id="variantContainer">
                                <!-- Variants will be added here dynamically -->
                            </div>
                        </div>
                    </div>

                    <div id="archivedTab" class="tab-pane">
    <div class="table-wrapper">
        <table class="product-table" cellspacing="0" cellpadding="0">
            <thead>
                <tr>
                    <th style="width:60px">ID</th>
                    <th>Product</th>
                    <th style="width:120px">Category</th>
                    <th style="width:120px">Supplier</th>
                    <th style="width:90px">Price</th>
                    <th style="width:120px">Created</th>
                </tr>
            </thead>
            <tbody id="tblArchivedProducts">
                <tr><td colspan="6" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading archived products...</td></tr>
            </tbody>
        </table>
    </div>
</div>



                </div>
            </div>
            
            <div class="modal-footer">
                <!-- Removed development/debug buttons -->
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <asp:Button ID="btnSaveProduct" runat="server" 
                    Text="Save Product" 
                    CssClass="btn-animated btn-primary" 
                    OnClick="btnSaveProduct_Click" 
                    OnClientClick="return openConfirmSaveProduct();" 
                    UseSubmitBehavior="true" />
            </div>
        </div>
    </div>

    <!-- 💖 Beautiful Add Product Variant Modal 💖 -->
    <div id="addVariantModal" class="modal-overlay">
        <div class="modal-container variant-modal">
            <div class="modal-header">
                <h2 class="modal-title">
                    <i class="fa fa-layer-group"></i>
                    Add Product Variant
                </h2>
                <div class="product-info">
                    <span id="variantProductName">Product Name</span>
                </div>
                <button class="modal-close" onclick="closeVariantModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <div class="variant-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Variant Name *</label>
                            <asp:TextBox ID="txtVariantName" runat="server" CssClass="form-control" placeholder="e.g., Rose Gold, Large, etc..." />
                        </div>
                        <div class="form-group">
                            <label class="form-label">SKU *</label>
                            <asp:TextBox ID="txtVariantSKU" runat="server" CssClass="form-control" placeholder="e.g., SKU001-RG" />
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Size</label>
                            <asp:TextBox ID="txtVariantSize" runat="server" CssClass="form-control" placeholder="e.g., 50ml, Large, etc..." />
                        </div>
                        <div class="form-group">
                            <label class="form-label">Color</label>
                            <asp:TextBox ID="txtVariantColor" runat="server" CssClass="form-control" placeholder="e.g., Rose Gold, Natural, etc..." />
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Price *</label>
                            <asp:TextBox ID="txtVariantPrice" runat="server" CssClass="form-control" placeholder="0.00" TextMode="Number" step="0.01" />
                        </div>
                        <div class="form-group">
                            <label class="form-label">Stock Quantity *</label>
                            <asp:TextBox ID="txtVariantStock" runat="server" CssClass="form-control" placeholder="0" TextMode="Number" />
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Minimum Stock</label>
                            <asp:TextBox ID="txtVariantMinStock" runat="server" CssClass="form-control" TextMode="Number" placeholder="5" Text="5" />
                        </div>
                        <div class="form-group">
                            <label class="form-label">Weight (grams)</label>
                            <asp:TextBox ID="txtVariantWeight" runat="server" CssClass="form-control" placeholder="0.00" TextMode="Number" step="0.01" />
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Dimensions</label>
                            <asp:TextBox ID="txtVariantDimensions" runat="server" CssClass="form-control" placeholder="e.g., 10cm x 5cm x 3cm" />
                        </div>
                        <div class="form-group">
                            <label class="form-label">Variant Image URL (optional override)</label>
                            <asp:TextBox ID="txtVariantImageUrl" runat="server" CssClass="form-control" placeholder="https://example.com/image.jpg" />
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Lifespan / Best Before (years)</label>
                        <asp:TextBox ID="txtShelfLifeYears" runat="server" CssClass="form-control" TextMode="Number" placeholder="1" />
                        <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
                            How many years the product stays fresh (e.g., 1 for 1 year, 2 for 2 years)
                        </small>
                    </div>
                    
                    <!-- 📍 Location Dropdown (Category-Based) -->
                    <div class="form-group">
                        <label class="form-label">Storage Location *</label>
                        <asp:DropDownList ID="ddlVariantLocation" runat="server" CssClass="form-control">
                            <asp:ListItem Value="">Select product category first...</asp:ListItem>
                        </asp:DropDownList>
                        <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
                            <i class="fa fa-info-circle"></i> Location options are based on the product category (set in Product Details tab)
                        </small>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Variant Image Upload</label>
                        <asp:FileUpload ID="fuVariantImage" runat="server" CssClass="form-control" />
                    </div>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeVariantModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <asp:Button ID="btnSaveVariant" runat="server" 
                    Text="Save Variant" 
                    CssClass="btn-animated btn_primary" 
                    OnClick="btnSaveVariant_Click" 
                    UseSubmitBehavior="true" />
            </div>
        </div>
    </div>

    <!-- 🎉 Success Celebration Modal 🎉 -->
    <div id="successModal" class="modal-overlay">
        <div class="modal-container success-modal">
            <div class="modal-header success-header">
                <h2 class="modal-title">
                    <i class="fa fa-check-circle"></i>
                    Product Created Successfully!
                </h2>
                <button class="modal-close" onclick="closeSuccessModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <div class="success-content">
                    <div class="celebration-animation">
                        <i class="fa fa-star"></i>
                        <i class="fa fa-star"></i>
                        <i class="fa fa-star"></i>
                    </div>
                    <p>Your product and variant have been successfully added to the inventory!</p>
                    <div class="product-summary" id="productSummary">
                        <!-- Product summary will be populated here -->
                    </div>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-primary" onclick="closeSuccessModal()">
                    <i class="fa fa-thumbs-up"></i>
                    <span>Awesome!</span>
                </button>
            </div>
        </div>
    </div>

    <!-- 🔎 View Product Variants Modal -->
    <div id="viewVariantsModal" class="modal-overlay">
        <div class="modal-container variants-list-modal">
            <div class="modal-header">
                <h2 class="modal-title">
                    <i class="fa fa-eye"></i>
                    Product Variants
                </h2>
                <div class="product-info">
                    <span id="viewVariantsProductName">Product</span>
                    <span id="viewVariantsSummary" style="margin-left:8px; opacity:.9;"></span>
                </div>
                <button class="modal-close" onclick="closeViewVariantsModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>

            <div class="modal-body">
                <div class="variants-toolbar">
                    <div class="meta" id="viewVariantsMeta">Loading…</div>
                    <div>
                        <input type="text" id="variantFilter" class="form-control" placeholder="Filter variants (name, SKU…)" style="width:240px;">
                    </div>
                </div>
                <div style="padding: 0 24px 24px 24px;">
                    <table class="variants-table">
                        <thead>
                            <tr>
                                <th style="width:32px">#</th>
                                <th>Variant</th>
                                <th style="width:140px">SKU</th>
                                <th style="width:120px">Price</th>
                                <th style="width:110px">Stock</th>
                                <th style="width:120px">Status</th>
                                <th style="width:120px">Size</th>
                                <th style="width:120px">Color</th>
                                <th style="width:150px">Action</th>
                            </tr>
                        </thead>
                        <tbody id="variantsTableBody">
                            <tr>
                                <td colspan="8" class="text-center">
                                    <i class="fa fa-spinner fa-spin"></i> Loading variants…
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <div id="variantsEmptyState" style="display:none; text-align:center; color:#888; padding:24px;">
                        <i class="fa fa-box-open" style="display:block; font-size:36px; color:#ddd; margin-bottom:6px;"></i>
                        No variants found for this product.
                    </div>
                </div>
            </div>

            <div class="modal-footer" style="display: flex; justify-content: space-between;">
                <button type="button" class="btn-animated btn-secondary" onclick="closeViewVariantsModal()">
                    <i class="fa fa-times"></i>
                    <span>Close</span>
                </button>
                <button type="button" class="btn-animated btn-primary" onclick="closeViewVariantsModal(); showVariantModal(currentProductId, currentProductName)">
                    <i class="fa fa-plus"></i>
                    <span>Add Variant</span>
                </button>
            </div>
        </div>
    </div>

    <!-- Table + Preview layout -->
    <div class="content-body">
        <div class="table-wrapper">
            <table class="product-table" cellspacing="0" cellpadding="0">
                <thead>
                    <tr>
                        
                        <th style="width:60px">ID</th>
                        <th>Product</th>
                        <th class="col-sku" style="width:110px">SKU</th>
                        <th style="width:120px">Supplier</th>
                        <th style="width:90px">Price</th>
                        <th style="width:90px">Stock</th>
                        <th style="width:95px">Action</th>
                    </tr>
                </thead>
                <tbody id="tblProducts">
                    <asp:Panel ID="pnlLoading" runat="server" Visible="true">
                        <tr>
                            <td colspan="8" class="text-center">
                                <i class="fa fa-spinner fa-spin"></i> Loading products from database...
                            </td>
                        </tr>
                    </asp:Panel>
                    <asp:Panel ID="pnlNoData" runat="server" Visible="false">
                        <tr>
                            <td colspan="8" class="text-center" style="padding: 40px;">
                                <div style="color: #666; font-size: 16px; margin-bottom: 15px;">
                                    <i class="fa fa-box-open" style="font-size: 48px; margin-bottom: 15px; display: block; color: #ddd;"></i>
                                    No products found
                                </div>
                                <div style="margin-bottom: 20px; color: #888;">
                                    Please add products to your inventory using the "Add Product" button above.
                                </div>
                            </td>
                        </tr>
                    </asp:Panel>
                    <asp:Repeater ID="rptProductVariants" runat="server" OnItemDataBound="rptProductVariants_ItemDataBound">
                        <ItemTemplate>
                            <tr class="row-select" onclick="selectRow(this)" 
                                data-name='<%# Eval("ProductName") %>'
                                data-variant='<%# Eval("VariantCount") %>'
                                data-sku='<%# Eval("SKU") %>'
                                data-price='<%# String.Format("₱{0:F2}", Eval("Price")) %>'
                                data-stock='<%# GetStockDisplay(Eval("StockQuantity"), Eval("MinimumStock")) %>'
                                data-status='<%# GetStockStatusForDisplay(Convert.ToInt32(Eval("StockQuantity")), Convert.ToInt32(Eval("MinimumStock"))) %>'
                                data-description='<%# Eval("ProductDesc") %>'
                                data-category='<%# Eval("ProductCategory") %>'
                                data-size='<%# Eval("StockDisplay") %>'
                                data-color='<%# Eval("PriceRange") %>'
                                data-product-id='<%# Eval("ProductId") %>'
                                data-variant-count='<%# Eval("VariantCount") %>'
                                data-image-url='<%# GetProductImage(Eval("ProductImg").ToString()) %>'>
                                
                                <td><%# Container.ItemIndex + 17410 %></td>
                                <td class="prod-cell">
                                    <img src='<%# GetProductImage(Eval("ProductImg").ToString()) %>' class="thumb" alt="Product Image" />
                                    <%# Eval("DisplayName") %>
                                </td>
                                <td class="col-sku"><%# Eval("SKU") %></td>
                                <td><%# Eval("Supplier") ?? "N/A" %></td>
                                <td><%# Eval("PriceRange") %></td>
                                <td class='<%# GetStockCssClass(Eval("StockQuantity"), Eval("MinimumStock")) %>'>
                                    <%# Eval("StockDisplay") %>
                                </td>
                                <td class="actions">
                                    <button type="button" class="icon" title="View Variants" onclick="viewProductVariants('<%# Eval("ProductId") %>', '<%# Eval("ProductName") %>'); event.stopPropagation();">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                    <button type="button" class="icon" title="Edit" onclick="event.stopPropagation(); showUpdateProductModal('<%# Eval("ProductId") %>', '<%# Eval("ProductName") %>')">
                                        <i class="fa fa-pen"></i>
                                    </button>
                                    <button type="button" class="icon" title="Archive" onclick="event.stopPropagation(); archiveProduct('<%# Eval("ProductId") %>');">
    <i class="fa fa-archive"></i>
</button>
                                   
                                    <!-- FIX: wire delete click to open confirmation modal -->
                                    <button type="button" class="icon btn-delete-product" title="Delete"
                                            data-product-id='<%# Eval("ProductId") %>'
                                            onclick="event.stopPropagation(); showDeleteProductModal('<%# Eval("ProductId") %>'); return false;">
                                        <i class="fa fa-trash"></i>
                                    </button>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </div>
        <aside class="preview" id="previewPanel">
            <div class="preview-header">Product Preview</div>
            <div class="preview-body">
                <div class="preview-image">
                    <img id="previewImage" src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2YwZjBmMCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI1MCIgZm9ydC1mYW1pbHk9IkFyaUVsbHAgc2Fucy1zZXJpZiIgbWFyZ2luPSJhcyI+UHJvZHVjdDwvdGV4dD4KICA8L3N2Zz4K" alt="Product Preview" style="width: 100%; height: 150px; object-fit: cover; border-radius: 8px; transition: all 0.3s ease;" />
                </div>
                <div class="preview-info">
                    <div class="p-name" id="pName">Select a product to view details</div>
                    <div class="p-field"><span class="lbl">Stock:</span> <span id="pStock">-</span></div>
                    <div class="p-field"><span class="lbl">Price:</span> <span id="pPrice">-</span></div>
                    <div class="p-field"><span class="lbl">Status:</span> <span id="pStatus">-</span></div>
                    
                    <!-- Additional preview info -->
                    <div class="preview-extra">
                        <div class="p-field"><span class="lbl">Category:</span> <span id="pCategory">-</span></div>
                        <div class="p-field"><span class="lbl">Variants:</span> <span id="pSize">-</span></div>
                        <div class="p-field"><span class="lbl">Product ID:</span> <span id="pColor">-</span></div>
                        <div class="p-field" style="margin-top: 8px;">
                            <span class="lbl">Description:</span> 
                            <div id="pDescription" style="color: #ccc; line-height: 1.3; margin-top: 4px;">-</div>
                        </div>
                    </div>
                </div>
            </div>
        </aside>
    </div>

    <!-- 💖 Beautiful Update Product Modal 💖 -->
    <asp:HiddenField ID="hiddenProductId" runat="server" />
    <div id="updateProductModal" class="modal-overlay">
        <div class="modal-container">
            <div class="modal-header">
                <h2 class="modal-title">
                    <i class="fa fa-edit"></i>
                    Update Product
                </h2>
                <button class="modal-close" onclick="closeUpdateProductModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Product Name *</label>
                        <input type="text" id="txtUpdateProductName" class="form-control" placeholder="Enter product name..." />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Category *</label>
                        <select id="ddlUpdateCategory" class="form-control">
                            <option value="">Select Category</option>
                            <option value="Skincare">Skincare</option>
                            <option value="Makeup">Makeup</option>
                            <option value="Haircare">Haircare</option>
                            <option value="Fragrance">Fragrance</option>
                            <option value="Body Care">Body Care</option>
                        </select>
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea id="txtUpdateDescription" class="form-control textarea-field" placeholder="Enter product description..."></textarea>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Base Ingredients</label>
                        <input type="text" id="txtUpdateBaseIngredients" class="form-control" placeholder="Enter base ingredients..." />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Supplier</label>
                        <select id="ddlUpdateSupplier" class="form-control">
                            <option value="">Select Supplier</option>
                        </select>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Product Image URL</label>
                        <input type="text" id="txtUpdateProductImageUrl" class="form-control" placeholder="https://example.com/image.jpg" />
                        <div class="preview-image" style="margin-top:10px;">
                            <img id="updateProductImagePreview" src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjgwIiB2aWV3Qm94PSIwIDAgMTAwIDgwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWNgd2lkdGg9IjEwMCIgaGVpZ2h0PSI4MCIgcng9IjEyIiBmaWxsPSIjZjBmMGYwIi8+CiAgPHBhdGggZD0iTTIwIDYwTDM4IDQwYTIgMiAwIDAxMyAwbDE5IDIwaDIwIiBzdHJva2U9IiNlZWUiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0iI2ZmZiIvPgogIDxjaXJjbGUgY3g9IjQ1IiBjeT0iMzAiIHI9IjExIiBmaWxsPSIjZmZmIiBzdHJva2U9IiNlZWUiLz4KICA8dGV4dCB4PSI1MCIgeT0iNDQiIGZvcnQtZmFtaWx5PSJBcmlhbCIgZm9ydC1zaXplPSIxMCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Tm8gSW1hZ2U8L3RleHQ+PC9zdmc+" alt="Update Product Image Preview" style="width:100%; height:150px; object-fit:cover; border-radius:8px;" />
                        </div>
                        <div class="preview-extra">Paste an image link to preview.</div>
                    </div>
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeUpdateProductModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <button type="button" class="btn-animated btn-primary" onclick="updateProduct()">
                    <i class="fa fa-save"></i>
                    <span>Save Changes</span>
                </button>
            </div>
        </div>
    </div>

    <!-- 🔥 Delete Product Confirmation Modal 🔥 -->
    <div id="deleteProductModal" class="modal-overlay">
        <div class="modal-container">
            <div class="modal-header">
                <h2 class="modal-title">
                    <i class="fa fa-trash"></i>
                    Delete Product
                </h2>
                <button class="modal-close" onclick="closeDeleteProductModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <p>Are you sure you want to delete this product? This action cannot be undone.</p>
                <div class="form-group">
                    <label class="form-label">Admin Password *</label>
                    <input type="password" id="txtAdminPassword" class="form-control" placeholder="Enter admin password..." />
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeDeleteProductModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <button type="button" class="btn-animated btn-danger" onclick="deleteProduct()">
                    <i class="fa fa-trash"></i>
                    <span>Delete</span>
                </button>
            </div>
        </div>
    </div>

    <!-- 🔥 Delete Variant Confirmation Modal 🔥 -->
    <div id="deleteVariantModal" class="modal-overlay">
        <div class="modal-container">
            <div class="modal-header">
                <h2 class="modal-title">
                    <i class="fa fa-trash"></i>
                    Delete Variant
                </h2>
                <button class="modal-close" onclick="closeDeleteVariantModal()">
                    <i class="fa fa-times"></i>
                </button>
            </div>
            
            <div class="modal-body">
                <p>Are you sure you want to delete this variant? This action cannot be undone.</p>
                <div class="form-group">
                    <label class="form-label">Admin Password *</label>
                    <input type="password" id="txtAdminPasswordVariant" class="form-control" placeholder="Enter admin password..." />
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeDeleteVariantModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <button type="button" class="btn-animated btn-danger" onclick="deleteVariant()">
                    <i class="fa fa-trash"></i>
                    <span>Delete</span>
                </button>
            </div>
        </div>
    </div>

    <!-- 🎨 Beautiful Notification Modals -->
    <!-- Success Notification Modal -->
    <div id="notificationModal" class="notification-modal">
        <div class="notification-container">
            <div class="notification-header">
                <div class="notification-icon" id="notificationIcon">
                    <i class="fa fa-check"></i>
                </div>
                <div class="notification-content">
                    <h3 class="notification-title" id="notificationTitle">Success</h3>
                    <p class="notification-message" id="notificationMessage">Operation completed successfully!</p>
                </div>
            </div>
            <div class="notification-footer">
                <button type="button" class="btn-notification primary" onclick="closeNotificationModal()">
                    <i class="fa fa-check"></i>
                    <span>OK</span>
                </button>
            </div>
            <div class="notification-progress" id="notificationProgress"></div>
        </div>
    </div>

    <!-- Confirmation Modal -->
    <div id="confirmationModal" class="notification-modal confirmation-modal">
        <div class="notification-container">
            <div class="notification-header">
                <div class="notification-icon warning" id="confirmationIcon">
                    <i class="fa fa-question-circle"></i>
                </div>
                <div class="notification-content">
                    <h3 class="notification-title" id="confirmationTitle">Confirm Action</h3>
                    <p class="notification-message" id="confirmationMessage">Are you sure you want to proceed?</p>
                </div>
            </div>
            <div class="notification-footer">
                <button type="button" class="btn-notification secondary" onclick="closeConfirmationModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <button type="button" class="btn-notification primary" id="confirmationConfirmBtn" onclick="confirmAction()">
                    <i class="fa fa-check"></i>
                    <span>Confirm</span>
                </button>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="ScriptsContentProduct" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// Early safe fallbacks to avoid ReferenceError before full helpers are defined
if (typeof window.showNotification !== 'function') {
    window.showNotification = function(type, title, message, autoHide, duration){
        // Minimal modal-based fallback (no browser alert)
        var modal = document.getElementById('notificationModal');
        if (modal) {
            var icon = document.getElementById('notificationIcon');
            var titleEl = document.getElementById('notificationTitle');
            var messageEl = document.getElementById('notificationMessage');
            var progress = document.getElementById('notificationProgress');
            if (titleEl) titleEl.textContent = title || '';
            if (messageEl) messageEl.textContent = message || '';
            if (icon) {
                var t = (type || 'info');
                icon.className = 'notification-icon ' + t;
                icon.innerHTML = (t==='success')?'<i class="fa fa-check"></i>':(t==='error')?'<i class="fa fa-times"></i>':(t==='warning')?'<i class="fa fa-exclamation-triangle"></i>':'<i class="fa fa-info-circle"></i>';
            }
            modal.classList.add('show');
            if (autoHide) {
                var ms = duration || 3000;
                if (progress) { progress.style.animationDuration = ms + 'ms'; progress.style.width = '100%'; modal.classList.add('auto-hide'); }
                setTimeout(function(){
                    try {
                        modal.classList.remove('show','auto-hide');
                        if (progress) { progress.style.width = '0%'; progress.style.animationDuration=''; }
                    } catch(_) {}
                }, ms);
            }
            return;
        }
        // If modal not present, log silently
        try { console.log('[Notification]', type, title, message); } catch(_) {}
    };
}
if (typeof window.openModal !== 'function') {
    window.openModal = function(){}; // will be replaced by real implementation below
}
if (typeof window.setupSearch !== 'function') {
    window.setupSearch = function(){}; // placeholder until real implementation below
}
if (typeof window.resetForm !== 'function') {
    window.resetForm = function(){}; // placeholder to avoid early ReferenceError
}
if (typeof window.addVariant !== 'function') {
    window.addVariant = function(){}; // placeholder until real implementation below
}
if (typeof window.removeVariant !== 'function') {
    window.removeVariant = function(){}; // placeholder until real implementation below
}
var GET_VARIANTS_URL = '/WebPages/ProductPage.aspx/GetProductVariants';
var baseHandlersUrl = '/Handlers/';

// 💖 Enhanced Modal JavaScript 💖
let variantCounter = 0;
let currentProductId = null;
let currentProductName = null;
let currentVariantId = null;
let currentVariantName = null;
let currentDeleteProductId = null; // Add this for delete functionality

document.addEventListener('DOMContentLoaded', function() {
console.log('🎯 ProductPage JavaScript loaded successfully!');
    
// ✅ ANTI-RESUBMISSION: Clear POST data from browser history on page load
if (window.history && window.history.replaceState) {
    // Replace current history state to remove POST data
    window.history.replaceState(null, null, window.location.href);
    console.log('✅ Browser history state cleared on page load');
}
    
// ✅ ANTI-RESUBMISSION: Prevent form resubmission on back button
window.addEventListener('pageshow', function(event) {
    if (event.persisted || (window.performance && window.performance.navigation.type === 2)) {
        // Page was loaded from cache (back button)
        if (window.history && window.history.replaceState) {
            window.history.replaceState(null, null, window.location.href);
            console.log('✅ Browser history cleared after back button navigation');
        }
    }
});
    
// ✅ ANTI-RESUBMISSION: Clear history before page unload
window.addEventListener('beforeunload', function() {
    if (window.history && window.history.replaceState) {
        window.history.replaceState(null, null, window.location.href);
    }
});
    
// Hook product image URL preview
    var imgUrlTb = document.getElementById('<%= txtProductImageUrl.ClientID %>');
    var imgPrev = document.getElementById('productImagePreview');
    function updateProductImagePreview(){
        if(!imgPrev || !imgUrlTb) return;
        var url = (imgUrlTb.value || '').trim();
        var defaultUrl = '<%= ResolveUrl("~/Content/images/sample-generic.png") %>';
        if(!url){ imgPrev.src = defaultUrl; return; }
        if(!(url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:') || url.startsWith('/'))){
            url = '/' + url;
        }
        imgPrev.onerror = function(){ this.onerror=null; this.src=defaultUrl; };
        imgPrev.src = url;
    }
    if(imgUrlTb){ imgUrlTb.addEventListener('input', updateProductImagePreview); }
    
    // Hook update product image URL preview
    var updateImgUrlTb = document.getElementById('txtUpdateProductImageUrl');
    var updateImgPrev = document.getElementById('updateProductImagePreview');
    function updateUpdateProductImagePreview(){
        if(!updateImgPrev || !updateImgUrlTb) return;
        var url = (updateImgUrlTb.value || '').trim();
        var defaultUrl = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjgwIiB2aWV3Qm94PSIwIDAgMTAwIDgwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWNgd2lkdGg9IjEwMCIgaGVpZ2h0PSI4MCIgcng9IjEyIiBmaWxsPSIjZjBmMGYwIi8+CiAgPHBhdGggZD0iTTIwIDYwTDM4IDQwYTIgMiAwIDAxMyAwbDE5IDIwaDIwIiBzdHJva2U9IiNlZWUiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0iI2ZmZiIvPgogIDxjaXJjbGUgY3g9IjQ1IiBjeT0iMzAiIHI9IjExIiBmaWxsPSIjZmZmIiBzdHJva2U9IiNlZWUiLz4KICA8dGV4dCB4PSI1MCIgeT0iNDQiIGZvcnQtZmFtaWx5PSJBcmlhbCIgZm9ydC1zaXplPSIxMCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Tm8gSW1hZ2U8L3RleHQ+PC9zdmc+";
        if(!url){ updateImgPrev.src = defaultUrl; return; }
        if(!(url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:') || url.startsWith('/'))){
            url = '/' + url;
        }
        updateImgPrev.onerror = function(){ this.onerror=null; this.src=defaultUrl; };
        updateImgPrev.src = url;
    }
    if(updateImgUrlTb){ updateImgUrlTb.addEventListener('input', updateUpdateProductImagePreview); }
    
    // Debug: Check if modal exists
    const modal = document.getElementById('addProductModal');
    const deleteModal = document.getElementById('deleteProductModal');
    const deleteVariantModal = document.getElementById('deleteVariantModal');
    
    console.log('🔍 Modal elements found:');
    console.log('- Add Product Modal:', modal ? '✅' : '❌');
    console.log('- Delete Product Modal:', deleteModal ? '✅' : '❌');
    console.log('- Delete Variant Modal:', deleteVariantModal ? '✅' : '❌');
    
    const selectAllCheckbox = document.getElementById('selectAll');
    if (selectAllCheckbox) {
        selectAllCheckbox.addEventListener('change', function() {
            const checkboxes = document.querySelectorAll('#tblProducts input[type="checkbox"]');
            checkboxes.forEach(cb => cb.checked = this.checked);
        });
    }
    
    const addButton = document.getElementById('btnAddItem');
    console.log('🔍 Add Product button element:', addButton);
    
    if (addButton) {
        console.log('✅ Add Product button found!');
        
        // Remove any existing event listeners and add a new one
        addButton.onclick = null;
        addButton.removeEventListener('click', openModal);
        
        addButton.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('🖱️ Add Product button clicked! Opening modal...');
            
            // Force open the modal
            const modal = document.getElementById('addProductModal');
            if (modal) {
                console.log('✅ Modal found, showing it...');
                modal.classList.add('show');
                modal.style.display = 'flex';
                modal.style.visibility = 'visible';
                document.body.style.overflow = 'hidden';
                
                resetForm();
                updateProductImagePreview();
                
                setTimeout(function() {
                    const firstInput = modal.querySelector('input[type="text"]');
                    if (firstInput) firstInput.focus();
                }, 400);
            } else {
                console.error('❌ Modal not found!');
                showNotification('error', 'Modal Error', 'Modal not found! Please check the HTML.');
            }
        });
        
        // Also add a simple onclick as backup
        addButton.onclick = function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('🖱️ Backup.onclick triggered!');
            openModal();
        };
        
    } else {
        console.error('❌ Add Product button not found! Looking for element with ID: btnAddItem');
    }
    
    // Add event listeners for delete buttons
    document.addEventListener('click', function(e) {
        if (e.target.closest('.btn-delete-product')) {
            e.preventDefault();
            e.stopPropagation();
            
            const button = e.target.closest('.btn-delete-product');
            const productId = button.getAttribute('data-product-id');
            
            console.log('🗑️ Delete button clicked for product:', productId);
            
            if (productId) {
                showDeleteProductModal(productId);
            } else {
                console.error('❌ No product ID found on delete button');
                showNotification('error', 'Delete Error', 'Product ID not found. Please refresh the page.');
            }
            
            return false;
        }
    });
    
    setupSearch();
    addVariant();
    setupFilters();
    
    console.log('🎉 Event listeners set up - allowing server-side processing!');
});

// ✅ CORE FUNCTION: selectRow - This is the missing function causing errors
function selectRow(row) {
    console.log('🖱️ Row selected:', row);
    
    // Remove selection from all rows
    document.querySelectorAll('.row-select').forEach(r => r.classList.remove('selected'));
    
    // Add selection to clicked row
    row.classList.add('selected');
    
    // Show loading state briefly for better UX
    const previewImage = document.getElementById('previewImage');
    const previewContainer = previewImage?.parentElement;
    
    if (previewContainer) {
        previewContainer.classList.add('loading');
        
        // Remove loading state after image loads or after a timeout
        setTimeout(() => {
            previewContainer.classList.remove('loading');
        }, 500);
    }
    
    // Update preview with selected product data
    updatePreview(row);
}

// ✅ CORE FUNCTION: updatePreview
function updatePreview(row) {
    try {
        const name = row.getAttribute('data-name') || '';
        const variantCount = row.getAttribute('data-variant') || '';
        const sku = row.getAttribute('data-sku') || '';
        const priceRange = row.getAttribute('data-color') || '';
        const stock = row.getAttribute('data-stock') || '';
        const status = row.getAttribute('data-status') || '';
        const description = row.getAttribute('data-description') || '';
        const category = row.getAttribute('data-category') || '';
        const stockDisplay = row.getAttribute('data-size') || '';
        const productId = row.getAttribute('data-product-id') || '';
        const imageUrl = row.getAttribute('data-image-url') || '';
        
        console.log('🔄 Updating preview for product:', {
            name: name,
            sku: sku,
            imageUrl: imageUrl,
            productId: productId
        });
        
        // Update product information
        document.getElementById('pName').textContent = sku + ' - ' + name;
        document.getElementById('pStock').textContent = stockDisplay;
        document.getElementById('pPrice').textContent = priceRange;
        document.getElementById('pStatus').textContent = status;
        document.getElementById('pDescription').textContent = description || '-';
        document.getElementById('pCategory').textContent = category || '-';
        document.getElementById('pSize').textContent = variantCount > 1 ? `${variantCount} variants` : (variantCount == 1 ? '1 variant' : 'No variants');
        document.getElementById('pColor').textContent = productId || '-';
        
        // Update preview image with better error handling
        const previewImage = document.getElementById('previewImage');
        if (previewImage) {
            var defaultImageUrl = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjgwIiB2aWV3Qm94PSIwIDAgMTAwIDgwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWNgd2lkdGg9IjEwMCIgaGVpZ2h0PSI4MCIgcng9IjEyIiBmaWxsPSIjZjBmMGYwIi8+CiAgPHBhdGggZD0iTTIwIDYwTDM4IDQwYTIgMiAwIDAxMyAwbDE5IDIwaDIwIiBzdHJva2U9IiNlZWUiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0iI2ZmZiIvPgogIDxjaXJjbGUgY3g9IjQ1IiBjeT0iMzAiIHI9IjExIiBmaWxsPSIjZmZmIiBzdHJva2U9IiNlZWUiLz4KICA8dGV4dCB4PSI1MCIgeT0iNDQiIGZvcnQtZmFtaWx5PSJBcmlhbCIgZm9ydC1zaXplPSIxMCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Tm8gSW1hZ2U8L3RleHQ+PC9zdmc+";
            function resolveImage(u){
                if(!u){return defaultImageUrl;}
                if(u.indexOf('data:')===0 || u.indexOf('http://')===0 || u.indexOf('https://')===0){return u;}
                // make absolute using application root
                return '/' + u.replace(/^\//,'');
            }
            var finalUrl = resolveImage(imageUrl);
            previewImage.onerror = function(){ this.onerror=null; this.src = defaultImageUrl; };
            previewImage.src = finalUrl;
        }
    } catch (e) {
        console.log('❌ Error updating preview:', e);
    }
}

// ✅ CORE FUNCTION: closeViewVariantsModal
function closeViewVariantsModal() {
    console.log('🔒 Closing variants modal...');
    const modal = document.getElementById('viewVariantsModal');
    if (modal) {
        modal.classList.remove('show');
        document.body.style.overflow = '';
        
        // Clear the table content
        const body = document.getElementById('variantsTableBody');
        if (body) {
            body.innerHTML = '<tr><td colspan="8" class="text-center">Modal closed</td></tr>';
        }
        
        // Reset meta text
        const meta = document.getElementById('viewVariantsMeta');
        if (meta) {
            meta.textContent = '';
        }
        
        console.log('✅ Variants modal closed successfully');
    } else {
        console.log('❌ Variants modal element not found');
    }
}

// 🔥 FIXED DELETE PRODUCT FUNCTIONALITY WITH BEAUTIFUL MODALS
function showDeleteProductModal(productId) {
    console.log('🗑️ showDeleteProductModal called with ID:', productId);
    
    if (!productId) {
        console.error('❌ No product ID provided');
        showNotification('error', 'Delete Error', 'No product ID provided');
        return;
    }
    
    currentDeleteProductId = productId;
    
    const modal = document.getElementById('deleteProductModal');
    console.log('🔍 Delete modal element:', modal);
    
    if (modal) {
        console.log('✅ Delete modal found, showing...');
        
        // Clear password field
        const passwordField = document.getElementById('txtAdminPassword');
        if (passwordField) {
            passwordField.value = '';
            console.log('✅ Password field cleared');
        }
        
        // Force show modal with multiple methods
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        modal.style.zIndex = '9999';
        document.body.style.overflow = 'hidden';
        
        console.log('✅ Modal styles applied');
        console.log('Modal classes:', modal.className);
        console.log('Modal display:', modal.style.display);
        
        // Focus on password field after modal opens
        setTimeout(function() {
            if (passwordField) {
                passwordField.focus();
                console.log('✅ Password field focused');
            }
        }, 400);
    } else {
        console.error('❌ Delete product modal not found in DOM!');
        
        // List all modal elements for debugging
        const allModals = document.querySelectorAll('[id$="Modal"]');
        console.log('🔍 All modals found:', Array.from(allModals).map(m => m.id));
        
        showNotification('error', 'Modal Error', 'Delete modal not found. Please refresh the page and try again.');
    }
}

function closeDeleteProductModal() {
    const modal = document.getElementById('deleteProductModal');
    if (modal) {
        modal.classList.remove('show');
        modal.style.display = '';
        modal.style.visibility = '';
        modal.style.opacity = '';
        document.body.style.overflow = '';
        currentDeleteProductId = null;
        
        // Clear password field
        const passwordField = document.getElementById('txtAdminPassword');
        if (passwordField) {
            passwordField.value = '';
        }
    }
}

// ✅ FIXED DELETE VARIANT FUNCTIONALITY WITH BEAUTIFUL MODALS
function showDeleteVariantModal(variantId, variantName) {
    console.log('🗑️ Delete variant modal for:', variantId, variantName);
    currentVariantId = variantId;
    currentVariantName = variantName;
    
    const modal = document.getElementById('deleteVariantModal');
    if (modal) {
        // Update modal text with variant name
        const modalBody = modal.querySelector('.modal-body p');
        if (modalBody) {
            modalBody.textContent = 'Are you sure you want to delete the variant "' + variantName + '"? This action cannot be undone.';
        }
        
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        document.body.style.overflow = 'hidden';
    } else {
        console.error('❌ Delete variant modal not found!');
        showNotification('error', 'Modal Error', 'Delete variant modal not found. Please refresh the page.');
    }
}

function closeDeleteVariantModal() {
    const modal = document.getElementById('deleteVariantModal');
    if (modal) {
        modal.classList.remove('show');
        modal.style.display = '';
        modal.style.visibility = '';
        modal.style.opacity = '';
        document.body.style.overflow = '';
        currentVariantId = null;
        currentVariantName = null;
    }
}

// ✅ CORE DELETE FUNCTION - This performs the actual deletion
function deleteProduct() {
    console.log('🗑️ Delete product functionality for:', currentDeleteProductId);
    
    if (!currentDeleteProductId) {
        showNotification('error', 'Missing Information', 'Product ID not found. Please try again.');
        return;
    }
    
    const passwordField = document.getElementById('txtAdminPassword');
    const adminPassword = passwordField ? passwordField.value.trim() : '';
    
    if (!adminPassword) {
        showNotification('warning', 'Password Required', 'Admin password is required to delete products.');
        if (passwordField) {
            passwordField.focus();
        }
        return;
    }
    
    // Show loading state
    const deleteBtn = document.querySelector('#deleteProductModal .btn-danger');
    const originalText = deleteBtn ? deleteBtn.innerHTML : '';
    if (deleteBtn) {
        deleteBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> <span>Deleting...</span>';
        deleteBtn.disabled = true;
    }
    
    // Call delete handler
    $.ajax({
        type: "POST",
        url: "/Handlers/DeleteProduct.ashx",
        data: JSON.stringify({
            productId: currentDeleteProductId,
            adminPassword: adminPassword
        }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function(response) {
            console.log('✅ Delete product response:', response);
            
            if (response.success) {
                showNotification('success', 'Product Deleted', 'Product deleted successfully!', true, 3000);
                closeDeleteProductModal();
                // Reload page to refresh product list
                setTimeout(function() {
                    window.location.reload();
                }, 3500);
            } else {
                showNotification('error', 'Delete Failed', 'Failed to delete product: ' + (response.error || 'Unknown error'));
            }
        },
        error: function(xhr, status, error) {
            console.error('❌ Delete product failed:', status, error);
            let errorMessage = 'Failed to delete product.';
            
            try {
                const response = JSON.parse(xhr.responseText);
                if (response.error) {
                    errorMessage = response.error;
                }
            } catch (e) {
                errorMessage = 'Server error: ' + (xhr.statusText || error);
            }
            
            showNotification('error', 'Delete Failed', errorMessage);
        },
        complete: function() {
            // Restore button state
            if (deleteBtn) {
                deleteBtn.innerHTML = originalText;
                deleteBtn.disabled = false;
            }
        }
    });
}

function deleteVariant() {
    console.log('🗑️ Delete variant functionality for:', currentVariantId);
    
    if (!currentVariantId) {
        showNotification('error', 'Missing Information', 'Variant ID not found. Please try again.');
        return;
    }
    var pwdField = document.getElementById('txtAdminPasswordVariant');
    var adminPassword = pwdField ? pwdField.value.trim() : '';
    if(!adminPassword){ showNotification('warning','Password Required','Admin password is required to delete variants.'); if(pwdField){pwdField.focus();} return; }
    
    // Show loading state
    const deleteBtn = document.querySelector('#deleteVariantModal .btn-danger');
    const originalText = deleteBtn ? deleteBtn.innerHTML : '';
    if (deleteBtn) {
        deleteBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> <span>Deleting...</span>';
        deleteBtn.disabled = true;
    }
    
    // Call delete handler
    $.ajax({
        type: "POST",
        url: "/Handlers/DeleteVariant.ashx",
        data: JSON.stringify({
            variantId: currentVariantId,
            adminPassword: adminPassword
        }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function(response) {
            console.log('✅ Delete variant response:', response);
            
            if (response.success) {
                showNotification('success', 'Variant Deleted', 'Variant deleted successfully!', true, 3000);
                closeDeleteVariantModal();
                
                // If we're in the variants modal, refresh the variants table
                if (document.getElementById('viewVariantsModal').classList.contains('show')) {
                    // Refresh variants table
                    setTimeout(function() {
                        viewProductVariants(currentProductId, currentProductName);
                    }, 1000);
                } else {
                    // Reload page to refresh product list
                    setTimeout(function() {
                        window.location.reload();
                    }, 3500);
                }
            } else {
                showNotification('error', 'Delete Failed', 'Failed to delete variant: ' + (response.error || 'Unknown error'));
            }
        },
        error: function(xhr, status, error) {
            console.error('❌ Delete variant failed:', status, error);
            let errorMessage = 'Failed to delete variant.';
            
            try {
                const response = JSON.parse(xhr.responseText);
                if (response.error) {
                    errorMessage = response.error;
                }
            } catch (e) {
                errorMessage = 'Server error: ' + (xhr.statusText || error);
            }
            
            showNotification('error', 'Delete Failed', errorMessage);
        },
        complete: function() {
            // Restore button state
            if (deleteBtn) {
                deleteBtn.innerHTML = originalText;
                deleteBtn.disabled = false;
            }
        }
    });
}

// 🧪 Test function to manually trigger delete modal (for debugging)
function testDeleteModal() {
    console.log('🧪 Testing delete modal...');
    const modal = document.getElementById('deleteProductModal');
    if (modal) {
        console.log('✅ Delete modal found, showing...');
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        modal.style.zIndex = '9999';
        document.body.style.overflow = 'hidden';
        
        // Test notification too
        setTimeout(function() {
            showNotification('info', 'Test Modal', 'Delete modal test successful!');
        }, 2000);
    } else {
        console.error('❌ Delete modal not found!');
        showNotification('error', 'Test Failed', 'Delete modal element not found in DOM');
    }
}

// Additional helper functions for modals and product management
function showUpdateProductModal(productId, productName) {
    console.log('✏️ Update product modal for:', productId, productName);
    
    const modal = document.getElementById('updateProductModal');
    if (!modal) {
        console.error('❌ Update product modal not found!');
        showNotification('error', 'Modal Error', 'Update modal not found. Please refresh the page.');
        return;
    }
    
    // Store product ID in hidden field for update operation
    var hiddenId = document.getElementById('<%= hiddenProductId.ClientID %>');
    if (hiddenId) {
        hiddenId.value = productId;
    }
    
    // Show modal with loading state
    modal.classList.add('show');
    modal.style.display = 'flex';
    modal.style.visibility = 'visible';
    modal.style.opacity = '1';
    document.body.style.overflow = 'hidden';
    
    // Populate supplier dropdown from global suppliersList
    var supplierDropdown = document.getElementById('ddlUpdateSupplier');
    if (supplierDropdown && window.suppliersList) {
        supplierDropdown.innerHTML = '<option value="">Select Supplier</option>';
        window.suppliersList.forEach(function(supplier) {
            var option = document.createElement('option');
            option.value = supplier.id;
            option.textContent = supplier.name;
            supplierDropdown.appendChild(option);
        });
    }
    
    // Show loading state in form fields
    var txtUpdateProductName = document.getElementById('txtUpdateProductName');
    var ddlUpdateCategory = document.getElementById('ddlUpdateCategory');
    var txtUpdateDescription = document.getElementById('txtUpdateDescription');
    var txtUpdateBaseIngredients = document.getElementById('txtUpdateBaseIngredients');
    
    if (txtUpdateProductName) txtUpdateProductName.value = 'Loading...';
    if (ddlUpdateCategory) ddlUpdateCategory.disabled = true;
    if (txtUpdateDescription) txtUpdateDescription.value = 'Loading...';
    if (txtUpdateBaseIngredients) txtUpdateBaseIngredients.value = 'Loading...';
    
    // Fetch product data from server
    $.ajax({
        type: "POST",
        url: "/Handlers/GetProduct.ashx",
        data: JSON.stringify({ productId: productId }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function(response) {
            console.log('✅ Product data loaded:', response);
            
            if (response.success && response.product) {
                var product = response.product;
                
                // Fill form fields with existing data (with null checks)
                var txtUpdateProductName = document.getElementById('txtUpdateProductName');
                if (txtUpdateProductName) txtUpdateProductName.value = product.productName || '';
                
                // Set category dropdown
                var categoryDropdown = document.getElementById('ddlUpdateCategory');
                if (categoryDropdown) {
                    categoryDropdown.disabled = false;
                    categoryDropdown.value = product.productCategory || '';
                }
                
                // Fill other fields
                var txtUpdateDescription = document.getElementById('txtUpdateDescription');
                if (txtUpdateDescription) txtUpdateDescription.value = product.productDesc || '';
                
                var txtUpdateBaseIngredients = document.getElementById('txtUpdateBaseIngredients');
                if (txtUpdateBaseIngredients) txtUpdateBaseIngredients.value = product.baseIngredients || '';
                
                // Set supplier dropdown value
                var ddlUpdateSupplier = document.getElementById('ddlUpdateSupplier');
                if (ddlUpdateSupplier && product.supplierId) {
                    ddlUpdateSupplier.value = product.supplierId;
                }
                
                // Fill image URL and update preview
                var imageUrlField = document.getElementById('txtUpdateProductImageUrl');
                if (imageUrlField) {
                    imageUrlField.value = product.productImg || '';
                    updateUpdateProductImagePreview();
                }
                
                console.log('✅ Form fields populated successfully');
            } else {
                showNotification('error', 'Load Failed', 'Failed to load product data: ' + (response.error || 'Unknown error'));
                closeUpdateProductModal();
            }
        },
        error: function(xhr, status, error) {
            console.error('❌ Failed to load product data:', status, error);
            
            let errorMessage = 'Failed to load product data.';
            try {
                const response = JSON.parse(xhr.responseText);
                if (response.error) {
                    errorMessage = response.error;
                }
            } catch (e) {
                errorMessage = 'Server error: ' + (xhr.statusText || error);
            }
            
            showNotification('error', 'Load Failed', errorMessage);
            closeUpdateProductModal();
        }
    });
}

function closeUpdateProductModal() {
    const modal = document.getElementById('updateProductModal');
    if (modal) {
        modal.classList.remove('show');
        modal.style.display = '';
        modal.style.visibility = '';
        modal.style.opacity = '';
        document.body.style.overflow = '';
    }
}

function updateProduct() {
    console.log('✏️ Update product functionality');
    
    // Get product ID from hidden field
    var hiddenId = document.getElementById('<%= hiddenProductId.ClientID %>');
    var productId = hiddenId ? hiddenId.value : '';
    
    if (!productId) {
        showNotification('error', 'Missing Information', 'Product ID not found. Please try again.');
        return;
    }
    
    // Get form values (with null checks)
    var txtUpdateProductName = document.getElementById('txtUpdateProductName');
    var ddlUpdateCategory = document.getElementById('ddlUpdateCategory');
    var txtUpdateDescription = document.getElementById('txtUpdateDescription');
    var txtUpdateBaseIngredients = document.getElementById('txtUpdateBaseIngredients');
    var ddlUpdateSupplier = document.getElementById('ddlUpdateSupplier');
    var txtUpdateProductImageUrl = document.getElementById('txtUpdateProductImageUrl');
    
    var productName = txtUpdateProductName ? txtUpdateProductName.value.trim() : '';
    var category = ddlUpdateCategory ? ddlUpdateCategory.value : '';
    var description = txtUpdateDescription ? txtUpdateDescription.value.trim() : '';
    var baseIngredients = txtUpdateBaseIngredients ? txtUpdateBaseIngredients.value.trim() : '';
    var supplierId = ddlUpdateSupplier ? ddlUpdateSupplier.value : '';
    var imageUrl = txtUpdateProductImageUrl ? txtUpdateProductImageUrl.value.trim() : '';
    
    // Validate required fields
    if (!productName) {
        showNotification('warning', 'Validation Error', 'Product name is required.');
        if (txtUpdateProductName) txtUpdateProductName.focus();
        return;
    }
    
    if (!category) {
        showNotification('warning', 'Validation Error', 'Category is required.');
        if (ddlUpdateCategory) ddlUpdateCategory.focus();
        return;
    }
    
    // Show loading state
    const updateBtn = document.querySelector('#updateProductModal .btn-primary');
    const originalText = updateBtn ? updateBtn.innerHTML : '';
    if (updateBtn) {
        updateBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> <span>Updating...</span>';
        updateBtn.disabled = true;
    }
    
    // Prepare data for update
    var updateData = {
        productId: productId,
        productName: productName,
        category: category,
        description: description,
        baseIngredients: baseIngredients,
        supplierId: supplierId,
        imageUrl: imageUrl,
        productValue: 0 // You can add product value field later
    };
    
    // Send update request
    $.ajax({
        type: "POST",
        url: "/Handlers/UpdateProduct.ashx",
        data: JSON.stringify(updateData),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function(response) {
            console.log('✅ Update product response:', response);
            
            if (response.success) {
                showNotification('success', 'Product Updated', 'Product updated successfully!', true, 3000);
                closeUpdateProductModal();
                
                // Reload page to refresh product list
                setTimeout(function() {
                    window.location.reload();
                }, 3500);
            } else {
                showNotification('error', 'Update Failed', 'Failed to update product: ' + (response.error || 'Unknown error'));
            }
        },
        error: function(xhr, status, error) {
            console.error('❌ Update product failed:', status, error);
            
            let errorMessage = 'Failed to update product.';
            try {
                const response = JSON.parse(xhr.responseText);
                if (response.error) {
                    errorMessage = response.error;
                }
            } catch (e) {
                errorMessage = 'Server error: ' + (xhr.statusText || error);
            }
            
            showNotification('error', 'Update Failed', errorMessage);
        },
        complete: function() {
            // Restore button state
            if (updateBtn) {
                updateBtn.innerHTML = originalText;
                updateBtn.disabled = false;
            }
        }
    });
}

function showUpdateVariantModal(variantId) {
    console.log('✏️ Update variant modal for:', variantId);
    showNotification('info', 'Coming Soon', 'Update variant functionality will be implemented soon.');
}

// ✴️ MISSING FUNCTION: closeConfirmationModal
function closeConfirmationModal() {
    const modal = document.getElementById('confirmationModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// ✴️ MISSING FUNCTION: confirmAction  
function confirmAction() {
    // This will be implemented based on the specific action being confirmed
    console.log('🔘 Confirm action called');
    closeConfirmationModal();
}

// ================= Notification modal (dialog) implementation =================
function showNotification(type, title, message, autoHide, duration) {
    var modal = document.getElementById('notificationModal');
    var icon = document.getElementById('notificationIcon');
    var titleEl = document.getElementById('notificationTitle');
    var messageEl = document.getElementById('notificationMessage');
    var progress = document.getElementById('notificationProgress');

    if (!modal || !icon || !titleEl || !messageEl) {
        // Fallback: if modal markup missing, do nothing
        return;
    }

    // Content
    titleEl.textContent = title || '';
    messageEl.textContent = message || '';

    // Icon + color
    var t = (type || 'info');
    icon.className = 'notification-icon ' + t;
    var iconHtml = '<i class="fa fa-info-circle"></i>';
    if (t === 'success') iconHtml = '<i class="fa fa-check"></i>';
    else if (t === 'error') iconHtml = '<i class="fa fa-times"></i>';
    else if (t === 'warning') iconHtml = '<i class="fa fa-exclamation-triangle"></i>';
    icon.innerHTML = iconHtml;

    // Show modal
    modal.classList.add('show');

    // Auto-hide support
    if (autoHide) {
        var ms = duration || 3000;
        if (progress) {
            modal.classList.add('auto-hide');
            progress.style.animationDuration = ms + 'ms';
            progress.style.width = '100%';
        }
        setTimeout(function(){ closeNotificationModal(); }, ms);
    }
}

function closeNotificationModal() {
    var modal = document.getElementById('notificationModal');
    var progress = document.getElementById('notificationProgress');
    if (!modal) return;
    modal.classList.remove('show','auto-hide');
    if (progress){ progress.style.width='0%'; progress.style.animationDuration=''; }
}

// confirmation for saving product
function openConfirmSaveProduct(){
    var name = document.getElementById('<%= txtProductName.ClientID %>').value.trim();
    var category = document.getElementById('<%= ddlCategory.ClientID %>').value;
    if(!name){ showNotification('warning','Validation','Product name is required.'); return false; }
    if(!category){ showNotification('warning','Validation','Category is required.'); return false; }

    var modal = document.getElementById('confirmationModal');
    if(!modal){ return true; }
    document.getElementById('confirmationTitle').textContent = 'Confirm Add Product';
    document.getElementById('confirmationMessage').textContent = 'Add product "' + name + '" to ' + category + '?';
    modal.classList.add('show');

    // set confirm handler once
    var btn = document.getElementById('confirmationConfirmBtn');
    btn.onclick = function(){
        modal.classList.remove('show');
        // set client guard and trigger server postback
        if(window.__savingProduct){ return; }
        window.__savingProduct = true;
        // Use WebForms postback to call server handler
        __doPostBack('<%= btnSaveProduct.UniqueID %>', '');
    };
    return false; // prevent immediate submit
}

// ===== Appended: ensure fetchVariants + viewProductVariants exist (no removals) =====
if (typeof window.fetchVariants !== 'function') {
    window.fetchVariants = function(productId){
        // Prefer handler first
        var path = window.location.pathname.replace(/\\/g,'/');
        var idx = path.toLowerCase().indexOf('/webpages/');
        var root = (idx>-1)? path.substring(0, idx+1) : '/';
        var handlerUrl = root + 'Handlers/GetProductVariants.ashx';
        return $.ajax({
            type:'POST', url:handlerUrl,
            data: JSON.stringify({ productId: productId }),
            contentType:'application/json; charset=utf-8', dataType:'json'
        }).then(function(r){ return r; })
        .catch(function(){
            // Fallback to page WebMethod
            return $.ajax({
                type:'POST', url:(window.GET_VARIANTS_URL||'/WebPages/ProductPage.aspx/GetProductVariants'),
                data: JSON.stringify({ productId: productId }),
                contentType:'application/json; charset=utf-8', dataType:'json'
            }).then(function(r){ return (r && r.d)? r.d : r; });
        });
    };
}

if (typeof window.viewProductVariants !== 'function') {
    window.viewProductVariants = function(productId, productName){
        try{
            currentProductId = productId; currentProductName = productName || '';
            var modal = document.getElementById('viewVariantsModal');
            if(modal){ modal.classList.add('show'); modal.style.display='flex'; modal.style.visibility='visible'; document.body.style.overflow='hidden'; }
            var nameEl = document.getElementById('viewVariantsProductName'); if(nameEl) nameEl.textContent = currentProductName || 'Product';
            var meta = document.getElementById('viewVariantsMeta'); if(meta) meta.textContent = 'Loading…';
            var tbody = document.getElementById('variantsTableBody'); if(tbody) tbody.innerHTML = '<tr><td colspan="9" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading…</td></tr>';
            if(typeof window.fetchVariants === 'function'){
                window.fetchVariants(productId).then(function(payload){
                    var data = payload && payload.d ? payload.d : payload;
                    if(typeof data === 'string'){ try{ data = JSON.parse(data); }catch(_){ } }
                    var list = [];
                    if(Array.isArray(data)) list = data; else if(data && data.success && Array.isArray(data.variants)) list = data.variants;
                    if(tbody){
                        if(!list.length){
                            tbody.innerHTML = '<tr><td colspan="9" class="text-center">No variants</td></tr>';
                        } else {
                            tbody.innerHTML = list.map(function(v,i){
                                return '<tr>'+
                                    '<td>'+(i+1)+'</td>'+
                                    '<td>'+(v.VariantName||'')+'</td>'+
                                    '<td>'+(v.SKU||'')+'</td>'+
                                    '<td>'+ (v.Price!=null? v.Price : '') +'</td>'+
                                    '<td>'+ (v.StockQuantity!=null? v.StockQuantity : '') +'</td>'+
                                    '<td>'+ (v.IsLowStock? 'Low':'OK') +'</td>'+
                                    '<td>'+(v.Size||'')+'</td>'+
                                    '<td>'+(v.Color||'')+'</td>'+
                                    '<td></td>'+
                                '</tr>';
                            }).join('');
                        }
                    }
                    var summary = document.getElementById('viewVariantsSummary'); if(summary) summary.textContent = ' ('+ list.length +' variants)';
                    if(meta) meta.textContent='';
                }).catch(function(err){
                    if(tbody) tbody.innerHTML = '<tr><td colspan="9" class="text-center">Failed to load variants</td></tr>';
                    if(meta) meta.textContent='';
                    try{ console.error('viewProductVariants load error', err); }catch(_){ }
                    showNotification('error','Variants','Failed to load variants');
                });
            }
        }catch(e){ try{ console.error('viewProductVariants error', e); }catch(_){ } }
    };
}
// ===== End appended code =====

// ===== Patch: add GET fallback for fetchVariants without removing existing code =====
if (window.fetchVariants && !window.fetchVariantsPatched) {
    (function(){
        var originalFetchVariants = window.fetchVariants;
        window.fetchVariants = function(productId){
            return originalFetchVariants(productId).then(function(res){
                try {
                    // Normalize if string
                    if (typeof res === 'string') { try { res = JSON.parse(res); } catch(_) {} }
                    var ok = false;
                    if (Array.isArray(res) && res.length >= 0) ok = true;
                    if (res && res.success && Array.isArray(res.variants)) ok = true;
                    if (ok) return res; // good result from original POST / fallback
                } catch(_) { }
                // Attempt GET querystring call (handler reads Request["productId"] for GET, not JSON body)
                var path = window.location.pathname.replace(/\\/g,'/');
                var idx = path.toLowerCase().indexOf('/webpages/');
                var root = (idx>-1)? path.substring(0, idx+1) : '/';
                var handlerUrl = root + 'Handlers/GetProductVariants.ashx?productId=' + encodeURIComponent(productId);
                return $.ajax({ type:'GET', url: handlerUrl, dataType:'json' });
            }).catch(function(){
                // Direct GET fallback if POST completely failed
                var path = window.location.pathname.replace(/\\/g,'/');
                var idx = path.toLowerCase().indexOf('/webpages/');
                var root = (idx>-1)? path.substring(0, idx+1) : '/';
                var handlerUrl = root + 'Handlers/GetProductVariants.ashx?productId=' + encodeURIComponent(productId);
                return $.ajax({ type:'GET', url: handlerUrl, dataType:'json' });
            });
        };
        window.fetchVariantsPatched = true;
    })();
}
// ===== End patch =====

// ===== Patch: capture variants in cache & inject Action buttons (non-destructive) =====
(function(){
    if(!window.__variantsCache){ window.__variantsCache = {}; }

    // Wrap fetchVariants once more (do not remove previous logic) to cache variants list
    if(window.fetchVariants && !window.fetchVariantsCachePatched){
        var originalFV = window.fetchVariants;
        window.fetchVariants = function(productId){
            return originalFV(productId).then(function(res){
                try {
                    var data = res && res.d ? res.d : res;
                    if(typeof data === 'string'){ try { data = JSON.parse(data); } catch(_){} }
                    var list = [];
                    if(Array.isArray(data)) list = data; else if(data && data.success && Array.isArray(data.variants)) list = data.variants;
                    if(list.length >= 0){ window.__variantsCache[productId] = list; }
                } catch(_){}
                return res;
            });
        };
        window.fetchVariantsCachePatched = true;
    }

    // Utility to safely escape quotes for inline handlers
    function esc(str){ return (str||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/\"/g,'&quot;'); }

    function injectVariantActions(){
        try{
            var tbody = document.getElementById('variantsTableBody');
            if(!tbody) return;
            var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
            if(!rows.length) return;
            var list = window.__variantsCache && window.__variantsCache[currentProductId];
            if(!Array.isArray(list) || !list.length) return; // nothing to map yet
            rows.forEach(function(r){
                var cells = r.children;
                if(!cells || cells.length < 9) return; // skip placeholder rows
                var actionCell = cells[cells.length-1];
                if(!actionCell) return;
                if(/fa-trash|showDeleteVariantModal|showUpdateVariantModal/.test(actionCell.innerHTML)) return; // already injected
                var indexText = cells[0].textContent.trim();
                var idx = parseInt(indexText,10) - 1;
                if(isNaN(idx) || idx < 0 || idx >= list.length) return;
                var v = list[idx];
                var vid = v.Id || v.id || '';
                var vname = esc(v.VariantName || v.variantName || 'Variant');
                actionCell.innerHTML = ''+
                  '<button type="button" class="icon" title="Edit Variant" onclick="event.stopPropagation(); showUpdateVariantModal(\''+ esc(vid) +'\');">'+
                     '<i class="fa fa-pen"></i>'+
                  '</button>'+
                  '<button type="button" class="icon" title="Delete Variant" onclick="event.stopPropagation(); showDeleteVariantModal(\''+ esc(vid) +'\', \''+ vname +'\');">'+
                     '<i class="fa fa-trash"></i>'+
                  '</button>';
            });
        }catch(e){ try{ console.error('injectVariantActions error', e); }catch(_){} }
    }

    // MutationObserver to react when variant rows are rendered
    if(!window.__variantActionObserver){
        var tbody = document.getElementById('variantsTableBody');
        if(tbody && window.MutationObserver){
            var obs = new MutationObserver(function(){ injectVariantActions(); });
            obs.observe(tbody, { childList:true, subtree:false });
            window.__variantActionObserver = obs;
        }
    }

    // Expose manual trigger (debug)
    window.refreshVariantActions = injectVariantActions;
})();
// ===== End action buttons patch =====

// ===== Append: Dynamic Update Variant Modal + logic (non-destructive) =====
(function(){
    if(!document.getElementById('updateVariantModal')){
        var modalHtml = ''+
        '<div id="updateVariantModal" class="modal-overlay">'+
          '<div class="modal-container" style="max-width:720px;">'+
            '<div class="modal-header">'+
              '<h2 class="modal-title"><i class="fa fa-pen"></i> Update Variant</h2>'+
              '<button class="modal-close" onclick="closeUpdateVariantModal()"><i class="fa fa-times"></i></button>'+
            '</div>'+
            '<div class="modal-body" style="padding:30px;">'+
              '<input type="hidden" id="updVariantId" />'+
              '<input type="hidden" id="updVariantProductId" />'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Variant Name *</label><input type="text" id="updVariantName" class="form-control" placeholder="Variant name" /></div>'+
                '<div class="form-group"><label class="form-label">SKU *</label><input type="text" id="updVariantSKU" class="form-control" placeholder="SKU" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Size</label><input type="text" id="updVariantSize" class="form-control" placeholder="Size" /></div>'+
                '<div class="form-group"><label class="form-label">Color</label><input type="text" id="updVariantColor" class="form-control" placeholder="Color" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Price *</label><input type="number" step="0.01" id="updVariantPrice" class="form-control" placeholder="0.00" /></div>'+
                '<div class="form-group"><label class="form-label">Stock *</label><input type="number" id="updVariantStock" class="form-control" placeholder="0" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Minimum Stock</label><input type="number" id="updVariantMinStock" class="form-control" placeholder="0" /></div>'+
                '<div class="form-group"><label class="form-label">Weight (g)</label><input type="number" step="0.01" id="updVariantWeight" class="form-control" placeholder="0.00" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Dimensions</label><input type="text" id="updVariantDimensions" class="form-control" placeholder="L x W x H" /></div>'+
                '<div class="form-group"><label class="form-label">Image URL</label><input type="text" id="updVariantImg" class="form-control" placeholder="https://..." /></div>'+
              '</div>'+
              '<div class="form-group"><label class="form-label">Lifespan / Best Before (years)</label><input type="number" id="updVariantShelfLifeYears" class="form-control" placeholder="1" /><small style="color:#666;font-size:12px;margin-top:5px;display:block;">How many years the product stays fresh (e.g., 1 for 1 year)</small></div>'+
              <!-- ✅ CHANGED: Location is now a dropdown instead of readonly text input -->
              '<div class="form-group"><label class="form-label">Storage Location *</label><select id="updVariantLocation" class="form-control"><option value="">Select location...</option></select><small style="color:#666;font-size:11px;margin-top:5px;display:block;"><i class="fa fa-info-circle"></i> Location options are based on the product category</small></div>'+
              '<div id="updVariantMsg" style="display:none; margin-top:5px; font-size:12px;"></div>'+
            '</div>'+
            '<div class="modal-footer">'+
              '<button type="button" class="btn-animated btn-secondary" onclick="closeUpdateVariantModal()"><i class="fa fa-times"></i><span>Cancel</span></button>'+
              '<button type="button" class="btn-animated btn-primary" id="btnDoUpdateVariant" onclick="updateVariantSave()"><i class="fa fa-save"></i><span>Save</span></button>'+
            '</div>'+
          '</div>'+
        '</div>';
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    }

    window.closeUpdateVariantModal = function(){
        var m = document.getElementById('updateVariantModal');
        if(m){ m.classList.remove('show'); m.style.display='none'; m.style.visibility='hidden'; document.body.style.overflow=''; }
    };

    // ✅ NEW: Function to populate location dropdown based on product category
    function updateUpdateVariantLocationDropdown(category, currentLocation) {
        var locationDropdown = document.getElementById('updVariantLocation');
        if (!locationDropdown) return;

        var locationsByCategory = {
            'Skincare': ['SC1', 'SC2', 'SC3', 'SC4', 'SC5'],
            'Makeup': ['MU1', 'MU2', 'MU3', 'MU4', 'MU5'],
            'Haircare': ['HC1', 'HC2', 'HC3', 'HC4', 'HC5'],
            'Fragrance': ['FR1', 'FR2', 'FR3', 'FR4', 'FR5'],
            'Body Care': ['BC1', 'BC2', 'BC3', 'BC4', 'BC5']
        };

        // Clear existing options
        locationDropdown.innerHTML = '';

        if (!category || !locationsByCategory[category]) {
            var option = document.createElement('option');
            option.value = '';
            option.textContent = 'Category not available';
            locationDropdown.appendChild(option);
            locationDropdown.disabled = true;
            return;
        }

        // Enable dropdown and add placeholder
        locationDropdown.disabled = false;
        var placeholderOption = document.createElement('option');
        placeholderOption.value = '';
        placeholderOption.textContent = 'Select Location...';
        locationDropdown.appendChild(placeholderOption);

        // Add location options for the category
        var locations = locationsByCategory[category];
        locations.forEach(function(location) {
            var option = document.createElement('option');
            option.value = location;
            option.textContent = location + ' - ' + category + ' Storage';
            if (currentLocation && location === currentLocation) {
                option.selected = true;
            }
            locationDropdown.appendChild(option);
        });

        console.log('✅ Update variant location dropdown populated with', locations.length, 'options for', category);
    }

    function fillUpdateVariantForm(variant){
        if(!variant) return;
        document.getElementById('updVariantId').value = variant.Id || variant.id || '';
        document.getElementById('updVariantProductId').value = variant.ProductId || variant.productId || currentProductId || '';
        document.getElementById('updVariantName').value = variant.VariantName || variant.variantName || '';
        document.getElementById('updVariantSKU').value = variant.SKU || variant.sku || '';
        document.getElementById('updVariantSize').value = variant.Size || variant.size || '';
        document.getElementById('updVariantColor').value = variant.Color || variant.color || '';
        document.getElementById('updVariantPrice').value = (variant.Price != null ? variant.Price : '');
        document.getElementById('updVariantStock').value = (variant.StockQuantity != null ? variant.StockQuantity : '');
        document.getElementById('updVariantMinStock').value = (variant.MinimumStock != null ? variant.MinimumStock : '');
        document.getElementById('updVariantWeight').value = (variant.Weight != null ? variant.Weight : '');
        document.getElementById('updVariantDimensions').value = (variant.Dimensions || variant.dimensions || '');
        document.getElementById('updVariantImg').value = (variant.VariantImg || variant.variantImg || '');
        
        // ✅ Fill shelf life years
        var shelfLifeYears = variant.ShelfLifeYears || variant.shelfLifeYears;
        document.getElementById('updVariantShelfLifeYears').value = shelfLifeYears || '';
        
        // ✅ Get product category and populate location dropdown
        var productId = variant.ProductId || variant.productId || currentProductId;
        var currentLocation = variant.Location || variant.location || '';
        
        // Get category from the product row in the table
        var productRow = document.querySelector('[data-product-id="' + productId + '"]');
        if (productRow) {
            var category = productRow.getAttribute('data-category');
            console.log('📍 Populating location dropdown for category:', category);
            updateUpdateVariantLocationDropdown(category, currentLocation);
        } else {
            console.warn('⚠️ Product row not found, using current location as text');
            // Fallback: just show the current location
            var locationDropdown = document.getElementById('updVariantLocation');
            if (locationDropdown && currentLocation) {
                locationDropdown.innerHTML = '<option value="' + currentLocation + '" selected>' + currentLocation + '</option>';
            }
        }
        
        var msg = document.getElementById('updVariantMsg'); if(msg){ msg.style.display='none'; msg.textContent=''; }
    }

    // Override previous placeholder (always override to ensure real logic active)
    window.showUpdateVariantModal = function(variantId){
        try{
            var list = (window.__variantsCache && window.__variantsCache[currentProductId]) || [];
            var variant = list.find(function(v){ return (v.Id||v.id)==variantId; });
            if(!variant){
                showNotification('error','Variant','Variant not found in cache. Refreshing…');
                // Force refetch then reopen
                fetchVariants(currentProductId).then(function(){
                    var list2 = (window.__variantsCache && window.__variantsCache[currentProductId]) || [];
                    variant = list2.find(function(v){ return (v.Id||v.id)==variantId; });
                    fillUpdateVariantForm(variant);
                    openModalVariant();
                });
            } else {
                fillUpdateVariantForm(variant);
                openModalVariant();
            }
        }catch(e){ console.error('showUpdateVariantModal error', e); }
    };

    function openModalVariant(){
        var m = document.getElementById('updateVariantModal');
        if(m){ m.classList.add('show'); m.style.display='flex'; m.style.visibility='visible'; document.body.style.overflow='hidden'; }
    }

    window.updateVariantSave = function(){
        var btn = document.getElementById('btnDoUpdateVariant');
        if(btn){ btn.disabled=true; btn.innerHTML='<i class="fa fa-spinner fa-spin"></i><span> Saving...</span>'; }
        
        // ✅ Get shelf life years
        var shelfLifeYears = document.getElementById('updVariantShelfLifeYears').value;
        
        // ✅ Get location from dropdown
        var locationDropdown = document.getElementById('updVariantLocation');
        var location = locationDropdown ? locationDropdown.value.trim() : '';
        
        var payload = {
            variantId: document.getElementById('updVariantId').value.trim(),
            variantName: document.getElementById('updVariantName').value.trim(),
            variantSKU: document.getElementById('updVariantSKU').value.trim(),
            variantSize: document.getElementById('updVariantSize').value.trim(),
            variantColor: document.getElementById('updVariantColor').value.trim(),
            variantPrice: parseFloat(document.getElementById('updVariantPrice').value) || 0,
            variantStock: parseInt(document.getElementById('updVariantStock').value) || 0,
            variantMinStock: parseInt(document.getElementById('updVariantMinStock').value) || 0,
            variantWeight: document.getElementById('updVariantWeight').value? parseFloat(document.getElementById('updVariantWeight').value): null,
            variantDimensions: document.getElementById('updVariantDimensions').value.trim(),
            variantImg: document.getElementById('updVariantImg').value.trim(),
            shelfLifeYears: shelfLifeYears ? parseInt(shelfLifeYears) : null,
            location: location
        };

        if(!payload.variantId || !payload.variantName || !payload.variantSKU || payload.variantPrice<=0){
            showNotification('warning','Validation','Fill required fields (Name, SKU, Price>0)');
            if(btn){ btn.disabled=false; btn.innerHTML='<i class="fa fa-save"></i><span> Save</span>'; }
            return;
        }

        $.ajax({
            type:'POST',
            url:'/Handlers/UpdateVariant.ashx',
            data: JSON.stringify(payload),
            contentType:'application/json; charset=utf-8',
            dataType:'json',
            cache: false  // Prevent caching of POST request
        }).done(function(res){
            if(res && res.success){
                showNotification('success','Variant Updated', res.message || 'Updated', true, 2500);
                closeUpdateVariantModal();
                
                // Clear browser history state to prevent form resubmission dialog
                if (window.history && window.history.replaceState) {
                    window.history.replaceState(null, null, window.location.href);
                }
                
                // Refresh variants listing without page reload
                if(currentProductId && currentProductName){
                    fetchVariants(currentProductId).then(function(){ 
                        viewProductVariants(currentProductId, currentProductName); 
                    });
                }
            } else {
                showNotification('error','Update Failed', (res && res.error)||'Unknown error');
            }
        }).fail(function(xhr){
            var msg='Server error';
            try{ var r=JSON.parse(xhr.responseText); if(r.error) msg=r.error; }catch(_){}
            showNotification('error','Update Failed', msg);
        }).always(function(){
            if(btn){ btn.disabled=false; btn.innerHTML='<i class="fa fa-save"></i><span> Save</span>'; }
        });
    };
})();

// ===== Append: Add Variant (existing product) modal + handler integration =====
(function(){
    if(!document.getElementById('addVariantActionModal')){
        var html = ''+
        '<div id="addVariantActionModal" class="modal-overlay">'+
          '<div class="modal-container" style="max-width:720px; display:flex; flex-direction:column; max-height:90vh;">'+
            '<div class="modal-header">'+
              '<h2 class="modal-title"><i class="fa fa-layer-group"></i> Add Variant</h2>'+
              '<button class="modal-close" onclick="closeAddVariantActionModal()"><i class="fa fa-times"></i></button>'+
            '</div>'+
            '<div class="modal-body" style="padding:30px; flex:1; overflow-y:auto; max-height:calc(90vh - 180px);">'+
              '<div style="margin-bottom:15px; font-size:13px; color:#666;">Product: <span id="addVariantProductName" style="font-weight:600;"></span></div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Variant Name *</label><input type="text" id="newVariantName" class="form-control" placeholder="Variant name" /></div>'+
                '<div class="form-group"><label class="form-label">SKU *</label><input type="text" id="newVariantSKU" class="form-control" placeholder="SKU" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Size</label><input type="text" id="newVariantSize" class="form-control" placeholder="Size" /></div>'+
                '<div class="form-group"><label class="form-label">Color</label><input type="text" id="newVariantColor" class="form-control" placeholder="Color" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Price *</label><input type="number" step="0.01" id="newVariantPrice" class="form-control" placeholder="0.00" /></div>'+
                '<div class="form-group"><label class="form-label">Stock *</label><input type="number" id="newVariantStock" class="form-control" placeholder="0" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Minimum Stock</label><input type="number" id="newVariantMinStock" class="form-control" placeholder="5" value="5" /></div>'+
                '<div class="form-group"><label class="form-label">Weight (g)</label><input type="number" step="0.01" id="newVariantWeight" class="form-control" placeholder="0.00" /></div>'+
              '</div>'+
              '<div class="form-row">'+
                '<div class="form-group"><label class="form-label">Dimensions</label><input type="text" id="newVariantDimensions" class="form-control" placeholder="L x W x H" /></div>'+
                '<div class="form-group"><label class="form-label">Image URL</label><input type="text" id="newVariantImg" class="form-control" placeholder="https://..." /></div>'+
              '</div>'+
              '<div class="form-group"><label class="form-label">Lifespan / Best Before (years)</label><input type="number" id="newVariantShelfLifeYears" class="form-control" placeholder="1" /><small style="color:#666;font-size:12px;margin-top:5px;display:block;">How many years the product stays fresh (e.g., 1 for 1 year)</small></div>'+
              // 📍 CHANGED: Location is now a dropdown instead of readonly text input
              '<div class="form-group"><label class="form-label">Storage Location *</label><select id="newVariantLocation" class="form-control"><option value="">Select location...</option></select><small style="color:#666;font-size:11px;margin-top:5px;display:block;"><i class="fa fa-info-circle"></i> Location options are based on the product category</small></div>'+
              '<div id="newVariantMsg" style="display:none; font-size:12px; margin-top:5px;"></div>'+
            '</div>'+
            '<div class="modal-footer" style="flex-shrink:0;">'+
              '<button type="button" class="btn-animated btn-secondary" onclick="closeAddVariantActionModal()"><i class="fa fa-times"></i><span>Cancel</span></button>'+
              '<button type="button" class="btn-animated btn-primary" id="btnSaveNewVariant" onclick="saveNewVariant()"><i class="fa fa-save"></i><span>Save Variant</span></button>'+
            '</div>'+
          '</div>'+
        '</div>';
        document.body.insertAdjacentHTML('beforeend', html);
    }

    function clearAddVariantForm(){
        ['newVariantName','newVariantSKU','newVariantSize','newVariantColor','newVariantPrice','newVariantStock','newVariantMinStock','newVariantWeight','newVariantDimensions','newVariantImg','newVariantShelfLifeYears'].forEach(function(id){ var el=document.getElementById(id); if(el){ if(id==='newVariantMinStock') { el.value = '5'; } else { el.value=''; }} });
        var msg=document.getElementById('newVariantMsg'); if(msg){ msg.style.display='none'; msg.textContent=''; }
    }

    window.showVariantModal = function(productId, productName){
        currentProductId = productId; currentProductName = productName || '';
        var m = document.getElementById('addVariantActionModal');
        if(!m){ return; }
        clearAddVariantForm();
        var nameEl = document.getElementById('addVariantProductName'); if(nameEl) nameEl.textContent = productName || productId || '';
        m.classList.add('show'); m.style.display='flex'; m.style.visibility='visible'; document.body.style.overflow='hidden';
        setTimeout(function(){ var f = document.getElementById('newVariantName'); if(f) f.focus(); }, 50);
    };

    window.closeAddVariantActionModal = function(){
        var m = document.getElementById('addVariantActionModal'); if(m){ m.classList.remove('show'); m.style.display='none'; m.style.visibility='hidden'; document.body.style.overflow=''; }
    };

    window.saveNewVariant = function(){
        if(!currentProductId){ showNotification('error','Missing','No product selected.'); return; }
        var btn = document.getElementById('btnSaveNewVariant');
        
        // ✅ Get shelf life years
        var shelfLifeYears = document.getElementById('newVariantShelfLifeYears').value;
        
        // ✅ Get location from dropdown
        var locationDropdown = document.getElementById('newVariantLocation');
        var location = locationDropdown ? locationDropdown.value.trim() : '';
        
        var payload = {
            ProductId: currentProductId,
            VariantName: (document.getElementById('newVariantName').value||'').trim(),
            SKU: (document.getElementById('newVariantSKU').value||'').trim(),
            Size: (document.getElementById('newVariantSize').value||'').trim(),
            Color: (document.getElementById('newVariantColor').value||'').trim(),
            Price: parseFloat(document.getElementById('newVariantPrice').value)||0,
            StockQuantity: parseInt(document.getElementById('newVariantStock').value)||0,
            MinimumStock: parseInt(document.getElementById('newVariantMinStock').value)||5,
            Weight: document.getElementById('newVariantWeight').value? parseFloat(document.getElementById('newVariantWeight').value): null,
            Dimensions: (document.getElementById('newVariantDimensions').value||'').trim(),
            VariantImg: (document.getElementById('newVariantImg').value||'').trim(),
            ShelfLifeYears: shelfLifeYears ? parseInt(shelfLifeYears) : null,
            Location: location
        };
        if(!payload.VariantName || !payload.SKU || payload.Price<=0){
            showNotification('warning','Validation','Variant Name, SKU and Price > 0 required');
            return;
        }
        if(btn){ btn.disabled=true; btn.innerHTML='<i class="fa fa-spinner fa-spin"></i><span> Saving...</span>'; }
        $.ajax({
            type:'POST', url:'/Handlers/AddProductVariant.ashx',
            data: JSON.stringify(payload), contentType:'application/json; charset=utf-8', dataType:'json',
            cache: false  // Prevent caching of POST request
        }).done(function(res){
            if(res && res.success){
                showNotification('success','Variant Added', res.message||'Saved', true, 2500);
                closeAddVariantActionModal();
                
                // refresh variant list if variants modal open
                if(document.getElementById('viewVariantsModal') && document.getElementById('viewVariantsModal').classList.contains('show')){
                    fetchVariants(currentProductId).then(function(){ viewProductVariants(currentProductId, currentProductName); });
                }
            } else {
                showNotification('error','Add Failed', (res && res.error)||'Unknown error');
            }
        }).fail(function(xhr){
            var msg='Server error';
            try{ var r=JSON.parse(xhr.responseText); if(r.error) msg=r.error; }catch(_){}
            showNotification('error','Add Failed', msg);
        }).always(function(){ if(btn){ btn.disabled=false; btn.innerHTML='<i class="fa fa-save"></i><span> Save Variant</span>'; }});
    };
})();

// ===== Patch: improve modal closing & auto-hide notifications =====
(function(){
    // Ensure modal close functions fully hide overlays (use display:none)
    function safeHide(id){ var el=document.getElementById(id); if(el){ el.classList.remove('show'); el.style.display='none'; el.style.visibility='hidden'; el.style.opacity='0'; } }
    if(window.closeAddVariantActionModal){ var orig=window.closeAddVariantActionModal; window.closeAddVariantActionModal=function(){ orig(); safeHide('addVariantActionModal'); document.body.style.overflow=''; }; }
    if(window.closeUpdateVariantModal){ var orig2=window.closeUpdateVariantModal; window.closeUpdateVariantModal=function(){ orig2(); safeHide('updateVariantModal'); document.body.style.overflow=''; }; }
    if(window.closeViewVariantsModal){ var orig3=window.closeViewVariantsModal; window.closeViewVariantsModal=function(){ orig3(); safeHide('viewVariantsModal'); document.body.style.overflow=''; }; }

    // Wrap notification to default auto-hide for success if not specified
    if(window.showNotification && !window.__notifPatched){
        var baseFn = window.showNotification;
        window.showNotification = function(type,title,message,autoHide,duration){
            if(type==='success' && (autoHide===undefined||autoHide===null)){ autoHide=true; duration = duration||2500; }
            return baseFn(type,title,message,autoHide,duration);
        };
        window.__notifPatched=true;
    }   

    // Force auto-hide on existing success flows if functions exist
    if(window.saveNewVariant){
        var originalSaveNewVariant = window.saveNewVariant;
        window.saveNewVariant = function(){
            // Monkey patch jQuery ajax success inside by temporarily overriding showNotification flag
            var prev = window.showNotification;
            window.showNotification = function(type,title,message,autoHide,duration){
                if(type==='success'){ autoHide=true; duration=duration||2500; }
                return prev(type,title,message,autoHide,duration);
            };
            try { return originalSaveNewVariant(); } finally { window.showNotification = prev; }
        };
    }
    if(window.updateVariantSave){
        var originalUpdateVariantSave = window.updateVariantSave;
        window.updateVariantSave = function(){
            var prev = window.showNotification;
            window.showNotification = function(type,title,message,autoHide,duration){
                if(type==='success'){ autoHide=true; duration=duration||2500; }
                return prev(type,title,message,autoHide,duration);
            };
            try { return originalUpdateVariantSave(); } finally { window.showNotification = prev; }
        };
    }
})();

// ===== NEW: Search, Filter, and Sort Functionality =====
(function(){
    // Global filter state
    window.filterState = {
        searchTerm: '',
        category: 'All',
        sortBy: 'name' // name, price, stock, date
    };

    // Setup search functionality
    window.setupSearch = function() {
        var searchBox = document.getElementById('<%= txtSearch.ClientID %>');
        if (searchBox) {
            // Debounce search to avoid filtering on every keystroke
            var searchTimeout;
            searchBox.addEventListener('input', function(e) {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(function() {
                    window.filterState.searchTerm = searchBox.value.trim().toLowerCase();
                    applyFilters();
                }, 300);
            });
            console.log('✅ Search functionality initialized');
        }
    };

    // Setup filter and sort functionality
    window.setupFilters = function() {
        console.log('🔧 Setting up filters and sorting...');
        
        // Setup category filter dropdown
        var filterBtn = document.querySelector('.toolbar-group button[title="Filter"]');
        if (filterBtn) {
            // Create dropdown menu for categories
            var filterDropdown = document.createElement('div');
            filterDropdown.className = 'filter-dropdown';
            filterDropdown.style.cssText = 'position:absolute; top:100%; left:0; background:white; border:1px solid #e9ecef; border-radius:8px; box-shadow:0 4px 12px rgba(0,0,0,0.1); min-width:200px; display:none; z-index:1000; margin-top:5px;';
            
            var categories = ['All', 'Skincare', 'Makeup', 'Haircare', 'Fragrance', 'Body Care'];
            categories.forEach(function(cat) {
                var item = document.createElement('div');
                item.textContent = cat;
                item.style.cssText = 'padding:12px 16px; cursor:pointer; transition:background 0.2s;';
                item.onmouseover = function() { this.style.background = '#f8f9fa'; };
                item.onmouseout = function() { this.style.background = 'white'; };
                item.onclick = function() {
                    window.filterState.category = cat;
                    filterBtn.querySelector('.btn-text').textContent = 'Filter : ' + cat;
                    filterDropdown.style.display = 'none';
                    applyFilters();
                };
                filterDropdown.appendChild(item);
            });
            
            filterBtn.parentElement.style.position = 'relative';
            filterBtn.parentElement.appendChild(filterDropdown);
            
            filterBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                var isVisible = filterDropdown.style.display === 'block';
                filterDropdown.style.display = isVisible ? 'none' : 'block';
            });
            
            // Close dropdown when clicking outside
            document.addEventListener('click', function(e) {
                if (!filterBtn.contains(e.target)) {
                    filterDropdown.style.display = 'none';
                }
            });
            
            console.log('✅ Filter dropdown initialized');
        }
        
        // Setup sort dropdown
        var sortBtn = document.querySelector('.toolbar-group button[title="Sort / Tag"]');
        if (sortBtn) {
            var sortDropdown = document.createElement('div');
            sortDropdown.className = 'sort-dropdown';
            sortDropdown.style.cssText = 'position:absolute; top:100%; left:0; background:white; border:1px solid #e9ecef; border-radius:8px; box-shadow:0 4px 12px rgba(0,0,0,0.1); min-width:200px; display:none; z-index:1000; margin-top:5px;';
            
            var sortOptions = [
                { value: 'name', label: '📝 Name (A-Z)' },
                { value: 'price-low', label: '💰 Price (Low to High)' },
                { value: 'price-high', label: '💰 Price (High to Low)' },
                { value: 'stock-low', label: '📦 Stock (Low to High)' },
                { value: 'stock-high', label: '📦 Stock (High to Low)' },
                { value: 'newest', label: '🆕 Newest First' },
                { value: 'oldest', label: '📅 Oldest First' }
            ];
            
            sortOptions.forEach(function(opt) {
                var item = document.createElement('div');
                item.textContent = opt.label;
                item.style.cssText = 'padding:12px 16px; cursor:pointer; transition:background 0.2s;';
                item.onmouseover = function() { this.style.background = '#f8f9fa'; };
                item.onmouseout = function() { this.style.background = 'white'; };
                item.onclick = function() {
                    window.filterState.sortBy = opt.value;
                    var label = opt.label.replace(/[📝💰📦🆕📅]/g, '').trim();
                    sortBtn.querySelector('.btn-text').textContent = label;
                    sortDropdown.style.display = 'none';
                    applyFilters();
                };
                sortDropdown.appendChild(item);
            });
            
            sortBtn.parentElement.style.position = 'relative';
            sortBtn.parentElement.appendChild(sortDropdown);
            
            sortBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                var isVisible = sortDropdown.style.display === 'block';
                sortDropdown.style.display = isVisible ? 'none' : 'block';
            });
            
            document.addEventListener('click', function(e) {
                if (!sortBtn.contains(e.target)) {
                    sortDropdown.style.display = 'none';
                }
            });
            
            console.log('✅ Sort dropdown initialized');
        }
    };

    // Apply filters and sorting to the product table
    function applyFilters() {
        console.log('🔍 Applying filters:', window.filterState);
        
        var tbody = document.getElementById('tblProducts');
        if (!tbody) return;
        
        var rows = Array.from(tbody.querySelectorAll('.row-select'));
        var visibleCount = 0;
        
        // Filter and collect rows with their data
        var filteredRows = rows.filter(function(row) {
            var name = (row.getAttribute('data-name') || '').toLowerCase();
            var category = row.getAttribute('data-category') || '';
            var sku = (row.getAttribute('data-sku') || '').toLowerCase();
            var supplier = (row.cells[4] ? row.cells[4].textContent : '').toLowerCase();
            
            // Search filter (search in name, SKU, category, supplier)
            var searchMatch = true;
            if (window.filterState.searchTerm) {
                var searchLower = window.filterState.searchTerm.toLowerCase();
                searchMatch = name.includes(searchLower) || 
                             sku.includes(searchLower) || 
                             category.toLowerCase().includes(searchLower) ||
                             supplier.includes(searchLower);
            }
            
            // Category filter
            var categoryMatch = window.filterState.category === 'All' || 
                               category === window.filterState.category;
            
            return searchMatch && categoryMatch;
        }).map(function(row) {
            // Extract data for sorting
            var priceText = row.getAttribute('data-color') || '₱0.00';
            var price = parseFloat(priceText.replace(/[₱,]/g, '').split('-')[0]) || 0;
            
            var stockText = row.getAttribute('data-stock') || '0';
            var stock = parseInt(stockText.replace(/[^0-9]/g, '')) || 0;
            
            var name = (row.getAttribute('data-name') || '').toLowerCase();
            
            // Try to get creation date from data attribute or use index
            var dateAttr = row.getAttribute('data-created') || '';
            var date = dateAttr ? new Date(dateAttr) : new Date(0);
            
            return { row: row, price: price, stock: stock, name: name, date: date };
        });
        
        // Sort filtered rows
        filteredRows.sort(function(a, b) {
            switch (window.filterState.sortBy) {
                case 'name':
                    return a.name.localeCompare(b.name);
                case 'price-low':
                    return a.price - b.price;
                case 'price-high':
                    return b.price - a.price;
                case 'stock-low':
                    return a.stock - b.stock;
                case 'stock-high':
                    return b.stock - a.stock;
                case 'newest':
                    return b.date - a.date;
                case 'oldest':
                    return a.date - b.date;
                default:
                    return 0;
            }
        });
        
        // Hide all rows first
        rows.forEach(function(row) {
            row.style.display = 'none';
        });
        
        // Show and reorder filtered rows
        var fragment = document.createDocumentFragment();
        filteredRows.forEach(function(item) {
            item.row.style.display = '';
            fragment.appendChild(item.row);
            visibleCount++;
        });
        
        // Append all filtered rows back to tbody
        tbody.appendChild(fragment);
        
        // Update stats or show no results message
        console.log('✅ Filter applied: ' + visibleCount + ' products visible');
        
        // Show "No results" message if needed
        var noResults = tbody.querySelector('.no-results-row');
        if (visibleCount === 0) {
            if (!noResults) {
                noResults = document.createElement('tr');
                noResults.className = 'no-results-row';
                noResults.innerHTML = '<td colspan="8" class="text-center" style="padding:40px;">' +
                    '<div style="color:#666; font-size:16px; margin-bottom:10px;">' +
                    '<i class="fa fa-search" style="font-size:48px; display:block; margin-bottom:15px; color:#ddd;"></i>' +
                    'No products found matching your search criteria' +
                    '</div>' +
                    '<button onclick="clearFilters()" class="btn-animated btn-primary" style="margin-top:10px;">' +
                    '<i class="fa fa-times"></i> Clear Filters' +
                    '</button>' +
                    '</td>';
                tbody.appendChild(noResults);
            }
        } else if (noResults) {
            noResults.remove();
        }
    }

    // Clear all filters
    window.clearFilters = function() {
        window.filterState = {
            searchTerm: '',
            category: 'All',
            sortBy: 'name'
        };
        
        var searchBox = document.getElementById('<%= txtSearch.ClientID %>');
        if (searchBox) searchBox.value = '';
        
        var filterBtn = document.querySelector('.toolbar-group button[title="Filter"] .btn-text');
        if (filterBtn) filterBtn.textContent = 'Filter : All';
        
        var sortBtn = document.querySelector('.toolbar-group button[title="Sort / Tag"] .btn-text');
        if (sortBtn) sortBtn.textContent = 'Best Seller';
        
        applyFilters();
        showNotification('info', 'Filters Cleared', 'All filters have been reset');
    };

    // Expose functions globally
    window.applyFilters = applyFilters;
})();
// ===== End Search, Filter, Sort =====

// ===== CATEGORY-BASED LOCATION LOGIC =====
(function(){
    // Location mappings by category
    var locationsByCategory = {
        'Skincare': ['SC1', 'SC2', 'SC3', 'SC4', 'SC5'],
        'Makeup': ['MU1', 'MU2', 'MU3', 'MU4', 'MU5'],
        'Haircare': ['HC1', 'HC2', 'HC3', 'HC4', 'HC5'],
        'Fragrance': ['FR1', 'FR2', 'FR3', 'FR4', 'FR5'],
        'Body Care': ['BC1', 'BC2', 'BC3', 'BC4', 'BC5']
    };

    // Function to update ASP.NET location dropdown (Add Variant Modal - ASP.NET)
    function updateLocationDropdownASPNET() {
        try {
            var categoryDropdown = document.getElementById('<%= ddlCategory.ClientID %>');
            if (!categoryDropdown) {
                console.log('❌ Category dropdown not found');
                return;
            }

            var selectedCategory = categoryDropdown.value;
            console.log('📍 Selected category:', selectedCategory);

            var locationDropdown = document.getElementById('<%= ddlVariantLocation.ClientID %>');
            if (!locationDropdown) {
                console.log('❌ Location dropdown not found');
                return;
            }

            // Clear existing options
            locationDropdown.innerHTML = '';

            if (!selectedCategory || !locationsByCategory[selectedCategory]) {
                var option = document.createElement('option');
                option.value = '';
                option.textContent = 'Select product category first...';
                locationDropdown.appendChild(option);
                locationDropdown.disabled = true;
                console.log('⚠️ No category selected, location dropdown disabled');
                return;
            }

            // Enable dropdown and add placeholder
            locationDropdown.disabled = false;
            var placeholderOption = document.createElement('option');
            placeholderOption.value = '';
            placeholderOption.textContent = 'Select Location...';
            locationDropdown.appendChild(placeholderOption);

            // Add location options for the selected category
            var locations = locationsByCategory[selectedCategory];
            locations.forEach(function(location) {
                var option = document.createElement('option');
                option.value = location;
                option.textContent = location + ' - ' + selectedCategory + ' Storage';
                locationDropdown.appendChild(option);
            });

            console.log('✅ Location dropdown updated with', locations.length, 'options');
        } catch (error) {
            console.error('❌ Error updating location dropdown:', error);
        }
    }

    // Function to update JavaScript location dropdown (Add Variant Action Modal)
    function updateLocationDropdownJS() {
        try {
            // For the Add Variant Action Modal (when adding variant to existing product)
            // We need to get the category from the current product
            if (!currentProductId) {
                console.log('⚠️ No current product selected');
                return;
            }

            // Get category from the product data
            var productRow = document.querySelector('[data-product-id="' + currentProductId + '"]');
            if (!productRow) {
                console.log('❌ Product row not found');
                return;
            }

            var category = productRow.getAttribute('data-category');
            console.log('📍 Product category:', category);

            var locationDropdown = document.getElementById('newVariantLocation');
            if (!locationDropdown) {
                console.log('❌ New variant location dropdown not found');
                return;
            }

            // Clear existing options
            locationDropdown.innerHTML = '';

            if (!category || !locationsByCategory[category]) {
                var option = document.createElement('option');
                option.value = '';
                option.textContent = 'Category not set for this product';
                locationDropdown.appendChild(option);
                locationDropdown.disabled = true;
                return;
            }

            // Enable dropdown and add placeholder
            locationDropdown.disabled = false;
            var placeholderOption = document.createElement('option');
            placeholderOption.value = '';
            placeholderOption.textContent = 'Select Location...';
            locationDropdown.appendChild(placeholderOption);

            // Add location options for the category
            var locations = locationsByCategory[category];
            locations.forEach(function(location) {
                var option = document.createElement('option');
                option.value = location;
                option.textContent = location + ' - ' + category + ' Storage';
                locationDropdown.appendChild(option);
            });

            console.log('✅ JS Location dropdown updated with', locations.length, 'options for', category);
        } catch (error) {
            console.error('❌ Error updating JS location dropdown:', error);
        }
    }

    // Set up event listeners when DOM is ready
    document.addEventListener('DOMContentLoaded', function() {
        console.log('📍 Setting up location dropdown listeners...');

        // Get category dropdown for ASP.NET modal
        var categoryDropdown = document.getElementById('<%= ddlCategory.ClientID %>');
        if (categoryDropdown) {
            categoryDropdown.addEventListener('change', updateLocationDropdownASPNET);
            console.log('✅ Category change listener added');
        }

        // Update on modal open
        var originalOpenModal = window.openModal;
        if (originalOpenModal) {
            window.openModal = function() {
                originalOpenModal();
                setTimeout(updateLocationDropdownASPNET, 100);
            };
        }

        // Update when switching to variants tab
        var variantsTab = document.querySelector('.nav-tab[onclick*="variants"]');
        if (variantsTab) {
            variantsTab.addEventListener('click', function() {
                setTimeout(updateLocationDropdownASPNET, 100);
            });
        }

        console.log('✅ Location dropdown system initialized');
    });

    // Wrap showVariantModal to update location dropdown
    if (window.showVariantModal) {
        var originalShowVariantModal = window.showVariantModal;
        window.showVariantModal = function(productId, productName) {
            originalShowVariantModal(productId, productName);
            setTimeout(updateLocationDropdownJS, 150);
        };
    }

    // Initial update
    setTimeout(updateLocationDropdownASPNET, 500);
})();
    // ===== END CATEGORY-BASED LOCATION LOGIC =====


    // ===== Add Variant Image URL Preview (non-destructive) =====
    (function () {
        // Create preview element if not exists
        function ensureAddVariantImgPreview() {
            var imgField = document.getElementById('newVariantImg');
            if (!imgField) return;
            var previewId = 'newVariantImgPreview';
            var existing = document.getElementById(previewId);
            if (!existing) {
                var preview = document.createElement('div');
                preview.style = 'margin-top:8px; text-align:center;';
                preview.innerHTML = '<img id="' + previewId + '" src="" alt="Image Preview" style="max-width:120px; max-height:80px; border-radius:6px; display:none; background:#f8f9fa; box-shadow:0 2px 8px #eee;">' +
                    '<div id="newVariantImgPreviewMsg" style="font-size:11px; color:#aaa; margin-top:2px;"></div>';
                imgField.parentNode.appendChild(preview);
            }
        }
        // Update preview on input
        function updateAddVariantImgPreview() {
            var imgField = document.getElementById('newVariantImg');
            var img = document.getElementById('newVariantImgPreview');
            var msg = document.getElementById('newVariantImgPreviewMsg');
            if (!imgField || !img) return;
            var url = imgField.value.trim();
            if (!url) {
                img.style.display = 'none';
                if (msg) msg.textContent = '';
                return;
            }
            // Accept http, https, data, or relative
            if (!(url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:') || url.startsWith('/'))) {
                url = '/' + url.replace(/^\//, '');
            }
            img.onerror = function () {
                img.style.display = 'none';
                if (msg) msg.textContent = 'Could not load image.';
            };
            img.onload = function () {
                img.style.display = '';
                if (msg) msg.textContent = '';
            };
            img.src = url;
            img.style.display = '';
            if (msg) msg.textContent = 'Preview';
        }
        // Attach listeners when modal opens
        document.addEventListener('DOMContentLoaded', function () {
            // Patch showVariantModal to always ensure preview
            if (window.showVariantModal) {
                var orig = window.showVariantModal;
                window.showVariantModal = function (pid, pname) {
                    orig(pid, pname);
                    setTimeout(function () {
                        ensureAddVariantImgPreview();
                        var imgField = document.getElementById('newVariantImg');
                        if (imgField) {
                            imgField.removeEventListener('input', updateAddVariantImgPreview);
                            imgField.addEventListener('input', updateAddVariantImgPreview);
                            updateAddVariantImgPreview();
                        }
                    }, 200);
                };
            }
        });
    })();


    function archiveProduct(productId) {
        if (!productId) {
            showNotification('error', 'Archive Error', 'Product ID not found.');
            return;
        }
        if (!confirm('Are you sure you want to archive this product?')) return;
        $.ajax({
            type: 'POST',
            url: '/Handlers/ArchiveProduct.ashx',
            data: { productId: productId },
            success: function (response) {
                var res = response;
                if (typeof res === 'string') {
                    try { res = JSON.parse(res); } catch (e) { }
                }
                if (res.success) {
                    showNotification('success', 'Archived', 'Product archived successfully!', true, 2000);
                    setTimeout(function () { window.location.reload(); }, 2200);
                } else {
                    showNotification('error', 'Archive Failed', res.error || 'Failed to archive product.');
                }
            },
            error: function (xhr) {
                showNotification('error', 'Archive Failed', 'Server error.');
            }
        });
    }


    function switchTab(tab, event) {
        document.querySelectorAll('.nav-tab').forEach(btn => btn.classList.remove('active'));
        document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active'));
        if (tab === 'archived') {
            document.getElementById('archivedTab').classList.add('active');
            event.target.classList.add('active');
            loadArchivedProducts();
        } else if (tab === 'variants') {
            document.getElementById('variantsTab').classList.add('active');
            event.target.classList.add('active');
        } else {
            document.getElementById('productTab').classList.add('active');
            event.target.classList.add('active');
        }
    }

    function loadArchivedProducts() {
        var tbody = document.getElementById('tblArchivedProducts');
        if (!tbody) return;
        tbody.innerHTML = '<tr><td colspan="6" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading archived products...</td></tr>';
        $.ajax({
            url: '/Handlers/GetArchivedProducts.ashx',
            method: 'GET',
            dataType: 'json',
            success: function (res) {
                if (res && res.success && Array.isArray(res.products) && res.products.length > 0) {
                    // Filter for status "In Active" or "Inactive"
                    var archived = res.products.filter(function (p) {
                        return p.status === "In Active" || p.status === "Inactive";
                    });
                    if (archived.length > 0) {
                        tbody.innerHTML = archived.map(function (p, i) {
                            return '<tr>' +
                                '<td>' + (i + 1) + '</td>' +
                                '<td><img src="' + p.ProductImg + '" class="thumb" style="margin-right:6px;">' + (p.ProductName || '') + '</td>' +
                                '<td>' + (p.ProductCategory || '') + '</td>' +
                                '<td>' + (p.SupplierName || '') + '</td>' +
                                '<td>' + (p.ProductVal != null ? ('₱' + parseFloat(p.ProductVal).toFixed(2)) : '-') + '</td>' +
                                '<td>' + (p.CreatedAt ? new Date(p.CreatedAt).toLocaleDateString() : '-') + '</td>' +
                                '</tr>';
                        }).join('');
                    } else {
                        tbody.innerHTML = '<tr><td colspan="6" class="text-center">No archived products found.</td></tr>';
                    }
                } else {
                    tbody.innerHTML = '<tr><td colspan="6" class="text-center">No archived products found.</td></tr>';
                }
            },
            error: function () {
                tbody.innerHTML = '<tr><td colspan="6" class="text-center">Failed to load archived products.</td></tr>';
            }
        });
    }
</script>
    </asp:Content>