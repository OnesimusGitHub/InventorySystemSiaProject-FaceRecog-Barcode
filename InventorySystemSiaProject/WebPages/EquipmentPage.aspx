<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true"
    CodeBehind="EquipmentPage.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.EquipmentPage" Async="true" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/EquipmentPage.css" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">

    <header class="page-header">
        <h1><i class="fa fa-tools" style="color:#A86D6A;"></i> Equipment Inventory</h1>
        <p>Manage equipment profiles, stock levels, and procurement requests</p>
    </header>

    <!-- Action Buttons -->
    <div class="btn-group">
        <button type="button" class="btn primary" id="btnAddEquipment">
            <i class="fa fa-plus"></i> <b>Add Equipment</b>
        </button>
        <button type="button" class="btn primary" id="btnRequestStock" style="background:#56ab2f;">
            <i class="fa fa-cart-plus"></i> <b>Request Stock</b>
        </button>
        <button type="button" class="btn square" title="Refresh" onclick="location.reload()">
            <i class="fa fa-rotate"></i>
        </button>
    </div>

    <!-- Toolbar -->
    <div class="toolbar">
        <div class="toolbar-left">
            <div class="search-box">
                <i class="fa fa-search"></i>
                <input type="text" id="txtEquipmentSearch" placeholder="Search equipment name, code, type…" />
            </div>
        </div>
        <div class="toolbar-right">
            <div class="toolbar-group">
                <p>Type</p>
                <button type="button" class="btn ghost" id="btnTypeFilter" title="Filter by Type">
                    <i class="fa fa-filter"></i>
                    <span class="btn-text" id="typeFilterLabel">All Types</span>
                    <i class="fa fa-chevron-down caret"></i>
                </button>
            </div>
            <div class="toolbar-group">
                <p>Status</p>
                <button type="button" class="btn ghost" id="btnStatusFilter" title="Filter by Stock Status">
                    <i class="fa fa-circle-dot"></i>
                    <span class="btn-text" id="statusFilterLabel">All Status</span>
                    <i class="fa fa-chevron-down caret"></i>
                </button>
            </div>
        </div>
    </div>

    <!-- Tabs: Equipment | Requests | Archived -->
    <div style="background:#fff; border-radius:12px; margin-bottom:0; box-shadow:0 2px 8px rgba(0,0,0,.06);">
        <div class="modal-nav" style="border-radius:12px 12px 0 0;">
            <button type="button" class="nav-tab active" id="tabEquipment" onclick="switchMainTab('equipment',this)">
                <i class="fa fa-tools"></i> Equipment
            </button>
            <button type="button" class="nav-tab" id="tabRequests" onclick="switchMainTab('requests',this)">
                <i class="fa fa-clipboard-list"></i> Stock Requests
            </button>
            <button type="button" class="nav-tab" id="tabArchived" onclick="switchMainTab('archived',this)">
                <i class="fa fa-archive"></i> Archived
            </button>
        </div>

        <!-- Equipment Tab -->
        <div id="equipmentTab" class="tab-pane active">
            <div class="content-body" style="border-radius:0 0 12px 12px; overflow:hidden;">
                <div class="table-wrapper" style="border-radius:0;">
                    <table class="equipment-table" cellspacing="0" cellpadding="0">
                        <thead>
                            <tr>
                                <th style="width:50px">#</th>
                                <th>Equipment</th>
                                <th style="width:130px">Type</th>
                                <th style="width:100px">Code</th>
                                <th style="width:80px">Stock</th>
                                <th style="width:90px">Min.Stock</th>
                                <th style="width:110px">Unit Cost</th>
                                <th style="width:100px">Condition</th>
                                <th style="width:110px">Stock Status</th>
                                <th style="width:110px">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="tblEquipment">
                            <tr><td colspan="10" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading equipment…</td></tr>
                        </tbody>
                    </table>
                </div>
                <!-- Preview panel -->
                <aside class="preview" id="eqPreviewPanel">
                    <div class="preview-header"><i class="fa fa-eye"></i> Equipment Preview</div>
                    <div class="preview-body">
                        <div class="preview-image">
                            <img id="eqPreviewImage" src="" alt="Equipment" style="width:100%;height:150px;object-fit:cover;border-radius:8px;" />
                        </div>
                        <div class="preview-info">
                            <div class="p-name" id="eqPName">Select an equipment item</div>
                            <div class="p-field"><span class="lbl">Type:</span><span id="eqPType">-</span></div>
                            <div class="p-field"><span class="lbl">Code:</span><span id="eqPCode">-</span></div>
                            <div class="p-field"><span class="lbl">Brand:</span><span id="eqPBrand">-</span></div>
                            <div class="p-field"><span class="lbl">Model:</span><span id="eqPModel">-</span></div>
                            <div class="p-field"><span class="lbl">Supplier:</span><span id="eqPSupplier">-</span></div>
                            <div class="p-field"><span class="lbl">Stock:</span><span id="eqPStock">-</span></div>
                            <div class="p-field"><span class="lbl">Status:</span><span id="eqPStatus">-</span></div>
                            <div class="p-field"><span class="lbl">Location:</span><span id="eqPLocation">-</span></div>
                            <div class="p-field" style="margin-top:8px;">
                                <span class="lbl">Desc:</span>
                                <span id="eqPDesc" style="color:#ddd;font-size:12px;">-</span>
                            </div>
                        </div>
                    </div>
                </aside>
            </div>
        </div>

        <!-- Requests Tab -->
        <div id="requestsTab" class="tab-pane" style="padding:20px;">
            <div id="requestsContainer">
                <table class="req-table">
                    <thead>
                        <tr>
                            <th style="width:120px">Request ID</th>
                            <th>Equipment</th>
                            <th style="width:70px">Qty</th>
                            <th style="width:120px">Requested By</th>
                            <th style="width:120px">Date</th>
                            <th style="width:90px">Priority</th>
                            <th style="width:120px">Status</th>
                            <th style="width:160px">Finance Actions</th>
                        </tr>
                    </thead>
                    <tbody id="tblRequests">
                        <tr><td colspan="8" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading requests…</td></tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Archived Tab -->
        <div id="archivedTab" class="tab-pane" style="padding:20px;">
            <table class="equipment-table" cellspacing="0">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Equipment</th>
                        <th>Type</th>
                        <th>Code</th>
                        <th>Stock</th>
                        <th>Condition</th>
                        <th style="width:100px">Action</th>
                    </tr>
                </thead>
                <tbody id="tblArchived">
                    <tr><td colspan="7" class="text-center">Switch to this tab to load archived items.</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ?????????? ADD EQUIPMENT MODAL ?????????? -->
    <div id="addEquipmentModal" class="modal-overlay">
        <div class="modal-container">
            <div class="modal-header">
                <h2 class="modal-title"><i class="fa fa-tools"></i> Add New Equipment</h2>
                <button class="modal-close" onclick="closeModal('addEquipmentModal')"><i class="fa fa-times"></i></button>
            </div>
            <div class="modal-body">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Equipment Name *</label>
                        <input type="text" id="addEqName" class="form-control" placeholder="e.g., Industrial Mixer" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Equipment Type *</label>
                        <select id="addEqType" class="form-control">
                            <option value="">Select Type…</option>
                            <option>Production Equipment</option>
                            <option>Packaging Equipment</option>
                            <option>Laboratory Equipment</option>
                            <option>Safety Equipment</option>
                            <option>Office Equipment</option>
                            <option>IT Equipment</option>
                            <option>Cleaning Equipment</option>
                            <option>Transport Equipment</option>
                            <option>Other</option>
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Equipment Code</label>
                        <input type="text" id="addEqCode" class="form-control" placeholder="e.g., EQ-001" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Brand</label>
                        <input type="text" id="addEqBrand" class="form-control" placeholder="Brand name" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Model</label>
                        <input type="text" id="addEqModel" class="form-control" placeholder="Model number/name" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Serial Number</label>
                        <input type="text" id="addEqSerial" class="form-control" placeholder="Serial No." />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Supplier</label>
                        <select id="addEqSupplier" class="form-control">
                            <option value="">Select Supplier…</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Stock Quantity</label>
                        <input type="number" id="addEqStock" class="form-control" placeholder="0" min="0" value="0" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Minimum Stock</label>
                        <input type="number" id="addEqMinStock" class="form-control" placeholder="5" min="1" value="5" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Unit Cost (?)</label>
                        <input type="number" id="addEqCost" class="form-control" placeholder="0.00" min="0" step="0.01" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Condition</label>
                        <select id="addEqCondition" class="form-control">
                            <option value="Good" selected>Good</option>
                            <option value="Fair">Fair</option>
                            <option value="Poor">Poor</option>
                            <option value="New">New</option>
                            <option value="For Repair">For Repair</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Purchase Date</label>
                        <input type="date" id="addEqPurchaseDate" class="form-control" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Warranty Expiry</label>
                        <input type="date" id="addEqWarranty" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Storage Location</label>
                        <input type="text" id="addEqLocation" class="form-control" placeholder="e.g., Warehouse A – Shelf 3" />
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea id="addEqDesc" class="form-control" placeholder="Optional description…"></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">Equipment Image</label>
                    <input type="file" id="addEqImage" class="form-control" accept="image/*" />
                    <div id="addEqImagePreview" style="margin-top:10px;display:none;">
                        <img id="addEqImagePreviewImg" src="" alt="Preview"
                             style="height:120px;border-radius:8px;object-fit:cover;border:2px solid #e9ecef;" />
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal('addEquipmentModal')">
                    <i class="fa fa-times"></i> Cancel
                </button>
                <button type="button" class="btn-animated btn-primary" id="btnSaveEquipment" onclick="saveEquipment()">
                    <i class="fa fa-save"></i> Save Equipment
                </button>
            </div>
        </div>
    </div>

    <!-- ?????????? UPDATE EQUIPMENT MODAL ?????????? -->
    <div id="updateEquipmentModal" class="modal-overlay">
        <div class="modal-container">
            <div class="modal-header">
                <h2 class="modal-title"><i class="fa fa-edit"></i> Update Equipment</h2>
                <button class="modal-close" onclick="closeModal('updateEquipmentModal')"><i class="fa fa-times"></i></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="updEqId" />
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Equipment Name *</label>
                        <input type="text" id="updEqName" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Equipment Type *</label>
                        <select id="updEqType" class="form-control">
                            <option value="">Select Type…</option>
                            <option>Production Equipment</option>
                            <option>Packaging Equipment</option>
                            <option>Laboratory Equipment</option>
                            <option>Safety Equipment</option>
                            <option>Office Equipment</option>
                            <option>IT Equipment</option>
                            <option>Cleaning Equipment</option>
                            <option>Transport Equipment</option>
                            <option>Other</option>
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Equipment Code</label>
                        <input type="text" id="updEqCode" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Brand</label>
                        <input type="text" id="updEqBrand" class="form-control" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Model</label>
                        <input type="text" id="updEqModel" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Serial Number</label>
                        <input type="text" id="updEqSerial" class="form-control" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Supplier</label>
                        <select id="updEqSupplier" class="form-control">
                            <option value="">Select Supplier…</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Stock Quantity</label>
                        <input type="number" id="updEqStock" class="form-control" min="0" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Minimum Stock</label>
                        <input type="number" id="updEqMinStock" class="form-control" min="1" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Unit Cost (?)</label>
                        <input type="number" id="updEqCost" class="form-control" step="0.01" min="0" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Condition</label>
                        <select id="updEqCondition" class="form-control">
                            <option value="Good">Good</option>
                            <option value="Fair">Fair</option>
                            <option value="Poor">Poor</option>
                            <option value="New">New</option>
                            <option value="For Repair">For Repair</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Purchase Date</label>
                        <input type="date" id="updEqPurchaseDate" class="form-control" />
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Warranty Expiry</label>
                        <input type="date" id="updEqWarranty" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Storage Location</label>
                        <input type="text" id="updEqLocation" class="form-control" />
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea id="updEqDesc" class="form-control"></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">Update Image (leave blank to keep current)</label>
                    <input type="file" id="updEqImage" class="form-control" accept="image/*" />
                    <div style="margin-top:10px;">
                        <img id="updEqCurrentImage" src="" alt="Current"
                             style="height:110px;border-radius:8px;object-fit:cover;border:2px solid #e9ecef;" />
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal('updateEquipmentModal')">
                    <i class="fa fa-times"></i> Cancel
                </button>
                <button type="button" class="btn-animated btn-primary" id="btnUpdateEquipment" onclick="updateEquipment()">
                    <i class="fa fa-save"></i> Save Changes
                </button>
            </div>
        </div>
    </div>

    <!-- ?????????? REQUEST STOCK MODAL ?????????? -->
    <div id="requestStockModal" class="modal-overlay">
        <div class="modal-container" style="max-width:600px;">
            <div class="modal-header" style="background:linear-gradient(135deg,#56ab2f,#a8e6cf);">
                <h2 class="modal-title"><i class="fa fa-cart-plus"></i> Request Equipment Stock</h2>
                <button class="modal-close" onclick="closeModal('requestStockModal')"><i class="fa fa-times"></i></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Equipment *</label>
                    <select id="reqEqSelect" class="form-control">
                        <option value="">Select Equipment…</option>
                    </select>
                    <div id="reqEqInfo" style="margin-top:8px;padding:10px;background:#f8f9fa;border-radius:8px;display:none;font-size:13px;color:#555;">
                        <span id="reqEqInfoText"></span>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Quantity Requested *</label>
                        <input type="number" id="reqQty" class="form-control" placeholder="0" min="1" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Priority</label>
                        <select id="reqPriority" class="form-control">
                            <option value="Low">Low</option>
                            <option value="Normal" selected>Normal</option>
                            <option value="High">High</option>
                            <option value="Urgent">Urgent</option>
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Estimated Cost (?)</label>
                        <input type="number" id="reqEstCost" class="form-control" placeholder="0.00" step="0.01" min="0" />
                    </div>
                    <div class="form-group">
                        <label class="form-label">Expected Delivery Date</label>
                        <input type="date" id="reqDelivery" class="form-control" />
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">Purpose / Reason *</label>
                    <textarea id="reqPurpose" class="form-control" placeholder="Explain why this stock is needed…"></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">Additional Notes</label>
                    <textarea id="reqNotes" class="form-control" placeholder="Any extra notes…"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal('requestStockModal')">
                    <i class="fa fa-times"></i> Cancel
                </button>
                <button type="button" class="btn-animated btn-success" id="btnSubmitRequest" onclick="submitStockRequest()">
                    <i class="fa fa-paper-plane"></i> Submit Request
                </button>
            </div>
        </div>
    </div>

    <!-- ?????????? FINANCE APPROVAL MODAL ?????????? -->
    <div id="financeModal" class="modal-overlay">
        <div class="modal-container" style="max-width:520px;">
            <div class="modal-header" style="background:linear-gradient(135deg,#1565c0,#42a5f5);">
                <h2 class="modal-title"><i class="fa fa-university"></i> Finance Approval</h2>
                <button class="modal-close" onclick="closeModal('financeModal')"><i class="fa fa-times"></i></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="financeRequestId" />
                <div class="finance-banner">
                    <i class="fa fa-info-circle"></i>
                    <span id="financeRequestSummary">Loading request details…</span>
                </div>
                <div class="form-group">
                    <label class="form-label">Approved Cost (?)</label>
                    <input type="number" id="financeApprovedCost" class="form-control" placeholder="0.00" step="0.01" min="0" />
                </div>
                <div class="form-group">
                    <label class="form-label">Finance Notes</label>
                    <textarea id="financeNotes" class="form-control" placeholder="Approval notes, budget codes, etc.…"></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">Approved By</label>
                    <input type="text" id="financeApprovedBy" class="form-control" placeholder="Finance officer name" />
                </div>
                <div id="financeRejectSection" style="display:none;">
                    <div class="form-group">
                        <label class="form-label" style="color:#dc3545;">Rejection Reason *</label>
                        <textarea id="financeRejectReason" class="form-control" placeholder="State the reason for rejection…"></textarea>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal('financeModal')">
                    <i class="fa fa-times"></i> Cancel
                </button>
                <button type="button" class="btn-animated btn-danger" id="btnFinanceReject" onclick="toggleRejectSection()">
                    <i class="fa fa-times-circle"></i> Reject
                </button>
                <button type="button" class="btn-animated btn-success" id="btnFinanceApprove" onclick="submitFinanceAction('approve')">
                    <i class="fa fa-check-circle"></i> Approve
                </button>
            </div>
        </div>
    </div>

    <!-- ?????????? COMPLETE REQUEST MODAL ?????????? -->
    <div id="completeRequestModal" class="modal-overlay">
        <div class="modal-container" style="max-width:460px;">
            <div class="modal-header" style="background:linear-gradient(135deg,#4CAF50,#81c784);">
                <h2 class="modal-title"><i class="fa fa-check-double"></i> Complete Request</h2>
                <button class="modal-close" onclick="closeModal('completeRequestModal')"><i class="fa fa-times"></i></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="completeRequestId" />
                <p id="completeRequestSummary" style="color:#555;margin-bottom:18px;"></p>
                <div class="form-group">
                    <label class="form-label">Quantity Actually Received *</label>
                    <input type="number" id="completeQtyAdded" class="form-control" placeholder="0" min="1" />
                    <small style="color:#888;font-size:12px;">This quantity will be added to the equipment stock.</small>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-animated btn-secondary" onclick="closeModal('completeRequestModal')">Cancel</button>
                <button type="button" class="btn-animated btn-success" onclick="submitComplete()">
                    <i class="fa fa-check"></i> Mark Complete & Update Stock
                </button>
            </div>
        </div>
    </div>

    <!-- ?????????? NOTIFICATION MODAL ?????????? -->
    <div id="eqNotificationModal" class="notification-modal">
        <div class="notification-container">
            <div class="notification-header">
                <div class="notification-icon" id="eqNotifIcon"><i class="fa fa-check"></i></div>
                <div class="notification-content">
                    <h3 class="notification-title" id="eqNotifTitle">Success</h3>
                    <p class="notification-message" id="eqNotifMessage">Done.</p>
                </div>
            </div>
            <div class="notification-footer">
                <button type="button" class="btn-notification primary" onclick="closeEqNotif()">
                    <i class="fa fa-check"></i> OK
                </button>
            </div>
            <div class="notification-progress" id="eqNotifProgress"></div>
        </div>
    </div>

    <!-- Archive confirmation -->
    <div id="archiveConfirmEqModal" class="notification-modal">
        <div class="notification-container">
            <div class="notification-header">
                <div class="notification-icon warning"><i class="fa fa-archive"></i></div>
                <div class="notification-content">
                    <h3 class="notification-title">Archive Equipment</h3>
                    <p class="notification-message" id="archiveEqConfirmText">Archive this equipment?</p>
                </div>
            </div>
            <div class="notification-footer">
                <button type="button" class="btn-notification secondary" id="archiveEqCancelBtn">Cancel</button>
                <button type="button" class="btn-notification primary" id="archiveEqConfirmBtn">Archive</button>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="ScriptsContent" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
/* ??????????????????????????????????????????
   Equipment Page – JavaScript
?????????????????????????????????????????? */

var allEquipment = [];   // cached equipment list
var allSuppliers = [];   // cached suppliers for dropdowns
var pendingArchiveId = null;

// Load suppliers from Suppliers collection
function loadSuppliersForEquipment() {
    $.ajax({
        url: '/Handlers/SupplierCrudHandler.ashx',
        method: 'GET',
        data: { action: 'get' },
        dataType: 'json',
        success: function (res) {
            if (!res || res.success !== true) {
                console && console.warn && console.warn('Failed to load suppliers for equipment:', res && res.message);
                return;
            }
            allSuppliers = res.suppliers || [];
            bindSupplierDropdowns();
        },
        error: function () {
            console && console.error && console.error('Network error loading suppliers for equipment');
        }
    });
}

function bindSupplierDropdowns() {
    var addSel = document.getElementById('addEqSupplier');
    var updSel = document.getElementById('updEqSupplier');
    if (!addSel && !updSel) return;

    var optionsHtml = '<option value="">Select Supplier…</option>';
    (allSuppliers || []).forEach(function (s) {
        // expect SupplierID and SupName from C# model
        if (s && s.SupplierID && s.SupName) {
            optionsHtml += '<option value="' + s.SupplierID + '" data-name="' + (s.SupName || '').replace(/"/g, '&quot;') + '">' +
                (s.SupName || '') + '</option>';
        }
    });

    if (addSel) addSel.innerHTML = optionsHtml;
    if (updSel) {
        var current = updSel.value;
        updSel.innerHTML = optionsHtml;
        if (current) updSel.value = current;
    }
}

// ??? Notification helper ???
function eqNotif(type, title, message, autoHide, ms) {
    var modal  = document.getElementById('eqNotificationModal');
    var icon   = document.getElementById('eqNotifIcon');
    var titleEl= document.getElementById('eqNotifTitle');
    var msgEl  = document.getElementById('eqNotifMessage');
    var prog   = document.getElementById('eqNotifProgress');
    if (!modal) return;
    titleEl.textContent = title || '';
    msgEl.textContent   = message || '';
    icon.className = 'notification-icon ' + (type || 'info');
    var iconMap = { success:'fa-check', error:'fa-times', warning:'fa-exclamation-triangle', info:'fa-info-circle' };
    icon.innerHTML = '<i class="fa ' + (iconMap[type] || 'fa-info-circle') + '"></i>';
    modal.classList.add('show');
    if (autoHide) {
        var dur = ms || 2500;
        if (prog) { prog.style.animationDuration = dur + 'ms'; prog.style.width = '100%'; }
        setTimeout(function () { closeEqNotif(); }, dur);
    }
}
function closeEqNotif() {
    var modal = document.getElementById('eqNotificationModal');
    if (modal) { modal.classList.remove('show'); }
}

// ??? Generic modal open/close ???
function openModal(id) {
    var m = document.getElementById(id);
    if (m) { m.classList.add('show'); m.style.display = 'flex'; document.body.style.overflow = 'hidden'; }
}
function closeModal(id) {
    var m = document.getElementById(id);
    if (m) { m.classList.remove('show'); m.style.display = ''; document.body.style.overflow = ''; }
}

// ??? Main tab switch ???
function switchMainTab(tab, btn) {
    document.querySelectorAll('.nav-tab').forEach(function(b){ b.classList.remove('active'); });
    btn.classList.add('active');
    document.getElementById('equipmentTab').classList.toggle('active', tab === 'equipment');
    document.getElementById('requestsTab').classList.toggle('active', tab === 'requests');
    document.getElementById('archivedTab').classList.toggle('active', tab === 'archived');
    if (tab === 'requests')  loadRequests();
    if (tab === 'archived')  loadArchived();
}

// ??? Load equipment list ???
    // ??? Load equipment list ???
    function loadEquipment() {
        var tbody = document.getElementById('tblEquipment');
        tbody.innerHTML = '<tr><td colspan="10" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading…</td></tr>';
        $.ajax({
            url: '/Handlers/GetEquipment.ashx',
            method: 'GET',
            dataType: 'json',
            success: function (res) {
                if (!res.success) {
                    tbody.innerHTML = '<tr><td colspan="10" class="text-center" style="color:#dc3545;">Failed to load: ' + (res.error || 'Unknown error') + '</td></tr>';
                    eqNotif('error', 'Load Failed', res.error);
                    return;
                }
                allEquipment = res.equipment || [];
                renderEquipmentTable(allEquipment);
                populateRequestDropdown(allEquipment);
            },
            error: function (xhr) {
                tbody.innerHTML = '<tr><td colspan="10" class="text-center" style="color:#dc3545;"><i class="fa fa-exclamation-triangle"></i> Network error loading equipment.</td></tr>';
                eqNotif('error', 'Network Error', 'Failed to load equipment.');
            }
        });
    }

function getStockPillClass(eq) {
    if (eq.stockQuantity <= 0) return 'stock-out';
    if (eq.stockQuantity <= eq.minimumStock) return 'stock-low';
    if (eq.stockQuantity <= eq.minimumStock * 2) return 'stock-moderate';
    return 'stock-adequate';
}

function renderEquipmentTable(list) {
    var tbody = document.getElementById('tblEquipment');
    var searchVal = (document.getElementById('txtEquipmentSearch').value || '').toLowerCase();
    var typeFilter = document.getElementById('typeFilterLabel').textContent.replace('All Types','').trim();
    var statusFilter = document.getElementById('statusFilterLabel').textContent.replace('All Status','').trim();

    var filtered = list.filter(function(e){
        var matchSearch = !searchVal ||
            (e.equipmentName||'').toLowerCase().includes(searchVal) ||
            (e.equipmentCode||'').toLowerCase().includes(searchVal) ||
            (e.equipmentType||'').toLowerCase().includes(searchVal);
        var matchType = !typeFilter || (e.equipmentType||'') === typeFilter;
        var matchStatus = !statusFilter || (e.stockStatus||'') === statusFilter;
        return matchSearch && matchType && matchStatus;
    });

    if (filtered.length === 0) {
        tbody.innerHTML = '<tr><td colspan="10" class="text-center" style="padding:40px;color:#888;"><i class="fa fa-box-open" style="font-size:40px;display:block;margin-bottom:10px;color:#ddd;"></i>No equipment found</td></tr>';
        return;
    }

    tbody.innerHTML = filtered.map(function(e, i){
        var lowRow = (e.stockQuantity <= e.minimumStock) ? ' low-stock-row' : '';
        return '<tr class="row-select' + lowRow + '" onclick="selectEquipment(this)" data-id="' + e.id + '">' +
            '<td>' + (i+1) + '</td>' +
            '<td class="prod-cell"><img src="/Handlers/GetEquipmentImage.ashx?equipmentId=' + e.id + '" class="thumb" onerror="this.src=\'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzYiIGhlaWdodD0iMzYiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjM2IiBoZWlnaHQ9IjM2IiBmaWxsPSIjZjBmMGYwIiByeD0iNiIvPjwvc3ZnPg==\'" />' +
                (e.equipmentName||'') + '</td>' +
            '<td>' + (e.equipmentType||'-') + '</td>' +
            '<td>' + (e.equipmentCode||'-') + '</td>' +
            '<td>' + (e.stockQuantity||0) + '</td>' +
            '<td>' + (e.minimumStock||0) + '</td>' +
            '<td>?' + parseFloat(e.unitCost||0).toFixed(2) + '</td>' +
            '<td>' + (e.condition||'-') + '</td>' +
            '<td><span class="status-pill ' + getStockPillClass(e) + '">' + (e.stockStatus||'-') + '</span></td>' +
            '<td class="actions">' +
                '<button type="button" class="icon" title="Edit" onclick="event.stopPropagation();showUpdateEquipmentModal(\'' + e.id + '\')"><i class="fa fa-pen"></i></button>' +
                '<button type="button" class="icon" title="Request Stock" onclick="event.stopPropagation();openRequestForEquipment(\'' + e.id + '\')"><i class="fa fa-cart-plus"></i></button>' +
                '<button type="button" class="icon" title="Archive" onclick="event.stopPropagation();confirmArchive(\'' + e.id + '\',\'' + (e.equipmentName||'').replace(/'/g,"\\'") + '\')"><i class="fa fa-archive"></i></button>' +
            '</td>' +
        '</tr>';
    }).join('');
}

function selectEquipment(row) {
    document.querySelectorAll('.row-select').forEach(function(r){ r.classList.remove('selected'); });
    row.classList.add('selected');
    var id = row.getAttribute('data-id');
    var eq = allEquipment.find(function(e){ return e.id === id; });
    if (!eq) return;
    document.getElementById('eqPName').textContent     = eq.equipmentName || '-';
    document.getElementById('eqPType').textContent     = eq.equipmentType || '-';
    document.getElementById('eqPCode').textContent     = eq.equipmentCode || '-';
    document.getElementById('eqPBrand').textContent    = eq.brand  || '-';
    document.getElementById('eqPModel').textContent    = eq.model  || '-';
    document.getElementById('eqPSupplier').textContent = eq.supplierName || '-';
    document.getElementById('eqPStock').textContent    = eq.stockQuantity + ' (min: ' + eq.minimumStock + ')';
    document.getElementById('eqPStatus').textContent   = eq.stockStatus || '-';
    document.getElementById('eqPLocation').textContent = eq.location || '-';
    document.getElementById('eqPDesc').textContent     = eq.description || '-';
    document.getElementById('eqPreviewImage').src =
        '/Handlers/GetEquipmentImage.ashx?equipmentId=' + id + '&t=' + Date.now();
}

// ??? Save (Add) Equipment ???
function saveEquipment() {
    var name = document.getElementById('addEqName').value.trim();
    var type = document.getElementById('addEqType').value;
    if (!name || !type) { eqNotif('warning','Validation','Equipment name and type are required.'); return; }

    var btn = document.getElementById('btnSaveEquipment');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving…';

    var fd = new FormData();
    fd.append('equipmentName',  name);
    fd.append('equipmentType',  type);
    fd.append('equipmentCode',  document.getElementById('addEqCode').value.trim());
    fd.append('brand',          document.getElementById('addEqBrand').value.trim());
    fd.append('model',          document.getElementById('addEqModel').value.trim());
    fd.append('serialNumber',   document.getElementById('addEqSerial').value.trim());
    fd.append('stockQuantity',  document.getElementById('addEqStock').value || 0);
    fd.append('minimumStock',   document.getElementById('addEqMinStock').value || 5);
    fd.append('unitCost',       document.getElementById('addEqCost').value || 0);
    fd.append('condition',      document.getElementById('addEqCondition').value);
    fd.append('location',       document.getElementById('addEqLocation').value.trim());
    fd.append('description',    document.getElementById('addEqDesc').value.trim());
    fd.append('purchaseDate',   document.getElementById('addEqPurchaseDate').value);
    fd.append('warrantyExpiry', document.getElementById('addEqWarranty').value);

    var supSel = document.getElementById('addEqSupplier');
    if (supSel) {
        var supOpt = supSel.options[supSel.selectedIndex];
        fd.append('supplierId', supSel.value || '');
        fd.append('supplierName', supOpt ? (supOpt.getAttribute('data-name') || supOpt.text) : '');
    }

    var img = document.getElementById('addEqImage').files[0];
    if (img) fd.append('equipmentImage', img);

    $.ajax({
        url: '/Handlers/SaveEquipment.ashx', type: 'POST',
        data: fd, processData: false, contentType: false,
        success: function(res){
            if (res.success) {
                eqNotif('success','Equipment Added', res.message, true, 2000);
                closeModal('addEquipmentModal');
                setTimeout(function(){ loadEquipment(); }, 500);
            } else { eqNotif('error','Save Failed', res.error); }
        },
        error: function(){ eqNotif('error','Network Error','Failed to save equipment.'); },
        complete: function(){
            btn.disabled = false;
            btn.innerHTML = '<i class="fa fa-save"></i> Save Equipment';
        }
    });
}

// ??? Show update modal ???
function showUpdateEquipmentModal(id) {
    var eq = allEquipment.find(function(e){ return e.id === id; });
    if (!eq) { eqNotif('error','Not Found','Equipment data not found.'); return; }

    document.getElementById('updEqId').value          = eq.id;
    document.getElementById('updEqName').value        = eq.equipmentName || '';
    document.getElementById('updEqType').value        = eq.equipmentType || '';
    document.getElementById('updEqCode').value        = eq.equipmentCode || '';
    document.getElementById('updEqBrand').value       = eq.brand  || '';
    document.getElementById('updEqModel').value       = eq.model  || '';
    document.getElementById('updEqSerial').value      = eq.serialNumber || '';
    document.getElementById('updEqStock').value       = eq.stockQuantity || 0;
    document.getElementById('updEqMinStock').value    = eq.minimumStock  || 5;
    document.getElementById('updEqCost').value        = eq.unitCost      || 0;
    document.getElementById('updEqCondition').value   = eq.condition     || 'Good';
    document.getElementById('updEqLocation').value    = eq.location      || '';
    document.getElementById('updEqDesc').value        = eq.description   || '';
    document.getElementById('updEqPurchaseDate').value = eq.purchaseDate  || '';
    document.getElementById('updEqWarranty').value    = eq.warrantyExpiry|| '';

    var updSupSel = document.getElementById('updEqSupplier');
    if (updSupSel) {
        // ensure options are bound
        if (!updSupSel.options.length || updSupSel.options.length === 1) {
            bindSupplierDropdowns();
        }
        updSupSel.value = eq.supplierId || '';
    }

    var img = document.getElementById('updEqCurrentImage');
    img.src = '/Handlers/GetEquipmentImage.ashx?equipmentId=' + id + '&t=' + Date.now();
    img.style.display = 'block';

    openModal('updateEquipmentModal');
}

function updateEquipment() {
    var id   = document.getElementById('updEqId').value;
    var name = document.getElementById('updEqName').value.trim();
    var type = document.getElementById('updEqType').value;
    if (!name || !type) { eqNotif('warning','Validation','Equipment name and type are required.'); return; }

    var btn = document.getElementById('btnUpdateEquipment');
    btn.disabled = true; btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving…';

    var fd = new FormData();
    fd.append('equipmentId',   id);
    fd.append('equipmentName', name);
    fd.append('equipmentType', type);
    fd.append('equipmentCode', document.getElementById('updEqCode').value.trim());
    fd.append('brand',         document.getElementById('updEqBrand').value.trim());
    fd.append('model',         document.getElementById('updEqModel').value.trim());
    fd.append('serialNumber',  document.getElementById('updEqSerial').value.trim());
    fd.append('stockQuantity', document.getElementById('updEqStock').value || 0);
    fd.append('minimumStock',  document.getElementById('updEqMinStock').value || 5);
    fd.append('unitCost',      document.getElementById('updEqCost').value || 0);
    fd.append('condition',     document.getElementById('updEqCondition').value);
    fd.append('location',      document.getElementById('updEqLocation').value.trim());
    fd.append('description',   document.getElementById('updEqDesc').value.trim());
    fd.append('purchaseDate',  document.getElementById('updEqPurchaseDate').value);
    fd.append('warrantyExpiry',document.getElementById('updEqWarranty').value);

    var updSupSel = document.getElementById('updEqSupplier');
    if (updSupSel) {
        var updOpt = updSupSel.options[updSupSel.selectedIndex];
        fd.append('supplierId', updSupSel.value || '');
        fd.append('supplierName', updOpt ? (updOpt.getAttribute('data-name') || updOpt.text) : '');
    }

    var imgFile = document.getElementById('updEqImage').files[0];
    if (imgFile) fd.append('equipmentImage', imgFile);

    $.ajax({
        url: '/Handlers/SaveEquipment.ashx', type: 'POST',
        data: fd, processData: false, contentType: false,
        success: function(res){
            if (res.success) {
                eqNotif('success','Equipment Updated', res.message, true, 2000);
                closeModal('updateEquipmentModal');
                setTimeout(function(){ loadEquipment(); }, 500);
            } else { eqNotif('error','Update Failed', res.error); }
        },
        error: function(){ eqNotif('error','Network Error','Failed to update equipment.'); },
        complete: function(){ btn.disabled = false; btn.innerHTML = '<i class="fa fa-save"></i> Save Changes'; }
    });
}

// ??? Archive / Restore ???
function confirmArchive(id, name) {
    pendingArchiveId = id;
    document.getElementById('archiveEqConfirmText').textContent = 'Archive "' + name + '"?';
    document.getElementById('archiveConfirmEqModal').classList.add('show');
}
document.getElementById('archiveEqCancelBtn').onclick = function () {
    pendingArchiveId = null;
    document.getElementById('archiveConfirmEqModal').classList.remove('show');
};
document.getElementById('archiveEqConfirmBtn').onclick = function () {
    document.getElementById('archiveConfirmEqModal').classList.remove('show');
    if (!pendingArchiveId) return;
    $.ajax({
        url: '/Handlers/ArchiveEquipment.ashx', type: 'POST',
        data: JSON.stringify({ equipmentId: pendingArchiveId, action: 'archive' }),
        contentType: 'application/json; charset=utf-8', dataType: 'json',
        success: function(res){
            eqNotif(res.success ? 'success' : 'error', res.success ? 'Archived' : 'Failed', res.message || res.error, true, 2000);
            if (res.success) setTimeout(loadEquipment, 500);
        },
        error: function(){ eqNotif('error','Error','Network error.'); }
    });
    pendingArchiveId = null;
};

function restoreEquipment(id) {
    $.ajax({
        url: '/Handlers/ArchiveEquipment.ashx', type: 'POST',
        data: JSON.stringify({ equipmentId: id, action: 'restore' }),
        contentType: 'application/json; charset=utf-8', dataType: 'json',
        success: function(res){
            eqNotif(res.success ? 'success' : 'error', res.success ? 'Restored' : 'Failed', res.message || res.error, true, 2000);
            if (res.success) { loadArchived(); loadEquipment(); }
        },
        error: function(){ eqNotif('error','Error','Network error.'); }
    });
}

// ??? Stock Request ???
function populateRequestDropdown(list) {
    var sel = document.getElementById('reqEqSelect');
    var opts = '<option value="">Select Equipment…</option>';
    (list || []).forEach(function(e){
        opts += '<option value="' + e.id + '" data-name="' + (e.equipmentName||'').replace(/"/g,'&quot;') +
            '" data-code="' + (e.equipmentCode||'') + '" data-cost="' + (e.unitCost||0) + '">' +
            (e.equipmentName||'') + (e.equipmentCode ? ' [' + e.equipmentCode + ']' : '') + '</option>';
    });
    sel.innerHTML = opts;
}

document.getElementById('reqEqSelect').addEventListener('change', function(){
    var opt = this.options[this.selectedIndex];
    var infoBox = document.getElementById('reqEqInfo');
    if (!this.value) { infoBox.style.display = 'none'; return; }
    var eq = allEquipment.find(function(e){ return e.id === opt.value; });
    if (eq) {
        document.getElementById('reqEqInfoText').innerHTML =
            '<b>Type:</b> ' + (eq.equipmentType||'-') + ' &nbsp;|&nbsp; ' +
            '<b>Current Stock:</b> ' + eq.stockQuantity + ' &nbsp;|&nbsp; ' +
            '<b>Min Stock:</b> ' + eq.minimumStock + ' &nbsp;|&nbsp; ' +
            '<b>Unit Cost:</b> ?' + parseFloat(eq.unitCost||0).toFixed(2);
        // Pre-fill estimated cost
        var qty = parseInt(document.getElementById('reqQty').value) || 1;
        document.getElementById('reqEstCost').value = (qty * parseFloat(eq.unitCost||0)).toFixed(2);
        infoBox.style.display = 'block';
    }
});
document.getElementById('reqQty').addEventListener('input', function(){
    var opt = document.getElementById('reqEqSelect').options[document.getElementById('reqEqSelect').selectedIndex];
    if (!opt || !opt.value) return;
    var eq = allEquipment.find(function(e){ return e.id === opt.value; });
    if (eq) document.getElementById('reqEstCost').value = (parseInt(this.value||1) * parseFloat(eq.unitCost||0)).toFixed(2);
});

function openRequestForEquipment(id) {
    var sel = document.getElementById('reqEqSelect');
    sel.value = id;
    sel.dispatchEvent(new Event('change'));
    openModal('requestStockModal');
}

function submitStockRequest() {
    var eqId = document.getElementById('reqEqSelect').value;
    var qty  = parseInt(document.getElementById('reqQty').value);
    var purpose = document.getElementById('reqPurpose').value.trim();
    if (!eqId)        { eqNotif('warning','Validation','Please select an equipment.'); return; }
    if (!qty || qty < 1){ eqNotif('warning','Validation','Quantity must be at least 1.'); return; }
    if (!purpose)     { eqNotif('warning','Validation','Purpose/reason is required.'); return; }

    var btn = document.getElementById('btnSubmitRequest');
    btn.disabled = true; btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Submitting…';

    var eq = allEquipment.find(function(e){ return e.id === eqId; });
    $.ajax({
        url: '/Handlers/SaveEquipmentStockRequest.ashx', type: 'POST',
        data: JSON.stringify({
            equipmentId:           eqId,
            equipmentName:         eq ? eq.equipmentName : '',
            equipmentCode:         eq ? eq.equipmentCode : '',
            // include supplier info from equipment
            supplierId:            eq ? (eq.supplierId || '') : '',
            supplierName:          eq ? (eq.supplierName || '') : '',
            quantityRequested:     qty,
            purpose:               purpose,
            requestedBy:           '<%= Page.User.Identity.Name ?? "Admin" %>',
            priority:              document.getElementById('reqPriority').value,
            estimatedCost:         parseFloat(document.getElementById('reqEstCost').value)||0,
            notes:                 document.getElementById('reqNotes').value.trim(),
            expectedDeliveryDate:  document.getElementById('reqDelivery').value,
            // new requests are always Pending
            status:                'Pending'
        }),
        contentType: 'application/json; charset=utf-8', dataType: 'json',
        success: function(res){
            if (res.success) {
                eqNotif('success','Request Submitted', res.message, true, 2500);
                closeModal('requestStockModal');
                clearRequestForm();
                // refresh requests tab if visible
                loadRequests();
            } else { eqNotif('error','Failed', res.error); }
        },
        error: function(){ eqNotif('error','Network Error','Failed to submit request.'); },
        complete: function(){ btn.disabled = false; btn.innerHTML = '<i class="fa fa-paper-plane"></i> Submit Request'; }
    });
}

function clearRequestForm() {
    ['reqEqSelect','reqQty','reqPriority','reqEstCost','reqDelivery','reqPurpose','reqNotes']
        .forEach(function(id){ var el = document.getElementById(id); if(el) el.value=''; });
    document.getElementById('reqPriority').value = 'Normal';
    document.getElementById('reqEqInfo').style.display = 'none';
}

// ??? Load Requests ???
    function loadRequests() {
        var tbody = document.getElementById('tblRequests');
        tbody.innerHTML = '<tr><td colspan="8" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading…</td></tr>';
        $.ajax({
            url: '/Handlers/GetEquipmentStockRequests.ashx',
            method: 'GET', dataType: 'json',
            success: function (res) {
                if (!res.success) { eqNotif('error', 'Error', res.error); return; }
                var list = res.requests || [];
                if (list.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="8" class="text-center" style="padding:30px;color:#888;">No stock requests found.</td></tr>';
                    return;
                }
                tbody.innerHTML = list.map(function (r) {
                    var financeActions;

                    // ONLY show Approve button when status is ApprovedByFinance
                    // Normalize status so we can match both DB value and our internal code
                    var rawStatus = r.status || '';
                    var normalizedStatus = rawStatus.replace(/\s+/g, ''); // e.g. "Approved by Finance" -> "ApprovedbyFinance"
                    normalizedStatus = normalizedStatus.toLowerCase();

                    // ONLY show Approve button when status is (Approved by Finance / ApprovedByFinance)
                    if (normalizedStatus === 'approvedbyfinance') {
                        financeActions =
                            '<button type="button" class="btn-animated btn-success" ' +
                            'style="padding:6px 10px;font-size:11px;" ' +
                            'onclick="approveRequestByAdmin(event, \'' + r.id + '\')">' +
                            '<i class="fa fa-check-circle"></i> Approve' +
                            '</button>';
                    } else {
                        // No button otherwise; just show the status text
                        financeActions = '<span style="color:#aaa;font-size:12px;">' + formatStatus(rawStatus) + '</span>';
                    }

                    return '<tr>' +
                        '<td><span style="font-family:monospace;font-size:12px;">' + r.displayId + '</span></td>' +
                        '<td><b>' + (r.equipmentName || '-') + '</b>' + (r.equipmentCode ? '<br><span style="font-size:11px;color:#888;">' + r.equipmentCode + '</span>' : '') + '</td>' +
                        '<td style="font-weight:700;">' + r.quantityRequested + '</td>' +
                        '<td>' + (r.requestedBy || '-') + '</td>' +
                        '<td>' + (r.requestDate || '-') + '</td>' +
                        '<td><span class="status-pill ' + getPriorityClass(r.priority) + '">' + (r.priority || 'Normal') + '</span></td>' +
                        '<td><span class="status-pill ' + r.statusBadgeClass + '">' + formatStatus(r.status) + '</span>' +
                        (r.financeApprovedBy ? '<br><span style="font-size:11px;color:#888;">by ' + r.financeApprovedBy + '</span>' : '') +
                        (r.approvedCost ? '<br><span style="font-size:11px;color:#2e7d32;">?' + parseFloat(r.approvedCost).toFixed(2) + '</span>' : '') +
                        '</td>' +
                        '<td>' + financeActions + '</td>' +
                        '</tr>';
                }).join('');
            },
            error: function () { eqNotif('error', 'Error', 'Failed to load requests.'); }
        });
    }

function getPriorityClass(p) {
    if (p === 'Urgent' || p === 'High') return 'stock-low';
    if (p === 'Normal') return 'stock-adequate';
    return 'stock-moderate';
}

    function formatStatus(s) {
        var map = {
            Pending: 'Pending',
            ApprovedByFinance: '? Finance Approved',
            ApprovedByAdmin: 'Approved by Admin',
            Completed: 'Completed',
            Rejected: 'Rejected'
        };
        return map[s] || s;
    }

// ??? Finance approval modal ???
var currentFinanceRequestId = null;
var rejectMode = false;

function showFinanceModal(requestId) {
    currentFinanceRequestId = requestId;
    rejectMode = false;
    document.getElementById('financeRequestId').value = requestId;
    document.getElementById('financeRejectSection').style.display = 'none';
    document.getElementById('btnFinanceReject').innerHTML = '<i class="fa fa-times-circle"></i> Reject';
    document.getElementById('btnFinanceApprove').style.display = 'flex';

    // Pre-fill approver name
    document.getElementById('financeApprovedBy').value = '<%= Session["UserName"] ?? "Finance Officer" %>';

    // Find the request to show summary
    $.ajax({
        url: '/Handlers/GetEquipmentStockRequests.ashx', method: 'GET', dataType: 'json',
        success: function(res){
            var req = (res.requests || []).find(function(r){ return r.id === requestId; });
            if (req) {
                document.getElementById('financeRequestSummary').innerHTML =
                    'Request <b>' + req.displayId + '</b> — <b>' + req.quantityRequested +
                    ' units</b> of <b>' + req.equipmentName + '</b>' +
                    (req.estimatedCost ? ' | Est. Cost: <b>?' + parseFloat(req.estimatedCost).toFixed(2) + '</b>' : '') +
                    '<br>Requested by: ' + req.requestedBy + ' | Purpose: ' + (req.purpose||'N/A');
                document.getElementById('financeApprovedCost').value = req.estimatedCost || '';
            }
        }
    });
    openModal('financeModal');
}

function toggleRejectSection() {
    rejectMode = !rejectMode;
    document.getElementById('financeRejectSection').style.display = rejectMode ? 'block' : 'none';
    document.getElementById('btnFinanceApprove').style.display    = rejectMode ? 'none'  : 'flex';
    document.getElementById('btnFinanceReject').innerHTML = rejectMode
        ? '<i class="fa fa-times"></i> Cancel Reject'
        : '<i class="fa fa-times-circle"></i> Reject';
    if (rejectMode) submitFinanceAction('reject');
}

function submitFinanceAction(action) {
    if (!currentFinanceRequestId) return;
    if (action === 'reject') {
        if (!rejectMode) { toggleRejectSection(); return; }
        var reason = document.getElementById('financeRejectReason').value.trim();
        if (!reason) { eqNotif('warning','Reason Required','Please enter a rejection reason.'); return; }
    }

    var btn = action === 'approve' ? document.getElementById('btnFinanceApprove') : document.getElementById('btnFinanceReject');
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Processing…'; }

    $.ajax({
        url: '/Handlers/ProcessEquipmentRequest.ashx', type: 'POST',
        data: JSON.stringify({
            requestId:    currentFinanceRequestId,
            action:       action,
            approvedBy:   document.getElementById('financeApprovedBy').value.trim() || 'Finance',
            approvedCost: parseFloat(document.getElementById('financeApprovedCost').value)||0,
            notes:        document.getElementById('financeNotes').value.trim(),
            reason:       action === 'reject' ? document.getElementById('financeRejectReason').value.trim() : ''
        }),
        contentType: 'application/json; charset=utf-8', dataType: 'json',
        success: function(res){
            if (res.success) {
                eqNotif('success', action === 'approve' ? 'Approved by Finance!' : 'Request Rejected', res.message, true, 2500);
                closeModal('financeModal');
                loadRequests();
            } else { eqNotif('error','Failed', res.error); }
        },
        error: function(){ eqNotif('error','Error','Network error.'); },
        complete: function(){
            if (btn) { btn.disabled = false; btn.innerHTML = action === 'approve' ? '<i class="fa fa-check-circle"></i> Approve' : '<i class="fa fa-times-circle"></i> Reject'; }
        }
    });
}

// ??? Complete Request ???
function showCompleteModal(requestId, defaultQty) {
    document.getElementById('completeRequestId').value = requestId;
    document.getElementById('completeQtyAdded').value  = defaultQty || '';
    document.getElementById('completeRequestSummary').textContent =
        'Mark request as completed and add stock to equipment inventory.';
    openModal('completeRequestModal');
}

function submitComplete() {
    var requestId = document.getElementById('completeRequestId').value;
    var qty = parseInt(document.getElementById('completeQtyAdded').value);
    if (!qty || qty < 1) { eqNotif('warning','Quantity','Please enter the quantity received.'); return; }
    $.ajax({
        url: '/Handlers/ProcessEquipmentRequest.ashx', type: 'POST',
        data: JSON.stringify({ requestId: requestId, action: 'complete', quantityAdded: qty }),
        contentType: 'application/json; charset=utf-8', dataType: 'json',
        success: function(res){
            if (res.success) {
                eqNotif('success','Completed!', res.message, true, 2500);
                closeModal('completeRequestModal');
                loadRequests(); loadEquipment();
            } else { eqNotif('error','Error', res.error); }
        },
        error: function(){ eqNotif('error','Error','Network error.'); }
    });
    }

    function approveRequestByAdmin(evt, requestId) {
        if (evt) {
            evt.preventDefault();
            evt.stopPropagation();
        }
        if (!requestId) return;

        $.ajax({
            url: '/Handlers/ProcessEquipmentRequest.ashx',
            type: 'POST',
            data: JSON.stringify({
                requestId: requestId,
                action: 'adminApprove'
            }),
            contentType: 'application/json; charset=utf-8',
            dataType: 'json',
            success: function (res) {
                if (res.success) {
                    eqNotif('success', 'Approved', res.message || 'Request approved by admin.', true, 2500);
                    loadRequests();
                } else {
                    eqNotif('error', 'Failed', res.error || 'Unable to approve request.');
                }
            },
            error: function () {
                eqNotif('error', 'Error', 'Network error while approving request.');
            }
        });
    }

// ??? Load Archived ???
function loadArchived() {
    var tbody = document.getElementById('tblArchived');
    tbody.innerHTML = '<tr><td colspan="7" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading…</td></tr>';
    $.ajax({
        url: '/Handlers/GetEquipment.ashx?includeArchived=true',
        method: 'GET', dataType: 'json',
        success: function(res){
            var list = (res.equipment||[]).filter(function(e){ return e.status === 'Archived'; });
            if (list.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="text-center" style="padding:30px;color:#888;">No archived equipment.</td></tr>';
                return;
            }
            tbody.innerHTML = list.map(function(e,i){
                return '<tr>' +
                    '<td>' + (i+1) + '</td>' +
                    '<td>' + (e.equipmentName||'') + '</td>' +
                    '<td>' + (e.equipmentType||'-') + '</td>' +
                    '<td>' + (e.equipmentCode||'-') + '</td>' +
                    '<td>' + (e.stockQuantity||0) + '</td>' +
                    '<td>' + (e.condition||'-') + '</td>' +
                    '<td><button class="btn-animated btn-success" style="padding:6px 12px;font-size:12px;" onclick="restoreEquipment(\'' + e.id + '\')"><i class="fa fa-undo"></i> Restore</button></td>' +
                '</tr>';
            }).join('');
        },
        error: function(){ eqNotif('error','Error','Failed to load archived equipment.'); }
    });
}

// ??? Image previews ???
document.getElementById('addEqImage').addEventListener('change', function(){
    var f = this.files[0];
    if (f && f.type.startsWith('image/')) {
        var r = new FileReader();
        r.onload = function(e){
            document.getElementById('addEqImagePreviewImg').src = e.target.result;
            document.getElementById('addEqImagePreview').style.display = 'block';
        };
        r.readAsDataURL(f);
    }
});

// ??? Search / Filter ???
document.getElementById('txtEquipmentSearch').addEventListener('input', function(){
    renderEquipmentTable(allEquipment);
});

(function setupFilterDropdowns(){
    function buildDropdown(btnId, labelId, items, onSelect) {
        var btn = document.getElementById(btnId);
        if (!btn) return;
        var dd = document.createElement('div');
        dd.style.cssText = 'position:absolute;top:100%;left:0;background:#fff;border:1px solid #e9ecef;' +
            'border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,.1);min-width:180px;display:none;z-index:999;margin-top:4px;';
        items.forEach(function(item){
            var el = document.createElement('div');
            el.textContent = item;
            el.style.cssText = 'padding:10px 14px;cursor:pointer;font-size:13px;transition:background .15s;';
            el.onmouseover = function(){ el.style.background='#f8f9fa'; };
            el.onmouseout  = function(){ el.style.background='#fff'; };
            el.onclick = function(){
                document.getElementById(labelId).textContent = item === 'All' ? (labelId === 'typeFilterLabel' ? 'All Types' : 'All Status') : item;
                dd.style.display = 'none';
                onSelect(item === 'All' ? '' : item);
            };
            dd.appendChild(el);
        });
        btn.parentElement.style.position = 'relative';
        btn.parentElement.appendChild(dd);
        btn.addEventListener('click', function(e){ e.stopPropagation(); dd.style.display = dd.style.display === 'none' ? 'block' : 'none'; });
        document.addEventListener('click', function(){ dd.style.display = 'none'; });
    }

    buildDropdown('btnTypeFilter', 'typeFilterLabel',
        ['All','Production Equipment','Packaging Equipment','Laboratory Equipment','Safety Equipment','Office Equipment','IT Equipment','Cleaning Equipment','Transport Equipment','Other'],
        function(){ renderEquipmentTable(allEquipment); });

    buildDropdown('btnStatusFilter', 'statusFilterLabel',
        ['All','Adequate','Moderate','Low Stock','Out of Stock'],
        function(){ renderEquipmentTable(allEquipment); });
})();

// ??? Add / Request buttons ???
document.getElementById('btnAddEquipment').onclick = function(){ openModal('addEquipmentModal'); };
document.getElementById('btnRequestStock').onclick  = function(){ openModal('requestStockModal'); };

// ??? Init ???
document.addEventListener('DOMContentLoaded', function(){
    loadSuppliersForEquipment();
    loadEquipment();
});




   
</script>
</asp:Content>
