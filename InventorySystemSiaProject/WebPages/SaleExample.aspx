<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SaleExample.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.SaleExample" Async="true" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Sales Example - Trigger Functionality</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <h2>Sales Management with Automatic Stock Decrement</h2>
            
            <h3>Create Sale (with automatic stock decrement trigger)</h3>
            <asp:Button ID="btnCreateSale" runat="server" Text="Create Sale" OnClick="CreateSale_Click" />
            <br /><br />
            
            <h3>Cancel Sale (restore stock)</h3>
            <asp:Button ID="btnCancelSale" runat="server" Text="Cancel Sale" OnClick="CancelSale_Click" />
            <br /><br />
            
            <h3>Check Stock Status</h3>
            <asp:Button ID="btnCheckStock" runat="server" Text="Check Stock" OnClick="CheckStock_Click" />
            <br /><br />
            
            <div style="background-color: #f0f0f0; padding: 10px; margin-top: 20px;">
                <h4>Trigger Functionality Implemented:</h4>
                <ul>
                    <li><strong>Automatic Stock Decrement:</strong> When a sale is created, variant stock is automatically decremented</li>
                    <li><strong>Transaction Safety:</strong> Uses MongoDB transactions to ensure data consistency</li>
                    <li><strong>Stock Validation:</strong> Prevents sales when insufficient stock is available</li>
                    <li><strong>Stock Restoration:</strong> When a sale is cancelled, stock is automatically restored</li>
                    <li><strong>Low Stock Warning:</strong> Checks if a sale would cause stock to fall below minimum threshold</li>
                    <li><strong>Batch Processing:</strong> Can process any sales that failed to decrement stock</li>
                </ul>
            </div>
        </div>
    </form>
</body>
</html>