# Testing Guide for Your Specific Password Hash

## Your Account Details
- **Email**: `jundillmharreyes@gmail.com`
- **Password**: `HihiAyy123!`
- **Hash Format**: `/km7+MLUCLA7dkBSd+XXXQ==.b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=`

## Hash Format Analysis

Your hash uses a **period (`.`) separator**:

```
Salt:     /km7+MLUCLA7dkBSd+XXXQ==
Separator: .
Hash:     b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=
```

Note: The salt itself contains special characters (`/`, `+`, `=`)

## What Was Fixed

The `VerifyTwoPartSaltedHash` method now:
1. ? Handles period (`.`) as separator
2. ? Uses `LastIndexOf()` to find separator (handles special chars in salt)
3. ? Tries multiple algorithms: SHA256, SHA512, MD5 (both orders)
4. ? Supports both base64 and hex formats

## How to Test

### Method 1: Check Debug Output (EASIEST)

1. **Stop your current debug session** (Shift+F5)
2. **Restart the application** (F5)
3. **Try to login** with:
   - Email: `jundillmharreyes@gmail.com`
   - Password: `HihiAyy123!`
4. **Immediately check Debug Output** (View > Output > Show output from: Debug)

### Expected Debug Output:

```
Verifying password against hash format: /km7+MLUCLA7dkBSd+X...
Attempting two-part salted hash verification
Two-part hash (period separator): salt='/km7+MLUCLA7dkBSd+XXXQ==', hashLength=44
Two-part hash verified: SHA256(password+salt) base64
Password verified using two-part salted hash
Successful login from TblUser collection: jundillmharreyes@gmail.com
```

### Method 2: Use Test Helper

Add this to your `Login.aspx.cs` Page_Load (temporarily):

```csharp
protected void Page_Load(object sender, EventArgs e)
{
    if (!IsPostBack)
    {
        // TEMPORARY TEST
        InventorySystemSiaProject.TestHelpers.PasswordHashTester.TestYourHash();
    }
}
```

This will output all hash attempts to the console/debug window.

### Method 3: Manual Test in MongoDB

Run this in MongoDB Compass/mongosh to verify your account exists:

```javascript
use db_shessentials
db.tbl_user.findOne({
  email: "jundillmharreyes@gmail.com"
}, {
  _id: 1,
  email: 1,
  first_name: 1,
  last_name: 1,
  password_hash: 1,
  is_email_verified: 1,
  role: 1
})
```

Expected result:
```javascript
{
  _id: ObjectId("69159684010ec3bb80a3bd916"),
  first_name: "Jm ,",
  last_name: "Reyes,",
  email: "jundillmharreyes@gmail.com",
  password_hash: "/km7+MLUCLA7dkBSd+XXXQ==.b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=",
  is_email_verified: true,
  role: "admin"
}
```

## Troubleshooting

### If login still fails:

#### 1. Check if Hot Reload Applied
- Press **Ctrl+Shift+F5** (Stop and Restart)
- Hot reload might not have applied the changes
- Full restart ensures new code is running

#### 2. Verify Account Not Locked
- After 5 failed attempts, account locks for 15 minutes
- **Solution**: Restart the application to clear lockout
- Or wait 15 minutes

#### 3. Check Debug Output for Clues
Look for these messages:
- ? "Two-part hash (period separator)" = Format recognized
- ? "Two-part hash verified: SHA256..." = Algorithm found
- ? "No matching algorithm found" = Wrong password or algorithm
- ? "Password verification fail: no matching format found" = Format not recognized

#### 4. Double-Check Password
Make sure you're typing exactly: `HihiAyy123!`
- Case-sensitive
- Includes exclamation mark at the end
- No extra spaces

#### 5. Verify Hash in Database
The hash should be EXACTLY:
```
/km7+MLUCLA7dkBSd+XXXQ==.b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=
```

## Hash Format Examples

The system now supports all these formats:

| Format | Example | Separator |
|--------|---------|-----------|
| **Your Format** | `/km7+MLUCLA7dkBSd+XXXQ==.b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=` | `.` (period) |
| Standard Format | `/salt+hash` | `+` (plus) |
| Alternative | `salt/hash` | `/` (slash) |
| Simple | `SHA256hash` | None |

## Algorithms Tried (in order)

For your format, the system tries:
1. SHA256(password + salt) - Base64
2. SHA256(salt + password) - Base64
3. SHA256(password + salt) - Hex
4. SHA256(salt + password) - Hex
5. SHA512(password + salt) - Base64 ? Most likely for 44-char hash
6. SHA512(salt + password) - Base64
7. MD5(password + salt) - Base64
8. MD5(salt + password) - Base64

**Note**: Your hash length (44 characters base64) suggests SHA256 (32 bytes) or possibly SHA512 truncated.

## Success Indicators

When login works, you should see:
1. ? Debug Output shows "Password verified using two-part salted hash"
2. ? Debug Output shows "Successful login from TblUser collection"
3. ? Redirect to Dashboard
4. ? Session variables set (check with: `Session["UserEmail"]`)

## Quick Actions

### Action 1: Restart and Try
```
1. Press Shift+F5 (Stop Debugging)
2. Press F5 (Start Debugging)
3. Navigate to Login page
4. Enter: jundillmharreyes@gmail.com / HihiAyy123!
5. Click Login
6. Immediately check Debug Output (View > Output)
```

### Action 2: If Still Fails - Check the Exact Hash
```csharp
// Add to Login.aspx.cs temporarily
var authService = new UserAuthenticationService();
System.Diagnostics.Debug.WriteLine("Testing hash verification...");

string password = "HihiAyy123!";
string hash = "/km7+MLUCLA7dkBSd+XXXQ==.b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=";

// This will log all attempts
var result = authService.LoginAsync("jundillmharreyes@gmail.com", password).Result;
System.Diagnostics.Debug.WriteLine($"Result: {result.Success}, {result.Message}");
```

## Next Steps

1. **STOP** your current debug session
2. **RESTART** the application (Ctrl+Shift+F5 or Shift+F5 then F5)
3. **TRY** logging in with your credentials
4. **CHECK** the Debug Output window IMMEDIATELY
5. **REPORT** what you see in the debug output

The debug output will tell us exactly what's happening!

---

**Important**: The hash length of 44 characters (base64) = 33 bytes, which is unusual. This might be:
- SHA256 (32 bytes) + 1 byte checksum = 33 bytes
- Custom hash format
- We need to see the debug output to confirm which algorithm works!
