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
            var nameFilter = Builders<Product>.Filter.Regex(p => p.productName, new BsonRegularExpression("^" + Regex.Escape(name.Trim()) + "$", "i"));
            var catFilter = Builders<Product>.Filter.Regex(p => p.productCategory, new BsonRegularExpression("^" + Regex.Escape(category.Trim()) + "$", "i"));
            var timeFilter = Builders<Product>.Filter.Gte(p => p.createdAt, since);
            var statusFilter = Builders<Product>.Filter.Or(
                Builders<Product>.Filter.Eq(p => p.status, null),
                Builders<Product>.Filter.Eq(p => p.status, "Active")
            );

            var filter = Builders<Product>.Filter.And(nameFilter, catFilter, timeFilter, statusFilter);
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

                    // Simple index on Products.Status for fast filtering
                    var productKeys = Builders<Product>.IndexKeys.Ascending(p => p.status);
                    var productOptions = new CreateIndexOptions
                    {
                        Name = "idx_product_status",
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
                    System.Diagnostics.Debug.WriteLine(string.Format("EnsureIndexes warning: {0}", ex.Message));
                }
                finally
                {
                    _indexesEnsured = true;
                }
            }
        }
        public async Task<bool> UpdateProductAsync(Product product)
        {
            try
            {
                var filter = Builders<Product>.Filter.Eq("_id", ObjectId.Parse(product.Id));

                var update = Builders<Product>.Update
                    .Set(p => p.productName, product.productName)
                    .Set(p => p.productCategory, product.productCategory)
                    .Set(p => p.productDesc, product.productDesc)
                    .Set(p => p.updatedAt, product.updatedAt);

                // ✅ Only update image if new one was uploaded
                if (product.productImg != null && product.productImg.Length > 0)
                {
                    update = update
                        .Set(p => p.productImg, product.productImg)
                        .Set(p => p.ProductImgContentType, product.ProductImgContentType);
                }

                var result = await _productsCollection.UpdateOneAsync(filter, update);

                System.Diagnostics.Debug.WriteLine($"✅ Product updated: {result.ModifiedCount} document(s) modified");

                return result.ModifiedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ UpdateProductAsync error: {ex.Message}");
                throw;
            }
        }

        public async Task<bool> DeleteProductIngredientAsync(string ingredientId)
        {
            try
            {
                var filter = Builders<ProductIngredient>.Filter.Eq("_id", ObjectId.Parse(ingredientId));
                var result = await _productIngredientsCollection.DeleteOneAsync(filter);
                return result.DeletedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ DeleteProductIngredientAsync error: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Creates a new product with enhanced debugging and proper ObjectId handling
        /// </summary>
        public async Task<string> CreateProductAsync(Product product)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🔧 CreateProductAsync started");
                System.Diagnostics.Debug.WriteLine(string.Format("🔧 Product Name: {0}", product.productName));
                System.Diagnostics.Debug.WriteLine(string.Format("🔧 Product Category: {0}", product.productCategory));

                // ✅ FIXED: Use IsValid as a property, not a method
                if (!product.IsValid)  // ✅ Changed from IsValid() to IsValid
                {
                    throw new ArgumentException("Product validation failed: Product name and category are required");
                }

                // Prepare the product for insertion
                product.PrepareForInsertion();

                System.Diagnostics.Debug.WriteLine(string.Format("🔧 Product prepared for insertion:"));
                System.Diagnostics.Debug.WriteLine(string.Format("  - Name: {0}", product.productName));
                System.Diagnostics.Debug.WriteLine(string.Format("  - Category: {0}", product.productCategory));
                System.Diagnostics.Debug.WriteLine(string.Format("  - Description: {0}", product.productDesc));
                System.Diagnostics.Debug.WriteLine(string.Format("  - Value: {0}", product.productVal));
                System.Diagnostics.Debug.WriteLine(string.Format("  - CreatedAt: {0}", product.createdAt));
                System.Diagnostics.Debug.WriteLine(string.Format("  - Status: {0}", product.status));

                // Get the collection
                var collection = _productsCollection;
                if (collection == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Products collection is null!");
                    throw new Exception("Products collection is not initialized");
                }

                System.Diagnostics.Debug.WriteLine("✅ Products collection obtained successfully");
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Collection name: {0}", collection.CollectionNamespace.CollectionName));
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Database name: {0}", collection.Database.DatabaseNamespace.DatabaseName));

                // Test collection access first
                try
                {
                    var testCount = await collection.CountDocumentsAsync(FilterDefinition<Product>.Empty);
                    System.Diagnostics.Debug.WriteLine(string.Format("✅ Current document count in Products collection: {0}", testCount));
                }
                catch (Exception testEx)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ Error accessing collection: {0}", testEx.Message));
                    throw new Exception(string.Format("Cannot access Products collection: {0}", testEx.Message));
                }

                // Clear any existing ID to let MongoDB generate a new one
                product.Id = null;

                // Insert the product
                System.Diagnostics.Debug.WriteLine("✅ About to insert product into database...");
                await collection.InsertOneAsync(product);

                System.Diagnostics.Debug.WriteLine(string.Format("✅ Product inserted successfully with ID: {0}", product.Id));

                // Verify the insertion immediately
                if (string.IsNullOrEmpty(product.Id))
                {
                    System.Diagnostics.Debug.WriteLine("❌ Product ID is still null after insert!");
                    throw new Exception("MongoDB did not generate an ID for the product");
                }

                // Double-check by querying the database
                var insertedProduct = await collection.Find(p => p.Id == product.Id).FirstOrDefaultAsync();
                if (insertedProduct == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Product verification failed - not found after insert");
                    throw new Exception("Product was not saved properly - verification failed");
                }

                System.Diagnostics.Debug.WriteLine(string.Format("✅ Product verified in database: {0}", insertedProduct.productName));
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Verified Product ID: {0}", insertedProduct.Id));
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Verified Product Category: {0}", insertedProduct.productCategory));
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Verified Product Value: {0}", insertedProduct.productVal));

                // Final count verification
                var finalCount = await collection.CountDocumentsAsync(FilterDefinition<Product>.Empty);
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Final document count in Products collection: {0}", finalCount));

                return product.Id;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ CreateProductAsync failed: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("❌ Stack trace: {0}", ex.StackTrace));

                // If it's a MongoDB specific error, provide more details
                if (ex is MongoException mongoEx)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ MongoDB Error Code: {0}", mongoEx.GetType().Name));
                }

                throw new Exception(string.Format("Failed to create product: {0}", ex.Message), ex);
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
                throw new Exception(string.Format("Failed to create ingredient: {0}", ex.Message), ex);
            }
        }

        /// <summary>
        /// Creates a product variant
        /// </summary>
        public async Task<string> CreateProductVariantAsync(ProductVariant variant)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("🔧 CreateProductVariantAsync started");
                System.Diagnostics.Debug.WriteLine(string.Format("🔧 Variant Name: {0}", variant.VariantName));
                System.Diagnostics.Debug.WriteLine(string.Format("🔧 Product ID: {0}", variant.ProductId));
                System.Diagnostics.Debug.WriteLine(string.Format("🔧 SKU: {0}", variant.SKU));

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
                    System.Diagnostics.Debug.WriteLine("❌ ProductVariants collection is null!");
                    throw new Exception("ProductVariants collection is not initialized");
                }

                System.Diagnostics.Debug.WriteLine("✅ ProductVariants collection obtained successfully");

                // Test collection access first
                try
                {
                    var testCount = await collection.CountDocumentsAsync(FilterDefinition<ProductVariant>.Empty);
                    System.Diagnostics.Debug.WriteLine(string.Format("✅ Current document count in ProductVariants collection: {0}", testCount));
                }
                catch (Exception testEx)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ Error accessing ProductVariants collection: {0}", testEx.Message));
                    throw new Exception(string.Format("Cannot access ProductVariants collection: {0}", testEx.Message));
                }

                // Insert the variant
                System.Diagnostics.Debug.WriteLine("✅ About to insert variant into database...");
                await collection.InsertOneAsync(variant);

                System.Diagnostics.Debug.WriteLine(string.Format("✅ Variant inserted successfully with ID: {0}", variant.Id));

                // Verify the insertion
                if (string.IsNullOrEmpty(variant.Id))
                {
                    System.Diagnostics.Debug.WriteLine("❌ Variant ID is still null after insert!");
                    throw new Exception("MongoDB did not generate an ID for the variant");
                }

                // Double-check by querying the database
                var insertedVariant = await collection.Find(v => v.Id == variant.Id).FirstOrDefaultAsync();
                if (insertedVariant == null)
                {
                    System.Diagnostics.Debug.WriteLine("❌ Variant verification failed - not found after insert");
                    throw new Exception("Variant was not saved properly - verification failed");
                }

                System.Diagnostics.Debug.WriteLine(string.Format("✅ Variant verified in database: {0}", insertedVariant.VariantName));
                System.Diagnostics.Debug.WriteLine(string.Format("✅ Verified Variant ID: {0}", insertedVariant.Id));

                return variant.Id;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ CreateProductVariantAsync failed: {0}", ex.Message));
                System.Diagnostics.Debug.WriteLine(string.Format("❌ Stack trace: {0}", ex.StackTrace));
                throw new Exception(string.Format("Failed to create product variant: {0}", ex.Message), ex);
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
                throw new Exception(string.Format("Failed to create product ingredient relationship: {0}", ex.Message), ex);
            }
        }

        /// <summary>
        /// Gets all products
        /// </summary>
        public async Task<List<Product>> GetAllProductsAsync()
        {
            try
            {
                // ✅ FIX: Add projection to exclude productImg binary data
                var projection = Builders<Product>.Projection
                    .Exclude(p => p.productImg); // Exclude binary image data to avoid deserialization errors

                var products = await _productsCollection
                    .Find(Builders<Product>.Filter.Empty)
                    .Project<Product>(projection)
                    .ToListAsync();

                System.Diagnostics.Debug.WriteLine($"✅ Retrieved {products.Count} products (without productImg)");
                return products;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error in GetAllProductsAsync: {ex.Message}");
                throw;
            }
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
            try
            {
                // ✅ FIX: Add projection to exclude VariantImgUrls binary data
                var projection = Builders<ProductVariant>.Projection
                    .Exclude(v => v.VariantImgUrls); // Exclude binary image data array

                var variants = await _productVariantsCollection
                    .Find(Builders<ProductVariant>.Filter.Empty)
                    .Project<ProductVariant>(projection)
                    .ToListAsync();

                System.Diagnostics.Debug.WriteLine($"✅ Retrieved {variants.Count} product variants (without VariantImgUrls)");
                return variants;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error in GetAllProductVariantsAsync: {ex.Message}");
                throw;
            }
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
                    System.Diagnostics.Debug.WriteLine("❌ ProductId is null or empty in GetProductVariantsByProductIdAsync");
                    return new List<ProductVariant>();
                }

                // ✅ FIX: Add projection to exclude VariantImgUrls
                var projection = Builders<ProductVariant>.Projection
                    .Exclude(v => v.VariantImgUrls);

                var filter = Builders<ProductVariant>.Filter.Eq(v => v.ProductId, productId);

                var variants = await _productVariantsCollection
                    .Find(filter)
                    .Project<ProductVariant>(projection)
                    .ToListAsync();

                System.Diagnostics.Debug.WriteLine($"✅ Retrieved {variants.Count} variants for product {productId}");
                return variants;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Error in GetProductVariantsByProductIdAsync: {ex.Message}");
                throw;
            }
        }


        public Product GetProductById(string productId)
        {
            try
            {
                if (string.IsNullOrEmpty(productId))
                {
                    throw new ArgumentException("Product ID is required");
                }

                // ✅ FIX: Add projection to exclude binary image data
                var projection = Builders<Product>.Projection
                    .Exclude(p => p.productImg)
                    .Exclude(p => p.ProductImgContentType);

                var filter = Builders<Product>.Filter.Eq(p => p.Id, productId);

                var product = _productsCollection
                    .Find(filter)
                    .Project<Product>(projection)
                    .FirstOrDefault();

                return product;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting product by ID: {ex.Message}");
                throw;
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
                    .Find(p => p.Id == productId && (p.status == null || p.status == "Active"))
                    .FirstOrDefaultAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("Error getting product by ID: {0}", ex.Message));
                throw new Exception(string.Format("Failed to get product: {0}", ex.Message), ex);
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
                System.Diagnostics.Debug.WriteLine(string.Format("Error getting product variant by ID: {0}", ex.Message));
                throw new Exception(string.Format("Failed to get product variant: {0}", ex.Message), ex);
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
                var existingProducts = await _productsCollection.CountDocumentsAsync(
                    Builders<Product>.Filter.Or(
                        Builders<Product>.Filter.Eq(p => p.status, null),
                        Builders<Product>.Filter.Eq(p => p.status, "Active")
                    )
                );
                if (existingProducts > 0)
                {
                    System.Diagnostics.Debug.WriteLine("Products already exist, skipping seed data");
                    return;
                }

                System.Diagnostics.Debug.WriteLine("Starting to seed beauty products data...");

                // Get or create suppliers first
                var supplierService = new SupplierService();

                // Ensure suppliers are seeded
                var existingSuppliers = await supplierService.GetAllSuppliersAsync();
                if (existingSuppliers == null || existingSuppliers.Count == 0)
                {
                    System.Diagnostics.Debug.WriteLine("No suppliers found, seeding suppliers first...");
                    await supplierService.SeedSuppliersAsync();
                    existingSuppliers = await supplierService.GetAllSuppliersAsync();
                }

                // Get supplier IDs by name
                string GetSupplierIdByName(string supplierName)
                {
                    var supplier = existingSuppliers.FirstOrDefault(s => s.SupName.Contains(supplierName));
                    return supplier?.SupplierID ?? string.Empty;
                }

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
                        SupplierId = GetSupplierIdByName("Beauty Essentials")
                    },
                    new Ingredient
                    {
                        IngredientName = "Vitamin C",
                        Unit = "g",
                        CostPerUnit = 0.25m,
                        CurrentStock = 500,
                        MinimumStock = 50,
                        SupplierId = GetSupplierIdByName("Premium Skincare")
                    },
                    new Ingredient
                    {
                        IngredientName = "Retinol",
                        Unit = "g",
                        CostPerUnit = 2.50m,
                        CurrentStock = 200,
                        MinimumStock = 20,
                        SupplierId = GetSupplierIdByName("Premium Skincare")
                    },
                    new Ingredient
                    {
                        IngredientName = "Niacinamide",
                        Unit = "g",
                        CostPerUnit = 0.30m,
                        CurrentStock = 800,
                        MinimumStock = 80,
                        SupplierId = GetSupplierIdByName("Natural Beauty")
                    },
                    new Ingredient
                    {
                        IngredientName = "Salicylic Acid",
                        Unit = "g",
                        CostPerUnit = 0.40m,
                        CurrentStock = 600,
                        MinimumStock = 60,
                        SupplierId = GetSupplierIdByName("Glow Cosmetics")
                    },
                    new Ingredient
                    {
                        IngredientName = "Glycolic Acid",
                        Unit = "g",
                        CostPerUnit = 0.35m,
                        CurrentStock = 400,
                        MinimumStock = 40,
                        SupplierId = GetSupplierIdByName("Premium Skincare")
                    },
                    new Ingredient
                    {
                        IngredientName = "Peptides",
                        Unit = "g",
                        CostPerUnit = 5.00m,
                        CurrentStock = 150,
                        MinimumStock = 15,
                        SupplierId = GetSupplierIdByName("Luxury Cosmetics")
                    },
                    new Ingredient
                    {
                        IngredientName = "Ceramides",
                        Unit = "g",
                        CostPerUnit = 1.20m,
                        CurrentStock = 300,
                        MinimumStock = 30,
                        SupplierId = GetSupplierIdByName("Natural Beauty")
                    }
                };

                var ingredientIds = new List<string>();
                foreach (var ingredient in ingredients)
                {
                    var id = await CreateIngredientAsync(ingredient);
                    ingredientIds.Add(id);
                }

                // Create beauty products with supplier IDs
                var products = new List<Product>
                {
                    new Product
                    {
                        productName = "Hydrating Serum",
                        productDesc = "Intensive hydrating serum with hyaluronic acid for plump, moisturized skin",
                        productCategory = "Skincare",
                        baseIngredients = "Hyaluronic Acid, Glycerin, Water",
                        productVal = 29.99m,
                    },
                    new Product
                    {
                        productName = "Vitamin C Brightening Cream",
                        productDesc = "Brightening day cream with vitamin C to even skin tone and reduce dark spots",
                        productCategory = "Skincare",
                        baseIngredients = "Vitamin C, Niacinamide, Shea Butter",
                        productVal = 34.99m,
                    },
                    new Product
                    {
                        productName = "Anti-Aging Night Serum",
                        productDesc = "Powerful anti-aging serum with retinol and peptides for overnight skin renewal",
                        productCategory = "Skincare",
                        baseIngredients = "Retinol, Peptides, Ceramides",
                        productVal = 49.99m,
                    },
                    new Product
                    {
                        productName = "Acne Treatment Gel",
                        productDesc = "Targeted acne treatment gel with salicylic acid to clear blemishes",
                        productCategory = "Skincare",
                        baseIngredients = "Salicylic Acid, Niacinamide, Tea Tree Oil",
                        productVal = 19.99m,
                    },
                    new Product
                    {
                        productName = "Exfoliating Toner",
                        productDesc = "Gentle exfoliating toner with glycolic acid for smooth, radiant skin",
                        productCategory = "Skincare",
                        baseIngredients = "Glycolic Acid, Witch Hazel, Aloe Vera",
                        productVal = 24.99m,
                    },
                    new Product
                    {
                        productName = "Luxe Face Mask Set",
                        productDesc = "Premium face mask collection for deep cleansing and nourishment",
                        productCategory = "Skincare",
                        baseIngredients = "Clay, Hyaluronic Acid, Vitamin E",
                        productVal = 39.99m,
                    },
                    new Product
                    {
                        productName = "Matte Lipstick Collection",
                        productDesc = "Long-lasting matte lipsticks in 12 stunning shades",
                        productCategory = "Makeup",
                        baseIngredients = "Wax, Pigments, Vitamin E",
                        productVal = 18.99m,
                    },
                    new Product
                    {
                        productName = "Eyeshadow Palette - Sunset",
                        productDesc = "18-shade eyeshadow palette with warm sunset tones",
                        productCategory = "Makeup",
                        baseIngredients = "Mica, Talc, Pigments",
                        productVal = 42.99m,
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
                System.Diagnostics.Debug.WriteLine(string.Format("Seed data error: {0}", ex.Message));
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
            if (request == null) throw new ArgumentNullException("request");
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

        public async Task<StockRequest> GetStockRequestByIdAsync(string requestId)
        {
            if (string.IsNullOrWhiteSpace(requestId)) throw new ArgumentException("Request ID is required");

            var filter = Builders<StockRequest>.Filter.Eq(r => r.RequestID, requestId);
            return await _stockRequestsCollection.Find(filter).FirstOrDefaultAsync();
        }

        public async Task<bool> UpdateStockRequestAsync(StockRequest request)
        {
            if (request == null) throw new ArgumentNullException("request");
            if (string.IsNullOrWhiteSpace(request.RequestID)) throw new ArgumentException("RequestID is required");

            // Convert string RequestID to ObjectId for MongoDB filter
            ObjectId objectId;
            if (!ObjectId.TryParse(request.RequestID, out objectId))
                throw new ArgumentException("Invalid RequestID format (not a valid ObjectId)");

            var filter = Builders<StockRequest>.Filter.Eq("_id", objectId);
            var update = Builders<StockRequest>.Update
                .Set(r => r.RequestStatus, request.RequestStatus)
                .Set(r => r.UpdatedAt, DateTime.UtcNow);

            var result = await _stockRequestsCollection.UpdateOneAsync(filter, update);
            return result.ModifiedCount > 0;
        }

        public async Task<List<ProductIngredient>> GetProductIngredientsByProductIdAsync(string productId)
        {
            var filter = Builders<ProductIngredient>.Filter.Eq(pi => pi.ProductId, productId) &
                         Builders<ProductIngredient>.Filter.Eq(pi => pi.IsActive, true);
            return await _productIngredientsCollection.Find(filter).ToListAsync();
        }
    }
}