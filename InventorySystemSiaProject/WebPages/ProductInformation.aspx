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

    <!-- Categories Section (static placeholder, can be made dynamic later) -->
    <div class="categories-container">
        <div class="category-item">
            <img src="../Content/images/serum-icon.png" alt="Serum" class="category-icon" />
            <span class="category-label">SERUM</span>
        </div>
        <div class="category-item">
            <img src="../Content/images/cleanser-icon.png" alt="Cleanser" class="category-icon" />
            <span class="category-label">CLEANSER</span>
        </div>
        <div class="category-item">
            <img src="../Content/images/cream-icon.png" alt="Cream" class="category-icon" />
            <span class="category-label">CREAM</span>
        </div>
    </div>

    <!-- Best Selling Products Section -->
    <div class="best-selling-container">
        <h2 class="section-title">BEST SELLING PRODUCTS</h2>
        <asp:Panel ID="pnlNoProducts" runat="server" Visible="false" CssClass="no-products">No active products found.</asp:Panel>
        <div class="product-grid">
            <asp:Repeater ID="rptBestSelling" runat="server">
                <ItemTemplate>
                    <div class="product-card">
                        <img src="<%# Eval("ProductImg") %>" alt="<%# Eval("ProductName") %>" class="product-image" />
                        <div class="product-info">
                            <span class="product-name"><%# Eval("ProductName") %></span>
                            <span class="product-price"><%# Eval("PriceDisplay") %></span>
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
        </div>
    </div>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
