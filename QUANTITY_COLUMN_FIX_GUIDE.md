# Fix for Missing Quantity Values in Employee Activities

## Problem
The **Quantity column** in the **Employee Activities table** on the Activity Log page shows empty values, even though:
- The column header is visible
- The code is correctly configured to display it
- The model has the `Quantity` property

## Root Cause
Existing `EmployeeActivity` records in MongoDB **do not have the `quantity` field** populated when they were initially created. This happens because:
1. The handlers that create `EmployeeActivity` records may not be setting the `Quantity` property
2. Older records were created before the `Quantity` field was added to the model
3. The field is nullable and MongoDB allows documents without it

## Solutions

### Immediate Fix (For Existing Records)
1. **Go to**: `http://your-app/Admin/FixQuantityColumn.aspx`
2. **Click**: "?? Fix Missing Quantity Values" button
3. **What it does**: 
   - Finds all `EmployeeActivity` records where `quantity` is missing or null
   - Sets their `quantity` to `0`
   - Updates the records in MongoDB
   - Shows you how many records were fixed

### Permanent Fix (For Future Records)
You need to find where `EmployeeActivity` records are being created and **ensure the `Quantity` property is always set**.

#### Where to Look
Search your codebase for:
- "new EmployeeActivity"
- "ManualProductAdjustment"
- Stock adjustment handlers (`.ashx` files)
- Product variance handlers

#### What to Fix
Make sure every `EmployeeActivity` creation looks like this:

```csharp
// ? CORRECT - Includes Quantity
var employeeActivity = new EmployeeActivity
{
    Username = currentUser,
    EmployeeId = employeeId,
    ActionType = "AddProductStock",  // or "UpdateStock", "RemoveStock", etc.
    ItemType = "ProductVariant",
    ItemId = variantId,
    SKU = productSku,
    Quantity = quantityChanged,  // ? ALWAYS SET THIS
    Details = JsonConvert.SerializeObject(details),
    CreatedAt = DateTime.UtcNow
};

await employeeActivitiesCollection.InsertOneAsync(employeeActivity);
```

Not like this:
```csharp
// ? WRONG - Missing Quantity
var employeeActivity = new EmployeeActivity
{
    Username = currentUser,
    ActionType = "AddProductStock",
    ItemId = variantId,
    // ? Quantity is not set!
    Details = JsonConvert.SerializeObject(details),
    CreatedAt = DateTime.UtcNow
};
```

### Example Handlers to Check
Look in: `InventorySystemSiaProject/Handlers/` for files like:
- `AddProductVariant.ashx`
- `UpdateVariant.ashx`
- `DeleteVariant.ashx`
- `ArchiveProductVariant.ashx`
- Any stock adjustment handlers

Search for: `new EmployeeActivity` and add `Quantity = ` parameter

## Verification

### Step 1: Apply the Fix
Visit the fix page and run the batch update to set all missing quantities to 0.

### Step 2: Check Activity Log
1. Go to: `~/WebPages/ActivityLog.aspx`
2. Look at the **Employee Activities** table
3. The **Quantity column** should now show values (0 for old records, actual values for new records)

### Step 3: Monitor New Records
Going forward, all new `EmployeeActivity` records will have the `quantity` field populated automatically (as long as you've fixed the creation code).

## Code Changes Made

### Files Created:
1. **`/Handlers/FixEmployeeActivityQuantity.ashx`** - HTTP handler wrapper
2. **`/Handlers/FixEmployeeActivityQuantity.ashx.cs`** - Backend logic to fix missing quantities
3. **`/Admin/FixQuantityColumn.aspx`** - User-friendly page to run the fix

### What the Fix Does:
```csharp
// Finds all records where quantity is missing or null
var filter = Builders<BsonDocument>.Filter.Or(
    Builders<BsonDocument>.Filter.Not(Builders<BsonDocument>.Filter.Exists("quantity")),
    Builders<BsonDocument>.Filter.Eq("quantity", BsonNull.Value)
);

// Sets quantity to 0 for all matching records
var update = Builders<BsonDocument>.Update.Set("quantity", 0);
await collection.UpdateManyAsync(filter, update);
```

## MongoDB Query (Manual Fix)
If you want to run the fix directly in MongoDB Compass or mongo shell:

```javascript
// Fix missing quantity fields
db.EmployeeActivities.updateMany(
  { $or: [
    { quantity: { $exists: false } },
    { quantity: null }
  ]},
  { $set: { quantity: 0 } }
)
```

## Expected Results
- ? All existing EmployeeActivity records will have a `quantity` field
- ? Quantity column in Activity Log will display properly
- ? Old records show `0`, new records show actual quantities
- ? Future records automatically include quantity values

## Troubleshooting

### Still Showing Empty After Fix?
1. **Clear browser cache** (Ctrl+F5 / Cmd+Shift+R)
2. **Refresh the database connection** in your application
3. **Verify the fix ran successfully** - check that FixQuantityColumn.ashx returned success
4. **Check MongoDB directly** using MongoDB Compass to see if the field was added

### The Fix Page Shows Error?
1. Make sure you're logged in as an **Admin**
2. Check the browser console (F12) for JavaScript errors
3. Check the server logs for exceptions
4. Verify MongoDB connection is working

## Questions?
Look at the ActivityLog.aspx.cs file to see how it retrieves and displays the Quantity:
- Line 212-221: Quantity extraction logic
- Line 197: GridView column binding

