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
        private static bool _salesIndexesEnsured = false;
        
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
            // Keep timeouts short so the app fails fast and falls back to local if Atlas is unreachable
            settings.ConnectTimeout = TimeSpan.FromSeconds(15);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(15);
            settings.SocketTimeout = TimeSpan.FromSeconds(20);
            settings.MaxConnectionPoolSize = 25;
            settings.MinConnectionPoolSize = 1;
            settings.ApplicationName = "InventorySystemSiaProject";
            
            // Configure SSL for Atlas
            settings.SslSettings = new SslSettings
            {
                EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                CheckCertificateRevocation = false
            };
            
            var client = new MongoClient(settings);
            var database = client.GetDatabase(databaseName);
            
            // Test connection with short timeout
            try
            {
                var timeout = TimeSpan.FromSeconds(6);
                var task = database.RunCommandAsync((Command<BsonDocument>)"{ping:1}");
                if (!task.Wait(timeout))
                {
                    throw new TimeoutException("Database ping timed out");
                }
                System.Diagnostics.Debug.WriteLine("Successfully connected to MongoDB Atlas");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Atlas ping failed: {ex.Message}");
                throw;
            }
            
            return database;
        }

        private static IMongoDatabase CreateLocalConnection(string databaseName)
        {
            var connectionString = ConfigurationManager.ConnectionStrings["MongoDBConnectionLocal"].ConnectionString;
            
            var settings = MongoClientSettings.FromConnectionString(connectionString);
            settings.ConnectTimeout = TimeSpan.FromSeconds(8);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(8);
            settings.SocketTimeout = TimeSpan.FromSeconds(12);
            settings.ApplicationName = "InventorySystemSiaProject-local";
            
            var client = new MongoClient(settings);
            var database = client.GetDatabase(databaseName);
            
            // Test connection fast
            var timeout = TimeSpan.FromSeconds(3);
            var task = database.RunCommandAsync((Command<BsonDocument>)"{ping:1}");
            if (!task.Wait(timeout))
            {
                throw new TimeoutException("Local MongoDB ping timed out");
            }
            System.Diagnostics.Debug.WriteLine("Successfully connected to local MongoDB");
            
            return database;
        }
        public static IMongoCollection<BsonDocument> GetActivityLogCollectionRaw()
        {
            return GetCollection<BsonDocument>(GetActivityLogCollectionName());
        }
        public static IMongoCollection<T> GetCollection<T>(string collectionName)
        {
            return Database.GetCollection<T>(collectionName);
        }
        
        // Helper methods to get collection names from config
        public static string GetUsersCollectionName() => ConfigurationManager.AppSettings["UsersCollection"];
        public static string GetTblUserCollectionName() => ConfigurationManager.AppSettings["TblUserCollection"] ?? "tbl_user";
        public static string GetInventoryCollectionName() => ConfigurationManager.AppSettings["InventoryCollection"];
        public static string GetProductsCollectionName() => ConfigurationManager.AppSettings["ProductsCollection"];
        public static string GetIngredientsCollectionName() => ConfigurationManager.AppSettings["IngredientsCollection"];
        public static string GetProductIngredientsCollectionName() => ConfigurationManager.AppSettings["ProductIngredientsCollection"];
        public static string GetProductVariantsCollectionName() => ConfigurationManager.AppSettings["ProductVariantsCollection"];
        public static string GetVariantIngredientsCollectionName() => ConfigurationManager.AppSettings["VariantIngredientsCollection"];
        public static string GetSalesCollectionName() => ConfigurationManager.AppSettings["SalesCollection"];
        // New: ProductSales collection (alternate sales storage)
        public static string GetProductSalesCollectionName() => ConfigurationManager.AppSettings["ProductSalesCollection"] ?? "ProductSales";
        public static string GetActivityLogCollectionName() => ConfigurationManager.AppSettings["ActivityLogCollection"] ?? "ActivityLog";
        public static string GetStockRequestsCollectionName() => ConfigurationManager.AppSettings["StockRequestsCollection"] ?? "StockRequests";
        public static string GetIngredientStockRequestsCollectionName() => ConfigurationManager.AppSettings["IngredientStockRequestsCollection"] ?? "IngredientStockRequests";
        public static string GetSuppliersCollectionName() => ConfigurationManager.AppSettings["SuppliersCollection"] ?? "Suppliers";
        public static string GetEmployeesCollectionName() => ConfigurationManager.AppSettings["EmployeesCollection"] ?? "Employees";

        // Model-specific collection getters
        public static IMongoCollection<User> GetUsersCollection() => GetCollection<User>(GetUsersCollectionName());
        public static IMongoCollection<Inventory> GetInventoryCollection() => GetCollection<Inventory>(GetInventoryCollectionName());
        public static IMongoCollection<Product> GetProductsCollection() => GetCollection<Product>(GetProductsCollectionName());
        public static IMongoCollection<Ingredient> GetIngredientsCollection() => GetCollection<Ingredient>(GetIngredientsCollectionName());
        public static IMongoCollection<ProductIngredient> GetProductIngredientsCollection() => GetCollection<ProductIngredient>(GetProductIngredientsCollectionName());
        public static IMongoCollection<ProductVariant> GetProductVariantsCollection() => GetCollection<ProductVariant>(GetProductVariantsCollectionName());
        public static IMongoCollection<VariantIngredient> GetVariantIngredientsCollection() => GetCollection<VariantIngredient>(GetVariantIngredientsCollectionName());
        public static IMongoCollection<Sale> GetSalesCollection() => GetCollection<Sale>(GetSalesCollectionName());
        public static IMongoCollection<Sale> GetProductSalesCollection() => GetCollection<Sale>(GetProductSalesCollectionName());
        public static IMongoCollection<ActivityLog> GetActivityLogCollection() => GetCollection<ActivityLog>(GetActivityLogCollectionName());
        public static IMongoCollection<InventorySystemSiaProject.Models.StockRequest> GetStockRequestsCollection() => GetCollection<InventorySystemSiaProject.Models.StockRequest>(GetStockRequestsCollectionName());
        public static IMongoCollection<InventorySystemSiaProject.Models.IngredientStockRequest> GetIngredientStockRequestsCollection() => GetCollection<InventorySystemSiaProject.Models.IngredientStockRequest>(GetIngredientStockRequestsCollectionName());
        public static IMongoCollection<Supplier> GetSuppliersCollection() => GetCollection<Supplier>(GetSuppliersCollectionName());
        
        // Get TblUser collection from db_essentials (primary) or fallback to db_shessentials/main DB
        public static IMongoCollection<TblUser> GetTblUserCollection()
        {
            // Preferred: db_essentials
            var essentialsDbName = ConfigurationManager.AppSettings["EssentialsDatabase"] ?? "db_essentials";
            var essentialsConn = ConfigurationManager.ConnectionStrings["EssentialsConnection"]?.ConnectionString;

            if (!string.IsNullOrEmpty(essentialsConn))
            {
                try
                {
                    var settings = MongoClientSettings.FromConnectionString(essentialsConn);
                    settings.ConnectTimeout = TimeSpan.FromSeconds(10);
                    settings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
                    settings.SocketTimeout = TimeSpan.FromSeconds(15);
                    settings.SslSettings = new SslSettings
                    {
                        EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                        CheckCertificateRevocation = false
                    };
                    var client = new MongoClient(settings);
                    var database = client.GetDatabase(essentialsDbName);
                    System.Diagnostics.Debug.WriteLine($"[DB] Using Essentials DB '{essentialsDbName}' for tbl_user");
                    return database.GetCollection<TblUser>(GetTblUserCollectionName());
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[DB] Essentials connection failed: {ex.Message}. Falling back...");
                }
            }

            // Fallback: db_shessentials if configured
            var sheEssentialsDbName = ConfigurationManager.AppSettings["SheEssentialsDatabase"] ?? "db_shessentials";
            var sheEssentialsConnectionString = ConfigurationManager.ConnectionStrings["SheEssentialsConnection"]?.ConnectionString;
            if (!string.IsNullOrEmpty(sheEssentialsConnectionString))
            {
                try
                {
                    var settings = MongoClientSettings.FromConnectionString(sheEssentialsConnectionString);
                    settings.ConnectTimeout = TimeSpan.FromSeconds(10);
                    settings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
                    settings.SocketTimeout = TimeSpan.FromSeconds(15);
                    settings.SslSettings = new SslSettings
                    {
                        EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                        CheckCertificateRevocation = false
                    };
                    var client = new MongoClient(settings);
                    var database = client.GetDatabase(sheEssentialsDbName);
                    System.Diagnostics.Debug.WriteLine($"[DB] Using SheEssentials DB '{sheEssentialsDbName}' for tbl_user");
                    return database.GetCollection<TblUser>(GetTblUserCollectionName());
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[DB] SheEssentials connection failed: {ex.Message}. Falling back to main DB...");
                }
            }

            // Final fallback: main DB
            System.Diagnostics.Debug.WriteLine("[DB] Falling back to main database for tbl_user.");
            return GetCollection<TblUser>(GetTblUserCollectionName());
        }
        
        // Get Employees collection from HumanResourcesDB (kept for backward compatibility)
        public static IMongoCollection<Employee> GetEmployeesCollection()
        {
            var hrDatabaseName = ConfigurationManager.AppSettings["HumanResourcesDatabase"] ?? "HumanResourcesDB";
            var hrConnectionString = ConfigurationManager.ConnectionStrings["HumanResourcesConnection"]?.ConnectionString;
            
            if (string.IsNullOrEmpty(hrConnectionString))
            {
                // Fallback to main connection if HumanResourcesConnection is not configured
                return GetCollection<Employee>(GetEmployeesCollectionName());
            }
            
            var settings = MongoClientSettings.FromConnectionString(hrConnectionString);
            settings.ConnectTimeout = TimeSpan.FromSeconds(10);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
            settings.SocketTimeout = TimeSpan.FromSeconds(15);
            settings.SslSettings = new SslSettings
            {
                EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                CheckCertificateRevocation = false
            };
            
            var client = new MongoClient(settings);
            var database = client.GetDatabase(hrDatabaseName);
            return database.GetCollection<Employee>(GetEmployeesCollectionName());
        }

        // Test database connection
        public static async Task<bool> TestConnectionAsync()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("?? TestConnectionAsync starting...");
                var command = new BsonDocument("ping", 1);
                var cts = new System.Threading.CancellationTokenSource(TimeSpan.FromSeconds(6));
                var result = await Database.RunCommandAsync((Command<BsonDocument>)command, cancellationToken: cts.Token).ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine("? Database ping successful");
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"? Database ping failed: {ex.Message}");
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
                if (!await TestConnectionAsync().ConfigureAwait(false))
                {
                    throw new Exception("Cannot establish connection to MongoDB");
                }

                // Create indexes for Users collection
                var usersCollection = Database.GetCollection<BsonDocument>(GetUsersCollectionName());
                try
                {
                    var emailIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("email");
                    var emailIndexOptions = new CreateIndexOptions { Unique = true };
                    await usersCollection.Indexes.CreateOneAsync(new CreateIndexModel<BsonDocument>(emailIndexKeys, emailIndexOptions)).ConfigureAwait(false);
                }
                catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
                {
                    // Index already exists, ignore
                }

                // Create other essential indexes only
                try
                {
                    var nameIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("name");
                    await usersCollection.Indexes.CreateOneAsync(new CreateIndexModel<BsonDocument>(nameIndexKeys)).ConfigureAwait(false);
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

        public static async Task EnsureSalesIndexesAsync()
        {
            if (_salesIndexesEnsured) return;
            try
            {
                var sales = GetSalesCollection();
                var productSales = GetProductSalesCollection();

                // compound index productId + transactionDate
                var keys = Builders<Sale>.IndexKeys.Ascending(s => s.ProductId).Ascending(s => s.TransactionDate);
                var model = new CreateIndexModel<Sale>(keys, new CreateIndexOptions { Name = "ix_product_date" });
                await sales.Indexes.CreateOneAsync(model).ConfigureAwait(false);
                await productSales.Indexes.CreateOneAsync(model).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("EnsureSalesIndexes failed: " + ex.Message);
            }
            finally
            {
                _salesIndexesEnsured = true;
            }
        }

        public static void EnsureSalesIndexes()
        {
            try { EnsureSalesIndexesAsync().GetAwaiter().GetResult(); } catch { }
        }
    }
}