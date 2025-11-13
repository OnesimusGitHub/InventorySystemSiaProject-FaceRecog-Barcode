<%@ Page Title="Supplier Management" Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="SuppliersPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.SuppliersPage" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Supplier Management
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/productinformation.css" rel="stylesheet" />
    <style>
        /* --- Copy styles from ProductStock.aspx for consistency --- */
        .tab-container { margin: 20px 0; }
        .btn { padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; font-weight: 500; transition: all 0.3s ease; }
        .btn-success { background: #28a745; color: white; }
        .btn-success:hover { background: #218838; }
        .btn-warning { background: #ffc107; color: #333; }
        .btn-warning:hover { background: #e0a800; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-danger:hover { background: #c82333; }
        .btn-secondary { background: #6c757d; color: white; }
        .btn-secondary:hover { background: #5a6268; }
        .table { width: 100%; border-collapse: separate; border-spacing: 0; margin-top: 16px; background: #fff; font-size: 14px; box-shadow: 0 2px 8px rgba(166,77,121,0.06); border-radius: 10px; overflow: hidden; }
        .table th { background: #a64d79; color: #fff; padding: 10px 8px; text-align: left; font-weight: 600; font-size: 14px; border: none; }
        .table td { padding: 8px 8px; border-bottom: 1px solid #f0e3ea; vertical-align: middle; background: #fff; }
        .table tr:hover { background: #f9f6f8; }
        .table tr:last-child td { border-bottom: none; }
        .status-badge { padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; }
        .status-active { background: #d4edda; color: #155724; }
        .status-inactive { background: #f8d7da; color: #721c24; }
        .alert { padding: 15px; margin-bottom: 20px; border-radius: 4px; font-weight: 500; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-danger { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .modal { display: none; position: fixed; z-index: 2000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.5); animation: fadeIn 0.3s; pointer-events: none; }
        .modal.show { display: block; pointer-events: auto; }
        .modal-dialog { position: relative; width: 90%; max-width: 800px; margin: 50px auto; animation: slideDown 0.3s; }
        .modal-content { background-color: #fefefe; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.3); overflow: hidden; }
        .modal-header { background: #a64d79; color: white; padding: 20px 24px; display: flex; justify-content: space-between; align-items: center; }
        .modal-header h3 { margin: 0; font-size: 24px; font-weight: 600; }
        .modal-close { background: none; border: none; color: white; font-size: 28px; font-weight: bold; cursor: pointer; padding: 0; width: 30px; height: 30px; line-height: 28px; text-align: center; border-radius: 4px; transition: background 0.2s; }
        .modal-close:hover { background: rgba(255,255,255,0.2); }
        .modal-body { padding: 24px; }
        .modal-footer { background: #f5f5f5; padding: 16px 24px; display: flex; gap: 10px; justify-content: flex-end; border-top: 1px solid #ddd; }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideDown { from { opacity: 0; transform: translateY(-50px); } to { opacity: 1; transform: translateY(0); } }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <h1 class="dashboard-title">Supplier Management</h1>
    </div>

    <!-- Success/Error Message -->
    <asp:Panel ID="pnlSupplierMessage" runat="server" CssClass="alert" Style="display:none;">
        <asp:Label ID="lblSupplierMessage" runat="server" />
    </asp:Panel>

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
        <h2>Suppliers</h2>
        <button type="button" class="btn btn-success" onclick="openSupplierModal()">
            <i class="fa fa-plus"></i> Add New Supplier
        </button>
    </div>

    <!-- Suppliers Grid -->
    <div id="suppliersGridContainer">
        <asp:GridView ID="gvSuppliers" runat="server" AutoGenerateColumns="False" CssClass="table" OnRowCommand="gvSuppliers_RowCommand" DataKeyNames="SupplierID">
            <Columns>
                <asp:BoundField DataField="SupName" HeaderText="Supplier Name" />
                <asp:BoundField DataField="SupContactPer" HeaderText="Contact Person" />
                <asp:BoundField DataField="SupContactNo" HeaderText="Contact Number" />
                <asp:BoundField DataField="SupEmail" HeaderText="Email" />
                <asp:BoundField DataField="SupAddress" HeaderText="Address" />
                <asp:TemplateField HeaderText="Status">
                    <ItemTemplate>
                        <span class='status-badge <%# Convert.ToBoolean(Eval("IsActive")) ? "status-active" : "status-inactive" %>'>
                            <%# Convert.ToBoolean(Eval("IsActive")) ? "Active" : "Inactive" %>
                        </span>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="Actions">
                    <ItemTemplate>
                        <asp:Button ID="btnEditSupplier" runat="server" Text="Edit" 
                            CommandName="EditSupplier" CommandArgument='<%# Eval("SupplierID") %>'
                            CssClass="btn btn-warning" CausesValidation="false" />
                        <asp:Button ID="btnDeleteSupplier" runat="server" Text="Delete" 
                            CommandName="DeleteSupplier" CommandArgument='<%# Eval("SupplierID") %>'
                            CssClass="btn btn-danger" CausesValidation="false"
                            OnClientClick="return confirm('Are you sure you want to delete this supplier?');" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <EmptyDataTemplate>
                <div style="text-align: center; padding: 40px; color: #666;">
                    <i class="fa fa-inbox" style="font-size: 48px; margin-bottom: 15px; display: block; color: #ddd;"></i>
                    <p>No suppliers found. Click "Add New Supplier" to get started.</p>
                </div>
            </EmptyDataTemplate>
        </asp:GridView>
    </div>

    <!-- Supplier Modal -->
    <asp:Panel ID="supplierModal" runat="server" CssClass="modal">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <asp:Label ID="lblFormTitle" runat="server" CssClass="formTitle" Text="Add New Supplier" />
                    <button type="button" class="modal-close" onclick="closeSupplierModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfSupplierId" runat="server" />
                    <div class="form-row">
                        <div class="form-group">
                            <label for="txtSupName">Supplier Name <span style="color: red;">*</span></label>
                            <asp:TextBox ID="txtSupName" runat="server" CssClass="form-control" placeholder="Enter supplier name" />
                            <asp:RequiredFieldValidator ID="rfvSupName" runat="server" ControlToValidate="txtSupName" ErrorMessage="Supplier name is required" ForeColor="Red" Display="Dynamic" />
                        </div>
                        <div class="form-group">
                            <label for="txtSupContactPer">Contact Person <span style="color: red;">*</span></label>
                            <asp:TextBox ID="txtSupContactPer" runat="server" CssClass="form-control" placeholder="Enter contact person" />
                            <asp:RequiredFieldValidator ID="rfvContactPer" runat="server" ControlToValidate="txtSupContactPer" ErrorMessage="Contact person is required" ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label for="txtSupContactNo">Contact Number <span style="color: red;">*</span></label>
                            <asp:TextBox ID="txtSupContactNo" runat="server" CssClass="form-control" placeholder="+63 XXX-XXXX" />
                            <asp:RequiredFieldValidator ID="rfvContactNo" runat="server" ControlToValidate="txtSupContactNo" ErrorMessage="Contact number is required" ForeColor="Red" Display="Dynamic" />
                        </div>
                        <div class="form-group">
                            <label for="txtSupEmail">Email</label>
                            <asp:TextBox ID="txtSupEmail" runat="server" CssClass="form-control" placeholder="email@example.com" />
                            <asp:RegularExpressionValidator ID="revEmail" runat="server" ControlToValidate="txtSupEmail" ErrorMessage="Invalid email format" ValidationExpression="^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$" ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="txtSupAddress">Address <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtSupAddress" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Enter full address" />
                        <asp:RequiredFieldValidator ID="rfvAddress" runat="server" ControlToValidate="txtSupAddress" ErrorMessage="Address is required" ForeColor="Red" Display="Dynamic" />
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeSupplierModal()">Cancel</button>
                    <asp:Button ID="btnSaveSupplier" runat="server" CssClass="btn btn-success" Text="Save Supplier" OnClick="btnSaveSupplier_Click" OnClientClick="saveSupplier(); return false;" />
                </div>
            </div>
        </div>
    </asp:Panel>

    <!-- Confirmation Modal -->
    <div id="confirmSaveSupplierModal" class="modal">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Confirm Save</h3>
                    <button type="button" class="modal-close" onclick="closeConfirmSaveSupplierModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <p>Are you sure you want to save this supplier?</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeConfirmSaveSupplierModal()">No</button>
                    <button type="button" class="btn btn-success" onclick="confirmSaveSupplier()">Yes, Save</button>
                </div>
            </div>
        </div>
    </div>
    <!-- Persistent Alert -->
    <div id="supplierAddedAlert" class="alert alert-success" style="display:none; position:fixed; top:0; left:0; right:0; z-index:3000; text-align:center; font-size:18px;">
        Supplier has been added successfully!
    </div>

    <script type="text/javascript">
        // --- Modal Functions ---
        function openSupplierModal(supplier) {
            var modal = document.getElementById('<%= supplierModal.ClientID %>');
            var formTitle = document.getElementById('<%= lblFormTitle.ClientID %>');
            var btnSaveSupplier = document.getElementById('<%= btnSaveSupplier.ClientID %>');
            var hfSupplierId = document.getElementById('<%= hfSupplierId.ClientID %>');
            var txtSupName = document.getElementById('<%= txtSupName.ClientID %>');
            var txtSupContactPer = document.getElementById('<%= txtSupContactPer.ClientID %>');
            var txtSupContactNo = document.getElementById('<%= txtSupContactNo.ClientID %>');
            var txtSupEmail = document.getElementById('<%= txtSupEmail.ClientID %>');
            var txtSupAddress = document.getElementById('<%= txtSupAddress.ClientID %>');
            modal.style.display = 'block';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            if (supplier) {
                formTitle.textContent = 'Edit Supplier';
                btnSaveSupplier.textContent = 'Update Supplier';
                hfSupplierId.value = supplier.SupplierID;
                txtSupName.value = supplier.SupName;
                txtSupContactPer.value = supplier.SupContactPer;
                txtSupContactNo.value = supplier.SupContactNo;
                txtSupEmail.value = supplier.SupEmail;
                txtSupAddress.value = supplier.SupAddress;
            } else {
                formTitle.textContent = 'Add New Supplier';
                btnSaveSupplier.textContent = 'Save Supplier';
                hfSupplierId.value = '';
                txtSupName.value = '';
                txtSupContactPer.value = '';
                txtSupContactNo.value = '';
                txtSupEmail.value = '';
                txtSupAddress.value = '';
            }
        }
        function closeSupplierModal() {
            var modal = document.getElementById('<%= supplierModal.ClientID %>');
            modal.classList.remove('show');
            modal.style.display = 'none';
            modal.style.pointerEvents = 'none';
            document.body.style.overflow = '';
            document.body.style.position = '';
            // Force reflow
            void(document.body.offsetHeight);
        }
        window.onclick = function(event) {
            var supplierModal = document.getElementById('<%= supplierModal.ClientID %>');
            if (event.target == supplierModal) {
                closeSupplierModal();
            }
        }
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeSupplierModal();
            }
        });

        // --- Confirmation Modal Functions ---
        function showConfirmSaveSupplierModal() {
            var modal = document.getElementById('confirmSaveSupplierModal');
            modal.style.display = 'block';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
        }
        function closeConfirmSaveSupplierModal() {
            var modal = document.getElementById('confirmSaveSupplierModal');
            modal.classList.remove('show');
            modal.style.display = 'none';
            document.body.style.overflow = '';
        }
        function showSupplierAddedAlert() {
            var alert = document.getElementById('supplierAddedAlert');
            alert.style.display = 'block';
            setTimeout(function() { alert.style.display = 'none'; }, 4000);
        }

        // --- AJAX CRUD Functions ---
        function showSupplierMessage(msg, type) {
            var el = document.getElementById('<%= pnlSupplierMessage.ClientID %>');
            var lblMessage = document.getElementById('<%= lblSupplierMessage.ClientID %>');
            lblMessage.textContent = msg;
            el.className = 'alert';
            el.style.display = 'block';
            if (type === 'success') el.classList.add('alert-success');
            else el.classList.add('alert-danger');
            setTimeout(function() { el.style.display = 'none'; }, 4000);
        }
        function loadSuppliers() {
            fetch('../Handlers/SupplierCrudHandler.ashx?action=get')
                .then(res => res.json())
                .then(data => {
                    if (data.success) renderSuppliersGrid(data.suppliers);
                    else showSupplierMessage('Failed to load suppliers', 'danger');
                })
                .catch(() => {
                    showSupplierMessage('Error loading suppliers', 'danger');
                });
        }
        function renderSuppliersGrid(suppliers) {
            var html = '<table class="table"><thead><tr>' +
                '<th>Supplier Name</th><th>Contact Person</th><th>Contact Number</th><th>Email</th><th>Address</th><th>Status</th><th>Actions</th></tr></thead><tbody>';
            if (!suppliers || suppliers.length === 0) {
                html += '<tr><td colspan="7" style="text-align:center; padding:40px; color:#666;">No suppliers found. Click "Add New Supplier" to get started.</td></tr>';
            } else {
                suppliers.forEach(function(s) {
                    html += '<tr>' +
                        '<td>' + (s.SupName || '') + '</td>' +
                        '<td>' + (s.SupContactPer || '') + '</td>' +
                        '<td>' + (s.SupContactNo || '') + '</td>' +
                        '<td>' + (s.SupEmail || '') + '</td>' +
                        '<td>' + (s.SupAddress || '') + '</td>' +
                        '<td><span class="status-badge ' + (s.IsActive ? 'status-active' : 'status-inactive') + '">' + (s.IsActive ? 'Active' : 'Inactive') + '</span></td>' +
                        '<td>' +
                            '<button class="btn btn-warning" onclick=\'editSupplier(' + JSON.stringify(encodeURIComponent(JSON.stringify(s))) + ')\'>Edit</button> ' +
                            '<button class="btn btn-danger" onclick="deleteSupplier(\'' + s.SupplierID + '\')">Delete</button>' +
                        '</td>' +
                    '</tr>';
                });
            }
            html += '</tbody></table>';
            document.getElementById('suppliersGridContainer').innerHTML = html;
        }
        // Intercept Save button to show confirmation modal
        function saveSupplier() {
            showConfirmSaveSupplierModal();
        }
        // Actual save logic after confirmation
        function confirmSaveSupplier() {
            closeConfirmSaveSupplierModal();
            var btnSaveSupplier = document.getElementById('<%= btnSaveSupplier.ClientID %>');
            btnSaveSupplier.disabled = true;
            btnSaveSupplier.textContent = 'Processing...';
            var hfSupplierId = document.getElementById('<%= hfSupplierId.ClientID %>');
            var txtSupName = document.getElementById('<%= txtSupName.ClientID %>');
            var txtSupContactPer = document.getElementById('<%= txtSupContactPer.ClientID %>');
            var txtSupContactNo = document.getElementById('<%= txtSupContactNo.ClientID %>');
            var txtSupEmail = document.getElementById('<%= txtSupEmail.ClientID %>');
            var txtSupAddress = document.getElementById('<%= txtSupAddress.ClientID %>');
            var id = hfSupplierId.value;
            var data = {
                SupName: txtSupName.value,
                SupContactPer: txtSupContactPer.value,
                SupContactNo: txtSupContactNo.value,
                SupEmail: txtSupEmail.value,
                SupAddress: txtSupAddress.value
            };
            var action = id ? 'update' : 'add';
            var params = new URLSearchParams(data);
            if (id) params.append('SupplierID', id);
            fetch('../Handlers/SupplierCrudHandler.ashx?action=' + action, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params.toString()
            })
            .then(res => res.json())
            .then(result => {
                if (result.success) {
                    // Store success message in sessionStorage
                    sessionStorage.setItem('supplierMessage', (action === 'add' ? 'Added' : 'Updated') + ' successfully!');
                    sessionStorage.setItem('supplierMessageType', 'success');
                    
                    // Refresh the page to show the new supplier
                    window.location.reload();
                } else {
                    btnSaveSupplier.disabled = false;
                    btnSaveSupplier.textContent = id ? 'Update Supplier' : 'Save Supplier';
                    closeSupplierModal();
                    showSupplierMessage(result.message || 'Operation failed', 'danger');
                }
            })
            .catch(() => {
                btnSaveSupplier.disabled = false;
                btnSaveSupplier.textContent = id ? 'Update Supplier' : 'Save Supplier';
                closeSupplierModal();
                showSupplierMessage('Error saving supplier', 'danger');
            });
        }
        function editSupplier(supplierJson) {
            var supplier = JSON.parse(decodeURIComponent(supplierJson));
            openSupplierModal(supplier);
        }
        function deleteSupplier(id) {
            var deleteBtn = document.querySelector('.btn-danger[onclick^="deleteSupplier"]');
            if (!confirm('Are you sure you want to delete this supplier?')) return;
            if (deleteBtn) deleteBtn.disabled = true;
            fetch('../Handlers/SupplierCrudHandler.ashx?action=delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'SupplierID=' + encodeURIComponent(id)
            })
            .then(res => res.json())
            .then(result => {
                if (deleteBtn) deleteBtn.disabled = false;
                if (result.success) {
                    showSupplierMessage('Deleted successfully!', 'success');
                    loadSuppliers();
                } else {
                    showSupplierMessage(result.message || 'Delete failed', 'danger');
                }
            })
            .catch(() => {
                if (deleteBtn) deleteBtn.disabled = false;
                showSupplierMessage('Error deleting supplier', 'danger');
            });
        }
        // Initial load
        document.addEventListener('DOMContentLoaded', function() {
            // Check for success message from sessionStorage
            var message = sessionStorage.getItem('supplierMessage');
            var messageType = sessionStorage.getItem('supplierMessageType');
            if (message) {
                showSupplierMessage(message, messageType);
                sessionStorage.removeItem('supplierMessage');
                sessionStorage.removeItem('supplierMessageType');
                if (messageType === 'success') {
                    showSupplierAddedAlert();
                }
            }
            
            // Load suppliers
            loadSuppliers();
        });
    </script>
</asp:Content>
