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

        // Example method to create a sale with automatic stock decrement
        protected async void CreateSale_Click(object sender, EventArgs e)
        {
            try
            {
                var newSale = new Sale
                {
                    VariantId = "your-variant-objectid-here", // Replace with actual variant ID
                    Quantity = 2,
                    SalePrice = 29.99m,
                    CustomerName = "John Doe",
                    CustomerContact = "john@example.com",
                    PaymentMethod = "Credit Card",
                    PaymentStatus = "Completed",
                    SoldBy = "your-user-objectid-here" // Replace with actual user ID
                };

                // This will automatically decrement the stock (trigger functionality)
                bool success = await _salesService.CreateSaleAsync(newSale);

                if (success)
                {
                    Response.Write("<script>alert('Sale created successfully and stock decremented!');</script>");
                }
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Error: {ex.Message}');</script>");
            }
        }

        // Example method to cancel a sale and restore stock
        protected async void CancelSale_Click(object sender, EventArgs e)
        {
            try
            {
                string saleId = "your-sale-objectid-here"; // Replace with actual sale ID
                string cancelledBy = "admin-user-id"; // Replace with actual user ID

                bool success = await _salesService.CancelSaleAsync(saleId, cancelledBy);

                if (success)
                {
                    Response.Write("<script>alert('Sale cancelled and stock restored!');</script>");
                }
            }
            catch (Exception ex)
            {
                Response.Write($"<script>alert('Error: {ex.Message}');</script>");
            }
        }

        // Example method to check stock before sale
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
                    string message = $"Current Stock: {variant.StockQuantity}\\n";
                    message += $"Minimum Stock: {variant.MinimumStock}\\n";
                    message += $"Requested Quantity: {requestedQuantity}\\n";
                    message += $"Would cause low stock: {wouldCauseLowStock}";

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
    }
}