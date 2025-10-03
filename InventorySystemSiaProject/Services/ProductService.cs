using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Bson;
using System.Text.RegularExpressions;
using System.Linq;

namespace InventorySystemSiaProject.Services
{
    public class ProductService
    {
        private readonly IMongoCollection<Product> _productsCollection;
        private readonly IMongoCollection<Ingredient> _ingredientsCollection;
        private readonly IMongoCollection<ProductIngredient> _productIngredientsCollection;
        private readonly IMongoCollection<ProductVariant> _productVariantsCollection;
        private readonly IMongoCollection<Sale> _salesCollection;
        private readonly IMongoCollection<StockRequest> _stockRequestsCollection;

        // One-time index setup flags
        private static bool _indexesEnsured = false;
        private static readonly object _indexLock = new object();

        public ProductService()
        {
            _productsCollection = DatabaseHelper.GetProductsCollection();
            _ingredientsCollection = DatabaseHelper.GetIngredientsCollection();
            _productIngredientsCollection = DatabaseHelper.GetProductIngredientsCollection();
            _productVariantsCollection = DatabaseHelper.GetProductVariantsCollection();
            _salesCollection = DatabaseHelper.GetSalesCollection();
            _stockRequestsCollection = DatabaseHelper.GetStockRequestsCollection();

            EnsureIndexes();
        }

        // Idempotency helper: find a product with same name+category created within a time window (case-insensitive)
        public async Task<Product> FindRecentDuplicateAsync(string name, string category, TimeSpan window)
        {
            if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(category)) return null;
            var since = DateTime.UtcNow.Subtract(window);

            // Use case-insensitive filters for name and category
            var nameFilter = Builders<Product>.Filter.Regex(p => p.ProductName, new BsonRegularExpression("^" + Regex.Escape(name.Trim()) + "$", "i"));
            var catFilter = Builders<Product>.Filter.Regex(p => p.ProductCategory, new BsonRegularExpression("^" + Regex.Escape(category.Trim()) + "$", "i"));
            var timeFilter = Builders<Product>.Filter.Gte(p => p.CreatedAt, since);
            var activeFilter = Builders<Product>.Filter.Eq(p => p.IsActive, true);

            var filter = Builders<Product>.Filter.And(nameFilter, catFilter, timeFilter, activeFilter);
            return await _productsCollection.Find(filter).FirstOrDefaultAsync();
        }

        private void EnsureIndexes()
        {
            if (_indexesEnsured) return;
            lock (_indexLock)
            {
                if (_indexesEnsured) return;
                try
                {
                    // Index for variants lookup by productId + isActive
                    var variantKeys = Builders<ProductVariant>.IndexKeys
                        .Ascending(v => v.ProductId)
                        .Ascending(v => v.IsActive);
                    var variantOptions = new CreateIndexOptions
                    {
                        Name = "idx_variant_productId_isActive",
                        Background = true
                    };
                    _productVariantsCollection.Indexes.CreateOne(new CreateIndexModel<ProductVariant>(variantKeys, variantOptions));

                    // Simple index on Products.IsActive for fast filtering
                    var productKeys = Builders<Product>.IndexKeys.Ascending(p => p.IsActive);
                    var productOptions = new CreateIndexOptions
                    {
                        Name = "idx_product_isActive",
                        Background = true
                    };
                    _productsCollection.Indexes.CreateOne(new CreateIndexModel<Product>(productKeys, productOptions));

                    // Helpful index for direct id lookups (redundant in many cases but cheap)
                    try
                    {
                        var productIdKeys = Builders<Product>.IndexKeys.Ascending(p => p.Id);
                        _productsCollection.Indexes.CreateOne(new CreateIndexModel<Product>(productIdKeys, new CreateIndexOptions { Name = "idx_product_id", Background = true }));
                    }
                    catch { }

                    // Index for stock requests: by productVariantID and status
                    try
                    {
                        var srKeys = Builders<StockRequest>.IndexKeys
                            .Ascending(r => r.ProductVariantID)
                            .Ascending(r => r.RequestStatus)
                            .Descending(r => r.RequestDate);
                        _stockRequestsCollection.Indexes.CreateOne(new CreateIndexModel<StockRequest>(srKeys, new CreateIndexOptions { Name = "idx_stockRequests_variant_status_date", Background = true }));
                    }
                    catch { }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"EnsureIndexes warning: {ex.Message}");
                }
                finally
                {
                    _indexesEnsured = true;
                }
            }
        }

        /// <summary>
        /// Creates a new product with enhanced debugging and proper ObjectId handling
        /// </summary>
        public async Task<string> CreateProductAsync(Product product)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("?? CreateProductAsync started");
                System.Diagnostics.Debug.WriteLine($"?? Product Name: {product.ProductName}");
                System.Diagnostics.Debug.WriteLine($"?? Product Category: {product.ProductCategory}");
                
                // Validate the product first
                if (!product.IsValid())
                {
                    throw new ArgumentException("Product validation failed: Product name and category are required");
                }
                
                // Prepare the product for insertion
                product.PrepareForInsertion();
                
                System.Diagnostics.Debug.WriteLine($"?? Product prepared for insertion:");
                System.Diagnostics.Debug.WriteLine($"  - Name: {product.ProductName}");
                System.Diagnostics.Debug.WriteLine($"  - Category: {product.ProductCategory}");
                System.Diagnostics.Debug.WriteLine($"  - Description: {product.ProductDesc}");
                System.Diagnostics.Debug.WriteLine($"  - Value: {product.ProductVal}");
                System.Diagnostics.Debug.WriteLine($"  - CreatedAt: {product.CreatedAt}");
                System.Diagnostics.Debug.WriteLine($"  - IsActive: {product.IsActive}");
                
                // Get the collection
                var collection = _productsCollection;
                if (collection == null)
                {
                    System.Diagnostics.Debug.WriteLine("? Products collection is null!");
                    throw new Exception("Products collection is not initialized");
                }
                
                System.Diagnostics.Debug.WriteLine("?? Products collection obtained successfully");
                System.Diagnostics.Debug.WriteLine($"?? Collection name: {collection.CollectionNamespace.CollectionName}");
                System.Diagnostics.Debug.WriteLine($"?? Database name: {collection.Database.DatabaseNamespace.DatabaseName}");
                
                // Test collection access first
                try
                {
                    var testCount = await collection.CountDocumentsAsync(FilterDefinition<Product>.Empty);
                    System.Diagnostics.Debug.WriteLine($"?? Current document count in Products collection: {testCount}");
                }
                catch (Exception testEx)
                {
                    System.Diagnostics.Debug.WriteLine($"? Error accessing collection: {testEx.Message}");
                    throw new Exception($"Cannot access Products collection: {testEx.Message}");
                }
                
                // Clear any existing ID to let MongoDB generate a new one
                product.Id = null;
                
                // Insert the product
                System.Diagnostics.Debug.WriteLine("?? About to insert product into database...");
                await collection.InsertOneAsync(product);
                
                System.Diagnostics.Debug.WriteLine($"?? Product inserted successfully with ID: {product.Id}");
                
                // Verify the insertion immediately
                if (string.IsNullOrEmpty(product.Id))
                {
                    System.Diagnostics.Debug.WriteLine("? Product ID is still null after insert!");
                    throw new Exception("MongoDB did not generate an ID for the product");
                }
                
                // Double-check by querying the database
                var insertedProduct = await collection.Find(p => p.Id == product.Id).FirstOrDefaultAsync();
                if (insertedProduct == null)
                {
                    System.Diagnostics.Debug.WriteLine("? Product verification failed - not found after insert");
                    throw new Exception("Product was not saved properly - verification failed");
                }
                
                System.Diagnostics.Debug.WriteLine($"? Product verified in database: {insertedProduct.ProductName}");
                System.Diagnostics.Debug.WriteLine($"? Verified Product ID: {insertedProduct.Id}");
                System.Diagnostics.Debug.WriteLine($"? Verified Product Category: {insertedProduct.ProductCategory}");
                System.Diagnostics.Debug.WriteLine($"? Verified Product Value: {insertedProduct.ProductVal}");
                
                // Final count verification
                var finalCount = await collection.CountDocumentsAsync(FilterDefinition<Product>.Empty);
                System.Diagnostics.Debug.WriteLine($"?? Final document count in Products collection: {finalCount}");
                
                return product.Id;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? CreateProductAsync failed: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"? Stack trace: {ex.StackTrace}");
                
                // If it's a MongoDB specific error, provide more details
                if (ex is MongoException mongoEx)
                {
                    System.Diagnostics.Debug.WriteLine($"? MongoDB Error Code: {mongoEx.GetType().Name}");
                }
                
                throw new Exception($"Failed to create product: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Creates an ingredient
        /// </summary>
        public async Task<string> CreateIngredientAsync(Ingredient ingredient)
        {
            try
            {
                ingredient.CreatedAt = DateTime.UtcNow;
                ingredient.UpdatedAt = DateTime.UtcNow;
                ingredient.IsActive = true;
                
                await _ingredientsCollection.InsertOneAsync(ingredient);
                return ingredient.Id;
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to create ingredient: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Creates a product variant
        /// </summary>
        public async Task<string> CreateProductVariantAsync(ProductVariant variant)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("?? CreateProductVariantAsync started");
                System.Diagnostics.Debug.WriteLine($"?? Variant Name: {variant.VariantName}");
                System.Diagnostics.Debug.WriteLine($"?? Product ID: {variant.ProductId}");
                System.Diagnostics.Debug.WriteLine($"?? SKU: {variant.SKU}");
                
                // Validate required fields
                if (string.IsNullOrEmpty(variant.ProductId))
                {
                    throw new ArgumentException("Product ID is required for variant");
                }
                
                if (string.IsNullOrEmpty(variant.SKU))
                {
                    throw new ArgumentException("SKU is required for variant");
                }
                
                // Set default values
                variant.CreatedAt = DateTime.UtcNow;
                variant.UpdatedAt = DateTime.UtcNow;
                variant.IsActive = true;
                
                // Clear any existing ID to let MongoDB generate a new one
                variant.Id = null;
                
                // Get the collection
                var collection = _productVariantsCollection;
                if (collection == null)
                {
                    System.Diagnostics.Debug.WriteLine("? ProductVariants collection is null!");
                    throw new Exception("ProductVariants collection is not initialized");
                }
                
                System.Diagnostics.Debug.WriteLine("?? ProductVariants collection obtained successfully");
                
                // Test collection access first
                try
                {
                    var testCount = await collection.CountDocumentsAsync(FilterDefinition<ProductVariant>.Empty);
                    System.Diagnostics.Debug.WriteLine($"?? Current document count in ProductVariants collection: {testCount}");
                }
                catch (Exception testEx)
                {
                    System.Diagnostics.Debug.WriteLine($"? Error accessing ProductVariants collection: {testEx.Message}");
                    throw new Exception($"Cannot access ProductVariants collection: {testEx.Message}");
                }
                
                // Insert the variant
                System.Diagnostics.Debug.WriteLine("?? About to insert variant into database...");
                await collection.InsertOneAsync(variant);
                
                System.Diagnostics.Debug.WriteLine($"?? Variant inserted successfully with ID: {variant.Id}");
                
                // Verify the insertion
                if (string.IsNullOrEmpty(variant.Id))
                {
                    System.Diagnostics.Debug.WriteLine("? Variant ID is still null after insert!");
                    throw new Exception("MongoDB did not generate an ID for the variant");
                }
                
                // Double-check by querying the database
                var insertedVariant = await collection.Find(v => v.Id == variant.Id).FirstOrDefaultAsync();
                if (insertedVariant == null)
                {
                    System.Diagnostics.Debug.WriteLine("? Variant verification failed - not found after insert");
                    throw new Exception("Variant was not saved properly - verification failed");
                }
                
                System.Diagnostics.Debug.WriteLine($"? Variant verified in database: {insertedVariant.VariantName}");
                System.Diagnostics.Debug.WriteLine($"? Verified Variant ID: {insertedVariant.Id}");
                
                return variant.Id;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? CreateProductVariantAsync failed: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"? Stack trace: {ex.StackTrace}");
                throw new Exception($"Failed to create product variant: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Creates a product-ingredient relationship
        /// </summary>
        public async Task<string> CreateProductIngredientAsync(ProductIngredient productIngredient)
        {
            try
            {
                productIngredient.CreatedAt = DateTime.UtcNow;
                productIngredient.IsActive = true;
                
                await _productIngredientsCollection.InsertOneAsync(productIngredient);
                return productIngredient.Id;
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to create product ingredient relationship: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Gets all products
        /// </summary>
        public async Task<List<Product>> GetAllProductsAsync()
        {
            return await _productsCollection
                .Find(p => p.IsActive)
                .ToListAsync();
        }

        /// <summary>
        /// Gets all ingredients
        /// </summary>
        public async Task<List<Ingredient>> GetAllIngredientsAsync()
        {
            return await _ingredientsCollection
                .Find(i => i.IsActive)
                .ToListAsync();
        }

        /// <summary>
        /// Gets all product variants
        /// </summary>
        public async Task<List<ProductVariant>> GetAllProductVariantsAsync()
        {
            return await _productVariantsCollection
                .Find(v => v.IsActive)
                .ToListAsync();
        }

        /// <summary>
        /// Gets product variants by product ID
        /// </summary>
        public async Task<List<ProductVariant>> GetProductVariantsByProductIdAsync(string productId)
        {
            try
            {
                if (string.IsNullOrEmpty(productId))
                {
                    throw new ArgumentException("Product ID is required");
                }

                return await _productVariantsCollection
                    .Find(v => v.ProductId == productId && v.IsActive)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting product variants: {ex.Message}");
                throw new Exception($"Failed to get product variants: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Gets a product by ID
        /// </summary>
        public async Task<Product> GetProductByIdAsync(string productId)
        {
            try
            {
                if (string.IsNullOrEmpty(productId))
                {
                    throw new ArgumentException("Product ID is required");
                }

                return await _productsCollection
                    .Find(p => p.Id == productId && p.IsActive)
                    .FirstOrDefaultAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting product by ID: {ex.Message}");
                throw new Exception($"Failed to get product: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Gets a product variant by ID
        /// </summary>
        public async Task<ProductVariant> GetProductVariantByIdAsync(string variantId)
        {
            try
            {
                if (string.IsNullOrEmpty(variantId))
                {
                    throw new ArgumentException("Variant ID is required");
                }

                return await _productVariantsCollection
                    .Find(v => v.Id == variantId && v.IsActive)
                    .FirstOrDefaultAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting product variant by ID: {ex.Message}");
                throw new Exception($"Failed to get product variant: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Gets all sales
        /// </summary>
        public async Task<List<Sale>> GetAllSalesAsync()
        {
            return await _salesCollection
                .Find(_ => true)
                .SortByDescending(s => s.TransactionDate)
                .ToListAsync();
        }

        /// <summary>
        /// Seeds the database with beauty product data
        /// </summary>
        public async Task SeedBeautyProductsAsync()
        {
            try
            {
                // Check if data already exists
                var existingProducts = await _productsCollection.CountDocumentsAsync(p => p.IsActive);
                if (existingProducts > 0)
                {
                    System.Diagnostics.Debug.WriteLine("Products already exist, skipping seed data");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("Starting to seed beauty products data...");

                // Create ingredients first
                var ingredients = new List<Ingredient>
                {
                    new Ingredient
                    {
                        IngredientName = "Hyaluronic Acid",
                        Unit = "ml",
                        CostPerUnit = 0.15m,
                        CurrentStock = 1000,
                        MinimumStock = 100,
                        Supplier = "BeautyIngredients Co."
                    },
                    new Ingredient
                    {
                        IngredientName = "Vitamin C",
                        Unit = "g",
                        CostPerUnit = 0.25m,
                        CurrentStock = 500,
                        MinimumStock = 50,
                        Supplier = "VitaminSupply Ltd."
                    },
                    new Ingredient
                    {
                        IngredientName = "Retinol",
                        Unit = "g",
                        CostPerUnit = 2.50m,
                        CurrentStock = 200,
                        MinimumStock = 20,
                        Supplier = "PremiumSkincare Inc."
                    },
                    new Ingredient
                    {
                        IngredientName = "Niacinamide",
                        Unit = "g",
                        CostPerUnit = 0.30m,
                        CurrentStock = 800,
                        MinimumStock = 80,
                        Supplier = "SkincareTech Solutions"
                    },
                    new Ingredient
                    {
                        IngredientName = "Salicylic Acid",
                        Unit = "g",
                        CostPerUnit = 0.40m,
                        CurrentStock = 600,
                        MinimumStock = 60,
                        Supplier = "ChemBeauty Corp."
                    },
                    new Ingredient
                    {
                        IngredientName = "Glycolic Acid",
                        Unit = "g",
                        CostPerUnit = 0.35m,
                        CurrentStock = 400,
                        MinimumStock = 40,
                        Supplier = "AcidBeauty Ltd."
                    },
                    new Ingredient
                    {
                        IngredientName = "Peptides",
                        Unit = "g",
                        CostPerUnit = 5.00m,
                        CurrentStock = 150,
                        MinimumStock = 15,
                        Supplier = "BioSkincare Research"
                    },
                    new Ingredient
                    {
                        IngredientName = "Ceramides",
                        Unit = "g",
                        CostPerUnit = 1.20m,
                        CurrentStock = 300,
                        MinimumStock = 30,
                        Supplier = "LipidBeauty Inc."
                    }
                };

                var ingredientIds = new List<string>();
                foreach (var ingredient in ingredients)
                {
                    var id = await CreateIngredientAsync(ingredient);
                    ingredientIds.Add(id);
                }

                // Create beauty products
                var products = new List<Product>
                {
                    new Product
                    {
                        ProductName = "Hydrating Serum",
                        ProductDesc = "Intensive hydrating serum with hyaluronic acid for plump, moisturized skin",
                        ProductCategory = "Skincare",
                        BaseIngredients = "Hyaluronic Acid, Glycerin, Water",
                        ProductImg = "/Content/images/hydrating-serum.jpg",
                        ProductVal = 29.99m
                    },
                    new Product
                    {
                        ProductName = "Vitamin C Brightening Cream",
                        ProductDesc = "Brightening day cream with vitamin C to even skin tone and reduce dark spots",
                        ProductCategory = "Skincare",
                        BaseIngredients = "Vitamin C, Niacinamide, Shea Butter",
                        ProductImg = "/Content/images/vitamin-c-cream.jpg",
                        ProductVal = 34.99m
                    },
                    new Product
                    {
                        ProductName = "Anti-Aging Night Serum",
                        ProductDesc = "Powerful anti-aging serum with retinol and peptides for overnight skin renewal",
                        ProductCategory = "Skincare",
                        BaseIngredients = "Retinol, Peptides, Ceramides",
                        ProductImg = "/Content/images/anti-aging-serum.jpg",
                        ProductVal = 49.99m
                    },
                    new Product
                    {
                        ProductName = "Acne Treatment Gel",
                        ProductDesc = "Targeted acne treatment gel with salicylic acid to clear blemishes",
                        ProductCategory = "Skincare",
                        BaseIngredients = "Salicylic Acid, Niacinamide, Tea Tree Oil",
                        ProductImg = "/Content/images/acne-treatment.jpg",
                        ProductVal = 19.99m
                    },
                    new Product
                    {
                        ProductName = "Exfoliating Toner",
                        ProductDesc = "Gentle exfoliating toner with glycolic acid for smooth, radiant skin",
                        ProductCategory = "Skincare",
                        BaseIngredients = "Glycolic Acid, Witch Hazel, Aloe Vera",
                        ProductImg = "/Content/images/exfoliating-toner.jpg",
                        ProductVal = 24.99m
                    },
                    new Product
                    {
                        ProductName = "Luxe Face Mask Set",
                        ProductDesc = "Premium face mask collection for deep cleansing and nourishment",
                        ProductCategory = "Skincare",
                        BaseIngredients = "Clay, Hyaluronic Acid, Vitamin E",
                        ProductImg = "/Content/images/face-mask-set.jpg",
                        ProductVal = 39.99m
                    },
                    new Product
                    {
                        ProductName = "Matte Lipstick Collection",
                        ProductDesc = "Long-lasting matte lipsticks in 12 stunning shades",
                        ProductCategory = "Makeup",
                        BaseIngredients = "Wax, Pigments, Vitamin E",
                        ProductImg = "/Content/images/matte-lipstick.jpg",
                        ProductVal = 18.99m
                    },
                    new Product
                    {
                        ProductName = "Eyeshadow Palette - Sunset",
                        ProductDesc = "18-shade eyeshadow palette with warm sunset tones",
                        ProductCategory = "Makeup",
                        BaseIngredients = "Mica, Talc, Pigments",
                        ProductImg = "/Content/images/eyeshadow-palette.jpg",
                        ProductVal = 42.99m
                    }
                };

                var productIds = new List<string>();
                foreach (var product in products)
                {
                    var id = await CreateProductAsync(product);
                    productIds.Add(id);
                }

                // Create product variants
                var variants = new List<ProductVariant>
                {
                    // Hydrating Serum variants
                    new ProductVariant
                    {
                        ProductId = productIds[0],
                        VariantName = "Hydrating Serum - 30ml",
                        Size = "30ml",
                        Color = "Clear",
                        SKU = "HS-30ML-001",
                        Price = 29.99m,
                        StockQuantity = 50,
                        MinimumStock = 10,
                        Weight = 0.05m,
                        Dimensions = "3x3x8 cm"
                    },
                    new ProductVariant
                    {
                        ProductId = productIds[0],
                        VariantName = "Hydrating Serum - 50ml",
                        Size = "50ml",
                        Color = "Clear",
                        SKU = "HS-50ML-001",
                        Price = 45.99m,
                        StockQuantity = 30,
                        MinimumStock = 5,
                        Weight = 0.08m,
                        Dimensions = "4x4x10 cm"
                    },
                    // Vitamin C Cream variants
                    new ProductVariant
                    {
                        ProductId = productIds[1],
                        VariantName = "Vitamin C Cream - 50ml",
                        Size = "50ml",
                        Color = "White",
                        SKU = "VC-50ML-001",
                        Price = 34.99m,
                        StockQuantity = 40,
                        MinimumStock = 8,
                        Weight = 0.08m,
                        Dimensions = "5x5x6 cm"
                    },
                    // Anti-Aging Serum variants
                    new ProductVariant
                    {
                        ProductId = productIds[2],
                        VariantName = "Anti-Aging Serum - 30ml",
                        Size = "30ml",
                        Color = "Amber",
                        SKU = "AS-30ML-001",
                        Price = 49.99m,
                        StockQuantity = 25,
                        MinimumStock = 5,
                        Weight = 0.05m,
                        Dimensions = "3x3x8 cm"
                    },
                    // Acne Treatment variants
                    new ProductVariant
                    {
                        ProductId = productIds[3],
                        VariantName = "Acne Treatment - 15ml",
                        Size = "15ml",
                        Color = "Clear",
                        SKU = "AT-15ML-001",
                        Price = 19.99m,
                        StockQuantity = 60,
                        MinimumStock = 12,
                        Weight = 0.03m,
                        Dimensions = "2x2x6 cm"
                    },
                    // Exfoliating Toner variants
                    new ProductVariant
                    {
                        ProductId = productIds[4],
                        VariantName = "Exfoliating Toner - 150ml",
                        Size = "150ml",
                        Color = "Clear",
                        SKU = "ET-150ML-001",
                        Price = 24.99m,
                        StockQuantity = 35,
                        MinimumStock = 7,
                        Weight = 0.15m,
                        Dimensions = "6x6x12 cm"
                    },
                    // Face Mask Set variants
                    new ProductVariant
                    {
                        ProductId = productIds[5],
                        VariantName = "Face Mask Set - 5 Pack",
                        Size = "5 masks",
                        Color = "Multi",
                        SKU = "FM-5PK-001",
                        Price = 39.99m,
                        StockQuantity = 20,
                        MinimumStock = 4,
                        Weight = 0.20m,
                        Dimensions = "15x10x3 cm"
                    },
                    // Matte Lipstick variants
                    new ProductVariant
                    {
                        ProductId = productIds[6],
                        VariantName = "Matte Lipstick - Ruby Red",
                        Size = "3.5g",
                        Color = "Ruby Red",
                        SKU = "ML-RR-001",
                        Price = 18.99m,
                        StockQuantity = 45,
                        MinimumStock = 9,
                        Weight = 0.02m,
                        Dimensions = "2x2x8 cm"
                    },
                    new ProductVariant
                    {
                        ProductId = productIds[6],
                        VariantName = "Matte Lipstick - Berry Crush",
                        Size = "3.5g",
                        Color = "Berry Crush",
                        SKU = "ML-BC-001",
                        Price = 18.99m,
                        StockQuantity = 38,
                        MinimumStock = 8,
                        Weight = 0.02m,
                        Dimensions = "2x2x8 cm"
                    },
                    // Eyeshadow Palette variants
                    new ProductVariant
                    {
                        ProductId = productIds[7],
                        VariantName = "Eyeshadow Palette - Sunset",
                        Size = "18 shades",
                        Color = "Multi",
                        SKU = "EP-SUN-001",
                        Price = 42.99m,
                        StockQuantity = 22,
                        MinimumStock = 4,
                        Weight = 0.25m,
                        Dimensions = "14x8x1.5 cm"
                    }
                };

                // Insert variants
                foreach (var variant in variants)
                {
                    await CreateProductVariantAsync(variant);
                }

                System.Diagnostics.Debug.WriteLine("Seed beauty products completed successfully.");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Seed data error: {ex.Message}");
                throw;
            }
        }

        // DTO used by ProductProfile page expectations
        public class AggregationResult
        {
            public Product Product { get; set; }
            public List<ProductVariant> Variants { get; set; }
        }

        public async Task<AggregationResult> GetProductWithVariantsAggregationAsync(string productId)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(productId)) return new AggregationResult { Product = null, Variants = new List<ProductVariant>() };

                var product = await _productsCollection.Find(p => p.Id == productId).FirstOrDefaultAsync();
                var variants = await _productVariantsCollection.Find(v => v.ProductId == productId && v.IsActive).ToListAsync();
                if (variants == null) variants = new List<ProductVariant>();

                return new AggregationResult
                {
                    Product = product,
                    Variants = variants
                };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("GetProductWithVariantsAggregationAsync error: " + ex.Message);
                return new AggregationResult { Product = null, Variants = new List<ProductVariant>() };
            }
        }

        public async Task SeedSalesDataAsync()
        {
            // Placeholder: integrate with SalesService if needed
            await Task.CompletedTask;
        }

        public async Task SeedAllDataAsync()
        {
            await SeedBeautyProductsAsync();
            await SeedSalesDataAsync();
        }

        // StockRequest API
        public async Task<string> CreateStockRequestAsync(StockRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (string.IsNullOrWhiteSpace(request.ProductVariantID)) throw new ArgumentException("ProductVariantID is required");
            if (request.QuantityRequested <= 0) throw new ArgumentException("QuantityRequested must be greater than zero");

            request.RequestID = null; // let Mongo assign
            if (request.RequestDate == default(DateTime)) request.RequestDate = DateTime.UtcNow;
            if (string.IsNullOrWhiteSpace(request.RequestStatus)) request.RequestStatus = "Pending";

            await _stockRequestsCollection.InsertOneAsync(request);
            return request.RequestID;
        }

        public async Task<List<StockRequest>> GetStockRequestsAsync(string variantId = null, string status = null)
        {
            var filter = Builders<StockRequest>.Filter.Empty;
            if (!string.IsNullOrWhiteSpace(variantId))
            {
                filter &= Builders<StockRequest>.Filter.Eq(r => r.ProductVariantID, variantId);
            }
            if (!string.IsNullOrWhiteSpace(status))
            {
                filter &= Builders<StockRequest>.Filter.Eq(r => r.RequestStatus, status);
            }
            return await _stockRequestsCollection.Find(filter).SortByDescending(r => r.RequestDate).ToListAsync();
        }
    }
}