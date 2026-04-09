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
        private static IMongoDatabase _sheEssentialsDatabase;
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
                            _database = CreateDatabaseConnection();
                    }
                }
                return _database;
            }
        }

        /// <summary>
        /// Returns the db_shessentials database (used for tbl_order sales data).
        /// </summary>
        public static IMongoDatabase SheEssentialsDatabase
        {
            get
            {
                if (_sheEssentialsDatabase == null)
                {
                    lock (_lock)
                    {
                        if (_sheEssentialsDatabase == null)
                            _sheEssentialsDatabase = CreateSheEssentialsConnection();
                    }
                }
                return _sheEssentialsDatabase;
            }
        }

        /// <summary>
        /// Gets the tbl_order collection from db_shessentials.
        /// </summary>
        public static IMongoCollection<BsonDocument> GetOrdersCollection()
        {
            return SheEssentialsDatabase.GetCollection<BsonDocument>("tbl_order");
        }

        private static IMongoDatabase CreateSheEssentialsConnection()
        {
            var dbName = ConfigurationManager.AppSettings["SheEssentialsDatabase"] ?? "db_shessentials";
            var connStr = ConfigurationManager.ConnectionStrings["SheEssentialsConnection"]?.ConnectionString;

            if (string.IsNullOrEmpty(connStr))
                throw new InvalidOperationException("SheEssentialsConnection is not configured in Web.config.");

            var settings = MongoClientSettings.FromConnectionString(connStr);
            settings.ConnectTimeout = TimeSpan.FromSeconds(15);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(15);
            settings.SocketTimeout = TimeSpan.FromSeconds(20);
            settings.MaxConnectionPoolSize = 25;
            settings.MinConnectionPoolSize = 1;
            settings.ApplicationName = "InventorySystemSiaProject-SheEssentials";
            settings.SslSettings = new SslSettings
            {
                EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                CheckCertificateRevocation = false
            };

            var client = new MongoClient(settings);
            var database = client.GetDatabase(dbName);

            var task = database.RunCommandAsync((Command<BsonDocument>)"{ping:1}");
            if (!task.Wait(TimeSpan.FromSeconds(6)))
                throw new TimeoutException("db_shessentials ping timed out");

            System.Diagnostics.Debug.WriteLine("[DB] Connected to db_shessentials");
            return database;
        }

        private static IMongoDatabase CreateDatabaseConnection()
        {
            var databaseName = ConfigurationManager.AppSettings["MongoDBDatabase"];
            var useLocal = bool.Parse(ConfigurationManager.AppSettings["UseLocalMongoDB"] ?? "false");

            if (!useLocal)
            {
                try
                {
                    return CreateAtlasConnection(databaseName);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Atlas connection failed: " + ex.Message);
                    System.Diagnostics.Debug.WriteLine("Attempting fallback to local MongoDB...");
                    try
                    {
                        return CreateLocalConnection(databaseName);
                    }
                    catch (Exception localEx)
                    {
                        throw new Exception("Failed to connect to both Atlas and local MongoDB. Atlas: " + ex.Message + ", Local: " + localEx.Message);
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
            settings.ConnectTimeout = TimeSpan.FromSeconds(15);
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(15);
            settings.SocketTimeout = TimeSpan.FromSeconds(20);
            settings.MaxConnectionPoolSize = 25;
            settings.MinConnectionPoolSize = 1;
            settings.ApplicationName = "InventorySystemSiaProject";
            settings.SslSettings = new SslSettings
            {
                EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                CheckCertificateRevocation = false
            };

            var client = new MongoClient(settings);
            var database = client.GetDatabase(databaseName);

            try
            {
                var task = database.RunCommandAsync((Command<BsonDocument>)"{ping:1}");
                if (!task.Wait(TimeSpan.FromSeconds(6)))
                    throw new TimeoutException("Database ping timed out");
                System.Diagnostics.Debug.WriteLine("Successfully connected to MongoDB Atlas");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Atlas ping failed: " + ex.Message);
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

            var task = database.RunCommandAsync((Command<BsonDocument>)"{ping:1}");
            if (!task.Wait(TimeSpan.FromSeconds(3)))
                throw new TimeoutException("Local MongoDB ping timed out");

            System.Diagnostics.Debug.WriteLine("Successfully connected to local MongoDB");
            return database;
        }

        public static IMongoCollection<BsonDocument> GetActivityLogCollectionRaw()
            => GetCollection<BsonDocument>(GetActivityLogCollectionName());

        public static IMongoCollection<T> GetCollection<T>(string collectionName)
            => Database.GetCollection<T>(collectionName);

        // Collection name helpers
        public static string GetUsersCollectionName() => ConfigurationManager.AppSettings["UsersCollection"];
        public static string GetTblUserCollectionName() => ConfigurationManager.AppSettings["TblUserCollection"] ?? "tbl_user";
        public static string GetInventoryCollectionName() => ConfigurationManager.AppSettings["InventoryCollection"];
        public static string GetProductsCollectionName() => ConfigurationManager.AppSettings["ProductsCollection"];
        public static string GetIngredientsCollectionName() => ConfigurationManager.AppSettings["IngredientsCollection"];
        public static string GetProductIngredientsCollectionName() => ConfigurationManager.AppSettings["ProductIngredientsCollection"];
        public static string GetProductVariantsCollectionName() => ConfigurationManager.AppSettings["ProductVariantsCollection"];
        public static string GetVariantIngredientsCollectionName() => ConfigurationManager.AppSettings["VariantIngredientsCollection"];
        public static string GetSalesCollectionName() => ConfigurationManager.AppSettings["SalesCollection"];
        public static string GetProductSalesCollectionName() => ConfigurationManager.AppSettings["ProductSalesCollection"] ?? "ProductSales";
        public static string GetActivityLogCollectionName() => ConfigurationManager.AppSettings["ActivityLogCollection"] ?? "ActivityLog";
        public static string GetStockRequestsCollectionName() => ConfigurationManager.AppSettings["StockRequestsCollection"] ?? "StockRequests";
        public static string GetIngredientStockRequestsCollectionName() => ConfigurationManager.AppSettings["IngredientStockRequestsCollection"] ?? "IngredientStockRequests";
        public static string GetSuppliersCollectionName() => ConfigurationManager.AppSettings["SuppliersCollection"] ?? "Suppliers";
        public static string GetEmployeesCollectionName() => ConfigurationManager.AppSettings["EmployeesCollection"] ?? "Employees";
        public static string GetEquipmentCollectionName() => ConfigurationManager.AppSettings["EquipmentCollection"] ?? "Equipment";
        public static string GetEquipmentStockRequestsCollectionName() => ConfigurationManager.AppSettings["EquipmentStockRequestsCollection"] ?? "EquipmentStockRequests";

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

        public static IMongoCollection<EquipmentStockRequest> GetEquipmentStockRequestsCollection()
        {
            // use the existing Database property
            return Database.GetCollection<EquipmentStockRequest>("EquipmentStockRequests");
        }
        public static IMongoCollection<TblUser> GetTblUserCollection()
        {
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
                    System.Diagnostics.Debug.WriteLine("[DB] Using Essentials DB '" + essentialsDbName + "' for tbl_user");
                    return client.GetDatabase(essentialsDbName).GetCollection<TblUser>(GetTblUserCollectionName());
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[DB] Essentials connection failed: " + ex.Message + ". Falling back...");
                }
            }

            var sheEssentialsDbName = ConfigurationManager.AppSettings["SheEssentialsDatabase"] ?? "db_shessentials";
            var sheEssentialsConn = ConfigurationManager.ConnectionStrings["SheEssentialsConnection"]?.ConnectionString;

            if (!string.IsNullOrEmpty(sheEssentialsConn))
            {
                try
                {
                    var settings = MongoClientSettings.FromConnectionString(sheEssentialsConn);
                    settings.ConnectTimeout = TimeSpan.FromSeconds(10);
                    settings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
                    settings.SocketTimeout = TimeSpan.FromSeconds(15);
                    settings.SslSettings = new SslSettings
                    {
                        EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12,
                        CheckCertificateRevocation = false
                    };
                    var client = new MongoClient(settings);
                    System.Diagnostics.Debug.WriteLine("[DB] Using SheEssentials DB '" + sheEssentialsDbName + "' for tbl_user");
                    return client.GetDatabase(sheEssentialsDbName).GetCollection<TblUser>(GetTblUserCollectionName());
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("[DB] SheEssentials connection failed: " + ex.Message + ". Falling back to main DB...");
                }
            }

            System.Diagnostics.Debug.WriteLine("[DB] Falling back to main database for tbl_user.");
            return GetCollection<TblUser>(GetTblUserCollectionName());
        }

        public static IMongoCollection<Employee> GetEmployeesCollection()
        {
            var hrDatabaseName = ConfigurationManager.AppSettings["HumanResourcesDatabase"] ?? "HumanResourcesDB";
            var hrConnectionString = ConfigurationManager.ConnectionStrings["HumanResourcesConnection"]?.ConnectionString;

            if (string.IsNullOrEmpty(hrConnectionString))
                return GetCollection<Employee>(GetEmployeesCollectionName());

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
            return client.GetDatabase(hrDatabaseName).GetCollection<Employee>(GetEmployeesCollectionName());
        }

        public static async Task<bool> TestConnectionAsync()
        {
            try
            {
                var command = new BsonDocument("ping", 1);
                var cts = new System.Threading.CancellationTokenSource(TimeSpan.FromSeconds(6));
                await Database.RunCommandAsync((Command<BsonDocument>)command, cancellationToken: cts.Token).ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine("Database ping successful");
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Database ping failed: " + ex.Message);
                return false;
            }
        }

        public static async Task InitializeCollectionsAsync()
        {
            if (_initialized) return;

            try
            {
                if (!await TestConnectionAsync().ConfigureAwait(false))
                    throw new Exception("Cannot establish connection to MongoDB");

                var usersCollection = Database.GetCollection<BsonDocument>(GetUsersCollectionName());

                try
                {
                    var emailIndexKeys = Builders<BsonDocument>.IndexKeys.Ascending("email");
                    await usersCollection.Indexes.CreateOneAsync(
                        new CreateIndexModel<BsonDocument>(emailIndexKeys, new CreateIndexOptions { Unique = true }))
                        .ConfigureAwait(false);
                }
                catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey) { }

                try
                {
                    await usersCollection.Indexes.CreateOneAsync(
                        new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("name")))
                        .ConfigureAwait(false);
                }
                catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey) { }

                _initialized = true;
                System.Diagnostics.Debug.WriteLine("Database initialization completed successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Database initialization error: " + ex.Message);
                throw;
            }
        }

        public static void InitializeCollections()
        {
            try { InitializeCollectionsAsync().GetAwaiter().GetResult(); }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine("Database initialization error: " + ex.Message); }
        }

        public static void UseLocalMongoDB()
        {
            _database = null;
            ConfigurationManager.AppSettings["UseLocalMongoDB"] = "true";
        }

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