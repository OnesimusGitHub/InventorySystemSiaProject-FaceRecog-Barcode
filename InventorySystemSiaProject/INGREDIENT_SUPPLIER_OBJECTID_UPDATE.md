# Ingredient Supplier ObjectId Implementation

## Summary
Updated the Ingredients Management page to properly store and retrieve the Supplier reference using ObjectId (SupplierId) instead of storing the supplier name as a string.

## Changes Made

### 1. Model (Already Updated)
**File:** `Models/Ingredient.cs`
- Changed from `Supplier` (string) to `SupplierId` (ObjectId)
- Added `[BsonRepresentation(BsonType.ObjectId)]` attribute
- Added navigation property `Supplier` marked with `[BsonIgnore]` for displaying supplier details

### 2. Code-Behind Updates
**File:** `WebPages/IngredientsPage.aspx.cs`

#### Key Changes:

**LoadIngredientsDataAsync():**
```csharp
// Get all suppliers for display mapping
var suppliers = await _supplierService.GetAllSuppliersAsync();
var supplierDict = suppliers.ToDictionary(s => s.SupplierID, s => s.SupName);

// Populate supplier names for display
foreach (var ingredient in ingredients)
{
    if (!string.IsNullOrEmpty(ingredient.SupplierId) && supplierDict.ContainsKey(ingredient.SupplierId))
    {
        ingredient.Supplier = new Supplier { SupName = supplierDict[ingredient.SupplierId] };
    }
}
```

**LoadIngredientForEditAsync():**
```csharp
// Set supplier dropdown using SupplierId (ObjectId)
if (!string.IsNullOrEmpty(ingredient.SupplierId))
{
    var supplierItem = ddlSupplier.Items.FindByValue(ingredient.SupplierId);
    if (supplierItem != null)
    {
        ddlSupplier.SelectedValue = ingredient.SupplierId;
    }
}
```

**SaveIngredientAsync():**
```csharp
// Get supplier ID from dropdown (ObjectId, not the name)
string supplierId = ddlSupplier.SelectedValue;

var ingredient = new Ingredient
{
    // ... other properties
    SupplierId = !string.IsNullOrEmpty(supplierId) ? supplierId : null,
    // ...
};
```

### 3. View Updates
**File:** `WebPages/IngredientsPage.aspx`

Changed the Supplier column binding:
```aspx
<asp:TemplateField HeaderText="Supplier">
    <ItemTemplate>
        <%# Eval("Supplier.SupName") ?? "N/A" %>
    </ItemTemplate>
</asp:TemplateField>
```

## Benefits

1. **Data Integrity:** Proper relational reference using ObjectId ensures data consistency
2. **No Redundancy:** Supplier data is stored only once in the Suppliers collection
3. **Easier Updates:** If a supplier name changes, it automatically reflects everywhere
4. **Better Performance:** MongoDB can optimize queries with proper ObjectId references
5. **Referential Integrity:** Easy to implement cascading operations or validation

## How It Works

### Adding an Ingredient
1. User selects a supplier from the dropdown
2. The dropdown's `SelectedValue` contains the `SupplierId` (ObjectId)
3. The ingredient is saved with the `SupplierId` field
4. MongoDB stores this as a proper ObjectId reference

### Displaying Ingredients
1. Load all ingredients from the database
2. Load all active suppliers into a dictionary (SupplierId -> SupName)
3. For each ingredient, populate the `Supplier` navigation property with the supplier name
4. GridView displays the supplier name via `Supplier.SupName`

### Editing an Ingredient
1. Load the ingredient by ID
2. Use the `SupplierId` to select the correct supplier in the dropdown
3. When saving, update the `SupplierId` with the new selection

## Testing Checklist

- [ ] Add a new ingredient with a supplier selected
- [ ] Add a new ingredient without selecting a supplier (should work)
- [ ] Edit an existing ingredient and change the supplier
- [ ] Edit an existing ingredient and clear the supplier
- [ ] Verify supplier name displays correctly in the grid
- [ ] Verify the correct supplier is selected when editing
- [ ] Check that MongoDB stores the SupplierId as ObjectId type

## Database Schema

```javascript
// Ingredients Collection Document
{
    "_id": ObjectId("..."),
    "ingredientName": "Hyaluronic Acid",
    "unit": "ml",
    "costPerUnit": 0.15,
    "currentStock": 1000,
    "minimumStock": 100,
    "supplierId": ObjectId("..."), // Reference to Suppliers collection
    "createdAt": ISODate("..."),
    "updatedAt": ISODate("..."),
    "isActive": true
}
```

## Notes

- The `Supplier` navigation property is never saved to the database (marked with `[BsonIgnore]`)
- It's only populated at runtime for display purposes
- If a supplier is deleted or deactivated, you may want to add validation to prevent orphaned references
- Consider adding a foreign key constraint check when deleting suppliers

## Compatibility

- .NET Framework 4.8
- MongoDB Driver with BSON serialization support
- ASP.NET Web Forms with async/await support
