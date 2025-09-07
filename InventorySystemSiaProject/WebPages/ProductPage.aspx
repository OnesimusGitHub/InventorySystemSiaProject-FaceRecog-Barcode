<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ProductPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductPage" Async="true" %>

<asp:Content ID="HeadContentProduct" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/ProductPage.css" rel="stylesheet" />
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

        .modal-body {
            padding: 0;
            max-height: calc(90vh - 100px);
            overflow-y: auto;
        }

        .modal-nav {
            display: flex;
            background: #f8f9fa;
            border-bottom: 1px solid #e9ecef;
        }

        .nav-tab {
            flex: 1;
            padding: 20px;
            text-align: center;
            background: none;
            border: none;
            cursor: pointer;
            font-weight: 600;
            color: #6c757d;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .nav-tab::before {
            content: '';
            position: absolute;
            bottom: 0;
            left: 50%;
            width: 0;
            height: 3px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            transition: all 0.3s ease;
            transform: translateX(-50%);
        }

        .nav-tab.active {
            color: #667eea;
            background: white;
        }

        .nav-tab.active::before {
            width: 100%;
        }

        .nav-tab:hover:not(.active) {
            background: #e9ecef;
            color: #495057;
        }

        .tab-content {
            padding: 30px;
            min-height: 400px;
        }

        .tab-pane {
            display: none;
            animation: fadeInUp 0.5s ease-out;
        }

        .tab-pane.active {
            display: block;
        }

        @keyframes fadeInUp {
            from { 
                opacity: 0; 
                transform: translateY(20px); 
            }
            to { 
                opacity: 1; 
                transform: translateY(0); 
            }
        }

        .form-row {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }

        .form-group {
            flex: 1;
            margin-bottom: 20px;
        }

        .form-label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }

        .form-control {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            font-size: 14px;
            transition: all 0.3s ease;
            background: #fff;
        }

        .form-control:focus {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15);
            border-color: #667eea;
        }

        .form-control:hover {
            border-color: #c7d2fe;
        }

        .textarea-field {
            min-height: 100px;
            resize: vertical;
        }

        .variant-section {
            border: 2px dashed #e9ecef;
            border-radius: 15px;
            padding: 25px;
            margin-top: 30px;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .variant-section::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(102, 126, 234, 0.05), transparent);
            transition: left 0.6s ease;
        }

        .variant-section:hover::before {
            left: 100%;
        }

        .variant-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 20px;
            position: relative;
            z-index: 1;
        }

        .variant-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .variant-title i {
            color: #667eea;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.1); }
            100% { transform: scale(1); }
        }

        .add-variant-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 25px;
            cursor: pointer;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .add-variant-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
        }

        .variant-card {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 15px;
            position: relative;
            transition: all 0.3s ease;
            animation: slideInRight 0.5s ease-out;
        }

        @keyframes slideInRight {
            from { 
                opacity: 0; 
                transform: translateX(30px); 
            }
            to { 
                opacity: 1; 
                transform: translateX(0); 
            }
        }

        .variant-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }

        .variant-remove {
            position: absolute;
            top: 15px;
            right: 15px;
            background: #dc3545;
            color: white;
            border: none;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
        }

        .variant-remove:hover {
            background: #c82333;
            transform: rotate(90deg) scale(1.1);
        }

        .modal-footer {
            background: #f8f9fa;
            padding: 25px 30px;
            border-top: 1px solid #e9ecef;
            display: flex;
            gap: 15px;
            justify-content: flex-end;
        }

        .btn-animated {
            padding: 12px 30px;
            border-radius: 25px;
            border: none;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
            position: relative;
            overflow: hidden;
        }

        .btn-animated::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            background: rgba(255,255,255,0.3);
            border-radius: 50%;
            transition: all 0.3s ease;
            transform: translate(-50%, -50%);
        }

        .btn-animated:hover::before {
            width: 300px;
            height: 300px;
        }

        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
        }

        /* 🌟 Enhanced Button Styles 🌟 */
        .btn-success {
            background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(86, 171, 47, 0.3);
        }

        .btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(86, 171, 47, 0.4);
        }

        .btn-secondary {
            background: #6c757d;
            color: white;
        }

        .btn-secondary:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }

        /* Scrollbar styling */
        .modal-body::-webkit-scrollbar {
            width: 8px;
        }

        .modal-body::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 10px;
        }

        .modal-body::-webkit-scrollbar-thumb {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
        }

        .modal-body::-webkit-scrollbar-thumb:hover {
            background: linear-gradient(135deg, #5a67d8 0%, #6b46c1 100%);
        }

        /* Loading spinner for submit */
        .loading-spinner {
            display: none;
            width: 20px;
            height: 20px;
            border: 2px solid transparent;
            border-top: 2px solid currentColor;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .btn-animated.loading .loading-spinner {
            display: inline-block;
        }

        .btn-animated.loading span {
            display: none;
        }

        /* 💫 Variant Modal Specific Styles 💫 */
        .variant-modal {
            max-width: 600px;
            transform: scale(0.7) translateX(100px);
        }

        .modal-overlay.show .variant-modal {
            transform: scale(1) translateX(0);
        }

        .variant-header {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            position: relative;
        }

        .product-info {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 5px;
            font-weight: 400;
        }

        .variant-form {
            padding: 30px;
        }

        /* 🎉 Success Modal Styles 🎉 */
        .success-modal {
            max-width: 500px;
            transform: scale(0.5) rotate(5deg);
        }

        .modal-overlay.show .success-modal {
            transform: scale(1) rotate(0deg);
        }

        .success-header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }

        .success-content {
            padding: 40px 30px;
            text-align: center;
        }

        .celebration-animation {
            margin-bottom: 20px;
            position: relative;
            height: 60px;
        }

        .celebration-animation i {
            position: absolute;
            font-size: 24px;
            color: #ffd700;
            animation: celebration 2s infinite;
        }

        .celebration-animation i:nth-child(1) {
            left: 20%;
            animation-delay: 0s;
        }

        .celebration-animation i:nth-child(2) {
            left: 50%;
            animation-delay: 0.5s;
        }

        .celebration-animation i:nth-child(3) {
            left: 80%;
            animation-delay: 1s;
        }

        @keyframes celebration {
            0%, 100% { 
                transform: translateY(0) scale(1) rotate(0deg); 
                opacity: 1; 
            }
            25% { 
                transform: translateY(-20px) scale(1.2) rotate(10deg); 
                opacity: 0.8; 
            }
            50% { 
                transform: translateY(-30px) scale(1.3) rotate(-10deg); 
                opacity: 0.6; 
            }
            75% { 
                transform: translateY(-20px) scale(1.1) rotate(5deg); 
                opacity: 0.8; 
            }
        }

        .product-summary {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-top: 20px;
            text-align: left;
        }

        .summary-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }

        .summary-item:last-child {
            border-bottom: none;
            font-weight: 600;
        }

        /* 🎭 Modal Transition Effects 🎭 */
        .modal-slide-right {
            animation: slideInRight 0.6s cubic-bezier(0.68, -0.55, 0.265, 1.55);
        }

        @keyframes slideInRight {
            from {
                opacity: 0;
                transform: translateX(100px) scale(0.8);
            }
            to {
                opacity: 1;
                transform: translateX(0) scale(1);
            }
        }

        .modal-bounce-in {
            animation: bounceIn 0.8s cubic-bezier(0.68, -0.55, 0.265, 1.55);
        }

        @keyframes bounceIn {
            0% {
                opacity: 0;
                transform: scale(0.3) rotate(-10deg);
            }
            50% {
                opacity: 1;
                transform: scale(1.05) rotate(2deg);
            }
            70% {
                transform: scale(0.9) rotate(-1deg);
            }
            100% {
                opacity: 1;
                transform: scale(1) rotate(0deg);
            }
        }

        /* 💎 Enhanced Form Styling 💎 */
        .form-control:focus {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15);
            border-color: #667eea;
        }

        .form-group {
            position: relative;
        }

        .form-group::before {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            width: 0;
            height: 2px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s ease;
        }

        .form-group:focus-within::before {
            width: 100%;
        }

        /* 🎯 Enhanced Error Styling 🎯 */
        .form-control.error {
            border-color: #ff6b6b !important;
            box-shadow: 0 0 0 3px rgba(255, 107, 107, 0.1) !important;
            animation: errorShake 0.3s ease-in-out;
        }

        @keyframes errorShake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-5px); }
            75% { transform: translateX(5px); }
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
            20%, 40%, 60%, 80% { transform: translateX(5px); }
        }

        /* 🔧 Debug Styling 🔧 */
        .debug-info {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            padding: 10px;
            margin: 10px 0;
            font-family: monospace;
            font-size: 12px;
            color: #6c757d;
        }

        /* 💫 Enhanced Button Loading State 💫 */
        .btn-animated.loading {
            position: relative;
            color: transparent !important;
            pointer-events: none;
        }

        .btn-animated.loading::after {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 20px;
            height: 20px;
            margin: -10px 0 0 -10px;
            border: 2px solid transparent;
            border-top: 2px solid currentColor;
            border-radius: 50%;
            animation: buttonSpin 1s linear infinite;
        }

        @keyframes buttonSpin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* 🎨 Enhanced Form Focus States 🎨 */
        .form-control:focus {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15);
            border-color: #667eea;
        }

        .form-control:focus:not(.error) {
            border-color: #667eea !important;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1) !important;
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
                                <label class="form-label">Product Value</label>
                                <asp:TextBox ID="txtProductValue" runat="server" CssClass="form-control" placeholder="0.00" TextMode="Number" step="0.01" />
                            </div>
                            <div class="form-group">
                                <label class="form-label">Product Image URL</label>
                                <asp:TextBox ID="txtImageUrl" runat="server" CssClass="form-control" placeholder="Enter image URL..." />
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
                <!-- Debug Buttons -->
                <button type="button" class="btn-animated btn-secondary" onclick="testSaveButton()">
                    <i class="fa fa-bug"></i>
                    <span>Test Save</span>
                </button>
                
                <button type="button" class="btn-animated btn-secondary" onclick="testDatabaseConnection()">
                    <i class="fa fa-database"></i>
                    <span>Test DB</span>
                </button>
                
                <asp:Button ID="btnTestDatabase" runat="server" 
                    Text="Test Insert" 
                    CssClass="btn-animated btn-secondary" 
                    OnClick="btnTestDatabase_Click" 
                    UseSubmitBehavior="true" />
                
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal()">
                    <i class="fa fa-times"></i>
                    <span>Cancel</span>
                </button>
                <asp:Button ID="btnSaveProduct" runat="server" 
                    Text="Save Product" 
                    CssClass="btn-animated btn-primary" 
                    OnClick="btnSaveProduct_Click" 
                    UseSubmitBehavior="true" />
            </div>
        </div>
    </div>

    <!-- 💖 Beautiful Add Product Variant Modal 💖 -->
    <div id="addVariantModal" class="modal-overlay">
        <div class="modal-container variant-modal">
            <div class="modal-header variant-header">
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
                </div>
            </div>
            
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="skipVariants()">
                    <i class="fa fa-skip-forward"></i>
                    <span>Skip for Now</span>
                </button>
                <button type="button" class="btn-animated btn-success" onclick="addAnotherVariant()">
                    <i class="fa fa-plus"></i>
                    <span>Add Another</span>
                </button>
                <asp:Button ID="btnSaveVariant" runat="server" Text="Save Variant" CssClass="btn-animated btn-primary" OnClick="btnSaveVariant_Click" UseSubmitBehavior="true" />
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

    <!-- Table + Preview layout -->
    <div class="content-body">
        <div class="table-wrapper">
            <table class="product-table" cellspacing="0" cellpadding="0">
                <thead>
                    <tr>
                        <th style="width:30px"><input type="checkbox" id="selectAll" title="Select All" /></th>
                        <th style="width:60px">ID</th>
                        <th>Product</th>
                        <th style="width:110px">SKU</th>
                        <th style="width:80px">Location</th>
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
                                data-variant-count='<%# Eval("VariantCount") %>'>
                                <td>
                                    <input type="checkbox" onclick="event.stopPropagation();" />
                                </td>
                                <td><%# Container.ItemIndex + 17410 %></td>
                                <td class="prod-cell">
                                    <img src='<%# GetProductImage(Eval("ProductImg").ToString()) %>' class="thumb" alt="Product Image" />
                                    <%# Eval("DisplayName") %>
                                </td>
                                <td><%# Eval("SKU") %></td>
                                <td>WH1</td>
                                <td><%# Eval("PriceRange") %></td>
                                <td class='<%# GetStockCssClass(Convert.ToInt32(Eval("StockQuantity")), Convert.ToInt32(Eval("MinimumStock"))) %>'>
                                    <%# Eval("StockDisplay") %>
                                </td>
                                <td class="actions">
                                    <button type="button" class="icon" title="View Variants" onclick="viewProductVariants('<%# Eval("ProductId") %>', '<%# Eval("ProductName") %>'); event.stopPropagation();">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                    <button type="button" class="icon" title="Edit" onclick="event.stopPropagation();">
                                        <i class="fa fa-pen"></i>
                                    </button>
                                    <button type="button" class="icon" title="Duplicate" onclick="event.stopPropagation();">
                                        <i class="fa fa-copy"></i>
                                    </button>
                                    <button type="button" class="icon" title="Delete" onclick="event.stopPropagation();">
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
                    <img id="previewImage" src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1zbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2YwZjBmMCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI1MCIgZm9udC1mYW1pbHk9IkFyaUFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjEyIiBmaWxsPSIjOTk5IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkeT0iLjNlbSI+UHJvZHVjdDwvdGV4dD4KICA8L3N2Zz4K" alt="Product Preview" />
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
</asp:Content>

<asp:Content ID="ScriptsContentProduct" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// 🎯 Existing Functions 🎯
function selectRow(row) {
    document.querySelectorAll('.row-select').forEach(r => r.classList.remove('selected'));
    row.classList.add('selected');
    updatePreview(row);
}

function updatePreview(row) {
    try {
        const name = row.getAttribute('data-name') || '';
        const variantCount = row.getAttribute('data-variant') || '';
        const sku = row.getAttribute('data-sku') || '';
        const priceRange = row.getAttribute('data-color') || ''; // Using data-color for price range
        const stock = row.getAttribute('data-stock') || '';
        const status = row.getAttribute('data-status') || '';
        const description = row.getAttribute('data-description') || '';
        const category = row.getAttribute('data-category') || '';
        const stockDisplay = row.getAttribute('data-size') || ''; // Using data-size for stock display
        const productId = row.getAttribute('data-product-id') || '';
        
        document.getElementById('pName').textContent = sku + ' - ' + name;
        document.getElementById('pStock').textContent = stockDisplay;
        document.getElementById('pPrice').textContent = priceRange;
        document.getElementById('pStatus').textContent = status;
        document.getElementById('pDescription').textContent = description || '-';
        document.getElementById('pCategory').textContent = category || '-';
        document.getElementById('pSize').textContent = variantCount > 1 ? `${variantCount} variants` : (variantCount == 1 ? '1 variant' : 'No variants');
        document.getElementById('pColor').textContent = productId || '-';
    } catch (e) {
        console.log('Error updating preview:', e);
    }
}

// Add function to view product variants
function viewProductVariants(productId, productName) {
    console.log('🔍 Viewing variants for product:', productName, 'ID:', productId);
    
    // Show loading message
    showTemporaryMessage(`Loading variants for ${productName}...`, 'info');
    
    // Call server method to get variants
    fetch('/WebPages/ProductPage.aspx/GetProductVariants', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ productId: productId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.d) {
            const variants = JSON.parse(data.d);
            if (variants.error) {
                showTemporaryMessage(`Error: ${variants.error}`, 'error');
                return;
            }
            
            // Display variants in a modal or alert
            let variantInfo = `Product: ${productName}\n\nVariants:\n`;
            if (variants.length === 0) {
                variantInfo += 'No variants found for this product.';
            } else {
                variants.forEach((variant, index) => {
                    variantInfo += `${index + 1}. ${variant.VariantName}\n`;
                    variantInfo += `   SKU: ${variant.SKU}\n`;
                    variantInfo += `   Price: ₱${variant.Price.toFixed(2)}\n`;
                    variantInfo += `   Stock: ${variant.StockQuantity}`;
                    if (variant.Size) variantInfo += ` | Size: ${variant.Size}`;
                    if (variant.Color) variantInfo += ` | Color: ${variant.Color}`;
                    variantInfo += `\n   Status: ${variant.IsLowStock ? 'Low Stock' : 'In Stock'}\n\n`;
                });
            }
            
            alert(variantInfo);
        }
    })
    .catch(error => {
        console.error('Error fetching variants:', error);
        showTemporaryMessage('Error loading variants. Please try again.', 'error');
    });
}

function setupSearch() {
    console.log('🔍 Setting up search functionality...');
    const searchInput = document.querySelector('input[placeholder*="Search"]');
    if (searchInput) {
        console.log('✅ Search input found:', searchInput);
        searchInput.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase();
            const rows = document.querySelectorAll('.row-select');
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                if (text.includes(searchTerm)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });
    } else {
        console.log('❌ Search input not found');
    }
}

// 🔧 Debug Functions 🔧
function testSaveButton() {
    console.log('🔧 Test Save Button clicked!');
    
    const productName = document.getElementById('<%= txtProductName.ClientID %>');
    const category = document.getElementById('<%= ddlCategory.ClientID %>');
    const saveButton = document.getElementById('<%= btnSaveProduct.ClientID %>');
    
    console.log('Product Name field:', productName);
    console.log('Category field:', category);
    console.log('Save Button:', saveButton);
    
    if (productName) {
        productName.value = 'Test Beauty Product - ' + new Date().getTime();
        console.log('✅ Test product name filled:', productName.value);
    }
    
    if (category) {
        if (category.options.length > 1) {
            category.selectedIndex = 1;
            console.log('✅ Test category selected:', category.value);
        } else {
            console.log('❌ No category options available');
        }
    }
    
    const description = document.getElementById('<%= txtDescription.ClientID %>');
    if (description) {
        description.value = 'This is a test product created for debugging purposes.';
        console.log('✅ Test description filled');
    }
    
    const productValue = document.getElementById('<%= txtProductValue.ClientID %>');
    if (productValue) {
        productValue.value = '29.99';
        console.log('✅ Test product value filled');
    }
    
    const supplier = document.getElementById('<%= txtSupplier.ClientID %>');
    if (supplier) {
        supplier.value = 'Test Supplier Inc.';
        console.log('✅ Test supplier filled');
    }
    
    console.log('✅ All test data filled successfully!');
    alert('✅ Test data filled successfully! Now click the "Save Product" button to test the database insertion.');
}

function testDatabaseConnection() {
    console.log('🧪 Testing database connection by filling test data...');
    testSaveButton();
}

// 💖 Enhanced Modal JavaScript 💖
let variantCounter = 0;
let currentProductId = null;
let currentProductName = null;

document.addEventListener('DOMContentLoaded', function() {
    console.log('🎯 ProductPage JavaScript loaded successfully!');
    
    const selectAllCheckbox = document.getElementById('selectAll');
    if (selectAllCheckbox) {
        selectAllCheckbox.addEventListener('change', function() {
            const checkboxes = document.querySelectorAll('#tblProducts input[type="checkbox"]');
            checkboxes.forEach(cb => cb.checked = this.checked);
        });
    }
    
    const addButton = document.getElementById('btnAddItem');
    if (addButton) {
        console.log('✅ Add Product button found!');
        addButton.addEventListener('click', function() {
            console.log('🖱️ Add Product button clicked!');
            openModal();
        });
    } else {
        console.error('❌ Add Product button not found!');
    }
    
    // Remove event listeners from save buttons to allow default form submission
    console.log('🔧 Allowing default form submission for save buttons');
    
    setupSearch();
    addVariant();
    
    console.log('🎉 Event listeners set up - allowing server-side processing!');
});

// 🌟 Product Modal Functions 🌟
function openModal() {
    const modal = document.getElementById('addProductModal');
    modal.classList.add('show');
    document.body.style.overflow = 'hidden';
    resetForm();
    
    setTimeout(function() {
        const firstInput = modal.querySelector('input[type="text"]');
        if (firstInput) firstInput.focus();
    }, 400);
}

function closeModal() {
    const modal = document.getElementById('addProductModal');
    modal.classList.remove('show');
    document.body.style.overflow = '';
    
    setTimeout(function() {
        resetForm();
    }, 400);
}

// 🎨 Variant Modal Functions 🎨
function showVariantModal(productId, productName) {
    currentProductId = productId;
    currentProductName = productName;
    
    const modal = document.getElementById('addVariantModal');
    const productNameLabel = document.getElementById('variantProductName');
    
    productNameLabel.textContent = productName;
    modal.querySelector('.modal-container').classList.add('modal-slide-right');
    modal.classList.add('show');
    document.body.style.overflow = 'hidden';
    resetVariantForm();
    
    setTimeout(function() {
        const firstInput = modal.querySelector('input[type="text"]');
        if (firstInput) firstInput.focus();
    }, 600);
}

function closeVariantModal() {
    const modal = document.getElementById('addVariantModal');
    modal.classList.remove('show');
    document.body.style.overflow = '';
    
    setTimeout(function() {
        resetVariantForm();
        modal.querySelector('.modal-container').classList.remove('modal-slide-right');
    }, 400);
}

function resetVariantForm() {
    document.querySelectorAll('#addVariantModal input[type="text"], #addVariantModal input[type="number"]').forEach(field => {
        field.value = '';
    });
}

// 🎯 Variant Actions 🎯
function addAnotherVariant() {
    if (validateVariantForm()) {
        const submitBtn = document.getElementById('<%= btnSaveVariant.ClientID %>');
            submitBtn.click();
        }
    }

    function skipVariants() {
        closeVariantModal();
        showSuccessModal();
    }

    // 🎉 Success Modal Functions 🎉
    function showSuccessModal() {
        const modal = document.getElementById('successModal');
        const summaryDiv = document.getElementById('productSummary');

        summaryDiv.innerHTML =
            '<div class="summary-item">' +
            '<span>Product Name:</span>' +
            '<span>' + (currentProductName || 'New Product') + '</span>' +
            '</div>' +
            '<div class="summary-item">' +
            '<span>Product ID:</span>' +
            '<span>' + (currentProductId || 'Generated') + '</span>' +
            '</div>' +
            '<div class="summary-item">' +
            '<span>Status:</span>' +
            '<span style="color: #28a745;">✅ Active</span>' +
            '</div>';

        modal.querySelector('.modal-container').classList.add('modal-bounce-in');
        modal.classList.add('show');
        document.body.style.overflow = 'hidden';

        setTimeout(function () {
            closeSuccessModal();
        }, 5000);
    }

    function closeSuccessModal() {
        const modal = document.getElementById('successModal');
        modal.classList.remove('show');
        document.body.style.overflow = '';

        setTimeout(function () {
            modal.querySelector('.modal-container').classList.remove('modal-bounce-in');
            window.location.reload();
        }, 400);
    }

    function resetForm() {
        document.querySelectorAll('#addProductModal input[type="text"], #addProductModal textarea, #addProductModal select').forEach(field => {
            field.value = '';
        });

        switchTab('product');

        const variantContainer = document.getElementById('variantContainer');
        if (variantContainer) {
            variantContainer.innerHTML = '';
        }
        variantCounter = 0;
        addVariant();
    }

    // 🎨 Tab Switching 🎨
    function switchTab(tabName, event) {
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }

        console.log('🎨 Switching to tab:', tabName);

        document.querySelectorAll('.nav-tab').forEach(tab => {
            tab.classList.remove('active');
        });

        document.querySelectorAll('.tab-pane').forEach(pane => {
            pane.classList.remove('active');
        });

        const clickedTab = event ? event.target : document.querySelector('[onclick*="' + tabName + '"]');
        if (clickedTab) {
            clickedTab.classList.add('active');
        }

        const tabContent = document.getElementById(tabName + 'Tab');
        if (tabContent) {
            tabContent.classList.add('active');
            console.log('✅ Tab switched successfully to:', tabName);
        } else {
            console.error('❌ Tab content not found for:', tabName);
        }

        return false;
    }

    // ✨ Variant Management ✨
    function addVariant() {
        variantCounter++;
        const container = document.getElementById('variantContainer');

        if (!container) {
            console.log('❌ Variant container not found');
            return;
        }

        const variantHtml =
            '<div class="variant-card" id="variant' + variantCounter + '">' +
            '<button type="button" class="variant-remove" onclick="removeVariant(' + variantCounter + ')">' +
            '<i class="fa fa-times"></i>' +
            '</button>' +
            '<div class="form-row">' +
            '<div class="form-group">' +
            '<label class="form-label">Variant Name *</label>' +
            '<input type="text" class="form-control variant-name" placeholder="e.g., Rose Gold, Large, etc..." />' +
            '</div>' +
            '<div class="form-group">' +
            '<label class="form-label">SKU *</label>' +
            '<input type="text" class="form-control variant-sku" placeholder="e.g., SKU001-RG" />' +
            '</div>' +
            '</div>' +
            '<div class="form-row">' +
            '<div class="form-group">' +
            '<label class="form-label">Size</label>' +
            '<input type="text" class="form-control variant-size" placeholder="e.g., 50ml, Large, etc..." />' +
            '</div>' +
            '<div class="form-group">' +
            '<label class="form-label">Color</label>' +
            '<input type="text" class="form-control variant-color" placeholder="e.g., Rose Gold, Natural, etc..." />' +
            '</div>' +
            '</div>' +
            '<div class="form-row">' +
            '<div class="form-group">' +
            '<label class="form-label">Price *</label>' +
            '<input type="number" step="0.01" class="form-control variant-price" placeholder="0.00" />' +
            '</div>' +
            '<div class="form-group">' +
            '<label class="form-label">Stock Quantity *</label>' +
            '<input type="number" class="form-control variant-stock" placeholder="0" />' +
            '</div>' +
            '</div>' +
            '<div class="form-row">' +
            '<div class="form-group">' +
            '<label class="form-label">Minimum Stock</label>' +
            '<input type="number" class="form-control variant-min-stock" placeholder="5" />' +
            '</div>' +
            '<div class="form-group">' +
            '<label class="form-label">Weight (grams)</label>' +
            '<input type="number" step="0.01" class="form-control variant-weight" placeholder="0.00" />' +
            '</div>' +
            '</div>' +
            '<div class="form-group">' +
            '<label class="form-label">Dimensions</label>' +
            '<input type="text" class="form-control variant-dimensions" placeholder="e.g., 10cm x 5cm x 3cm" />' +
            '</div>' +
            '</div>';

        container.insertAdjacentHTML('beforeend', variantHtml);

        const newCard = document.getElementById('variant' + variantCounter);
        if (newCard) {
            newCard.style.opacity = '0';
            newCard.style.transform = 'translateX(30px)';

            setTimeout(function () {
                newCard.style.transition = 'all 0.5s ease-out';
                newCard.style.opacity = '1';
                newCard.style.transform = 'translateX(0)';
            }, 10);
        }
    }

    function removeVariant(variantId) {
        const variant = document.getElementById('variant' + variantId);
        if (variant) {
            variant.style.transition = 'all 0.3s ease-out';
            variant.style.opacity = '0';
            variant.style.transform = 'translateX(-30px)';

            setTimeout(function () {
                variant.remove();

                if (document.querySelectorAll('.variant-card').length === 0) {
                    addVariant();
                }
            }, 300);
        }
    }

    // 🔍 Enhanced Form Validation 🔍
    function validateForm() {
        // Always return true to allow server-side validation
        return true;
    }

    function validateVariantForm() {
        // Always return true to allow server-side validation  
        return true;
    }

    // Event Listeners
    document.addEventListener('click', function (e) {
        if (e.target.classList.contains('modal-overlay')) {
            if (e.target.id === 'addProductModal') {
                closeModal();
            } else if (e.target.id === 'addVariantModal') {
                closeVariantModal();
            } else if (e.target.id === 'successModal') {
                closeSuccessModal();
            }
        }
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            closeModal();
            closeVariantModal();
            closeSuccessModal();
        }
    });

    function showTemporaryMessage(message, type) {
        const messagePanel = document.querySelector('[id*="pnlMessage"]');
        const messageLabel = document.querySelector('[id*="lblMessage"]');

        if (messagePanel && messageLabel) {
            messageLabel.textContent = message;
            messagePanel.className = type === 'success' ? 'success-container' : 'error-container';
            messagePanel.style.display = 'block';

            setTimeout(function () {
                messagePanel.style.display = 'none';
            }, 3000);
        }
    }
</script>
</asp:Content>