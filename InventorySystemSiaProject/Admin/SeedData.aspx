<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SeedData.aspx.cs" Inherits="InventorySystemSiaProject.Admin.SeedData" Async="true" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Seed Beauty Products Data</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            color: #333;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            background-color: #fafafa;
        }
        .section h3 {
            color: #a64d79;
            margin-bottom: 15px;
        }
        .btn {
            background-color: #007bff;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px 5px;
        }
        .btn:hover {
            background-color: #0056b3;
        }
        .btn-success {
            background-color: #28a745;
        }
        .btn-success:hover {
            background-color: #1e7e34;
        }
        .btn-warning {
            background-color: #ffc107;
            color: #212529;
        }
        .btn-warning:hover {
            background-color: #e0a800;
        }
        .btn-info {
            background-color: #17a2b8;
        }
        .btn-info:hover {
            background-color: #138496;
        }
        .btn-danger {
            background-color: #dc3545;
            color: white;
        }
        .btn-danger:hover {
            background-color: #c82333;
        }
        .message {
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        .description {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .product-list {
            columns: 2;
            column-gap: 20px;
        }
        .product-item {
            break-inside: avoid;
            margin-bottom: 10px;
        }
        .sales-info {
            background-color: #e8f5e8;
            padding: 15px;
            border-radius: 4px;
            border-left: 4px solid #28a745;
        }
        .btn-group {
            display: flex;
            gap: 10px;
            justify-content: center;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <div class="header">
                <h1>?? Beauty Products & Sales Data Seeding</h1>
                <p>Initialize your inventory with premium beauty products and sample sales data</p>
            </div>

            <asp:Panel ID="pnlMessage" runat="server" Visible="false">
                <asp:Label ID="lblMessage" runat="server"></asp:Label>
            </asp:Panel>

            <!-- Products Section -->
            <div class="section">
                <h3>?? Products & Inventory</h3>
                <div class="description">
                    <h4>What will be created:</h4>
                    <div class="product-list">
                        <div class="product-item">? <strong>Hydrating Serum</strong> - Intensive hydration with hyaluronic acid</div>
                        <div class="product-item">?? <strong>Vitamin C Brightening Cream</strong> - Even skin tone and reduce dark spots</div>
                        <div class="product-item">?? <strong>Anti-Aging Night Serum</strong> - Retinol and peptides for skin renewal</div>
                        <div class="product-item">?? <strong>Acne Treatment Gel</strong> - Salicylic acid for clear skin</div>
                        <div class="product-item">?? <strong>Exfoliating Toner</strong> - Glycolic acid for smooth skin</div>
                        <div class="product-item">?? <strong>Luxe Face Mask Set</strong> - Premium cleansing collection</div>
                        <div class="product-item">?? <strong>Matte Lipstick Collection</strong> - 3 stunning shades</div>
                        <div class="product-item">?? <strong>Eyeshadow Palette</strong> - 18 sunset-inspired shades</div>
                    </div>
                    <br />
                    <p><strong>Includes:</strong> 8 Products, 11 Product Variants, 8 Premium Ingredients, and Product-Ingredient relationships</p>
                </div>
                <div class="btn-group">
                    <asp:Button ID="btnSeedProducts" runat="server" Text="?? Seed Beauty Products" 
                        CssClass="btn btn-success" OnClick="btnSeedProducts_Click" />
                </div>
            </div>

            <!-- Sales Section -->
            <div class="section">
                <h3>?? Sales Transactions</h3>
                <div class="sales-info">
                    <h4>Comprehensive Sales Data:</h4>
                    <p>?? <strong>Daily Sales:</strong> 2-4 transactions per day for the last 30 days</p>
                    <p>?? <strong>Weekly Sales:</strong> 8-14 transactions per week for the last 12 weeks</p>
                    <p>?? <strong>Monthly Sales:</strong> 25-45 transactions per month for the last 12 months</p>
                    <p>?? <strong>Last Year Data:</strong> Complete year-over-year comparison data</p>
                    <p>?? <strong>Seasonal Variations:</strong> Holiday seasons show higher sales volumes</p>
                    <p>?? <strong>Realistic Pricing:</strong> Historical price variations and trends</p>
                    <p>?? <strong>Automatic Stock Updates:</strong> All sales automatically decrement inventory</p>
                </div>
                <div class="btn-group">
                    <asp:Button ID="btnSeedSales" runat="server" Text="?? Seed Sales Data" 
                        CssClass="btn btn-info" OnClick="btnSeedSales_Click" />
                    <asp:Button ID="btnSeedSampleSales" runat="server" Text="?? Seed Sample Sales" 
                        CssClass="btn btn-info" OnClick="btnSeedSampleSales_Click" />
                    <asp:Button ID="btnDeleteAllSales" runat="server" Text="??? Delete All Sales" 
                        CssClass="btn btn-danger" OnClick="btnDeleteAllSales_Click" 
                        OnClientClick="return confirm('Are you sure you want to delete ALL sales data? This action cannot be undone!');" />
                </div>
            </div>

            <!-- All Data Section -->
            <div class="section">
                <h3>?? Complete Setup</h3>
                <div class="description">
                    <p><strong>One-click comprehensive setup:</strong> Seeds both products and complete sales data across all time periods.</p>
                    <p><strong>Perfect for dashboard analytics:</strong> Provides data for daily, weekly, monthly, and yearly views with realistic seasonal patterns.</p>
                    <p><strong>Ready for production demo:</strong> Your beauty product inventory system will have authentic-looking data!</p>
                </div>
                <div class="btn-group">
                    <asp:Button ID="btnSeedAllData" runat="server" Text="?? Seed Everything" 
                        CssClass="btn btn-warning" OnClick="btnSeedAllData_Click" />
                </div>
            </div>

            <!-- View Data Section -->
            <div class="section">
                <h3>??? View Current Data</h3>
                <div class="btn-group">
                    <asp:Button ID="btnViewProducts" runat="server" Text="?? View Products" 
                        CssClass="btn" OnClick="btnViewProducts_Click" />
                    
                    <asp:Button ID="btnViewSales" runat="server" Text="?? View Sales" 
                        CssClass="btn" OnClick="btnViewSales_Click" />
                    
                    <asp:Button ID="btnBackToDashboard" runat="server" Text="?? Back to Dashboard" 
                        CssClass="btn" OnClick="btnBackToDashboard_Click" />
                </div>
            </div>

            <!-- Products List -->
            <div id="productsList" runat="server" visible="false" style="margin-top: 30px;">
                <h3>?? Current Products in Database:</h3>
                <asp:Repeater ID="rptProducts" runat="server">
                    <HeaderTemplate>
                        <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                            <tr style="background-color: #f8f9fa; font-weight: bold;">
                                <td style="padding: 10px; border: 1px solid #ddd;">Product Name</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Category</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Price</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Status</td>
                            </tr>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("ProductName") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("ProductCategory") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;">$<%# Eval("ProductVal", "{0:F2}") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;">
                                <%# (bool)Eval("IsActive") ? "? Active" : "? Inactive" %>
                            </td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate>
                        </table>
                    </FooterTemplate>
                </asp:Repeater>
            </div>

            <!-- Sales List -->
            <div id="salesList" runat="server" visible="false" style="margin-top: 30px;">
                <h3>?? Current Sales in Database:</h3>
                <asp:Repeater ID="rptSales" runat="server">
                    <HeaderTemplate>
                        <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                            <tr style="background-color: #f8f9fa; font-weight: bold;">
                                <td style="padding: 10px; border: 1px solid #ddd;">Sale Date</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Variant ID</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Quantity</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Price</td>
                                <td style="padding: 10px; border: 1px solid #ddd;">Total</td>
                            </tr>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("FormattedTransactionDate") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("VariantId") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("Quantity") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("FormattedSalePrice") %></td>
                            <td style="padding: 10px; border: 1px solid #ddd;"><%# Eval("FormattedTotalAmount") %></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate>
                        </table>
                    </FooterTemplate>
                </asp:Repeater>
            </div>
        </div>
    </form>
</body>
</html>