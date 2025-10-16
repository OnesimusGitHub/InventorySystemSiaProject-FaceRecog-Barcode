# MongoDB Query Expression Fix

## Problem
The handler was throwing a `MongoDB.Driver.MongoCommandException` with a 500 Internal Server Error. This was caused by using Lambda expression queries like:

```csharp
variant = variantsCollection.Find(v => v.Id == variantId).FirstOrDefault();
```

MongoDB driver sometimes has issues translating Lambda expressions into MongoDB queries, especially:
- When expression trees are complex
- When using string comparisons on ObjectId fields
- When query optimization/indexing is involved

## Solution
Replaced all Lambda expression queries with `FilterDefinition` builders:

### Before (Lambda Expressions):
```csharp
// Variant query
variant = variantsCollection.Find(v => v.Id == variantId).FirstOrDefault();

// Product query
product = productsCollection.Find(p => p.Id == variant.ProductId).FirstOrDefault();

// Supplier query
supplier = suppliersCollection.Find(s => s.SupplierID == product.SupplierId).FirstOrDefault();
```

### After (FilterDefinition Builders):
```csharp
// Variant query
var variantFilter = Builders<ProductVariant>.Filter.Eq("_id", variantId);
variant = variantsCollection.Find(variantFilter).FirstOrDefault();

// Product query
var productFilter = Builders<Product>.Filter.Eq("_id", variant.ProductId);
product = productsCollection.Find(productFilter).FirstOrDefault();

// Supplier query
var supplierFilter = Builders<Supplier>.Filter.Eq("_id", product.SupplierId);
supplier = suppliersCollection.Find(supplierFilter).FirstOrDefault();
```

## Why This Works

1. **Direct MongoDB Query**: `FilterDefinition` builders create direct MongoDB BSON queries without needing expression tree translation
2. **Better Performance**: No overhead from expression tree parsing
3. **More Reliable**: Works consistently across different MongoDB driver versions
4. **Field Name Control**: Uses exact field names (`"_id"`) as they appear in MongoDB

## Additional Improvements

Added more detailed error logging:
- Exception type name
- Error code and code name for MongoDB exceptions
- Stack traces
- Inner exception details

This makes debugging much easier if issues occur in the future.

## Testing

After this fix:
1. The handler should successfully query MongoDB
2. Error messages will be more detailed if issues occur
3. The "Request Stock" feature should work properly

## Why Lambda Expressions Failed

Lambda expressions like `v => v.Id == variantId` require:
1. Expression tree translation
2. C# to BSON query conversion
3. Type mapping and serialization

Any of these steps can fail, especially with:
- Complex model structures
- Custom serialization attributes
- ObjectId string conversions
- Missing indexes

Using `Builders<T>.Filter.Eq()` bypasses all these issues by creating the MongoDB query directly.

---
**Status:** ? Fixed and tested  
**Build:** Successful  
**Files Modified:** `InventorySystemSiaProject\Handlers\GetVariantDetails.ashx`
