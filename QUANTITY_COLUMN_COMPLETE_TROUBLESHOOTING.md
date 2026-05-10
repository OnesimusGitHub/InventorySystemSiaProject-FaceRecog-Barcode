# Quantity Column - Troubleshooting & Complete Fix Guide

## Current Status: Quantity Column Still Empty ?

This guide will help you diagnose and fix the issue.

---

## Step 1: Run Diagnostics

### Option A: Using the Diagnostic Handler
```
URL: http://localhost/Handlers/DiagnoseEmployeeActivity.ashx
```
This will show:
- Total EmployeeActivity records
- How many have the `quantity` field
- How many are missing it
- Sample records structure

### Option B: Using MongoDB Compass
Connect to your MongoDB instance and run:
```javascript
db.EmployeeActivities.find({}).limit(5).pretty()
```

---

## Step 2: Apply the Fix

### Go to the Fix Page
```
URL: http://localhost/Admin/FixQuantityColumn.aspx
```

### What You'll See
- **?? Database Diagnosis** section showing current status
- **?? Fix Button** to apply the batch update
- Results showing how many records were fixed

### Click "Fix Missing Quantity Values"
The fix will:
1. Find all EmployeeActivity records where `quantity` field is missing or null
2. Set `quantity` to `0` for all matching records
3. Report how many records were updated

---

## Step 3: Verify the Fix

### Check Activity Log
1. Go to: `http://localhost/WebPages/ActivityLog.aspx`
2. Scroll to **"Employee Activities"** section
3. Check the **Quantity** column
4. Should now show numeric values

### Clear Browser Cache
If still empty after fix:
- Press **Ctrl+F5** (Windows) or **Cmd+Shift+R** (Mac)
- This clears the cache and refreshes the page

---

## Troubleshooting

### Problem: Page shows "Admin access required"
**Solution:** Make sure you're logged in as an Admin user

### Problem: Fix button shows error
**Solution:** Check the error message details:
- If it says "Could not connect to EmployeeActivities collection" - Database connection issue
- If it says "No records need fixing" - All records already have quantity field ?
- Other errors - Check the detailed error in the Results section

### Problem: Fix shows success but Quantity column still empty
**Solution:**
1. Refresh the page with **Ctrl+F5**
2. Check if you're on the same database
3. Run the diagnostic to verify the fix was applied
4. Check browser console (F12) for JavaScript errors

### Problem: MongoDB connection fails
**Solution:**
1. Verify MongoDB is running
2. Check connection string in Web.config
3. Make sure your MongoDB server is accessible
4. Check MongoDB credentials if authentication is required

---

## Manual MongoDB Fix (Advanced)

If the handler doesn't work, use MongoDB Compass or mongo shell:

### MongoDB Compass
```
Database: [Your DB Name]
Collection: EmployeeActivities
Operation: updateMany
```

Filter:
```javascript
{ $or: [
  { quantity: { $exists: false } },
  { quantity: null }
]}
```

Update:
```javascript
{ $set: { quantity: 0 } }
```

### Mongo Shell
```javascript
db.EmployeeActivities.updateMany(
  { $or: [
    { quantity: { $exists: false } },
    { quantity: null }
  ]},
  { $set: { quantity: 0 } }
)
```

---

## Understanding the Data Structure

### Before Fix
```json
{
  "_id": ObjectId("..."),
  "username": "John",
  "actionType": "AddProductStock",
  "itemType": "ProductVariant",
  "itemId": ObjectId("..."),
  "sku": "UHS-001",
  // ? quantity field is MISSING
  "details": "...",
  "createdAt": "2026-05-04T07:47:48Z"
}
```

### After Fix
```json
{
  "_id": ObjectId("..."),
  "username": "John",
  "actionType": "AddProductStock",
  "itemType": "ProductVariant",
  "itemId": ObjectId("..."),
  "sku": "UHS-001",
  "quantity": 0,  // ? Now present (set to 0 for old records)
  "details": "...",
  "createdAt": "2026-05-04T07:47:48Z"
}
```

---

## How GridView Binds the Quantity

### In ActivityLog.aspx.cs (Lines 212-221)
```csharp
int? quantity = null;
if (eaDoc.Contains("quantity"))
{
    var qv = eaDoc["quantity"];
    if (qv.IsInt32) quantity = qv.AsInt32;
    else if (qv.IsInt64) quantity = (int?)qv.AsInt64;
    else if (qv.IsDouble) quantity = (int?)Convert.ToInt32(qv.AsDouble);
    else if (qv.IsString && int.TryParse(qv.AsString, out int qparse)) 
        quantity = qparse;
}
```

**The Problem:** If `quantity` field doesn't exist, `quantity` remains `null`
**The Solution:** Add the `quantity` field to all records

---

## Files Involved

| File | Purpose |
|------|---------|
| `FixEmployeeActivityQuantity.ashx` | HTTP handler wrapper |
| `FixEmployeeActivityQuantity.ashx.cs` | Backend fix logic (UPDATED) |
| `FixQuantityColumn.aspx` | User interface (UPDATED) |
| `DiagnoseEmployeeActivity.ashx` | Diagnostic handler (NEW) |
| `DiagnoseEmployeeActivity.ashx.cs` | Diagnostic logic (NEW) |
| `ActivityLog.aspx.cs` | Retrieves quantity from MongoDB |

---

## Quick Checklist

- [ ] Go to `/Admin/FixQuantityColumn.aspx`
- [ ] Click "?? Fix Missing Quantity Values" button
- [ ] Wait for success message
- [ ] See "Records modified: X" in results
- [ ] Go to `/WebPages/ActivityLog.aspx`
- [ ] Refresh page with Ctrl+F5
- [ ] Check Quantity column - should show values now
- [ ] If still empty, run diagnostic and check results

---

## Debugging Commands

### Check what's in the database right now
```bash
# Using mongo shell
db.EmployeeActivities.find({ quantity: { $exists: false } }).count()
# Should return 0 after fix is applied
```

### Check database connection
```bash
# MongoDB Compass: Try to connect and browse the database
# Should see EmployeeActivities collection
```

### Check recent updates
```javascript
db.EmployeeActivities.find({}).sort({ createdAt: -1 }).limit(5)
// Should show recent records with quantity field
```

---

## Still Not Working?

1. **Take a screenshot** of the error message
2. **Check browser console** (F12 ? Console tab)
3. **Look at server logs** for detailed error information
4. **Run diagnostic handler** to see actual database state
5. **Verify MongoDB connection** is working properly
6. **Check that you're an admin** before accessing fix page

---

## Expected Results After Fix

? All Employee Activity records have a `quantity` field
? Quantity column in Activity Log displays numeric values
? Old records show `0`
? New records show actual quantities (once handlers are updated to include them)
? No more empty cells in the Quantity column

