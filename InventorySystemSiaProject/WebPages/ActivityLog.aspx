<%@ Page Title="Activity Log" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="ActivityLog.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ActivityLogPage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">Activity Log</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        .activity-log-container {
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(166,77,121,0.08);
            padding: 32px 24px 24px 24px;
            margin: 32px auto 0 auto;
            max-width: 98vw;
            overflow-y: auto;
        }
        .activity-log-title {
            font-size: 2rem;
            font-weight: 700;
            color: #a64d79;
            margin-bottom: 24px;
        }
        .activity-table-wrapper {
            overflow-x: auto;
            overflow-y: auto;
            max-height: 90vh;
        }
        .activity-table {
            width: 100%;
            min-width: 1000px;
            border-collapse: collapse;
            font-size: 15px;
            background: #fff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 1px 4px rgba(166,77,121,0.06);
            table-layout: auto;
        }
        .activity-table th, .activity-table td {
            padding: 10px 12px;
            border-bottom: 1px solid #f0e3ea;
            text-align: left;
            vertical-align: top;
            word-break: break-word;
        }
        .activity-table th {
            background: #a64d79;
            color: #fff;
            font-weight: 600;
            font-size: 15px;
            min-width: 90px;
        }
        .activity-table td {
            min-width: 90px;
        }
        .activity-table th.details-header, .activity-table td.details-cell {
            min-width: 320px;
            max-width: 600px;
        }
        .activity-table tr:nth-child(even) {
            background: #f9f6f8;
        }
        .activity-table tr:last-child td {
            border-bottom: none;
        }
        .activity-table td.details-cell {
            font-size: 14px;
            background: #f8f9fa;
        }
        
        /* Human-friendly details styling */
        .details-container {
            padding: 8px;
            background: white;
            border-radius: 6px;
            border: 1px solid #e9ecef;
        }
        
        .detail-item {
            padding: 4px 0;
            line-height: 1.6;
        }
        
        .detail-label {
            font-weight: 600;
            color: #a64d79;
            display: inline-block;
            min-width: 120px;
        }
        
        .detail-value {
            color: #333;
        }
        
        .detail-section {
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px solid #e9ecef;
        }
        
        .detail-section-title {
            font-weight: 700;
            color: #a64d79;
            margin-bottom: 4px;
            font-size: 13px;
            text-transform: uppercase;
        }
        
        .changes-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-top: 8px;
        }
        
        .before-after {
            padding: 8px;
            border-radius: 4px;
            font-size: 13px;
        }
        
        .before-column {
            background: #fff3cd;
            border-left: 3px solid #ffc107;
        }
        
        .after-column {
            background: #d4edda;
            border-left: 3px solid #28a745;
        }
        
        .column-title {
            font-weight: 700;
            margin-bottom: 6px;
            font-size: 12px;
            text-transform: uppercase;
        }
        
        .change-item {
            padding: 3px 0;
            font-size: 13px;
        }
        
        .change-label {
            font-weight: 600;
            color: #555;
        }
        
        .action-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        
        .badge-create {
            background: #d4edda;
            color: #155724;
        }
        
        .badge-update {
            background: #d1ecf1;
            color: #0c5460;
        }
        
        .badge-delete {
            background: #f8d7da;
            color: #721c24;
        }
        
        @media (max-width: 900px) {
            .activity-log-container { padding: 10px; }
            .activity-table th, .activity-table td { font-size: 13px; padding: 7px 6px; min-width: 60px; }
            .activity-table th.details-header, .activity-table td.details-cell { min-width: 120px; max-width: 220px; }
            .changes-grid { grid-template-columns: 1fr; }
        }
    </style>
    <div class="activity-log-container">
        <div class="activity-log-title">?? Activity Log</div>
        <!-- Date Filter Bar -->
        <div style="display: flex; gap: 16px; align-items: flex-end; margin-bottom: 18px; flex-wrap: wrap;">
            <div style="display: flex; flex-direction: column;">
                <label for="txtStartDate" style="font-weight:600; color:#333; margin-bottom:4px;">Start Date</label>
                <asp:TextBox ID="txtStartDate" runat="server" CssClass="form-control" TextMode="Date" />
            </div>
            <div style="display: flex; flex-direction: column;">
                <label for="txtEndDate" style="font-weight:600; color:#333; margin-bottom:4px;">End Date</label>
                <asp:TextBox ID="txtEndDate" runat="server" CssClass="form-control" TextMode="Date" />
            </div>
            <asp:Button ID="btnFilterDate" runat="server" Text="Filter" CssClass="btn btn-primary" OnClick="btnFilterDate_Click" />
        </div>
        <div class="activity-table-wrapper">
            <asp:GridView ID="gvActivity" runat="server" AutoGenerateColumns="false" CssClass="activity-table">
                <Columns>
                    <asp:BoundField DataField="Timestamp" HeaderText="Time" DataFormatString="{0:yyyy-MM-dd HH:mm:ss}" />
                    <asp:BoundField DataField="UserName" HeaderText="User" />
                    <asp:BoundField DataField="Action" HeaderText="Action" />
                    <asp:BoundField DataField="EntityType" HeaderText="Entity" />
                    <asp:BoundField DataField="EntityId" HeaderText="Entity Id" />
                    <asp:TemplateField HeaderText="Details">
                        <HeaderStyle CssClass="details-header" />
                        <ItemTemplate>
                            <div class="details-cell"><%# FormatActivityDetails(Eval("Details"), Eval("Action")) %></div>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
</asp:Content>
