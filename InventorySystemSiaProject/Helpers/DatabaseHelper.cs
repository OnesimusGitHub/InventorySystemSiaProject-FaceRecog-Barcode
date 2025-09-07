using System;
using System.Configuration;
using MongoDB.Driver;
using MongoDB.Bson;
using InventorySystemSiaProject.Models;
using System.Threading.Tasks;

namespace InventorySystemSiaProject.Helpers
{
    public static class DatabaseHelper
    {
        private static IMongoDatabase _database;
        private static readonly object _lock = new object();
        private static bool _initialized = false;
        
        public static IMongoDatabase Database
        {
            get
            {
                if (_database == null)
                {
                    lock (_lock)
                    {
                        if (_database == null)
                        {
                            _database = CreateDatabaseConnection();
                        }
                    }
                }
                return _database;
            }
        }

        private static IMongoDatabase CreateDatabaseConnection()
        {
            var databaseName = ConfigurationManager.AppSettings["MongoDBDatabase"];
            var useLocal = bool.Parse(ConfigurationManager.AppSettings["UseLocalMongoDB"] ?? "false");

            // Try Atlas connection first, then fallback to local if needed
            if (!useLocal)
            {
                try
                {
                    return CreateAtlasConnection(databaseName);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Atlas connection failed: {ex.Message}");
                    System.Diagnostics.Debug.WriteLine("Attempting fallback to local MongoDB...");
                    
                    try
                    {
                        return CreateLocalConnection(databaseName);
                    }
                    catch (Exception localEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"Local connection also failed: {localEx.Message}");
                        throw new Exception($"Failed to connect to both Atlas and local MongoDB. Atlas: {ex.Message}, Local: {localEx.Message}");
                    }
                }
            }
            else
            {
                return CreateLocalConnection(databaseName);
            }
        }

        private static IMongoDatabase CreateAtlasConnection(string databaseName)
        {
            var connectionString = ConfigurationManager.ConnectionStrings["MongoDBConnection"].ConnectionString;
            
            var settings = MongoClientSettings.FromConnectionString(connectionString);
            settings.ConnectTimeout = TimeSpan.FromSeconds(5);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(5);
            settings.SocketTimeout = TimeSpan.FromSeconds(5);
            settings.MaxConnectionPoolSize = 25;
            settings.MinConnectionPoolSize = 1;
            
            // Configure SSL for Atlas
            settings.SslSettings = new SslSettings
            {
                EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                CheckCertificateRevocation = false
            };
            
            var client = new MongoClient(settings);
            var database = client.GetDatabase(databaseName);
            
            // Test connection
            database.ListCollectionNames().ToList();
            System.Diagnostics.Debug.WriteLine("Successfully connected to MongoDB Atlas");
            
            return database;
        }

        private static IMongoDatabase CreateLocalConnection(string databaseName)
        {
            var connectionString = ConfigurationManager.ConnectionStrings["MongoDBConnectionLocal"].ConnectionString;
            
            var settings = MongoClientSettings.FromConnectionString(connectionString);
            settings.ConnectTimeout = TimeSpan.FromSeconds(5);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(5);
            settings.SocketTimeout = TimeSpan.FromSeconds(5);
            
            var client = new MongoClient(settings);
            var database = client.GetDatabase(databaseName);
            
            // Test connection
            database.ListCollectionNames().ToList();
            System.Diagnostics.Debug.WriteLine("Successfully connected to local MongoDB");
            
            return database;
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

        // Test database connection
        public static async Task<bool> TestConnectionAsync()
        {
            try
            {
                var collections = await Database.ListCollectionNamesAsync();
                await collections.ToListAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        // Initialize collections and indexes - called only when needed
        public static async Task InitializeCollectionsAsync()
        {
            if (_initialized) return;
            
            try
            {
                // Test connection first
                if (!await TestConnectionAsync())
                {
                    throw new Exception("Cannot establish connection to MongoDB");
                }

                // Create indexes for Users collection
                var usersCollection = Database.GetCollection<BsonDocument>(GetUsersCollectionName());
                try
                {
                    var emailIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("email");
                    var emailIndexOptions = new CreateIndexOptions { Unique = true };
                    await usersCollection.Indexes.CreateOneAsync(new CreateIndexModel<BsonDocument>(emailIndexKeys, emailIndexOptions));
                }
                catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
                {
                    // Index already exists, ignore
                }

                // Create other essential indexes only
                try
                {
                    var nameIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("name");
                    await usersCollection.Indexes.CreateOneAsync(new CreateIndexModel<BsonDocument>(nameIndexKeys));
                }
                catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
                {
                    // Index already exists, ignore
                }

                _initialized = true;
                System.Diagnostics.Debug.WriteLine("Database initialization completed successfully");
            }
            catch (Exception ex)
            {
                // Log error or handle initialization failure
                System.Diagnostics.Debug.WriteLine($"Database initialization error: {ex.Message}");
                throw;
            }
        }

        // Synchronous version for backward compatibility
        public static void InitializeCollections()
        {
            try
            {
                InitializeCollectionsAsync().GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Database initialization error: {ex.Message}");
            }
        }

        // Force use of local MongoDB for testing
        public static void UseLocalMongoDB()
        {
            _database = null;
            ConfigurationManager.AppSettings["UseLocalMongoDB"] = "true";
        }

        // Reset to use Atlas MongoDB
        public static void UseAtlasMongoDB()
        {
            _database = null;
            ConfigurationManager.AppSettings["UseLocalMongoDB"] = "false";
        }
    }
}