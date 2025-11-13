using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Web.Script.Services;
using System.Diagnostics;
using System.Collections.Generic;

namespace InventorySystemSiaProject.WebPages
{
    public class StatusChangeResult
    {
        public bool success { get; set; }
        public string message { get; set; }
    }

    public partial class PstockForm : System.Web.UI.Page
    {
        private SupplierService _supplierService;
        private ProductService _productService;

        protected void Page_Load(object sender, EventArgs e)
        {

            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
            _supplierService = new SupplierService();
            _productService = new ProductService();

            if (!IsPostBack)
            {
                LoadProducts();
                // Register async tasks
                RegisterAsyncTask(new PageAsyncTask(LoadSuppliersAsync));
                RegisterAsyncTask(new PageAsyncTask(LoadIngredientStockRequestsAsync));
                
                // Check for success messages from redirect
                if (Request.QueryString["msg"] != null)
                {
                    string msg = Request.QueryString["msg"];
                    switch (msg)
                    {
                        case "created":
                            ShowSupplierMessage("✅ Supplier added successfully!", "success");
                            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                                "switchTab('suppliers');", true);
                            break;
                        case "updated":
                            ShowSupplierMessage("✅ Supplier updated successfully!", "success");
                            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                                "switchTab('suppliers');", true);
                            break;
                        case "deleted":
                            ShowSupplierMessage("✅ Supplier deleted successfully!", "success");
                            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                                "switchTab('suppliers');", true);
                            break;
                        case "requestCreated":
                            ShowMessage("✅ Stock request created successfully!", "success");
                            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                                "switchTab('requests');", true);
                            break;
                        case "requestUpdated":
                            ShowMessage("✅ Stock request updated successfully!", "success");
                            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                                "switchTab('requests');", true);
                            break;
                        case "ingredientRequestCreated":
                            ShowMessage("✅ Ingredient stock request created successfully!", "success");
                            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                                "switchTab('requests');", true);
                            break;
                    }
                    
                    // CRITICAL: Remove the query string to prevent form resubmission on refresh
                    string cleanUrl = Request.Url.GetLeftPart(UriPartial.Path);
                    if (!string.IsNullOrEmpty(Request.QueryString["tab"]))
                    {
                        cleanUrl += "?tab=" + Request.QueryString["tab"];
                    }
                    Response.Redirect(cleanUrl, false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
                
                // Handle tab parameter for initial load (when navigating from sidebar)
                string tabParam = Request.QueryString["tab"];
                if (!string.IsNullOrEmpty(tabParam))
                {
                    ClientScript.RegisterStartupScript(this.GetType(), "InitialTabSwitch",
                        $"switchTab('{tabParam}');", true);
                }
            }
        }

        #region Product Stock Methods

        private void LoadProducts()
        {
            try
            {
                // Get all product variants
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var allVariants = variantsCollection.Find(FilterDefinition<ProductVariant>.Empty).ToList();

                // Get all products
                var productsCollection = DatabaseHelper.GetProductsCollection();
                var allProducts = productsCollection.Find(FilterDefinition<Product>.Empty).ToList();

                // Filter variants: only include those whose parent product has a supplier
                var variantsWithSuppliers = allVariants
                    .Where(variant =>
                    {
                        var product = allProducts.FirstOrDefault(p => p.Id == variant.ProductId);
                        // Check if product exists and has a supplier
                        return product != null && !string.IsNullOrWhiteSpace(product.SupplierId);
                    })
                    .ToList();

                System.Diagnostics.Debug.WriteLine($"📦 Total variants: {allVariants.Count}");
                System.Diagnostics.Debug.WriteLine($"✅ Variants with suppliers: {variantsWithSuppliers.Count}");

                gvProducts.DataSource = variantsWithSuppliers;
                gvProducts.DataBind();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error loading products: {ex.Message}");
                lblMessage.Text = $"Error loading products: {ex.Message}";
                lblMessage.ForeColor = System.Drawing.Color.Red;
                lblMessage.Visible = true;
            }
        }

        protected void gvProducts_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "SendHelp")
            {
                string variantId = e.CommandArgument.ToString();

                try
                {
                    // Get variant details
                    var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                    var variant = variantsCollection.Find(x => x.Id == variantId).FirstOrDefault();

                    if (variant == null)
                    {
                        ShowMessage("❌ Product variant not found.", "danger");
                        return;
                    }

                    // Get product details to find supplier
                    var productsCollection = DatabaseHelper.GetProductsCollection();
                    var product = productsCollection.Find(p => p.Id == variant.ProductId).FirstOrDefault();

                    if (product == null || string.IsNullOrWhiteSpace(product.SupplierId))
                    {
                        ShowMessage("❌ No supplier assigned to this product.", "danger");
                        return;
                    }

                    // Get supplier details
                    var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                    var supplier = suppliersCollection.Find(s => s.SupplierID == product.SupplierId).FirstOrDefault();

                    if (supplier == null)
                    {
                        ShowMessage("❌ Supplier information not found.", "danger");
                        return;
                    }

                    if (string.IsNullOrWhiteSpace(supplier.SupEmail))
                    {
                        ShowMessage("❌ Supplier email is not available.", "danger");
                        return;
                    }

                    // Open stock request modal with JavaScript
                    string script = $@"
                        openStockRequestModal(
                            '{variant.Id}',
                            '{product.Id}',
                            '{supplier.SupplierID}',
                            '{variant.VariantName.Replace("'", "\\'")}',
                            {variant.StockQuantity},
                            {variant.MinimumStock},
                            '{supplier.SupName.Replace("'", "\\'")}'
                        );";
                    
                    ClientScript.RegisterStartupScript(this.GetType(), "OpenStockRequest", script, true);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ Error opening stock request modal: {ex.Message}");
                    ShowMessage($"❌ Error: {ex.Message}", "danger");
                }
            }
        }

        protected async void btnSendRequest_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
                return;

            try
            {
                string variantId = hfVariantId.Value;
                string productId = hfProductId.Value;
                string supplierId = hfSupplierId2.Value;
                int requestedQuantity = int.Parse(txtRequestQuantity.Text.Trim());
                string additionalNotes = txtRequestNotes.Text.Trim();
                
                // Parse expected delivery date if provided
                DateTime? expectedDeliveryDate = null;
                if (!string.IsNullOrWhiteSpace(txtExpectedDeliveryDate.Text))
                {
                    DateTime parsedDate;
                    if (DateTime.TryParse(txtExpectedDeliveryDate.Text, out parsedDate))
                    {
                        expectedDeliveryDate = parsedDate;
                    }
                }

                // Get variant details
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var variant = variantsCollection.Find(x => x.Id == variantId).FirstOrDefault();

                if (variant == null)
                {
                    ShowMessage("❌ Product variant not found.", "danger");
                    return;
                }

                // Get supplier details
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                var supplier = suppliersCollection.Find(s => s.SupplierID == supplierId).FirstOrDefault();

                if (supplier == null)
                {
                    ShowMessage("❌ Supplier not found.", "danger");
                    return;
                }

                if (string.IsNullOrWhiteSpace(supplier.SupEmail))
                {
                    ShowMessage("❌ Supplier email is not available.", "danger");
                    return;
                }

                // Get current user
                string requestedBy = "System Admin"; // Default
                string requestedByUserId = "";
                
                if (Session["UserName"] != null)
                {
                    requestedBy = Session["UserName"].ToString();
                }
                if (Session["UserId"] != null)
                {
                    requestedByUserId = Session["UserId"].ToString();
                }

                // Create stock request record
                var stockRequest = new StockRequest
                {
                    ProductVariantID = variantId,
                    ProductID = productId,
                    SupplierID = supplierId,
                    QuantityRequested = requestedQuantity,
                    Instructions = additionalNotes,
                    RequestedBy = requestedBy,
                    RequestedByUserId = requestedByUserId,
                    CurrentStockAtRequest = variant.StockQuantity,
                    MinimumStockLevel = variant.MinimumStock,
                    UnitPrice = variant.Price,
                    Priority = variant.IsLowStock ? "High" : "Normal",
                    ExpectedDeliveryDate = expectedDeliveryDate
                };

                stockRequest.PrepareForInsertion();

                // Save to database
                var requestId = await _productService.CreateStockRequestAsync(stockRequest);

                if (!string.IsNullOrEmpty(requestId))
                {
                    // Send stock request email with approval links
                    SendEmaikService.SendStockRequestEmail(
                        supplierEmail: supplier.SupEmail,
                        supplierName: supplier.SupName,
                        productName: variant.VariantName,
                        currentStock: variant.StockQuantity,
                        minimumStock: variant.MinimumStock,
                        requestedQuantity: requestedQuantity,
                        additionalNotes: additionalNotes,
                        expectedDeliveryDate: expectedDeliveryDate,
                        requestId: requestId,
                        requestDate: stockRequest.RequestDate
                    );

                    // Mark email as sent
                    stockRequest.MarkEmailSent();
                    await _productService.UpdateStockRequestAsync(stockRequest);

                    Response.Redirect("~/WebPages/ProductStock.aspx?tab=requests&msg=requestCreated", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
                else
                {
                    ShowMessage("❌ Failed to create stock request.", "danger");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error sending stock request: {ex.Message}");
                ShowMessage($"❌ Failed to send request: {ex.Message}", "danger");
            }
        }

        protected void btnCancelRequest_Click(object sender, EventArgs e)
        {
            // Clear form
            txtRequestQuantity.Text = string.Empty;
            txtExpectedDeliveryDate.Text = string.Empty;
            txtRequestNotes.Text = string.Empty;
            hfVariantId.Value = string.Empty;
            hfProductId.Value = string.Empty;
            hfSupplierId2.Value = string.Empty;
        }

        private void ShowMessage(string message, string type)
        {
            lblMessage.Text = message;
            lblMessage.Visible = true;
            
            switch (type.ToLower())
            {
                case "success":
                    lblMessage.CssClass = "alert alert-success";
                    lblMessage.ForeColor = System.Drawing.Color.Green;
                    break;
                case "danger":
                case "error":
                    lblMessage.CssClass = "alert alert-danger";
                    lblMessage.ForeColor = System.Drawing.Color.Red;
                    break;
                case "info":
                    lblMessage.CssClass = "alert alert-info";
                    lblMessage.ForeColor = System.Drawing.Color.Blue;
                    break;
            }

            // Auto-hide message after 5 seconds
            ClientScript.RegisterStartupScript(this.GetType(), "HideMainMessage",
                "setTimeout(function() { var msg = document.getElementById('" + lblMessage.ClientID + "'); if(msg) msg.style.display='none'; }, 5000);", true);
        }

        #endregion

        #region Supplier CRUD Methods

        private async Task LoadSuppliersAsync()
        {
            try
            {
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                gvSuppliers.DataSource = suppliers;
                gvSuppliers.DataBind();
            }
            catch (Exception ex)
            {
                ShowSupplierMessage($"Error loading suppliers: {ex.Message}", "danger");
            }
        }

        protected async void btnSaveSupplier_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
                return;

            try
            {
                var supplier = new Supplier
                {
                    SupName = txtSupName.Text.Trim(),
                    SupContactPer = txtSupContactPer.Text.Trim(),
                    SupContactNo = txtSupContactNo.Text.Trim(),
                    SupEmail = txtSupEmail.Text.Trim(),
                    SupAddress = txtSupAddress.Text.Trim()
                };

                if (!string.IsNullOrWhiteSpace(hfSupplierId.Value))
                {
                    // Update existing supplier
                    var success = await _supplierService.UpdateSupplierAsync(hfSupplierId.Value, supplier);
                    if (success)
                    {
                        Response.Redirect("~/WebPages/ProductStock.aspx?tab=suppliers&msg=updated", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    else
                    {
                        ShowSupplierMessage("❌ Failed to update supplier.", "danger");
                    }
                }
                else
                {
                    // Create new supplier
                    var supplierId = await _supplierService.CreateSupplierAsync(supplier);
                    if (!string.IsNullOrWhiteSpace(supplierId))
                    {
                        Response.Redirect("~/WebPages/ProductStock.aspx?tab=suppliers&msg=created", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    else
                    {
                        ShowSupplierMessage("❌ Failed to add supplier.", "danger");
                    }
                }
            }
            catch (ArgumentException argEx)
            {
                ShowSupplierMessage($"❌ Validation Error: {argEx.Message}", "danger");
            }
            catch (Exception ex)
            {
                ShowSupplierMessage($"❌ Error: {ex.Message}", "danger");
            }
        }

        protected void btnCancelSupplier_Click(object sender, EventArgs e)
        {
            // Clear the form server-side
            ClearSupplierForm();
            
            // Switch to suppliers tab and close modal
            ClientScript.RegisterStartupScript(this.GetType(), "CloseSupplierModal",
                "closeSupplierModal(); switchTab('suppliers');", true);
        }

        protected async void gvSuppliers_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            string supplierId = e.CommandArgument.ToString();

            if (e.CommandName == "EditSupplier")
            {
                try
                {
                    var supplier = await _supplierService.GetSupplierByIdAsync(supplierId);
                    if (supplier != null)
                    {
                        // Populate form for editing
                        hfSupplierId.Value = supplier.SupplierID;
                        txtSupName.Text = supplier.SupName;
                        txtSupContactPer.Text = supplier.SupContactPer;
                        txtSupContactNo.Text = supplier.SupContactNo;
                        txtSupEmail.Text = supplier.SupEmail;
                        txtSupAddress.Text = supplier.SupAddress;
                        lblFormTitle.Text = "Edit Supplier";
                        btnSaveSupplier.Text = "Update Supplier";

                        // CRITICAL FIX: Switch to suppliers tab first, then open modal with a delay
                        string script = @"
                            console.log('🔧 Opening edit supplier modal...');
                            // First, switch to suppliers tab
                            switchTab('suppliers');
                            // Then open the modal after a short delay to ensure tab is fully switched
                            setTimeout(function() {
                                console.log('📂 Opening supplier modal for edit');
                                openSupplierModal();
                            }, 100);
                        ";
                        ClientScript.RegisterStartupScript(this.GetType(), "OpenEditModal", script, true);
                    }
                }
                catch (Exception ex)
                {
                    ShowSupplierMessage($"❌ Error loading supplier: {ex.Message}", "danger");
                    
                    // Make sure we're on the suppliers tab to show the error
                    ClientScript.RegisterStartupScript(this.GetType(), "SwitchToSuppliers",
                        "switchTab('suppliers');", true);
                }
            }
            else if (e.CommandName == "DeleteSupplier")
            {
                try
                {
                    var success = await _supplierService.DeleteSupplierAsync(supplierId);
                    if (success)
                    {
                        Response.Redirect("~/WebPages/ProductStock.aspx?tab=suppliers&msg=deleted", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    else
                    {
                        ShowSupplierMessage("❌ Failed to delete supplier.", "danger");
                        
                        // Make sure we're on the suppliers tab to show the error
                        ClientScript.RegisterStartupScript(this.GetType(), "SwitchToSuppliers",
                            "switchTab('suppliers');", true);
                    }
                }
                catch (Exception ex)
                {
                    ShowSupplierMessage($"❌ Error deleting supplier: {ex.Message}", "danger");
                    
                    // Make sure we're on the suppliers tab to show the error
                    ClientScript.RegisterStartupScript(this.GetType(), "SwitchToSuppliers",
                        "switchTab('suppliers');", true);
                }
            }
        }

        private void ClearSupplierForm()
        {
            hfSupplierId.Value = string.Empty;
            txtSupName.Text = string.Empty;
            txtSupContactPer.Text = string.Empty;
            txtSupContactNo.Text = string.Empty;
            txtSupEmail.Text = string.Empty;
            txtSupAddress.Text = string.Empty;
            lblFormTitle.Text = "Add New Supplier";
            btnSaveSupplier.Text = "Save Supplier";
        }

        private void ShowSupplierMessage(string message, string type)
        {
            lblSupplierMessage.Text = message;
            pnlSupplierMessage.Visible = true;
            
            pnlSupplierMessage.CssClass = "alert";
            switch (type.ToLower())
            {
                case "success":
                    pnlSupplierMessage.CssClass += " alert-success";
                    break;
                case "danger":
                case "error":
                    pnlSupplierMessage.CssClass += " alert-danger";
                    break;
                case "info":
                    pnlSupplierMessage.CssClass += " alert-info";
                    break;
            }

            // Auto-hide message after 5 seconds
            ClientScript.RegisterStartupScript(this.GetType(), "HideMessage",
                "setTimeout(function() { var msg = document.getElementById('" + pnlSupplierMessage.ClientID + "'); if(msg) msg.style.display='none'; }, 5000);", true);
        }

        #endregion

        #region Stock Requests Methods

        private async Task LoadStockRequestsAsync()
        {
            try
            {
                // Get selected filter
                string statusFilter = ddlStatusFilter?.SelectedValue;

                // Get stock requests with optional filter
                var stockRequests = await _productService.GetStockRequestsAsync(status: statusFilter);

                // Get all variants for lookup
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var allVariants = variantsCollection.Find(FilterDefinition<ProductVariant>.Empty).ToList();

                // Get all suppliers for lookup
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                var allSuppliers = suppliersCollection.Find(FilterDefinition<Supplier>.Empty).ToList();

                // Enrich stock requests with related data
                foreach (var request in stockRequests)
                {
                    request.ProductVariant = allVariants.FirstOrDefault(v => v.Id == request.ProductVariantID);
                    request.Supplier = allSuppliers.FirstOrDefault(s => s.SupplierID == request.SupplierID);
                }

                gvStockRequests.DataSource = stockRequests;
                gvStockRequests.DataBind();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error loading stock requests: {ex.Message}");
                ShowMessage($"Error loading stock requests: {ex.Message}", "danger");
            }
        }

        // Loads ingredient stock requests and binds to gvStockRequests
        private async Task LoadIngredientStockRequestsAsync()
        {
            try
            {
                string statusFilter = ddlStatusFilter?.SelectedValue;
                var ingredientStockRequestsCollection = Helpers.DatabaseHelper.GetIngredientStockRequestsCollection();
                var filter = string.IsNullOrEmpty(statusFilter) || statusFilter == "All Status"
                    ? Builders<Models.IngredientStockRequest>.Filter.Empty
                    : Builders<Models.IngredientStockRequest>.Filter.Eq(r => r.RequestStatus, statusFilter);
                var ingredientRequests = await ingredientStockRequestsCollection.Find(filter).ToListAsync();
                var ingredientsCollection = Helpers.DatabaseHelper.GetIngredientsCollection();
                var allIngredients = await ingredientsCollection.Find(FilterDefinition<Models.Ingredient>.Empty).ToListAsync();
                var suppliersCollection = Helpers.DatabaseHelper.GetSuppliersCollection();
                var allSuppliers = await suppliersCollection.Find(FilterDefinition<Models.Supplier>.Empty).ToListAsync();
                foreach (var request in ingredientRequests)
                {
                    var ingredient = allIngredients.FirstOrDefault(i => i.Id == request.IngredientID);
                    var supplier = allSuppliers.FirstOrDefault(s => s.SupplierID == request.SupplierID);
                    request.IngredientName = ingredient?.IngredientName ?? "N/A";
                    request.SupplierName = supplier?.SupName ?? "N/A";
                }
                gvStockRequests.DataSource = ingredientRequests;
                gvStockRequests.DataBind();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error loading ingredient stock requests: {ex.Message}");
                ShowMessage($"Error loading ingredient stock requests: {ex.Message}", "danger");
            }
        }

        protected async void gvStockRequests_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            string requestId = e.CommandArgument.ToString();

            try
            {
                if (e.CommandName == "ApproveRequest")
                {
                    // Check if this is an ingredient stock request
                    var ingredientStockRequestsCollection = Helpers.DatabaseHelper.GetIngredientStockRequestsCollection();
                    var filter = Builders<IngredientStockRequest>.Filter.Eq("_id", new MongoDB.Bson.ObjectId(requestId));
                    var ingredientRequest = await ingredientStockRequestsCollection.Find(filter).FirstOrDefaultAsync();
                    if (ingredientRequest != null)
                    {
                        // --- INGREDIENT STOCK REQUEST APPROVAL LOGIC ---
                        string processedBy = Session["UserName"]?.ToString() ?? "System Admin";
                        string processedByUserId = Session["UserId"]?.ToString() ?? "";
                        ingredientRequest.RequestStatus = "Approved by Admin";
                        ingredientRequest.ProcessedBy = processedBy;
                        ingredientRequest.ProcessedByUserId = processedByUserId;
                        ingredientRequest.StatusUpdatedDate = DateTime.UtcNow;
                        ingredientRequest.UpdatedAt = DateTime.UtcNow;
                        var update = Builders<IngredientStockRequest>.Update
                            .Set(r => r.RequestStatus, ingredientRequest.RequestStatus)
                            .Set(r => r.ProcessedBy, ingredientRequest.ProcessedBy)
                            .Set(r => r.ProcessedByUserId, ingredientRequest.ProcessedByUserId)
                            .Set(r => r.StatusUpdatedDate, ingredientRequest.StatusUpdatedDate)
                            .Set(r => r.UpdatedAt, ingredientRequest.UpdatedAt);
                        await ingredientStockRequestsCollection.UpdateOneAsync(filter, update);

                        // Send email to supplier with approve/reject links
                        var ingredientsCollection = Helpers.DatabaseHelper.GetIngredientsCollection();
                        var ingredient = await ingredientsCollection.Find(i => i.Id == ingredientRequest.IngredientID).FirstOrDefaultAsync();
                        var suppliersCollection = Helpers.DatabaseHelper.GetSuppliersCollection();
                        var supplier = await suppliersCollection.Find(s => s.SupplierID == ingredientRequest.SupplierID).FirstOrDefaultAsync();
                        if (supplier != null && !string.IsNullOrWhiteSpace(supplier.SupEmail) && ingredient != null)
                        {
                            InventorySystemSiaProject.Services.SendEmaikService.SendIngredientStockRequestEmail(
                                supplierEmail: supplier.SupEmail,
                                supplierName: supplier.SupName,
                                ingredientName: ingredient.IngredientName,
                                unit: ingredient.Unit,
                                currentStock: ingredientRequest.CurrentStockAtRequest,
                                minimumStock: ingredientRequest.MinimumStockLevel,
                                requestedQuantity: ingredientRequest.QuantityRequested,
                                additionalNotes: ingredientRequest.Instructions ?? "",
                                expectedDeliveryDate: ingredientRequest.ExpectedDeliveryDate,
                                requestId: ingredientRequest.RequestID,
                                requestDate: ingredientRequest.RequestDate
                            );

                            // Mark email as sent
                            var emailUpdate = Builders<IngredientStockRequest>.Update
                                .Set(r => r.EmailSent, true)
                                .Set(r => r.EmailSentDate, DateTime.UtcNow);
                            await ingredientStockRequestsCollection.UpdateOneAsync(filter, emailUpdate);
                        }

                        Response.Redirect("~/WebPages/ProductStock.aspx?tab=requests&msg=requestUpdated", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    // --- END INGREDIENT STOCK REQUEST LOGIC ---
                    // If not ingredient request, fallback to product stock request logic below
                }
                else if (e.CommandName == "RejectRequest")
                {
                    // Store request ID for rejection modal
                    hfRequestIdToReject.Value = requestId;
                    
                    // Open rejection modal
                    ClientScript.RegisterStartupScript(this.GetType(), "OpenRejectModal",
                        "openRejectModal(); switchTab('requests');", true);
                }
                else if (e.CommandName == "CompleteRequest")
                {
                    var stockRequest = await _productService.GetStockRequestByIdAsync(requestId);
                    if (stockRequest != null)
                    {
                        stockRequest.Complete();
                        await _productService.UpdateStockRequestAsync(stockRequest);

                        // Update variant stock quantity
                        var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                        var variant = variantsCollection.Find(v => v.Id == stockRequest.ProductVariantID).FirstOrDefault();
                        
                        if (variant != null)
                        {
                            variant.StockQuantity += stockRequest.QuantityRequested;
                            variant.UpdatedAt = DateTime.UtcNow;
                            
                            var filter = Builders<ProductVariant>.Filter.Eq(v => v.Id, variant.Id);
                            var update = Builders<ProductVariant>.Update
                                .Set(v => v.StockQuantity, variant.StockQuantity)
                                .Set(v => v.UpdatedAt, variant.UpdatedAt);
                            
                            await variantsCollection.UpdateOneAsync(filter, update);
                        }

                        Response.Redirect("~/WebPages/ProductStock.aspx?tab=requests&msg=requestUpdated", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                }
                else if (e.CommandName == "ViewDetails")
                {
                    var stockRequest = await _productService.GetStockRequestByIdAsync(requestId);
                    if (stockRequest != null)
                    {
                        // Populate details modal
                        var variant = await _productService.GetProductVariantByIdAsync(stockRequest.ProductVariantID);
                        var supplier = await _supplierService.GetSupplierByIdAsync(stockRequest.SupplierID);

                        // Format expected delivery date
                        string expectedDeliveryText = "Not specified";
                        if (stockRequest.ExpectedDeliveryDate.HasValue)
                        {
                            expectedDeliveryText = stockRequest.ExpectedDeliveryDate.Value.ToString("MMM dd, yyyy");
                        }

                        // Build details display
                        string detailsScript = $@"
                            document.getElementById('detailRequestID').textContent = '{stockRequest.DisplayRequestID}';
                            document.getElementById('detailProductName').textContent = '{(variant?.VariantName ?? "N/A").Replace("'", "\\'")}';
                            document.getElementById('detailSupplier').textContent = '{(supplier?.SupName ?? "N/A").Replace("'", "\\'")}';
                            document.getElementById('detailQuantity').textContent = '{stockRequest.QuantityRequested}';
                            document.getElementById('detailStockQuantity').textContent = '{(variant?.StockQuantity ?? 0)}';
                            document.getElementById('detailStatus').textContent = '{stockRequest.RequestStatus}';
                            document.getElementById('detailRequestedBy').textContent = '{stockRequest.RequestedBy}';
                            document.getElementById('detailRequestDate').textContent = '{stockRequest.RequestDate:MMM dd, yyyy HH:mm}';
                            document.getElementById('detailExpectedDelivery').textContent = '{expectedDeliveryText}';
                            document.getElementById('detailInstructions').textContent = '{stockRequest.Instructions?.Replace("'", "\\'") ?? "No additional instructions"}';
                            openDetailsModal();
                            switchTab('requests');";

                        ClientScript.RegisterStartupScript(this.GetType(), "ShowDetails", detailsScript, true);
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error processing stock request command: {ex.Message}");
                ShowMessage($"❌ Error: {ex.Message}", "danger");
            }
        }

        protected async void btnConfirmReject_Click(object sender, EventArgs e)
        {
            try
            {
                string requestId = hfRequestIdToReject.Value;
                string rejectionReason = txtRejectionReason.Text.Trim();

                if (string.IsNullOrWhiteSpace(rejectionReason))
                {
                    ShowMessage("❌ Please provide a rejection reason.", "danger");
                    return;
                }

                var stockRequest = await _productService.GetStockRequestByIdAsync(requestId);
                if (stockRequest != null)
                {
                    string processedBy = Session["UserName"]?.ToString() ?? "System Admin";
                    string processedByUserId = Session["UserId"]?.ToString() ?? "";

                    stockRequest.Reject(processedBy, processedByUserId, rejectionReason);
                    await _productService.UpdateStockRequestAsync(stockRequest);

                    Response.Redirect("~/WebPages/ProductStock.aspx?tab=requests&msg=requestUpdated", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error rejecting request: {ex.Message}");
                ShowMessage($"❌ Error: {ex.Message}", "danger");
            }
        }

        #endregion

        #region Ingredient Stock Request Methods

        protected async void btnSendIngredientRequest_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
                return;

            try
            {
                string ingredientId = hfIngredientId.Value;
                string supplierId = hfIngredientSupplierId.Value;
                decimal requestedQuantity = decimal.Parse(txtIngredientRequestQuantity.Text.Trim());
                string additionalNotes = txtIngredientRequestNotes.Text.Trim();
                
                // Parse expected delivery date if provided
                DateTime? expectedDeliveryDate = null;
                if (!string.IsNullOrWhiteSpace(txtIngredientExpectedDeliveryDate.Text))
                {
                    DateTime parsedDate;
                    if (DateTime.TryParse(txtIngredientExpectedDeliveryDate.Text, out parsedDate))
                    {
                        expectedDeliveryDate = parsedDate;
                    }
                }

                // Get ingredient details
                var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
                var ingredient = ingredientsCollection.Find(x => x.Id == ingredientId).FirstOrDefault();

                if (ingredient == null)
                {
                    ShowMessage("❌ Ingredient not found.", "danger");
                    return;
                }

                // Get supplier details
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                var supplier = suppliersCollection.Find(s => s.SupplierID == supplierId).FirstOrDefault();

                if (supplier == null)
                {
                    ShowMessage("❌ Supplier not found.", "danger");
                    return;
                }

                if (string.IsNullOrWhiteSpace(supplier.SupEmail))
                {
                    ShowMessage("❌ Supplier email is not available.", "danger");
                    return;
                }

                // Get current user
                string requestedBy = "System Admin"; // Default
                string requestedByUserId = "";
                
                if (Session["UserName"] != null)
                {
                    requestedBy = Session["UserName"].ToString();
                }
                if (Session["UserId"] != null)
                {
                    requestedByUserId = Session["UserId"].ToString();
                }

                // Create ingredient stock request record
                var ingredientStockRequest = new IngredientStockRequest
                {
                    IngredientID = ingredientId,
                    SupplierID = supplierId,
                    QuantityRequested = requestedQuantity,
                    Unit = ingredient.Unit,
                    Instructions = additionalNotes,
                    RequestedBy = requestedBy,
                    RequestedByUserId = requestedByUserId,
                    CurrentStockAtRequest = ingredient.CurrentStock,
                    MinimumStockLevel = ingredient.MinimumStock,
                    UnitPrice = ingredient.CostPerUnit,
                    Priority = ingredient.IsLowStock ? "High" : "Normal",
                    ExpectedDeliveryDate = expectedDeliveryDate,
                    RequestStatus = "Pending" // ✅ Start as Pending, will be approved by admin first
                };

                ingredientStockRequest.PrepareForInsertion();

                // Calculate total cost
                ingredientStockRequest.TotalCost = requestedQuantity * ingredient.CostPerUnit;

                // Save to database
                var ingredientStockRequestsCollection = DatabaseHelper.GetIngredientStockRequestsCollection();
                await ingredientStockRequestsCollection.InsertOneAsync(ingredientStockRequest);

                if (!string.IsNullOrEmpty(ingredientStockRequest.RequestID))
                {
                    // ✅ NOTE: Email will be sent when admin approves the request
                    // Don't send email immediately on creation
                    
                    Response.Redirect("~/WebPages/ProductStock.aspx?tab=requests&msg=ingredientRequestCreated", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
                else
                {
                    ShowMessage("❌ Failed to create ingredient stock request.", "danger");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error sending ingredient stock request: {ex.Message}");
                ShowMessage($"❌ Failed to send request: {ex.Message}", "danger");
            }
        }

        protected void btnCancelIngredientRequest_Click(object sender, EventArgs e)
        {
            // Clear form
            txtIngredientRequestQuantity.Text = string.Empty;
            txtIngredientExpectedDeliveryDate.Text = string.Empty;
            txtIngredientRequestNotes.Text = string.Empty;
            hfIngredientId.Value = string.Empty;
            hfIngredientSupplierId.Value = string.Empty;
        }
        
        /// <summary>
        /// ✅ NEW: Approve ingredient stock request and send email to supplier with approval/rejection links
        /// </summary>
        protected async Task ApproveIngredientStockRequestAsync(string requestId)
        {
            try
            {
                var ingredientStockRequestsCollection = DatabaseHelper.GetIngredientStockRequestsCollection();
                
                // Get the request
                var filter = Builders<IngredientStockRequest>.Filter.Eq("_id", new MongoDB.Bson.ObjectId(requestId));
                var request = await ingredientStockRequestsCollection.Find(filter).FirstOrDefaultAsync();

                if (request == null)
                {
                    ShowMessage("❌ Ingredient stock request not found.", "danger");
                    return;
                }

                // Update status
                string processedBy = Session["UserName"]?.ToString() ?? "System Admin";
                string processedByUserId = Session["UserId"]?.ToString() ?? "";

                request.RequestStatus = "Approved by Admin";
                request.ProcessedBy = processedBy;
                request.ProcessedByUserId = processedByUserId;
                request.StatusUpdatedDate = DateTime.UtcNow;
                request.UpdatedAt = DateTime.UtcNow;

                var update = Builders<IngredientStockRequest>.Update
                    .Set(r => r.RequestStatus, request.RequestStatus)
                    .Set(r => r.ProcessedBy, request.ProcessedBy)
                    .Set(r => r.ProcessedByUserId, request.ProcessedByUserId)
                    .Set(r => r.StatusUpdatedDate, request.StatusUpdatedDate)
                    .Set(r => r.UpdatedAt, request.UpdatedAt);

                await ingredientStockRequestsCollection.UpdateOneAsync(filter, update);

                // ✅ NOW SEND EMAIL TO SUPPLIER WITH APPROVAL/REJECTION LINKS
                try
                {
                    // Get ingredient and supplier details
                    var ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
                    var ingredient = await ingredientsCollection.Find(i => i.Id == request.IngredientID).FirstOrDefaultAsync();

                    var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                    var supplier = await suppliersCollection.Find(s => s.SupplierID == request.SupplierID).FirstOrDefaultAsync();

                    if (supplier != null && !string.IsNullOrWhiteSpace(supplier.SupEmail) && ingredient != null)
                    {
                        // Send email with approval/rejection links
                        SendEmaikService.SendIngredientStockRequestEmail(
                            supplierEmail: supplier.SupEmail,
                            supplierName: supplier.SupName,
                            ingredientName: ingredient.IngredientName,
                            unit: ingredient.Unit,
                            currentStock: request.CurrentStockAtRequest,
                            minimumStock: request.MinimumStockLevel,
                            requestedQuantity: request.QuantityRequested,
                            additionalNotes: request.Instructions ?? "",
                            expectedDeliveryDate: request.ExpectedDeliveryDate,
                            requestId: request.RequestID,
                            requestDate: request.RequestDate
                        );

                        // Mark email as sent
                        var emailUpdate = Builders<IngredientStockRequest>.Update
                            .Set(r => r.EmailSent, true)
                            .Set(r => r.EmailSentDate, DateTime.UtcNow);
                        await ingredientStockRequestsCollection.UpdateOneAsync(filter, emailUpdate);

                        System.Diagnostics.Debug.WriteLine($"✅ Email sent to supplier {supplier.SupEmail} for ingredient request {request.DisplayRequestID}");
                    }
                }
                catch (Exception emailEx)
                {
                    System.Diagnostics.Debug.WriteLine($"⚠️ Failed to send email: {emailEx.Message}");
                    // Don't fail the approval if email fails
                }

                ShowMessage("✅ Ingredient stock request approved and email sent to supplier!", "success");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error approving ingredient stock request: {ex.Message}");
                ShowMessage($"❌ Error: {ex.Message}", "danger");
            }
        }

        #endregion

        #region Helper Methods

        protected string GetStatusClass(string status)
        {
            switch (status?.ToLower())
            {
                case "pending":
                    return "status-pending";
                case "approved":
                    return "status-approved";
                case "in process":
                    return "status-inprocess";
                case "completed":
                    return "status-active";
                case "rejected":
                    return "status-inactive";
                case "delivered":
                    return "status-delivered";
                default:
                    return "status-badge";
            }
        }

        protected string GetPriorityClass(string priority)
        {
            switch (priority?.ToLower())
            {
                case "urgent":
                    return "status-priority-urgent";
                case "high":
                    return "status-priority-high";
                case "normal":
                    return "status-approved";
                case "low":
                    return "status-badge";
                default:
                    return "status-badge";
            }
        }

        // ✅ NEW: Helper method to display expiration status
        protected string GetExpirationDisplay(object expirationDate)
        {
            if (expirationDate == null || expirationDate == DBNull.Value)
            {
                return "<span style='color: #999; font-size: 11px;'>No expiry</span>";
            }

            try
            {
                DateTime expiry = Convert.ToDateTime(expirationDate);
                TimeSpan timeLeft = expiry - DateTime.Now;
                int daysLeft = (int)timeLeft.TotalDays;

                if (daysLeft < 0)
                {
                    // Expired
                    return $"<span style='background: #dc3545; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 11px;'>⚠️ EXPIRED</span>";
                }
                else if (daysLeft == 0)
                {
                    // Expires today
                    return $"<span style='background: #dc3545; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 11px;'>⚠️ Today!</span>";
                }
                else if (daysLeft <= 7)
                {
                    // Expires within a week - critical
                    return $"<span style='background: #dc3545; color: white; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 11px;'>⏰ {daysLeft}d left</span>";
                }
                else if (daysLeft <= 30)
                {
                    // Expires within 30 days - warning
                    return $"<span style='background: #ffc107; color: #333; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 11px;'>⏰ {daysLeft} days</span>";
                }
                else if (daysLeft <= 90)
                {
                    // Expires within 90 days - info
                    return $"<span style='background: #17a2b8; color: white; padding: 4px 8px; border-radius: 4px; font-size: 11px;'>📅 {expiry:MMM dd}</span>";
                }
                else
                {
                    // Good - more than 90 days
                    return $"<span style='color: #28a745; font-size: 11px;'>✓ {expiry:MMM dd, yyyy}</span>";
                }
            }
            catch
            {
                return "<span style='color: #999; font-size: 11px;'>Invalid date</span>";
            }
        }

        protected async void ddlStatusFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
            await LoadIngredientStockRequestsAsync();
            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab", "switchTab('requests');", true);
        }

        protected async void btnRefreshRequests_Click(object sender, EventArgs e)
        {
            await LoadIngredientStockRequestsAsync();
            ClientScript.RegisterStartupScript(this.GetType(), "SwitchTab",
                "switchTab('requests');", true);
        }

        #endregion

        #region WebMethods
       
        [WebMethod(EnableSession = true)]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json)]
        public static StatusChangeResult ChangeStockRequestStatus(string requestId, string newStatus)
        {
            try
            {
                Debug.WriteLine($"[ChangeStockRequestStatus] Called with requestId={requestId}, newStatus={newStatus}");
                var context = HttpContext.Current;
                var session = context.Session;
                string adminUser = session?["UserName"] as string;
                string adminId = session?["UserId"] as string;
                if (string.IsNullOrEmpty(adminUser) || string.IsNullOrEmpty(adminId))
                {
                    Debug.WriteLine("[ChangeStockRequestStatus] Session expired");
                    return new StatusChangeResult { success = false, message = "Session expired. Please log in again." };
                }
                var productService = new InventorySystemSiaProject.Services.ProductService();
                var requestTask = productService.GetStockRequestByIdAsync(requestId);
                requestTask.Wait();
                var request = requestTask.Result;
                if (request == null)
                {
                    Debug.WriteLine("[ChangeStockRequestStatus] Stock request not found");
                    return new StatusChangeResult { success = false, message = "Stock request not found." };
                }
                request.RequestStatus = newStatus;
                productService.UpdateStockRequestAsync(request).Wait();
                Debug.WriteLine("[ChangeStockRequestStatus] Status updated successfully");
                return new StatusChangeResult { success = true, message = "Status updated successfully." };
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ChangeStockRequestStatus] Exception: {ex}");
                return new StatusChangeResult { success = false, message = ex.Message };
            }
        }
        #endregion
    }
}


