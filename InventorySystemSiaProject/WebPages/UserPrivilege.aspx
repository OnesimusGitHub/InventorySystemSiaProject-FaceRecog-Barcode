<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="UserPrivilege.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.UserPrivilege" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">User Management</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="head" runat="server">
    <link href="../Content/userprivilege.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div id="userPageRoot" data-edit-face-encoding-id="<%= txtEditFaceEncoding.ClientID %>" data-edit-face-hash-id="<%= txtEditFaceHash.ClientID %>" data-add-face-encoding-id="<%= txtAddFaceEncoding.ClientID %>" data-add-face-hash-id="<%= txtAddFaceHash.ClientID %>" data-add-face-snapshot-id="<%= hfAddFaceSnapshot.ClientID %>" data-edit-face-snapshot-id="<%= hfEditFaceSnapshot.ClientID %>">
    <div class="user-crud-container">
        <div class="user-crud-header">User Management(ABOUT TO CHANGE)</div>
        <asp:Label ID="lblMessage" runat="server" CssClass="user-message" Visible="false" />
        <asp:Label ID="lblError" runat="server" CssClass="user-error" Visible="false" />
        <div class="user-toolbar">
            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control toolbar-input" Placeholder="Search name or email" />
            <asp:DropDownList ID="ddlFilterRole" runat="server" CssClass="form-control toolbar-select">
                <asp:ListItem Text="All Roles" Value="" />
                <asp:ListItem Text="User" Value="User" />
                <asp:ListItem Text="Admin" Value="Admin" />
            </asp:DropDownList>
            <button type="button" class="btn-secondary" data-action="search">Search</button>
            <button type="button" class="btn-primary" data-action="open-add-user">Add User</button>
        </div>
        <asp:GridView ID="gvUsers" runat="server" AutoGenerateColumns="False" CssClass="user-table" DataKeyNames="Id" OnRowCommand="gvUsers_RowCommand" OnRowDeleting="gvUsers_RowDeleting">
            <Columns>
                <asp:BoundField DataField="Name" HeaderText="Name" />
                <asp:BoundField DataField="Email" HeaderText="Email" />
                <asp:BoundField DataField="Role" HeaderText="Role" />
                <asp:CheckBoxField DataField="IsActive" HeaderText="Active" />
                <asp:TemplateField HeaderText="Actions">
                    <ItemTemplate>
                        <asp:LinkButton ID="lnkEdit" runat="server" Text="Edit" CommandName="EditUser" CommandArgument='<%# Eval("Id") %>' CssClass="btn-link" />
                        <asp:LinkButton ID="lnkDelete" runat="server" Text="Delete" CommandName="Delete" CommandArgument='<%# Eval("Id") %>' OnClientClick="return confirm('Delete this user?');" CssClass="btn-link danger" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <!-- Edit User Modal -->
    <div id="editUserModal" class="modal-overlay">
        <div class="modal">
            <div class="modal-header"><h3>Edit User</h3><button type="button" class="close-btn" data-action="close-edit">&times;</button></div>
            <div class="modal-body">
                <asp:HiddenField ID="hfEditUserId" runat="server" />
                <div class="form-row"><label>Name</label><asp:TextBox ID="txtEditName" runat="server" CssClass="form-control" /></div>
                <div class="form-row"><label>Email</label><asp:TextBox ID="txtEditEmail" runat="server" CssClass="form-control" /></div>
                <div class="form-row"><label>Password (leave blank)</label><asp:TextBox ID="txtEditPassword" runat="server" CssClass="form-control" TextMode="Password" /></div>
                <div class="form-row"><label>Role</label><asp:DropDownList ID="ddlEditRole" runat="server" CssClass="form-control"><asp:ListItem Text="User" Value="User" /><asp:ListItem Text="Admin" Value="Admin" /></asp:DropDownList></div>
                <asp:TextBox ID="txtEditFaceEncoding" runat="server" TextMode="MultiLine" Style="display:none;" />
                <asp:TextBox ID="txtEditFaceHash" runat="server" Style="display:none;" />
                <asp:HiddenField ID="hfEditFaceSnapshot" runat="server" />
                <div class="form-row"><label>Short Pass</label><asp:TextBox ID="txtEditShortPass" runat="server" CssClass="form-control" /></div>
                <div class="form-row inline"><asp:CheckBox ID="chkEditActive" runat="server" /> <span>Active</span></div>
                <div class="camera-section">
                    <div class="camera-preview-wrapper">
                        <video id="faceVideo" class="face-video" autoplay playsinline></video>
                        <canvas id="faceCanvas" width="320" height="240" style="display:none;"></canvas>
                        <img id="faceSnapshot" class="face-preview" alt="Face snapshot" style="display:none;" />
                    </div>
                    <div class="camera-buttons">
                        <button type="button" class="btn-secondary" data-action="start-edit-cam">Start Camera</button>
                        <button type="button" class="btn-primary" data-action="capture-edit-face">Capture Face</button>
                        <button type="button" class="btn-secondary" data-action="stop-edit-cam">Stop</button>
                    </div>
                    <div id="faceStatus" class="status-text"></div>
                </div>
            </div>
            <div class="modal-footer"><button type="button" class="btn-secondary" data-action="close-edit">Cancel</button><asp:Button ID="btnUpdateUser" runat="server" Text="Save Changes" CssClass="btn-primary" /></div>
        </div>
    </div>

    <!-- Add User Modal -->
    <div id="addUserModal" class="modal-overlay">
        <div class="modal">
            <div class="modal-header"><h3>Add User</h3><button type="button" class="close-btn" data-action="close-add">&times;</button></div>
            <div class="modal-body">
                <div class="form-row"><label>Name</label><asp:TextBox ID="txtAddName" runat="server" CssClass="form-control" /></div>
                <div class="form-row"><label>Email</label><asp:TextBox ID="txtAddEmail" runat="server" CssClass="form-control" /></div>
                <div class="form-row"><label>Password</label><asp:TextBox ID="txtAddPassword" runat="server" CssClass="form-control" TextMode="Password" /></div>
                <div class="form-row"><label>Role</label><asp:DropDownList ID="ddlAddRole" runat="server" CssClass="form-control"><asp:ListItem Text="User" Value="User" /><asp:ListItem Text="Admin" Value="Admin" /></asp:DropDownList></div>
                <asp:TextBox ID="txtAddFaceEncoding" runat="server" TextMode="MultiLine" Style="display:none;" />
                <asp:TextBox ID="txtAddFaceHash" runat="server" Style="display:none;" />
                <asp:HiddenField ID="hfAddFaceSnapshot" runat="server" />
                <div class="form-row"><label>Short Pass</label><asp:TextBox ID="txtAddShortPass" runat="server" CssClass="form-control" /></div>
                <div class="form-row inline"><asp:CheckBox ID="chkAddActive" runat="server" Checked="true" /> <span>Active</span></div>
                <div class="camera-section">
                    <div class="camera-preview-wrapper">
                        <video id="faceVideoAdd" class="face-video" autoplay playsinline></video>
                        <canvas id="faceCanvasAdd" width="320" height="240" style="display:none;"></canvas>
                        <img id="faceSnapshotAdd" class="face-preview" alt="Face snapshot" style="display:none;" />
                    </div>
                    <div class="camera-buttons">
                        <button type="button" class="btn-secondary" data-action="start-add-cam">Start Camera</button>
                        <button type="button" class="btn-primary" data-action="capture-add-face">Capture Face</button>
                        <button type="button" class="btn-secondary" data-action="stop-add-cam">Stop</button>
                    </div>
                    <div id="faceStatusAdd" class="status-text"></div>
                </div>
            </div>
            <div class="modal-footer"><button type="button" class="btn-secondary" data-action="close-add">Cancel</button><asp:Button ID="btnAddUserSave" runat="server" Text="Add User" CssClass="btn-primary" /></div>
        </div>
    </div>
    </div>
</asp:Content>
<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script src="../Scripts/userprivilege.js"></script>
</asp:Content>
