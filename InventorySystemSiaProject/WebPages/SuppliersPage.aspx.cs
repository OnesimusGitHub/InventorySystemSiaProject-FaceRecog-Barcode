using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using System;
using System.Net;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace InventorySystemSiaProject.WebPages
{
    public partial class SuppliersPage : Page
    {
        private SupplierService _supplierService;

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
            if (!IsPostBack)
            {
                RegisterAsyncTask(new PageAsyncTask(LoadSuppliersAsync));
                if (Request.QueryString["msg"] != null)
                {
                    string msg = Request.QueryString["msg"];
                    switch (msg)
                    {
                        case "created":
                            ShowSupplierMessage("? Supplier added successfully!", "success");
                            break;
                        case "updated":
                            ShowSupplierMessage("? Supplier updated successfully!", "success");
                            break;
                        case "deleted":
                            ShowSupplierMessage("? Supplier deleted successfully!", "success");
                            break;
                    }
                }
            }
        }

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
                // Log error or handle as needed
            }
        }

        private void BindSuppliersFromHandler()
        {
            try
            {
                var url = ResolveUrl("~/Handlers/SupplierHandler.ashx?action=get");
                var request = (HttpWebRequest)WebRequest.Create(url);
                request.Method = "GET";
                using (var response = request.GetResponse())
                using (var stream = response.GetResponseStream())
                using (var reader = new StreamReader(stream))
                {
                    var json = reader.ReadToEnd();
                    var serializer = new JavaScriptSerializer();
                    var result = serializer.Deserialize<Dictionary<string, object>>(json);
                    if (result.ContainsKey("success") && (bool)result["success"])
                    {
                        var suppliersJson = result["suppliers"];
                        var suppliers = serializer.ConvertToType<List<dynamic>>(suppliersJson);
                        gvSuppliers.DataSource = suppliers;
                        gvSuppliers.DataBind();
                    }
                }
            }
            catch (Exception ex)
            {
                // Log error or handle as needed
            }
        }

        protected async void btnSaveSupplier_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
                return;
            try
            {
                // Implement server-side logic if needed, otherwise remove this handler
            }
            catch (ArgumentException argEx)
            {
                // Log error or handle as needed
            }
            catch (Exception ex)
            {
                // Log error or handle as needed
            }
        }

        protected void btnCancelSupplier_Click(object sender, EventArgs e)
        {
            // Implement server-side logic if needed, otherwise remove this handler
        }

        protected async void gvSuppliers_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            string supplierId = e.CommandArgument.ToString();
            if (e.CommandName == "EditSupplier")
            {
                // Implement edit logic if needed
            }
            else if (e.CommandName == "DeleteSupplier")
            {
                try
                {
                    bool deleted = await _supplierService.DeleteSupplierAsync(supplierId);
                    if (deleted)
                    {
                        // Redirect to prevent form resubmission on refresh
                        Response.Redirect(Request.RawUrl, false);
                        Context.ApplicationInstance.CompleteRequest();
                    }
                    else
                    {
                        ShowSupplierMessage("Supplier could not be deleted.", "danger");
                    }
                }
                catch (Exception ex)
                {
                    ShowSupplierMessage("Error deleting supplier: " + ex.Message, "danger");
                }
            }
        }

        private void ClearSupplierForm()
        {
            // No UI controls to clear
        }

        private void ShowSupplierMessage(string message, string type)
        {
            // No UI controls to show message
        }
    }
}
