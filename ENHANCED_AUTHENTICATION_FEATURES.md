# Enhanced Authentication & Security Features

## Overview
This document describes the enhanced authentication features added to the login system, including multi-format password verification, account lockout protection, and additional security utilities.

---

## 1. Enhanced Password Verification

### Supported Hash Formats

The system now supports multiple password hashing algorithms automatically:

| Hash Format | Description | Detection Method |
|------------|-------------|------------------|
| **BCrypt** | Industry standard (e.g., `$2a$10$...`) | Prefix detection |
| **SHA256 + Salt** | Custom salt (default: "SaltKey2024") | Base64 format (44 chars) |
| **SHA256 No Salt** | Plain SHA256 hash | Base64 or Hex encoding |
| **SHA256 Hex** | SHA256 in hexadecimal format | 64 character hex string |
| **MD5** | Legacy support (not recommended) | Base64 or Hex encoding |
| **Plain Text** | Unencrypted (for testing only) | Direct comparison |

### Custom Salt Support

The system tries multiple salt variations:
- `SaltKey2024` (default)
- `salt`
- `shessentials`
- Empty string (no salt)
- `admin`

### Usage Example

```csharp
var result = await _authService.LoginAsync("user@example.com", "password123");
if (result.Success) {
    // Login successful - hash format detected automatically
    Console.WriteLine(result.Message);
}
```

---

## 2. Account Lockout Protection

### Brute Force Prevention

**Settings:**
- **Max Login Attempts:** 5 failed attempts
- **Lockout Duration:** 15 minutes
- **Tracking:** In-memory (per email address)

### How It Works

1. **First Failed Attempt:**
   - Records attempt count
   - Returns: "Invalid email or password. 4 attempts remaining."

2. **Subsequent Failures:**
   - Increments attempt count
   - Shows remaining attempts: "3 attempts remaining", "2 attempts remaining", etc.

3. **5th Failed Attempt:**
   - Account locked for 15 minutes
   - Returns: "Account locked due to too many failed attempts. Try again in 15 minutes."

4. **Successful Login:**
   - Clears all failed attempts
   - Resets lockout status

### API Methods

```csharp
// Check remaining attempts
int remaining = _authService.GetRemainingAttempts("user@example.com");

// Check if locked out
bool isLocked = IsAccountLockedOut("user@example.com", out int minutesRemaining);
```

---

## 3. New Utility Methods

### Email Validation

```csharp
// Check if email exists in either Users or TblUser collection
bool exists = await _authService.EmailExistsAsync("user@example.com");
```

### Account Details Retrieval

```csharp
// Get account info for debugging
var (source, userId, name, email, role) = await _authService.GetAccountDetailsAsync("user@example.com");
// source: "Users" or "TblUser"
```

### Password Strength Validation

```csharp
var (isValid, message) = _authService.ValidatePasswordStrength("myPassword123");
if (!isValid) {
    Console.WriteLine(message); // "Password should contain at least one number"
}
```

**Validation Rules:**
- ? Minimum 6 characters
- ? Maximum 100 characters
- ? Must contain at least one number
- ? Optional: uppercase, lowercase requirements

### Flexible Password Hashing

```csharp
// Hash with specific algorithm
string hash = _authService.HashPasswordWithAlgorithm(
    password: "myPassword123",
    algorithm: "SHA256",      // Options: SHA256, SHA256_HEX, MD5
    salt: "CustomSalt2024"
);
```

---

## 4. TblUser Integration

### Automatic Collection Detection

The login system automatically checks both databases:

1. **InventorySystemDB.Users** (face recognition enabled)
2. **db_shessentials.tbl_user** (email/password only)

### TblUser Helper Methods

```csharp
// Get TblUser by email
TblUser tblUser = await _authService.GetTblUserByEmailAsync("user@example.com");

// Conversion happens automatically during login
// TblUser ? User (for session management)
```

---

## 5. Security Best Practices

### Implemented Features

? **Rate Limiting:** Account lockout after 5 failed attempts  
? **Password Hashing:** Multiple secure algorithms supported  
? **Attempt Tracking:** In-memory tracking with automatic expiration  
? **User Feedback:** Remaining attempts displayed to user  
? **Debug Logging:** Detailed logs for troubleshooting  
? **Session Management:** Automatic conversion between User types  

### Recommendations

?? **For Production:**
1. Store login attempts in **Redis** or **database** (not in-memory)
2. Implement **CAPTCHA** after 3 failed attempts
3. Enable **2FA** for admin accounts
4. Use **BCrypt** for all new passwords (install `BCrypt.Net-Next`)
5. Implement **email notifications** for suspicious login attempts
6. Add **IP-based rate limiting**

---

## 6. Login Flow Diagram

```
???????????????????????????????????????????
?  User Enters Email & Password           ?
???????????????????????????????????????????
               ?
               ?
???????????????????????????????????????????
?  Check if Account is Locked Out          ?
???????????????????????????????????????????
               ?
        Yes ???????? No
               ?          ?
               ?          ?
   ????????????????????  ??????????????????????????
   ? Return Lockout   ?  ? Search in Users DB     ?
   ? Message          ?  ??????????????????????????
   ????????????????????              ?
                              Found ????? Not Found
                                     ?           ?
                                     ?           ?
                        ???????????????????  ????????????????????
                        ? Verify Password ?  ? Search TblUser   ?
                        ? (Users hash)    ?  ????????????????????
                        ???????????????????           ?
                                ?               Found ??? Not Found
                          Valid ??? Invalid             ?          ?
                                ?         ?             ?          ?
                                ?         ?   ??????????????????  ?
                   ????????????????????  ?   ? Verify Password?  ?
                   ? Clear Attempts   ?  ?   ? (Enhanced)     ?  ?
                   ? Create Session   ?  ?   ??????????????????  ?
                   ? ? Dashboard      ?  ?           ?           ?
                   ????????????????????  ?    Valid ??? Invalid  ?
                                        ?           ?           ?
                                        ?           ?           ?
                              ???????????????????????????????????
                              ? Record Failed Attempt           ?
                              ? Show Remaining Attempts         ?
                              ? Lock if >= 5 attempts           ?
                              ???????????????????????????????????
```

---

## 7. Testing Checklist

### Test Scenarios

- [ ] **Users Collection Login** (SHA256 with salt)
  - Email: `admin@test.com`
  - Password: `admin123`
  - Expected: Login successful

- [ ] **TblUser Collection Login** (SHA256 without salt)
  - Email: `reyesjundillmarcalagahan@gmail.com`
  - Password: [your password]
  - Expected: Login successful

- [ ] **Failed Login Attempts**
  - Try wrong password 3 times
  - Expected: "2 attempts remaining"
  
- [ ] **Account Lockout**
  - Try wrong password 5 times
  - Expected: "Account locked for 15 minutes"

- [ ] **Lockout Expiration**
  - Wait 15 minutes after lockout
  - Try login again
  - Expected: Login works

- [ ] **Password Strength Validation**
  - Try password without numbers
  - Expected: Validation error

- [ ] **Different Hash Formats**
  - Test SHA256, MD5, plain text
  - Expected: All formats detected

---

## 8. Configuration

### Adjustable Constants

```csharp
// In UserAuthenticationService.cs
private const int MAX_LOGIN_ATTEMPTS = 5;              // Change to adjust max attempts
private const int LOCKOUT_DURATION_MINUTES = 15;       // Change lockout duration
```

### Web.config Settings

```xml
<appSettings>
  <!-- Database settings -->
  <add key="SheEssentialsDatabase" value="db_shessentials" />
  <add key="TblUserCollection" value="tbl_user" />
  
  <!-- Security settings (optional - add these) -->
  <add key="MaxLoginAttempts" value="5" />
  <add key="LockoutDurationMinutes" value="15" />
  <add key="PasswordSalt" value="SaltKey2024" />
</appSettings>
```

---

## 9. Debugging

### Debug Output

The system logs detailed information to help troubleshoot:

```
Password verified using SHA256 without salt
Successful login from TblUser collection: user@example.com
Account locked: user@test.com for 15 minutes
Failed attempt 3/5 for: user@example.com
```

### Enable Debug Logging

Already enabled via `System.Diagnostics.Debug.WriteLine()`. View in:
- Visual Studio ? **Output Window** ? **Debug**

---

## 10. Migration Path

### Upgrading to BCrypt

To use BCrypt (recommended):

1. **Install NuGet Package:**
   ```powershell
   Install-Package BCrypt.Net-Next
   ```

2. **Update VerifyPasswordHash:**
   ```csharp
   if (storedHash.StartsWith("$2a$") || storedHash.StartsWith("$2b$"))
   {
       return BCrypt.Net.BCrypt.Verify(password, storedHash);
   }
   ```

3. **Hash New Passwords:**
   ```csharp
   string bcryptHash = BCrypt.Net.BCrypt.HashPassword(password);
   ```

---

## Files Modified

1. ? `UserAuthenticationService.cs` - Enhanced authentication logic
2. ? `TblUser.cs` - Model for db_shessentials.tbl_user
3. ? `DatabaseHelper.cs` - Connection to db_shessentials
4. ? `Web.config` - Database configuration

## Next Steps

1. Test all login scenarios
2. Monitor debug logs for hash detection
3. Consider implementing BCrypt for new accounts
4. Add Redis/database for distributed login tracking
5. Implement email notifications for lockouts
6. Add admin panel to view/reset locked accounts

---

**Last Updated:** 2024
**Version:** 2.0 Enhanced Security Edition
