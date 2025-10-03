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
                                <asp:TextBox ID="txtSupplier" runat="server" CssClass="form-control" placeholder="Enter supplier name..." />
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
                            <asp:TextBox ID="txtVariantMinStock" runat="server" CssClass="form-control" placeholder="5" TextMode="Number" />
                        </div>
                        <div class="form-group">
                            <label class="form-label">Weight (grams)</label>
                            <asp:TextBox ID="txtVariantWeight" runat="server" CssClass="form-control" placeholder="0.00" TextMode="Number" step="0.01" />
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Dimensions</label>
                        <asp:TextBox ID="txtVariantDimensions" runat="server" CssClass="form-control" placeholder="e.g., 10cm x 5cm x 3cm" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Variant Image Upload</label>
                        <asp:FileUpload ID="fuVariantImage" runat="server" CssClass="form-control" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Variant Image URL (optional override)</label>
                        <asp:TextBox ID="txtVariantImageUrl" runat="server" CssClass="form-control" placeholder="https://example.com/image.jpg" />
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
                        <th style="width:30px"><input type="checkbox" id="selectAll" title="Select All" /></th>
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
                                <td>
                                    <input type="checkbox" onclick="event.stopPropagation();" />
                                </td>
                                <td><%# Container.ItemIndex + 17410 %></td>
                                <td class="prod-cell">
                                    <img src='<%# GetProductImage(Eval("ProductImg").ToString()) %>' class="thumb" alt="Product Image" />
                                    <%# Eval("DisplayName") %>
                                </td>
                                <td class="col-sku"><%# Eval("SKU") %></td>
                                <td><%# Eval("Supplier") %></td>
                                <td><%# Eval("PriceRange") %></td>
                                <td class='<%# GetStockCssClass(Convert.ToInt32(Eval("StockQuantity")), Convert.ToInt32(Eval("MinimumStock"))) %>'>
                                    <%# Eval("StockDisplay") %>
                                </td>
                                <td class="actions">
                                    <button type="button" class="icon" title="View Variants" onclick="viewProductVariants('<%# Eval("ProductId") %>', '<%# Eval("ProductName") %>'); event.stopPropagation();">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                    <button type="button" class="icon" title="Edit" onclick="event.stopPropagation(); showUpdateProductModal('<%# Eval("ProductId") %>', '<%# Eval("ProductName") %>')">
                                        <i class="fa fa-pen"></i>
                                    </button>
                                    <button type="button" class="icon" title="Duplicate" onclick="event.stopPropagation();">
                                        <i class="fa fa-copy"></i>
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
                        <input type="text" id="txtUpdateSupplier" class="form-control" placeholder="Enter supplier name..." />
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Product Image Upload</label>
                        <asp:FileUpload ID="fuUpdateProductImage" runat="server" CssClass="form-control" />
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
            variantId: currentVariantId
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
    // Implementation for update product modal
    const modal = document.getElementById('updateProductModal');
    if (modal) {
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        document.body.style.overflow = 'hidden';
    } else {
        console.error('❌ Update product modal not found!');
        showNotification('error', 'Modal Error', 'Update modal not found. Please refresh the page.');
    }
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
    showNotification('info', 'Coming Soon', 'Update product functionality will be implemented soon.');
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

// expose globally (overrides early fallback)
window.showNotification = showNotification;
window.closeNotificationModal = closeNotificationModal;

// Confirmation for saving product
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
</script>
</asp:Content>