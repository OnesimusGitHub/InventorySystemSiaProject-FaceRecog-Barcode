<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ProductInformation.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductInformation" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Product Information - 
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/productinformation.css" rel="stylesheet" />
    <style>
        /* Search and Filter Bar Styling */
        .product-filter-bar {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            align-items: center;
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(33, 150, 243, 0.07);
            padding: 1.2rem 2rem;
            margin: 1.5rem 0 2.5rem 0;
        }
        .product-filter-group {
            display: flex;
            flex-direction: column;
            gap: 0.3rem;
            min-width: 180px;
        }
        .product-filter-label {
            font-size: 1rem;
            font-weight: 500;
            color: #333;
        }
        .product-filter-input, .product-filter-select {
            padding: 0.6rem 1rem;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1rem;
            background: #fafbfc;
            color: #333;
            transition: border-color 0.2s, box-shadow 0.2s;
            box-shadow: 0 1px 4px rgba(33, 150, 243, 0.04);
        }
        .product-filter-input:focus, .product-filter-select:focus {
            outline: none;
            border-color: #FF6B35;
            box-shadow: 0 0 0 2px rgba(255, 107, 53, 0.15);
        }
        @media (max-width: 700px) {
            .product-filter-bar {
                flex-direction: column;
                gap: 1rem;
                padding: 1rem;
            }
            .product-filter-group {
                min-width: 0;
            }
        }

        /* New Styles for Category Counts Section */
        .categories-container {
            display: flex;
            justify-content: center;
            gap: 2rem;
            margin-bottom: 2rem;
        }
        .category-count-rect {
            background: #f5f7fa;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(33,150,243,0.08);
            padding: 1.2rem 2.5rem;
            text-align: center;
            min-width: 120px;
            display: flex;
            flex-direction: column;
            align-items: center;
            border: 2px solid #e0e0e0;
        }
        .category-label {
            font-size: 1.1rem;
            font-weight: bold;
            color: #FF6B35;
            margin-bottom: 0.5rem;
        }
        .category-count {
            font-size: 1.5rem;
            font-weight: 600;
            color: #2196F3;
            background: #fff;
            border-radius: 6px;
            padding: 0.3rem 1.2rem;
            margin-top: 0.2rem;
            box-shadow: 0 1px 4px rgba(33,150,243,0.07);
        }

        /* Categories Stats Cards Styles */
        .categories-stats-container {
            display: flex;
            justify-content: center;
            gap: 2rem;
            margin-bottom: 2rem;
            margin-top: 1.5rem;
        }
        .category-stat-card {
            background: #f9f9fb;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(33,150,243,0.07);
            padding: 1.5rem 2.5rem 2rem 2.5rem;
            text-align: center;
            min-width: 180px;
            display: flex;
            flex-direction: column;
            align-items: center;
            border: 2px solid #e0e0e0;
            transition: box-shadow 0.2s;
        }
        .category-stat-card:hover {
            box-shadow: 0 4px 24px rgba(33,150,243,0.13);
        }
        .category-stat-icon img {
            width: 40px;
            height: 40px;
            margin-bottom: 0.7rem;
        }
        .category-stat-label {
            font-size: 1.2rem;
            font-weight: bold;
            color: #FF6B35;
            margin-bottom: 0.7rem;
            letter-spacing: 1px;
        }
        .category-stat-count-rect {
            background: #fff;
            border-radius: 8px;
            padding: 0.5rem 1.5rem;
            display: flex;
            align-items: baseline;
            justify-content: center;
            box-shadow: 0 1px 4px rgba(33,150,243,0.07);
        }
        .category-stat-count {
            font-size: 2rem;
            font-weight: 700;
            color: #2196F3;
            margin-right: 0.4rem;
        }
        .category-stat-products {
            font-size: 1.1rem;
            color: #2196F3;
            font-weight: 400;
        }
    </style>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <div>
            <div class="date-info">Product Management</div>
            <h1 class="dashboard-title">Product Information</h1>
        </div>
    </div>

    <!-- Search and Category Filter Bar -->
    <div class="product-filter-bar">
        <div class="product-filter-group">
            <label for="productSearch" class="product-filter-label">Search</label>
            <input type="text" id="productSearch" class="product-filter-input" placeholder="Search products..." onkeyup="filterProducts()" />
        </div>
        <div class="product-filter-group">
            <label for="categoryDropdown" class="product-filter-label">Category</label>
            <select id="categoryDropdown" class="product-filter-select" onchange="filterProducts()">
                <option value="">All Categories</option>
                <option value="Skincare">Skincare</option>
                <option value="Makeup">Makeup</option>
                <option value="Haircare">Haircare</option>
                <option value="Fragrance">Fragrance</option>
                <option value="Bodycare">Bodycare</option>
            </select>
        </div>
    </div>

    <!-- Categories Section: Stat Cards with Icons and Counts -->
    <div class="categories-stats-container">
        <% 
            var categoryIcons = new Dictionary<string, string> {
                { "Skincare", "/Content/images/serum-icon.png" },
                { "Makeup", "/Content/images/makeup-icon.png" },
                { "Haircare", "/Content/images/haircare-icon.png" },
                { "Fragrance", "/Content/images/fragrance-icon.png" },
                { "Bodycare", "/Content/images/bodycare-icon.png" }
            };
            var categories = new[] { "Skincare", "Makeup", "Haircare", "Fragrance", "Bodycare" };
            foreach (var cat in categories) {
                int count = CategoryCounts.ContainsKey(cat) ? CategoryCounts[cat] : 0;
                string icon = categoryIcons.ContainsKey(cat) ? categoryIcons[cat] : "";
        %>
        <div class="category-stat-card">
            <div class="category-stat-icon">
                <% if (!string.IsNullOrEmpty(icon)) { %>
                    <img src="<%= icon %>" alt="<%= cat %>" />
                <% } %>
            </div>
            <div class="category-stat-label"><%= cat.ToUpper() %></div>
            <div class="category-stat-count-rect">
                <span class="category-stat-count"><%= count %></span>
                <span class="category-stat-products">products</span>
            </div>
        </div>
        <% } %>
    </div>

    <div class="best-selling-container">
        <h2 class="section-title">BEST SELLING PRODUCTS</h2>
        <asp:Panel ID="pnlNoProducts" runat="server" Visible="false" CssClass="no-products">No active products found.</asp:Panel>

        <div class="product-grid" runat="server" id="productGridWrapper">
            <asp:PlaceHolder ID="phProducts" runat="server" />
        </div>
    </div>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script>
function filterProducts() {
    var search = document.getElementById('productSearch').value;
    var category = document.getElementById('categoryDropdown').value;
    var grid = document.getElementById('<%= productGridWrapper.ClientID %>');
    var noProductsPanel = document.getElementById('<%= pnlNoProducts.ClientID %>');

    var url = '/Handlers/GetFilteredProducts.ashx?category=' + encodeURIComponent(category) + '&search=' + encodeURIComponent(search);

    grid.innerHTML = "<div style='padding:2em;text-align:center;'>Loading...</div>";

    var xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            grid.innerHTML = xhr.responseText;
            if (xhr.responseText.trim() === "") {
                if (noProductsPanel) noProductsPanel.style.display = '';
            } else {
                if (noProductsPanel) noProductsPanel.style.display = 'none';
            }
        }
    };
    xhr.send();
}

window.onload = function() {
    filterProducts();
};
</script>
</asp:Content>
