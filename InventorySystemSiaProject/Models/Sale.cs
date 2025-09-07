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
        public string FormattedSalePrice => $"${SalePrice:F2}";

        [BsonIgnore]
        public string FormattedTransactionDate => TransactionDate.ToString("MMM dd, yyyy HH:mm");

        [BsonIgnore]
        public decimal TotalAmount => SalePrice * Quantity; // keep compatibility - gross amount

        [BsonIgnore]
        public decimal NetAmount => (SalePrice * Quantity) + SaleTax - SaleDiscounts;

        [BsonIgnore]
        public string FormattedTotalAmount => $"${TotalAmount:F2}";

        [BsonIgnore]
        public string FormattedNetAmount => $"${NetAmount:F2}";

        /// <summary>
        /// Trigger-like functionality: Automatically decrements stock when sale is inserted
        /// This mimics the SQL trigger behavior: UPDATE pv SET pv.Variant_Stock = pv.Variant_Stock - i.Quantity
        /// </summary>
        public async Task<bool> ProcessStockDecrementAsync()
        {
            try
            {
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();
                
                // Find the product variant
                var variant = await variantsCollection
                    .Find(pv => pv.Id == this.VariantId && pv.IsActive)
                    .FirstOrDefaultAsync();

                if (variant == null)
                {
                    throw new InvalidOperationException($"Product variant with ID {this.VariantId} not found or inactive");
                }

                // Check if there's sufficient stock
                if (variant.StockQuantity < this.Quantity)
                {
                    throw new InvalidOperationException($"Insufficient stock. Available: {variant.StockQuantity}, Requested: {this.Quantity}");
                }

                // Update stock quantity (mimics the trigger logic)
                var updateDefinition = Builders<ProductVariant>.Update
                    .Inc(pv => pv.StockQuantity, -this.Quantity)  // pv.Variant_Stock = pv.Variant_Stock - i.Quantity
                    .Set(pv => pv.UpdatedAt, DateTime.UtcNow);

                var updateResult = await variantsCollection.UpdateOneAsync(
                    pv => pv.Id == this.VariantId,
                    updateDefinition
                );

                return updateResult.ModifiedCount > 0;
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
                
                // Update stock quantity (reverse the decrement)
                var updateDefinition = Builders<ProductVariant>.Update
                    .Inc(pv => pv.StockQuantity, this.Quantity)  // Add back the quantity
                    .Set(pv => pv.UpdatedAt, DateTime.UtcNow);

                var updateResult = await variantsCollection.UpdateOneAsync(
                    pv => pv.Id == this.VariantId,
                    updateDefinition
                );

                return updateResult.ModifiedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Stock increment failed: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Static method to create a sale with automatic stock decrement (trigger behavior)
        /// </summary>
        public static async Task<Sale> CreateSaleWithTriggerAsync(string variantId, int quantity, decimal salePrice, decimal saleTax = 0m, decimal saleDiscounts = 0m)
        {
            var salesCollection = DatabaseHelper.GetSalesCollection();
            
            // Create new sale instance
            var newSale = new Sale
            {
                VariantId = variantId,
                Quantity = quantity,
                SalePrice = salePrice,
                SaleTax = saleTax,
                SaleDiscounts = saleDiscounts,
                TransactionDate = DateTime.UtcNow
            };

            // Use transaction to ensure atomicity (like SQL trigger)
            using (var session = await DatabaseHelper.Database.Client.StartSessionAsync())
            {
                session.StartTransaction();
                try
                {
                    // Insert the sale
                    await salesCollection.InsertOneAsync(session, newSale);
                    
                    // Process stock decrement (trigger behavior)
                    var stockDecremented = await newSale.ProcessStockDecrementAsync();
                    
                    if (!stockDecremented)
                    {
                        throw new InvalidOperationException("Failed to decrement stock");
                    }

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
        /// Seeds comprehensive sales data for daily, weekly, and monthly analytics
        /// </summary>
        public static async Task SeedSalesDataAsync()
        {
            try
            {
                var salesCollection = DatabaseHelper.GetSalesCollection();
                var variantsCollection = DatabaseHelper.GetProductVariantsCollection();

                // Check if sales data already exists
                var existingSales = await salesCollection.CountDocumentsAsync(_ => true);
                if (existingSales > 0)
                {
                    System.Diagnostics.Debug.WriteLine("Sales data already exists, skipping seed");
                    return;
                }

                // Get available product variants for sales
                var variants = await variantsCollection
                    .Find(v => v.IsActive && v.StockQuantity > 10)
                    .ToListAsync();

                if (variants.Count == 0)
                {
                    throw new InvalidOperationException("No product variants available for sales seeding. Please seed products first.");
                }

                System.Diagnostics.Debug.WriteLine($"Found {variants.Count} variants for comprehensive sales seeding...");

                var salesCreated = 0;
                var random = new Random(42); // Fixed seed for consistent data

                // Create comprehensive sales data spanning different periods
                
                // 1. Daily sales (last 30 days) - 2-4 sales per day
                for (int day = 30; day >= 1; day--)
                {
                    var salesPerDay = random.Next(2, 5); // 2-4 sales per day
                    
                    for (int sale = 0; sale < salesPerDay; sale++)
                    {
                        var variant = variants[random.Next(variants.Count)];
                        var quantity = random.Next(1, 4); // 1-3 items per sale
                        
                        // Check stock availability
                        var currentVariant = await variantsCollection
                            .Find(v => v.Id == variant.Id)
                            .FirstOrDefaultAsync();

                        if (currentVariant?.StockQuantity < quantity) continue;

                        // Create realistic sale time (business hours 9 AM - 8 PM)
                        var saleDate = DateTime.UtcNow.AddDays(-day)
                            .Date.AddHours(random.Next(9, 21))
                            .AddMinutes(random.Next(0, 60));

                        var saleRecord = new Sale
                        {
                            VariantId = variant.Id,
                            Quantity = quantity,
                            SalePrice = variant.Price * (decimal)(0.9 + random.NextDouble() * 0.2), // Price variation ±10%
                            SaleTax = variant.Price * quantity * 0.12m, // 12% tax
                            SaleDiscounts = random.Next(0, 3) == 0 ? variant.Price * quantity * 0.05m : 0m, // 5% discount 1/3 of the time
                            TransactionDate = saleDate,
                            SRP = variant.Price // Always set SRP
                        };

                        await salesCollection.InsertOneAsync(saleRecord);

                        // Update stock
                        await variantsCollection.UpdateOneAsync(
                            v => v.Id == variant.Id,
                            Builders<ProductVariant>.Update
                                .Inc(v => v.StockQuantity, -quantity)
                                .Set(v => v.UpdatedAt, DateTime.UtcNow)
                        );

                        salesCreated++;
                    }
                }

                // 2. Weekly sales (last 12 weeks) - Additional weekly sales
                for (int week = 12; week >= 5; week--) // Start from 12 weeks ago, stop at 5 weeks to avoid overlap
                {
                    var salesPerWeek = random.Next(8, 15); // 8-14 sales per week
                    
                    for (int sale = 0; sale < salesPerWeek; sale++)
                    {
                        var variant = variants[random.Next(variants.Count)];
                        var quantity = random.Next(1, 5); // 1-4 items per sale
                        
                        // Check stock availability
                        var currentVariant = await variantsCollection
                            .Find(v => v.Id == variant.Id)
                            .FirstOrDefaultAsync();

                        if (currentVariant?.StockQuantity < quantity) continue;

                        // Random day within the week
                        var dayOfWeek = random.Next(0, 7);
                        var saleDate = DateTime.UtcNow.AddDays(-(week * 7) + dayOfWeek)
                            .Date.AddHours(random.Next(9, 21))
                            .AddMinutes(random.Next(0, 60));

                        var saleRecord = new Sale
                        {
                            VariantId = variant.Id,
                            Quantity = quantity,
                            SalePrice = variant.Price * (decimal)(0.85 + random.NextDouble() * 0.3), // Historical price variation
                            SaleTax = variant.Price * quantity * 0.10m, // 10% tax for historical data
                            SaleDiscounts = random.Next(0, 4) == 0 ? variant.Price * quantity * 0.08m : 0m, // 8% discount 1/4 of the time
                            TransactionDate = saleDate,
                            SRP = variant.Price // Always set SRP
                        };

                        await salesCollection.InsertOneAsync(saleRecord);

                        // Update stock
                        await variantsCollection.UpdateOneAsync(
                            v => v.Id == variant.Id,
                            Builders<ProductVariant>.Update
                                .Inc(v => v.StockQuantity, -quantity)
                                .Set(v => v.UpdatedAt, DateTime.UtcNow)
                        );

                        salesCreated++;
                    }
                }

                // 3. Monthly sales (last 12 months) - Seasonal variations
                for (int month = 12; month >= 3; month--) // Start from 12 months ago, stop at 3 months
                {
                    var seasonalMultiplier = GetSeasonalMultiplier(DateTime.UtcNow.AddMonths(-month).Month);
                    var salesPerMonth = (int)(random.Next(25, 45) * seasonalMultiplier); // 25-45 base sales with seasonal variation
                    
                    for (int sale = 0; sale < salesPerMonth; sale++)
                    {
                        var variant = variants[random.Next(variants.Count)];
                        var quantity = random.Next(1, 4); // 1-3 items per sale
                        
                        // Check stock availability
                        var currentVariant = await variantsCollection
                            .Find(v => v.Id == variant.Id)
                            .FirstOrDefaultAsync();

                        if (currentVariant?.StockQuantity < quantity) continue;

                        // Random day within the month
                        var baseDate = DateTime.UtcNow.AddMonths(-month);
                        var daysInMonth = DateTime.DaysInMonth(baseDate.Year, baseDate.Month);
                        var dayOfMonth = random.Next(1, daysInMonth + 1);
                        
                        var saleDate = new DateTime(baseDate.Year, baseDate.Month, dayOfMonth)
                            .AddHours(random.Next(9, 21))
                            .AddMinutes(random.Next(0, 60));

                        var saleRecord = new Sale
                        {
                            VariantId = variant.Id,
                            Quantity = quantity,
                            SalePrice = variant.Price * (decimal)(0.8 + random.NextDouble() * 0.4), // Historical price variation
                            SaleTax = variant.Price * quantity * 0.08m, // 8% tax for older data
                            SaleDiscounts = random.Next(0, 5) == 0 ? variant.Price * quantity * 0.10m : 0m, // 10% discount 1/5 of the time
                            TransactionDate = saleDate,
                            SRP = variant.Price // Always set SRP
                        };

                        await salesCollection.InsertOneAsync(saleRecord);

                        // Update stock
                        await variantsCollection.UpdateOneAsync(
                            v => v.Id == variant.Id,
                            Builders<ProductVariant>.Update
                                .Inc(v => v.StockQuantity, -quantity)
                                .Set(v => v.UpdatedAt, DateTime.UtcNow)
                        );

                        salesCreated++;
                    }
                }

                // 4. Create last year's data for comparison
                for (int month = 1; month <= 12; month++)
                {
                    var lastYearDate = DateTime.UtcNow.AddYears(-1);
                    var targetDate = new DateTime(lastYearDate.Year, month, 1);
                    
                    var seasonalMultiplier = GetSeasonalMultiplier(month);
                    var salesPerMonth = (int)(random.Next(20, 35) * seasonalMultiplier); // Lower baseline for last year
                    
                    for (int sale = 0; sale < salesPerMonth; sale++)
                    {
                        var variant = variants[random.Next(variants.Count)];
                        var quantity = random.Next(1, 3); // 1-2 items per sale (lower than current year)
                        
                        // Check stock availability
                        var currentVariant = await variantsCollection
                            .Find(v => v.Id == variant.Id)
                            .FirstOrDefaultAsync();

                        if (currentVariant?.StockQuantity < quantity) continue;

                        // Random day within the month
                        var daysInMonth = DateTime.DaysInMonth(targetDate.Year, targetDate.Month);
                        var dayOfMonth = random.Next(1, daysInMonth + 1);
                        
                        var saleDate = new DateTime(targetDate.Year, targetDate.Month, dayOfMonth)
                            .AddHours(random.Next(9, 21))
                            .AddMinutes(random.Next(0, 60));

                        var saleRecord = new Sale
                        {
                            VariantId = variant.Id,
                            Quantity = quantity,
                            SalePrice = variant.Price * (decimal)(0.7 + random.NextDouble() * 0.3), // Lower historical prices
                            SaleTax = variant.Price * quantity * 0.06m, // 6% tax for last year data
                            SaleDiscounts = random.Next(0, 6) == 0 ? variant.Price * quantity * 0.15m : 0m, // 15% discount 1/6 of the time
                            TransactionDate = saleDate,
                            SRP = variant.Price // Always set SRP
                        };

                        await salesCollection.InsertOneAsync(saleRecord);

                        // Update stock
                        await variantsCollection.UpdateOneAsync(
                            v => v.Id == variant.Id,
                            Builders<ProductVariant>.Update
                                .Inc(v => v.StockQuantity, -quantity)
                                .Set(v => v.UpdatedAt, DateTime.UtcNow)
                        );

                        salesCreated++;
                    }
                }

                System.Diagnostics.Debug.WriteLine($"Successfully seeded {salesCreated} comprehensive sales records spanning daily, weekly, monthly, and yearly periods!");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error seeding comprehensive sales data: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Returns seasonal multiplier for realistic sales variations
        /// </summary>
        private static double GetSeasonalMultiplier(int month)
        {
            // C# 7.3 compatible switch statement
            switch (month)
            {
                case 12:
                case 1:
                case 2:
                    return 1.3; // Holiday season - higher sales
                case 3:
                case 4:
                case 5:
                    return 1.1; // Spring - moderate increase
                case 6:
                case 7:
                case 8:
                    return 0.9; // Summer - slightly lower
                case 9:
                case 10:
                case 11:
                    return 1.0; // Fall - normal sales
                default:
                    return 1.0;
            }
        }
    }
}