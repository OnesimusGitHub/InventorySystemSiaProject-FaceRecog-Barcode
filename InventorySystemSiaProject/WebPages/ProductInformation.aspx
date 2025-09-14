<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ProductInformation.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ProductInformation" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">

    Product Information - 
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
        <link href="../Content/productinformation.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <div>
            <div class="date-info">Product Management</div>
            <h1 class="dashboard-title">Product Information</h1>
        </div>
    </div>

    <!-- Search and Filter Section -->
    <div class="search-filter-container">
        <input type="text" class="search-box" placeholder="Search products, SKU, or category..." />
        <select class="filter-dropdown">
            <option>Best Seller</option>
            <option>Newest</option>
            <option>Price: Low to High</option>
            <option>Price: High to Low</option>
        </select>
        <select class="filter-dropdown">
            <option>Filter: All</option>
            <option>Low Stock</option>
            <option>Out of Stock</option>
        </select>
    </div>

    <!-- Product Table Section -->
    <div class="product-table-container">
        <div class="table-summary">
            <span>Total Products: 11</span>
            <span>Low Stock: <span class="low-stock">11</span></span>
            <span>Categories: 3</span>
        </div>
        <table class="product-table">
            <thead>
                <tr>
                    <th><input type="checkbox" /></th>
                    <th>ID</th>
                    <th>Product</th>
                    <th>Supplier</th>
                    <th>Price</th>
                    <th>Stock</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><input type="checkbox" /></td>
                    <td>17410</td>
                    <td>
                        <img src="../Content/images/sample-generic.png" alt="Product Image" class="product-image" />
                        Hydrating Serum (2 variants)
                    </td>
                    <td>Test Supplier Inc.</td>
                    <td>₱29.99 - ₱45.99</td>
                    <td class="low-stock">0</td>
                    <td>
                        <button class="action-button view">👁️</button>
                        <button class="action-button edit">✏️</button>
                        <button class="action-button delete">🗑️</button>
                    </td>
                </tr>
                <!-- Additional rows can be added here -->
            </tbody>
        </table>
    </div>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
