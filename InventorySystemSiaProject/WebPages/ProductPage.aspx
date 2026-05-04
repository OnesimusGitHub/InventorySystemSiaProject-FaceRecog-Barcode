<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ProductPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductPage" Async="true" %>

<asp:Content ID="HeadContentProduct" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/ProductPage.css" rel="stylesheet" />
    <!-- Add jQuery CDN -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        /* Quantity input styling */
#txtIngredientQuantity:disabled {
    background: #f5f5f5;
    cursor: not-allowed;
    opacity: 0.6;
}

#txtIngredientQuantity:enabled {
    background: white;
    border-color: #667eea;
}
.remove-img-url {
    background: #dc3545;
    color: white;
    border: none;
    border-radius: 50%;
    width: 32px;
    height: 32px;
    font-size: 18px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
}
.remove-img-url:hover {
    background: #b71c1c;
}

.remove-img-url {
    position: absolute;
    top: -8px;
    right: -8px;
    background: #dc3545;
    color: white;
    border: none;
    border-radius: 50%;
    width: 32px;
    height: 32px;
    cursor: pointer;
    font-size: 18px;
    line-height: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
    z-index: 10;
}
/* Update Product Image Preview Styles */
#updateProductImagePreview {
    transition: all 0.3s ease;
}

#updateProductImagePreview[style*="border: 3px solid #4CAF50"] {
    animation: pulse-green 1.5s ease-in-out infinite;
}

@keyframes pulse-green {
    0%, 100% {
        box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.7);
    }
    50% {
        box-shadow: 0 0 0 10px rgba(76, 175, 80, 0);
    }
}

/* Show "NEW" label when new image is selected */
.preview-image[data-new-upload="true"]::after {
    content: "NEW UPLOAD";
    position: absolute;
    top: 10px;
    right: 10px;
    background: #4CAF50;
    color: white;
    padding: 4px 12px;
    border-radius: 4px;
    font-size: 11px;
    font-weight: bold;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}


@keyframes fadeIn {
    from {
        opacity: 0;
        transform: scale(0.8);
    }
    to {
        opacity: 1;
        transform: scale(1);
    }
}
.remove-img-url:hover {
    background: #b71c1c;
    transform: scale(1.1);
}

/* Ingredient tag styling with quantity */
.ingredient-tag strong {
    color: #667eea;
    margin-right: 4px;
}
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
            display: flex;              /* ✅ ADD THIS */
            flex-direction: column; 
        }

        .modal-overlay.show .modal-container {
            transform: scale(1) translateY(0);
        }

        .modal-header {
            background:#C97B7B;
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
             background-color: #A86D6A;
             color: white;
            }
        .table-wrapper {
             max-height: 90vh;
          overflow-y: auto;
            }
        .modal-close:hover {
            background: rgba(255,255,255,0.3);
            transform: rotate(90deg) scale(1.1);
        }







        .modal-body { 
    padding: 0; 
    flex: 1;                    /* ✅ ADD THIS */
    overflow-y: auto;           /* ✅ KEEP THIS */
    max-height: calc(90vh - 200px); /* ✅ CHANGE FROM 100px to 200px */
}
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
        .btn-primary { background: #A86D6A; color: white; box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3); }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4); }
        .btn-success { background: linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%); color: white; box-shadow: 0 4px 15px rgba(86, 171, 47, 0.3); }
        .btn-success:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(86, 171, 47, 0.4); }
        .btn-secondary { background: #6c757d; color: white; }
        .btn-secondary:hover { background: #5a6268; transform: translateY(-2px); }
        .btn-danger { background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); color: white; box-shadow: 0 4px 15px rgba(220, 53, 69, 0.3); }
        .btn-danger:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(220, 53, 69, 0.4); }
        .modal-body::-webkit-scrollbar { width: 8px; }
        .modal-body::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 10px; }
        .modal-body::-webkit-scrollbar-thumb { background: #C97B7B; border-radius: 10px; }
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

                /* ✅ FIX: Update Variant modal must appear above the View Variants modal */
        #updateVariantModal {
            z-index: 1100 !important;
        }

        #addVariantActionModal {
            z-index: 1100 !important;
        }

        #deleteVariantModal,
        #deleteProductModal {
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


        /* Ensure all modal overlays are always on top regardless of parent stacking context */
.modal-overlay {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    z-index: 1000;
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
            background: white;
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

        .desc-cell {
            overflow: hidden;
            white-space: nowrap;
            text-overflow: ellipsis;
            max-width: 220px; /* match your column width */
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
        button {
        
        border: 0px;
        }

        #ingredientSuggestions::-webkit-scrollbar { width: 6px; }
#ingredientSuggestions::-webkit-scrollbar-thumb { background: #667eea; border-radius: 10px; }
.ingredient-suggestion-item {
    padding: 10px 15px;
    cursor: pointer;
    border-bottom: 1px solid #f1f3f5;
    transition: background 0.2s;
}
.ingredient-suggestion-item:hover {
    background: #f8f9fa;
}
.ingredient-suggestion-item:last-child {
    border-bottom: none;
}
.ingredient-tag {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: white;
    border: 2px solid #667eea;
    border-radius: 20px;
    padding: 8px 12px;
    margin: 5px 5px 0 0;
    font-size: 13px;
    color: #333;
    transition: all 0.3s ease;
}
.ingredient-tag:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}
.ingredient-tag-remove {
    cursor: pointer;
    color: #dc3545;
    font-weight: bold;
    transition: all 0.2s;
}
.ingredient-tag-remove:hover {
    transform: scale(1.2);
}

.btn-group {
    float: right;
    margin-top: -60px; /* adjust as needed to align with toolbar */
    margin-right: 24px; /* adjust for spacing from right edge */
      z-index: 2;
      position: relative;
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
     <div class="btn-group">
     <button type="button" class="btn primary" id="btnAddItem">
         <i class="fa fa-plus"></i> <b>Add Product</b>
     </button>
     <button type="button" class="btn square" title="Refresh" onclick="location.reload()">
         <i class="fa fa-rotate"></i> <b>Refresh</b>
     </button>
     
    

 </div>

    <!-- Main Toolbar -->
    <div class="toolbar">
        <div class="toolbar-left">
            <div class="search-box">
                <i class="fa fa-search"></i>
                <asp:TextBox ID="txtSearch" runat="server" placeholder="Search products, SKU, or category..." />
            </div>
            
        </div>
        <div class="toolbar-right">
            <div class="toolbar-group">
   <p>Categories</p>
    <button type="button" class="btn ghost" title="Filter">
        <i class="fa fa-filter"></i>
        <span class="btn-text">Filter : All</span>
        <i class="fa fa-chevron-down caret"></i>
    </button>

</div>

        </div>
    </div>
    <div class="content-body">
    <div class="table-wrapper">
        <table class="product-table" cellspacing="0" cellpadding="0">
            <thead>
                <tr>
                    
                    <th>Product</th>
                    <th style="width:120px">Category</th>
                    <th style="width:90px">Price</th>
                    <th style="width:220px">Description</th>
                    <th class="col-sku" style="width:110px">SKU</th>
              
                    
                   
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
    data-image-url='<%# GetProductImage(Eval("ProductId").ToString()) %>'>
    <td class="prod-cell">
        <img src='<%# GetProductImage(Eval("ProductId").ToString()) %>' class="thumb" alt="Product Image" />
        <%# Eval("DisplayName") %> 
        <button type="button" class="icon" title="View Variants" onclick="viewProductVariants('<%# Eval("productId") %>', '<%# Eval("productName") %>'); event.stopPropagation();">
            <i class="fa fa-eye"></i>
        </button>
    </td>
    <td><%# Eval("ProductCategory") %></td>
    <td><%# Eval("PriceRange") %></td>
    <td class="desc-cell"><%# Eval("ProductDesc") %></td>
    <td class="col-sku"><%# Eval("SKU") %></td>
    <td class="actions">
        <button type="button" class="icon" title="Edit" onclick="event.stopPropagation(); showUpdateProductModal('<%# Eval("ProductId") %>', '<%# Eval("ProductName") %>')">
            <i class="fa fa-pen"></i>
        </button>
        <button type="button" class="icon" title="Archive" onclick="event.stopPropagation(); archiveProduct('<%# Eval("ProductId") %>');">
            <i class="fa fa-archive"></i>
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
                    <div class="p-field">
                        <span class="lbl">Ingredients:</span>
                        <div id="pIngredients" style="color: white; margin-top: 4px;">-</div>
                    </div>
                    <div class="p-field" style="margin-top: 8px;">
                        <span class="lbl">Description:</span> 
                        <div id="pDescription" style="color: #ccc; line-height: 1.3; margin-top: 4px;">-</div>
                    </div>
                    <div style="margin-top:16px; text-align:center;">
                            <button id="btnViewMore" class="btn-animated btn-primary" style="padding:10px 24px;">
                                <i class="fa fa-eye"></i> View More
                            </button>
                    </div>
                </div>
            </div>
        </div>
    </aside>
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
    <div class="form-group" style="flex: 2;">
        <label class="form-label">Base Ingredients</label>
        <div style="position: relative;">
            <div style="display: flex; gap: 8px; align-items: flex-start;">
                <div style="flex: 2;">
                    <input type="text" id="txtIngredientSearch" class="form-control" placeholder="Search ingredient (e.g., Hyaluronic Acid)..." autocomplete="off" />
                    <div id="ingredientSuggestions" style="position: absolute; top: 100%; left: 0; right: 0; background: white; border: 1px solid #e9ecef; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); max-height: 200px; overflow-y: auto; display: none; z-index: 1000; margin-top: 5px;"></div>
                </div>
                <input type="number" id="txtIngredientQuantity" class="form-control" placeholder="Quantity" min="0.01" step="0.01" disabled style="width: 120px;" />
                <button type="button" id="btnAddIngredient" class="btn-animated btn-primary" disabled style="padding: 12px 20px; white-space: nowrap;">
                    <i class="fa fa-plus"></i> Add
                </button>
            </div>
            <div id="ingredientValidationMsg" style="font-size: 12px; margin-top: 5px;"></div>
        </div>
        <div id="ingredientListContainer" style="margin-top: 15px; display: none;">
            <div style="background: #f8f9fa; border-radius: 10px; padding: 15px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <span style="font-weight: 600; color: #333;">
                        <i class="fa fa-flask"></i> Added Ingredients
                    </span>
                    <span id="ingredientCountBadge" style="background: #667eea; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">0</span>
                </div>
                <div id="ingredientList"></div>
            </div>
        </div>

        <asp:HiddenField ID="hdnSelectedIngredients" runat="server" />
    </div>
                            
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
    <label class="form-label">Product Image Upload</label>
    <asp:FileUpload ID="fuProductImage" runat="server" CssClass="form-control" accept="image/*" />
    <div class="preview-image" style="margin-top:10px;">
        <img id="productImagePreview" src="<%= ResolveUrl("~/Content/images/sample-generic.png") %>" alt="Product Image Preview" style="width:100%; height:150px; object-fit:cover; border-radius:8px;" />
    </div>
    <div class="preview-extra">
        <i class="fa fa-info-circle"></i> Upload an image file (JPG, PNG, GIF - Max 5MB)
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
    <asp:TextBox ID="txtVariantMinStock" runat="server" 
        CssClass="form-control" 
        TextMode="Number" 
        placeholder="5" 
        Text="1000"
        ReadOnly="true" 
        style="background-color: #f5f5f5; cursor: not-allowed;" />
    <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
        <i class="fa fa-info-circle"></i> Minimum stock is set to 1000 by default
    </small>
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
                     
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Lifespan / Best Before (years)</label>
                        <asp:TextBox ID="txtShelfLifeYears" runat="server" CssClass="form-control" TextMode="Number" placeholder="1" />
                        <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
                            How many years the product stays fresh (e.g., 1 for 1 year, 2 for 2 years)
                        </small>
                    </div>
                    <asp:HiddenField ID="hdnUpdateProductImage" runat="server" />


<div class="form-row">
    <div class="form-group">
        <label class="form-label">Description</label>
        <input type="text" id="updVariantDescription" class="form-control" placeholder="Enter variant description..." />
    </div>
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
    <label class="form-label">Variant Images Upload (Multiple)</label>
    <asp:FileUpload ID="fuVariantImages" runat="server" CssClass="form-control" accept="image/*" AllowMultiple="true" />
    <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
        <i class="fa fa-info-circle"></i> You can select multiple images (Ctrl+Click or Shift+Click)
    </small>
    <div id="variantImagesPreview" style="margin-top: 10px; display: flex; flex-wrap: wrap; gap: 10px;">
        <!-- Preview thumbnails will appear here -->
    </div>
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
    <div id="viewVariantsModal" class="modal-overlay"  data-move-to-body="true">
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
                <!-- Tab Navigation -->
                <div class="modal-nav">
                    <button type="button" class="nav-tab active" onclick="switchVariantTab('activeVariants', event)">
                        <i class="fa fa-layer-group"></i> Active Variants
                    </button>
                    <button type="button" class="nav-tab" onclick="switchVariantTab('archivedVariants', event)">
                        <i class="fa fa-archive"></i> Archived Variants
                    </button>
                </div>

                <!-- Active Variants Tab -->
                <div id="activeVariantsTab" class="tab-pane active" style="padding: 0 24px 24px 24px;">
                    <div class="variants-toolbar">
                        <div class="meta" id="viewVariantsMeta">Loading…</div>
                        <div>
                            <input type="text" id="variantFilter" class="form-control" placeholder="Filter variants (name, SKU…)" style="width:240px;"/>
                        </div>
                    </div>
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
                                <td colspan="9" class="text-center">
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

                <!-- Archived Variants Tab -->
                <div id="archivedVariantsTab" class="tab-pane" style="padding: 0 24px 24px 24px;">
                    <div class="variants-toolbar">
                        <div class="meta" id="archivedVariantsMeta">Loading…</div>
                    </div>
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
                            </tr>
                        </thead>
                        <tbody id="archivedVariantsTableBody">
                            <tr>
                                <td colspan="8" class="text-center">
                                    <i class="fa fa-spinner fa-spin"></i> Loading archived variants…
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <div id="archivedVariantsEmptyState" style="display:none; text-align:center; color:#888; padding:24px;">
                        <i class="fa fa-box-open" style="display:block; font-size:36px; color:#ddd; margin-bottom:6px;"></i>
                        No archived variants found for this product.
                    </div>
                </div>
            </div>

            <div class="modal-footer" style="display: flex; justify-content: space-between;">
                
                <button type="button" class="btn-animated btn-primary" onclick="closeViewVariantsModal(); showVariantModal(currentProductId, currentProductName)">
                    <i class="fa fa-plus"></i>
                    <span>Add Variant</span>
                </button>
            </div>
        </div>
    </div>

    <!-- Table + Preview layout -->
    

    <!-- 💖 Beautiful Update Product Modal 💖 -->
    <asp:HiddenField ID="hiddenProductId" runat="server" />
    <div id="updateProductModal" class="modal-overlay"  data-move-to-body="true">
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
                       <!-- Replace this in the update modal: -->
<!--
<input type="text" id="txtUpdateBaseIngredients" class="form-control" placeholder="Enter base ingredients..." />
-->

<!-- With this: -->
<div style="position: relative;">
    <div style="display: flex; gap: 8px; align-items: flex-start;">
        <div style="flex: 2;">
            <input type="text" id="txtUpdateIngredientSearch" class="form-control" placeholder="Search ingredient (e.g., Hyaluronic Acid)..." autocomplete="off" />
            <div id="updateIngredientSuggestions" style="position: absolute; top: 100%; left: 0; right: 0; background: white; border: 1px solid #e9ecef; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); max-height: 200px; overflow-y: auto; display: none; z-index: 1000; margin-top: 5px;"></div>
        </div>
        <input type="number" id="txtUpdateIngredientQuantity" class="form-control" placeholder="Quantity" min="0.01" step="0.01" disabled style="width: 120px;" />
        <button type="button" id="btnUpdateAddIngredient" class="btn-animated btn-primary" disabled style="padding: 12px 20px; white-space: nowrap;">
            <i class="fa fa-plus"></i> Add
        </button>
    </div>
    <div id="updateIngredientValidationMsg" style="font-size: 12px; margin-top: 5px;"></div>
</div>
<div id="updateIngredientListContainer" style="margin-top: 15px; display: none;">
    <div style="background: #f8f9fa; border-radius: 10px; padding: 15px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <span style="font-weight: 600; color: #333;">
                <i class="fa fa-flask"></i> Added Ingredients
            </span>
            <span id="updateIngredientCountBadge" style="background: #667eea; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">0</span>
        </div>
        <div id="updateIngredientList"></div>
    </div>
</div>
<input type="hidden" id="hdnUpdateSelectedIngredients" />
                    </div>





                    
                </div>
<!-- Update Product Modal - Make sure ID is correct -->
<div class="form-group">
    <label class="form-label">Product Image Upload</label>
    <input type="file" 
           id="fuUpdateProductImage" 
           name="fuUpdateProductImage"
           class="form-control" 
           accept="image/*" />
    <small style="color:#666; font-size:12px; margin-top:5px; display:block;">
        <i class="fa fa-info-circle"></i> Upload a new image (JPG, PNG, GIF - Max 5MB) or leave blank to keep existing image
    </small>
    <div class="preview-image" style="margin-top:10px;">
        <img id="updateProductImagePreview" 
             src="" 
             alt="Current Product Image" 
             style="width:100%; height:150px; object-fit:cover; border-radius:8px; border:2px solid #e9ecef;" />
    </div>
    <div class="preview-extra" style="font-size:11px; color:#aaa; margin-top:5px;">
        Current image preview
    </div>
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
                <strong style="color:#dc3545;">⚠️ WARNING: PERMANENT DELETION</strong><br/><br/>
                    Are you sure you want to <strong>permanently delete this product</strong> ?<br/><br/>
                    This will <strong>completely remove it from the database</strong> and <strong>CANNOT BE UNDONE!</strong>
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


    <div id="archiveConfirmModal" class="notification-modal confirmation-modal">
    <div class="notification-container">
        <div class="notification-header">
            <div class="notification-icon warning">
                <i class="fa fa-archive"></i>
            </div>
            <div class="notification-content">
                <h3 class="notification-title">Archive Product</h3>
                <p class="notification-message">Are you sure you want to archive this product?</p>
            </div>
        </div>
        <div class="notification-footer">
            <button type="button" class="btn-notification secondary" id="archiveCancelBtn">
                <i class="fa fa-times"></i>
                <span>Cancel</span>
            </button>
            <button type="button" class="btn-notification primary" id="archiveConfirmBtn">
                <i class="fa fa-archive"></i>
                <span>Archive</span>
            </button>
        </div>
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

    function openModal() {
        var modal = document.getElementById('addProductModal');
        if (modal) {
            modal.classList.add('show');
            modal.style.display = 'flex';
            modal.style.visibility = 'visible';
            document.body.style.overflow = 'hidden';
            resetForm();
            updateProductImagePreview();
            setTimeout(function () {
                var firstInput = modal.querySelector('input[type="text"]');
                if (firstInput) firstInput.focus();
            }, 400);
        }
    }

    function closeModal() {
        var modal = document.getElementById('addProductModal');
        if (modal) {
            modal.classList.remove('show');
            modal.style.display = 'none';
            modal.style.visibility = 'hidden';
            document.body.style.overflow = '';
        }
    }

    function resetForm() {
        var form = document.getElementById('addProductModal');
        if (!form) return;
        form.querySelectorAll('input[type="text"], input[type="number"], textarea, select').forEach(function (el) {
            el.value = el.tagName === 'SELECT' ? '' : '';
        });
        if (typeof window.clearIngredients === 'function') window.clearIngredients();
        var variantContainer = document.getElementById('variantContainer');
        if (variantContainer) variantContainer.innerHTML = '';
        variantCounter = 0;
    }

    var updateImgUrlTb = document.getElementById('txtUpdateProductImageUrl');
    function updateUpdateProductImagePreview() {
        var updateImgPrev = document.getElementById('updateProductImagePreview');
        var updateImgUrlTb = document.getElementById('txtUpdateProductImageUrl');

        if (!updateImgPrev || !updateImgUrlTb) return;

        var url = (updateImgUrlTb.value || '').trim();
        var defaultUrl = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjgwIi8+";

        if (!url) {
            updateImgPrev.src = defaultUrl;
            return;
        }
        url = '/' + url;

        updateImgPrev.onerror = function () {
            this.onerror = null;
            this.src = defaultUrl;
        };

        updateImgPrev.src = url;
    }




    // Early safe fallbacks to avoid ReferenceError before full helpers are defined
    if (typeof window.showNotification !== 'function') {
        window.showNotification = function (type, title, message, autoHide, duration) {
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
                    icon.innerHTML = (t === 'success') ? '<i class="fa fa-check"></i>' : (t === 'error') ? '<i class="fa fa-times"></i>' : (t === 'warning') ? '<i class="fa fa-exclamation-triangle"></i>' : '<i class="fa fa-info-circle"></i>';
                }
                modal.classList.add('show');
                if (autoHide) {
                    var ms = duration || 3000;
                    if (progress) { progress.style.animationDuration = ms + 'ms'; progress.style.width = '100%'; modal.classList.add('auto-hide'); }
                    setTimeout(function () {
                        try {
                            modal.classList.remove('show', 'auto-hide');
                            if (progress) { progress.style.width = '0%'; progress.style.animationDuration = ''; }
                        } catch (_) { }
                    }, ms);
                }
                return;
            }
            // If modal not present, log silently
            try { console.log('[Notification]', type, title, message); } catch (_) { }
        };
    }
    if (typeof window.openModal !== 'function') {
        window.openModal = function () { }; // will be replaced by real implementation below
    }
    if (typeof window.setupSearch !== 'function') {
        window.setupSearch = function () { }; // placeholder until real implementation below
    }
    if (typeof window.resetForm !== 'function') {
        window.resetForm = function () { }; // placeholder to avoid early ReferenceError
    }
    if (typeof window.addVariant !== 'function') {
        window.addVariant = function () { }; // placeholder until real implementation below
    }
    if (typeof window.removeVariant !== 'function') {
        window.removeVariant = function () { }; // placeholder until real implementation below
    }
    var GET_VARIANTS_URL = '/Handlers/GetProductVariants.ashx';
    var baseHandlersUrl = '/Handlers/';

    if (typeof window.fetchVariants !== 'function') {
        window.fetchVariants = function (productId) {
            // ✅ Validate productId before sending
            if (!productId || productId.trim() === '') {
                console.error('❌ Invalid productId:', productId);
                return Promise.reject(new Error('Product ID is required'));
            }

            // ✅ Ensure productId is a string and trimmed
            productId = String(productId).trim();

            console.log('📡 Fetching variants for productId:', productId);
            console.log('📡 Request URL:', GET_VARIANTS_URL);

            return $.ajax({
                type: 'GET',  // ✅ CHANGED: Use GET instead of POST
                url: GET_VARIANTS_URL,
                data: { productId: productId },  // ✅ CHANGED: Send as query parameter
                dataType: 'json',
                success: function (response) {
                    console.log('✅ Variants fetched successfully:', response);
                },
                error: function (xhr, status, error) {
                    console.error('❌ Failed to fetch variants:', {
                        status: status,
                        error: error,
                        response: xhr.responseText
                    });
                }
            });
        };
    }

    // 💖 Enhanced Modal JavaScript 💖
    let variantCounter = 0;
    let currentProductId = null;
    let currentProductName = null;
    let currentVariantId = null;
    let currentVariantName = null;
    let currentDeleteProductId = null; // Add this for delete functionality

    document.addEventListener('DOMContentLoaded', function () {
        console.log('🎯 ProductPage JavaScript loaded successfully!');


        document.querySelectorAll('.modal-overlay[data-move-to-body="true"], .notification-modal[data-move-to-body="true"]').forEach(function (m) {
            if (m.parentElement !== document.body) {
                document.body.appendChild(m);
                // keep a debug hint so you can verify which ones were moved
                console.log('Moved client-only overlay to body:', m.id || m.className);
            }
        });

        // ✅ ANTI-RESUBMISSION: Clear POST data from browser history on page load
        if (window.history && window.history.replaceState) {
            // Replace current history state to remove POST data
            window.history.replaceState(null, null, window.location.href);
            console.log('✅ Browser history state cleared on page load');
        }

        // ✅ ANTI-RESUBMISSION: Prevent form resubmission on back button
        window.addEventListener('pageshow', function (event) {
            if (event.persisted || (window.performance && window.performance.navigation.type === 2)) {
                // Page was loaded from cache (back button)
                if (window.history && window.history.replaceState) {
                    window.history.replaceState(null, null, window.location.href);
                    console.log('✅ Browser history cleared after back button navigation');
                }
            }
        });

        // ✅ ANTI-RESUBMISSION: Clear history before page unload
        window.addEventListener('beforeunload', function () {
            if (window.history && window.history.replaceState) {
                window.history.replaceState(null, null, window.location.href);
            }
        });

        // Hook product image URL preview


        // Hook update product image URL preview

        if (updateImgUrlTb) { updateImgUrlTb.addEventListener('input', updateUpdateProductImagePreview); }

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
            selectAllCheckbox.addEventListener('change', function () {
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

            addButton.addEventListener('click', function (e) {
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

                    setTimeout(function () {
                        const firstInput = modal.querySelector('input[type="text"]');
                        if (firstInput) firstInput.focus();
                    }, 400);
                } else {
                    console.error('❌ Modal not found!');
                    showNotification('error', 'Modal Error', 'Modal not found! Please check the HTML.');
                }
            });

            // Also add a simple onclick as backup
            addButton.onclick = function (e) {
                e.preventDefault();
                e.stopPropagation();
                console.log('🖱️ Backup.onclick triggered!');
                openModal();
            };

        } else {
            console.error('❌ Add Product button not found! Looking for element with ID: btnAddItem');
        }

        // Add event listeners for delete buttons
        document.addEventListener('click', function (e) {
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

    function updateProductImagePreview() {
        var fileInput = document.getElementById('<%= fuProductImage.ClientID %>');
        var preview = document.getElementById('productImagePreview');

        if (!fileInput || !preview) return;

        var file = fileInput.files[0];
        if (file && file.type.startsWith('image/')) {
            var reader = new FileReader();
            reader.onload = function (e) {
                preview.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else {  // ✅ NOW 'else' IS INSIDE THE FUNCTION
            // Reset to placeholder if no file selected
            preview.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2YwZjBmMCIvPgogIDx0ZXh0IHg9IjUwIiB5PSI1MCIgZm9udC1mYW1pbHk9IkFyaWFsIiBmb250LXNpemU9IjE0IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjOTk5Ij5Qcm9kdWN0IEltYWdlPC90ZXh0Pgo8L3N2Zz4K';
        }
    }  // ✅ PROPER CLOSING BRACE FOR FUNCTION


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




            // After setting productId
            if (productId) {
                $.ajax({
                    type: "POST",
                    url: "/Handlers/GetProductIngredients.ashx",
                    data: JSON.stringify({ productId: productId }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (response) {
                        var container = document.getElementById('pIngredients');
                        if (container) {
                            if (response.success && Array.isArray(response.ingredients) && response.ingredients.length > 0) {
                                container.innerHTML = response.ingredients.map(function (ing) {
                                    return `<span style="display:inline-block; margin-right:8px;">
                          <b>${ing.name}</b> (${ing.quantity} ${ing.unit})
                      </span>`;
                                }).join('');
                            } else {
                                container.textContent = '-';
                            }
                        }
                    },
                    error: function () {
                        var container = document.getElementById('pIngredients');
                        if (container) container.textContent = '-';
                    }
                });
            }
            // Update preview image with better error handling
            const previewImage = document.getElementById('previewImage');
            if (previewImage && productId) {
                previewImage.src = '/Handlers/GetProductImage.ashx?productId=' + encodeURIComponent(productId);
            }
        } catch (e) {
            console.log('❌ Error updating preview:', e);
        }

        const productId = row.getAttribute('data-product-id') || '';
        const viewMoreBtn = document.getElementById('btnViewMore');
        if (viewMoreBtn) {
            viewMoreBtn.onclick = function (event) {
                event.preventDefault(); // Prevent form submission or default button behavior
                console.log('View More clicked for productId:', productId);
                if (productId) {
                    window.location.href = '/WebPages/ProductProfile.aspx?productId=' + encodeURIComponent(productId);
                }
            };
        }
    }

    // ✅ CORE FUNCTION: closeViewVariantsModal
    function closeViewVariantsModal() {
        console.log('🔒 Closing variants modal...');
        const modal = document.getElementById('viewVariantsModal');
        if (modal) {
            modal.classList.remove('show');
            modal.style.display = '';
            modal.style.visibility = '';
            modal.style.opacity = '';
            document.body.style.overflow = '';

            const body = document.getElementById('variantsTableBody');
            if (body) {
                body.innerHTML = '<tr><td colspan="9" class="text-center">Modal closed</td></tr>';
            }

            const meta = document.getElementById('viewVariantsMeta');
            if (meta) meta.textContent = '';

            console.log('✅ Variants modal closed successfully');
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
            setTimeout(function () {
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
            // ✅ CLEAR PASSWORD FIELD FIRST - before updating modal text
            const passwordField = document.getElementById('txtAdminPasswordVariant');
            if (passwordField) {
                passwordField.value = ''; // Clear the password field
                console.log('✅ Password field cleared');
            }

            // Update modal text with variant name

            var modalBody = modal.querySelector('.modal-body p');
            if (modalBody) {
                modalBody.innerHTML = '<strong style="color:#dc3545;">⚠️ WARNING: PERMANENT DELETION</strong><br/><br/>' +
                    'Are you sure you want to <strong>permanently delete</strong> the variant <strong>"' + variantName + '"</strong>?<br/><br/>' +
                    'This will <strong>completely remove it from the database</strong> and <strong>CANNOT BE UNDONE!</strong>';
            }

            // Show modal
            modal.classList.add('show');
            modal.style.display = 'flex';
            modal.style.visibility = 'visible';
            modal.style.opacity = '1';
            modal.style.zIndex = '9999';
            document.body.style.overflow = 'hidden';

            // ✅ Focus on password field after modal is visible
            setTimeout(function () {
                if (passwordField) {
                    passwordField.focus();
                    console.log('✅ Password field focused');
                }
            }, 400);
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

            // ✅ ALWAYS clear password field when closing modal
            const passwordField = document.getElementById('txtAdminPasswordVariant');
            if (passwordField) {
                passwordField.value = '';
                console.log('✅ Password field cleared on modal close');
            }
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
            success: function (response) {
                console.log('✅ Delete product response:', response);

                if (response.success) {
                    showNotification('success', 'Product Deleted', 'Product deleted successfully!', true, 3000);
                    closeDeleteProductModal();
                    // Reload page to refresh product list
                    setTimeout(function () {
                        window.location.reload();
                    }, 3500);
                } else {
                    showNotification('error', 'Delete Failed', 'Failed to delete product: ' + (response.error || 'Unknown error'));
                }
            },
            error: function (xhr, status, error) {
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
            complete: function () {
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
        if (!adminPassword) { showNotification('warning', 'Password Required', 'Admin password is required to delete variants.'); if (pwdField) { pwdField.focus(); } return; }

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
            success: function (response) {
                console.log('✅ Delete variant response:', response);

                if (response.success) {
                    showNotification('success', 'Variant Deleted', 'Variant deleted successfully!', true, 3000);
                    closeDeleteVariantModal();

                    // If we're in the variants modal, refresh the variants table
                    if (document.getElementById('viewVariantsModal') && document.getElementById('viewVariantsModal').classList.contains('show')) {
                        // Refresh variants table
                        setTimeout(function () {
                            viewProductVariants(currentProductId, currentProductName);
                        }, 1000);
                    } else {
                        // Reload page to refresh product list
                        setTimeout(function () {
                            window.location.reload();
                        }, 3500);
                    }
                } else {
                    showNotification('error', 'Delete Failed', 'Failed to delete variant: ' + (response.error || 'Unknown error'));
                }
            },
            error: function (xhr, status, error) {
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
            complete: function () {
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
            setTimeout(function () {
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

        // Store product ID in hidden field
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

        window.loadUpdateProductIngredients(productId);

        // Show loading state
        var txtUpdateProductName = document.getElementById('txtUpdateProductName');
        var ddlUpdateCategory = document.getElementById('ddlUpdateCategory');
        var txtUpdateDescription = document.getElementById('txtUpdateDescription');

        if (txtUpdateProductName) txtUpdateProductName.value = 'Loading...';
        if (ddlUpdateCategory) ddlUpdateCategory.disabled = true;
        if (txtUpdateDescription) txtUpdateDescription.value = 'Loading...';

        // Fetch product data
        $.ajax({
            type: "POST",
            url: "/Handlers/GetProduct.ashx",
            data: JSON.stringify({ productId: productId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (response) {
                console.log('✅ Product data loaded:', response);

                if (response.success && response.product) {
                    var product = response.product;

                    // Fill form fields
                    if (txtUpdateProductName) txtUpdateProductName.value = product.productName || '';

                    var categoryDropdown = document.getElementById('ddlUpdateCategory');
                    if (categoryDropdown) {
                        categoryDropdown.disabled = false;
                        categoryDropdown.value = product.productCategory || '';
                    }

                    if (txtUpdateDescription) txtUpdateDescription.value = product.productDesc || '';

                    // ✅ FIXED: Load existing image into preview
                    var imagePreview = document.getElementById('updateProductImagePreview');
                    var fileInput = document.getElementById('fuUpdateProductImage');

                    if (imagePreview) {
                        // Display existing image from database (via handler)
                        imagePreview.src = '/Handlers/GetProductImage.ashx?productId=' + productId;
                        imagePreview.onerror = function () {
                            console.error('❌ Failed to load existing product image');
                            this.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjgwIi8+'; // Placeholder
                        };

                        console.log('✅ Loaded existing image from database');
                    }

                    // ✅ Clear file input so user can choose new file
                    if (fileInput) {
                        fileInput.value = '';
                    }

                    console.log('✅ Form fields populated successfully');
                } else {
                    showNotification('error', 'Load Failed', 'Failed to load product data: ' + (response.error || 'Unknown error'));
                    closeUpdateProductModal();
                }
            },
            error: function (xhr, status, error) {
                console.error('❌ Failed to load product data:', status, error);
                showNotification('error', 'Load Failed', 'Server error: ' + error);
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

        var hiddenId = document.getElementById('<%= hiddenProductId.ClientID %>');
        var productId = hiddenId ? hiddenId.value : '';

        if (!productId) {
            showNotification('error', 'Missing Information', 'Product ID not found. Please try again.');
            return;
        }

        var txtUpdateProductName = document.getElementById('txtUpdateProductName');
        var ddlUpdateCategory = document.getElementById('ddlUpdateCategory');
        var txtUpdateDescription = document.getElementById('txtUpdateDescription');
        var fileInput = document.getElementById('fuUpdateProductImage');

        var productName = txtUpdateProductName ? txtUpdateProductName.value.trim() : '';
        var category = ddlUpdateCategory ? ddlUpdateCategory.value : '';
        var description = txtUpdateDescription ? txtUpdateDescription.value.trim() : '';
        var ingredients = window.getUpdateIngredients ? window.getUpdateIngredients() : [];

        if (!productName || !category) {
            showNotification('warning', 'Validation Error', 'Product name and category are required.');
            return;
        }

        const updateBtn = document.querySelector('#updateProductModal .btn-primary');
        const originalText = updateBtn ? updateBtn.innerHTML : '';
        if (updateBtn) {
            updateBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> <span>Updating...</span>';
            updateBtn.disabled = true;
        }

        // ✅ CREATE FORMDATA - EXACTLY LIKE VARIANT UPDATE
        var formData = new FormData();
        formData.append('productId', productId);
        formData.append('productName', productName);
        formData.append('category', category);
        formData.append('description', description);
        formData.append('ingredients', JSON.stringify(ingredients));

        // ✅ CRITICAL: Append file exactly like variant update
        console.log('🔍 File input element:', fileInput);
        console.log('🔍 Files count:', fileInput && fileInput.files ? fileInput.files.length : 0);

        if (fileInput && fileInput.files && fileInput.files.length > 0) {
            var file = fileInput.files[0];
            console.log('📷 File selected:', file.name, '(' + (file.size / 1024).toFixed(2) + ' KB)');
            console.log('📷 File type:', file.type);

            // ✅ Append with key 'productImage' (same as handler expects)
            formData.append('productImage', file, file.name);
            console.log('✅ File appended to FormData');
        } else {
            console.log('⚠️ No file selected for upload');
        }

        // ✅ SEND REQUEST - EXACTLY LIKE VARIANT UPDATE
        $.ajax({
            type: 'POST',
            url: '/Handlers/UpdateProduct.ashx',
            data: formData,
            processData: false,  // ✅ CRITICAL - Same as variant update
            contentType: false,  // ✅ CRITICAL - Same as variant update
            cache: false,
            success: function (response) {
                console.log('✅ Update response:', response);

                if (response.success) {
                    showNotification('success', 'Product Updated',
                        response.message || 'Product updated successfully!', true, 3000);
                    closeUpdateProductModal();

                    // ✅ Force reload to show new image
                    setTimeout(function () {
                        window.location.reload(true);
                    }, 3500);
                } else {
                    showNotification('error', 'Update Failed', response.error || 'Unknown error');
                }
            },
            error: function (xhr, status, error) {
                console.error('❌ Update failed:', status, error);
                console.error('📄 Response text:', xhr.responseText);

                let errorMessage = 'Failed to update product.';
                try {
                    const response = JSON.parse(xhr.responseText);
                    if (response.error) {
                        errorMessage = response.error;
                    }
                } catch (e) {
                    errorMessage = xhr.statusText || error || 'Server error';
                }

                showNotification('error', 'Update Failed', errorMessage);
            },
            complete: function () {
                if (updateBtn) {
                    updateBtn.innerHTML = originalText;
                    updateBtn.disabled = false;
                }
            }
        });
    }

    // ✅ Helper function to send the update request
    function sendUpdateRequest(productId, productName, category, description, ingredients, base64Image, updateBtn, originalText) {
        var requestData = {
            productId: productId,
            productName: productName,
            category: category,
            description: description,
            ingredients: JSON.stringify(ingredients)
        };

        // Add image if provided
        if (base64Image) {
            requestData.productImage = base64Image;
            console.log('📷 Including new image in update request');
            console.log('🔍 Image data length:', base64Image.length);
        } else {
            console.log('⚠️ No image in update request');
        }

        console.log('📦 Sending update request...');
        console.log('📋 Request data keys:', Object.keys(requestData));

        $.ajax({
            type: "POST",
            url: "/Handlers/UpdateProduct.ashx",
            data: JSON.stringify(requestData),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (response) {
                console.log('✅ Update response:', response);

                if (response.success) {
                    showNotification('success', 'Product Updated', response.message || 'Product updated successfully!', true, 3000);
                    closeUpdateProductModal();

                    // Clear browser cache and reload
                    setTimeout(function () {
                        // Force cache clear
                        if (window.performance && window.performance.navigation.type === 1) {
                            console.log('🔄 Hard reload detected');
                        }
                        window.location.reload(true); // Force reload from server
                    }, 3500);
                } else {
                    showNotification('error', 'Update Failed', 'Failed to update product: ' + (response.error || 'Unknown error'));
                }
            },
            error: function (xhr, status, error) {
                console.error('❌ Update failed:', status, error);
                console.error('📄 Response:', xhr.responseText);

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
            complete: function () {
                if (updateBtn) {
                    updateBtn.innerHTML = originalText;
                    updateBtn.disabled = false;
                }
            }
        });
    }

    // ✅ Helper function to send the update request
    function sendUpdateRequest(productId, productName, category, description, ingredients, base64Image, updateBtn, originalText) {
        var requestData = {
            productId: productId,
            productName: productName,
            category: category,
            description: description,
            ingredients: JSON.stringify(ingredients)
        };

        // Add image if provided
        if (base64Image) {
            requestData.productImage = base64Image;
            console.log('📷 Uploading new product image (base64)');
        }

        console.log('📦 Update data prepared');

        $.ajax({
            type: "POST",
            url: "/Handlers/UpdateProduct.ashx",
            data: JSON.stringify(requestData),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (response) {
                console.log('✅ Update product response:', response);

                if (response.success) {
                    showNotification('success', 'Product Updated', 'Product updated successfully!', true, 3000);
                    closeUpdateProductModal();

                    setTimeout(function () {
                        window.location.reload();
                    }, 3500);
                } else {
                    showNotification('error', 'Update Failed', 'Failed to update product: ' + (response.error || 'Unknown error'));
                }
            },
            error: function (xhr, status, error) {
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
            complete: function () {
                if (updateBtn) {
                    updateBtn.innerHTML = originalText;
                    updateBtn.disabled = false;
                }
            }
        });
    }

    // Replace existing showUpdateVariantModal implementation with this version
    (function () {
        // Resilient showUpdateVariantModal: prefer cache but fetch details when price/weight are missing
        window.showUpdateVariantModal = function (variantId) {
            try {
                if (!variantId) { showNotification('error', 'Variant', 'Variant ID missing'); return; }

                var list = (window.__variantsCache && window.__variantsCache[currentProductId]) || [];
                var cached = list.find(function (v) { return (v.Id || v.id) == variantId; });

                function normalizeNumericFields(v) {
                    if (!v) return v;
                    if (v.Price !== undefined && v.Price !== null && typeof v.Price === 'string') {
                        var p = parseFloat(v.Price);
                        v.Price = isNaN(p) ? v.Price : p;
                    }
                    if (v.Weight !== undefined && v.Weight !== null && typeof v.Weight === 'string') {
                        var w = parseFloat(v.Weight);
                        v.Weight = isNaN(w) ? v.Weight : w;
                    }
                    return v;
                }

                function applyAndOpen(v) {
                    if (!v) { showNotification('error', 'Variant', 'Variant not found'); return; }
                    normalizeNumericFields(v);
                    fillUpdateVariantForm(v);
                    openModalVariant();
                }

                // If we have cached entry and it already includes price & weight, use it.
                if (cached && (cached.Price !== undefined && cached.Price !== null) && (cached.Weight !== undefined && cached.Weight !== null)) {
                    applyAndOpen(cached);
                    return;
                }

                // Otherwise fetch authoritative details from server
                $.ajax({
                    type: 'GET',
                    url: '/Handlers/GetVariantDetails.ashx',
                    data: { variantId: variantId },
                    dataType: 'json'
                }).done(function (res) {
                    var v = null;
                    if (!res) {
                        showNotification('error', 'Variant', 'Empty response from server');
                        return;
                    }
                    // Server may return { success:true, variant: {...} } or the variant object directly
                    if (res.success && res.variant) v = res.variant;
                    else if (res.variant) v = res.variant;
                    else v = res;

                    if (v) {
                        // update cache if present
                        try {
                            if (window.__variantsCache && window.__variantsCache[currentProductId]) {
                                var idx = window.__variantsCache[currentProductId].findIndex(function (x) { return (x.Id || x.id) == variantId; });
                                if (idx > -1) window.__variantsCache[currentProductId][idx] = v;
                            }
                        } catch (e) { console.warn('Failed to update cache', e); }

                        applyAndOpen(v);
                    } else {
                        // fallback to cached variant if available
                        if (cached) {
                            applyAndOpen(cached);
                            showNotification('warning', 'Offline', 'Loaded variant from cache');
                        } else {
                            showNotification('error', 'Variant', 'Could not load variant details');
                        }
                    }
                }).fail(function () {
                    // network / server error - fall back to cache if available
                    if (cached) {
                        applyAndOpen(cached);
                        showNotification('warning', 'Offline', 'Loaded variant from cache');
                    } else {
                        showNotification('error', 'Variant', 'Failed to load variant details from server');
                    }
                });
            } catch (e) {
                console.error('showUpdateVariantModal error', e);
                showNotification('error', 'Variant', 'Unexpected error opening variant modal');
            }
        };
    })();

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
            setTimeout(function () { closeNotificationModal(); }, ms);
        }
    }

    function closeNotificationModal() {
        var modal = document.getElementById('notificationModal');
        var progress = document.getElementById('notificationProgress');
        if (!modal) return;
        modal.classList.remove('show', 'auto-hide');
        if (progress) { progress.style.width = '0%'; progress.style.animationDuration = ''; }
    }

    // confirmation for saving product
    // ✅ IMPROVED: Ensure ingredients are always saved before form submission
    function openConfirmSaveProduct() {
        var name = document.getElementById('<%= txtProductName.ClientID %>').value.trim();
        var category = document.getElementById('<%= ddlCategory.ClientID %>').value;

        if (!name) {
            showNotification('warning', 'Validation', 'Product name is required.');
            return false;
        }
        if (!category) {
            showNotification('warning', 'Validation', 'Category is required.');
            return false;
        }

        // ✅ CRITICAL: Always save ingredients to hidden field before proceeding
        var ingredients = window.getSelectedIngredients ? window.getSelectedIngredients() : [];
        var hdnField = document.getElementById('<%= hdnSelectedIngredients.ClientID %>');
        if (hdnField) {
            hdnField.value = JSON.stringify(ingredients);
            console.log('✅ Ingredients saved to hidden field:', ingredients);
        } else {
            console.error('❌ Hidden field hdnSelectedIngredients not found!');
        }

        // Show confirmation modal
        var modal = document.getElementById('confirmationModal');
        if (!modal) {
            console.log('⚠️ No confirmation modal found, submitting directly');
            return true; // Allow form submission if modal doesn't exist
        }

        document.getElementById('confirmationTitle').textContent = 'Confirm Add Product';
        document.getElementById('confirmationMessage').textContent = 'Add product "' + name + '" to ' + category + '?';
        modal.classList.add('show');

        // Set confirm handler
        var btn = document.getElementById('confirmationConfirmBtn');
        btn.onclick = function () {
            modal.classList.remove('show');
            // Prevent double submission
            if (window.__savingProduct) { return; }
            window.__savingProduct = true;
            // Trigger server postback
            __doPostBack('<%= btnSaveProduct.UniqueID %>', '');
    };

    return false; // Prevent immediate form submission
}

// ===== Appended: ensure fetchVariants + viewProductVariants exist (no removals) =====
    // ===== Fix the viewProductVariants and fetchVariants functions =====
    (function () {
        if (typeof window.viewProductVariants !== 'function') {
            window.viewProductVariants = function (productId, productName) {
                try {
                    // ✅ NEW: Validate and log productId before proceeding
                    console.log('👁️ viewProductVariants called with:', {
                        productId: productId,
                        productName: productName,
                        productIdType: typeof productId,
                        productIdLength: productId ? productId.length : 0
                    });

                    // ✅ NEW: Validate productId format
                    if (!productId || productId.trim() === '') {
                        console.error('❌ Invalid productId:', productId);
                        showNotification('error', 'Invalid Product', 'Product ID is missing or invalid');
                        return;
                    }

                    // ✅ NEW: Ensure productId is a string and trimmed
                    productId = String(productId).trim();

                    currentProductId = productId;
                    currentProductName = productName || '';

                    var modal = document.getElementById('viewVariantsModal');
                    if (modal) {
                        modal.style.display = 'flex';
                        modal.style.visibility = 'visible';
                        modal.style.opacity = '1';
                        modal.classList.add('show');
                        document.body.style.overflow = 'hidden';
                    }

                    var nameEl = document.getElementById('viewVariantsProductName');
                    if (nameEl) nameEl.textContent = currentProductName || 'Product';

                    // ✅ NEW: Show "Loading..." instead of "0 variants" initially
                    var summary = document.getElementById('viewVariantsSummary');
                    if (summary) summary.textContent = ' (Loading...)';

                    var meta = document.getElementById('viewVariantsMeta');
                    if (meta) meta.textContent = 'Loading…';

                    var tbody = document.getElementById('variantsTableBody');
                    if (tbody) tbody.innerHTML = '<tr><td colspan="9" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading…</td></tr>';

                    if (typeof window.fetchVariants === 'function') {
                        // ✅ NEW: Log the exact URL and data being sent
                        console.log('📡 About to fetch variants for productId:', productId);

                        window.fetchVariants(productId).then(function (response) {
                            console.log('📊 fetchVariants resolved with:', response);

                            // ✅ Extract variants array properly
                            var variants = [];

                            if (response && response.success && Array.isArray(response.variants)) {
                                variants = response.variants;
                            } else if (Array.isArray(response)) {
                                variants = response;
                            } else if (response && response.d) {
                                var d = response.d;
                                if (typeof d === 'string') {
                                    try { d = JSON.parse(d); } catch (e) { }
                                }
                                if (Array.isArray(d)) {
                                    variants = d;
                                } else if (d && Array.isArray(d.variants)) {
                                    variants = d.variants;
                                }
                            }

                            console.log('✅ Extracted', variants.length, 'variants');

                            // ✅ NEW: If no variants found, show error message with productId for debugging
                            if (variants.length === 0) {
                                console.warn('⚠️ No variants found for productId:', productId);
                                console.warn('⚠️ Response was:', response);
                            }

                            // ✅ Cache the variants for action buttons
                            if (!window.__variantsCache) window.__variantsCache = {};
                            window.__variantsCache[productId] = variants;

                            // ✅ Update the modal UI
                            if (tbody) {
                                if (variants.length === 0) {
                                    tbody.innerHTML = '<tr><td colspan="9" class="text-center" style="padding:40px; color:#888;">' +
                                        '<i class="fa fa-box-open" style="font-size:48px; display:block; margin-bottom:10px; color:#ddd;"></i>' +
                                        'No variants found for this product<br>' +
                                        '<small style="font-size:12px; color:#999; margin-top:10px; display:block;">Product ID: ' + productId + '</small>' +
                                        '</td></tr>';
                                } else {
                                    tbody.innerHTML = variants.map(function (v, i) {
                                        var status = (v.StockQuantity != null && v.MinimumStock != null && v.StockQuantity <= v.MinimumStock) ? 'Low' : 'OK';

                                        return '<tr>' +
                                            '<td>' + (i + 1) + '</td>' +
                                            '<td>' + (v.VariantName || '') + '</td>' +
                                            '<td>' + (v.SKU || '') + '</td>' +
                                            '<td>' + (v.Price != null ? '₱' + v.Price.toFixed(2) : '') + '</td>' +
                                            '<td>' + (v.StockQuantity != null ? v.StockQuantity : '') + '</td>' +
                                            '<td>' + status + '</td>' +
                                            '<td>' + (v.Size || '') + '</td>' +
                                            '<td>' + (v.Color || '') + '</td>' +
                                            '<td></td>' + // Action buttons will be injected by refreshVariantActions
                                            '</tr>';
                                    }).join('');
                                }
                            }

                            // ✅ NEW: Update summary with actual count
                            if (summary) summary.textContent = ' (' + variants.length + ' variant' + (variants.length === 1 ? '' : 's') + ')';

                            if (meta) meta.textContent = variants.length + ' variant(s)';

                            // ✅ Inject action buttons
                            if (window.refreshVariantActions) {
                                window.refreshVariantActions();
                            }

                        }).catch(function (err) {
                            console.error('❌ viewProductVariants error:', err);
                            if (tbody) tbody.innerHTML = '<tr><td colspan="9" class="text-center" style="color:#f44336;">Failed to load variants: ' + (err.message || 'Unknown error') + '</td></tr>';
                            if (meta) meta.textContent = 'Error loading variants';
                            if (summary) summary.textContent = ' (Error)';
                            showNotification('error', 'Load Failed', 'Failed to load variants: ' + (err.message || 'Unknown error'));
                        });
                    }
                } catch (e) {
                    console.error('❌ viewProductVariants exception:', e);
                    showNotification('error', 'Error', 'Failed to open variants modal: ' + e.message);
                }
            };
        }
    })();
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
                    '</button>' +
                    '<button type="button" class="icon" title="Archive Variant" onclick="event.stopPropagation(); archiveVariant(\'' + esc(vid) + '\');">' +
                    '<i class="fa fa-archive"></i>' +
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
        '<div id="updateVariantModal" class="modal-overlay"  data-move-to-body="true">'+
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
            '<div class="form-row">' +
            '<div class="form-group"><label class="form-label">Minimum Stock</label><input type="number" id="updVariantMinStock" class="form-control" placeholder="1000" value="1000" readonly style="background-color: #f5f5f5; cursor: not-allowed;" /><small style="color:#666;font-size:12px;margin-top:5px;display:block;"><i class="fa fa-info-circle"></i> Minimum stock is set to 1000 by default</small></div>' +
            '<div class="form-group"><label class="form-label">Weight (g)</label><input type="number" step="0.01" id="updVariantWeight" class="form-control" placeholder="0.00" /></div>' +
            '</div>' +
              '<div class="form-row">'+
            '<div class="form-group"><label class="form-label">Dimensions</label><input type="text" id="updVariantDimensions" class="form-control" placeholder="L x W x H" /></div>' +
           
            // ✅ NEW FILE UPLOAD SECTION:
            '<div class="form-group">' +
            '<label class="form-label">Variant Images (Multiple)</label>' +
            '<input type="file" id="updVariantImagesFiles" class="form-control" accept="image/*" multiple />' +
            '<small style="color:#666;font-size:12px;margin-top:5px;display:block;">' +
            '<i class="fa fa-info-circle"></i> Select multiple images (Ctrl+Click - Max 10 images, 5MB each)' +
            '</small>' +
            '<div id="updVariantImagesPreview" style="margin-top:10px; display:flex; flex-wrap:wrap; gap:10px;"></div>' +
            '</div>' +

            // ✅ ADD EXISTING IMAGES DISPLAY:
            '<div class="form-group">' +
            '<label class="form-label">Current Images</label>' +
            '<div id="updVariantCurrentImages" style="display:flex; flex-wrap:wrap; gap:10px; margin-top:10px;"></div>' +
            '</div>' +
              '</div>'+
               ` <div class="form-row"> <div class="form-group"> <label class="form-label">Description</label> <input type="text" id="updVariantDescription" class="form-control" placeholder="Enter variant description..." /> </div> </div>`+
              '<div class="form-group"><label class="form-label">Lifespan / Best Before (years)</label><input type="number" id="updVariantShelfLifeYears" class="form-control" placeholder="1" /><small style="color:#666;font-size:12px;margin-top:5px;display:block;">How many years the product stays fresh (e.g., 1 for 1 year)</small></div>'+
              // 📍 CHANGED: Location is now a dropdown instead of readonly text input
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





    // ✅ NEW: Setup Update Variant Image Upload Preview
    (function () {
        function setupUpdateVariantImagePreview() {
            var fileInput = document.getElementById('updVariantImagesFiles');
            var previewContainer = document.getElementById('updVariantImagesPreview');

            if (!fileInput || !previewContainer) {
                console.log('⚠️ Update variant file input or preview container not found');
                return;
            }

            // Remove existing listener to avoid duplicates
            fileInput.removeEventListener('change', handleUpdateVariantImageChange);
            fileInput.addEventListener('change', handleUpdateVariantImageChange);

            console.log('✅ Update variant image preview setup complete');
        }

        function handleUpdateVariantImageChange(e) {
            var previewContainer = document.getElementById('updVariantImagesPreview');
            if (!previewContainer) return;

            previewContainer.innerHTML = ''; // Clear previous previews

            var files = Array.from(e.target.files);
            console.log('📷 Selected', files.length, 'NEW image(s) for update');

            if (files.length > 10) {
                showNotification('warning', 'Too Many Files', 'Maximum 10 images allowed');
                e.target.value = '';
                return;
            }

            files.forEach(function (file, index) {
                if (file.type.startsWith('image/')) {
                    // Check file size
                    if (file.size > 5 * 1024 * 1024) {
                        showNotification('warning', 'File Too Large', file.name + ' is larger than 5MB');
                        return;
                    }

                    var reader = new FileReader();
                    reader.onload = function (e) {
                        var previewDiv = document.createElement('div');
                        previewDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                        var img = document.createElement('img');
                        img.src = e.target.result;
                        img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px; border:2px solid #4CAF50;';

                        var removeBtn = document.createElement('button');
                        removeBtn.type = 'button';
                        removeBtn.innerHTML = '×';
                        removeBtn.style.cssText = 'position:absolute; top:-8px; right:-8px; background:#dc3545; color:white; border:none; border-radius:50%; width:24px; height:24px; cursor:pointer; font-size:16px; line-height:1;';
                        removeBtn.onclick = function () {
                            previewDiv.remove();
                            console.log('🗑️ Removed preview for:', file.name);
                        };

                        // Add label to distinguish new uploads
                        var label = document.createElement('div');
                        label.textContent = 'NEW';
                        label.style.cssText = 'position:absolute; bottom:0; left:0; right:0; background:#4CAF50; color:white; text-align:center; font-size:10px; padding:2px; border-radius:0 0 8px 8px;';

                        previewDiv.appendChild(img);
                        previewDiv.appendChild(removeBtn);
                        previewDiv.appendChild(label);
                        previewContainer.appendChild(previewDiv);

                        console.log('✅ NEW image preview loaded for:', file.name);
                    };
                    reader.readAsDataURL(file);
                }
            });
        }

        // Initialize when modal opens
        var originalShowUpdateVariantModal = window.showUpdateVariantModal;
        if (originalShowUpdateVariantModal) {
            window.showUpdateVariantModal = function (variantId) {
                originalShowUpdateVariantModal(variantId);
                setTimeout(setupUpdateVariantImagePreview, 200);
            };
        }

        // Also setup on DOM ready
        document.addEventListener('DOMContentLoaded', function () {
            setTimeout(setupUpdateVariantImagePreview, 1000);
        });
    })();


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
            option.textContent = 'Select product category first';
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

        // Add location options for the category
        var locations = locationsByCategory[category];
        locations.forEach(function(location) {
            var option = document.createElement('option');
            option.value = location;
            option.textContent = location + ' - ' + category + ' Storage';
            locationDropdown.appendChild(option);
        });

        console.log('✅ Update variant location dropdown populated with', locations.length, 'options for', category);
    }


    function fillUpdateVariantForm(variant) {
        if (!variant) return;

        // Fill all existing fields
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
        document.getElementById('updVariantDescription').value = (variant.Description || variant.description || '');

        // Fill shelf life years
        var shelfLifeYears = variant.ShelfLifeYears || variant.shelfLifeYears;
        document.getElementById('updVariantShelfLifeYears').value = shelfLifeYears || '';

        // Get product category and populate location dropdown
        var productId = variant.ProductId || variant.productId || currentProductId;
        var currentLocation = variant.Location || variant.location || '';

        var productRow = document.querySelector('[data-product-id="' + productId + '"]');
        if (productRow) {
            var category = productRow.getAttribute('data-category');
            console.log('📍 Populating location dropdown for category:', category);
            updateUpdateVariantLocationDropdown(category, currentLocation);

            // Set the current location as selected
            setTimeout(function () {
                var locationDropdown = document.getElementById('updVariantLocation');
                if (locationDropdown && currentLocation) {
                    locationDropdown.value = currentLocation;
                }
            }, 100);
        }

        // ✅ LOAD IMAGES FROM DATABASE
        var variantId = variant.Id || variant.id || '';
        if (variantId) {
            loadVariantImagesFromDatabase(variantId);
        }

        var msg = document.getElementById('updVariantMsg');
        if (msg) { msg.style.display = 'none'; msg.textContent = ''; }

        // ✅ ADD THESE NEW FUNCTIONS HERE (after fillUpdateVariantForm)
        function loadVariantImagesFromDatabase(variantId) {
            console.log('📥 Loading images for variant:', variantId);

            $.ajax({
                type: "POST",
                url: "/Handlers/GetVariantImages.ashx",
                data: JSON.stringify({ variantId: variantId }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: function (response) {
                    console.log('📦 GetVariantImages response:', response);

                    if (response.success && response.images && response.images.length > 0) {
                        console.log('✅ Found', response.images.length, 'images');
                        displayCurrentImages(response.images);
                    } else {
                        console.log('⚠️ No images found for variant:', variantId);
                        displayCurrentImages([]);
                    }
                },
                error: function (xhr, status, error) {
                    console.error('❌ Failed to load variant images:', status, error);
                    displayCurrentImages([]);
                }
            });
        }

        // Replace the existing displayCurrentImages(images) function with this implementation
        function displayCurrentImages(images) {
            var currentImagesContainer = document.getElementById('updVariantCurrentImages');
            if (!currentImagesContainer) {
                console.error('Current images container not found');
                return;
            }

            currentImagesContainer.innerHTML = '';

            if (!images || images.length === 0) {
                currentImagesContainer.innerHTML = '<div style="color:#999; font-size:13px; padding:10px;">No existing images</div>';
                console.log('⚠️ No images to display');
                return;
            }

            var variantId = document.getElementById('updVariantId').value;
            console.log('🖼️ Displaying', images.length, 'images for variant:', variantId);

            images.forEach(function (imageUrl, index) {
                var imageDiv = document.createElement('div');
                imageDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                var img = document.createElement('img');

                // Use the URL returned by the handler and append a cache-buster to force re-fetch
                var separator = imageUrl.indexOf('?') === -1 ? '?' : '&';
                img.src = imageUrl + separator + 'v=' + Date.now();

                img.alt = 'Variant Image ' + (index + 1);
                img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px; border:2px solid #667eea;';

                img.onerror = function () {
                    console.error('❌ Failed to load image:', imageUrl);
                    imageDiv.innerHTML = '<div style="width:100%; height:100%; background:#f0f0f0; display:flex; align-items:center; justify-content:center; border-radius:8px; font-size:10px; color:#999;">Failed to load</div>';
                };

                img.onload = function () {
                    console.log('✅ Image loaded:', imageUrl);
                };

                var removeBtn = document.createElement('button');
                removeBtn.type = 'button';
                removeBtn.innerHTML = '×';
                removeBtn.className = 'remove-img-url';
                removeBtn.title = 'Remove this image';
                removeBtn.onclick = function () {
                    removeVariantImage(index, variantId);
                };

                imageDiv.appendChild(img);
                imageDiv.appendChild(removeBtn);
                currentImagesContainer.appendChild(imageDiv);
            });

            console.log('✅ Displayed', images.length, 'images with remove buttons');
        }

        function removeVariantImage(imageUrl, variantId) {
            if (!confirm('Are you sure you want to remove this image?')) {
                return;
            }

            // ✅ FIX: imageUrl is actually an index number, not a URL
            var imageIndex;

            // Check if imageUrl is already a number (index)
            if (typeof imageUrl === 'number') {
                imageIndex = imageUrl;
            } else if (typeof imageUrl === 'string') {
                // Try to extract index from URL
                var indexMatch = imageUrl.match(/[?&]index=(\d+)/i);
                if (indexMatch && indexMatch[1]) {
                    imageIndex = parseInt(indexMatch[1]);
                } else {
                    console.error('❌ Cannot extract index from URL:', imageUrl);
                    showNotification('error', 'Invalid Image URL', 'Cannot determine which image to remove');
                    return;
                }
            } else {
                console.error('❌ Invalid imageUrl type:', typeof imageUrl);
                showNotification('error', 'Invalid Parameter', 'Cannot remove image');
                return;
            }

            console.log('🗑️ Removing image at index:', imageIndex, 'from variant:', variantId);

            // Show loading state
            var currentImagesContainer = document.getElementById('updVariantCurrentImages');
            if (currentImagesContainer) {
                var loadingDiv = document.createElement('div');
                loadingDiv.style.cssText = 'position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); background:rgba(255,255,255,0.9); padding:20px; border-radius:8px; z-index:1000;';
                loadingDiv.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Removing...';
                currentImagesContainer.style.position = 'relative';
                currentImagesContainer.appendChild(loadingDiv);
            }

            $.ajax({
                type: 'POST',
                url: '/Handlers/RemoveVariantImage.ashx',
                data: JSON.stringify({
                    variantId: variantId,
                    index: imageIndex  // ✅ Send index instead of imageUrl
                }),
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (response) {
                    console.log('✅ Remove response:', response);

                    if (response.success) {
                        showNotification('success', 'Image Removed', 'Image removed successfully!', true, 2000);

                        // Reload the variant images from database
                        loadVariantImagesFromDatabase(variantId);
                    } else {
                        showNotification('error', 'Remove Failed', response.error || 'Failed to remove image');

                        // Remove loading state
                        if (currentImagesContainer && currentImagesContainer.lastChild.tagName === 'DIV') {
                            currentImagesContainer.removeChild(currentImagesContainer.lastChild);
                        }
                    }
                },
                error: function (xhr, status, error) {
                    console.error('❌ Remove image failed:', status, error);

                    let errorMessage = 'Server error while removing image';
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (response.error) {
                            errorMessage = response.error;
                        }
                    } catch (e) {
                        errorMessage = xhr.statusText || error || 'Unknown error';
                    }

                    showNotification('error', 'Remove Failed', errorMessage);

                    // Remove loading state
                    if (currentImagesContainer && currentImagesContainer.lastChild.tagName === 'DIV') {
                        currentImagesContainer.removeChild(currentImagesContainer.lastChild);
                    }
                }
            });
        }


        // ✅ NEW: Load and display existing images
        var currentImagesContainer = document.getElementById('updVariantCurrentImages');
        if (currentImagesContainer) {
            currentImagesContainer.innerHTML = ''; // Clear previous images

            // Get variant images (handle different property names)
            var variantImages = variant.VariantImgUrls || variant.variantImgUrls || variant.Images || [];

            console.log('🖼️ Loading existing images:', variantImages);

            if (Array.isArray(variantImages) && variantImages.length > 0) {
                variantImages.forEach(function (imageUrl, index) {
                    var imageDiv = document.createElement('div');
                    imageDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                    var img = document.createElement('img');
                    img.src = imageUrl;
                    img.alt = 'Variant Image ' + (index + 1);
                    img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px; border:2px solid #667eea;';

                    // Add error handling
                    img.onerror = function () {
                        console.error('❌ Failed to load image:', imageUrl);
                        imageDiv.innerHTML = '<div style="width:100%; height:100%; background:#f0f0f0; display:flex; align-items:center; justify-content:center; border-radius:8px; font-size:10px; color:#999;">Failed to load</div>';
                    };

                    imageDiv.appendChild(img);
                    currentImagesContainer.appendChild(imageDiv);

                    console.log('✅ Loaded image', index + 1, ':', imageUrl);
                });
            } else {
                currentImagesContainer.innerHTML = '<div style="color:#999; font-size:13px; padding:10px;">No existing images</div>';
                console.log('⚠️ No existing images found');
            }
        }

        var msg = document.getElementById('updVariantMsg');
        if (msg) { msg.style.display = 'none'; msg.textContent = ''; }
    }

    // Robust showUpdateVariantModal — always request authoritative variant details,
    // normalize numeric fields, then fill the update modal (falls back to cache on error)
    window.showUpdateVariantModal = function (variantId) {
        try {
            if (!variantId) { showNotification('error', 'Variant', 'Variant ID missing'); return; }

            // show loading notification (non-blocking)
            showNotification('info', 'Loading', 'Loading variant details...', true, 1200);

            // Always prefer authoritative handler so Price/Weight are present
            $.ajax({
                type: 'GET',
                url: '/Handlers/GetVariantDetails.ashx',
                data: { variantId: variantId },
                dataType: 'json',
                cache: false
            }).done(function (res) {
                var v = null;
                if (!res) {
                    showNotification('error', 'Variant', 'Empty response from server');
                    return;
                }
                // Support multiple response shapes
                if (res.success && res.variant) v = res.variant;
                else if (res.variant) v = res.variant;
                else v = res;

                if (!v) {
                    showNotification('error', 'Variant', 'Could not load variant details');
                    // fallback to cache if available
                    var cached = (window.__variantsCache && window.__variantsCache[currentProductId]) ? window.__variantsCache[currentProductId].find(function (x) { return (x.Id || x.id) == variantId; }) : null;
                    if (cached) { fillUpdateVariantForm(cached); openModalVariant(); showNotification('warning', 'Offline', 'Loaded variant from cache'); }
                    return;
                }

                // Normalize numeric fields (Price, Weight, Stock, MinimumStock)
                function normNum(val) {
                    if (val === null || val === undefined || val === '') return null;
                    if (typeof val === 'number') return val;
                    var n = parseFloat(val);
                    return isNaN(n) ? null : n;
                }
                if (v.Price === undefined) v.Price = normNum(v.price);
                else v.Price = normNum(v.Price);
                if (v.Weight === undefined) v.Weight = normNum(v.weight);
                else v.Weight = normNum(v.Weight);
                if (v.StockQuantity === undefined) v.StockQuantity = normNum(v.stockQuantity);
                else v.StockQuantity = normNum(v.StockQuantity);
                if (v.MinimumStock === undefined) v.MinimumStock = normNum(v.minimumStock);
                else v.MinimumStock = normNum(v.MinimumStock);

                // Update cache so subsequent opens are fast
                try {
                    if (!window.__variantsCache) window.__variantsCache = {};
                    if (!window.__variantsCache[currentProductId]) window.__variantsCache[currentProductId] = [];
                    var idx = window.__variantsCache[currentProductId].findIndex(function (x) { return (x.Id || x.id) == variantId; });
                    if (idx > -1) window.__variantsCache[currentProductId][idx] = v;
                    else window.__variantsCache[currentProductId].push(v);
                } catch (_) { /* ignore cache errors */ }

                // Fill form & open modal
                fillUpdateVariantForm(v);
                openModalVariant();
            }).fail(function () {
                // On error try to use cache
                var cached = (window.__variantsCache && window.__variantsCache[currentProductId]) ? window.__variantsCache[currentProductId].find(function (x) { return (x.Id || x.id) == variantId; }) : null;
                if (cached) {
                    fillUpdateVariantForm(cached);
                    openModalVariant();
                    showNotification('warning', 'Offline', 'Loaded variant from cache');
                } else {
                    showNotification('error', 'Variant', 'Failed to load variant details from server');
                }
            });
        } catch (e) {
            console.error('showUpdateVariantModal error', e);
            showNotification('error', 'Variant', 'Unexpected error opening variant modal');
        }
    };

    function openModalVariant(){
        var m = document.getElementById('updateVariantModal');
        if (m) {
            m.classList.add('show');
            m.style.display = 'flex';
            m.style.visibility = 'visible';
            m.style.opacity = '1';
            document.body.style.overflow = 'hidden';
        }
    }

    // Replace existing updateVariantSave with this scoped implementation
    window.updateVariantSave = async function () {
        var btn = document.getElementById('btnDoUpdateVariant');
        if (btn) {
            btn.disabled = true;
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i><span> Saving...</span>';
        }

        // Scope all element lookups to the updateVariantModal to avoid duplicate ID collisions
        var modal = document.getElementById('updateVariantModal');

        function q(id) {
            if (modal) {
                var el = modal.querySelector('#' + id);
                if (el) return el;
            }
            // fallback
            return document.getElementById(id);
        }

        // Basic validation
        var variantIdEl = q('updVariantId');
        var variantId = variantIdEl ? variantIdEl.value.trim() : '';

        var variantNameEl = q('updVariantName');
        var variantName = variantNameEl ? variantNameEl.value.trim() : '';

        var variantSKUEl = q('updVariantSKU');
        var variantSKU = variantSKUEl ? variantSKUEl.value.trim() : '';

        var variantPriceEl = q('updVariantPrice');
        var variantPrice = variantPriceEl ? parseFloat(variantPriceEl.value) || 0 : 0;

        if (!variantId || !variantName || !variantSKU || variantPrice <= 0) {
            showNotification('warning', 'Validation', 'Fill required fields (Name, SKU, Price>0)');
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = '<i class="fa fa-save"></i><span> Save</span>';
            }
            return;
        }

        try {
            // Use the UpdateVariantFileManager already on page
            var files = (typeof updateVariantFileManager !== 'undefined') ? updateVariantFileManager.getFiles() : [];
            var useFormData = files && files.length > 0;
            var requestData;

            var descriptionEl = q('updVariantDescription');
            var descriptionValue = descriptionEl ? descriptionEl.value.trim() : '';

            if (useFormData) {
                btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i><span> Compressing & Uploading...</span>';

                // compress selected files (if compressImage exists)
                var compressedFiles = [];
                if (files.length > 0) {
                    showNotification('info', 'Processing', 'Compressing ' + files.length + ' image(s)...', true, 2000);
                    for (var i = 0; i < files.length; i++) {
                        try {
                            const compressed = await compressImage(files[i]);
                            compressedFiles.push(compressed);
                        } catch (err) {
                            console.error('Compression failed for', files[i].name, err);
                            compressedFiles.push(files[i]);
                        }
                    }
                }

                requestData = new FormData();
                requestData.append('variantId', variantId);
                requestData.append('variantName', variantName);
                requestData.append('variantSKU', variantSKU);
                requestData.append('variantSize', (q('updVariantSize') ? q('updVariantSize').value.trim() : ''));
                requestData.append('variantColor', (q('updVariantColor') ? q('updVariantColor').value.trim() : ''));
                requestData.append('variantPrice', variantPrice);
                requestData.append('variantStock', parseInt(q('updVariantStock') ? q('updVariantStock').value : 0) || 0);
                requestData.append('variantMinStock', parseInt(q('updVariantMinStock') ? q('updVariantMinStock').value : 1000) || 1000);
                requestData.append('variantWeight', q('updVariantWeight') ? q('updVariantWeight').value : '');
                requestData.append('variantDimensions', q('updVariantDimensions') ? q('updVariantDimensions').value.trim() : '');
                requestData.append('description', descriptionValue);
                requestData.append('shelfLifeYears', q('updVariantShelfLifeYears') ? q('updVariantShelfLifeYears').value : '');
                requestData.append('location', q('updVariantLocation') ? q('updVariantLocation').value.trim() : '');

                compressedFiles.forEach(function (file) {
                    requestData.append('variantImages', file);
                });

                $.ajax({
                    type: 'POST',
                    url: '/Handlers/UpdateVariant.ashx',
                    data: requestData,
                    contentType: false,
                    processData: false,
                    dataType: 'json',
                    cache: false
                }).done(function (res) {
                    if (res && res.success) {
                        showNotification('success', 'Variant Updated', res.message || 'Updated', true, 2500);
                        closeUpdateVariantModal();
                        updateVariantFileManager.clear();
                        if (currentProductId && currentProductName) {
                            fetchVariants(currentProductId).then(function () {
                                viewProductVariants(currentProductId, currentProductName);
                            });
                        }
                    } else {
                        showNotification('error', 'Update Failed', (res && res.error) || 'Unknown error');
                    }
                }).fail(function (xhr) {
                    var msg = 'Server error';
                    try { var r = JSON.parse(xhr.responseText); if (r.error) msg = r.error; } catch (_) { }
                    showNotification('error', 'Update Failed', msg);
                }).always(function () {
                    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fa fa-save"></i><span> Save</span>'; }
                });

            } else {
                // text-only update (JSON) - ensure description included and scoped fields used
                requestData = JSON.stringify({
                    variantId: variantId,
                    variantName: variantName,
                    variantSKU: variantSKU,
                    variantSize: (q('updVariantSize') ? q('updVariantSize').value.trim() : ''),
                    variantColor: (q('updVariantColor') ? q('updVariantColor').value.trim() : ''),
                    variantPrice: variantPrice,
                    variantStock: parseInt(q('updVariantStock') ? q('updVariantStock').value : 0) || 0,
                    variantMinStock: parseInt(q('updVariantMinStock') ? q('updVariantMinStock').value : 1000) || 1000,
                    variantWeight: q('updVariantWeight') && q('updVariantWeight').value ? parseFloat(q('updVariantWeight').value) : null,
                    variantDimensions: q('updVariantDimensions') ? q('updVariantDimensions').value.trim() : '',
                    description: descriptionValue,
                    shelfLifeYears: q('updVariantShelfLifeYears') && q('updVariantShelfLifeYears').value ? parseInt(q('updVariantShelfLifeYears').value) : null,
                    location: q('updVariantLocation') ? q('updVariantLocation').value.trim() : ''
                });

                $.ajax({
                    type: 'POST',
                    url: '/Handlers/UpdateVariant.ashx',
                    data: requestData,
                    contentType: 'application/json; charset=utf-8',
                    dataType: 'json',
                    cache: false
                }).done(function (res) {
                    if (res && res.success) {
                        showNotification('success', 'Variant Updated', res.message || 'Updated', true, 2500);
                        closeUpdateVariantModal();
                        if (currentProductId && currentProductName) {
                            fetchVariants(currentProductId).then(function () {
                                viewProductVariants(currentProductId, currentProductName);
                            });
                        }
                    } else {
                        showNotification('error', 'Update Failed', (res && res.error) || 'Unknown error');
                    }
                }).fail(function (xhr) {
                    var msg = 'Server error';
                    try { var r = JSON.parse(xhr.responseText); if (r.error) msg = r.error; } catch (_) { }
                    showNotification('error', 'Update Failed', msg);
                }).always(function () {
                    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fa fa-save"></i><span> Save</span>'; }
                });
            }

        } catch (error) {
            console.error('❌ Error in updateVariantSave:', error);
            showNotification('error', 'Error', error.message || 'Failed to process images');
            if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fa fa-save"></i><span> Save</span>'; }
        }
    };

    // ✅ ADD THIS AFTER LINE 4520 (after updateVariantSave function)

    // Enhanced File Manager for Update Variant Modal
    class UpdateVariantFileManager {
        constructor() {
            this.files = [];
            this.previewContainer = document.getElementById('updVariantImagesPreview');
        }

        addFiles(fileList) {
            this.files = [];
            for (let i = 0; i < fileList.length; i++) {
                this.files.push(fileList[i]);
            }
            this.displayPreviews();
        }

        removeFile(index) {
            this.files.splice(index, 1);
            this.displayPreviews();
        }

        displayPreviews() {
            if (!this.previewContainer) return;
            this.previewContainer.innerHTML = '';

            this.files.forEach((file, index) => {
                const previewDiv = document.createElement('div');
                previewDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                const img = document.createElement('img');
                img.src = URL.createObjectURL(file);
                img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px; border:2px solid #4CAF50;';

                const removeBtn = document.createElement('button');
                removeBtn.type = 'button';
                removeBtn.innerHTML = '×';
                removeBtn.style.cssText = 'position:absolute; top:-8px; right:-8px; background:#dc3545; color:white; border:none; border-radius:50%; width:24px; height:24px; cursor:pointer; font-size:16px; line-height:1;';
                removeBtn.onclick = () => this.removeFile(index);

                previewDiv.appendChild(img);
                previewDiv.appendChild(removeBtn);
                this.previewContainer.appendChild(previewDiv);
            });
        }

        getFiles() {
            return this.files;
        }

        clear() {
            this.files = [];
            if (this.previewContainer) this.previewContainer.innerHTML = '';
        }
    }

    // Initialize file manager
    const updateVariantFileManager = new UpdateVariantFileManager();

    // ✅ REPLACE the existing file input handler around line 3800
    document.getElementById('updVariantImagesFiles').addEventListener('change', function (e) {
        updateVariantFileManager.addFiles(e.target.files);
    });

    // ✅ Image compression helper (if not already present)
    // Robust image compressor that preserves transparency when present or requested.
    // - auto-detects alpha by sampling the drawn image
    // - outputs PNG when alpha must be preserved, otherwise JPEG for smaller size
    // - usage: const out = await compressImage(file, 1920, 0.8, /*preferTransparent*/ false);
    function compressImage(file, maxWidth = 1920, quality = 0.8, preferTransparent = false) {
        return new Promise((resolve, reject) => {
            if (!file || !file.type || !file.type.startsWith('image/')) {
                resolve(file);
                return;
            }

            const reader = new FileReader();
            reader.onload = (e) => {
                const img = new Image();
                img.onload = () => {
                    try {
                        // Resize preserving aspect ratio
                        let width = img.width;
                        let height = img.height;
                        if (width > maxWidth) {
                            height = Math.round(height * (maxWidth / width));
                            width = maxWidth;
                        }

                        // Draw into a temp canvas to detect alpha
                        const testCanvas = document.createElement('canvas');
                        testCanvas.width = width;
                        testCanvas.height = height;
                        const testCtx = testCanvas.getContext('2d', { willReadFrequently: true });
                        // Clear (transparent) intentionally
                        testCtx.clearRect(0, 0, width, height);
                        testCtx.drawImage(img, 0, 0, width, height);

                        // Quick alpha detection: sample pixels at intervals rather than full scan
                        let hasAlpha = false;
                        try {
                            const step = Math.max(1, Math.floor((width * height) / 1000)); // dynamic step
                            const data = testCtx.getImageData(0, 0, width, height).data;
                            for (let i = 3; i < data.length; i += 4 * step) {
                                if (data[i] !== 255) { hasAlpha = true; break; }
                            }
                        } catch (err) {
                            // getImageData can throw if CORS; fallback to type heuristic
                            hasAlpha = false;
                        }

                        const originalType = (file.type || '').toLowerCase();
                        const originalHasAlphaType = originalType === 'image/png' || originalType === 'image/webp' || originalType === 'image/gif';
                        const wantAlpha = preferTransparent === true || hasAlpha || originalHasAlphaType;

                        // Prepare final canvas
                        const canvas = document.createElement('canvas');
                        canvas.width = width;
                        canvas.height = height;
                        const ctx = canvas.getContext('2d');

                        // If we must output JPEG (no alpha), fill a background color to avoid black/transparent flattening.
                        // If you want transparent output, do NOT fill.
                        if (!wantAlpha) {
                            // Use white background; change to '#fff' or configurable color if desired
                            ctx.fillStyle = '#ffffff';
                            ctx.fillRect(0, 0, width, height);
                        } else {
                            // ensure full transparent background (default)
                            ctx.clearRect(0, 0, width, height);
                        }

                        ctx.drawImage(img, 0, 0, width, height);

                        // Choose output type
                        const outputType = wantAlpha ? 'image/png' : 'image/jpeg';
                        const outputQuality = outputType === 'image/jpeg' ? quality : undefined;

                        canvas.toBlob((blob) => {
                            if (!blob) {
                                reject(new Error('Failed to compress image'));
                                return;
                            }
                            // choose sensible extension
                            const ext = outputType === 'image/png' ? '.png' : '.jpg';
                            const name = file.name.replace(/\.\w+$/, ext);
                            resolve(new File([blob], name, { type: outputType, lastModified: Date.now() }));
                        }, outputType, outputQuality);
                    } catch (err) {
                        reject(err);
                    }
                };
                img.onerror = () => reject(new Error('Failed to load image for compression'));
                img.src = e.target.result;
            };
            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsDataURL(file);
        });
    }
})();

// ===== Append: Add Variant (existing product) modal + handler integration =====
    (function () {
        if (!document.getElementById('addVariantActionModal')) {
            var html = '' +
                '<div id="addVariantActionModal" class="modal-overlay"  data-move-to-body="true">' +
                '<div class="modal-container" style="max-width:720px; display:flex; flex-direction:column; max-height:90vh;">' +
                '<div class="modal-header">' +
                '<h2 class="modal-title"><i class="fa fa-layer-group"></i> Add Variant</h2>' +
                '<button class="modal-close" onclick="closeAddVariantActionModal()"><i class="fa fa-times"></i></button>' +
                '</div>' +
                '<div class="modal-body" style="padding:30px; flex:1; overflow-y:auto; max-height:calc(90vh - 180px);">' +
                '<div style="margin-bottom:15px; font-size:13px; color:#666;">Product: <span id="addVariantProductName" style="font-weight:600;"></span></div>' +
                '<div class="form-row">' +
                '<div class="form-group"><label class="form-label">Variant Name *</label><input type="text" id="newVariantName" class="form-control" placeholder="Variant name" /></div>' +
                '<div class="form-group"><label class="form-label">SKU *</label><input type="text" id="newVariantSKU" class="form-control" placeholder="SKU" /></div>' +
                '</div>' +
                '<div class="form-row">' +
                '<div class="form-group"><label class="form-label">Size</label><input type="text" id="newVariantSize" class="form-control" placeholder="Size" /></div>' +
                '<div class="form-group"><label class="form-label">Color</label><input type="text" id="newVariantColor" class="form-control" placeholder="Color" /></div>' +
                '</div>' +
                '<div class="form-row">' +
                '<div class="form-group"><label class="form-label">Price *</label><input type="number" step="0.01" id="newVariantPrice" class="form-control" placeholder="0.00" /></div>' +
                '<div class="form-group"><label class="form-label">Stock *</label><input type="number" id="newVariantStock" class="form-control" placeholder="0" /></div>' +
                '</div>' +
                '<div class="form-row">' +
                '<div class="form-group"><label class="form-label">Minimum Stock</label><input type="number" id="newVariantMinStock" class="form-control" placeholder="1000" value="1000" readonly style="background-color: #f5f5f5; cursor: not-allowed;" /><small style="color:#666;font-size:12px;margin-top:5px;display:block;"><i class="fa fa-info-circle"></i> Minimum stock is set to 1000 by default</small></div>' +
                '<div class="form-group"><label class="form-label">Weight (g)</label><input type="number" step="0.01" id="newVariantWeight" class="form-control" placeholder="0.00" /></div>' +
                '</div>' +
                '<div class="form-row">' +
                '<div class="form-group"><label class="form-label">Dimensions</label><input type="text" id="newVariantDimensions" class="form-control" placeholder="L x W x H" /></div>' +
                '</div>' +
                // ✅ NEW: Multiple file upload for variant images
                '<div class="form-group">' +
                '<label class="form-label">Variant Images (Multiple)</label>' +
                '<input type="file" id="newVariantImages" class="form-control" accept="image/*" multiple />' +
                '<small style="color:#666;font-size:12px;margin-top:5px;display:block;">' +
                '<i class="fa fa-info-circle"></i> Select multiple images (Ctrl+Click or Shift+Click - Max 10 images, 5MB each)' +
                '</small>' +
                '<div id="newVariantImagesPreview" style="margin-top:10px; display:flex; flex-wrap:wrap; gap:10px;"></div>' +
                '</div>' +
                '<div class="form-row">' +
                '<div class="form-group">' +
                '<label class="form-label">Description</label>' +
                '<input type="text" id="newVariantDescription" class="form-control" placeholder="Enter variant description..." />' +
                '</div>' +
                '</div>' +
                '<div class="form-group"><label class="form-label">Lifespan / Best Before (years)</label><input type="number" id="newVariantShelfLifeYears" class="form-control" placeholder="1" /><small style="color:#666;font-size:12px;margin-top:5px;display:block;">How many years the product stays fresh (e.g., 1 for 1 year)</small></div>' +
                '<div class="form-group"><label class="form-label">Storage Location *</label><select id="newVariantLocation" class="form-control"><option value="">Select location...</option></select><small style="color:#666;font-size:11px;margin-top:5px;display:block;"><i class="fa fa-info-circle"></i> Location options are based on the product category</small></div>' +
                '<div id="newVariantMsg" style="display:none; font-size:12px; margin-top:5px;"></div>' +
                '</div>' +
                '<div class="modal-footer" style="flex-shrink:0;">' +
                '<button type="button" class="btn-animated btn-secondary" onclick="closeAddVariantActionModal()"><i class="fa fa-times"></i><span>Cancel</span></button>' +
                '<button type="button" class="btn-animated btn-primary" id="btnSaveNewVariant" onclick="saveNewVariant()"><i class="fa fa-save"></i><span>Save Variant</span></button>' +
                '</div>' +
                '</div>' +
                '</div>';
            document.body.insertAdjacentHTML('beforeend', html);
        }

        // ===== NEW: Add Variant Images Preview Functionality =====
        (function () {
            document.addEventListener('DOMContentLoaded', function () {
                // Wait for modal to be added to DOM
                setTimeout(function () {
                    setupNewVariantImagePreview();
                }, 500);
            });

            // Also setup when modal is shown
            var originalShowVariantModal = window.showVariantModal;
            if (originalShowVariantModal) {
                window.showVariantModal = function (productId, productName) {
                    originalShowVariantModal(productId, productName);
                    setTimeout(setupNewVariantImagePreview, 100);
                };
            }

            function setupNewVariantImagePreview() {
                var fileInput = document.getElementById('newVariantImages');
                var previewContainer = document.getElementById('newVariantImagesPreview');

                if (!fileInput || !previewContainer) {
                    console.log('⚠️ File input or preview container not found yet');
                    return;
                }

                // Remove existing listener to avoid duplicates
                fileInput.removeEventListener('change', handleNewVariantImageChange);
                fileInput.addEventListener('change', handleNewVariantImageChange);

                console.log('✅ New variant image preview setup complete');
            }

            function handleNewVariantImageChange(e) {
                var previewContainer = document.getElementById('newVariantImagesPreview');
                if (!previewContainer) return;

                previewContainer.innerHTML = ''; // Clear previous previews

                var files = Array.from(e.target.files);
                console.log('📷 Selected', files.length, 'image(s) for new variant');

                if (files.length > 10) {
                    showNotification('warning', 'Too Many Files', 'Maximum 10 images allowed');
                    e.target.value = '';
                    return;
                }

                files.forEach(function (file, index) {
                    if (file.type.startsWith('image/')) {
                        // Check file size
                        if (file.size > 5 * 1024 * 1024) {
                            showNotification('warning', 'File Too Large', file.name + ' is larger than 5MB');
                            return;
                        }

                        var reader = new FileReader();
                        reader.onload = function (e) {
                            var previewDiv = document.createElement('div');
                            previewDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                            var img = document.createElement('img');
                            img.src = e.target.result;
                            img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px; border:2px solid #e9ecef;';

                            var removeBtn = document.createElement('button');
                            removeBtn.type = 'button';
                            removeBtn.innerHTML = '×';
                            removeBtn.style.cssText = 'position:absolute; top:-8px; right:-8px; background:#dc3545; color:white; border:none; border-radius:50%; width:24px; height:24px; cursor:pointer; font-size:16px; line-height:1;';
                            removeBtn.onclick = function () {
                                previewDiv.remove();
                                console.log('🗑️ Removed preview for:', file.name);
                            };

                            previewDiv.appendChild(img);
                            previewDiv.appendChild(removeBtn);
                            previewContainer.appendChild(previewDiv);

                            console.log('✅ Preview loaded for:', file.name);
                        };
                        reader.readAsDataURL(file);
                    }
                });
            }
        })();

    function clearAddVariantForm() {
        ['newVariantName', 'newVariantSKU', 'newVariantSize', 'newVariantColor', 'newVariantPrice', 'newVariantStock', 'newVariantWeight', 'newVariantDimensions', 'newVariantImg', 'newVariantShelfLifeYears'].forEach(function (id) {
            var el = document.getElementById(id);
            if (el) {
                el.value = '';
            }
        });
        // Set minimum stock to 1000 (don't clear it)
        var minStockEl = document.getElementById('newVariantMinStock');
        if (minStockEl) minStockEl.value = '1000';

        var msg = document.getElementById('newVariantMsg');
        if (msg) { msg.style.display = 'none'; msg.textContent = ''; }
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

        window.saveNewVariant = function () {
            if (!currentProductId) {
                showNotification('error', 'Missing', 'No product selected.');
                return;
            }

            var btn = document.getElementById('btnSaveNewVariant');

            // Get file input
            var fileInput = document.getElementById('newVariantImages');
            var files = fileInput ? fileInput.files : [];

            // Basic validation
            var variantName = document.getElementById('newVariantName').value.trim();
            var sku = document.getElementById('newVariantSKU').value.trim();
            var price = parseFloat(document.getElementById('newVariantPrice').value) || 0;

            if (!variantName || !sku || price <= 0) {
                showNotification('warning', 'Validation', 'Variant Name, SKU and Price > 0 required');
                return;
            }

            if (btn) {
                btn.disabled = true;
                btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i><span> Uploading & Saving...</span>';
            }

            // Create FormData to handle file uploads
            var formData = new FormData();
            formData.append('ProductId', currentProductId);
            formData.append('VariantName', variantName);
            formData.append('SKU', sku);
            formData.append('Size', document.getElementById('newVariantSize').value.trim());
            formData.append('Color', document.getElementById('newVariantColor').value.trim());
            formData.append('Price', price);
            formData.append('StockQuantity', parseInt(document.getElementById('newVariantStock').value) || 0);
            formData.append('MinimumStock', parseInt(document.getElementById('newVariantMinStock').value) || 1000);
            formData.append('Weight', document.getElementById('newVariantWeight').value || '');
            formData.append('Dimensions', document.getElementById('newVariantDimensions').value.trim());
            formData.append('Description', document.getElementById('newVariantDescription').value.trim());
            formData.append('ShelfLifeYears', document.getElementById('newVariantShelfLifeYears').value || '');
            formData.append('Location', document.getElementById('newVariantLocation').value.trim());

            // Add image files
            if (files && files.length > 0) {
                for (var i = 0; i < files.length; i++) {
                    formData.append('variantImages', files[i]);
                }
                console.log('📎 Attaching', files.length, 'image file(s)');
            }

            $.ajax({
                type: 'POST',
                url: '/Handlers/AddProductVariant.ashx',
                data: formData,
                processData: false,  // Important for FormData
                contentType: false,  // Important for FormData
                success: function (res) {
                    if (res && res.success) {
                        showNotification('success', 'Variant Added', res.message || 'Variant added successfully!', true, 2000);
                        closeAddVariantActionModal();
                        setTimeout(function () {
                            window.location.reload();
                        }, 2200);
                    } else {
                        showNotification('error', 'Add Failed', (res && res.error) || 'Unknown error');
                    }
                },
                error: function (xhr) {
                    var msg = 'Server error';
                    try {
                        var r = JSON.parse(xhr.responseText);
                        if (r.error) msg = r.error;
                    } catch (_) { }
                    showNotification('error', 'Add Failed', msg);
                },
                complete: function () {
                    if (btn) {
                        btn.disabled = false;
                        btn.innerHTML = '<i class="fa fa-save"></i><span>Save Variant</span>';
                    }
                }
            });
        };
       
        

        // ✅ Updated saveNewVariant function with compression
        window.saveNewVariant = async function () {
            if (!currentProductId) {
                showNotification('error', 'Missing', 'No product selected.');
                return;
            }

            var btn = document.getElementById('btnSaveNewVariant');

            // Get file input
            var fileInput = document.getElementById('newVariantImages');
            var files = fileInput ? fileInput.files : [];

            // Basic validation
            var variantName = document.getElementById('newVariantName').value.trim();
            var sku = document.getElementById('newVariantSKU').value.trim();
            var price = parseFloat(document.getElementById('newVariantPrice').value) || 0;
            var location = document.getElementById('newVariantLocation').value.trim();

            if (!variantName || !sku || price <= 0) {
                showNotification('warning', 'Validation', 'Variant Name, SKU and Price > 0 required');
                return;
            }

            if (!location) {
                showNotification('warning', 'Validation', 'Storage Location is required');
                document.getElementById('newVariantLocation').focus();
                return;
            }

            if (btn) {
                btn.disabled = true;
                btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i><span> Compressing & Uploading...</span>';
            }

            try {
                // ✅ Compress images before upload
                var compressedFiles = [];
                if (files && files.length > 0) {
                    showNotification('info', 'Processing', 'Compressing ' + files.length + ' image(s)...', true, 2000);

                    // inside window.saveNewVariant loop that compresses files
                    for (var i = 0; i < files.length; i++) {
                        try {
                            console.log('📷 Compressing:', files[i].name, '(', (files[i].size / 1024 / 1024).toFixed(2), 'MB)');
                            // Ensure we preserve alpha (transparent background) when present
                            const compressed = await compressImage(files[i], 1920, 0.8, true);
                            compressedFiles.push(compressed);
                            console.log('✅ Compressed:', compressed.name, '(', (compressed.size / 1024 / 1024).toFixed(2), 'MB)');
                        } catch (err) {
                            console.error('❌ Compression failed for', files[i].name, err);
                            compressedFiles.push(files[i]); // fallback to original if compression fails
                        }
                    }
                }

                // Create FormData with compressed images
                var formData = new FormData();
                formData.append('ProductId', currentProductId);
                formData.append('VariantName', variantName);
                formData.append('SKU', sku);
                formData.append('Size', document.getElementById('newVariantSize').value.trim());
                formData.append('Color', document.getElementById('newVariantColor').value.trim());
                formData.append('Price', price);
                formData.append('StockQuantity', parseInt(document.getElementById('newVariantStock').value) || 0);
                formData.append('MinimumStock', parseInt(document.getElementById('newVariantMinStock').value) || 1000);
                formData.append('Weight', document.getElementById('newVariantWeight').value || '');
                formData.append('Dimensions', document.getElementById('newVariantDimensions').value.trim());
                formData.append('Description', document.getElementById('newVariantDescription').value.trim());
                formData.append('ShelfLifeYears', document.getElementById('newVariantShelfLifeYears').value || '');
                formData.append('Location', location);

                // ✅ Append compressed image files
                for (var i = 0; i < compressedFiles.length; i++) {
                    formData.append('variantImages', compressedFiles[i]);
                }

                console.log('📤 Uploading', compressedFiles.length, 'compressed image(s)...');

                $.ajax({
                    type: 'POST',
                    url: '/Handlers/AddProductVariant.ashx',
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function (res) {
                        console.log('✅ Upload response:', res);
                        if (res && res.success) {
                            showNotification('success', 'Variant Added',
                                res.message || 'Variant added successfully!', true, 2000);
                            closeAddVariantActionModal();
                            setTimeout(function () {
                                window.location.reload();
                            }, 2200);
                        } else {
                            showNotification('error', 'Add Failed', (res && res.error) || 'Unknown error');
                        }
                    },
                    error: function (xhr) {
                        console.error('❌ Upload failed:', xhr);
                        var msg = 'Server error';
                        try {
                            var r = JSON.parse(xhr.responseText);
                            if (r.error) msg = r.error;
                        } catch (_) {
                            msg = xhr.statusText || 'Server error';
                        }
                        showNotification('error', 'Add Failed', msg);
                    },
                    complete: function () {
                        if (btn) {
                            btn.disabled = false;
                            btn.innerHTML = '<i class="fa fa-save"></i><span>Save Variant</span>';
                        }
                    }
                });

            } catch (error) {
                console.error('❌ Error in saveNewVariant:', error);
                showNotification('error', 'Error', error.message || 'Failed to process images');
                if (btn) {
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fa fa-save"></i><span>Save Variant</span>';
                }
            }
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
                option.textContent = 'Select product category first';
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
        showArchiveConfirmModal(productId);
        return;
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

    function archiveVariant(variantId) {
        if (!variantId) {
            showNotification('error', 'Archive Error', 'Variant ID not found.');
            return;
        }
        if (!confirm('Are you sure you want to archive this variant?')) return;
        $.ajax({
            type: 'POST',
            url: '/Handlers/ArchiveProductVariant.ashx',
            data: JSON.stringify({ variantId: variantId }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (response) {
                var res = response;
                if (typeof res === 'string') {
                    try { res = JSON.parse(res); } catch (e) { }
                }
                if (res.success) {
                    showNotification('success', 'Archived', 'Variant archived successfully!', true, 2000);
                    if (document.getElementById('viewVariantsModal') && document.getElementById('viewVariantsModal').classList.contains('show')) {
                        fetchVariants(currentProductId).then(function () { viewProductVariants(currentProductId, currentProductName); });
                    }
                } else {
                    showNotification('error', 'Archive Failed', res.error || 'Failed to archive variant.');
                }
            },
            error: function (xhr) {
                showNotification('error', 'Archive Failed', 'Server error.');
            }
        });
    }

    // Update the loadArchivedVariants function to include delete button
    function loadArchivedVariants(productId) {
        var tbody = document.getElementById('archivedVariantsTableBody');
        var meta = document.getElementById('archivedVariantsMeta');
        if (!tbody) return;
        tbody.innerHTML = '<tr><td colspan="9" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading archived variants…</td></tr>';
        meta.textContent = 'Loading…';
        $.ajax({
            url: '/Handlers/GetArchivedProductVariants.ashx?productId=' + encodeURIComponent(productId),
            method: 'GET',
            dataType: 'json',
            success: function (res) {
                var list = (res && res.success && Array.isArray(res.variants)) ? res.variants : [];
                if (list.length > 0) {
                    tbody.innerHTML = list.map(function (v, i) {
                        // Calculate status dynamically based on stock levels
                        var status = '';
                        if (v.StockQuantity != null && v.MinimumStock != null) {
                            status = (v.StockQuantity <= v.MinimumStock) ? 'Low' : 'OK';
                        }

                        return '<tr>' +
                            '<td>' + (i + 1) + '</td>' +
                            '<td>' + (v.VariantName || '') + '</td>' +
                            '<td>' + (v.SKU || '') + '</td>' +
                            '<td>' + (v.Price != null ? v.Price : '') + '</td>' +
                            '<td>' + (v.StockQuantity != null ? v.StockQuantity : '') + '</td>' +
                            '<td>' + status + '</td>' +
                            '<td>' + (v.Size || '') + '</td>' +
                            '<td>' + (v.Color || '') + '</td>' +
                            '<td style="display:flex; gap:5px;">' +
                            '<button type="button" class="btn-animated btn-success" style="padding:8px 12px; font-size:12px;" onclick="restoreVariant(\'' + (v.Id || v.id) + '\')"><i class="fa fa-undo"></i> Restore</button>' +
                            '<button type="button" class="btn-animated btn-danger" style="padding:8px 12px; font-size:12px;" onclick="deleteArchivedVariant(\'' + (v.Id || v.id) + '\', \'' + (v.VariantName || '').replace(/'/g, "\\'") + '\')"><i class="fa fa-trash"></i> Delete</button>' +
                            '</td>' +
                            '</tr>';
                    }).join('');
                    document.getElementById('archivedVariantsEmptyState').style.display = 'none';
                } else {
                    tbody.innerHTML = '';
                    document.getElementById('archivedVariantsEmptyState').style.display = '';
                }
                meta.textContent = list.length + ' archived variant(s)';
            },
            error: function () {
                tbody.innerHTML = '<tr><td colspan="9" class="text-center">Failed to load archived variants.</td></tr>';
                meta.textContent = '';
            }
        });
    }

    // Add the deleteArchivedVariant function
    // ✅ UPDATED: Delete archived variant with password field clearing
    function deleteArchivedVariant(variantId, variantName) {
        if (!variantId) {
            showNotification('error', 'Delete Error', 'Variant ID not found.');
            return;
        }

        console.log('🗑️ Delete archived variant:', variantId, variantName);

        // Show confirmation modal
        var modal = document.getElementById('deleteVariantModal');
        if (!modal) {
            console.error('❌ Delete variant modal not found!');
            showNotification('error', 'Modal Error', 'Delete modal not found. Please refresh the page.');
            return;
        }

        // ✅ CLEAR PASSWORD FIELD FIRST
        var passwordField = document.getElementById('txtAdminPasswordVariant');
        if (passwordField) {
            passwordField.value = '';
            console.log('✅ Password field cleared for archived variant deletion');
        }

        // ✅ Update modal message to indicate PERMANENT deletion
        var modalBody = modal.querySelector('.modal-body p');
        if (modalBody) {
            modalBody.innerHTML = '<strong style="color:#dc3545;">⚠️ WARNING: PERMANENT DELETION</strong><br/><br/>' +
                'Are you sure you want to <strong>permanently delete</strong> the variant <strong>"' + variantName + '"</strong>?<br/><br/>' +
                'This will <strong>completely remove it from the database</strong> and <strong>CANNOT BE UNDONE!</strong>';
        }

        // Store the variant ID for deletion
        currentVariantId = variantId;
        currentVariantName = variantName;

        // Show modal
        modal.classList.add('show');
        modal.style.display = 'flex';
        modal.style.visibility = 'visible';
        modal.style.opacity = '1';
        modal.style.zIndex = '9999';
        document.body.style.overflow = 'hidden';

        // ✅ Focus on password field after modal opens
        setTimeout(function () {
            if (passwordField) {
                passwordField.focus();
                console.log('✅ Password field focused');
            }
        }, 400);
    }

    function switchVariantTab(tab, event) {
        document.querySelectorAll('.nav-tab').forEach(btn => btn.classList.remove('active'));
        document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active'));
        if (tab === 'archivedVariants') {
            document.getElementById('archivedVariantsTab').classList.add('active');
            event.target.classList.add('active');
            loadArchivedVariants(currentProductId);
        } else {
            document.getElementById('activeVariantsTab').classList.add('active');
            event.target.classList.add('active');
            // Optionally, reload active variants here if needed
            fetchVariants(currentProductId).then(function(){ viewProductVariants(currentProductId, currentProductName); });
        }
    }

    function restoreVariant(variantId) {
        if (!variantId) return;
        if (!confirm('Restore this variant?')) return;
        $.ajax({
            type: 'POST',
            url: '/Handlers/RestoreProductVariant.ashx',
            data: JSON.stringify({ variantId: variantId }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (res) {
                if (res && res.success) {
                    showNotification('success', 'Restored', 'Variant restored!', true, 2000);
                    loadArchivedVariants(currentProductId);
                    fetchVariants(currentProductId).then(function () { viewProductVariants(currentProductId, currentProductName); });
                } else {
                    showNotification('error', 'Restore Failed', res.error || 'Failed to restore variant.');
                }
            },
            error: function () {
                showNotification('error', 'Restore Failed', 'Server error.');
            }
        });
    }


    

    // 🧪 INGREDIENT AUTOCOMPLETE FUNCTIONALITY WITH QUANTITY
    (function () {
        var selectedIngredients = [];
        var searchTimeout = null;
        var currentSelectedIngredient = null;

        function initIngredientAutocomplete() {
            var searchInput = document.getElementById('txtIngredientSearch');
            var quantityInput = document.getElementById('txtIngredientQuantity');
            var addBtn = document.getElementById('btnAddIngredient');
            var suggestions = document.getElementById('ingredientSuggestions');
            var validationMsg = document.getElementById('ingredientValidationMsg');
            var ingredientList = document.getElementById('ingredientList');
            var container = document.getElementById('ingredientListContainer');
            var countBadge = document.getElementById('ingredientCountBadge');

            if (!searchInput || !addBtn || !quantityInput) {
                console.log('❌ Ingredient form elements not found');
                return;
            }

            console.log('✅ Ingredient autocomplete initialized');

            // Search as user types
            searchInput.addEventListener('input', function () {
                clearTimeout(searchTimeout);
                var query = this.value.trim();

                // Reset selection when user types
                currentSelectedIngredient = null;
                quantityInput.disabled = true;
                quantityInput.value = '';
                addBtn.disabled = true;

                if (query.length < 2) {
                    suggestions.style.display = 'none';
                    validationMsg.textContent = '';
                    return;
                }

                validationMsg.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Searching...';
                validationMsg.style.color = '#666';

                searchTimeout = setTimeout(function () {
                    $.ajax({
                        url: '/Handlers/SearchIngredients.ashx?query=' + encodeURIComponent(query),
                        method: 'GET',
                        dataType: 'json',
                        success: function (res) {
                            console.log('🔍 Search response:', res);

                            if (res && res.success && res.ingredients && res.ingredients.length > 0) {
                                suggestions.innerHTML = res.ingredients.map(function (ing) {
                                    return '<div class="ingredient-suggestion-item" data-id="' + ing.id + '" data-name="' + ing.name + '" data-unit="' + ing.unit + '">' +
                                        '<div style="font-weight: 600;">' + ing.name + '</div>' +
                                        '<div style="font-size: 11px; color: #666;">Unit: ' + ing.unit + ' | Cost: ₱' + (ing.costPerUnit || '0.00') + '</div>' +
                                        '</div>';
                                }).join('');
                                suggestions.style.display = 'block';
                                validationMsg.innerHTML = '<i class="fa fa-check" style="color: #4CAF50;"></i> ' + res.ingredients.length + ' ingredient(s) found';
                                validationMsg.style.color = '#4CAF50';
                            } else {
                                suggestions.style.display = 'none';
                                validationMsg.innerHTML = '<i class="fa fa-times" style="color: #f44336;"></i> Ingredient not found in database';
                                validationMsg.style.color = '#f44336';
                            }
                        },
                        error: function () {
                            suggestions.style.display = 'none';
                            validationMsg.innerHTML = '<i class="fa fa-exclamation-triangle" style="color: #ff9800;"></i> Search failed';
                            validationMsg.style.color = '#ff9800';
                        }
                    });
                }, 300);
            });

            // Select ingredient from suggestions
            suggestions.addEventListener('click', function (e) {
                var item = e.target.closest('.ingredient-suggestion-item');
                if (!item) return;

                var id = item.getAttribute('data-id');
                var name = item.getAttribute('data-name');
                var unit = item.getAttribute('data-unit');

                currentSelectedIngredient = {
                    id: id,
                    name: name,
                    unit: unit
                };

                searchInput.value = name;
                suggestions.style.display = 'none';

                // Enable quantity input
                quantityInput.disabled = false;
                quantityInput.focus();

                validationMsg.innerHTML = '<i class="fa fa-check" style="color: #4CAF50;"></i> ' + name + ' selected. Enter quantity required.';
                validationMsg.style.color = '#4CAF50';

                console.log('✅ Ingredient selected:', currentSelectedIngredient);
            });

            // Enable add button when quantity is entered
            quantityInput.addEventListener('input', function () {
                var quantity = parseFloat(this.value);
                addBtn.disabled = !(currentSelectedIngredient && quantity > 0);
            });

            // Add ingredient with quantity
            addBtn.addEventListener('click', function () {
                if (!currentSelectedIngredient) {
                    showNotification('warning', 'Select Ingredient', 'Please select an ingredient first');
                    return;
                }

                var quantity = parseFloat(quantityInput.value);
                if (!quantity || quantity <= 0) {
                    showNotification('warning', 'Enter Quantity', 'Please enter a valid quantity');
                    quantityInput.focus();
                    return;
                }

                var id = currentSelectedIngredient.id;
                var name = currentSelectedIngredient.name;
                var unit = currentSelectedIngredient.unit;

                // Check if already added
                var existingIndex = selectedIngredients.findIndex(function (ing) {
                    return ing.id === id;
                });

                if (existingIndex !== -1) {
                    // Update quantity if already exists
                    selectedIngredients[existingIndex].quantity = quantity;
                    showNotification('info', 'Updated', name + ' quantity updated to ' + quantity + ' ' + unit, true, 1500);
                } else {
                    // Add new ingredient
                    selectedIngredients.push({
                        id: id,
                        name: name,
                        unit: unit,
                        quantity: quantity
                    });
                    showNotification('success', 'Added', name + ' (' + quantity + ' ' + unit + ') added successfully', true, 1500);
                }

                updateIngredientList();

                // Reset form
                searchInput.value = '';
                quantityInput.value = '';
                quantityInput.disabled = true;
                currentSelectedIngredient = null;
                addBtn.disabled = true;
                validationMsg.textContent = '';

                console.log('✅ Current ingredients:', selectedIngredients);
            });

            // Allow Enter key to add ingredient
            quantityInput.addEventListener('keypress', function (e) {
                if (e.key === 'Enter' && !addBtn.disabled) {
                    e.preventDefault();
                    addBtn.click();
                }
            });

            function updateIngredientList() {
                if (selectedIngredients.length === 0) {
                    container.style.display = 'none';
                    return;
                }

                container.style.display = 'block';
                countBadge.textContent = selectedIngredients.length;

                ingredientList.innerHTML = selectedIngredients.map(function (ing, index) {
                    return '<span class="ingredient-tag">' +
                        '<i class="fa fa-flask" style="color: #667eea;"></i>' +
                        '<span><strong>' + ing.name + '</strong>: ' + ing.quantity + ' ' + ing.unit + '</span>' +
                        '<span class="ingredient-tag-remove" onclick="removeIngredient(' + index + ')" title="Remove">×</span>' +
                        '</span>';
                }).join('');
            }

            // Close suggestions when clicking outside
            document.addEventListener('click', function (e) {
                if (!searchInput.contains(e.target) && !suggestions.contains(e.target)) {
                    suggestions.style.display = 'none';
                }
            });

            window.removeIngredient = function (index) {
                var removed = selectedIngredients.splice(index, 1)[0];
                updateIngredientList();
                showNotification('info', 'Removed', removed.name + ' (' + removed.quantity + ' ' + removed.unit + ') removed', true, 1500);
                console.log('🗑️ Ingredient removed:', removed);
            };

            window.getSelectedIngredients = function () {
                return selectedIngredients;
            };

            window.clearIngredients = function () {
                selectedIngredients = [];
                updateIngredientList();
                searchInput.value = '';
                quantityInput.value = '';
                quantityInput.disabled = true;
                currentSelectedIngredient = null;
                addBtn.disabled = true;
                validationMsg.textContent = '';
                console.log('🧹 Ingredients cleared');
            };
        }

        // Initialize on DOM ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initIngredientAutocomplete);
        } else {
            initIngredientAutocomplete();
        }
    })();



    // Enable filtering inside the View Product Variants modal
    (function setupVariantFilter() {
        var input = document.getElementById('variantFilter');
        if (!input) return;

        var debounce;
        function applyVariantFilter() {
            var q = (input.value || '').trim().toLowerCase();
            var tbody = document.getElementById('variantsTableBody');
            if (!tbody) return;
            var rows = Array.from(tbody.querySelectorAll('tr'));

            rows.forEach(function (r) {
                // skip placeholder rows (loading / empty states)
                if (r.querySelector('td') === null) return;

                var name = (r.children[1] && r.children[1].textContent) ? r.children[1].textContent.toLowerCase() : '';
                var sku = (r.children[2] && r.children[2].textContent) ? r.children[2].textContent.toLowerCase() : '';

                var match = !q || name.indexOf(q) !== -1 || sku.indexOf(q) !== -1;
                r.style.display = match ? '' : 'none';
            });
        }

        input.addEventListener('input', function () {
            clearTimeout(debounce);
            debounce = setTimeout(applyVariantFilter, 200);
        });

        // Reapply filter whenever variants table is updated via refreshVariantActions or viewProductVariants
        var tbody = document.getElementById('variantsTableBody');
        if (tbody && window.MutationObserver) {
            var obs = new MutationObserver(function () {
                applyVariantFilter();
            });
            obs.observe(tbody, { childList: true, subtree: false });
        }
    })();


    function loadProductIngredients(productId) {
        $.ajax({
            type: "POST",
            url: "ProductPage.aspx/GetProductIngredients",
            data: JSON.stringify({ productId: productId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (response) {
                if (response.d && response.d.success) {
                    renderIngredientsList(response.d.ingredients);
                } else {
                    // handle error
                }
            }
        });
    }

    function renderIngredientsList(ingredients) {
        // Clear the container
        $('#ingredients-list').empty();
        ingredients.forEach(function (ing) {
            $('#ingredients-list').append(
                `<div class="ingredient-item">
                <span>${ing.Name || ing.IngredientId}</span>
                <span>${ing.QuantityRequired} ${ing.Unit}</span>
            </div>`
            );
        });
    }



(function () {
    var updateSelectedIngredients = [];
    var updateSearchTimeout = null;
    var updateCurrentSelectedIngredient = null;

    function initUpdateIngredientAutocomplete() {
        var searchInput = document.getElementById('txtUpdateIngredientSearch');
        var quantityInput = document.getElementById('txtUpdateIngredientQuantity');
        var addBtn = document.getElementById('btnUpdateAddIngredient');
        var suggestions = document.getElementById('updateIngredientSuggestions');
        var validationMsg = document.getElementById('updateIngredientValidationMsg');
        var ingredientList = document.getElementById('updateIngredientList');
        var container = document.getElementById('updateIngredientListContainer');
        var countBadge = document.getElementById('updateIngredientCountBadge');
        var hiddenField = document.getElementById('hdnUpdateSelectedIngredients');

        if (!searchInput || !addBtn || !quantityInput) return;

        // Search as user types
        searchInput.addEventListener('input', function () {
            clearTimeout(updateSearchTimeout);
            var query = this.value.trim();

            // Reset selection when user types
            updateCurrentSelectedIngredient = null;
            quantityInput.disabled = true;
            quantityInput.value = '';
            addBtn.disabled = true;

            if (query.length < 2) {
                suggestions.style.display = 'none';
                validationMsg.textContent = '';
                return;
            }

            validationMsg.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Searching...';
            validationMsg.style.color = '#666';

            updateSearchTimeout = setTimeout(function () {
                $.ajax({
                    url: '/Handlers/SearchIngredients.ashx?query=' + encodeURIComponent(query),
                    method: 'GET',
                    dataType: 'json',
                    success: function (res) {
                        if (res && res.success && res.ingredients && res.ingredients.length > 0) {
                            suggestions.innerHTML = res.ingredients.map(function (ing) {
                                return '<div class="ingredient-suggestion-item" data-id="' + ing.id + '" data-name="' + ing.name + '" data-unit="' + ing.unit + '">' +
                                    '<div style="font-weight: 600;">' + ing.name + '</div>' +
                                    '<div style="font-size: 11px; color: #666;">Unit: ' + ing.unit + ' | Cost: ₱' + (ing.costPerUnit || '0.00') + '</div>' +
                                    '</div>';
                            }).join('');
                            suggestions.style.display = 'block';
                            validationMsg.innerHTML = '<i class="fa fa-check" style="color: #4CAF50;"></i> ' + res.ingredients.length + ' ingredient(s) found';
                            validationMsg.style.color = '#4CAF50';
                        } else {
                            suggestions.style.display = 'none';
                            validationMsg.innerHTML = '<i class="fa fa-times" style="color: #f44336;"></i> Ingredient not found in database';
                            validationMsg.style.color = '#f44336';
                        }
                    },
                    error: function () {
                        suggestions.style.display = 'none';
                        validationMsg.innerHTML = '<i class="fa fa-exclamation-triangle" style="color: #ff9800;"></i> Search failed';
                        validationMsg.style.color = '#ff9800';
                    }
                });
            }, 300);
        });

        // Select ingredient from suggestions
        suggestions.addEventListener('click', function (e) {
            var item = e.target.closest('.ingredient-suggestion-item');
            if (!item) return;

            var id = item.getAttribute('data-id');
            var name = item.getAttribute('data-name');
            var unit = item.getAttribute('data-unit');

            updateCurrentSelectedIngredient = { id: id, name: name, unit: unit };

            searchInput.value = name;
            suggestions.style.display = 'none';

            // Enable quantity input
            quantityInput.disabled = false;
            quantityInput.focus();

            validationMsg.innerHTML = '<i class="fa fa-check" style="color: #4CAF50;"></i> ' + name + ' selected. Enter quantity required.';
            validationMsg.style.color = '#4CAF50';
        });

        // Enable add button when quantity is entered
        quantityInput.addEventListener('input', function () {
            var quantity = parseFloat(this.value);
            addBtn.disabled = !(updateCurrentSelectedIngredient && quantity > 0);
        });

        // Add ingredient with quantity
        addBtn.addEventListener('click', function () {
            if (!updateCurrentSelectedIngredient) {
                showNotification('warning', 'Select Ingredient', 'Please select an ingredient first');
                return;
            }
            var quantity = parseFloat(quantityInput.value);
            if (!quantity || quantity <= 0) {
                showNotification('warning', 'Enter Quantity', 'Please enter a valid quantity');
                quantityInput.focus();
                return;
            }
            var id = updateCurrentSelectedIngredient.id;
            var name = updateCurrentSelectedIngredient.name;
            var unit = updateCurrentSelectedIngredient.unit;
            var existingIndex = updateSelectedIngredients.findIndex(function (ing) { return ing.id === id; });
            if (existingIndex !== -1) {
                updateSelectedIngredients[existingIndex].quantity = quantity;
                showNotification('info', 'Updated', name + ' quantity updated to ' + quantity + ' ' + unit, true, 1500);
            } else {
                updateSelectedIngredients.push({ id: id, name: name, unit: unit, quantity: quantity });
                showNotification('success', 'Added', name + ' (' + quantity + ' ' + unit + ') added', true, 1500);
            }
            updateIngredientList();
            searchInput.value = '';
            quantityInput.value = '';
            quantityInput.disabled = true;
            updateCurrentSelectedIngredient = null;
            addBtn.disabled = true;
            validationMsg.textContent = '';
        });

        // Allow Enter key to add ingredient
        quantityInput.addEventListener('keypress', function (e) {
            if (e.key === 'Enter' && !addBtn.disabled) {
                e.preventDefault();
                addBtn.click();
            }
        });

        // Remove ingredient
        window.removeUpdateIngredient = function (index) {
            var removed = updateSelectedIngredients.splice(index, 1)[0];
            updateIngredientList();
            showNotification('info', 'Removed', removed.name + ' removed', true, 1500);
        };

        // Update ingredient list UI
        function updateIngredientList() {
            if (updateSelectedIngredients.length === 0) {
                container.style.display = 'none';
                if (hiddenField) hiddenField.value = '';
                return;
            }
            container.style.display = 'block';
            countBadge.textContent = updateSelectedIngredients.length;
            ingredientList.innerHTML = updateSelectedIngredients.map(function (ing, index) {
                return '<span class="ingredient-tag">' +
                    '<i class="fa fa-flask" style="color: #667eea;"></i>' +
                    '<span><strong>' + ing.name + '</strong>: ' + ing.quantity + ' ' + ing.unit + '</span>' +
                    '<span class="ingredient-tag-remove" onclick="removeUpdateIngredient(' + index + ')" title="Remove">×</span>' +
                    '</span>';
            }).join('');
            if (hiddenField) hiddenField.value = JSON.stringify(updateSelectedIngredients);
        }

        // Expose for modal open
        window.setUpdateIngredients = function (ingredients) {
            updateSelectedIngredients = ingredients || [];
            updateIngredientList();
        };
        window.getUpdateIngredients = function () {
            return updateSelectedIngredients;
        };

        // Close suggestions when clicking outside
        document.addEventListener('click', function (e) {
            if (!searchInput.contains(e.target) && !suggestions.contains(e.target)) {
                suggestions.style.display = 'none';
            }
        });
    }

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initUpdateIngredientAutocomplete);
    } else {
        initUpdateIngredientAutocomplete();
    }

    // On modal open, fetch and set ingredients
    window.loadUpdateProductIngredients = function (productId) {
        $.ajax({
            type: "POST",
            url: "/Handlers/GetProductIngredients.ashx",
            data: JSON.stringify({ productId: productId }),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function (response) {
                if (response.success) {
                    // Map to expected format
                    var ings = (response.ingredients || []).map(function (ing) {
                        return {
                            id: ing.id,
                            name: ing.name,
                            unit: ing.unit,
                            quantity: ing.quantity
                        };
                    });
                    window.setUpdateIngredients(ings);
                }
            }
        });
    };
    })();
    var archiveProductIdToArchive = null;
    function showArchiveConfirmModal(productId) {
        archiveProductIdToArchive = productId;
        var modal = document.getElementById('archiveConfirmModal');
        if (modal) modal.classList.add('show');
    }
    document.getElementById('archiveCancelBtn').onclick = function () {
        var modal = document.getElementById('archiveConfirmModal');
        if (modal) modal.classList.remove('show');
        archiveProductIdToArchive = null;
    };
    document.getElementById('archiveConfirmBtn').onclick = function () {
        var modal = document.getElementById('archiveConfirmModal');
        if (modal) modal.classList.remove('show');
        if (archiveProductIdToArchive) {
            doArchiveProduct(archiveProductIdToArchive);
            archiveProductIdToArchive = null;
        }
    };
    function archiveProduct(productId) {
        if (!productId) {
            showNotification('error', 'Archive Error', 'Product ID not found.');
            return;
        }
        showArchiveConfirmModal(productId);
    }
    function doArchiveProduct(productId) {
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


   
// To get all image URLs when saving:
  
    var variantImageUrlInput = document.getElementById('variantImageUrl');
    if (variantImageUrlInput) {
        variantImageUrlInput.addEventListener('input', function () {
            var url = this.value.trim();
            var preview = document.getElementById('imagePreview');
            if (url && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:'))) {
                preview.innerHTML = '<img src="' + url + '" style="max-width:200px;max-height:150px;border:1px solid #ccc;" />';
            } else {
                preview.innerHTML = '';
            }
        });
    }
    

    function uploadBase64Image(base64String) {
        return $.ajax({
            type: 'POST',
            url: '/Handlers/UploadProductImage.ashx',
            data: JSON.stringify({ imageData: base64String }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json'
        }).then(function (res) {
            // Expect { success: true, imageUrl: '...' }
            if (res && res.success && res.imageUrl) return res.imageUrl;
            throw new Error(res.error || 'Upload failed');
        });
    }

    // ✅ Enhanced Update Product Image Preview with "NEW" Label
    (function () {
        document.addEventListener('DOMContentLoaded', function () {
            setupUpdateProductImagePreview();
        });

        function setupUpdateProductImagePreview() {
            var fileInput = document.getElementById('fuUpdateProductImage');
            var preview = document.getElementById('updateProductImagePreview');
            var previewContainer = preview ? preview.parentElement : null;

            if (!fileInput || !preview || !previewContainer) {
                console.log('⚠️ Update product image elements not found');
                return;
            }

            fileInput.addEventListener('change', function (e) {
                var file = e.target.files[0];

                if (file && file.type.startsWith('image/')) {
                    // Validate file size
                    if (file.size > 5 * 1024 * 1024) {
                        showNotification('warning', 'File Too Large', 'Image must be less than 5MB');
                        this.value = '';
                        return;
                    }

                    // Show preview with "NEW" indicator
                    var reader = new FileReader();
                    reader.onload = function (e) {
                        preview.src = e.target.result;
                        preview.style.border = '3px solid #4CAF50';

                        // Add "NEW UPLOAD" label
                        previewContainer.setAttribute('data-new-upload', 'true');

                        // Add temporary label (remove existing first)
                        var existingLabel = previewContainer.querySelector('.new-upload-label');
                        if (existingLabel) existingLabel.remove();

                        var label = document.createElement('div');
                        label.className = 'new-upload-label';
                        label.textContent = 'NEW UPLOAD';
                        label.style.cssText = 'position:absolute; top:10px; right:10px; background:#4CAF50; color:white; padding:6px 12px; border-radius:4px; font-size:11px; font-weight:bold; box-shadow:0 2px 8px rgba(0,0,0,0.3); animation:fadeIn 0.3s ease;';
                        previewContainer.appendChild(label);

                        console.log('✅ New image preview loaded:', file.name);
                    };
                    reader.readAsDataURL(file);
                } else {
                    showNotification('warning', 'Invalid File', 'Please select a valid image file');
                    this.value = '';
                }
            });

            console.log('✅ Update product image preview initialized');
        }
    })();
    (function () {
        document.addEventListener('DOMContentLoaded', function () {
            console.log('🎯 ProductPage JavaScript loaded successfully!');

            // ✅ Product Image File Upload Preview (Add Product Modal)
            var fuProductImage = document.getElementById('<%= fuProductImage.ClientID %>');
           var productImagePreview = document.getElementById('productImagePreview');

           if (fuProductImage) {
               fuProductImage.addEventListener('change', function (e) {
                   var file = e.target.files[0];
                   if (file && file.type.startsWith('image/')) {
                       if (file.size > 5 * 1024 * 1024) {
                           showNotification('warning', 'File Too Large', 'Image must be less than 5MB');
                           this.value = '';
                           return;
                       }

                       var reader = new FileReader();
                       reader.onload = function (e) {
                           productImagePreview.src = e.target.result;
                           console.log('✅ Product image preview loaded');
                       };
                       reader.readAsDataURL(file);
                   } else {
                       showNotification('warning', 'Invalid File', 'Please select a valid image file');
                       this.value = '';
                   }
               });
           }

           // ✅ Update Product Image URL Preview (Update Product Modal)
           var updateImgUrlTb = document.getElementById('txtUpdateProductImageUrl');
           if (updateImgUrlTb) {
               updateImgUrlTb.addEventListener('input', updateUpdateProductImagePreview);
           }
    });
})();




// ===== Variant Images Upload Preview (Multiple) =====
(function() {
    document.addEventListener('DOMContentLoaded', function() {
        var fuVariantImages = document.getElementById('<%= fuVariantImages.ClientID %>');
        var previewContainer = document.getElementById('variantImagesPreview');

        if (fuVariantImages && previewContainer) {
            fuVariantImages.addEventListener('change', function (e) {
                previewContainer.innerHTML = ''; // Clear previous previews

                var files = Array.from(e.target.files);
                console.log('📷 Selected', files.length, 'image(s)');

                if (files.length > 10) {
                    showNotification('warning', 'Too Many Files', 'Maximum 10 images allowed');
                    this.value = '';
                    return;
                }

                files.forEach(function (file, index) {
                    if (file.type.startsWith('image/')) {
                        // Check file size
                        if (file.size > 5 * 1024 * 1024) {
                            showNotification('warning', 'File Too Large', file.name + ' is larger than 5MB');
                            return;
                        }

                        var reader = new FileReader();
                        reader.onload = function (e) {
                            var previewDiv = document.createElement('div');
                            previewDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                            var img = document.createElement('img');
                            img.src = e.target.result;
                            img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px; border:2px solid #e9ecef;';

                            var removeBtn = document.createElement('button');
                            removeBtn.type = 'button';
                            removeBtn.innerHTML = '×';
                            removeBtn.style.cssText = 'position:absolute; top:-8px; right:-8px; background:#dc3545; color:white; border:none; border-radius:50%; width:24px; height:24px; cursor:pointer; font-size:16px; line-height:1;';
                            removeBtn.onclick = function () {
                                previewDiv.remove();
                                // Note: Cannot actually remove from FileList, but visual feedback is important
                                console.log('🗑️ Removed preview for:', file.name);
                            };

                            previewDiv.appendChild(img);
                            previewDiv.appendChild(removeBtn);
                            previewContainer.appendChild(previewDiv);

                            console.log('✅ Preview loaded for:', file.name);
                        };
                        reader.readAsDataURL(file);
                    }
                });
            });
        }
    });
    })();

    // ✅ Enhanced File Manager (Add this to your existing JavaScript)
    class UpdateVariantFileManager {
        constructor() {
            this.files = [];
            this.previewContainer = document.getElementById('updVariantImagesPreview');
        }

        addFiles(fileList) {
            this.files = [];
            for (let i = 0; i < fileList.length; i++) {
                this.files.push(fileList[i]);
            }
            this.displayPreviews();
        }

        removeFile(index) {
            this.files.splice(index, 1);
            this.displayPreviews();
        }

        displayPreviews() {
            if (!this.previewContainer) return;
            this.previewContainer.innerHTML = '';

            this.files.forEach((file, index) => {
                const previewDiv = document.createElement('div');
                previewDiv.style.cssText = 'position:relative; width:100px; height:100px;';

                const img = document.createElement('img');
                img.src = URL.createObjectURL(file);
                img.style.cssText = 'width:100%; height:100%; object-fit:cover; border-radius:8px;';

                const removeBtn = document.createElement('button');
                removeBtn.type = 'button';
                removeBtn.innerHTML = '×';
                removeBtn.style.cssText = 'position:absolute; top:-8px; right:-8px; background:#dc3545; color:white; border:none; border-radius:50%; width:24px; height:24px; cursor:pointer;';
                removeBtn.onclick = () => this.removeFile(index);

                previewDiv.appendChild(img);
                previewDiv.appendChild(removeBtn);
                this.previewContainer.appendChild(previewDiv);
            });
        }

        getFiles() {
            return this.files;
        }
    }

    // Initialize
    const updateVariantFileManager = new UpdateVariantFileManager();

    // Connect to file input
    document.getElementById('updVariantImagesFiles').addEventListener('change', function (e) {
        updateVariantFileManager.addFiles(e.target.files);
    });



</script>
    </asp:Content>