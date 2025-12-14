# Password Verification Test Guide

## ? What Was Fixed

The `UserAuthenticationService` has been enhanced with comprehensive password verification that now supports:

1. **Custom Two-Part Salted Hash** (`/salt+hash` or `salt/hash`)
   - Example: `/km7+M1CLA7dkBSd+...`
   - Tries multiple algorithms: SHA256, MD5 (both base64 and hex formats)

2. **SHA256 with SaltKey2024** (Standard format)
   - Used by the Users collection

3. **SHA256 without salt**
   - Both base64 and hex formats

4. **MD5 hashes**
   - Both base64 and hex formats

5. **Plain text** (for testing/legacy only)

## ?? How It Works

When logging in with a `TblUser` (from db_shessentials), the system:

1. Checks if user exists in Users collection first
2. If not found, checks TblUser collection
3. Uses `VerifyPasswordHash()` method which tries all formats
4. Logs detailed debug output to help diagnose issues

## ?? Testing Your Password Hash

### Check your password hash format in MongoDB:

```javascript
// In MongoDB Compass or mongosh
use db_shessentials
db.tbl_user.findOne({email: "your@email.com"}, {password_hash: 1, email: 1})
```

### Expected Debug Output (View > Output > Debug):

```
Verifying password against hash format: /km7+M1CLA7dkBSd+...
Attempting two-part salted hash verification
Two-part hash: salt='km7', hashLength=45
Two-part hash verified: SHA256(password+salt)
Password verified using two-part salted hash
Successful login from TblUser collection: your@email.com
```

## ?? Test Scenarios

### Test 1: Login with TblUser account
```csharp
// This should work now with custom salted hashes
var result = await authService.LoginAsync("your@email.com", "yourPassword");
// Check Debug Output window for verification details
```

### Test 2: Verify hash format manually
Add this temporary test method to verify your hash format:

```csharp
// In UserAuthenticationService.cs (for testing only)
public void TestPasswordHash(string password, string storedHash)
{
    System.Diagnostics.Debug.WriteLine($"Testing password against hash: {storedHash.Substring(0, Math.Min(30, storedHash.Length))}...");
    bool result = VerifyPasswordHash(password, storedHash);
    System.Diagnostics.Debug.WriteLine($"Result: {result}");
}
```

Call it from Login.aspx.cs:
```csharp
var authService = new UserAuthenticationService();
authService.TestPasswordHash("yourTestPassword", "/km7+M1CLA7dkBSd+...");
```

## ?? Troubleshooting

### If login still fails:

1. **Check Debug Output** (View > Output > Debug pane)
   - Look for messages starting with "Two-part hash:"
   - This will tell you which format is being tried

2. **Verify your hash format**:
   ```csharp
   // Check if it's really two-part
   string hash = "/km7+M1CLA7dkBSd+...";
   Console.WriteLine($"Contains /: {hash.Contains("/")}");
   Console.WriteLine($"Contains +: {hash.Contains("+")}");
   Console.WriteLine($"Starts with /: {hash.StartsWith("/")}");
   ```

3. **Try different algorithms manually**:
   ```csharp
   string password = "yourPassword";
   string salt = "km7"; // Extract from your hash
   
   using (var sha256 = SHA256.Create())
   {
       // Try password+salt
       var hash1 = Convert.ToBase64String(sha256.ComputeHash(Encoding.UTF8.GetBytes(password + salt)));
       Console.WriteLine($"SHA256(password+salt): {hash1}");
       
       // Try salt+password
       var hash2 = Convert.ToBase64String(sha256.ComputeHash(Encoding.UTF8.GetBytes(salt + password)));
       Console.WriteLine($"SHA256(salt+password): {hash2}");
   }
   ```

4. **Check if account is locked**:
   - After 5 failed attempts, account is locked for 15 minutes
   - Wait or restart the application to clear lockout

## ?? Additional Enhancements Included

### Account Lockout Protection
- **MAX_LOGIN_ATTEMPTS**: 5 attempts
- **LOCKOUT_DURATION**: 15 minutes
- Shows remaining attempts in error message

### Dual Database Support
- **Users collection**: Standard users (face recognition, short pass)
- **TblUser collection**: From db_shessentials (different hash format)

### Debug Logging
All verification attempts are logged to Debug Output for troubleshooting.

## ?? Next Steps

1. **Try logging in** with your account
2. **Check the Debug Output window** immediately after login attempt
3. **Look for the verification messages** to see which format was detected
4. If it still fails, check the exact error message and debug output

## ?? Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| "Password verification fail: no matching format found" | Hash format not recognized. Check Debug Output to see what was tried |
| "Account temporarily locked" | Too many failed attempts. Wait 15 minutes or restart app |
| "Account not configured for login" | password_hash field is empty in database |
| "Invalid email or password" | Email not found or password doesn't match any format |

## ?? Security Notes

- Two-part salted hashes are more secure than plain SHA256
- The system tries multiple formats for compatibility
- Account lockout prevents brute force attacks
- All password verification happens server-side
- Plain text comparison is only for legacy/testing (will log warning)

## ? Success Indicators

When login works correctly, you'll see:
1. ? "Password verified using two-part salted hash" in Debug Output
2. ? "Successful login from TblUser collection: your@email.com"
3. ? Redirect to Dashboard or intended page
4. ? Session variables set (UserID, UserEmail, UserName, UserRole)

---

**Need Help?** Check the Debug Output window first - it contains detailed information about what's happening during authentication.
