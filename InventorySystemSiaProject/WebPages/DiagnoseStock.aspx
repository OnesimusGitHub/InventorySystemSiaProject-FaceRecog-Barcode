<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DiagnoseStock.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.DiagnoseStock" Async="true" %>

<!DOCTYPE html>
<html>
<head>
    <title>Diagnose Stock Request Issue</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 30px auto;
            padding: 20px;
            background: #f5f7fa;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 4px solid #a64d79;
            padding-bottom: 15px;
            margin-bottom: 30px;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 5px solid #a64d79;
        }
        .section h2 {
            color: #a64d79;
            margin-top: 0;
        }
        .stat {
            display: inline-block;
            margin: 10px 20px 10px 0;
            padding: 15px 25px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .stat-label {
            font-size: 12px;
            color: #7f8c8d;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            color: #2c3e50;
        }
        .success {
            color: #27ae60;
        }
        .warning {
            color: #f39c12;
        }
        .error {
            color: #e74c3c;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background: white;
        }
        th {
            background: #a64d79;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #ecf0f1;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        .badge-success {
            background: #d4edda;
            color: #155724;
        }
        .badge-danger {
            background: #f8d7da;
            color: #721c24;
        }
        .badge-warning {
            background: #fff3cd;
            color: #856404;
        }
        .btn {
            padding: 12px 24px;
            background: #a64d79;
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            display: inline-block;
            margin-top: 20px;
        }
        .btn:hover {
            background: #8b3d66;
        }
        .code {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <h1>?? Stock Request Diagnostic Report</h1>
            
            <div class="section">
                <h2>?? Database Statistics</h2>
                <div class="stat">
                    <div class="stat-label">Total Variants</div>
                    <div class="stat-value"><asp:Label ID="lblTotalVariants" runat="server" Text="0" /></div>
                </div>
                <div class="stat">
                    <div class="stat-label">With Suppliers</div>
                    <div class="stat-value success"><asp:Label ID="lblVariantsWithSuppliers" runat="server" Text="0" /></div>
                </div>
                <div class="stat">
                    <div class="stat-label">Low Stock Items</div>
                    <div class="stat-value warning"><asp:Label ID="lblLowStockItems" runat="server" Text="0" /></div>
                </div>
                <div class="stat">
                    <div class="stat-label">Total Suppliers</div>
                    <div class="stat-value"><asp:Label ID="lblTotalSuppliers" runat="server" Text="0" /></div>
                </div>
            </div>

            <div class="section">
                <h2>?? Products with Low Stock & Suppliers</h2>
                <p>These products can use the "Request Stock" feature:</p>
                <asp:GridView ID="gvLowStockProducts" runat="server" AutoGenerateColumns="False" 
                    CssClass="table" BorderWidth="0">
                    <Columns>
                        <asp:BoundField DataField="VariantName" HeaderText="Product Name" />
                        <asp:BoundField DataField="StockQuantity" HeaderText="Current Stock" />
                        <asp:BoundField DataField="MinimumStock" HeaderText="Minimum Stock" />
                        <asp:BoundField DataField="SupplierName" HeaderText="Supplier" />
                        <asp:BoundField DataField="SupplierEmail" HeaderText="Supplier Email" />
                        <asp:BoundField DataField="Id" HeaderText="Variant ID" />
                    </Columns>
                    <EmptyDataTemplate>
                        <div style="padding: 20px; text-align: center; color: #7f8c8d;">
                            No products found with low stock that have suppliers assigned.
                        </div>
                    </EmptyDataTemplate>
                </asp:GridView>
            </div>

            <div class="section">
                <h2>?? Problems Found</h2>
                <asp:Panel ID="pnlProblems" runat="server">
                    <asp:Label ID="lblProblems" runat="server" />
                </asp:Panel>
            </div>

            <div class="section">
                <h2>?? How to Test</h2>
                <ol>
                    <li>Find a Variant ID from the table above (if any exist)</li>
                    <li>Copy the Variant ID</li>
                    <li>Go to <a href="/TestVariantHandler.html" target="_blank">Test Variant Handler</a></li>
                    <li>Paste the Variant ID and click "Test Handler"</li>
                    <li>Check the console output for detailed error messages</li>
                </ol>
            </div>

            <asp:Button ID="btnRefresh" runat="server" Text="?? Refresh Report" CssClass="btn" OnClick="btnRefresh_Click" />
            <a href="/WebPages/ProductStock.aspx" class="btn">? Back to Product Stock</a>
        </div>
    </form>
</body>
</html>
