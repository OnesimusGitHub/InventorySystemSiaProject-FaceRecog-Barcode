using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using MongoDB.Driver;

namespace InventorySystemSiaProject.WebPages
{
    public partial class IngredientsPage : System.Web.UI.Page
    {
        private ProductService _productService;
        private SupplierService _supplierService;

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                _productService = new ProductService();
                _supplierService = new SupplierService();

                if (!IsPostBack)
                {
                    // Load ingredients data and suppliers asynchronously
                    RegisterAsyncTask(new PageAsyncTask(LoadPageDataAsync));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? Page_Load error: {ex.Message}");
                ShowMessage("Error loading page: " + ex.Message, "danger");
            }
        }

        private async Task LoadPageDataAsync()
        {
            try
            {
                // Load suppliers dropdown
                await LoadSuppliersAsync();
                
                // Load ingredients data
                await LoadIngredientsDataAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? LoadPageDataAsync error: {ex.Message}");
                ShowMessage("Failed to load page data: " + ex.Message, "danger");
            }
        }

        private async Task LoadSuppliersAsync()
        {
            try
            {
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                
                ddlSupplier.DataSource = suppliers;
                ddlSupplier.DataTextField = "SupName";
                ddlSupplier.DataValueField = "SupplierID";
                ddlSupplier.DataBind();
                
                // Add default "Select Supplier" option at the beginning
                ddlSupplier.Items.Insert(0, new ListItem("-- Select Supplier (Optional) --", ""));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? LoadSuppliersAsync error: {ex.Message}");
                ShowMessage("Failed to load suppliers: " + ex.Message, "danger");
            }
        }

        private async Task LoadIngredientsDataAsync()
        {
            try
            {
                // Fetch all ingredients
                var ingredients = await _productService.GetAllIngredientsAsync();

                // Bind to GridView
                gvIngredients.DataSource = ingredients;
                gvIngredients.DataBind();

                // Calculate statistics
                UpdateStatistics(ingredients);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? LoadIngredientsDataAsync error: {ex.Message}");
                ShowMessage("Failed to load ingredients: " + ex.Message, "danger");
            }
        }

        private void UpdateStatistics(List<Ingredient> ingredients)
        {
            try
            {
                // Total ingredients
                lblTotalIngredients.Text = ingredients.Count.ToString();

                // Low stock count
                var lowStockCount = ingredients.Count(i => i.IsLowStock && i.IsActive);
                lblLowStockCount.Text = lowStockCount.ToString();

                // Total inventory value
                var totalValue = ingredients.Where(i => i.IsActive).Sum(i => i.TotalValue);
                lblTotalValue.Text = totalValue.ToString("N2");

                // Active ingredients count
                var activeCount = ingredients.Count(i => i.IsActive);
                lblActiveCount.Text = activeCount.ToString();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? UpdateStatistics error: {ex.Message}");
            }
        }

        // Helper method for status badge rendering
        protected string GetStatusBadge(bool isLowStock, bool isActive)
        {
            if (isLowStock)
            {
                return "<span class='status-badge status-low'>Low Stock</span>";
            }
            else if (isActive)
            {
                return "<span class='status-badge status-active'>Active</span>";
            }
            else
            {
                return "<span class='status-badge status-inactive'>Inactive</span>";
            }
        }

        protected void gvIngredients_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            try
            {
                string ingredientId = e.CommandArgument.ToString();

                if (e.CommandName == "EditIngredient")
                {
                    // Open edit modal
                    RegisterAsyncTask(new PageAsyncTask(() => LoadIngredientForEditAsync(ingredientId)));
                }
                else if (e.CommandName == "DeleteIngredient")
                {
                    // Delete ingredient
                    RegisterAsyncTask(new PageAsyncTask(() => DeleteIngredientAsync(ingredientId)));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? RowCommand error: {ex.Message}");
                ShowMessage("Error processing action: " + ex.Message, "danger");
            }
        }

        private async Task LoadIngredientForEditAsync(string ingredientId)
        {
            try
            {
                var ingredientsColl = Helpers.DatabaseHelper.GetIngredientsCollection();
                var ingredient = await ingredientsColl.Find(i => i.Id == ingredientId).FirstOrDefaultAsync();

                if (ingredient != null)
                {
                    // Populate form fields
                    hfIngredientId.Value = ingredient.Id;
                    txtIngredientName.Text = ingredient.IngredientName;
                    txtUnit.SelectedValue = ingredient.Unit;
                    txtCostPerUnit.Text = ingredient.CostPerUnit.ToString("F2");
                    txtCurrentStock.Text = ingredient.CurrentStock.ToString("F2");
                    txtMinimumStock.Text = ingredient.MinimumStock.ToString("F2");
                    
                    // Set supplier dropdown
                    if (!string.IsNullOrEmpty(ingredient.Supplier))
                    {
                        // Try to find supplier by name or ID
                        var supplierItem = ddlSupplier.Items.FindByText(ingredient.Supplier);
                        if (supplierItem != null)
                        {
                            ddlSupplier.SelectedValue = supplierItem.Value;
                        }
                        else
                        {
                            // If not found, select the empty option and show warning
                            ddlSupplier.SelectedIndex = 0;
                        }
                    }
                    else
                    {
                        ddlSupplier.SelectedIndex = 0;
                    }

                    // Update modal title
                    lblModalTitle.Text = "Edit Ingredient";

                    // Show modal via client script
                    ScriptManager.RegisterStartupScript(this, GetType(), "ShowModal",
                        "document.getElementById('ingredientModal').classList.add('show'); document.body.style.overflow = 'hidden';", true);
                }
                else
                {
                    ShowMessage("Ingredient not found.", "danger");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? LoadIngredientForEditAsync error: {ex.Message}");
                ShowMessage("Failed to load ingredient: " + ex.Message, "danger");
            }
        }

        private async Task DeleteIngredientAsync(string ingredientId)
        {
            try
            {
                var ingredientsColl = Helpers.DatabaseHelper.GetIngredientsCollection();
                
                // Soft delete by setting IsActive to false
                var filter = Builders<Ingredient>.Filter.Eq(i => i.Id, ingredientId);
                var update = Builders<Ingredient>.Update.Set(i => i.IsActive, false);
                var result = await ingredientsColl.UpdateOneAsync(filter, update);

                if (result.ModifiedCount > 0)
                {
                    ShowMessage("Ingredient deleted successfully!", "success");
                    await LoadIngredientsDataAsync();
                }
                else
                {
                    ShowMessage("Failed to delete ingredient.", "danger");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? DeleteIngredientAsync error: {ex.Message}");
                ShowMessage("Error deleting ingredient: " + ex.Message, "danger");
            }
        }

        protected void btnSaveIngredient_Click(object sender, EventArgs e)
        {
            if (Page.IsValid)
            {
                RegisterAsyncTask(new PageAsyncTask(SaveIngredientAsync));
            }
        }

        private async Task SaveIngredientAsync()
        {
            try
            {
                var ingredientsColl = Helpers.DatabaseHelper.GetIngredientsCollection();
                string ingredientId = hfIngredientId.Value;

                // Get supplier name from dropdown
                string supplierName = "";
                if (!string.IsNullOrEmpty(ddlSupplier.SelectedValue))
                {
                    supplierName = ddlSupplier.SelectedItem.Text;
                }

                var ingredient = new Ingredient
                {
                    IngredientName = txtIngredientName.Text.Trim(),
                    Unit = txtUnit.SelectedValue,
                    CostPerUnit = decimal.Parse(txtCostPerUnit.Text),
                    CurrentStock = decimal.Parse(txtCurrentStock.Text),
                    MinimumStock = decimal.Parse(txtMinimumStock.Text),
                    Supplier = supplierName,
                    IsActive = true
                };

                if (string.IsNullOrEmpty(ingredientId))
                {
                    // Create new ingredient
                    ingredient.CreatedAt = DateTime.UtcNow;
                    ingredient.UpdatedAt = DateTime.UtcNow;
                    
                    await ingredientsColl.InsertOneAsync(ingredient);
                    ShowMessage("Ingredient added successfully!", "success");
                }
                else
                {
                    // Update existing ingredient
                    ingredient.Id = ingredientId;
                    ingredient.UpdatedAt = DateTime.UtcNow;
                    
                    // Get the created date from existing record
                    var existing = await ingredientsColl.Find(i => i.Id == ingredientId).FirstOrDefaultAsync();
                    if (existing != null)
                    {
                        ingredient.CreatedAt = existing.CreatedAt;
                    }
                    
                    var filter = Builders<Ingredient>.Filter.Eq(i => i.Id, ingredientId);
                    var result = await ingredientsColl.ReplaceOneAsync(filter, ingredient);
                    
                    if (result.ModifiedCount > 0)
                    {
                        ShowMessage("Ingredient updated successfully!", "success");
                    }
                    else
                    {
                        ShowMessage("No changes were made.", "danger");
                    }
                }

                // Reload data
                await LoadIngredientsDataAsync();

                // Clear form
                ClearForm();

                // Close modal
                ScriptManager.RegisterStartupScript(this, GetType(), "CloseModal",
                    "document.getElementById('ingredientModal').classList.remove('show'); document.body.style.overflow = '';", true);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? SaveIngredientAsync error: {ex.Message}");
                ShowMessage("Failed to save ingredient: " + ex.Message, "danger");
            }
        }

        private void ClearForm()
        {
            hfIngredientId.Value = string.Empty;
            txtIngredientName.Text = string.Empty;
            txtUnit.SelectedIndex = 0;
            txtCostPerUnit.Text = string.Empty;
            txtCurrentStock.Text = string.Empty;
            txtMinimumStock.Text = string.Empty;
            ddlSupplier.SelectedIndex = 0;
            lblModalTitle.Text = "Add New Ingredient";
        }

        private void ShowMessage(string message, string type)
        {
            pnlMessage.Visible = true;
            lblMessage.Text = message;
            
            // Set CSS class based on type
            pnlMessage.CssClass = type == "success" ? "alert alert-success" : "alert alert-danger";
        }
    }
}
