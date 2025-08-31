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
        /// Creates a new sale and automatically decrements the variant stock (trigger functionality)
        /// </summary>
        public async Task<bool> CreateSaleAsync(Sale sale)
        {
            using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
            {
                session.StartTransaction();
                try
                {
                    // Step 1: Validate variant stock availability
                    var variant = await _variantsCollection
                        .Find(session, v => v.Id == sale.VariantId && v.IsActive)
                        .FirstOrDefaultAsync();

                    if (variant == null)
                    {
                        throw new InvalidOperationException("Product variant not found or inactive");
                    }

                    if (variant.StockQuantity < sale.Quantity)
                    {
                        throw new InvalidOperationException($"Insufficient stock. Available: {variant.StockQuantity}, Requested: {sale.Quantity}");
                    }

                    // Step 2: Insert the sale record
                    sale.CreatedAt = DateTime.UtcNow;
                    sale.UpdatedAt = DateTime.UtcNow;
                    sale.StockDecrementProcessed = false;

                    await _salesCollection.InsertOneAsync(session, sale);

                    // Step 3: Decrement the variant stock (trigger functionality)
                    var updateDefinition = Builders<ProductVariant>.Update
                        .Inc(v => v.StockQuantity, -sale.Quantity)
                        .Set(v => v.UpdatedAt, DateTime.UtcNow);

                    var updateResult = await _variantsCollection.UpdateOneAsync(
                        session,
                        v => v.Id == sale.VariantId,
                        updateDefinition);

                    if (updateResult.ModifiedCount == 0)
                    {
                        throw new InvalidOperationException("Failed to update variant stock");
                    }

                    // Step 4: Mark stock decrement as processed
                    await _salesCollection.UpdateOneAsync(
                        session,
                        s => s.Id == sale.Id,
                        Builders<Sale>.Update.Set(s => s.StockDecrementProcessed, true));

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
        /// Cancels a sale and restores the variant stock
        /// </summary>
        public async Task<bool> CancelSaleAsync(string saleId, string cancelledBy)
        {
            using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
            {
                session.StartTransaction();
                try
                {
                    // Step 1: Get the sale record
                    var sale = await _salesCollection
                        .Find(session, s => s.Id == saleId && s.IsActive)
                        .FirstOrDefaultAsync();

                    if (sale == null)
                    {
                        throw new InvalidOperationException("Sale not found or already cancelled");
                    }

                    // Step 2: Restore the variant stock
                    if (sale.StockDecrementProcessed)
                    {
                        var updateDefinition = Builders<ProductVariant>.Update
                            .Inc(v => v.StockQuantity, sale.Quantity)
                            .Set(v => v.UpdatedAt, DateTime.UtcNow);

                        await _variantsCollection.UpdateOneAsync(
                            session,
                            v => v.Id == sale.VariantId,
                            updateDefinition);
                    }

                    // Step 3: Mark sale as cancelled
                    await _salesCollection.UpdateOneAsync(
                        session,
                        s => s.Id == saleId,
                        Builders<Sale>.Update
                            .Set(s => s.IsActive, false)
                            .Set(s => s.UpdatedAt, DateTime.UtcNow)
                            .Set(s => s.Notes, $"{sale.Notes} | Cancelled by {cancelledBy} on {DateTime.UtcNow}"));

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
        /// Batch process to fix any sales that didn't process stock decrements
        /// </summary>
        public async Task<int> ProcessPendingStockDecrementsAsync()
        {
            var pendingSales = await _salesCollection
                .Find(s => s.IsActive && !s.StockDecrementProcessed)
                .ToListAsync();

            int processedCount = 0;

            foreach (var sale in pendingSales)
            {
                try
                {
                    using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
                    {
                        session.StartTransaction();

                        var updateDefinition = Builders<ProductVariant>.Update
                            .Inc(v => v.StockQuantity, -sale.Quantity)
                            .Set(v => v.UpdatedAt, DateTime.UtcNow);

                        await _variantsCollection.UpdateOneAsync(
                            session,
                            v => v.Id == sale.VariantId,
                            updateDefinition);

                        await _salesCollection.UpdateOneAsync(
                            session,
                            s => s.Id == sale.Id,
                            Builders<Sale>.Update.Set(s => s.StockDecrementProcessed, true));

                        await session.CommitTransactionAsync();
                        processedCount++;
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Failed to process stock decrement for sale {sale.Id}: {ex.Message}");
                }
            }

            return processedCount;
        }
    }
}