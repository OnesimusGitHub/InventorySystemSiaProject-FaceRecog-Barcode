<%@ Page Title="Ingredients Management" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="IngredientsPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.IngredientsPage" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Ingredients Management -
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/productinformation.css" rel="stylesheet" />
    <style>
        .dashboard-header {
            background: #a86d6a;
            color: white;
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .dashboard-title {
            font-size: 32px;
            font-weight: 700;
            margin: 0 0 10px 0;
            color:white;
        }
        
        .dashboard-subtitle {
            font-size: 16px;
            opacity: 0.9;
            margin: 0;
        }

        .toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            padding: 20px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .toolbar-left {
            display: flex;
            gap: 15px;
            align-items: center;
            flex: 1;
        }

        .search-box {
            position: relative;
            flex: 1;
            max-width: 400px;
        }

        .search-box i {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #999;
        }

        .search-box input {
            width: 100%;
            padding: 12px 15px 12px 45px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .search-box input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
        }

        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-primary {
            background: #a86d6a;
            color: white;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
        }

        .btn-success {
            background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(40, 167, 69, 0.3);
        }

        .btn-warning {
            background: linear-gradient(135deg, #C97B7B 0%, #B66B6B 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(201, 123, 123, 0.3);
        }

        .btn-warning:hover {
            background: linear-gradient(135deg, #B66B6B 0%, #A35B5B 100%);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(201, 123, 123, 0.4);
        }

        .btn-danger {
            background: linear-gradient(135deg, #6c757d 0%, #5a6268 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(108, 117, 125, 0.3);
        }

        .btn-danger:hover {
            background: linear-gradient(135deg, #5a6268 0%, #4e555b 100%);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(108, 117, 125, 0.4);
        }

        .btn-secondary {
            background: #6c757d;
            color: white;
        }

        .table-container {
            background: white;
            border-radius: 16px; /* Increased for more modern look */
            box-shadow: 0 4px 24px rgba(102,126,234,0.10);
            overflow-x: auto;
            margin-bottom: 30px;
            max-height: 500px; /* Set max height for scroll */
            overflow-y: auto; /* Enable vertical scroll */
        }

        .table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            background: white;
        }

        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .table th {
            padding: 18px 16px;
            text-align: left;
            font-weight: 700;
            font-size: 15px;
            border-bottom: 2px solid #e9ecef;
        }

        .table td {
            padding: 16px 16px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 14px;
            vertical-align: middle;
        }

        .table tbody tr:nth-child(even) {
            background: #f4f6fb;
        }

        .table tbody tr:hover {
            background: #e9ecef;
            transition: background 0.2s;
        }

        .table tbody tr:last-child td {
            border-bottom: none;
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 2000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.5);
            backdrop-filter: blur(4px);
        }

        .modal.show {
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .modal-dialog {
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 90%;
            max-width: 600px;
            animation: slideDown 0.3s ease-out;
        }

        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .modal-header {
            background: #C97B7B;
            color: white;
            padding: 24px 30px;
            border-radius: 16px 16px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .modal-header h3 {
            margin: 0;
            font-size: 24px;
            font-weight: 700;
        }

        .modal-close {
            background: rgba(255,255,255,0.2);
            border: none;
            color: white;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
        }

        .modal-close:hover {
            background: rgba(255,255,255,0.3);
            transform: rotate(90deg);
        }

        .modal-body {
            padding: 30px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }

        .form-control {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .form-control:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        .modal-footer {
            padding: 20px 30px;
            background: #f8f9fa;
            border-radius: 0 0 16px 16px;
            display: flex;
            gap: 12px;
            justify-content: flex-end;
        }

        .stats-bar {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: white;
            padding: 24px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
        }

        .stat-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 4px 16px rgba(0,0,0,0.12);
        }

        .stat-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            margin-bottom: 12px;
        }

        .stat-label {
            font-size: 13px;
            color: #6c757d;
            margin-bottom: 4px;
        }

        .stat-value {
            font-size: 28px;
            font-weight: 700;
            color: #333;
        }

        .alert {
            padding: 16px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
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

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }

        .empty-state i {
            font-size: 64px;
            color: #dee2e6;
            margin-bottom: 20px;
        }

        .empty-state h3 {
            font-size: 20px;
            color: #495057;
            margin-bottom: 10px;
        }

        .empty-state p {
            color: #6c757d;
            margin-bottom: 20px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="dashboard-header">
        <h1 class="dashboard-title"> Ingredients Management</h1> 
        <p class="dashboard-subtitle"></p>
    </div>

    <!-- Success/Error Messages -->
    <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="alert">
        <asp:Label ID="lblMessage" runat="server"></asp:Label>
    </asp:Panel>

    <!-- Statistics Bar -->
    <div class="stats-bar">
        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                <i class="fa fa-flask"></i>
            </div>
            <div class="stat-label">Total Ingredients</div>
            <div class="stat-value">
                <asp:Label ID="lblTotalIngredients" runat="server" Text="0"></asp:Label>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #ffc107 0%, #ff9800 100%); color: white;">
                <i class="fa fa-exclamation-triangle"></i>
            </div>
            <div class="stat-label">Low Stock Items</div>
            <div class="stat-value" style="color: #ffc107;">
                <asp:Label ID="lblLowStockCount" runat="server" Text="0"></asp:Label>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%); color: white;">
                <i class="fa fa-dollar-sign"></i>
            </div>
            <div class="stat-label">Total Inventory Value</div>
            <div class="stat-value" style="color: #28a745;">
                ₱<asp:Label ID="lblTotalValue" runat="server" Text="0.00"></asp:Label>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon" style="background: linear-gradient(135deg, #17a2b8 0%, #138496 100%); color: white;">
                <i class="fa fa-check-circle"></i>
            </div>
            <div class="stat-label">Active Ingredients</div>
            <div class="stat-value" style="color: #17a2b8;">
                <asp:Label ID="lblActiveCount" runat="server" Text="0"></asp:Label>
            </div>
        </div>
    </div>

    <!-- Toolbar -->
    <div class="toolbar">
        <div class="toolbar-left">
            <div class="search-box">
                <i class="fa fa-search"></i>
                <input type="text" id="txtSearch" placeholder="Search ingredients by name or supplier..." onkeyup="filterIngredients()" />
            </div>
        </div>
        <div>
            <button type="button" class="btn btn-primary" onclick="openAddModal()">
                <i class="fa fa-plus"></i> Add New Ingredient
            </button>
        </div>
    </div>

    <!-- Ingredients Table -->
    <div class="table-container">
        <asp:GridView ID="gvIngredients" runat="server" AutoGenerateColumns="False" CssClass="table"
            OnRowCommand="gvIngredients_RowCommand" DataKeyNames="Id" EmptyDataText="No ingredients found.">
            <Columns>
                <asp:BoundField DataField="IngredientName" HeaderText="Ingredient Name" />
                <asp:BoundField DataField="Unit" HeaderText="Unit" />
                
                <asp:TemplateField HeaderText="Cost Per Unit">
                    <ItemTemplate>
                        ₱<%# String.Format("{0:N2}", Eval("CostPerUnit")) %>
                    </ItemTemplate>
                </asp:TemplateField>
                
                <asp:TemplateField HeaderText="Current Stock">
                    <ItemTemplate>
                        <span style='<%# (bool)Eval("IsLowStock") ? "color: #dc3545; font-weight: 600;" : "" %>'>
                            <%# String.Format("{0:N0}", Eval("CurrentStock")) %>
                        </span>
                    </ItemTemplate>
                </asp:TemplateField>
                
                <asp:TemplateField HeaderText="Minimum Stock">
                    <ItemTemplate>
                        <%# String.Format("{0:N0}", Eval("MinimumStock")) %>
                    </ItemTemplate>
                </asp:TemplateField>

                <asp:TemplateField HeaderText="Total Value">
                    <ItemTemplate>
                        ₱<%# String.Format("{0:N2}", Eval("TotalValue")) %>
                    </ItemTemplate>
                </asp:TemplateField>

                <asp:TemplateField HeaderText="Supplier">
                    <ItemTemplate>
                        <%# GetSupplierName(Container.DataItem) %>
                    </ItemTemplate>
                </asp:TemplateField>
                
                <asp:TemplateField HeaderText="Status">
                    <ItemTemplate>
                        <%# GetStatusBadge((bool)Eval("IsLowStock"), (bool)Eval("IsActive")) %>
                    </ItemTemplate>
                </asp:TemplateField>

                <asp:TemplateField HeaderText="Actions">
                    <ItemTemplate>
                        <button type="button" class="btn btn-warning" 
                            onclick="editIngredient('<%# Eval("Id") %>'); return false;"
                            style="padding: 8px 16px; font-size: 12px; margin-right: 5px;">
                            Edit
                        </button>
                        <asp:Button ID="btnDelete" runat="server" Text="Delete" 
                            CommandName="DeleteIngredient" CommandArgument='<%# Eval("Id") %>'
                            CssClass="btn btn-danger" CausesValidation="false"
                            OnClientClick="return confirm('Are you sure you want to delete this ingredient?');"
                            style="padding: 8px 16px; font-size: 12px;" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
            <EmptyDataTemplate>
                <div class="empty-state">
                    <i class="fa fa-flask"></i>
                    <h3>No Ingredients Yet</h3>
                    <p>Start by adding your first ingredient to the inventory</p>
                    <button type="button" class="btn btn-primary" onclick="openAddModal()">
                        <i class="fa fa-plus"></i> Add First Ingredient
                    </button>
                </div>
            </EmptyDataTemplate>
        </asp:GridView>
    </div>

    <!-- Add/Edit Ingredient Modal -->
    <div id="ingredientModal" class="modal">
        <div class="modal-dialog">
            <div class="modal-header">
                <h3>
                    <asp:Label ID="lblModalTitle" runat="server" Text="Add New Ingredient"></asp:Label>
                </h3>
                <button type="button" class="modal-close" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <asp:HiddenField ID="hfIngredientId" runat="server" />
                

                 <div class="form-group">
                        <label>SKU <span style="color: red;">*</span></label>
                                <asp:TextBox ID="txtSKU" runat="server" CssClass="form-control" placeholder="e.g., ING-0001, VITC-100, etc." />
                         <asp:RequiredFieldValidator ID="rfvSKU" runat="server"
                           ControlToValidate="txtSKU" ErrorMessage="SKU is required"
                           ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                    </div>

                <div class="form-group">
                    <label>Ingredient Name <span style="color: red;">*</span></label>
                    <asp:TextBox ID="txtIngredientName" runat="server" CssClass="form-control" 
                        placeholder="e.g., Hyaluronic Acid, Vitamin C, etc." />
                    <asp:RequiredFieldValidator ID="rfvIngredientName" runat="server" 
                        ControlToValidate="txtIngredientName" ErrorMessage="Ingredient name is required" 
                        ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label>Unit <span style="color: red;">*</span></label>
                        <asp:DropDownList ID="txtUnit" runat="server" CssClass="form-control">
                            <asp:ListItem Value="">Select Unit</asp:ListItem>
                            <asp:ListItem Value="g">Grams (g)</asp:ListItem>
                            <asp:ListItem Value="kg">Kilograms (kg)</asp:ListItem>
                            <asp:ListItem Value="ml">Milliliters (ml)</asp:ListItem>
                            <asp:ListItem Value="L">Liters (L)</asp:ListItem>
                            <asp:ListItem Value="oz">Ounces (oz)</asp:ListItem>
                            <asp:ListItem Value="lb">Pounds (lb)</asp:ListItem>
                            <asp:ListItem Value="pcs">Pieces (pcs)</asp:ListItem>
                        </asp:DropDownList>
                        <asp:RequiredFieldValidator ID="rfvUnit" runat="server" 
                            ControlToValidate="txtUnit" ErrorMessage="Unit is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                    </div>

                    <div class="form-group">
                        <label>Cost Per Unit (₱) <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtCostPerUnit" runat="server" CssClass="form-control" 
                            TextMode="Number" step="0.01" placeholder="0.00" />
                        <asp:RequiredFieldValidator ID="rfvCostPerUnit" runat="server" 
                            ControlToValidate="txtCostPerUnit" ErrorMessage="Cost per unit is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                        <asp:RangeValidator ID="rvCostPerUnit" runat="server" 
                            ControlToValidate="txtCostPerUnit" MinimumValue="0.01" MaximumValue="999999" 
                            Type="Double" ErrorMessage="Cost must be greater than 0" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label>Current Stock <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtCurrentStock" runat="server" CssClass="form-control" 
                            TextMode="Number" step="0.01" placeholder="0.00" />
                        <asp:RequiredFieldValidator ID="rfvCurrentStock" runat="server" 
                            ControlToValidate="txtCurrentStock" ErrorMessage="Current stock is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                    </div>

                    <div class="form-group">
                        <label>Minimum Stock <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtMinimumStock" runat="server" CssClass="form-control" 
                            TextMode="Number" step="0.01" placeholder="0.00" />
                        <asp:RequiredFieldValidator ID="rfvMinimumStock" runat="server" 
                            ControlToValidate="txtMinimumStock" ErrorMessage="Minimum stock is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientValidation" />
                    </div>
                </div>

                <div class="form-group">
                    <label>Supplier</label>
                    <asp:DropDownList ID="ddlSupplier" runat="server" CssClass="form-control">
                    </asp:DropDownList>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">
                    <i class="fa fa-times"></i> Cancel
                </button>
                <button type="button" class="btn btn-success" onclick="showConfirmationModal()">
                    <i class="fa fa-check"></i> Save Ingredient
                </button>
            </div>
        </div>
    </div>

    <!-- Confirmation Modal -->
    <div id="confirmationModal" class="modal">
        <div class="modal-dialog" style="max-width: 500px;">
            <div class="modal-header">
                <h3>
                    <i class="fa fa-question-circle"></i> Confirm Action
                </h3>
                <button type="button" class="modal-close" onclick="closeConfirmationModal()">&times;</button>
            </div>
            <div class="modal-body">
                <p id="confirmationMessage" style="font-size: 16px; margin-bottom: 20px;">
                    Are you sure you want to save this ingredient?
                </p>
                <div id="confirmationDetails" style="background: #f8f9fa; padding: 15px; border-radius: 8px; font-size: 14px;">
                    <!-- Details will be populated by JavaScript -->
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeConfirmationModal()">
                    <i class="fa fa-times"></i> Cancel
                </button>
                <asp:Button ID="btnConfirmSave" runat="server" Text="Confirm & Save" 
                    CssClass="btn btn-success" OnClick="btnSaveIngredient_Click" 
                    ValidationGroup="IngredientValidation" />
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function openAddModal() {
            // Clear form for add mode
            clearForm();
            document.getElementById('<%= lblModalTitle.ClientID %>').innerText = 'Add New Ingredient';
            document.getElementById('<%= hfIngredientId.ClientID %>').value = '';
            document.getElementById('ingredientModal').classList.add('show');
            document.body.style.overflow = 'hidden';
        }

        function closeModal() {
            document.getElementById('ingredientModal').classList.remove('show');
            document.body.style.overflow = '';
        }

        function closeConfirmationModal() {
            document.getElementById('confirmationModal').classList.remove('show');
            document.body.style.overflow = 'hidden'; // Keep main modal open
        }

        function showConfirmationModal() {
            // Validate form first
            if (typeof (Page_ClientValidate) == 'function') {
                if (!Page_ClientValidate('IngredientValidation')) {
                    return false;
                }
            }

            // Get form values
            var ingredientName = document.getElementById('<%= txtIngredientName.ClientID %>').value;
            var unit = document.getElementById('<%= txtUnit.ClientID %>');
            var unitText = unit.options[unit.selectedIndex].text;
            var costPerUnit = document.getElementById('<%= txtCostPerUnit.ClientID %>').value;
            var currentStock = document.getElementById('<%= txtCurrentStock.ClientID %>').value;
            var minimumStock = document.getElementById('<%= txtMinimumStock.ClientID %>').value;
            var supplier = document.getElementById('<%= ddlSupplier.ClientID %>');
            var supplierText = supplier.options[supplier.selectedIndex].text;
            var ingredientId = document.getElementById('<%= hfIngredientId.ClientID %>').value;
            var sku = document.getElementById('<%= txtSKU.ClientID %>').value;


            // Determine action type
            var isEdit = ingredientId && ingredientId.trim() !== '';
            var actionType = isEdit ? 'update' : 'add';
            var actionText = isEdit ? 'Update' : 'Add';

            // Update confirmation message
            document.getElementById('confirmationMessage').innerHTML = 
                'Are you sure you want to <strong>' + actionText.toLowerCase() + '</strong> this ingredient?';

            // Build confirmation details
            var details = '<strong>Ingredient Details:</strong><br/><br/>' +
                '<strong>SKU:</strong> ' + sku + '<br/>' + // <-- Add this line

                          '<strong>Name:</strong> ' + ingredientName + '<br/>' +
                          '<strong>Unit:</strong> ' + unitText + '<br/>' +
                          '<strong>Cost Per Unit:</strong> ?' + parseFloat(costPerUnit).toFixed(2) + '<br/>' +
                          '<strong>Current Stock:</strong> ' + parseFloat(currentStock).toFixed(2) + '<br/>' +
                          '<strong>Minimum Stock:</strong> ' + parseFloat(minimumStock).toFixed(2) + '<br/>' +
                          '<strong>Supplier:</strong> ' + supplierText;

            document.getElementById('confirmationDetails').innerHTML = details;

            // Show confirmation modal
            document.getElementById('confirmationModal').classList.add('show');
            document.body.style.overflow = 'hidden';
        }

        function clearForm() {
            document.getElementById('<%= txtIngredientName.ClientID %>').value = '';
            document.getElementById('<%= txtUnit.ClientID %>').selectedIndex = 0;
            document.getElementById('<%= txtCostPerUnit.ClientID %>').value = '';
            document.getElementById('<%= txtCurrentStock.ClientID %>').value = '';
            document.getElementById('<%= txtMinimumStock.ClientID %>').value = '';
            document.getElementById('<%= ddlSupplier.ClientID %>').selectedIndex = 0;
            document.getElementById('<%= hfIngredientId.ClientID %>').value = '';
        }

        function editIngredient(ingredientId) {
            // Fetch ingredient data via AJAX
            fetch('/Handlers/GetIngredient.ashx?id=' + ingredientId)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Populate form fields
                        document.getElementById('<%= hfIngredientId.ClientID %>').value = data.data.id;
                        document.getElementById('<%= txtSKU.ClientID %>').value = data.data.SKU || '';
                        document.getElementById('<%= txtIngredientName.ClientID %>').value = data.data.ingredientName;
                        document.getElementById('<%= txtUnit.ClientID %>').value = data.data.unit;
                        document.getElementById('<%= txtCostPerUnit.ClientID %>').value = data.data.costPerUnit;
                        document.getElementById('<%= txtCurrentStock.ClientID %>').value = data.data.currentStock;
                        document.getElementById('<%= txtMinimumStock.ClientID %>').value = data.data.minimumStock;
                        
                        // Set supplier dropdown
                        var supplierDropdown = document.getElementById('<%= ddlSupplier.ClientID %>');
                        if (data.data.supplierId) {
                            supplierDropdown.value = data.data.supplierId;
                        } else {
                            supplierDropdown.selectedIndex = 0;
                        }
                        
                        // Update modal title
                        document.getElementById('<%= lblModalTitle.ClientID %>').innerText = 'Edit Ingredient';
                        
                        // Show modal
                        document.getElementById('ingredientModal').classList.add('show');
                        document.body.style.overflow = 'hidden';
                    } else {
                        alert('Failed to load ingredient: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error loading ingredient data');
                });
        }

        function filterIngredients() {
            var input = document.getElementById('txtSearch');
            var filter = input.value.toLowerCase();
            var table = document.getElementById('<%= gvIngredients.ClientID %>');
            var rows = table.getElementsByTagName('tr');

            for (var i = 1; i < rows.length; i++) {
                var row = rows[i];
                var cells = row.getElementsByTagName('td');
                var found = false;

                for (var j = 0; j < cells.length; j++) {
                    var cell = cells[j];
                    if (cell) {
                        var textValue = cell.textContent || cell.innerText;
                        if (textValue.toLowerCase().indexOf(filter) > -1) {
                            found = true;
                            break;
                        }
                    }
                }

                row.style.display = found ? '' : 'none';
            }
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            var ingredientModal = document.getElementById('ingredientModal');
            var confirmModal = document.getElementById('confirmationModal');
            
            if (event.target == ingredientModal) {
                closeModal();
            } else if (event.target == confirmModal) {
                closeConfirmationModal();
            }
        }

        // Close modal on Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                var confirmModal = document.getElementById('confirmationModal');
                if (confirmModal.classList.contains('show')) {
                    closeConfirmationModal();
                } else {
                    closeModal();
                }
            }
        });

        // Close both modals after successful save
        function closeAllModals() {
            document.getElementById('confirmationModal').classList.remove('show');
            document.getElementById('ingredientModal').classList.remove('show');
            document.body.style.overflow = '';
        }
    </script>
</asp:Content>
