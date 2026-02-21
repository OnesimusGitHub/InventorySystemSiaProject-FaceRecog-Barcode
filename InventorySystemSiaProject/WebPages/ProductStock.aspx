<%@ Page Title="" Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ProductStock.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.PstockForm" Async="true" %>

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
            background: #DEC7C5;
            border: none;
            border-radius: 8px 8px 0 0;
            cursor: pointer;
            font-size: 16px;
            color: black;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        .tab-btn.active {
            background: #A86D6A;
            color: white;
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
            background: #A86D6A;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        .btn-primary {
            background: #A86D6A;
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
 border-collapse: separate;
 border-spacing: 0;
 margin-top: 16px;
 background: #fff;
 font-size: 14px;
 box-shadow: 0 2px 8px rgba(166,77,121,0.06);
 border-radius: 10px;
 overflow: hidden;
        }
        .table th {
             background: #A86D6A;
 color: #fff;
 padding: 10px 8px;
 text-align: left;
 font-weight: 600;
 font-size: 14px;
 border: none;
        }
        .table td {
            padding: 8px 8px;
border-bottom: 1px solid #f0e3ea;
vertical-align: middle;
background: #fff;
        }
        .table tr:hover {
             background: #f9f6f8;
        }

        .table tr:last-child td {
    border-bottom: none;
}
        .status-badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        .table .btn {
    padding: 6px 16px;
    font-size: 13px;
    border-radius: 6px;
    background: #a64d79;
    color: #fff;
    border: none;
    transition: background 0.2s;
    box-shadow: 0 2px 6px rgba(166,77,121,0.08);
}
        .table img {
    width: 48px;
    height: 48px;
    object-fit: cover;
    border-radius: 8px;
    box-shadow: 0 1px 4px rgba(166,77,121,0.08);
    background: #f5f5f5;
}
        .product-stock-table-scroll {
    max-height: 420px;
    overflow-y: auto;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(166,77,121,0.06);
       background: #fff;
   }
        .table .btn:hover {
    background: #8b3d66;
}
.table td, .table th {
    height: 56px;
}
        .status-active {
            background: #d4edda;
            color: #155724;
        }
        .status-inactive {
            background: #f8d7da;
            color: #721c24;
        }
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        .status-approved {
            background: #d1ecf1;
            color: #0c5460;
        }
        .status-approved-finance {
            background: #fff3cd;
            color: #856404;
        }
        .status-inprocess {
            background: #ffeeba;
            color: #856404;
        }
        .status-priority-urgent {
            background: #f8d7da;
            color: #721c24;
            font-weight: bold;
        }
        .status-priority-high {
            background: #fff3cd;
            color: #856404;
        }
        .status-delivered {
            background: #b6fcb6;
            color: #155724;
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
            z-index: 2000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
            pointer-events: none;
        }
        .modal.show {
            display: block;
            pointer-events: auto;
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
        <div class="tab-buttons" id="tabButtons">
            <button type="button" class="tab-btn active" id="tabBtnStock" onclick="handleTabSwitch('stock')">?? Product Stock</button>
            <button type="button" class="tab-btn" id="tabBtnIngredients" onclick="handleTabSwitch('ingredients')">?? Ingredient Stock</button>
            <button type="button" class="tab-btn" id="tabBtnSuppliers" onclick="handleTabSwitch('suppliers')">?? Suppliers</button>
            <button type="button" class="tab-btn" id="tabBtnRequests" onclick="handleTabSwitch('requests')">?? Stock Requests</button>
        </div>

        <!-- Product Stock Tab -->
        <div id="stockTab" class="tab-content active">
            <!-- Filter Bar for Product Stock -->
            <div class="form-row" style="display: flex; gap: 18px; align-items: flex-end; margin-bottom: 18px;">
                <div class="form-group" style="flex: 1; min-width: 180px;">
                    <label for="stockSearchInput">Search</label>
                    <input type="text" id="stockSearchInput" class="form-control" placeholder="Search product..." onkeyup="filterStockGrid()" />
                </div>
                <div class="form-group" style="flex: 1; min-width: 180px;">
                    <label for="stockCategoryDropdown">Category</label>
                    <select id="stockCategoryDropdown" class="form-control" onchange="fetchVariantsByCategory(this.value)">
                        <option value="">All Categories</option>
                        <option value="Skincare">Skincare</option>
                        <option value="Haircare">Haircare</option>
                        <option value="Makeup">Makeup</option>
                        <option value="Fragrance">Fragrance</option>
                        <option value="Body Care">Body care</option>
                    </select>
                </div>
                <div class="form-group" style="flex: 1; min-width: 180px;">
                    <label for="stockStatusDropdown">Stock Status</label>
                    <select id="stockStatusDropdown" class="form-control" onchange="filterStockGrid()">
                        <option value="">All Status</option>
                        <option value="low">Low Stock</option>
                        <option value="medium">Medium Stock</option>
                        <option value="need">Need Stocking</option>
                    </select>
                </div>
            </div>

            <div id="stockSummaryBar" style="margin-bottom: 18px; padding: 14px 18px; background: #f5f5f5; border-radius: 8px; display: flex; gap: 24px; align-items: center; font-size: 16px; font-weight: 500; color: #333; box-shadow: 0 1px 4px rgba(0,0,0,0.04);">
                <span>Total Stock: <span id="stockTotalCount" style="color:#a64d79; font-weight:bold;">0</span></span>
                <span>Low Stock: <span id="stockLowCount" style="color:#dc3545; font-weight:bold;">0</span></span>
                <span>Medium Stock: <span id="stockMediumCount" style="color:#ffc107; font-weight:bold;">0</span></span>
                <span>Need Stocking: <span id="stockZeroCount" style="color:#007bff; font-weight:bold;">0</span></span>
            </div>
            <div id="locationStockSummary" style="margin-bottom: 18px; padding: 10px 18px; background: #f5f5f5; border-radius: 8px; font-size: 15px; color: #333; display: flex; flex-wrap: wrap; gap: 18px;"></div>

            <h2>Product Stock Management</h2>
            <div class="product-stock-table-scroll">

            <asp:GridView ID="gvProducts" runat="server" AutoGenerateColumns="False" CssClass="table" OnRowCommand="gvProducts_RowCommand">
                <Columns>
                    <asp:TemplateField HeaderText="Image">
                        <ItemTemplate>
                            <asp:Image ID="imgVariant" runat="server"
                                       ImageUrl='<%# GetVariantImage(Eval("VariantImgUrls"), Eval("VariantImg")) %>'
                                       Width="80px" Height="80px" />
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:BoundField DataField="VariantName" HeaderText="Product" />
                    <asp:BoundField DataField="StockQuantity" HeaderText="Stock" />
                    <asp:BoundField DataField="Location" HeaderText="Location" />

                    <asp:TemplateField HeaderText="Status">
                        <ItemTemplate>
                            <asp:Label ID="lblStatus" runat="server" 
                                Text='<%# (Convert.ToBoolean(Eval("IsLowStock")) ? "Low Stock" : "In Stock") %>' 
                                ForeColor='<%# (Convert.ToBoolean(Eval("IsLowStock")) ? System.Drawing.Color.Red : System.Drawing.Color.Green) %>'>
                            </asp:Label>
                        </ItemTemplate>
                    </asp:TemplateField>

                </Columns>
            </asp:GridView>
                 </div>
        </div>

        <!-- Ingredient Stock Tab -->
        <div id="ingredientsTab" class="tab-content">
            <!-- Filter Bar for Ingredient Stock -->
            <div class="form-row" style="display: flex; gap: 18px; align-items: flex-end; margin-bottom: 18px;">
                <div class="form-group" style="flex: 1; min-width: 180px;">
                    <label for="ingredientSearchInput">Search</label>
                    <input type="text" id="ingredientSearchInput" class="form-control" placeholder="Search ingredient..." onkeyup="filterIngredientGrid()" />
                </div>
                <div class="form-group" style="flex: 1; min-width: 180px;">
                    <label for="ingredientStockStatusDropdown">Stock Status</label>
                    <select id="ingredientStockStatusDropdown" class="form-control" onchange="filterIngredientGrid()">
                        <option value="">All Status</option>
                        <option value="low">Low Stock</option>
                        <option value="ok">In Stock</option>
                    </select>
                </div>
            </div>

            <div id="ingredientSummaryBar" style="margin-bottom: 18px; padding: 14px 18px; background: #f5f5f5; border-radius: 8px; display: flex; gap: 24px; align-items: center; font-size: 16px; font-weight: 500; color: #333; box-shadow: 0 1px 4px rgba(0,0,0,0.04);">
                <span>Total Ingredients: <span id="ingredientTotalCount" style="color:#a64d79; font-weight:bold;">0</span></span>
                <span>Low Stock: <span id="ingredientLowCount" style="color:#dc3545; font-weight:bold;">0</span></span>
                <span>Total Value: ₱<span id="ingredientTotalValue" style="color:#28a745; font-weight:bold;">0.00</span></span>
            </div>

            <h2>Ingredient Stock Management</h2>
            <div class="product-stock-table-scroll">
                <table id="gvIngredients" class="table">
                    <thead>
                        <tr>
                            <th>Ingredient Name</th>
                            <th>Unit</th>
                            <th>Current Stock</th>
                            <th>Minimum Stock</th>
                            <th>Cost Per Unit</th>
                            <th>Total Value</th>
                            <th>Supplier</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Populated by JavaScript -->
                    </tbody>
                </table>
            </div>
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

        <!-- Stock Requests Tab -->
        <div id="requestsTab" class="tab-content">
            <h2>Stock Request Status</h2>
            
            <!-- Filter Panel -->
            <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin-bottom: 20px; display: flex; gap: 15px; align-items: flex-end;">
                <div class="form-group" style="flex: 1; margin-bottom: 0;">
                    <label>Filter by Status:</label>
                    <asp:DropDownList ID="ddlStatusFilter" runat="server" CssClass="form-control" AutoPostBack="true" OnSelectedIndexChanged="ddlStatusFilter_SelectedIndexChanged">
                        <asp:ListItem Value="" Text="All Status"></asp:ListItem>
                        <asp:ListItem Value="Pending" Text="Pending"></asp:ListItem>
                        <asp:ListItem Value="Approved by Finance" Text="Approved by Finance"></asp:ListItem>
                        <asp:ListItem Value="Approved" Text="Approved"></asp:ListItem>
                        <asp:ListItem Value="In Process" Text="In Process"></asp:ListItem>
                        <asp:ListItem Value="Rejected" Text="Rejected"></asp:ListItem>
                        <asp:ListItem Value="Completed" Text="Completed"></asp:ListItem>
                        <asp:ListItem Value="Delivered" Text="Delivered"></asp:ListItem>
                    </asp:DropDownList>
                </div>
                <div>
                    <asp:Button ID="btnRefreshRequests" runat="server" Text="?? Refresh" CssClass="btn btn-secondary" OnClick="btnRefreshRequests_Click" CausesValidation="false" />
                </div>
            </div>

            <!-- Request Status Summary Bar -->
            <div id="requestStatusSummaryBar" style="margin-bottom: 18px; padding: 14px 18px; background: #f5f5f5; border-radius: 8px; display: flex; gap: 24px; align-items: center; font-size: 16px; font-weight: 500; color: #333; box-shadow: 0 1px 4px rgba(0,0,0,0.04);">
                <span>Pending: <span id="statusCountPending" style="color:#ffc107; font-weight:bold;">0</span></span>
                <span>Approved: <span id="statusCountApproved" style="color:#28a745; font-weight:bold;">0</span></span>
                <span>In Process: <span id="statusCountInProcess" style="color:#007bff; font-weight:bold;">0</span></span>
                <span>Rejected: <span id="statusCountRejected" style="color:#dc3545; font-weight:bold;">0</span></span>
                <span>Completed: <span id="statusCountCompleted" style="color:#6c757d; font-weight:bold;">0</span></span>
                <span>Delivered: <span id="statusCountDelivered" style="color:#a64d79; font-weight:bold;">0</span></span>
            </div>

            <!-- Stock Requests Grid -->
            <asp:GridView ID="gvStockRequests" runat="server" AutoGenerateColumns="False" CssClass="table" 
                OnRowCommand="gvStockRequests_RowCommand" DataKeyNames="RequestID" EmptyDataText="No stock requests found.">
                <Columns>
                    <asp:TemplateField HeaderText="Request ID">
                        <ItemTemplate>
                            <strong><%# Eval("DisplayRequestID") %></strong>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Ingredient">
                        <ItemTemplate>
                            <%# Eval("IngredientName") ?? "N/A" %>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Supplier">
                        <ItemTemplate>
                            <%# Eval("SupplierName") ?? "N/A" %>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:BoundField DataField="QuantityRequested" HeaderText="Quantity" />

                    <asp:TemplateField HeaderText="Request Date">
                        <ItemTemplate>
                            <%# ((DateTime)Eval("RequestDate")).ToString("MMM dd, yyyy") %>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Expected Delivery">
                        <ItemTemplate>
                            <%# Eval("ExpectedDeliveryDate") != null && (DateTime?)Eval("ExpectedDeliveryDate") != null ? 
                                ((DateTime)Eval("ExpectedDeliveryDate")).ToString("MMM dd, yyyy") : 
                                "<span style='color: #999;'>Not specified</span>" %>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Requested By">
                        <ItemTemplate>
                            <%# Eval("RequestedBy") %>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Status">
                        <ItemTemplate>
                            <span class='status-badge <%# GetStatusClass(Eval("RequestStatus").ToString()) %>'>
                                <%# Eval("RequestStatus") %>
                            </span>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Priority">
                        <ItemTemplate>
                            <span class='status-badge <%# GetPriorityClass(Eval("Priority").ToString()) %>'>
                                <%# Eval("Priority") %>
                            </span>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:TemplateField HeaderText="Actions">
                        <ItemTemplate>
                            <asp:Button ID="btnViewDetails" runat="server" Text="View"
                                CommandName="ViewDetails" CommandArgument='<%# Eval("RequestID") %>'
                                CssClass="btn btn-primary" CausesValidation="false"
                                style="padding: 6px 12px; font-size: 12px; margin: 2px;"
                                OnClientClick='<%# "viewStockRequest(\"" + Eval("RequestID") + "\"); return false;" %>' />
                            
                            <asp:Button ID="btnApprove" runat="server" Text="? Approve" 
                                CommandName="ApproveRequest" CommandArgument='<%# Eval("RequestID") %>'
                                CssClass="btn btn-success" CausesValidation="false"
                                Visible='<%# Eval("RequestStatus").ToString() == "Pending" || Eval("RequestStatus").ToString() == "Approved by Finance" %>'
                                OnClientClick='<%# "openApprovalModal(\"" + Eval("RequestID") + "\"); return false;" %>'
                                style="padding: 6px 12px; font-size: 12px; margin: 2px;" />
                            
                            <asp:Button ID="btnReject" runat="server" Text="? Reject" 
                                CommandName="RejectRequest" CommandArgument='<%# Eval("RequestID") %>'
                                CssClass="btn btn-danger" CausesValidation="false"
                                Visible='<%# Eval("RequestStatus").ToString() == "Pending" || Eval("RequestStatus").ToString() == "Approved by Finance" %>'
                                style="padding: 6px 12px; font-size: 12px; margin: 2px;" />
                            
                            <asp:Button ID="btnComplete" runat="server" Text="? Complete" 
                                CommandName="CompleteRequest" CommandArgument='<%# Eval("RequestID") %>'
                                CssClass="btn btn-success" CausesValidation="false"
                                Visible='<%# Eval("RequestStatus").ToString() == "Approved" || Eval("RequestStatus").ToString() == "Approved by Supplier" %>'
                                OnClientClick="return confirm('Mark this request as completed? This will update the stock quantity.');"
                                style="padding: 6px 12px; font-size: 12px; margin: 2px;" />
                            
                            <select class="status-dropdown" data-requestid='<%# Eval("RequestID") %>' style="margin-left:8px; padding:4px 8px; border-radius:4px;">
                                <option value="">Change Status...</option>
                                <option value="In Process">In Process</option>
                                <option value="Completed">Completed</option>
                                <option value="Delivered">Delivered</option>
                            </select>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate>
                    <div style="text-align: center; padding: 40px; color: #666;">
                        <i class="fa fa-inbox" style="font-size: 48px; margin-bottom: 15px; display: block; color: #ddd;"></i>
                        <p>No stock requests found.</p>
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
                        <label for("<%= txtSupAddress.ClientID %>">Address <span style="color: red;">*</span></label>
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
                         />
                    <asp:Button ID="btnSaveSupplier" runat="server" Text="Save Supplier" 
                        CssClass="btn btn-success" OnClick="btnSaveSupplier_Click" />
                </div>
            </div>
        </div>
    </div>

    <!-- Request Details Modal -->
    <div id="detailsModal" class="modal">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>?? Stock Request Details</h3>
                    <button type="button" class="modal-close" onclick="closeDetailsModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <div style="background: #f0f4f8; padding: 20px; border-radius: 8px; border-left: 4px solid #667eea;">
                        <div style="display: grid; grid-template-columns: 180px 1fr; gap: 12px; font-size: 14px;">
                            <div style="font-weight: 600; color: #555;">Request ID:</div>
                            <div id="detailRequestID" style="color: #333; font-weight: bold;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Product Name:</div>
                            <div id="detailProductName" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Supplier:</div>
                            <div id="detailSupplier" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Quantity Requested:</div>
                            <div id="detailQuantity" style="color: #333; font-weight: 600;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Status:</div>
                            <div id="detailStatus" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Requested By:</div>
                            <div id="detailRequestedBy" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Request Date:</div>
                            <div id="detailRequestDate" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Expected Delivery:</div>
                            <div id="detailExpectedDelivery" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Current Stock:</div>
                            <div id="detailStockQuantity" style="color: #dc3545; font-weight: 600;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Instructions:</div>
                            <div id="detailInstructions" style="color: #333; font-style: italic;">-</div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeDetailsModal()">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Rejection Modal -->
    <div id="rejectModal" class="modal">
        <div class="modal-dialog" style="max-width: 500px;">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>? Reject Stock Request</h3>
                    <button type="button" class="modal-close" onclick="closeRejectModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfRequestIdToReject" runat="server" />
                    
                    <div class="form-group">
                        <label for="<%= txtRejectionReason.ClientID %>">Rejection Reason <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtRejectionReason" runat="server" CssClass="form-control" 
                            TextMode="MultiLine" Rows="4" 
                            placeholder="Please provide a reason for rejecting this stock request..." />
                        <asp:RequiredFieldValidator ID="rfvRejectionReason" runat="server" 
                            ControlToValidate="txtRejectionReason" ErrorMessage="Rejection reason is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="RejectRequest" />
                    </div>

                    <div style="background: #fff3cd; padding: 12px; border-radius: 6px; border-left: 4px solid #ffc107; margin-top: 15px;">
                        <div style="display: flex; align-items: center; gap: 8px; color: #856404; font-size: 13px;">
                            <i class="fa fa-exclamation-triangle"></i>
                            <span>The supplier will be notified of the rejection.</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeRejectModal()">Cancel</button>
                    <asp:Button ID="btnConfirmReject" runat="server" Text="Confirm Rejection" 
                        CssClass="btn btn-danger" OnClick="btnConfirmReject_Click" ValidationGroup="RejectRequest" />
                </div>
            </div>
        </div>
    </div>

    <!-- Approval Confirmation Modal -->
    <div id="approvalModal" class="modal">
        <div class="modal-dialog" style="max-width: 500px;">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>? Approve Stock Request</h3>
                    <button type="button" class="modal-close" onclick="closeApprovalModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfRequestIdToApprove" runat="server" />
                    
                    <div style="text-align: center; padding: 20px 0;">
                        <div style="width: 80px; height: 80px; background: #28a745; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; font-size: 48px; color: white;">
                            ?
                        </div>
                        <h4 style="margin-bottom: 15px; color: #333;">Approve this stock request?</h4>
                        <p style="color: #666; font-size: 14px; line-height: 1.6;">
                            This will send an email notification to the supplier with the request details and approval/rejection links.
                        </p>
                    </div>

                    <div style="background: #e8f5e9; padding: 12px; border-radius: 6px; border-left: 4px solid #28a745; margin-top: 15px;">
                        <div style="display: flex; align-items: center; gap: 8px; color: #155724; font-size: 13px;">
                            <i class="fa fa-info-circle"></i>
                            <span>The supplier will receive an email with this stock request.</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeApprovalModal()">Cancel</button>
                    <asp:Button ID="btnConfirmApprove" runat="server" Text="? Confirm Approval" 
                        CssClass="btn btn-success" OnClick="btnConfirmApprove_Click" CausesValidation="false" />
                </div>
            </div>
        </div>
    </div>

    <!-- Stock Request Modal -->
    <div id="stockRequestModal" class="modal" style="display: none;">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>?? Request Stock from Supplier</h3>
                    <button type="button" class="modal-close" onclick="closeStockRequestModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfVariantId" runat="server" />
                    <asp:HiddenField ID="hfProductId" runat="server" />
                    <asp:HiddenField ID="hfSupplierId2" runat="server" />
                    
                    <!-- Product Information -->
                    <div style="background: #f0f4f8; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                        <h4 style="margin: 0 0 10px 0; color: #333; font-size: 16px;">Product Information</h4>
                        <div style="display: grid; grid-template-columns: 140px 1fr; gap: 8px; font-size: 14px;">
                            <div style="font-weight: 600; color: #555;">Product Name:</div>
                            <div id="reqProductName" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Current Stock:</div>
                            <div id="reqCurrentStock" style="color: #dc3545; font-weight: 600;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Minimum Stock:</div>
                            <div id="reqMinStock" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Supplier:</div>
                            <div id="reqSupplierName" style="color: #333;">-</div>
                        </div>
                    </div>

                    <!-- Request Form -->
                    <div class="form-group">
                        <label for="<%= txtRequestQuantity.ClientID %>">Requested Quantity <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtRequestQuantity" runat="server" CssClass="form-control" 
                            TextMode="Number" placeholder="Enter quantity to request" />
                        <asp:RequiredFieldValidator ID="rfvRequestQuantity" runat="server" 
                            ControlToValidate="txtRequestQuantity" ErrorMessage="Quantity is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="StockRequest" />
                        <asp:RangeValidator ID="rvRequestQuantity" runat="server" 
                            ControlToValidate="txtRequestQuantity" MinimumValue="1" MaximumValue="10000" 
                            Type="Integer" ErrorMessage="Quantity must be between 1 and 10000" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="StockRequest" />
                    </div>

                    <div class="form-group">
                        <label for="<%= txtExpectedDeliveryDate.ClientID %>">Expected Delivery Date (Optional)</label>
                        <asp:TextBox ID="txtExpectedDeliveryDate" runat="server" CssClass="form-control" 
                            TextMode="Date" />
                        <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
                            Specify your preferred delivery date for this stock request
                        </small>
                    </div>

                    <div class="form-group">
                        <label for="<%= txtRequestNotes.ClientID %>">Additional Notes (Optional)</label>
                        <asp:TextBox ID="txtRequestNotes" runat="server" CssClass="form-control" 
                            TextMode="MultiLine" Rows="4" 
                            placeholder="Enter any special requirements or other notes..." />
                    </div>

                    <!-- Email Preview -->
                    <div style="background: #e8f5e9; padding: 12px; border-radius: 6px; border-left: 4px solid #28a745; margin-top: 15px;">
                        <div style="display: flex; align-items: center; gap: 8px; color: #155724; font-size: 13px;">
                            <i class="fa fa-info-circle"></i>
                            <span>An email will be sent to the supplier with your stock request details.</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <asp:Button ID="btnCancelRequest" runat="server" Text="Cancel" 
                        CssClass="btn btn-secondary" OnClick="btnCancelRequest_Click" CausesValidation="false" 
                        OnClientClick="closeStockRequestModal(); return false;" />
                    <asp:Button ID="btnSendRequest" runat="server" Text="Send Request" 
                        CssClass="btn btnprimary" OnClick="btnSendRequest_Click" ValidationGroup="StockRequest" />
                </div>
            </div>
        </div>
    </div>

    <!-- Ingredient Stock Request Modal -->
    <div id="ingredientStockRequestModal" class="modal" style="display: none;">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>?? Request Ingredient Stock from Supplier</h3>
                    <button type="button" class="modal-close" onclick="closeIngredientStockRequestModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <asp:HiddenField ID="hfIngredientId" runat="server" />
                    <asp:HiddenField ID="hfIngredientSupplierId" runat="server" />
                    
                    <!-- Ingredient Information -->
                    <div style="background: #f0f4f8; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #667eea;">
                        <h4 style="margin: 0 0 10px 0; color: #333; font-size: 16px;">Ingredient Information</h4>
                        <div style="display: grid; grid-template-columns: 140px 1fr; gap: 8px; font-size: 14px;">
                            <div style="font-weight: 600; color: #555;">Ingredient Name:</div>
                            <div id="reqIngredientName" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Unit:</div>
                            <div id="reqIngredientUnit" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Current Stock:</div>
                            <div id="reqIngredientCurrentStock" style="color: #dc3545; font-weight: 600;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Minimum Stock:</div>
                            <div id="reqIngredientMinStock" style="color: #333;">-</div>
                            
                            <div style="font-weight: 600; color: #555;">Supplier:</div>
                            <div id="reqIngredientSupplierName" style="color: #333;">-</div>
                        </div>
                    </div>

                    <!-- Request Form -->
                    <div class="form-group">
                        <label for="<%= txtIngredientRequestQuantity.ClientID %>">Requested Quantity <span style="color: red;">*</span></label>
                        <asp:TextBox ID="txtIngredientRequestQuantity" runat="server" CssClass="form-control" 
                            TextMode="Number" step="0.01" placeholder="Enter quantity to request" />
                        <asp:RequiredFieldValidator ID="rfvIngredientRequestQuantity" runat="server" 
                            ControlToValidate="txtIngredientRequestQuantity" ErrorMessage="Quantity is required" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientStockRequest" />
                        <asp:RangeValidator ID="rvIngredientRequestQuantity" runat="server" 
                            ControlToValidate="txtIngredientRequestQuantity" MinimumValue="0.01" MaximumValue="99999" 
                            Type="Double" ErrorMessage="Quantity must be between 0.01 and 99999" 
                            ForeColor="Red" Display="Dynamic" ValidationGroup="IngredientStockRequest" />
                    </div>

                    <div class="form-group">
                        <label for="<%= txtIngredientExpectedDeliveryDate.ClientID %>">Expected Delivery Date (Optional)</label>
                        <asp:TextBox ID="txtIngredientExpectedDeliveryDate" runat="server" CssClass="form-control" 
                            TextMode="Date" />
                        <small style="color: #666; font-size: 12px; margin-top: 5px; display: block;">
                            Specify your preferred delivery date for this ingredient stock request
                        </small>
                    </div>

                    <div class="form-group">
                        <label for="<%= txtIngredientRequestNotes.ClientID %>">Additional Notes (Optional)</label>
                        <asp:TextBox ID="txtIngredientRequestNotes" runat="server" CssClass="form-control" 
                            TextMode="MultiLine" Rows="4" 
                            placeholder="Enter any special requirements or other notes..." />
                    </div>

                    <!-- Email Preview -->
                    <div style="background: #e8f5e9; padding: 12px; border-radius: 6px; border-left: 4px solid #28a745; margin-top: 15px;">
                        <div style="display: flex; align-items: center; gap: 8px; color: #155724; font-size: 13px;">
                            <i class="fa fa-info-circle"></i>
                            <span>An email will be sent to the supplier with your ingredient stock request details.</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <asp:Button ID="btnCancelIngredientRequest" runat="server" Text="Cancel" 
                        CssClass="btn btn-secondary" OnClick="btnCancelIngredientRequest_Click" CausesValidation="false" 
                        OnClientClick="closeIngredientStockRequestModal(); return false;" />
                    <asp:Button ID="btnSendIngredientRequest" runat="server" Text="Send Request" 
                        CssClass="btn btn-primary" OnClick="btnSendIngredientRequest_Click" ValidationGroup="IngredientStockRequest" />
                </div>
            </div>
        </div>
    </div>

    <!-- Debugging Test Modal (For development purposes) -->
    <div id="testModal" class="modal" style="display:none;">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h3>Debug Test Modal</h3>
                    <button type="button" class="modal-close" onclick="closeTestModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <p>This is a test modal for debugging purposes.</p>
                    <button class="btn btn-primary" onclick="closeTestModal()">Close Test Modal</button>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        // Test function to verify modal can be shown
        function testModal() {
            console.log('?? Testing modal display');
            var modal = document.getElementById('stockRequestModal');
            if (!modal) {
                console.error('? Modal element not found!');
                return;
            }
            console.log('? Modal element found:', modal);
            modal.style.display = 'block';
            modal.style.pointerEvents = 'auto';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            console.log('? Modal should now be visible');
        }

        // CRITICAL: Ensure page is fully interactive on load
        document.addEventListener('DOMContentLoaded', function() {
            console.log('? ProductStock page loaded - ensuring full interactivity');
            // Test if modal exists
            var stockModal = document.getElementById('stockRequestModal');
            if (stockModal) {
                console.log('? Stock Request Modal found in DOM');
            } else {
                console.error('? Stock Request Modal NOT found in DOM');
            }
            // Force remove any blocking overlays or modals
            document.body.style.overflow = '';
            document.body.style.position = '';
            document.body.style.pointerEvents = '';
            // Ensure all modals are hidden
            var modals = document.querySelectorAll('.modal, .modal-overlay');
            modals.forEach(function(modal) {
                modal.style.display = 'none';
                modal.style.pointerEvents = 'none';
                modal.classList.remove('show');
            });
            console.log('? Page interactivity restored');
            
            // --- Check for tab query parameter ---
            var urlParams = new URLSearchParams(window.location.search);
            var tabParam = urlParams.get('tab');
            if (tabParam) {
                console.log('?? Tab parameter detected:', tabParam);
                handleTabSwitch(tabParam);
            } else {
                // Default: Initialize product grid on stock tab
                fetchVariantsByCategory('');
            }
        });
    
        function switchTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(function(tab) {
                tab.classList.remove('active');
            });
            
            // Remove active class from all buttons
            document.querySelectorAll('.tab-btn').forEach(function(btn) {
                btn.classList.remove('active');
            });
            
            // Get tab button elements
            var tabBtnStock = document.getElementById('tabBtnStock');
            var tabBtnIngredients = document.getElementById('tabBtnIngredients');
            var tabBtnSuppliers = document.getElementById('tabBtnSuppliers');
            var tabBtnRequests = document.getElementById('tabBtnRequests');
            
            // Show selected tab and activate button
            if (tabName === 'stock') {
                document.getElementById('stockTab').classList.add('active');
                tabBtnStock.classList.add('active');
                // Hide Suppliers and Stock Requests tabs, show Product Stock and Ingredient Stock
                tabBtnStock.style.display = '';
                tabBtnIngredients.style.display = '';
                tabBtnSuppliers.style.display = 'none';
                tabBtnRequests.style.display = 'none';
            } else if (tabName === 'ingredients') {
                document.getElementById('ingredientsTab').classList.add('active');
                tabBtnIngredients.classList.add('active');
                // Hide Suppliers and Stock Requests tabs, show Product Stock and Ingredient Stock
                tabBtnStock.style.display = '';
                tabBtnIngredients.style.display = '';
                tabBtnSuppliers.style.display = 'none';
                tabBtnRequests.style.display = 'none';
            } else if (tabName === 'suppliers') {
                document.getElementById('suppliersTab').classList.add('active');
                tabBtnSuppliers.classList.add('active');
                // Hide the first three tabs, show only Suppliers
                tabBtnStock.style.display = 'none';
                tabBtnIngredients.style.display = 'none';
                tabBtnRequests.style.display = 'none';
                tabBtnSuppliers.style.display = '';
            } else if (tabName === 'requests') {
                document.getElementById('requestsTab').classList.add('active');
                tabBtnRequests.classList.add('active');
                // Hide Product Stock, Ingredient Stock, and Suppliers tabs, show only Stock Requests
                tabBtnStock.style.display = 'none';
                tabBtnIngredients.style.display = 'none';
                tabBtnSuppliers.style.display = 'none';
                tabBtnRequests.style.display = '';
            }
        }

        function handleTabSwitch(tabName) {
            console.log('🔄 Tab switch requested:', tabName);

            // Call switchTab to handle the UI
            switchTab(tabName);

            // Load appropriate data based on tab
            if (tabName === 'ingredients') {
                console.log('📦 Loading ingredients...');
                fetchIngredients();
            } else if (tabName === 'stock') {
                console.log('📦 Loading product stock...');
                fetchVariantsByCategory('');
            }
        }

        // ✅ ADD THIS FUNCTION - Closes the stock request modal
        function closeStockRequestModal() {
            console.log('🔒 Closing stock request modal');
            var modal = document.getElementById('stockRequestModal');
            if (modal) {
                modal.classList.remove('show');
                modal.style.display = 'none';
                modal.style.pointerEvents = 'none';
            }
            document.body.style.overflow = '';
            document.body.style.position = '';
            void (document.body.offsetHeight);
            console.log('✅ Stock request modal closed');
        }

        // ✅ ADD THIS FUNCTION - View stock request details
        function viewStockRequest(requestId) {
            console.log('👁️ Viewing stock request:', requestId);

            if (!requestId) {
                alert('Request ID is missing');
                return;
            }

            // Open the details modal
            openDetailsModal();

            // Set loading state
            document.getElementById('detailRequestID').textContent = 'Loading...';
            document.getElementById('detailProductName').textContent = 'Loading...';
            document.getElementById('detailSupplier').textContent = 'Loading...';
            document.getElementById('detailQuantity').textContent = 'Loading...';
            document.getElementById('detailStatus').textContent = 'Loading...';
            document.getElementById('detailRequestedBy').textContent = 'Loading...';
            document.getElementById('detailRequestDate').textContent = 'Loading...';
            document.getElementById('detailExpectedDelivery').textContent = 'Loading...';
            document.getElementById('detailStockQuantity').textContent = 'Loading...';
            document.getElementById('detailInstructions').textContent = 'Loading...';

            // Build absolute URL
            var baseUrl = window.location.protocol + '//' + window.location.host;
            var handlerPath = '/Handlers/GetStockRequest.ashx';
            var fullUrl = baseUrl + handlerPath + '?id=' + encodeURIComponent(requestId);

            console.log('🔍 Fetching from URL:', fullUrl);

            fetch(fullUrl)
                .then(function (response) {
                    console.log('📡 Response status:', response.status, response.statusText);

                    if (!response.ok) {
                        return response.text().then(function (text) {
                            console.error('❌ Server error response:', text);
                            throw new Error('Server returned ' + response.status + ': ' + response.statusText);
                        });
                    }

                    return response.json();
                })
                .then(function (data) {
                    console.log('✅ Stock request data received:', data);

                    if (data.success && data.request) {
                        var request = data.request;

                        // Populate modal with request details
                        document.getElementById('detailRequestID').textContent = request.DisplayRequestID || request.RequestID || 'N/A';
                        document.getElementById('detailProductName').textContent = request.ProductName || 'N/A';
                        document.getElementById('detailSupplier').textContent = request.SupplierName || 'N/A';
                        document.getElementById('detailQuantity').textContent = (request.QuantityRequested || 0) + ' units';
                        document.getElementById('detailStatus').innerHTML = '<span class="status-badge status-' +
                            (request.RequestStatus || 'pending').toLowerCase().replace(/ /g, '') + '">' +
                            (request.RequestStatus || 'Pending') + '</span>';
                        document.getElementById('detailRequestedBy').textContent = request.RequestedBy || 'N/A';
                        document.getElementById('detailRequestDate').textContent = formatDate(request.RequestDate);
                        document.getElementById('detailExpectedDelivery').textContent = request.ExpectedDeliveryDate ?
                            formatDate(request.ExpectedDeliveryDate) : 'Not specified';
                        document.getElementById('detailStockQuantity').textContent = (request.CurrentStockAtRequest || request.StockQuantity || 0) + ' units';
                        document.getElementById('detailInstructions').textContent = request.Instructions || 'No special instructions';

                    } else {
                        alert('Failed to load request details: ' + (data.message || 'Unknown error'));
                        closeDetailsModal();
                    }
                })
                .catch(function (error) {
                    console.error('❌ Error loading request details:', error);
                    alert('Error loading request details:\n\n' + error.message);
                    closeDetailsModal();
                });
        }

        // Helper function to format dates
        function formatDate(dateString) {
            if (!dateString) return 'N/A';
            try {
                var date = new Date(dateString);
                var options = { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
                return date.toLocaleDateString('en-US', options);
            } catch (e) {
                return dateString;
            }
        }
        // Details Modal Functions
        function openDetailsModal() {
            console.log('?? Opening details modal');
            var modal = document.getElementById('detailsModal');
            if (!modal) {
                alert('Details modal not found!');
                return;
            }
            modal.style.display = 'block';
            modal.style.pointerEvents = 'auto';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            console.log('? Details modal opened');
        }

        function closeDetailsModal() {
            console.log('?? Closing details modal');
            var modal = document.getElementById('detailsModal');
            modal.classList.remove('show');
            modal.style.display = 'none';
            modal.style.pointerEvents = 'none';
            document.body.style.overflow = '';
            document.body.style.position = '';
            void(document.body.offsetHeight);
            console.log('? Details modal closed');
        }

        // Rejection Modal Functions
        function openRejectModal() {
            console.log('?? Opening reject modal');
            var modal = document.getElementById('rejectModal');
            modal.style.display = 'block';
            modal.style.pointerEvents = 'auto';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            console.log('? Reject modal opened');
        }

        function closeRejectModal() {
            console.log('?? Closing reject modal');
            var modal = document.getElementById('rejectModal');
            modal.classList.remove('show');
            modal.style.display = 'none';
            modal.style.pointerEvents = 'none';
            document.body.style.overflow = '';
            document.body.style.position = '';
            void(document.body.offsetHeight);
            console.log('? Reject modal closed');
        }

        // Approval Modal Functions
        function openApprovalModal(requestId) {
            console.log('? Opening approval modal for request:', requestId);
            if (!requestId) {
                alert('Invalid request ID');
                return;
            }
            
            // Set the hidden field value
            document.getElementById('<%= hfRequestIdToApprove.ClientID %>').value = requestId;
            
            // Open the modal
            var modal = document.getElementById('approvalModal');
            modal.style.display = 'block';
            modal.style.pointerEvents = 'auto';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            console.log('? Approval modal opened');
        }

        function closeApprovalModal() {
            console.log('?? Closing approval modal');
            var modal = document.getElementById('approvalModal');
            modal.classList.remove('show');
            modal.style.display = 'none';
            modal.style.pointerEvents = 'none';
            document.body.style.overflow = '';
            document.body.style.position = '';
            void(document.body.offsetHeight);
            console.log('? Approval modal closed');
        }

        function openSupplierModal() {
            console.log('?? Opening supplier modal');
            var modal = document.getElementById('supplierModal');
            modal.style.display = 'block'; // Force display block
            modal.style.pointerEvents = 'auto'; // Enable pointer events
            modal.classList.add('show');
            document.body.style.overflow = 'hidden'; // Prevent background scrolling
            console.log('? Supplier modal opened');
        }

        function closeSupplierModal() {
            console.log('?? Closing supplier modal');
            var modal = document.getElementById('supplierModal');
            modal.classList.remove('show');
            
            // Force display none and pointer-events none to ensure modal doesn't block anything
            modal.style.display = 'none';
            modal.style.pointerEvents = 'none';
            
            // Simply restore normal overflow - let CSS handle the rest
            document.body.style.overflow = '';
            document.body.style.position = '';
            
            // Force a reflow
            void(document.body.offsetHeight);
            
            console.log('? Modal closed, scrolling restored');
        }

        // Request Stock for Variant - Fetches data and opens modal
        function requestStockForVariant(variantId) {
            console.log('?? Request stock for variant:', variantId);
            
            // Validate variantId
            if (!variantId || variantId === 'undefined' || variantId === 'null') {
                console.error('❌ Invalid variant ID:', variantId);
                alert('Error: Invalid product ID. Please refresh the page and try again.');
                return;
            }
            
            // Show loading indicator
            var modal = document.getElementById('stockRequestModal');
            document.getElementById('reqProductName').textContent = 'Loading...';
            document.getElementById('reqCurrentStock').textContent = 'Loading...';
            document.getElementById('reqMinStock').textContent = 'Loading...';
            document.getElementById('reqSupplierName').textContent = 'Loading...';
            
            // Open modal immediately to show loading state
            modal.style.display = 'block';
            modal.style.pointerEvents = 'auto';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            
            // Build the URL
            var url = '<%= ResolveUrl("~/Handlers/GetVariantDetails.ashx") %>?variantId=' + encodeURIComponent(variantId);
            console.log('🔍 Fetching from URL:', url);
            
            // Make AJAX call to fetch variant and product data
            fetch(url)
                .then(function(response) {
                    console.log('📡 Response status:', response.status, response.statusText);
                    
                    // Check if response is OK
                    if (!response.ok) {
                        return response.text().then(function(text) {
                            console.error('❌ Server error response:', text);
                            throw new Error('Server returned ' + response.status + ': ' + response.statusText);
                        });
                    }
                    
                    // Try to parse JSON
                    return response.text().then(function(text) {
                        console.log('📄 Response text:', text);
                        try {
                            return JSON.parse(text);
                        } catch (e) {
                            console.error('❌ JSON parse error:', e);
                            console.error('Response was:', text);
                            throw new Error('Invalid JSON response from server');
                        }
                    });
                })
                .then(function(data) {
                    console.log('✅ Variant data received:', data);
                    
                    if (data.success) {
                        // Validate data structure
                        if (!data.variant || !data.product || !data.supplier) {
                            console.error('? Incomplete data structure:', data);
                            throw new Error('Incomplete data received from server');
                        }
                        
                        // Populate modal with data
                        openStockRequestModal(
                            data.variant.id,
                            data.product.id,
                            data.supplier.id,
                            data.variant.variantName,
                            data.variant.stockQuantity,
                            data.variant.minimumStock,
                            data.supplier.name
                        );
                    } else {
                        var errorMsg = data.message || 'Failed to load product data';
                        console.error('❌ Server returned error:', errorMsg);
                        if (data.details) {
                            console.error('Error details:', data.details);
                        }
                        alert('Error: ' + errorMsg);
                        closeStockRequestModal();
                    }
                })
                .catch(function(error) {
                    console.error('❌ Error fetching variant details:', error);
                    console.error('Error stack:', error.stack);
                    
                    var errorMessage = 'Failed to load product data.\n\n';
                    errorMessage += 'Error: ' + error.message + '\n\n';
                    errorMessage += 'Please check:\n';
                    errorMessage += '1. Your internet connection\n';
                    errorMessage += '2. The database connection\n';
                    errorMessage += '3. The browser console for details (F12)';
                    
                    alert(errorMessage);
                    closeStockRequestModal();
                });
        }

        // Stock Request Modal Functions
        function openStockRequestModal(variantId, productId, supplierId, productName, currentStock, minStock, supplierName) {
            console.log('?? Opening stock request modal with:', {
                variantId: variantId,
                productId: productId,
                supplierId: supplierId,
                productName: productName,
                currentStock: currentStock,
                minStock: minStock,
                supplierName: supplierName
            });
            
            // Validate all required parameters
            if (!variantId || !productId || !supplierId) {
                console.error('❌ Missing required IDs');
                alert('Error: Missing required data. Please refresh the page and try again.');
                closeStockRequestModal();
                return;
            }
            
            // Set hidden field values
            document.getElementById('<%= hfVariantId.ClientID %>').value = variantId || '';
            document.getElementById('<%= hfProductId.ClientID %>').value = productId || '';
            document.getElementById('<%= hfSupplierId2.ClientID %>').value = supplierId || '';
            
            // Set display values with defaults
            document.getElementById('reqProductName').textContent = productName || 'Unknown Product';
            document.getElementById('reqCurrentStock').textContent = (currentStock || 0) + ' units';
            document.getElementById('reqMinStock').textContent = (minStock || 0) + ' units';
            document.getElementById('reqSupplierName').textContent = supplierName || 'Unknown Supplier';
            
            // Calculate suggested quantity (difference to reach minimum stock + buffer)
            var suggestedQty = Math.max((minStock || 0) - (currentStock || 0) + 10, 10);
            document.getElementById('<%= txtRequestQuantity.ClientID %>').value = suggestedQty;
            
            // Clear expected delivery date and notes
            document.getElementById('<%= txtExpectedDeliveryDate.ClientID %>').value = '';
            document.getElementById('<%= txtRequestNotes.ClientID %>').value = '';
            
            // Show modal (if not already shown)
            var modal = document.getElementById('stockRequestModal');
            modal.style.display = 'block'; // Force display block
            modal.style.pointerEvents = 'auto'; // Enable pointer events
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            
            // Focus on quantity field
            setTimeout(function() {
                try {
                    document.getElementById('<%= txtRequestQuantity.ClientID %>').focus();
                    document.getElementById('<%= txtRequestQuantity.ClientID %>').select();
                } catch (e) {
                    console.warn('Could not focus on quantity field:', e);
                }
            }, 300);
            
            console.log('? Modal opened successfully');
        }

        // Add the missing closeIngredientStockRequestModal function
        function closeIngredientStockRequestModal() {
            console.log('🔒 Closing ingredient stock request modal');
            var modal = document.getElementById('ingredientStockRequestModal');
            modal.classList.remove('show');
            modal.style.display = 'none';
            modal.style.pointerEvents = 'none';
            document.body.style.overflow = '';
            document.body.style.position = '';
            void(document.body.offsetHeight);
            console.log('✅ Ingredient stock request modal closed');
        }

        // --- Ingredient Stock Tab Functions ---

        function filterIngredientGrid() {
            var search = document.getElementById('ingredientSearchInput').value.toLowerCase();
            var stockStatus = document.getElementById('ingredientStockStatusDropdown').value;
            var table = document.getElementById('gvIngredients');
            if (!table) return;
            var rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            
            for (var i = 0; i < rows.length; i++) {
                var row = rows[i];
                var cells = row.cells;
                if (!cells || cells.length < 2) continue;
                
                var ingredientName = cells[0].innerText.toLowerCase();
                var currentStock = parseFloat(cells[2].innerText) || 0;
                var minStock = parseFloat(cells[3].innerText) || 0;
                
                var show = true;
                
                // Search filter
                if (search && ingredientName.indexOf(search) === -1) {
                    show = false;
                }
                
                // Stock status filter
                if (stockStatus) {
                    if (stockStatus === 'low' && currentStock > minStock) {
                        show = false;
                    }
                    if (stockStatus === 'ok' && currentStock <= minStock) {
                        show = false;
                    }
                }
                
                row.style.display = show ? '' : 'none';
            }
        }

        // Fetch and populate ingredient stock data
        function fetchIngredients() {
            console.log('?? Fetching ingredient stock data...');
            
            fetch('/Handlers/GetIngredients.ashx')
                .then(response => response.json())
                .then(data => {
                    console.log('? Ingredient data received:', data);
                    
                    if (Array.isArray(data)) {
                        updateIngredientGrid(data);
                        updateIngredientSummary(data);
                    } else {
                        console.error('? Invalid data format:', data);
                        alert('Failed to load ingredient stock: Invalid data format');
                    }
                })
                .catch(err => {
                    console.error('? Error fetching ingredients:', err);
                    alert('Failed to load ingredient stock: ' + err);
                });
        }

        function updateIngredientGrid(ingredients) {
            console.log('[updateIngredientGrid] called with', ingredients.length, 'ingredients');
            var tbody = document.getElementById('gvIngredients').getElementsByTagName('tbody')[0];
            tbody.innerHTML = '';
            
            if (!Array.isArray(ingredients) || ingredients.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding:40px; color:#666;">No ingredients found.</td></tr>';
                updateIngredientSummary([]);
                return;
            }
            
            ingredients.forEach(function(ingredient) {
                var row = tbody.insertRow(-1);
                
                // Ingredient Name
                var cellName = row.insertCell(0);
                cellName.textContent = ingredient.IngredientName || '-';
                
                // Unit
                var cellUnit = row.insertCell(1);
                cellUnit.textContent = ingredient.Unit || '-';
                
                // Current Stock
                var cellCurrentStock = row.insertCell(2);
                var isLowStock = (ingredient.CurrentStock || 0) <= (ingredient.MinimumStock || 0);
                cellCurrentStock.innerHTML = '<span style="' + (isLowStock ? 'color: red; font-weight: 600;' : '') + '">' + 
                    (ingredient.CurrentStock || 0).toFixed(2) + '</span>';
                
                // Minimum Stock
                var cellMinStock = row.insertCell(3);
                cellMinStock.textContent = (ingredient.MinimumStock || 0).toFixed(2);
                
                // Cost Per Unit
                var cellCost = row.insertCell(4);
                cellCost.textContent = '₱' + (ingredient.CostPerUnit || 0).toFixed(2);
                
                // Total Value
                var cellValue = row.insertCell(5);
                var totalValue = (ingredient.CurrentStock || 0) * (ingredient.CostPerUnit || 0);
                cellValue.textContent = '₱' + totalValue.toFixed(2);
                
                // Supplier
                var cellSupplier = row.insertCell(6);
                cellSupplier.textContent = ingredient.SupplierName || 'N/A';
                
                // Status
                var cellStatus = row.insertCell(7);
                var statusHtml = isLowStock ? 
                    '<span class="status-badge status-inactive">Low Stock</span>' : 
                    '<span class="status-badge status-active">In Stock</span>';
                cellStatus.innerHTML = statusHtml;
                
                // Actions
                var cellActions = row.insertCell(8);
                cellActions.innerHTML = '<button type="button" class="btn btn-primary" onclick="requestIngredientStock(\'' + 
                    ingredient.Id + '\'); return false;">Request Stock</button>';
            });
            
            // Update ingredient summary
            updateIngredientSummary(ingredients);
        }

        // Add the missing updateIngredientSummary function
        function updateIngredientSummary(ingredients) {
            var totalCount = 0;
            var lowCount = 0;
            var totalValue = 0;
            
            ingredients.forEach(function(ingredient) {
                totalCount++;
                var currentStock = ingredient.CurrentStock || 0;
                var minStock = ingredient.MinimumStock || 0;
                var costPerUnit = ingredient.CostPerUnit || 0;
                
                if (currentStock <= minStock) {
                    lowCount++;
                }
                
                totalValue += (currentStock * costPerUnit);
            });
            
            document.getElementById('ingredientTotalCount').textContent = totalCount;
            document.getElementById('ingredientLowCount').textContent = lowCount;
            document.getElementById('ingredientTotalValue').textContent = totalValue.toFixed(2);
        }

        // Add the missing requestIngredientStock function
        function requestIngredientStock(ingredientId) {
            console.log('🧪 Request ingredient stock for:', ingredientId);
            
            // Validate ingredientId
            if (!ingredientId || ingredientId === 'undefined' || ingredientId === 'null') {
                console.error('❌ Invalid ingredient ID:', ingredientId);
                alert('Error: Invalid ingredient ID. Please refresh the page and try again.');
                return;
            }
            
            // Show loading indicator
            var modal = document.getElementById('ingredientStockRequestModal');
            document.getElementById('reqIngredientName').textContent = 'Loading...';
            document.getElementById('reqIngredientUnit').textContent = 'Loading...';
            document.getElementById('reqIngredientCurrentStock').textContent = 'Loading...';
            document.getElementById('reqIngredientMinStock').textContent = 'Loading...';
            document.getElementById('reqIngredientSupplierName').textContent = 'Loading...';
            
            // Open modal immediately to show loading state
            modal.style.display = 'block';
            modal.style.pointerEvents = 'auto';
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            
            // Build the URL
            var url = '<%= ResolveUrl("~/Handlers/GetIngredient.ashx") %>?id=' + encodeURIComponent(ingredientId);
            console.log('🔍 Fetching from URL:', url);
            
            // Make AJAX call to fetch ingredient data
            fetch(url)
                .then(function(response) {
                    console.log('📡 Response status:', response.status, response.statusText);
                    
                    if (!response.ok) {
                        return response.text().then(function(text) {
                            console.error('❌ Server error response:', text);
                            throw new Error('Server returned ' + response.status + ': ' + response.statusText);
                        });
                    }
                    
                    return response.text().then(function(text) {
                        console.log('📄 Response text:', text);
                        try {
                            return JSON.parse(text);
                        } catch (e) {
                            console.error('❌ JSON parse error:', e);
                            console.error('Response was:', text);
                            throw new Error('Invalid JSON response from server');
                        }
                    });
                })
                .then(function(data) {
                    console.log('✅ Ingredient data received:', data);
                    
                    if (data.success && data.ingredient) {
                        var ingredient = data.ingredient;
                        
                        // Set hidden field values
                        document.getElementById('<%= hfIngredientId.ClientID %>').value = ingredient.Id || '';
                        document.getElementById('<%= hfIngredientSupplierId.ClientID %>').value = ingredient.SupplierId || '';
                        
                        // Set display values
                        document.getElementById('reqIngredientName').textContent = ingredient.IngredientName || 'Unknown Ingredient';
                        document.getElementById('reqIngredientUnit').textContent = ingredient.Unit || 'units';
                        document.getElementById('reqIngredientCurrentStock').textContent = (ingredient.CurrentStock || 0).toFixed(2);
                        document.getElementById('reqIngredientMinStock').textContent = (ingredient.MinimumStock || 0).toFixed(2);
                        document.getElementById('reqIngredientSupplierName').textContent = ingredient.SupplierName || 'Unknown Supplier';
                        
                        // Calculate suggested quantity
                        var suggestedQty = Math.max((ingredient.MinimumStock || 0) - (ingredient.CurrentStock || 0) + 10, 10);
                        document.getElementById('<%= txtIngredientRequestQuantity.ClientID %>').value = suggestedQty.toFixed(2);
                        
                        // Clear other fields
                        document.getElementById('<%= txtIngredientExpectedDeliveryDate.ClientID %>').value = '';
                        document.getElementById('<%= txtIngredientRequestNotes.ClientID %>').value = '';
                        
                        console.log('✅ Ingredient stock request modal populated');
                    } else {
                        var errorMsg = data.message || 'Failed to load ingredient data';
                        console.error('❌ Server returned error:', errorMsg);
                        alert('Error: ' + errorMsg);
                        closeIngredientStockRequestModal();
                    }
                })
                .catch(function(error) {
                    console.error('❌ Error fetching ingredient details:', error);
                    console.error('Error stack:', error.stack);
                    
                    var errorMessage = 'Failed to load ingredient data.\n\n';
                    errorMessage += 'Error: ' + error.message + '\n\n';
                    errorMessage += 'Please check:\n';
                    errorMessage += '1. Your internet connection\n';
                    errorMessage += '2. The database connection\n';
                    errorMessage += '3. The browser console for details (F12)';
                    
                    alert(errorMessage);
                    closeIngredientStockRequestModal();
                });
        }

        // Close modals when clicking outside
        window.onclick = function(event) {
            var supplierModal = document.getElementById('supplierModal');
            var stockRequestModal = document.getElementById('stockRequestModal');
            var ingredientStockRequestModal = document.getElementById('ingredientStockRequestModal');
            var detailsModal = document.getElementById('detailsModal');
            var rejectModal = document.getElementById('rejectModal');
            var approvalModal = document.getElementById('approvalModal');
            
            if (event.target == supplierModal) {
                closeSupplierModal();
            }
            
            if (event.target == stockRequestModal) {
                closeStockRequestModal();
            }

            if (event.target == ingredientStockRequestModal) {
                closeIngredientStockRequestModal();
            }

            if (event.target == detailsModal) {
                closeDetailsModal();
            }

            if (event.target == rejectModal) {
                closeRejectModal();
            }

            if (event.target == approvalModal) {
                closeApprovalModal();
            }
        }

        // Close modals on Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeSupplierModal();
                closeStockRequestModal();
                closeIngredientStockRequestModal();
                closeDetailsModal();
                closeRejectModal();
                closeApprovalModal();
            }
        });

        // Safety check: Ensure body is always scrollable when no modals are open (Updated)
        setInterval(function() {
            var supplierModal = document.getElementById('supplierModal');
            var stockModal = document.getElementById('stockRequestModal');
            var ingredientStockModal = document.getElementById('ingredientStockRequestModal');
            var detailsModal = document.getElementById('detailsModal');
            var rejectModal = document.getElementById('rejectModal');
            var approvalModal = document.getElementById('approvalModal');
            
            var anyModalOpen = (supplierModal && supplierModal.classList.contains('show')) || 
                               (stockModal && stockModal.classList.contains('show')) ||
                               (ingredientStockModal && ingredientStockModal.classList.contains('show')) ||
                               (detailsModal && detailsModal.classList.contains('show')) ||
                               (rejectModal && rejectModal.classList.contains('show')) ||
                               (approvalModal && approvalModal.classList.contains('show'));
            
            if (!anyModalOpen) {
                if (document.body.style.overflow === 'hidden') {
                    console.warn('?? Body was locked but no modals open - fixing...');
                    document.body.style.overflow = '';
                    document.body.style.position = '';
                }
                
                if (supplierModal && supplierModal.style.display !== 'none') {
                    supplierModal.style.display = 'none';
                    supplierModal.style.pointerEvents = 'none';
                }
                if (stockModal && stockModal.style.display !== 'none') {
                    stockModal.style.display = 'none';
                    stockModal.style.pointerEvents = 'none';
                }
                if (ingredientStockModal && ingredientStockModal.style.display !== 'none') {
                    ingredientStockModal.style.display = 'none';
                    ingredientStockModal.style.pointerEvents = 'none';
                }
                if (detailsModal && detailsModal.style.display !== 'none') {
                    detailsModal.style.display = 'none';
                    detailsModal.style.pointerEvents = 'none';
                }
                if (rejectModal && rejectModal.style.display !== 'none') {
                    rejectModal.style.display = 'none';
                    rejectModal.style.pointerEvents = 'none';
                }
                if (approvalModal && approvalModal.style.display !== 'none') {
                    approvalModal.style.display = 'none';
                    approvalModal.style.pointerEvents = 'none';
                }
            }
        }, 500);
        // --- Product stock filtering using GetProductVariantsByCategory.ashx ---

        function fetchVariantsByCategory(category) {
            console.log('[fetchVariantsByCategory] category =', category);

            var grid = document.getElementById('<%= gvProducts.ClientID %>');
            if (!grid) {
                console.error('gvProducts not found in DOM.');
                return;
            }

            var tbody = grid.tBodies && grid.tBodies.length > 0
                ? grid.tBodies[0]
                : null;

            if (!tbody) {
                console.error('gvProducts has no <tbody>.');
                return;
            }

            // Loading row
            tbody.innerHTML =
                '<tr><td colspan="5" style="text-align:center; padding:24px;">' +
                '<span>Loading products…</span>' +
                '</td></tr>';

            var url = '<%= ResolveUrl("~/Handlers/GetProductVariantsByCategory.ashx") %>';
            if (category) {
                url += '?category=' + encodeURIComponent(category);
            }

            fetch(url)
                .then(function (resp) {
                    if (!resp.ok) {
                        throw new Error('HTTP ' + resp.status);
                    }
                    return resp.json();
                })
                .then(function (variants) {
                    console.log('[fetchVariantsByCategory] received', variants.length, 'variants');
                    bindVariantsToGrid(variants);
                })
                .catch(function (err) {
                    console.error('Error loading variants:', err);
                    tbody.innerHTML =
                        '<tr><td colspan="5" style="text-align:center; padding:24px; color:#c00;">' +
                        'Failed to load products.' +
                        '</td></tr>';
                });
        }

        // Bind JSON variants into the existing gvProducts rows
        function bindVariantsToGrid(variants) {
            var grid = document.getElementById('<%= gvProducts.ClientID %>');
            if (!grid || !grid.tBodies.length) return;

            var tbody = grid.tBodies[0];
            tbody.innerHTML = '';

            if (!variants || !variants.length) {
                tbody.innerHTML =
                    '<tr><td colspan="5" style="text-align:center; padding:24px; color:#666;">' +
                    'No products found.' +
                    '</td></tr>';
                updateStockSummaryFromVariants([]);
                return;
            }

            variants.forEach(function (v) {
                var row = tbody.insertRow(-1);

                // col0: Image
                var cImg = row.insertCell(0);
                var imgUrl = (v.VariantImgUrls && v.VariantImgUrls.length > 0)
                    ? v.VariantImgUrls[0]
                    : (v.VariantImg || '/Content/images/sample-generic.png');
                cImg.innerHTML =
                    '<img src="' + imgUrl + '" style="width:80px;height:80px;object-fit:cover;border-radius:8px;" />';

                // col1: Product
                var cName = row.insertCell(1);
                cName.textContent = v.VariantName || '';

                // col2: Stock
                var cStock = row.insertCell(2);
                var stock = Number(v.StockQuantity) || 0;
                cStock.textContent = stock;

                // col3: Location
                var cLoc = row.insertCell(3);
                cLoc.textContent = v.Location || '';

                // col4: Status
                var cStatus = row.insertCell(4);
                var min = Number(v.MinimumStock) || 0;
                var label, color;
                if (stock === 0) {
                    label = 'Need Stocking';
                    color = 'red';
                } else if (stock <= min) {
                    label = 'Low Stock';
                    color = 'red';
                } else {
                    label = 'In Stock';
                    color = 'green';
                }
                cStatus.innerHTML =
                    '<span style="font-weight:600;color:' + color + ';">' + label + '</span>';
            });

            updateStockSummaryFromVariants(variants);
            // apply current search/status filters on the freshly-bound rows
            filterStockGrid();
        }

        // Simple stock summary using the variant list
        function updateStockSummaryFromVariants(variants) {
            var total = 0, low = 0, medium = 0, zero = 0;

            (variants || []).forEach(function (v) {
                var qty = Number(v.StockQuantity) || 0;
                var min = Number(v.MinimumStock) || 0;
                total += qty;
                if (qty === 0) zero++;
                else if (qty <= min) low++;
                else if (qty > min && qty <= min * 2) medium++;
            });

            document.getElementById('stockTotalCount').textContent = total;
            document.getElementById('stockLowCount').textContent = low;
            document.getElementById('stockMediumCount').textContent = medium;
            document.getElementById('stockZeroCount').textContent = zero;
        }

        // Basic filter for the gvProducts GridView based on search + status
        function filterStockGrid() {
            var grid = document.getElementById('<%= gvProducts.ClientID %>');
            if (!grid || !grid.tBodies.length) return;

            var search = (document.getElementById('stockSearchInput').value || '').toLowerCase();
            var statusFilter = document.getElementById('stockStatusDropdown').value;

            var rows = grid.tBodies[0].rows;
            for (var i = 0; i < rows.length; i++) {
                var r = rows[i];
                if (!r.cells || r.cells.length < 5) continue;

                var name = r.cells[1].innerText.toLowerCase();
                var statusText = r.cells[4].innerText.toLowerCase();

                var visible = true;

                if (search && name.indexOf(search) === -1) {
                    visible = false;
                }

                if (statusFilter) {
                    if (statusFilter === 'low' && statusText.indexOf('low') === -1) visible = false;
                    if (statusFilter === 'need' && statusText.indexOf('need') === -1) visible = false;
                    if (statusFilter === 'medium' && statusText.indexOf('medium') === -1) visible = false;
                }

                r.style.display = visible ? '' : 'none';
            }
        }
    </script>
</asp:Content>