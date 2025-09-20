using System;
using System.Threading.Tasks;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Models
{
    public class Sale
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; }

        // NEW: direct reference to Product (for fast product-level aggregation)
        [BsonElement("productId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductId { get; set; }

        [BsonElement("variantId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string VariantId { get; set; }

        [BsonElement("quantity")]
        public int Quantity { get; set; }

        [BsonElement("salePrice")]
        public decimal SalePrice { get; set; }

        // NEW: tax and discounts
        [BsonElement("saleTax")]
        public decimal SaleTax { get; set; } = 0m;

        [BsonElement("saleDiscounts")]
        public decimal SaleDiscounts { get; set; } = 0m;

        [BsonElement("transactionDate")]
        public DateTime TransactionDate { get; set; } = DateTime.UtcNow;

        // NEW: Suggested Retail Price
        [BsonElement("srp")]
        public decimal SRP { get; set; } = 0m;

        // Navigation property (not stored in MongoDB)
        [BsonIgnore]
        public ProductVariant ProductVariant { get; set; }

        // Calculated properties for display purposes
        [BsonIgnore]
        public string FormattedSalePrice => "$" + SalePrice.ToString("F2");

        [BsonIgnore]
        public string FormattedTransactionDate => TransactionDate.ToString("MMM dd, yyyy HH:mm");

        [BsonIgnore]
        public decimal TotalAmount => SalePrice * Quantity; // gross

        [BsonIgnore]
        public decimal NetAmount => (SalePrice * Quantity) + SaleTax - SaleDiscounts;

        [BsonIgnore]
        public string FormattedTotalAmount => "$" + TotalAmount.ToString("F2");

        [BsonIgnore]
        public string FormattedNetAmount => "$" + NetAmount.ToString("F2");

        /// <summary>
        /// Trigger-like functionality: Automatically decrements stock when sale is inserted
        /// </summary>
        public async Task<bool> ProcessStockDecrementAsync()
        {
            try
            {
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var variant = await variantsCollection.Find(pv => pv.Id == VariantId && pv.IsActive).FirstOrDefaultAsync();
                if (variant == null) throw new InvalidOperationException($"Product variant with ID {VariantId} not found or inactive");
                if (variant.StockQuantity < Quantity) throw new InvalidOperationException($"Insufficient stock. Available: {variant.StockQuantity}, Requested: {Quantity}");

                // ensure ProductId populated if not set (backward compatibility)
                if (string.IsNullOrWhiteSpace(ProductId)) ProductId = variant.ProductId;

                var updateDefinition = Builders<ProductVariant>.Update
                    .Inc(pv => pv.StockQuantity, -Quantity)
                    .Set(pv => pv.UpdatedAt, DateTime.UtcNow);

                var result = await variantsCollection.UpdateOneAsync(pv => pv.Id == VariantId, updateDefinition);
                return result.ModifiedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Stock decrement failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Reverse trigger functionality: Restores stock when sale is deleted/cancelled
        /// </summary>
        public async Task<bool> ProcessStockIncrementAsync()
        {
            try
            {
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var updateDefinition = Builders<ProductVariant>.Update
                    .Inc(pv => pv.StockQuantity, Quantity)
                    .Set(pv => pv.UpdatedAt, DateTime.UtcNow);
                var result = await variantsCollection.UpdateOneAsync(pv => pv.Id == VariantId, updateDefinition);
                return result.ModifiedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Stock increment failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Factory method creates sale, sets ProductId (via variant lookup) and decrements stock.
        /// </summary>
        public static async Task<Sale> CreateSaleWithTriggerAsync(string variantId, int quantity, decimal salePrice, decimal saleTax = 0m, decimal saleDiscounts = 0m)
        {
            var salesCollection = DatabaseHelper.GetSalesCollection();
            var variantsCollection = DatabaseHelper.GetProductVariantsCollection();

            var variant = await variantsCollection.Find(v => v.Id == variantId).FirstOrDefaultAsync();
            if (variant == null) throw new InvalidOperationException("Variant not found for sale creation");

            var newSale = new Sale
            {
                VariantId = variantId,
                ProductId = variant.ProductId, // direct link to product
                Quantity = quantity,
                SalePrice = salePrice,
                SaleTax = saleTax,
                SaleDiscounts = saleDiscounts,
                TransactionDate = DateTime.UtcNow,
                SRP = variant.Price
            };

            using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
            {
                session.StartTransaction();
                try
                {
                    await salesCollection.InsertOneAsync(session, newSale);
                    var stockDecremented = await newSale.ProcessStockDecrementAsync();
                    if (!stockDecremented) throw new InvalidOperationException("Failed to decrement stock");
                    await session.CommitTransactionAsync();
                    return newSale;
                }
                catch
                {
                    await session.AbortTransactionAsync();
                    throw;
                }
            }
        }

        /// <summary>
        /// Seeds comprehensive sales data tying both VariantId and ProductId.
        /// </summary>
        public static async Task SeedSalesDataAsync()
        {
            try
            {
                var salesCollection = DatabaseHelper.GetSalesCollection();
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var existingSales = await salesCollection.CountDocumentsAsync(_ => true);
                if (existingSales > 0) { System.Diagnostics.Debug.WriteLine("Sales data exists - skipping seed"); return; }

                var variants = await variantsCollection.Find(v => v.IsActive && v.StockQuantity > 10).ToListAsync();
                if (variants.Count == 0) throw new InvalidOperationException("No variants available for seeding");

                var random = new Random(42);
                int created = 0;

                DateTime Utc(int daysBack) => DateTime.UtcNow.AddDays(-daysBack).Date.AddHours(random.Next(9, 21)).AddMinutes(random.Next(0, 60));

                // Recent 30 days
                for (int d = 30; d >= 1; d--)
                {
                    var salesPerDay = random.Next(2, 5);
                    for (int i = 0; i < salesPerDay; i++)
                    {
                        var variant = variants[random.Next(variants.Count)];
                        if (variant.StockQuantity <= 0) continue;
                        var qty = Math.Min(variant.StockQuantity, random.Next(1, 4));
                        var sale = new Sale
                        {
                            VariantId = variant.Id,
                            ProductId = variant.ProductId,
                            Quantity = qty,
                            SalePrice = variant.Price * (decimal)(0.9 + random.NextDouble() * 0.2),
                            SaleTax = variant.Price * qty * 0.12m,
                            SaleDiscounts = random.Next(0, 3) == 0 ? variant.Price * qty * 0.05m : 0m,
                            TransactionDate = Utc(d),
                            SRP = variant.Price
                        };
                        await salesCollection.InsertOneAsync(sale);
                        await variantsCollection.UpdateOneAsync(v => v.Id == variant.Id, Builders<ProductVariant>.Update.Inc(v => v.StockQuantity, -qty));
                        created++;
                    }
                }

                System.Diagnostics.Debug.WriteLine($"Seeded {created} sales records with ProductId linkage.");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Seed sales error: " + ex.Message);
                throw;
            }
        }
    }
}