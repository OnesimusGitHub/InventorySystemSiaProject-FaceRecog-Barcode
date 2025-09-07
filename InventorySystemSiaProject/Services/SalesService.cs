using System;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Services
{
    public class SalesService
    {
        private readonly IMongoCollection<Sale> _salesCollection;
        private readonly IMongoCollection<ProductVariant> _variantsCollection;

        public SalesService()
        {
            _salesCollection = DatabaseHelper.GetSalesCollection();
            _variantsCollection = DatabaseHelper.GetProductVariantsCollection();
        }

        /// <summary>
        /// Creates a new sale with automatic stock decrement (uses trigger-like behavior)
        /// </summary>
        public async Task<Sale> CreateSaleAsync(string variantId, int quantity, decimal salePrice)
        {
            try
            {
                // Use the static method that includes trigger behavior
                return await Sale.CreateSaleWithTriggerAsync(variantId, quantity, salePrice);
            }
            catch (Exception ex)
            {
                throw new Exception($"Sale creation failed: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Creates a sale from a Sale object with automatic stock decrement
        /// </summary>
        public async Task<bool> CreateSaleAsync(Sale sale)
        {
            using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
            {
                session.StartTransaction();
                try
                {
                    // Insert the sale
                    await _salesCollection.InsertOneAsync(session, sale);
                    
                    // Process stock decrement (trigger behavior)
                    var stockDecremented = await sale.ProcessStockDecrementAsync();
                    
                    if (!stockDecremented)
                    {
                        throw new InvalidOperationException("Failed to decrement stock");
                    }

                    await session.CommitTransactionAsync();
                    return true;
                }
                catch (Exception ex)
                {
                    await session.AbortTransactionAsync();
                    throw new Exception($"Sale creation failed: {ex.Message}", ex);
                }
            }
        }

        /// <summary>
        /// Cancels a sale and restores the variant stock (reverse trigger)
        /// </summary>
        public async Task<bool> CancelSaleAsync(string saleId)
        {
            using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
            {
                session.StartTransaction();
                try
                {
                    // Get the sale record
                    var sale = await _salesCollection
                        .Find(session, s => s.Id == saleId)
                        .FirstOrDefaultAsync();

                    if (sale == null)
                    {
                        throw new InvalidOperationException("Sale not found");
                    }

                    // Process stock increment (reverse trigger behavior)
                    var stockRestored = await sale.ProcessStockIncrementAsync();
                    
                    if (!stockRestored)
                    {
                        throw new InvalidOperationException("Failed to restore stock");
                    }

                    // Delete the sale record
                    await _salesCollection.DeleteOneAsync(session, s => s.Id == saleId);

                    await session.CommitTransactionAsync();
                    return true;
                }
                catch (Exception ex)
                {
                    await session.AbortTransactionAsync();
                    throw new Exception($"Sale cancellation failed: {ex.Message}", ex);
                }
            }
        }

        /// <summary>
        /// Gets variant stock information
        /// </summary>
        public async Task<ProductVariant> GetVariantStockAsync(string variantId)
        {
            return await _variantsCollection
                .Find(v => v.Id == variantId && v.IsActive)
                .FirstOrDefaultAsync();
        }

        /// <summary>
        /// Checks if a sale would cause stock to go below minimum
        /// </summary>
        public async Task<bool> WouldCauseLowStockAsync(string variantId, int quantity)
        {
            var variant = await GetVariantStockAsync(variantId);
            if (variant == null) return false;

            var newStock = variant.StockQuantity - quantity;
            return newStock <= variant.MinimumStock;
        }

        /// <summary>
        /// Gets the count of sales
        /// </summary>
        public async Task<long> GetSalesCountAsync()
        {
            return await _salesCollection.CountDocumentsAsync(_ => true);
        }

        /// <summary>
        /// Gets all sales
        /// </summary>
        public async Task<System.Collections.Generic.List<Sale>> GetAllSalesAsync()
        {
            return await _salesCollection
                .Find(_ => true)
                .SortByDescending(s => s.TransactionDate)
                .ToListAsync();
        }

        /// <summary>
        /// Gets sales by variant ID
        /// </summary>
        public async Task<System.Collections.Generic.List<Sale>> GetSalesByVariantAsync(string variantId)
        {
            return await _salesCollection
                .Find(s => s.VariantId == variantId)
                .SortByDescending(s => s.TransactionDate)
                .ToListAsync();
        }

        /// <summary>
        /// Example method demonstrating trigger usage
        /// </summary>
        public async Task<Sale> CreateSampleSaleAsync()
        {
            try
            {
                // This will automatically trigger stock decrement
                var sale = await CreateSaleAsync(
                    variantId: "your-variant-id-here",
                    quantity: 2,
                    salePrice: 29.99m
                );

                System.Diagnostics.Debug.WriteLine($"Sale created with trigger: {sale.Id}, Stock automatically decremented by {sale.Quantity}");
                return sale;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Trigger example failed: {ex.Message}");
                throw;
            }
        }
    }
}