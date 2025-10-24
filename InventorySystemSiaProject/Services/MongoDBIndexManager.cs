using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;
using System;
using System.Threading.Tasks;

namespace InventorySystemSiaProject.Services
{
    public static class MongoDBIndexManager
    {
        public static void EnsureCategoryIndexes()
        {
            try
            {
                var products = DatabaseHelper.GetProductsCollection();
                var variants = DatabaseHelper.GetProductVariantsCollection();
                var sales = DatabaseHelper.GetSalesCollection();
                // ProductCategory index
                try
                {
                    products.Indexes.CreateOne(new CreateIndexModel<Product>(
                        Builders<Product>.IndexKeys.Ascending(p => p.ProductCategory),
                        new CreateIndexOptions { Name = "idx_product_category", Background = true }
                    ));
                }
                catch (MongoDB.Driver.MongoCommandException ex) when (ex.Message.Contains("Index already exists"))
                {
                    System.Diagnostics.Debug.WriteLine($"ProductCategory index already exists. Skipping creation.");
                }
                // ProductId index
                try
                {
                    variants.Indexes.CreateOne(new CreateIndexModel<ProductVariant>(
                        Builders<ProductVariant>.IndexKeys.Ascending(v => v.ProductId),
                        new CreateIndexOptions { Name = "idx_variant_productId", Background = true }
                    ));
                }
                catch (MongoDB.Driver.MongoCommandException ex) when (ex.Message.Contains("Index already exists"))
                {
                    System.Diagnostics.Debug.WriteLine($"ProductId index already exists. Skipping creation.");
                }
                // VariantId index
                try
                {
                    sales.Indexes.CreateOne(new CreateIndexModel<Sale>(
                        Builders<Sale>.IndexKeys.Ascending(s => s.VariantId),
                        new CreateIndexOptions { Name = "idx_sale_variantId", Background = true }
                    ));
                }
                catch (MongoDB.Driver.MongoCommandException ex) when (ex.Message.Contains("Index already exists"))
                {
                    System.Diagnostics.Debug.WriteLine($"VariantId index already exists. Skipping creation.");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Index creation error: {ex.Message}");
            }
        }

        // Stub for async index creation
        public static Task CreateAllIndexesAsync()
        {
            EnsureCategoryIndexes();
            return Task.CompletedTask;
        }

        // Stub for dropping custom indexes
        public static Task DropAllCustomIndexesAsync()
        {
            // No-op stub
            return Task.CompletedTask;
        }

        // Stub for listing indexes
        public static Task ListIndexesAsync(string collectionName)
        {
            // No-op stub
            return Task.CompletedTask;
        }
    }
}
