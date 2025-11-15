<%@ Page Title="User Profile" Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="UserProfile.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.UserProfile" %>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    User Profile
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .profile-card {
            background: white;
            border-radius: 16px;
            box-shadow: 0 4px 24px rgba(102,126,234,0.10);
            padding: 32px 40px 24px 40px;
            margin: 32px auto;
            max-width: 900px;
        }
        .profile-header {
            display: flex;
            align-items: center;
            gap: 24px;
        }
        .profile-avatar {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: #a86d6a;
            color: white;
            font-size: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
        }
        .profile-info {
            flex: 1;
        }
        .profile-name {
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 2px;
        }
        .profile-email {
            font-size: 15px;
            color: #555;
            margin-bottom: 8px;
        }
        .profile-verified {
            display: inline-block;
            background: #e6f9ed;
            color: #28a745;
            font-size: 13px;
            font-weight: 600;
            border-radius: 8px;
            padding: 4px 14px;
            margin-bottom: 4px;
        }
        .profile-details {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 32px;
            margin: 32px 0 24px 0;
        }
        .profile-details label {
            font-size: 13px;
            color: #888;
            font-weight: 600;
            margin-bottom: 2px;
            display: block;
        }
        .profile-details .detail {
            font-size: 16px;
            color: #222;
            font-weight: 500;
            margin-bottom: 16px;
        }
        .profile-actions {
            display: flex;
            gap: 16px;
        }
        .btn-profile {
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 15px;
            font-weight: 600;
            border: none;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-edit {
            background: #2563eb;
            color: white;
        }
        .btn-edit:hover {
            background: #1746a2;
        }
        .btn-password {
            background: #f1f3f6;
            color: #222;
        }
        .btn-password:hover {
            background: #e2e6ea;
        }
        /* Activity Log Section */
        .activity-section {
            background: white;
            border-radius: 16px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            padding: 32px 40px;
            margin: 32px auto;
            width: 100%;
            max-width: 900px;
            max-height: 400px; /* Set your desired max height */
            overflow-y: auto;  /* Enable vertical scroll */
            overflow-x: hidden; /* Prevent horizontal scroll */
        }
        .activity-title {
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 18px;
        }
        .activity-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .activity-item {
            padding: 16px 0;
            border-bottom: 1px solid #f0f0f0;
        }
        .activity-item:last-child {
            border-bottom: none;
        }
        .activity-date {
            font-size: 13px;
            color: #888;
            margin-bottom: 2px;
        }
        .activity-desc {
            font-size: 15px;
            color: #222;
        }
        .activity-badge {
            display: inline-block;
            padding: 6px 18px;
            border-radius: 16px;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 10px;
            background: #e6f9ed;
            color: #28a745;
        }
        .activity-badge.update {
            background: #eaf7fa;
            color: #17a2b8;
        }
        .activity-badge.delete {
            background: #f8d7da;
            color: #dc3545;
        }
        .activity-badge.add {
            background: #e6f9ed;
            color: #28a745;
            display: inline-block;
            padding: 6px 18px;
            border-radius: 16px;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .activity-label {
            color: #b04a6a;
            font-weight: 600;
            margin-right: 8px;
        }
        .activity-fields {
            margin-bottom: 10px;
        }
        .activity-fields .activity-label {
            display: inline-block;
            min-width: 140px;
        }
        .activity-changes {
            display: flex;
            gap: 18px;
            margin-bottom: 10px;
        }
        .activity-before, .activity-after {
            flex: 1;
            padding: 16px;
            border-radius: 8px;
            font-size: 15px;
        }
        .activity-before {
            background: #fff7da;
        }
        .activity-after {
            background: #e6f9ed;
        }
        .activity-delete {
            background: #f8d7da;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 10px;
        }
        /* Add Ingredient Card */
        .activity-add-card {
            background: #f8f9fa;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(163, 106, 102, 0.08);
            border: 1px solid #e9ecef;
            padding: 24px 28px 18px 28px;
            margin-bottom: 18px;
        }
        .activity-add-title {
            font-size: 18px;
            font-weight: 700;
            color: #a86d6a;
            margin-bottom: 8px;
        }
        .activity-add-fields {
            margin-top: 10px;
        }
        .activity-add-fields .activity-label {
            color: #b04a6a;
            font-weight: 600;
            min-width: 140px;
            display: inline-block;
        }
        .activity-add-fields .activity-value {
            color: #222;
            font-weight: 500;
            margin-left: 8px;
        }
        .activity-add-fields .activity-row {
            margin-bottom: 8px;
        }
        .activity-json {
            display: block;
            background: #f8f9fa;
            border-radius: 8px;
            border: 1px solid #e9ecef;
            padding: 12px 16px;
            margin-top: 8px;
            font-family: 'Fira Mono', 'Consolas', 'Menlo', monospace;
            font-size: 14px;
            color: #444;
            white-space: pre-wrap;
            overflow-x: auto;
            max-width: 100%;
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="profile-card">
        <div class="profile-header">
            <div class="profile-avatar">
                <%-- Show first letter of name or user icon --%>
                <asp:Label ID="lblAvatar" runat="server" Text="J" />
            </div>
            <div class="profile-info">
                <div class="profile-name">
                    <asp:Label ID="lblFullName" runat="server" Text="Jm Reyes" />
                </div>
                <div class="profile-email">
                    <asp:Label ID="lblEmail" runat="server" Text="reyesjundillmharcalagahan@gmail.com" />
                </div>
                <span class="profile-verified">Verified</span>
            </div>
        </div>
        <hr />
        <div class="profile-details">
            <div>
                <label>FIRST NAME</label>
                <div class="detail"><asp:Label ID="lblFirstName" runat="server" Text="Jm" /></div>
                <label>EMAIL ADDRESS</label>
                <div class="detail"><asp:Label ID="lblEmail2" runat="server" Text="reyesjundillmharcalagahan@gmail.com" /></div>
                <label>ADDRESS</label>
                <div class="detail"><asp:Label ID="lblAddress" runat="server" Text="Bahay Toro" /></div>
            </div>
            <div>
                <label>LAST NAME</label>
                <div class="detail"><asp:Label ID="lblLastName" runat="server" Text="Reyes" /></div>
                <label>AGE</label>
                <div class="detail"><asp:Label ID="lblAge" runat="server" Text="20" /></div>
                <label>MEMBER SINCE</label>
                <div class="detail"><asp:Label ID="lblMemberSince" runat="server" Text="November 08, 2025" /></div>
            </div>
        </div>
       
    </div>

    <!-- Activity Log Section -->
    <div class="activity-section">
        <div class="activity-title">Your Activity Log</div>
        <asp:Repeater ID="rptActivityLog" runat="server">
            <ItemTemplate>
                <div class="activity-item">
                    <div class="activity-date"><%# Eval("Date") %></div>
                    <div class="activity-desc"><%# Eval("Description") %></div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
        <asp:Label ID="lblNoActivity" runat="server" Text="No activity found." Visible="false" CssClass="detail" />
    </div>

    
</asp:Content>
