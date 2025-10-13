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
            var collection = DatabaseHelper.GetProductVariantsCollection();
            var variants = collection.Find(FilterDefinition<ProductVariant>.Empty).ToList();

            gvProducts.DataSource = variants;
            gvProducts.DataBind();
        }

        protected void gvProducts_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "SendHelp")
            {
                string id = e.CommandArgument.ToString();

                var collection = DatabaseHelper.GetProductVariantsCollection();
                var product = collection.Find(x => x.Id == id).FirstOrDefault();

                if (product != null)
                {
                    try
                    {
                        SendEmaikService.SendLowStockEmail(
                            "salangsang.andrewjeremiah.castro@gmail.com",   // Change to real email
                            product.VariantName,
                            product.StockQuantity,
                            product.MinimumStock
                        );

                        lblMessage.Text = "✅ Email sent for product: " + product.VariantName;
                        lblMessage.ForeColor = System.Drawing.Color.Green;
                        lblMessage.Visible = true;
                    }
                    catch (Exception ex)
                    {
                        lblMessage.Text = "❌ Failed to send email: " + ex.Message;
                        lblMessage.ForeColor = System.Drawing.Color.Red;
                        lblMessage.Visible = true;
                    }
                }
            }
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

