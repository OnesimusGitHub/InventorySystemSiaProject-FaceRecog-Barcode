S<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="CreateIndexes.aspx.cs" Inherits="InventorySystemSiaProject.Admin.CreateIndexes" Async="true" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Create MongoDB Indexes</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 800px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2rem;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1rem;
        }
        .btn {
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 1rem;
            cursor: pointer;
            transition: all 0.3s ease;
            margin: 10px;
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
        .btn-danger {
            background: linear-gradient(135deg, #f44336 0%, #e91e63 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(244, 67, 54, 0.3);
        }
        .btn-danger:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(244, 67, 54, 0.4);
        }
        .btn-info {
            background: linear-gradient(135deg, #2196F3 0%, #21CBF3 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(33, 150, 243, 0.3);
        }
        .btn-info:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(33, 150, 243, 0.4);
        }
        .message {
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            font-weight: 500;
        }
        .message.success {
            background: #e8f5e9;
            color: #2e7d32;
            border: 2px solid #4caf50;
        }
        .message.error {
            background: #ffebee;
            color: #c62828;
            border: 2px solid #f44336;
        }
        .message.info {
            background: #e3f2fd;
            color: #1565c0;
            border: 2px solid #2196F3;
        }
        .index-list {
            background: #f5f5f5;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            max-height: 400px;
            overflow-y: auto;
        }
        .index-item {
            background: white;
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            border-left: 4px solid #667eea;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .index-item h4 {
            margin: 0 0 10px 0;
            color: #667eea;
            font-size: 1.1rem;
        }
        .index-item p {
            margin: 5px 0;
            color: #666;
            font-size: 0.9rem;
        }
        .button-group {
            display: flex;
            justify-content: center;
            flex-wrap: wrap;
            gap: 10px;
            margin: 20px 0;
        }
        .warning-box {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            color: #856404;
        }
        .warning-box h3 {
            margin: 0 0 10px 0;
            color: #856404;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <h1>?? MongoDB Index Manager</h1>
            <p class="subtitle">Create indexes to optimize query performance (from 30+ seconds to milliseconds!)</p>

            <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="message">
                <asp:Label ID="lblMessage" runat="server" />
            </asp:Panel>

            <div class="index-list">
                <h3>?? Indexes to be created:</h3>
                
                <div class="index-item">
                    <h4>?? ProductSales Indexes</h4>
                    <p>• <strong>idx_transactiondate_isactive</strong> - Date range queries (CRITICAL for dashboard)</p>
                    <p>• <strong>idx_variantid</strong> - Variant lookups</p>
                    <p>• <strong>idx_date_variant_active</strong> - COMPOUND index for filtered queries</p>
                    <p>• <strong>idx_createdat_desc</strong> - Sorting by creation date</p>
                </div>

                <div class="index-item">
                    <h4>?? Products Indexes</h4>
                    <p>• <strong>idx_category_isactive</strong> - Category filtering (CRITICAL for filters)</p>
                    <p>• <strong>idx_supplierid</strong> - Supplier lookups</p>
                    <p>• <strong>idx_createdat_desc</strong> - Sorting</p>
                </div>

                <div class="index-item">
                    <h4>?? ProductVariants Indexes</h4>
                    <p>• <strong>idx_productid_isactive</strong> - Product joins (CRITICAL for category aggregation)</p>
                    <p>• <strong>idx_sku</strong> - UNIQUE SKU lookups</p>
                    <p>• <strong>idx_stock_compound</strong> - Stock level queries</p>
                </div>
            </div>

            <div class="warning-box">
                <h3>?? Performance Impact</h3>
                <p><strong>Before indexes:</strong> Queries take 30+ seconds (timeouts)</p>
                <p><strong>After indexes:</strong> Queries complete in ~50-200ms (INSTANT!)</p>
                <p><strong>Note:</strong> Index creation runs in the background and won't block your database.</p>
            </div>

            <div class="button-group">
                <asp:Button ID="btnCreateIndexes" runat="server" Text="?? Create All Indexes" 
                    CssClass="btn btn-primary" OnClick="btnCreateIndexes_Click" />
                
                <asp:Button ID="btnListIndexes" runat="server" Text="?? List Existing Indexes" 
                    CssClass="btn btn-info" OnClick="btnListIndexes_Click" />
                
                <asp:Button ID="btnDropIndexes" runat="server" Text="??? Drop All Custom Indexes" 
                    CssClass="btn btn-danger" OnClick="btnDropIndexes_Click" 
                    OnClientClick="return confirm('Are you sure you want to drop all custom indexes? This cannot be undone.');" />
            </div>

            <asp:Panel ID="pnlIndexList" runat="server" Visible="false">
                <div class="index-list">
                    <h3>?? Current Indexes:</h3>
                    <asp:Literal ID="litIndexList" runat="server" />
                </div>
            </asp:Panel>

            <div style="text-align: center; margin-top: 30px;">
                <a href="../WebPages/Dashboard.aspx" style="color: #667eea; text-decoration: none; font-weight: 600;">
                    ? Back to Dashboard
                </a>
            </div>
        </div>
    </form>
</body>
</html>
