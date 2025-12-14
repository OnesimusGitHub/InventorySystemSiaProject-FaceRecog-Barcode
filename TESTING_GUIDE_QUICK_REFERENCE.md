# Quick Testing Guide - Enhanced Login System

## ?? Quick Start Testing

### Test 1: Normal Login (TblUser from db_shessentials)
```
Email: reyesjundillmarcalagahan@gmail.com
Password: [your actual password]
Expected: ? "Login successful" ? Dashboard
```

### Test 2: Failed Login Attempts
```
Email: test@example.com
Password: wrong123 (try 3 times)
Expected: 
  - Attempt 1: "Invalid email or password. 4 attempts remaining."
  - Attempt 2: "Invalid email or password. 3 attempts remaining."
  - Attempt 3: "Invalid email or password. 2 attempts remaining."
```

### Test 3: Account Lockout
```
Email: test@example.com
Password: wrong123 (try 5 times total)
Expected: ? "Account locked due to too many failed attempts. Try again in 15 minutes."
```

### Test 4: Successful Login Resets Attempts
```
1. Try wrong password 3 times
2. Enter correct password
Expected: ? Login successful, attempts counter reset
```

---

## ?? Password Hash Format Detection

Your `tbl_user` table likely uses one of these formats:

### Common Hash Formats in Your Database:

| Format | Length | Example Start | Detection |
|--------|--------|---------------|-----------|
| SHA256 Base64 | 44 chars | `xK7R...` | Automatically detected |
| SHA256 Hex | 64 chars | `c897...` | Automatically detected |
| BCrypt | ~60 chars | `$2a$10$` | Automatically detected |
| MD5 | 24/32 chars | `5d41...` | Automatically detected |

### To Check Your Hash Format:

1. Open MongoDB Compass
2. Go to `db_shessentials` ? `tbl_user`
3. Look at `password_hash` field
4. Check length and format:
   - 44 characters ? SHA256 Base64
   - 60+ characters with `$2a$` ? BCrypt
   - 64 characters (hex) ? SHA256 Hex

---

## ?? Testing Different Hash Formats

### If your password_hash is SHA256 (most common):

**Test Account Setup:**
```javascript
// In MongoDB Compass, update a test user:
{
  "email": "test@test.com",
  "password_hash": "jGl25bVBBBW96Qi9Te4V37Fnqchz/Eu4qB9vKrRIqRg=", // = "test123"
  "is_email_verified": true,
  "role": "admin"
}
```

**Then test:**
```
Email: test@test.com
Password: test123
Expected: ? Login successful
```

### If password_hash is plain text (for testing):

**Test Account:**
```javascript
{
  "email": "test@test.com",
  "password_hash": "password123", // Plain text
  "is_email_verified": true
}
```

**Then test:**
```
Email: test@test.com
Password: password123
Expected: ? Login successful (with warning in debug output)
```

---

## ??? Debugging Tips

### View Debug Output:

1. In Visual Studio ? **View** ? **Output**
2. Select **"Debug"** from dropdown
3. Look for messages like:
   ```
   Password verified using SHA256 without salt
   Successful login from TblUser collection: user@example.com
   ```

### Common Issues & Solutions:

| Issue | Cause | Solution |
|-------|-------|----------|
| "Invalid email or password" | Hash format mismatch | Check password_hash length/format |
| "Account not configured" | password_hash is null/empty | Set password_hash in database |
| "Account locked" | Too many failed attempts | Wait 15 minutes or restart app |
| "is_email_verified: false" | Email not verified | Set is_email_verified: true |

---

## ?? Expected Behavior Matrix

| Scenario | Database | Result | Redirect |
|----------|----------|--------|----------|
| Valid credentials (Users) | InventorySystemDB.Users | ? Success | Dashboard.aspx |
| Valid credentials (TblUser) | db_shessentials.tbl_user | ? Success | Dashboard.aspx |
| Wrong password (1st) | Any | ? "4 attempts remaining" | Login.aspx |
| Wrong password (5th) | Any | ? "Account locked for 15 minutes" | Login.aspx |
| Locked account | Any | ? "Locked. Try in X minutes" | Login.aspx |
| Email not found | Any | ? "Invalid email or password" | Login.aspx |
| Inactive account | Any | ? No match (IsActive = false) | Login.aspx |

---

## ?? Security Features Active

? **Account Lockout** - 5 attempts, 15 min lockout  
? **Multi-Hash Support** - SHA256, BCrypt, MD5, plain text  
? **Attempt Counter** - Shows remaining attempts  
? **Auto-Reset** - Clears on successful login  
? **Debug Logging** - Detailed logs in Output window  
? **Case-Insensitive Email** - user@test.com = USER@test.com  

---

## ?? Quick Test Script

Run this test sequence in order:

```
Test #1: Valid Login
  Email: [your-email]
  Password: [correct-password]
  Expected: ? Dashboard

Test #2: Wrong Password (3x)
  Email: [your-email]
  Password: wrongpass
  Expected: ? "2 attempts remaining"

Test #3: Correct Password (Reset)
  Email: [your-email]
  Password: [correct-password]
  Expected: ? Dashboard (attempts reset)

Test #4: Force Lockout (5x)
  Email: test2@test.com
  Password: wrong (5 times)
  Expected: ? "Account locked"

Test #5: Wait & Retry
  Wait: 15 minutes
  Email: test2@test.com
  Password: correct
  Expected: ? Login works again
```

---

## ?? Contact Support

If you encounter issues:

1. Check Output window for debug messages
2. Verify database connection to `db_shessentials`
3. Confirm `is_email_verified` is `true`
4. Check `password_hash` is not null/empty
5. Try plain text password first for testing

---

**System Status:** ? Ready for Testing  
**Version:** Enhanced Security 2.0  
**Last Updated:** Now
