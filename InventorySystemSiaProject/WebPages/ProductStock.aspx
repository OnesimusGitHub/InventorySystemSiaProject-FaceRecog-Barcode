<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="ProductStock.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.PstockForm" %>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Product Stock - 
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/productinformation.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <h1 class="dashboard-title">Product Stocks</h1>
    </div>

    <asp:Label ID="lblMessage" runat="server" CssClass="text-success" Visible="false"></asp:Label>
    <br />

    <asp:GridView ID="gvProducts" runat="server" AutoGenerateColumns="False" CssClass="table" OnRowCommand="gvProducts_RowCommand">
        <Columns>
            <asp:TemplateField HeaderText="Image">
                <ItemTemplate>
                    <asp:Image ID="imgVariant" runat="server"
                               ImageUrl='<%# Eval("VariantImg") %>'
                               Width="80px" Height="80px" />
                </ItemTemplate>
            </asp:TemplateField>

            <asp:BoundField DataField="VariantName" HeaderText="Product" />
            <asp:BoundField DataField="StockQuantity" HeaderText="Stock" />

            <asp:TemplateField HeaderText="Status">
                <ItemTemplate>
                    <asp:Label ID="lblStatus" runat="server" 
                        Text='<%# (Convert.ToBoolean(Eval("IsLowStock")) ? "Low Stock" : "In Stock") %>' 
                        ForeColor='<%# (Convert.ToBoolean(Eval("IsLowStock")) ? System.Drawing.Color.Red : System.Drawing.Color.Green) %>'>
                    </asp:Label>
                </ItemTemplate>
            </asp:TemplateField>

            <asp:TemplateField HeaderText="Actions">
                <ItemTemplate>
                    <asp:Button ID="btnEmail" runat="server" Text="Send Email"
                        CommandName="SendHelp"
                        CommandArgument='<%# Eval("Id") %>'
                        CssClass="btn btn-primary"
                        Enabled='<%# Convert.ToBoolean(Eval("IsLowStock")) %>' />
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</asp:Content>
