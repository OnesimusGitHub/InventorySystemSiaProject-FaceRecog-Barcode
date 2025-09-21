<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="UserPrivilege.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.UserPrivilege" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    User Management
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="head" runat="server">
    <link href="../Content/userprivilege.css" rel="stylesheet" />
    <style>
        .user-crud-container { max-width: 900px; margin: 2rem auto; background: #fff; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.08); padding: 2rem; }
        .user-crud-header { font-size: 1.5rem; font-weight: 600; margin-bottom: 1.5rem; }
        .user-table { width: 100%; border-collapse: collapse; margin-bottom: 2rem; }
        .user-table th, .user-table td { padding: 0.75rem 1rem; border-bottom: 1px solid #eee; text-align: left; }
        .user-table th { background: #f7f7f7; font-weight: 600; }
        .user-table tr:last-child td { border-bottom: none; }
        .user-actions button { margin-right: 0.5rem; }
        .user-form { display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 2rem; }
        .user-form input, .user-form select { padding: 0.5rem; border-radius: 6px; border: 1px solid #ccc; min-width: 180px; }
        .user-form label { font-weight: 500; margin-right: 0.5rem; }
        .user-form-row { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem; }
        .user-form-actions { margin-top: 1rem; }
        .user-form-actions button { margin-right: 0.5rem; }
        .user-message { color: #4CAF50; font-weight: 500; margin-bottom: 1rem; }
        .user-error { color: #f44336; font-weight: 500; margin-bottom: 1rem; }
    </style>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="user-crud-container">
        <div class="user-crud-header">User Management</div>
        <asp:Label ID="lblMessage" runat="server" CssClass="user-message" Visible="false" />
        <asp:Label ID="lblError" runat="server" CssClass="user-error" Visible="false" />
        <asp:Panel ID="pnlUserForm" runat="server" CssClass="user-form">
            <div class="user-form-row">
                <label for="txtName">Name</label>
                <asp:TextBox ID="txtName" runat="server" CssClass="form-control" />
            </div>
            <div class="user-form-row">
                <label for="txtEmail">Email</label>
                <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" />
            </div>
            <div class="user-form-row">
                <label for="ddlRole">Role</label>
                <asp:DropDownList ID="ddlRole" runat="server" CssClass="form-control">
                    <asp:ListItem Text="User" Value="User" />
                    <asp:ListItem Text="Admin" Value="Admin" />
                </asp:DropDownList>
            </div>
            <div class="user-form-row">
                <label for="txtPassword">Password</label>
                <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" />
            </div>
            <div class="user-form-actions">
                <asp:Button ID="btnSaveUser" runat="server" Text="Add User" />
                <asp:Button ID="btnCancelEdit" runat="server" Text="Cancel" Visible="false" />
            </div>
            <asp:HiddenField ID="hfUserId" runat="server" />
        </asp:Panel>
        <asp:GridView ID="gvUsers" runat="server" AutoGenerateColumns="False" CssClass="user-table" DataKeyNames="Id">
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" />
                <asp:BoundField DataField="Email" HeaderText="Email" />
                <asp:BoundField DataField="Role" HeaderText="Role" />
                <asp:CheckBoxField DataField="IsActive" HeaderText="Active" />
                <asp:CommandField ShowEditButton="True" ShowDeleteButton="True" />
            </Columns>
        </asp:GridView>
    </div>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
