<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="ProductStock.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.PstockForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Product Stock - 
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/productinformation.css" rel="stylesheet" />
    <style>
        .tab-container {
            margin: 20px 0;
        }
        .tab-buttons {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #a64d79;
        }
        .tab-btn {
            padding: 12px 24px;
            background: #f5f5f5;
            border: none;
            border-radius: 8px 8px 0 0;
            cursor: pointer;
            font-size: 16px;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        .tab-btn.active {
            background: #a64d79;
            color: white;
        }
        .tab-btn:hover:not(.active) {
            background: #e0e0e0;
        }
        .tab-content {
            display: none;
            padding: 20px;
            background: white;
            border-radius: 0 8px 8px 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .tab-content.active {
            display: block;
        }
        .form-container {
            background: #f9f9f9;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 15px;
        }
        .form-group {
            display: flex;
            flex-direction: column;
        }
        .form-group label {
            font-weight: 600;
            margin-bottom: 5px;
            color: #333;
        }
        .form-control {
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        .form-control:focus {
            outline: none;
            border-color: #a64d79;
            box-shadow: 0 0 0 2px rgba(166, 77, 121, 0.1);
        }
        .btn-container {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 20px;
        }
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        .btn-primary {
            background: #a64d79;
            color: white;
        }
        .btn-primary:hover {
            background: #8b3d66;
        }
        .btn-success {
            background: #28a745;
            color: white;
        }
        .btn-success:hover {
            background: #218838;
        }
        .btn-warning {
            background: #ffc107;
            color: #333;
        }
        .btn-warning:hover {
            background: #e0a800;
        }
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        .btn-danger:hover {
            background: #c82333;
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        .btn-secondary:hover {
            background: #5a6268;
        }
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .table th {
            background: #a64d79;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }
        .table td {
            padding: 10px 12px;
            border-bottom: 1px solid #ddd;
        }
        .table tr:hover {
            background: #f5f5f5;
        }
        .status-badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        .status-active {
            background: #d4edda;
            color: #155724;
        }
        .status-inactive {
            background: #f8d7da;
            color: #721c24;
        }
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 4px;
            font-weight: 500;
        }
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .alert-danger {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .alert-info {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
        }
        .modal.show {
            display: block;
        }
        .modal-dialog {
            position: relative;
            width: 90%;
            max-width: 800px;
            margin: 50px auto;
            animation: slideDown 0.3s;
        }
        .modal-content {
            background-color: #fefefe;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .modal-header {
            background: #a64d79;
            color: white;
            padding: 20px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .modal-header h3 {
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }
        .modal-close {
            background: none;
            border: none;
            color: white;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
            padding: 0;
            width: 30px;
            height: 30px;
            line-height: 28px;
            text-align: center;
            border-radius: 4px;
            transition: background 0.2s;
        }
        .modal-close:hover {
            background: rgba(255,255,255,0.2);
        }
        .modal-body {
            padding: 24px;
        }
        .modal-footer {
            background: #f5f5f5;
            padding: 16px 24px;
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            border-top: 1px solid #ddd;
        }
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        @keyframes slideDown {
            from { 
                opacity: 0;
                transform: translateY(-50px);
            }
            to { 
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <h1 class="dashboard-title">Inventory Management</h1>
    </div>

    <asp:Label ID="lblMessage" runat="server" CssClass="text-success" Visible="false"></asp:Label>
    
    <!-- Tab Navigation -->
    <div class="tab-container">
        <div class="tab-buttons">
            <button type="button" class="tab-btn active" onclick="switchTab('stock')">📦 Product Stock</button>
            <button type="button" class="tab-btn" onclick="switchTab('suppliers')">🏢 Suppliers</button>
        </div>

        <!-- Product Stock Tab -->
        <div id="stockTab" class="tab-content active">
            <h2>Product Stock Management</h2>
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
        </div>

        <!-- Suppliers Tab -->
        <div id="suppliersTab" class="tab-content">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h2>Supplier Management</h2>
                <button type="button" class="btn btn-success" onclick="openSupplierModal()">
                    <i class="fa fa-plus"></i> Add New Supplier
                </button>
            </div>
            
            <!-- Success/Error Message -->
            <asp:Panel ID="pnlSupplierMessage" runat="server" Visible="false" CssClass="alert">
                <asp:Label ID="lblSupplierMessage" runat="server"></asp:Label>
            </asp:Panel>

            <!-- Suppliers Grid -->
            <asp:GridView ID="gvSuppliers" runat="server" AutoGenerateColumns="False" CssClass="table" 
                OnRowCommand="gvSuppliers_RowCommand" DataKeyNames="SupplierID">
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
    </div>

    <!-- Supplier Modal -->
    <div id="supplierModal" class="modal">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>
                        <asp:Label ID="lblFormTitle" runat="server" Text="Add New Supplier"></asp:Label>
                    </h3>
                    <button type="button" class="modal-close" onclick="closeSupplierModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfSupplierId" runat="server" />
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="<%= txtSupName.ClientID %>">Supplier Name <span style="color: red;">*</span></label>
                            <asp:TextBox ID="txtSupName" runat="server" CssClass="form-control" placeholder="Enter supplier name" />
                            <asp:RequiredFieldValidator ID="rfvSupName" runat="server" 
                                ControlToValidate="txtSupName" ErrorMessage="Supplier name is required" 
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                        <div class="form-group">
                            <label for="<%= txtSupContactPer.ClientID %>">Contact Person <span style="color: red;">*</span></label>
                            <asp:TextBox ID="txtSupContactPer" runat="server" CssClass="form-control" placeholder="Enter contact person" />
                            <asp:RequiredFieldValidator ID="rfvContactPer" runat="server" 
                                ControlToValidate="txtSupContactPer" ErrorMessage="Contact person is required" 
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="<%= txtSupContactNo.ClientID %>">Contact Number <span style="color: red;">*</span></label>
                            <asp:TextBox ID="txtSupContactNo" runat="server" CssClass="form-control" placeholder="+63 XXX-XXXX" />
                            <asp:RequiredFieldValidator ID="rfvContactNo" runat="server" 
                                ControlToValidate="txtSupContactNo" ErrorMessage="Contact number is required" 
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                        <div class="form-group">
                            <label for="<%= txtSupEmail.ClientID %>">Email</label>
                            <asp:TextBox ID="txtSupEmail" runat="server" CssClass="form-control" placeholder="email@example.com" TextMode="Email" />
                            <asp:RegularExpressionValidator ID="revEmail" runat="server" 
                                ControlToValidate="txtSupEmail" ErrorMessage="Invalid email format" 
                                ValidationExpression="^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$" 
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="<%= txtSupAddress.ClientID %>">Address <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtSupAddress" runat="server" CssClass="form-control" 
                            TextMode="MultiLine" Rows="3" placeholder="Enter full address" />
                        <asp:RequiredFieldValidator ID="rfvAddress" runat="server" 
                            ControlToValidate="txtSupAddress" ErrorMessage="Address is required" 
                            ForeColor="Red" Display="Dynamic" />
                    </div>
                </div>
                <div class="modal-footer">
                    <asp:Button ID="btnCancelSupplier" runat="server" Text="Cancel" 
                        CssClass="btn btn-secondary" OnClick="btnCancelSupplier_Click" CausesValidation="false" 
                        OnClientClick="closeSupplierModal(); return false;" />
                    <asp:Button ID="btnSaveSupplier" runat="server" Text="Save Supplier" 
                        CssClass="btn btn-success" OnClick="btnSaveSupplier_Click" />
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function switchTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(function(tab) {
                tab.classList.remove('active');
            });
            
            // Remove active class from all buttons
            document.querySelectorAll('.tab-btn').forEach(function(btn) {
                btn.classList.remove('active');
            });
            
            // Show selected tab and activate button
            if (tabName === 'stock') {
                document.getElementById('stockTab').classList.add('active');
                document.querySelectorAll('.tab-btn')[0].classList.add('active');
            } else if (tabName === 'suppliers') {
                document.getElementById('suppliersTab').classList.add('active');
                document.querySelectorAll('.tab-btn')[1].classList.add('active');
            }
        }

        function openSupplierModal() {
            document.getElementById('supplierModal').classList.add('show');
            document.body.style.overflow = 'hidden'; // Prevent background scrolling
        }

        function closeSupplierModal() {
            document.getElementById('supplierModal').classList.remove('show');
            document.body.style.overflow = ''; // Restore scrolling
        }

        // Close modal when clicking outside of it
        window.onclick = function(event) {
            var modal = document.getElementById('supplierModal');
            if (event.target == modal) {
                closeSupplierModal();
            }
        }

        // Close modal on Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeSupplierModal();
            }
        });
    </script>
</asp:Content>
