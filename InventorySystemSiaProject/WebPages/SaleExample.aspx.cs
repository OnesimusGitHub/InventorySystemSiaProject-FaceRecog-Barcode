using System;
using System.Threading.Tasks;
using System.Web.UI;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.WebPages
{
    public partial class SaleExample : Page
    {
        private SalesService _salesService;

        protected void Page_Load(object sender, EventArgs e)
        {
            _salesService = new SalesService();
        }

        // Example method to create a sale with automatic stock decrement (TRIGGER BEHAVIOR)
        protected async void CreateSale_Click(object sender, EventArgs e)
        {
            try
            {
                // Method 1: Using the trigger-like static method
                var sale = await Sale.CreateSaleWithTriggerAsync(
                    variantId: "your-variant-objectid-here", // Replace with actual variant ID
                    quantity: 2,
                    salePrice: 29.99m
                );

                Response.Write($"<script>alert('Sale created with TRIGGER behavior! Sale ID: {sale.Id}\\nStock automatically decremented by {sale.Quantity} units.');</script>");
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Error: {ex.Message}');</script>");
            }
        }

        // Alternative method using SalesService (also has trigger behavior)
        protected async void CreateSaleAlt_Click(object sender, EventArgs e)
        {
            try
            {
                var newSale = new Sale
                {
                    VariantId = "your-variant-objectid-here", // Replace with actual variant ID
                    Quantity = 3,
                    SalePrice = 45.99m,
                    TransactionDate = DateTime.UtcNow
                };

                // This will automatically trigger stock decrement
                bool success = await _salesService.CreateSaleAsync(newSale);

                if (success)
                {
                    Response.Write($"<script>alert('Sale created with SERVICE trigger! Sale total: {newSale.FormattedTotalAmount}\\nStock decremented: {newSale.Quantity} units.');</script>");
                }
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Error: {ex.Message}');</script>");
            }
        }

        // Example method to cancel a sale and restore stock (REVERSE TRIGGER)
        protected async void CancelSale_Click(object sender, EventArgs e)
        {
            try
            {
                string saleId = "your-sale-objectid-here"; // Replace with actual sale ID

                bool success = await _salesService.CancelSaleAsync(saleId);

                if (success)
                {
                    Response.Write("<script>alert('Sale cancelled with REVERSE TRIGGER!\\nStock automatically restored.');</script>");
                }
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Error: {ex.Message}');</script>");
            }
        }

        // Example method to check stock before sale (useful with triggers)
        protected async void CheckStock_Click(object sender, EventArgs e)
        {
            try
            {
                string variantId = "your-variant-objectid-here"; // Replace with actual variant ID
                int requestedQuantity = 5;

                var variant = await _salesService.GetVariantStockAsync(variantId);
                bool wouldCauseLowStock = await _salesService.WouldCauseLowStockAsync(variantId, requestedQuantity);

                if (variant != null)
                {
                    string message = $"STOCK CHECK (Before Trigger):\\n";
                    message += $"Current Stock: {variant.StockQuantity}\\n";
                    message += $"Minimum Stock: {variant.MinimumStock}\\n";
                    message += $"Requested Quantity: {requestedQuantity}\\n";
                    message += $"Would cause low stock: {wouldCauseLowStock}\\n";
                    message += $"After sale stock would be: {variant.StockQuantity - requestedQuantity}";

                    Response.Write($"<script>alert('{message}');</script>");
                }
                else
                {
                    Response.Write("<script>alert('Variant not found!');</script>");
                }
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Error: {ex.Message}');</script>");
            }
        }

        // Demonstration of the trigger behavior with comprehensive example
        protected async void DemoTrigger_Click(object sender, EventArgs e)
        {
            try
            {
                // This demonstrates the complete trigger workflow:
                // 1. INSERT INTO ProductSales -> Automatically decrements stock
                // 2. Shows before/after stock levels
                
                string variantId = "your-variant-objectid-here"; // Replace with actual variant ID
                
                // Check stock before
                var variantBefore = await _salesService.GetVariantStockAsync(variantId);
                if (variantBefore == null)
                {
                    Response.Write("<script>alert('Variant not found for demo!');</script>");
                    return;
                }

                int stockBefore = variantBefore.StockQuantity;
                int saleQuantity = 1;

                // Create sale (this triggers stock decrement)
                var sale = await Sale.CreateSaleWithTriggerAsync(variantId, saleQuantity, 25.00m);

                // Check stock after
                var variantAfter = await _salesService.GetVariantStockAsync(variantId);
                int stockAfter = variantAfter.StockQuantity;

                string demoMessage = $"TRIGGER DEMONSTRATION:\\n\\n";
                demoMessage += $"BEFORE SALE:\\n";
                demoMessage += $"Stock Level: {stockBefore}\\n\\n";
                demoMessage += $"SALE CREATED:\\n";
                demoMessage += $"Sale ID: {sale.Id}\\n";
                demoMessage += $"Quantity Sold: {saleQuantity}\\n";
                demoMessage += $"Sale Price: {sale.FormattedSalePrice}\\n\\n";
                demoMessage += $"AFTER SALE (Trigger Applied):\\n";
                demoMessage += $"Stock Level: {stockAfter}\\n";
                demoMessage += $"Stock Decremented: {stockBefore - stockAfter}\\n\\n";
                demoMessage += $"? TRIGGER WORKED: Stock automatically decremented on INSERT!";

                Response.Write($"<script>alert('{demoMessage}');</script>");
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Trigger Demo Error: {ex.Message}');</script>");
            }
        }
    }
}