<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="UserPrivilege.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.UserPrivilege" %>
<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">User Management</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="head" runat="server">
    <link href="../Content/userprivilege.css" rel="stylesheet" />
    <style>
        /* Inline palette inspired by screenshot */
        body { background:#f7f6f6; }
        .user-crud-container { background:#fff; border:1px solid #e5e5e5; border-radius:12px; box-shadow:0 2px 8px rgba(0,0,0,.04); padding:16px; }
        .user-crud-header { font-size:22px; font-weight:700; color:#2d2d2d; letter-spacing:.5px; margin-bottom:12px; }
        .user-toolbar { display:flex; gap:10px; align-items:center; margin-bottom:12px; }
        .user-toolbar .form-control { border:1px solid #e5e5e5; border-radius:8px; padding:8px 10px; }
        .btn-primary { background:#b56b6b; color:#fff; border:none; border-radius:10px; padding:8px 12px; cursor:pointer; }
        .btn-primary:hover { background:#8b5c5c; }
        .btn-secondary { background:#d9a6a6; color:#522; border:none; border-radius:10px; padding:8px 12px; cursor:pointer; }
        .btn-secondary:hover { filter:brightness(.95); }
        .btn-link { color:#8b5c5c; text-decoration:none; }
        .btn-link.danger { color:#d9534f; }
        .user-message { color:#4caf50; display:block; margin-bottom:6px; }
        .user-error { color:#d9534f; display:block; margin-bottom:6px; }
        .user-table { width:100%; border-collapse:collapse; border:1px solid #e5e5e5; }
        .user-table th, .user-table td { border-bottom:1px solid #e5e5e5; padding:8px 10px; }
        .user-table tr:hover { background:#faf7f7; }
        .modal-overlay { position:fixed; inset:0; background:rgba(0,0,0,.25); display:none; align-items:center; justify-content:center; z-index:9999; }
        .modal { width:800px; max-width:95vw; background:#fff; border:1px solid #e5e5e5; border-radius:12px; overflow:hidden; }
        .modal-header { display:flex; align-items:center; justify-content:space-between; padding:12px 14px; background:#f1e6e6; border-bottom:1px solid #e5e5e5; }
        .modal-body { padding:14px; }
        .modal-footer { display:flex; gap:8px; justify-content:flex-end; padding:12px 14px; border-top:1px solid #e5e5e5; }
        .close-btn { background:transparent; border:none; font-size:22px; cursor:pointer; color:#777; }
        .form-row { margin-bottom:10px; }
        .form-row.inline { display:flex; align-items:center; gap:8px; }
        .form-row label { display:block; font-size:13px; color:#777; margin-bottom:4px; }
        .form-control { width:100%; border:1px solid #e5e5e5; border-radius:8px; padding:8px 10px; }
        .camera-section { margin-top:8px; border-top:1px dashed #e5e5e5; padding-top:10px; }
        .face-video, .face-preview { width:320px; height:240px; border:1px solid #e5e5e5; border-radius:8px; background:#f9f4f4; }
        .status-text { font-size:12px; color:#777; margin-top:6px; }
        .she-search-wrapper { position: relative; margin-bottom: 10px; }
        .she-search-input { width: 100%; padding: 8px 10px; border: 1px solid #e5e5e5; border-radius: 8px; }
        .she-search-results { position: absolute; top: 100%; left: 0; right: 0; background: #fff; border: 1px solid #e5e5e5; border-top: none; z-index: 9999; max-height: 240px; overflow-y: auto; display:none; border-radius:0 0 12px 12px; }
        .she-search-item { padding: 8px 10px; cursor: pointer; display:flex; gap:8px; align-items:center; }
        .she-search-item:hover { background: #f8eeee; }
        .she-pill { font-size: 11px; padding: 2px 6px; background:#eee; border-radius:10px; color:#666; }
    </style>
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <!-- Hidden server controls used by code-behind logic -->
    <div style="display:none;">
        <asp:HiddenField ID="hfUserId" runat="server" />
        <asp:TextBox ID="txtName" runat="server" />
        <asp:TextBox ID="txtEmail" runat="server" />
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" />
        <asp:DropDownList ID="ddlRole" runat="server">
            <asp:ListItem Text="Employee" Value="Employee" />
            <asp:ListItem Text="Admin" Value="Admin" />
        </asp:DropDownList>
        <asp:Button ID="btnSaveUser" runat="server" Text="Save" />
        <asp:Button ID="btnCancelEdit" runat="server" Text="Cancel" />
        <asp:Button ID="btnSearch" runat="server" Text="Search" />
    </div>

    <div id="userPageRoot" data-edit-face-encoding-id="<%= txtEditFaceEncoding.ClientID %>" data-edit-face-hash-id="<%= txtEditFaceHash.ClientID %>" data-add-face-encoding-id="<%= txtAddFaceEncoding.ClientID %>" data-add-face-hash-id="<%= txtAddFaceHash.ClientID %>" data-add-face-snapshot-id="<%= hfAddFaceSnapshot.ClientID %>" data-edit-face-snapshot-id="<%= hfEditFaceSnapshot.ClientID %>">
    <div class="user-crud-container">
        <div class="user-crud-header">User Management</div>
        <asp:Label ID="lblMessage" runat="server" CssClass="user-message" Visible="false" />
        <asp:Label ID="lblError" runat="server" CssClass="user-error" Visible="false" />
        <div class="user-toolbar">
            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control toolbar-input" Placeholder="Search name or email" />
            <asp:DropDownList ID="ddlFilterRole" runat="server" CssClass="form-control toolbar-select">
                <asp:ListItem Text="All Roles" Value="" />
                <asp:ListItem Text="Employee" Value="Employee" />
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
                <div class="form-row"><label>Role</label><asp:DropDownList ID="ddlEditRole" runat="server" CssClass="form-control"><asp:ListItem Text="Employee" Value="Employee" /><asp:ListItem Text="Admin" Value="Admin" /></asp:DropDownList></div>
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
                <!-- New: Search tbl_user in db_shessentials -->
                <div class="form-row">
                    <label>Find from SheEssentials (tbl_user)</label>
                    <div class="she-search-wrapper">
                        <input type="text" id="sheSearchInput" class="she-search-input" placeholder="Search first/last name or email" autocomplete="off" />
                        <div id="sheSearchResults" class="she-search-results"></div>
                    </div>
                </div>
                <div class="form-row"><label>Name</label><asp:TextBox ID="txtAddName" runat="server" CssClass="form-control" /></div>
                <div class="form-row"><label>Email</label><asp:TextBox ID="txtAddEmail" runat="server" CssClass="form-control" /></div>
                <div class="form-row"><label>Password</label><asp:TextBox ID="txtAddPassword" runat="server" CssClass="form-control" TextMode="Password" /></div>
                <div class="form-row"><label>Role</label><asp:DropDownList ID="ddlAddRole" runat="server" CssClass="form-control"><asp:ListItem Text="Employee" Value="Employee" /><asp:ListItem Text="Admin" Value="Admin" /></asp:DropDownList></div>
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
<script type="text/javascript">
(function(){
  var input = document.getElementById('sheSearchInput');
  var results = document.getElementById('sheSearchResults');
  if(!input||!results||!window.PageMethods) return;
  var debounceTimer=null;
  function hide(){ results.style.display='none'; results.innerHTML=''; }
  function render(items){
    if(!items||items.length===0){ hide(); return; }
    results.innerHTML = items.map(function(x){
        var name = (x.FirstName||'') + ' ' + (x.LastName||'');
        name = name.trim() || x.Email;
        var verified = x.IsEmailVerified ? '<span class="she-pill">verified</span>' : '<span class="she-pill">unverified</span>';
        var role = x.Role ? '<span class="she-pill">'+x.Role+'</span>' : '';
        return '<div class="she-search-item" data-email="'+(x.Email||'')+'" data-name="'+name+'">'+
               '<i class="fas fa-user"></i><div style="flex:1">'+
               '<div>'+name+'</div><div style="font-size:12px;color:#666">'+(x.Email||'')+'</div></div>'+verified+role+'</div>';
    }).join('');
    results.style.display='block';
  }
  input.addEventListener('input', function(){
    var q = input.value.trim();
    if(q.length<2){ hide(); return; }
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(function(){
        try { PageMethods.SearchTblUsers(q, function(res){ render(res); }, function(){ hide(); }); } catch(e){ hide(); }
    }, 250);
  });
  results.addEventListener('click', function(e){
    var item = e.target.closest('.she-search-item');
    if(!item) return;
    var name = item.getAttribute('data-name')||'';
    var email = item.getAttribute('data-email')||'';
    document.getElementById('<%= txtAddName.ClientID %>').value = name;
    document.getElementById('<%= txtAddEmail.ClientID %>').value = email;
    hide();
  });
  document.addEventListener('click', function(ev){ if(!results.contains(ev.target) && ev.target!==input){ hide(); } });
})();
</script>
</asp:Content>
