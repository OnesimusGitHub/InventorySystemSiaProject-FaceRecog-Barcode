# Database Migration to db_shessentials

## Summary
Successfully migrated the login system from using `HumanResourcesDB` to using the `db_shessentials` database with the `tbl_user` collection.

## Changes Made

### 1. Created New Model - `TblUser.cs`
- **Location**: `InventorySystemSiaProject\Models\TblUser.cs`
- **Purpose**: Maps to the `tbl_user` collection in `db_shessentials` database
- **Key Properties**:
  - `first_name`, `middle_name`, `last_name` (name fields)
  - `email` (login identifier)
  - `password_hash` (hashed password)
  - `role` (user role - "admin" or regular user)
  - `is_email_verified` (determines active status)
  - `employee_id`, `department` (employee-specific fields)
  - `address` (stored as BsonDocument)
  - `created_at`, `updated_at` (timestamps)
  
- **Computed Properties**:
  - `FullName`: Concatenates first, middle, and last names
  - `IsAdmin`: Checks if role contains "admin"
  - `IsActive`: Based on `IsEmailVerified` status

### 2. Updated Web.config
- **Changes**:
  - Replaced `HumanResourcesConnection` with `SheEssentialsConnection`
  - Changed database name from `HumanResourcesDB` to `db_shessentials`
  - Added `TblUserCollection` app setting pointing to `tbl_user`
  
- **Connection String**:
  ```xml
  <add name="SheEssentialsConnection" 
       connectionString="mongodb+srv://delacruzonesimuspalles_db_user:mokmokxdpapogs19@cluster0.1uursjj.mongodb.net/db_shessentials?..." />
  ```

### 3. Updated DatabaseHelper.cs
- **New Methods**:
  - `GetTblUserCollectionName()`: Returns collection name from config
  - `GetTblUserCollection()`: Connects to `tbl_user` in `db_shessentials` database
  
- **Connection Handling**: Creates separate MongoDB client for `db_shessentials` database with proper SSL settings

### 4. Updated UserAuthenticationService.cs
- **Replaced**: `_employeesCollection` with `_tblUserCollection`
- **New Method**: `ConvertTblUserToUser()` - Converts TblUser to User for session management
- **Enhanced**: `VerifyPasswordHash()` - Handles different password hash formats
- **Updated**: `LoginAsync()` method now checks both:
  1. `Users` collection (from InventorySystemDB) - for existing users with face recognition
  2. `tbl_user` collection (from db_shessentials) - for employees/customers

## Login Flow

### Email/Password Login:
1. Check `Users` collection first (InventorySystemDB)
   - If found ? verify password ? login
2. If not found, check `tbl_user` collection (db_shessentials)
   - If found ? verify password_hash ? convert to User ? login
3. If neither found ? return error

### Face Recognition + PIN Login:
- **Only for Users collection** (not for tbl_user)
- TblUser accounts use email/password only

## Important Notes

### Password Verification
The system now handles two types of password storage:
- **Users collection**: Uses SHA256 with salt ("SaltKey2024")
- **tbl_user collection**: Uses password_hash field (already hashed)

The `VerifyPasswordHash()` method attempts multiple strategies to verify passwords.

### Role Mapping
When a TblUser logs in, their role is mapped:
- If `IsAdmin` property is true ? Role = "Admin"
- Otherwise ? Role = "User"

### Session Management
After successful login from tbl_user:
- TblUser is converted to User object
- Session stores the converted User data
- All existing session logic works normally

## Testing Checklist

- [ ] Login with existing Users collection account
- [ ] Login with tbl_user account (employee from db_shessentials)
- [ ] Verify admin access for tbl_user with admin role
- [ ] Test face recognition (should only work for Users collection)
- [ ] Verify session data is properly set
- [ ] Check dashboard redirect after login

## Database Structure

### db_shessentials.tbl_user
```
_id: ObjectId
first_name: string
middle_name: string (nullable)
last_name: string
email: string
password_hash: string
role: string ("customer" or "admin")
employee_id: string (nullable)
department: string (nullable)
is_email_verified: boolean
created_at: DateTime
updated_at: DateTime
address: Object
zip_code: string
phone: string
terms_accepted: boolean
```

## Files Modified
1. `InventorySystemSiaProject\Models\TblUser.cs` (NEW)
2. `InventorySystemSiaProject\Web.config`
3. `InventorySystemSiaProject\Helpers\DatabaseHelper.cs`
4. `InventorySystemSiaProject\Services\UserAuthenticationService.cs`

## Next Steps (Optional Enhancements)
1. Install `BCrypt.Net-Next` NuGet package for proper bcrypt verification
2. Add password reset functionality for tbl_user accounts
3. Sync user data between Users and tbl_user collections
4. Add logging for login attempts from both collections
