<%@ Page Title="Activity Log" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="ActivityLog.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ActivityLogPage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">Activity Log</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="user-crud-container">
        <h2>Activity Log</h2>
        <asp:GridView ID="gvActivity" runat="server" AutoGenerateColumns="false" CssClass="user-table">
            <Columns>
                <asp:BoundField DataField="Timestamp" HeaderText="Time" DataFormatString="{0:yyyy-MM-dd HH:mm:ss}" />
                <asp:BoundField DataField="UserName" HeaderText="User" />
                <asp:BoundField DataField="Action" HeaderText="Action" />
                <asp:BoundField DataField="EntityType" HeaderText="Entity" />
                <asp:BoundField DataField="EntityId" HeaderText="Entity Id" />
                <asp:BoundField DataField="Details" HeaderText="Details" />
            </Columns>
        </asp:GridView>
    </div>
</asp:Content>
