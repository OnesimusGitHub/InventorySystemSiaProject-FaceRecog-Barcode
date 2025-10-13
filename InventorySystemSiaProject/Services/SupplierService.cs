using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Services
{
    public class SupplierService
    {
        private readonly IMongoCollection<Supplier> _suppliersCollection;

        public SupplierService()
        {
            _suppliersCollection = DatabaseHelper.GetSuppliersCollection();
        }

        /// <summary>
        /// Seeds the Suppliers collection with sample beauty product suppliers
        /// </summary>
        public async Task SeedSuppliersAsync()
        {
            try
            {
                // Check if suppliers already exist
                var existingCount = await _suppliersCollection.CountDocumentsAsync(FilterDefinition<Supplier>.Empty);
                if (existingCount > 0)
                {
                    System.Diagnostics.Debug.WriteLine($"Suppliers collection already contains {existingCount} suppliers. Skipping seed.");
                    return;
                }

                var suppliers = new List<Supplier>
                {
                    new Supplier
                    {
                        SupName = "Beauty Essentials Inc.",
                        SupContactPer = "Maria Santos",
                        SupAddress = "123 Makati Ave, Makati City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8123-4567",
                        SupEmail = "maria.santos@beautyessentials.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Glow Cosmetics Supply",
                        SupContactPer = "Juan Dela Cruz",
                        SupAddress = "456 BGC Drive, Taguig City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8234-5678",
                        SupEmail = "juan.delacruz@glowcosmetics.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Premium Skincare Distributors",
                        SupContactPer = "Ana Reyes",
                        SupAddress = "789 Ortigas Center, Pasig City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8345-6789",
                        SupEmail = "ana.reyes@premiumskincare.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Natural Beauty Products Co.",
                        SupContactPer = "Pedro Garcia",
                        SupAddress = "321 Quezon Ave, Quezon City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8456-7890",
                        SupEmail = "pedro.garcia@naturalbeauty.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Luxury Cosmetics International",
                        SupContactPer = "Sofia Lim",
                        SupAddress = "555 Ayala Avenue, Makati City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8567-8901",
                        SupEmail = "sofia.lim@luxurycosmetics.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Korean Beauty Hub",
                        SupContactPer = "Kim Min-ji",
                        SupAddress = "888 Korea Town, Makati City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8678-9012",
                        SupEmail = "minji.kim@kbeautyhub.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Organic Skincare Solutions",
                        SupContactPer = "Carlos Fernandez",
                        SupAddress = "999 Greenhills, San Juan City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8789-0123",
                        SupEmail = "carlos.fernandez@organicskincare.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Professional Makeup Supplies",
                        SupContactPer = "Isabella Torres",
                        SupAddress = "777 Shaw Blvd, Mandaluyong City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8890-1234",
                        SupEmail = "isabella.torres@promakeup.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Fragrance World Distributors",
                        SupContactPer = "Miguel Santos",
                        SupAddress = "101 Alabang Town Center, Muntinlupa City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8901-2345",
                        SupEmail = "miguel.santos@fragranceworld.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    },
                    new Supplier
                    {
                        SupName = "Haircare Essentials Plus",
                        SupContactPer = "Gabriela Aquino",
                        SupAddress = "202 Commonwealth Ave, Quezon City, Metro Manila, Philippines",
                        SupContactNo = "+63 2 8012-3456",
                        SupEmail = "gabriela.aquino@haircareplus.ph",
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true
                    }
                };

                // Prepare all suppliers for insertion
                foreach (var supplier in suppliers)
                {
                    supplier.PrepareForInsertion();
                }

                // Insert all suppliers
                await _suppliersCollection.InsertManyAsync(suppliers);

                System.Diagnostics.Debug.WriteLine($"Successfully seeded {suppliers.Count} suppliers into the database.");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error seeding suppliers: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Gets all active suppliers
        /// </summary>
        public async Task<List<Supplier>> GetAllSuppliersAsync()
        {
            try
            {
                var filter = Builders<Supplier>.Filter.Eq(s => s.IsActive, true);
                return await _suppliersCollection.Find(filter).ToListAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting suppliers: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Gets a supplier by ID
        /// </summary>
        public async Task<Supplier> GetSupplierByIdAsync(string supplierId)
        {
            try
            {
                var filter = Builders<Supplier>.Filter.Eq(s => s.SupplierID, supplierId);
                return await _suppliersCollection.Find(filter).FirstOrDefaultAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting supplier by ID: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Creates a new supplier
        /// </summary>
        public async Task<string> CreateSupplierAsync(Supplier supplier)
        {
            try
            {
                if (!supplier.IsValid())
                {
                    throw new ArgumentException("Supplier data is invalid. Name and Contact Number are required.");
                }

                if (!string.IsNullOrWhiteSpace(supplier.SupEmail) && !supplier.IsValidEmail())
                {
                    throw new ArgumentException("Invalid email format.");
                }

                supplier.PrepareForInsertion();
                await _suppliersCollection.InsertOneAsync(supplier);
                
                return supplier.SupplierID;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error creating supplier: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Updates an existing supplier
        /// </summary>
        public async Task<bool> UpdateSupplierAsync(string supplierId, Supplier supplier)
        {
            try
            {
                if (!supplier.IsValid())
                {
                    throw new ArgumentException("Supplier data is invalid. Name and Contact Number are required.");
                }

                if (!string.IsNullOrWhiteSpace(supplier.SupEmail) && !supplier.IsValidEmail())
                {
                    throw new ArgumentException("Invalid email format.");
                }

                supplier.PrepareForUpdate();
                supplier.SupplierID = supplierId;

                var filter = Builders<Supplier>.Filter.Eq(s => s.SupplierID, supplierId);
                var result = await _suppliersCollection.ReplaceOneAsync(filter, supplier);

                return result.ModifiedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error updating supplier: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Soft deletes a supplier (sets IsActive to false)
        /// </summary>
        public async Task<bool> DeleteSupplierAsync(string supplierId)
        {
            try
            {
                var filter = Builders<Supplier>.Filter.Eq(s => s.SupplierID, supplierId);
                var update = Builders<Supplier>.Update
                    .Set(s => s.IsActive, false)
                    .Set(s => s.UpdatedAt, DateTime.UtcNow);

                var result = await _suppliersCollection.UpdateOneAsync(filter, update);
                return result.ModifiedCount > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error deleting supplier: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// Gets supplier count
        /// </summary>
        public async Task<long> GetSupplierCountAsync()
        {
            try
            {
                var filter = Builders<Supplier>.Filter.Eq(s => s.IsActive, true);
                return await _suppliersCollection.CountDocumentsAsync(filter);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting supplier count: {ex.Message}");
                throw;
            }
        }
    }
}
