<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="Stock.aspx.cs" Inherits="InventorySystemSiaProject.Admin.Stock" %>

<asp:Content ID="HeadContentStock" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="MainContentStock" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <div>
            <div class="date-info">Inventory Management</div>
            <h1 class="dashboard-title">Stock Management</h1>
        </div>
    </div>
    
    <div class="main-chart-container">
        <div class="chart-header">
            <h2 class="chart-title">Stock Overview</h2>
        </div>
        <p>Stock management functionality will be implemented here.</p>
    </div>
</asp:Content>

<asp:Content ID="ScriptsContentStock" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>