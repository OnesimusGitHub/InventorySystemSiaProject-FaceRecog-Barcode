using System;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using System.Collections.Generic;
using MongoDB.Bson;
using System.Linq;

namespace InventorySystemSiaProject.Services
{
    public class SalesService
    {
        private readonly IMongoCollection<Sale> _salesCollection;
        private readonly IMongoCollection<Sale> _productSalesCollection; // legacy/secondary collection
        private readonly IMongoCollection<ProductVariant> _variantsCollection;

        public SalesService()
        {
            _salesCollection = DatabaseHelper.GetSalesCollection();
            _productSalesCollection = DatabaseHelper.GetProductSalesCollection();
            _variantsCollection = DatabaseHelper.GetProductVariantsCollection();
        }

        #region Create / Cancel
        /// <summary>
        /// Creates a new sale with automatic stock decrement (uses trigger-like behavior)
        /// </summary>
        public async Task<Sale> CreateSaleAsync(string variantId, int quantity, decimal salePrice)
            => await Sale.CreateSaleWithTriggerAsync(variantId, quantity, salePrice);

        /// <summary>
        /// Creates a new sale with tax and discounts and automatic stock decrement
        /// </summary>
        public async Task<Sale> CreateSaleAsync(string variantId, int quantity, decimal salePrice, decimal saleTax, decimal saleDiscounts)
            => await Sale.CreateSaleWithTriggerAsync(variantId, quantity, salePrice, saleTax, saleDiscounts);

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
                    // Ensure ProductId populated
                    if (string.IsNullOrWhiteSpace(sale.ProductId))
                    {
                        var v = await _variantsCollection.Find(x => x.Id == sale.VariantId).FirstOrDefaultAsync();
                        if (v != null) sale.ProductId = v.ProductId;
                    }
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
        #endregion

        #region Variant & Stock Helpers
        /// <summary>
        /// Gets variant stock information
        /// </summary>
        public async Task<ProductVariant> GetVariantStockAsync(string variantId)
            => await _variantsCollection.Find(v => v.Id == variantId && v.IsActive).FirstOrDefaultAsync();

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
        #endregion

        #region Basic Queries
        /// <summary>
        /// Gets the count of sales
        /// </summary>
        public async Task<long> GetSalesCountAsync() => await _salesCollection.CountDocumentsAsync(_ => true);

        /// <summary>
        /// Gets all sales
        /// </summary>
        public async Task<List<Sale>> GetAllSalesAsync() => await _salesCollection
            .Find(_ => true).SortByDescending(s => s.TransactionDate).ToListAsync();

        /// <summary>
        /// Gets sales by variant ID
        /// </summary>
        public async Task<List<Sale>> GetSalesByVariantAsync(string variantId) => await _salesCollection
            .Find(s => s.VariantId == variantId).SortByDescending(s => s.TransactionDate).ToListAsync();
        #endregion

        #region Combined Fetch by VariantIds
        /// <summary>
        /// Combined fetch from both Sales and ProductSales tables
        /// </summary>
        public async Task<List<Sale>> GetCombinedSalesByVariantIdsAsync(IEnumerable<string> variantIds, DateTime? sinceUtc = null)
        {
            var idList = variantIds?.Where(id => !string.IsNullOrWhiteSpace(id)).Distinct().ToList() ?? new List<string>();
            if (idList.Count == 0) return new List<Sale>();
            var builder = Builders<Sale>.Filter;
            var filter = builder.In(s => s.VariantId, idList);
            if (sinceUtc.HasValue) filter = builder.And(filter, builder.Gte(s => s.TransactionDate, sinceUtc.Value));
            var list1 = await _salesCollection.Find(filter).ToListAsync();
            var list2 = await _productSalesCollection.Find(filter).ToListAsync();
            return Merge(list1, list2);
        }
        #endregion

        #region Combined Fetch by ProductId (direct ProductId field OR via variant lookup)
        /// <summary>
        /// Fetch sales for a product directly via lookup (fallback when variant list mismatch).
        /// Supports both ObjectId and string productId forms in variant.productId.
        /// </summary>
        public async Task<List<Sale>> GetCombinedSalesByProductIdAsync(string productId, DateTime? sinceUtc = null)
        {
            if (string.IsNullOrWhiteSpace(productId)) return new List<Sale>();

            // Direct productId filter (new field we added)
            var builder = Builders<Sale>.Filter;
            var filter = builder.Eq(s => s.ProductId, productId);
            if (sinceUtc.HasValue) filter = builder.And(filter, builder.Gte(s => s.TransactionDate, sinceUtc.Value));
            var direct1 = await _salesCollection.Find(filter).ToListAsync();
            var direct2 = await _productSalesCollection.Find(filter).ToListAsync();
            var combinedDirect = Merge(direct1, direct2);
            if (combinedDirect.Count > 0) return combinedDirect; // fast path

            // Fallback: look up variant ids for the product then aggregate
            var variantIds = await _variantsCollection.Find(v => v.ProductId == productId)
                .Project(v => v.Id).ToListAsync();
            return await GetCombinedSalesByVariantIdsAsync(variantIds, sinceUtc);
        }
        #endregion

        #region Aggregation Helpers
        private List<Sale> Merge(List<Sale> a, List<Sale> b)
        {
            var dict = new Dictionary<string, Sale>();
            void AddRange(List<Sale> list)
            {
                foreach (var s in list)
                {
                    if (string.IsNullOrEmpty(s.Id)) continue;
                    if (!dict.ContainsKey(s.Id)) dict[s.Id] = s;
                }
            }
            AddRange(a); AddRange(b);
            return new List<Sale>(dict.Values);
        }

        /// <summary>
        /// Returns total quantity & revenue for a product (current period window)
        /// </summary>
        public async Task<(int totalQty, decimal grossAmount, decimal netAmount)> GetProductTotalsAsync(string productId, DateTime? sinceUtc = null)
        {
            var sales = await GetCombinedSalesByProductIdAsync(productId, sinceUtc);
            int qty = 0; decimal gross = 0; decimal net = 0;
            foreach (var s in sales)
            {
                qty += s.Quantity;
                gross += s.TotalAmount;
                net += s.NetAmount;
            }
            return (qty, gross, net);
        }
        #endregion

        #region Sample / Demo
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
                    salePrice: 29.99m,
                    saleTax: 0m,
                    saleDiscounts: 0m
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
        #endregion
    }
}