# StockRequest Model Documentation

## Overview
Created a dedicated, professional `StockRequest.cs` model for managing stock replenishment requests from suppliers.

## File Location
- **Path**: `InventorySystemSiaProject\Models\StockRequest.cs`
- **Namespace**: `InventorySystemSiaProject.Models`

## Model Structure

### Core Fields

#### Identifiers
- **RequestID** (string, ObjectId) - Unique auto-generated identifier
- **ProductVariantID** (string, ObjectId) - Foreign key to ProductVariants collection
- **ProductID** (string, ObjectId) - Foreign key to Products collection (denormalized)
- **SupplierID** (string, ObjectId) - Foreign key to Suppliers collection

#### Request Details
- **QuantityRequested** (int) - Quantity requested for stock replenishment
- **RequestDate** (DateTime) - Date when the request was made
- **RequestedBy** (string) - Name of the employee/staff making the request
- **RequestedByUserId** (string, ObjectId) - User ID of the employee

#### Status Management
- **RequestStatus** (string) - Current status: `Pending`, `Approved`, `Rejected`, `Completed`
- **StatusUpdatedDate** (DateTime?) - Date when the request status was last updated
- **ProcessedBy** (string) - User who approved/rejected the request
- **ProcessedByUserId** (string, ObjectId) - User ID who processed the request

#### Additional Information
- **Instructions** (string) - Additional notes or special requirements
- **RejectionReason** (string) - Reason for rejection (if status is Rejected)
- **Priority** (string) - Priority level: `Low`, `Normal`, `High`, `Urgent`

#### Delivery Tracking
- **ExpectedDeliveryDate** (DateTime?) - Expected delivery date (optional)
- **ActualDeliveryDate** (DateTime?) - Actual delivery date (set when Completed)

#### Financial Information
- **TotalCost** (decimal?) - Total cost of the stock request
- **UnitPrice** (decimal?) - Unit price at the time of request

#### Stock Information
- **CurrentStockAtRequest** (int) - Current stock quantity at the time of request
- **MinimumStockLevel** (int) - Minimum stock level that triggered the request

#### Email Tracking
- **EmailSent** (bool) - Whether email confirmation was sent to supplier
- **EmailSentDate** (DateTime?) - Date when email was sent

#### Audit Fields
- **CreatedAt** (DateTime) - Timestamp when the record was created
- **UpdatedAt** (DateTime) - Timestamp when the record was last updated
- **IsActive** (bool) - Soft delete flag

### Navigation Properties (Not Stored in MongoDB)
- **ProductVariant** - Navigation to ProductVariant entity
- **Product** - Navigation to Product entity
- **Supplier** - Navigation to Supplier entity

### Calculated Properties

#### DisplayRequestID
Returns a human-readable request ID in format `SR-XXXX` (e.g., `SR-A1B2`)

#### StatusBadgeClass
Returns CSS class for status badge:
- `Pending` ? `badge-warning`
- `Approved` ? `badge-info`
- `Completed` ? `badge-success`
- `Rejected` ? `badge-danger`

#### PriorityBadgeClass
Returns CSS class for priority badge:
- `Urgent` ? `badge-danger`
- `High` ? `badge-warning`
- `Normal` ? `badge-info`
- `Low` ? `badge-secondary`

#### IsOverdue
Returns `true` if request is in Pending status for more than 7 days

#### IsRecent
Returns `true` if request was created within the last 24 hours

#### CalculatedTotalCost
Calculates total cost if not already set (UnitPrice × QuantityRequested)

### Helper Methods

#### IsValid()
Validates the stock request before insertion:
- ProductVariantID is not empty
- SupplierID is not empty
- QuantityRequested > 0
- RequestedBy is not empty

#### PrepareForInsertion()
Prepares the stock request for MongoDB insertion:
- Sets RequestDate, CreatedAt, UpdatedAt to current UTC time
- Sets default values for RequestStatus and Priority
- Trims all string properties

#### PrepareForUpdate()
Prepares the stock request for MongoDB update:
- Updates UpdatedAt timestamp
- Trims all string properties

#### Approve(processedBy, processedByUserId)
Approves the stock request:
- Sets status to "Approved"
- Records who processed it
- Updates timestamps

#### Reject(processedBy, processedByUserId, reason)
Rejects the stock request:
- Sets status to "Rejected"
- Records who processed it and why
- Updates timestamps

#### Complete(deliveryDate?)
Marks the stock request as completed:
- Sets status to "Completed"
- Records actual delivery date
- Updates timestamps

#### MarkEmailSent()
Marks that email was sent to supplier:
- Sets EmailSent to true
- Records EmailSentDate
- Updates timestamp

## Status Workflow

```
???????????
? Pending ? ????????????????
???????????                 ?
     ?                      ?
     ????????               ?
     ?      ?               ?
     ?      ?               ?
???????????? ???????????? ????????????
? Approved ? ? Rejected ? ? Completed?
???????????? ???????????? ????????????
     ?
     ?
     ?
????????????
?Completed ?
????????????
```

## Example Usage

### Creating a New Stock Request

```csharp
var stockRequest = new StockRequest
{
    ProductVariantID = variantId,
    ProductID = productId,
    SupplierID = supplierId,
    QuantityRequested = 100,
    RequestedBy = "John Doe",
    RequestedByUserId = userId,
    Instructions = "Urgent - Low stock alert",
    Priority = "High",
    CurrentStockAtRequest = 5,
    MinimumStockLevel = 10,
    UnitPrice = 29.99m
};

stockRequest.PrepareForInsertion();

if (stockRequest.IsValid())
{
    await productService.CreateStockRequestAsync(stockRequest);
    stockRequest.MarkEmailSent();
}
```

### Approving a Stock Request

```csharp
var stockRequest = await productService.GetStockRequestByIdAsync(requestId);
stockRequest.Approve("Jane Manager", managerId);
await productService.UpdateStockRequestAsync(stockRequest);
```

### Rejecting a Stock Request

```csharp
var stockRequest = await productService.GetStockRequestByIdAsync(requestId);
stockRequest.Reject("Jane Manager", managerId, "Insufficient budget");
await productService.UpdateStockRequestAsync(stockRequest);
```

### Completing a Stock Request

```csharp
var stockRequest = await productService.GetStockRequestByIdAsync(requestId);
stockRequest.Complete(DateTime.UtcNow);
await productService.UpdateStockRequestAsync(stockRequest);
```

## Integration Points

### ProductService Methods (To be implemented)
```csharp
Task<string> CreateStockRequestAsync(StockRequest request)
Task<StockRequest> GetStockRequestByIdAsync(string requestId)
Task<List<StockRequest>> GetStockRequestsAsync(string variantId = null, string status = null)
Task<bool> UpdateStockRequestAsync(StockRequest request)
Task<bool> DeleteStockRequestAsync(string requestId)
```

### Database Collection
- **Collection Name**: `StockRequests`
- **Configuration Key**: `StockRequestsCollection` in Web.config
- **Helper Method**: `DatabaseHelper.GetStockRequestsCollection()`

## Changes Made

### 1. Created New File
- **File**: `InventorySystemSiaProject\Models\StockRequest.cs`
- **Purpose**: Dedicated model for stock requests
- **Lines of Code**: ~370 lines

### 2. Updated VariantIngredient.cs
- **Removed**: StockRequest class definition (old implementation)
- **Reason**: Moved to separate file for better organization

### 3. Build Status
? **Build Successful** - No compilation errors

## Best Practices Implemented

1. ? **Separation of Concerns** - Dedicated file for StockRequest model
2. ? **MongoDB Attributes** - Proper BSON serialization attributes
3. ? **Data Validation** - IsValid() method for validation
4. ? **Audit Trail** - CreatedAt, UpdatedAt, ProcessedBy fields
5. ? **Soft Delete** - IsActive flag for data preservation
6. ? **Navigation Properties** - Proper [BsonIgnore] for related entities
7. ? **Calculated Properties** - DisplayRequestID, badge classes, status checks
8. ? **Helper Methods** - Approve, Reject, Complete workflow methods
9. ? **Comprehensive Documentation** - XML comments for all properties and methods
10. ? **Default Values** - Constructor sets sensible defaults

## Next Steps

To fully utilize this model, you should:

1. **Update ProductService.cs** to add CRUD methods for StockRequests
2. **Create a UI page** for managing stock requests (viewing, approving, rejecting)
3. **Integrate with email service** to notify suppliers
4. **Add dashboard widgets** to show pending/overdue requests
5. **Create reports** for stock request analytics
6. **Add notifications** for request status changes
7. **Implement workflow automation** for auto-approval based on rules

## Database Schema

```javascript
// MongoDB Document Structure
{
  "_id": ObjectId("..."),
  "productVariantID": ObjectId("..."),
  "productID": ObjectId("..."),
  "supplierID": ObjectId("..."),
  "quantityRequested": 100,
  "requestDate": ISODate("2024-01-15T10:30:00Z"),
  "requestedBy": "John Doe",
  "requestedByUserId": ObjectId("..."),
  "requestStatus": "Pending",
  "instructions": "Urgent delivery required",
  "expectedDeliveryDate": ISODate("2024-01-20T00:00:00Z"),
  "priority": "High",
  "unitPrice": 29.99,
  "totalCost": 2999.00,
  "currentStockAtRequest": 5,
  "minimumStockLevel": 10,
  "emailSent": true,
  "emailSentDate": ISODate("2024-01-15T10:35:00Z"),
  "createdAt": ISODate("2024-01-15T10:30:00Z"),
  "updatedAt": ISODate("2024-01-15T10:35:00Z"),
  "isActive": true
}
```

## Support

For questions or issues with the StockRequest model, please refer to:
- Model file: `InventorySystemSiaProject\Models\StockRequest.cs`
- This documentation: `STOCKREQUEST_MODEL.md`
- Related services: `ProductService.cs`, `SendEmaikService.cs`
