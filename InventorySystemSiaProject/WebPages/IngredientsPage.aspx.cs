using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using Newtonsoft.Json;

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
                    // Check for success message from session
                    if (Session["IngredientSuccessMessage"] != null)
                    {
                        ShowMessage(Session["IngredientSuccessMessage"].ToString(), "success");
                        Session.Remove("IngredientSuccessMessage");
                        
                        // Use client-side redirect to clean URL and prevent resubmission
                        ScriptManager.RegisterStartupScript(this, GetType(), "CleanUrl",
                            "if (window.history.replaceState) { window.history.replaceState(null, null, window.location.pathname); }", true);
                    }
                    
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

                // Get all suppliers for display mapping
                var suppliers = await _supplierService.GetAllSuppliersAsync();
                var supplierDict = suppliers.ToDictionary(s => s.SupplierID, s => s.SupName);

                // Populate supplier names for display
                foreach (var ingredient in ingredients)
                {
                    if (!string.IsNullOrEmpty(ingredient.SupplierId) && supplierDict.ContainsKey(ingredient.SupplierId))
                    {
                        ingredient.Supplier = new Supplier { SupName = supplierDict[ingredient.SupplierId] };
                    }
                }

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

        // Helper method to get supplier name safely
        protected string GetSupplierName(object ingredientObj)
        {
            try
            {
                var ingredient = ingredientObj as Ingredient;
                if (ingredient?.Supplier != null)
                {
                    return ingredient.Supplier.SupName ?? "N/A";
                }
                return "N/A";
            }
            catch
            {
                return "N/A";
            }
        }

        protected void gvIngredients_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            try
            {
                string ingredientId = e.CommandArgument.ToString();

                if (e.CommandName == "DeleteIngredient")
                {
                    RegisterAsyncTask(new PageAsyncTask(() => DeleteIngredientAsync(ingredientId)));
                }
                else if (e.CommandName == "EditIngredient")
                {
                    var ingredientsColl = Helpers.DatabaseHelper.GetIngredientsCollection();
                    var ingredient = ingredientsColl.Find(i => i.Id == ingredientId).FirstOrDefault();

                    if (ingredient != null)
                    {
                        hfIngredientId.Value = ingredient.Id;
                        txtIngredientName.Text = ingredient.IngredientName;
                        txtUnit.SelectedValue = ingredient.Unit;
                        txtCostPerUnit.Text = ingredient.CostPerUnit.ToString();
                        txtCurrentStock.Text = ingredient.CurrentStock.ToString();
                        txtMinimumStock.Text = ingredient.MinimumStock.ToString();
                        ddlSupplier.SelectedValue = ingredient.SupplierId ?? "";
                        txtSKU.Text = ingredient.SKU ?? string.Empty;
                        lblModalTitle.Text = "Edit Ingredient";
                        // Show modal here
                    }
                    else
                    {
                        ShowMessage("Ingredient not found.", "danger");
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? RowCommand error: {ex.Message}");
                ShowMessage("Error processing action: " + ex.Message, "danger");
            }
        }

        private async Task DeleteIngredientAsync(string ingredientId)
        {
            try
            {
                var ingredientsColl = Helpers.DatabaseHelper.GetIngredientsCollection();
                
                // Get ingredient details before deletion for logging
                var ingredient = await ingredientsColl.Find(i => i.Id == ingredientId).FirstOrDefaultAsync();
                
                if (ingredient == null)
                {
                    ShowMessage("Ingredient not found.", "danger");
                    return;
                }
                
                // Soft delete by setting IsActive to false
                var filter = Builders<Ingredient>.Filter.Eq(i => i.Id, ingredientId);
                var update = Builders<Ingredient>.Update.Set(i => i.IsActive, false);
                var result = await ingredientsColl.UpdateOneAsync(filter, update);

                if (result.ModifiedCount > 0)
                {
                    // Log the deletion activity
                    var logDetails = new
                    {
                        action = "Delete",
                        ingredientName = ingredient.IngredientName,
                        unit = ingredient.Unit,
                        costPerUnit = ingredient.CostPerUnit,
                        currentStock = ingredient.CurrentStock,
                        minimumStock = ingredient.MinimumStock,
                        supplierId = ingredient.SupplierId,
                        timestamp = DateTime.UtcNow
                    };
                    
                    ActivityLogger.Log(
                        action: "Delete Ingredient",
                        entityType: "Ingredient",
                        entityId: ingredientId,
                        detailsJson: JsonConvert.SerializeObject(logDetails, Formatting.Indented)
                    );
                    
                    // Store success message in session
                    Session["IngredientSuccessMessage"] = "Ingredient deleted successfully!";
                    
                    // Redirect to same page without query parameters
                    Response.Redirect(Request.Url.AbsolutePath, false);
                    Context.ApplicationInstance.CompleteRequest();
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
                bool isUpdate = !string.IsNullOrEmpty(ingredientId);

                // Get supplier ID from dropdown (not the name)
                string supplierId = ddlSupplier.SelectedValue;
                string sku = txtSKU.Text.Trim();

                var ingredient = new Ingredient
                {
                    IngredientName = txtIngredientName.Text.Trim(),
                    Unit = txtUnit.SelectedValue,
                    CostPerUnit = decimal.Parse(txtCostPerUnit.Text),
                    CurrentStock = decimal.Parse(txtCurrentStock.Text),
                    MinimumStock = decimal.Parse(txtMinimumStock.Text),
                    SupplierId = !string.IsNullOrEmpty(supplierId) ? supplierId : null,
                    IsActive = true,
                     SKU = sku
                };

                if (!isUpdate)
                {
                    // Create new ingredient
                    ingredient.CreatedAt = DateTime.UtcNow;
                    ingredient.UpdatedAt = DateTime.UtcNow;
                    
                    await ingredientsColl.InsertOneAsync(ingredient);
                    
                    // Log the creation activity
                    var createLogDetails = new
                    {
                        action = "Create",
                        ingredientName = ingredient.IngredientName,
                        unit = ingredient.Unit,
                        costPerUnit = ingredient.CostPerUnit,
                        currentStock = ingredient.CurrentStock,
                        minimumStock = ingredient.MinimumStock,
                        supplierId = ingredient.SupplierId,
                        supplierName = ddlSupplier.SelectedItem?.Text,
                        totalValue = ingredient.TotalValue,
                        timestamp = DateTime.UtcNow
                    };
                    
                    ActivityLogger.Log(
                        action: "Add Ingredient",
                        entityType: "Ingredient",
                        entityId: ingredient.Id,
                        detailsJson: JsonConvert.SerializeObject(createLogDetails, Formatting.Indented)
                    );
                    
                    // Store success message in session
                    Session["IngredientSuccessMessage"] = "Ingredient added successfully!";
                    
                    // Redirect to same page without query parameters
                    Response.Redirect(Request.Url.AbsolutePath, false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
                else
                {
                    // Get existing ingredient for comparison
                    var existingIngredient = await ingredientsColl.Find(i => i.Id == ingredientId).FirstOrDefaultAsync();
                    
                    if (existingIngredient == null)
                    {
                        ShowMessage("Ingredient not found.", "danger");
                        return;
                    }
                    
                    // Update existing ingredient
                    ingredient.Id = ingredientId;
                    ingredient.UpdatedAt = DateTime.UtcNow;
                    ingredient.CreatedAt = existingIngredient.CreatedAt;
                    
                    var filter = Builders<Ingredient>.Filter.Eq(i => i.Id, ingredientId);
                    var result = await ingredientsColl.ReplaceOneAsync(filter, ingredient);
                    
                    if (result.ModifiedCount > 0)
                    {
                        // Log the update activity with before/after comparison
                        var updateLogDetails = new
                        {
                            action = "Update",
                            ingredientName = ingredient.IngredientName,
                            changes = new
                            {
                                before = new
                                {
                                    ingredientName = existingIngredient.IngredientName,
                                    unit = existingIngredient.Unit,
                                    costPerUnit = existingIngredient.CostPerUnit,
                                    currentStock = existingIngredient.CurrentStock,
                                    minimumStock = existingIngredient.MinimumStock,
                                    supplierId = existingIngredient.SupplierId,
                                    totalValue = existingIngredient.TotalValue
                                },
                                after = new
                                {
                                    ingredientName = ingredient.IngredientName,
                                    unit = ingredient.Unit,
                                    costPerUnit = ingredient.CostPerUnit,
                                    currentStock = ingredient.CurrentStock,
                                    minimumStock = ingredient.MinimumStock,
                                    supplierId = ingredient.SupplierId,
                                    totalValue = ingredient.TotalValue
                                }
                            },
                            supplierName = ddlSupplier.SelectedItem?.Text,
                            timestamp = DateTime.UtcNow
                        };
                        
                        ActivityLogger.Log(
                            action: "Update Ingredient",
                            entityType: "Ingredient",
                            entityId: ingredientId,
                            detailsJson: JsonConvert.SerializeObject(updateLogDetails, Formatting.Indented)
                        );
                        
                        // Store success message in session
                        Session["IngredientSuccessMessage"] = "Ingredient updated successfully!";
                        
                        // Redirect to same page without query parameters
                        Response.Redirect(Request.Url.AbsolutePath, false);
                        Context.ApplicationInstance.CompleteRequest();
                        return;
                    }
                    else
                    {
                        ShowMessage("No changes were made.", "danger");
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? SaveIngredientAsync error: {ex.Message}");
                ShowMessage("Failed to save ingredient: " + ex.Message, "danger");
                
                // Log the error
                ActivityLogger.Log(
                    action: "Error - Save Ingredient Failed",
                    entityType: "Ingredient",
                    entityId: hfIngredientId.Value ?? "Unknown",
                    detailsJson: JsonConvert.SerializeObject(new { 
                        error = ex.Message,
                        stackTrace = ex.StackTrace,
                        timestamp = DateTime.UtcNow
                    }, Formatting.Indented)
                );
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
