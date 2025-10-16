using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace InventorySystemSiaProject.WebPages
{
    public partial class PstockForm : System.Web.UI.Page
    {
        private SupplierService _supplierService;

        protected void Page_Load(object sender, EventArgs e)
        {
            _supplierService = new SupplierService();

            if (!IsPostBack)
            {
                LoadProducts();
                // Register async task for loading suppliers
                RegisterAsyncTask(new PageAsyncTask(LoadSuppliersAsync));
                
                // Check for success messages from redirect
                if (Request.QueryString["msg"] != null)
                {
                    string msg = Request.QueryString["msg"];
                    switch (msg)
                    {
                        case "created":
                            ShowSupplierMessage("✅ Supplier added successfully!", "success");
                            // Switch to suppliers tab
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
                    }
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

                // Send stock request email
                SendEmaikService.SendStockRequestEmail(
                    supplierEmail: supplier.SupEmail,
                    supplierName: supplier.SupName,
                    productName: variant.VariantName,
                    currentStock: variant.StockQuantity,
                    minimumStock: variant.MinimumStock,
                    requestedQuantity: requestedQuantity,
                    additionalNotes: additionalNotes
                );

                // Show success message
                ShowMessage($"✅ Stock request sent successfully to {supplier.SupName} ({supplier.SupEmail})", "success");

                // Close modal via JavaScript
                ClientScript.RegisterStartupScript(this.GetType(), "CloseModal", 
                    "closeStockRequestModal();", true);

                // Clear form
                txtRequestQuantity.Text = string.Empty;
                txtRequestNotes.Text = string.Empty;
                hfVariantId.Value = string.Empty;
                hfProductId.Value = string.Empty;
                hfSupplierId2.Value = string.Empty;
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
                        // Redirect to avoid form resubmission warning (POST-Redirect-GET pattern)
                        Response.Redirect(Request.RawUrl + "?msg=updated", false);
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
                        // Redirect to avoid form resubmission warning (POST-Redirect-GET pattern)
                        Response.Redirect(Request.RawUrl + "?msg=created", false);
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
            ClearSupplierForm();
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

                        // Open modal and scroll to top
                        ClientScript.RegisterStartupScript(this.GetType(), "OpenModal",
                            "openSupplierModal(); switchTab('suppliers');", true);
                    }
                }
                catch (Exception ex)
                {
                    ShowSupplierMessage($"❌ Error loading supplier: {ex.Message}", "danger");
                }
            }
            else if (e.CommandName == "DeleteSupplier")
            {
                try
                {
                    var success = await _supplierService.DeleteSupplierAsync(supplierId);
                    if (success)
                    {
                        // Redirect to avoid form resubmission warning (POST-Redirect-GET pattern)
                        Response.Redirect(Request.RawUrl + "?msg=deleted", false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    else
                    {
                        ShowSupplierMessage("❌ Failed to delete supplier.", "danger");
                    }
                }
                catch (Exception ex)
                {
                    ShowSupplierMessage($"❌ Error deleting supplier: {ex.Message}", "danger");
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
    }
}

