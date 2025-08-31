using System;
using System.Configuration;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.Helpers
{
    public static class DatabaseHelper
    {
        private static IMongoDatabase _database;
        
        public static IMongoDatabase Database
        {
            get
            {
                if (_database == null)
                {
                    var connectionString = ConfigurationManager.ConnectionStrings["MongoDBConnection"].ConnectionString;
                    var databaseName = ConfigurationManager.AppSettings["MongoDBDatabase"];
                    
                    var client = new MongoClient(connectionString);
                    _database = client.GetDatabase(databaseName);
                }
                return _database;
            }
        }
        
        public static IMongoCollection<T> GetCollection<T>(string collectionName)
        {
            return Database.GetCollection<T>(collectionName);
        }
        
        // Helper methods to get collection names from config
        public static string GetUsersCollectionName()
        {
            return ConfigurationManager.AppSettings["UsersCollection"];
        }
        
        public static string GetInventoryCollectionName()
        {
            return ConfigurationManager.AppSettings["InventoryCollection"];
        }

        public static string GetProductsCollectionName()
        {
            return ConfigurationManager.AppSettings["ProductsCollection"];
        }

        public static string GetIngredientsCollectionName()
        {
            return ConfigurationManager.AppSettings["IngredientsCollection"];
        }

        public static string GetProductIngredientsCollectionName()
        {
            return ConfigurationManager.AppSettings["ProductIngredientsCollection"];
        }

        public static string GetProductVariantsCollectionName()
        {
            return ConfigurationManager.AppSettings["ProductVariantsCollection"];
        }

        public static string GetVariantIngredientsCollectionName()
        {
            return ConfigurationManager.AppSettings["VariantIngredientsCollection"];
        }

        public static string GetSalesCollectionName()
        {
            return ConfigurationManager.AppSettings["SalesCollection"];
        }

        // Model-specific collection getters
        public static IMongoCollection<User> GetUsersCollection()
        {
            return GetCollection<User>(GetUsersCollectionName());
        }

        public static IMongoCollection<Inventory> GetInventoryCollection()
        {
            return GetCollection<Inventory>(GetInventoryCollectionName());
        }

        public static IMongoCollection<Product> GetProductsCollection()
        {
            return GetCollection<Product>(GetProductsCollectionName());
        }

        public static IMongoCollection<Ingredient> GetIngredientsCollection()
        {
            return GetCollection<Ingredient>(GetIngredientsCollectionName());
        }

        public static IMongoCollection<ProductIngredient> GetProductIngredientsCollection()
        {
            return GetCollection<ProductIngredient>(GetProductIngredientsCollectionName());
        }

        public static IMongoCollection<ProductVariant> GetProductVariantsCollection()
        {
            return GetCollection<ProductVariant>(GetProductVariantsCollectionName());
        }

        public static IMongoCollection<VariantIngredient> GetVariantIngredientsCollection()
        {
            return GetCollection<VariantIngredient>(GetVariantIngredientsCollectionName());
        }

        public static IMongoCollection<Sale> GetSalesCollection()
        {
            return GetCollection<Sale>(GetSalesCollectionName());
        }

        // Initialize collections and indexes
        public static void InitializeCollections()
        {
            try
            {
                // Create indexes for Users collection
                var usersCollection = Database.GetCollection<BsonDocument>(GetUsersCollectionName());
                var emailIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("email");
                var emailIndexOptions = new CreateIndexOptions { Unique = true };
                usersCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(emailIndexKeys, emailIndexOptions));

                var nameIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("name");
                usersCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(nameIndexKeys));

                // Create indexes for Inventory collection
                var inventoryCollection = Database.GetCollection<BsonDocument>(GetInventoryCollectionName());
                var itemNameIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("itemName");
                inventoryCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(itemNameIndexKeys));

                var categoryIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("category");
                inventoryCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(categoryIndexKeys));

                // Create indexes for Products collection
                var productsCollection = Database.GetCollection<BsonDocument>(GetProductsCollectionName());
                var productNameIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("productName");
                productsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(productNameIndexKeys));

                var productCategoryIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("productCategory");
                productsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(productCategoryIndexKeys));

                // Create indexes for Ingredients collection
                var ingredientsCollection = Database.GetCollection<BsonDocument>(GetIngredientsCollectionName());
                var ingredientNameIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("ingredientName");
                ingredientsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(ingredientNameIndexKeys));

                // Create indexes for ProductIngredients collection
                var productIngredientsCollection = Database.GetCollection<BsonDocument>(GetProductIngredientsCollectionName());
                var productIngredientIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("productId").Ascending("ingredientId");
                productIngredientsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(productIngredientIndexKeys));

                // Create indexes for ProductVariants collection
                var productVariantsCollection = Database.GetCollection<BsonDocument>(GetProductVariantsCollectionName());
                var skuIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("sku");
                var skuIndexOptions = new CreateIndexOptions { Unique = true };
                productVariantsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(skuIndexKeys, skuIndexOptions));

                var productIdIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("productId");
                productVariantsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(productIdIndexKeys));

                // Create indexes for VariantIngredients collection
                var variantIngredientsCollection = Database.GetCollection<BsonDocument>(GetVariantIngredientsCollectionName());
                var variantIngredientIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("variantId").Ascending("ingredientId");
                variantIngredientsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(variantIngredientIndexKeys));

                var variantIdIndexKeys2 = Builders<BsonDocument>.IndexKeys.Ascending("variantId");
                variantIngredientsCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(variantIdIndexKeys2));

                // Create indexes for Sales collection (ProductSales)
                var salesCollection = Database.GetCollection<BsonDocument>(GetSalesCollectionName());
                
                // Index on transaction date for reporting
                var transactionDateIndexKeys = Builders<BsonDocument>.IndexKeys.Descending("transactionDate");
                salesCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(transactionDateIndexKeys));

                // Index on variant ID for stock tracking
                var variantIdIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("variantId");
                salesCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(variantIdIndexKeys));

                // Index on stock decrement processed for batch processing
                var stockDecrementIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("stockDecrementProcessed").Ascending("isActive");
                salesCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(stockDecrementIndexKeys));

                // Compound index for active sales by variant
                var activeVariantSalesIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("variantId").Ascending("isActive").Descending("transactionDate");
                salesCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(activeVariantSalesIndexKeys));

                // Index on sold by for user performance tracking
                var soldByIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("soldBy");
                salesCollection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(soldByIndexKeys));
            }
            catch (Exception ex)
            {
                // Log error or handle initialization failure
                System.Diagnostics.Debug.WriteLine($"Database initialization error: {ex.Message}");
            }
        }
    }
}