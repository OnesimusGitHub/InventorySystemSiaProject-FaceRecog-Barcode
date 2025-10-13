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
    // Added: granularity enum for single-product reporting
    public enum ProductReportGranularity
    {
        Daily,
        Weekly,
        Monthly
    }

    // Added: aggregation DTO
    public class ProductSalesAggregation
    {
        public string ProductId { get; set; }
        public DateTime PeriodStartUtc { get; set; }
        public DateTime PeriodEndUtc { get; set; }
        public string PeriodLabel { get; set; }
        public int TotalQuantity { get; set; }
        public decimal GrossAmount { get; set; }
        public decimal NetAmount { get; set; }
    }

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

        /// <summary>
        /// Aggregates sales for a single product for the given date window using daily / monthly server-side grouping or weekly in-memory.
        /// </summary>
        public async Task<List<ProductSalesAggregation>> GetSingleProductAggregatedAsync(string productId, ProductReportGranularity granularity, DateTime startUtc, DateTime endUtc)
        {
            if (string.IsNullOrWhiteSpace(productId)) return new List<ProductSalesAggregation>();
            startUtc = startUtc.ToUniversalTime();
            endUtc = endUtc.ToUniversalTime();
            if (endUtc <= startUtc) return new List<ProductSalesAggregation>();

            // Fallback variant ids for older sales where productId may be missing
            var variantIds = await _variantsCollection.Find(v => v.ProductId == productId)
                .Project(v => v.Id).ToListAsync();
            var variantIdSet = new HashSet<string>(variantIds ?? new List<string>());

            if (granularity == ProductReportGranularity.Weekly)
            {
                // Weekly done in-memory
                var filterBuilder = Builders<Sale>.Filter;
                var dateFilter = filterBuilder.Gte(s => s.TransactionDate, startUtc) & filterBuilder.Lt(s => s.TransactionDate, endUtc);
                FilterDefinition<Sale> idFilter;
                if (variantIdSet.Count > 0)
                {
                    idFilter = filterBuilder.Or(
                        filterBuilder.Eq(s => s.ProductId, productId),
                        filterBuilder.In(s => s.VariantId, variantIdSet)
                    );
                }
                else
                {
                    idFilter = filterBuilder.Eq(s => s.ProductId, productId);
                }
                var filter = dateFilter & idFilter;
                var list1 = await _salesCollection.Find(filter).ToListAsync();
                var list2 = await _productSalesCollection.Find(filter).ToListAsync();
                var all = list1.Concat(list2).ToList();

                // De-duplicate by Id (in case the OR matched both conditions or record appears in both collections)
                var distinct = new Dictionary<string, Sale>();
                foreach (var s in all)
                {
                    if (string.IsNullOrEmpty(s.Id)) continue;
                    distinct[s.Id] = s; // last wins (same content anyway)
                }

                var grouped = distinct.Values.GroupBy(s => WeekStartUtc(s.TransactionDate));
                var weeks = new List<ProductSalesAggregation>();
                foreach (var g in grouped.OrderBy(g => g.Key))
                {
                    int qty = 0; decimal gross = 0; decimal net = 0;
                    foreach (var s in g)
                    {
                        qty += s.Quantity;
                        gross += s.TotalAmount;
                        net += s.NetAmount;
                    }
                    weeks.Add(new ProductSalesAggregation
                    {
                        ProductId = productId,
                        PeriodStartUtc = g.Key,
                        PeriodEndUtc = g.Key.AddDays(7),
                        PeriodLabel = $"W{ISOWeek(g.Key):00}-{ISOWeekYear(g.Key)}",
                        TotalQuantity = qty,
                        GrossAmount = gross,
                        NetAmount = net
                    });
                }
                return weeks;
            }

            // Daily / Monthly via aggregation pipeline, include OR clause for variantId fallback
            string format = granularity == ProductReportGranularity.Daily ? "%Y-%m-%d" : "%Y-%m";

            BsonDocument idOr;
            if (variantIdSet.Count > 0)
            {
                idOr = new BsonDocument("$or", new BsonArray
                {
                    new BsonDocument("productId", productId),
                    new BsonDocument("variantId", new BsonDocument("$in", new BsonArray(variantIdSet)))
                });
            }
            else
            {
                idOr = new BsonDocument("productId", productId);
            }

            var match = new BsonDocument("$and", new BsonArray
            {
                new BsonDocument("transactionDate", new BsonDocument { {"$gte", startUtc}, {"$lt", endUtc} }),
                idOr
            });

            var grossExpr = new BsonDocument("$multiply", new BsonArray { "$salePrice", "$quantity" });
            var netExpr = new BsonDocument("$add", new BsonArray { new BsonDocument("$subtract", new BsonArray { grossExpr, "$saleDiscounts" }), "$saleTax" });
            var periodExpr = new BsonDocument("$dateToString", new BsonDocument { { "format", format }, { "date", "$transactionDate" } });

            var pipeline = new List<BsonDocument>
            {
                new BsonDocument("$match", match),
                new BsonDocument("$group", new BsonDocument
                {
                    { "_id", periodExpr },
                    { "qty", new BsonDocument("$sum", "$quantity") },
                    { "gross", new BsonDocument("$sum", grossExpr) },
                    { "net", new BsonDocument("$sum", netExpr) }
                }),
                new BsonDocument("$sort", new BsonDocument("_id", 1))
            };

            var aggCursor = await _salesCollection.AggregateAsync<BsonDocument>(pipeline);
            var docs1 = await aggCursor.ToListAsync();
            var aggCursor2 = await _productSalesCollection.AggregateAsync<BsonDocument>(pipeline);
            var docs2 = await aggCursor2.ToListAsync();
            var merged = new Dictionary<string, (int qty, decimal gross, decimal net)>();
            void AddDocs(List<BsonDocument> docs)
            {
                foreach (var d in docs)
                {
                    var key = d["_id"].AsString;
                    int q = d.GetValue("qty", 0).ToInt32();
                    decimal g = d.GetValue("gross", 0m).ToDecimal();
                    decimal n = d.GetValue("net", 0m).ToDecimal();
                    if (merged.ContainsKey(key))
                    {
                        var existing = merged[key];
                        merged[key] = (existing.qty + q, existing.gross + g, existing.net + n);
                    }
                    else merged[key] = (q, g, n);
                }
            }
            AddDocs(docs1); AddDocs(docs2);

            var results = new List<ProductSalesAggregation>();
            foreach (var kvp in merged.OrderBy(k => k.Key))
            {
                DateTime ps; DateTime pe;
                if (granularity == ProductReportGranularity.Daily)
                {
                    DateTime.TryParse(kvp.Key, out ps);
                    ps = DateTime.SpecifyKind(ps, DateTimeKind.Utc);
                    pe = ps.AddDays(1);
                }
                else
                {
                    var parts = kvp.Key.Split('-');
                    int year = int.Parse(parts[0]);
                    int month = int.Parse(parts[1]);
                    ps = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
                    pe = ps.AddMonths(1);
                }
                results.Add(new ProductSalesAggregation
                {
                    ProductId = productId,
                    PeriodStartUtc = ps,
                    PeriodEndUtc = pe,
                    PeriodLabel = kvp.Key,
                    TotalQuantity = kvp.Value.qty,
                    GrossAmount = kvp.Value.gross,
                    NetAmount = kvp.Value.net
                });
            }
            return results;
        }

        private DateTime WeekStartUtc(DateTime date)
        {
            if (date.Kind != DateTimeKind.Utc) date = date.ToUniversalTime();
            int diff = ((int)date.DayOfWeek + 6) % 7; // Monday=0
            return date.Date.AddDays(-diff);
        }
        private int ISOWeekYear(DateTime date)
        {
            var thursday = date.AddDays(3 - ((int)date.DayOfWeek + 6) % 7);
            return thursday.Year;
        }
        private int ISOWeek(DateTime date)
        {
            var thursday = date.AddDays(3 - ((int)date.DayOfWeek + 6) % 7);
            var firstThursday = new DateTime(thursday.Year, 1, 4);
            var firstWeekStart = firstThursday.AddDays(-((int)firstThursday.DayOfWeek + 6) % 7);
            return (int)((thursday.Date - firstWeekStart.Date).TotalDays / 7) + 1;
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