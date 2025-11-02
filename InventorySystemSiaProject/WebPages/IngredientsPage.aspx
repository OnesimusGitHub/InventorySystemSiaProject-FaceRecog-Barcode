<%@ Page Title="Ingredients Management" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="IngredientsPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.IngredientsPage" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Ingredients Management -
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/productinformation.css" rel="stylesheet" />
    <style>
        .dashboard-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
            background: #ffc107;
            color: #333;
        }

        .btn-danger {
            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
            color: white;
        }

        .btn-secondary {
            background: #6c757d;
            color: white;
        }

        .table-container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            overflow: hidden;
        }

        .table {
            width: 100%;
            border-collapse: collapse;
        }

        .table thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .table th {
            padding: 16px;
            text-align: left;
            font-weight: 600;
            font-size: 14px;
        }

        .table td {
            padding: 14px 16px;
            border-bottom: 1px solid #f0f0f0;
            font-size: 14px;
        }

        .table tbody tr:hover {
            background: #f8f9fa;
        }

        .table tbody tr:last-child td {
            border-bottom: none;
        }

        .status-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }

        .status-active {
            background: #d4edda;
            color: #155724;
        }

        .status-inactive {
            background: #f8d7da;
            color: #721c24;
        }

        .status-low {
            background: #fff3cd;
            color: #856404;
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
        <h1 class="dashboard-title">?? Ingredients Management</h1>
        <p class="dashboard-subtitle">Manage raw materials and ingredient inventory</p>
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
                ?<asp:Label ID="lblTotalValue" runat="server" Text="0.00"></asp:Label>
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
                        ?<%# String.Format("{0:N2}", Eval("CostPerUnit")) %>
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
                        ?<%# String.Format("{0:N2}", Eval("TotalValue")) %>
                    </ItemTemplate>
                </asp:TemplateField>

                <asp:BoundField DataField="Supplier" HeaderText="Supplier" />
                
                <asp:TemplateField HeaderText="Status">
                    <ItemTemplate>
                        <%# GetStatusBadge((bool)Eval("IsLowStock"), (bool)Eval("IsActive")) %>
                    </ItemTemplate>
                </asp:TemplateField>

                <asp:TemplateField HeaderText="Actions">
                    <ItemTemplate>
                        <asp:Button ID="btnEdit" runat="server" Text="Edit" 
                            CommandName="EditIngredient" CommandArgument='<%# Eval("Id") %>'
                            CssClass="btn btn-warning" CausesValidation="false"
                            style="padding: 8px 16px; font-size: 12px; margin-right: 5px;" />
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
                        <label>Cost Per Unit (?) <span style="color: red;">*</span></label>
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
                <asp:Button ID="btnSaveIngredient" runat="server" Text="Save Ingredient" 
                    CssClass="btn btn-success" OnClick="btnSaveIngredient_Click" 
                    ValidationGroup="IngredientValidation" />
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function openAddModal() {
            document.getElementById('ingredientModal').classList.add('show');
            document.body.style.overflow = 'hidden';
        }

        function closeModal() {
            document.getElementById('ingredientModal').classList.remove('show');
            document.body.style.overflow = '';
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
            var modal = document.getElementById('ingredientModal');
            if (event.target == modal) {
                closeModal();
            }
        }

        // Close modal on Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeModal();
            }
        });
    </script>
</asp:Content>
