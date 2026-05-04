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
            color: #A86D6A;
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
            background: #A86D6A;
            color: #fff;
            font-weight: 600;
            font-size: 15px;
            min-width: 90px;
        }
        .activity-table td {
            min-width: 90px;
        }
        .activity-table tr:nth-child(even) {
            background: #f9f6f8;
        }
        .activity-table tr:last-child td {
            border-bottom: none;
        }
        .action-btn {
            background: none;
            border: none;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 6px;
            transition: background 0.2s;
        }
        .action-btn:hover {
            background: #f0e3ea;
        }
        .action-icon {
            font-size: 18px;
            color: #a64d79;
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
        .filter-bar {
    display: flex;
    gap: 18px;
    align-items: flex-end;
    margin-bottom: 18px;
    flex-wrap: wrap;
}
.filter-label {
    font-weight: 700;
    color: #A86D6A;
    margin-bottom: 6px;
    font-size: 1.1rem;
    letter-spacing: 0.5px;
}
.filter-input {
    padding: 10px 14px;
    border: 1.5px solid #A86D6A;
    border-radius: 8px;
    font-size: 1rem;
    background: #f9f6f8;
    color: #333;
    margin-bottom: 2px;
    transition: border-color 0.2s;
}
.filter-input:focus {
    border-color: #a64d79;
    outline: none;
    background: #fff;
}
.filter-btn {
    padding: 10px 22px;
    border-radius: 8px;
    background: #A86D6A;
    color: #fff;
    font-weight: 600;
    border: none;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
}
.filter-btn:hover {
    background: #a64d79;
}
    </style>
    <div class="activity-log-container">
        <div class="activity-log-title"> Activity Log</div>
        <!-- Date Filter Bar -->
      <div class="filter-bar">
    <div style="display: flex; flex-direction: column;">
        <label for="txtStartDate" class="filter-label">Start Date</label>
        <asp:TextBox ID="txtStartDate" runat="server" CssClass="filter-input" TextMode="Date" />
    </div>
    <div style="display: flex; flex-direction: column;">
        <label for="txtEndDate" class="filter-label">End Date</label>
        <asp:TextBox ID="txtEndDate" runat="server" CssClass="filter-input" TextMode="Date" />
    </div>
    <asp:Button ID="btnFilterDate" runat="server" Text="Filter" CssClass="filter-btn" OnClick="btnFilterDate_Click" />
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
            <ItemTemplate>
                <%# ((InventorySystemSiaProject.WebPages.ActivityLogPage)Page).FormatActivityDetails(Eval("Details"), Eval("Action"), Eval("EntityType")) %>
            </ItemTemplate>
        </asp:TemplateField>
    </Columns>
</asp:GridView>
        </div>

        <!-- Separate Employee Activities table -->
        <h3 style="margin-top:28px;color:#A86D6A;">Employee Activities</h3>
        <div class="activity-table-wrapper">
            <asp:GridView ID="gvEmployeeActivity" runat="server" AutoGenerateColumns="false" CssClass="activity-table">
                <Columns>
                    <asp:BoundField DataField="CreatedAt" HeaderText="Time" DataFormatString="{0:yyyy-MM-dd HH:mm:ss}" />
                    <asp:BoundField DataField="Username" HeaderText="Username" />
                    <asp:BoundField DataField="EmployeeId" HeaderText="Employee Id" />
                    <asp:BoundField DataField="ActionType" HeaderText="Action" />
                    <asp:BoundField DataField="ItemType" HeaderText="Item Type" />
                    <asp:BoundField DataField="ItemId" HeaderText="Item Id" />
                    <asp:BoundField DataField="SKU" HeaderText="SKU" />
                    <asp:BoundField DataField="Quantity" HeaderText="Quantity" />
                    <asp:TemplateField HeaderText="Details">
                        <ItemTemplate>
                            <%# ((InventorySystemSiaProject.WebPages.ActivityLogPage)Page).FormatActivityDetails(Eval("Details"), Eval("ActionType"), Eval("ItemType")) %>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </div>
    <!-- Modal Structure -->
    <div id="activityModal" class="modal" style="display:none; position:fixed; top:0; left:0; width:100vw; height:100vh; background:rgba(0,0,0,0.25); z-index:9999; align-items:center; justify-content:center;">
        <div class="modal-content" style="background:#fff; border-radius:12px; max-width:500px; width:90vw; padding:32px 24px; position:relative; box-shadow:0 8px 32px rgba(166,77,121,0.18);">
            <span class="close" onclick="closeActivityModal()" style="position:absolute; top:18px; right:18px; font-size:22px; color:#a64d79; cursor:pointer;">&times;</span>
            <div id="modalDetailsContent"></div>
        </div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
    <script>
        function showActivityModal(btn) {
            var detailsHtml = btn.getAttribute('data-details');
            document.getElementById('modalDetailsContent').innerHTML = decodeHtml(detailsHtml);
            document.getElementById('activityModal').style.display = 'flex';
        }
        function closeActivityModal() {
            document.getElementById('activityModal').style.display = 'none';
        }
        function decodeHtml(html) {
            var txt = document.createElement('textarea');
            txt.innerHTML = html;
            return txt.value;
        }
        // Close modal when clicking outside content
        document.getElementById('activityModal').addEventListener('click', function(e) {
            if (e.target === this) closeActivityModal();
        });
    </script>
</asp:Content>
