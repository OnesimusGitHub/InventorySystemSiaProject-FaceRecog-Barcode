<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ArchivedProducts.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ArchivedProducts" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Archived Products
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/ProductPage.css" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        body {
            background: #f7f7f7;
            font-family: 'Segoe UI', Arial, sans-serif;
        }
        .main-container {
            max-width: 1200px;
            margin: 32px auto;
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 2px 16px rgba(0,0,0,0.06);
            padding: 32px 32px 24px 32px;
        }
        .page-title {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 4px;
            color: #222;
        }
        .page-subtitle {
            color: #888;
            font-size: 1rem;
            margin-bottom: 24px;
        }
        .archived-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            background: #fff;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 1px 4px rgba(0,0,0,0.04);
        }
        .archived-table th, .archived-table td {
            padding: 14px 12px;
            border-bottom: 1px solid #f0f0f0;
            text-align: left;
        }
        .archived-table th {
            background: #fafbfc;
            font-weight: 600;
            color: #444;
            font-size: 15px;
            border: none;
        }
        .archived-table tr:last-child td {
            border-bottom: none;
        }
        .archived-table tr:hover {
            background: #f6f6f9;
        }
        .thumb {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            object-fit: cover;
            box-shadow: 0 1px 4px rgba(0,0,0,0.08);
            background: #f5f5f5;
        }
        .empty-state {
            text-align: center;
            padding: 60px 0;
            color: #bbb;
        }
        .empty-state-icon {
            font-size: 48px;
            margin-bottom: 12px;
            color: #e0e0e0;
        }
        .search-bar {
            margin-bottom: 18px;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .search-input {
            flex: 1;
            padding: 10px 16px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            font-size: 15px;
            background: #fafbfc;
        }
        .category-filter {
            padding: 10px 16px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            font-size: 15px;
            background: #fafbfc;
            margin-left: 8px;
        }
        .restore-btn {
            background: #28a745;
            color: #fff;
            border: none;
            border-radius: 6px;
            padding: 7px 18px;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.2s;
        }
        .restore-btn:hover {
            background: #218838;
        }
    </style>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="main-container">
        <div class="page-title">Archived Products</div>
        <div class="page-subtitle">View all products that are currently inactive in your inventory.</div>
        <div class="search-bar">
            <input type="text" id="searchInput" class="search-input" placeholder="Search archived products..." />
            <select id="categoryFilter" class="category-filter">
                <option value="">All Categories</option>
                <option value="Skincare">Skincare</option>
                <option value="Makeup">Makeup</option>
                <option value="Haircare">Haircare</option>
                <option value="Fragrance">Fragrance</option>
                <option value="Body Care">Body Care</option>
            </select>
        </div>
        <div id="archivedProductsContainer">
            <table class="archived-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Image</th>
                        <th>Product</th>
                        <th>Category</th>
                        <th>Supplier</th>
                        <th>Price</th>
                        <th>Stock</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody id="archivedProductsBody">
                    <tr><td colspan="8" class="empty-state"><span class="empty-state-icon">&#128230;</span><br>Loading archived products...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
    <script type="text/javascript">
    $(document).ready(function () {
        function renderRows(products) {
            if (!products || products.length === 0) {
                return '<tr><td colspan="8" class="empty-state"><span class="empty-state-icon">&#128230;</span><br>No archived products found.<br><span style="font-size:13px; color:#bbb;">Please add products to your inventory using the Add Product button above.</span></td></tr>';
            }
            return products.map(function (p, i) {
                return '<tr>' +
                    '<td>' + (i + 1) + '</td>' +
                    '<td><img src="' + (p.ProductImg || p.productImg || '') + '" class="thumb" /></td>' +
                    '<td>' + (p.ProductName || p.productName || '') + '</td>' +
                    '<td>' + (p.ProductCategory || p.productCategory || '') + '</td>' +
                    '<td>' + (p.SupplierName || p.supplierName || '') + '</td>' +
                    '<td>' + (p.ProductVal != null ? ('₱' + parseFloat(p.ProductVal).toFixed(2)) : (p.productVal != null ? ('₱' + parseFloat(p.productVal).toFixed(2)) : '-')) + '</td>' +
                    '<td>' + (p.StockCount != null ? p.StockCount : '-') + '</td>' +
                    '<td><button class="restore-btn" data-id="' + (p.ProductId || p.productId || '') + '">Set Active</button></td>' +
                    '</tr>';
            }).join('');
        }

        function loadArchivedProducts() {
            var tbody = $('#archivedProductsBody');
            tbody.html('<tr><td colspan="8" class="empty-state"><span class="empty-state-icon">&#128230;</span><br>Loading archived products...</td></tr>');
            $.ajax({
                url: '/Handlers/GetArchivedProducts.ashx',
                method: 'GET',
                dataType: 'json',
                success: function (res) {
                    var products = res.products;
                    if (typeof products === 'string') {
                        products = JSON.parse(products);
                    }
                    if (res && res.success && Array.isArray(products) && products.length > 0) {
                        var archived = products.filter(function (p) {
                            var status = (p.Status || p.status || '').toLowerCase().trim();
                            return status === 'inactive';
                        });
                        // Filter by search
                        var search = $('#searchInput').val().toLowerCase();
                        if (search) {
                            archived = archived.filter(function (p) {
                                return (p.ProductName || '').toLowerCase().includes(search) ||
                                       (p.ProductCategory || '').toLowerCase().includes(search) ||
                                       (p.SupplierName || '').toLowerCase().includes(search);
                            });
                        }
                        // Filter by category
                        var selectedCategory = $('#categoryFilter').val();
                        if (selectedCategory) {
                            archived = archived.filter(function (p) {
                                return (p.ProductCategory || '').toLowerCase() === selectedCategory.toLowerCase();
                            });
                        }
                        tbody.html(renderRows(archived));
                    } else {
                        tbody.html(renderRows([]));
                    }
                },
                error: function () {
                    $('#archivedProductsBody').html('<tr><td colspan="8" class="empty-state"><span class="empty-state-icon">&#9888;</span><br>Failed to load archived products.</td></tr>');
                }
            });
        }

        // Search filter
        $('#searchInput').on('input', function () {
            loadArchivedProducts();
        });

        // Category filter
        $('#categoryFilter').on('change', function () {
            loadArchivedProducts();
        });

        $(document).on('click', '.restore-btn', function () {
            var productId = $(this).data('id');
            if (!productId) return;
            if (!confirm('Are you sure you want to set this product to Active?')) return;
            $.ajax({
                url: '/Handlers/ArchiveProduct.ashx',
                method: 'POST',
                data: { productId: productId, status: 'Active' },
                success: function (res) {
                    if (typeof res === 'string') res = JSON.parse(res);
                    if (res.success) {
                        alert('Product set to Active!');
                        loadArchivedProducts();
                    } else {
                        alert('Failed to set product to Active: ' + (res.error || 'Unknown error'));
                    }
                },
                error: function () {
                    alert('Failed to set product to Active.');
                }
            });
        });

        loadArchivedProducts();
    });
    </script>
</asp:Content>
