# Employee Autocomplete Search - Troubleshooting & Testing Guide

## Issue: Autocomplete Not Showing Results

The autocomplete search in the "Add User" modal should display employees from the Inventory department as you type. If results aren't showing, follow this guide to diagnose and fix the issue.

---

## Quick Debugging Steps

### Step 1: Open Browser Developer Tools
1. Press **F12** to open Developer Tools
2. Click on **Console** tab
3. You should see `[SheSearch] Autocomplete initialized` message

### Step 2: Test the Search
1. In User Management page, click "Add User" button
2. In the search box, type "se" or "ser"
3. Watch the Console tab for messages starting with `[SheSearch]`

### Step 3: Expected Console Output
When you type in the search box, you should see:
```
[SheSearch] Autocomplete initialized
[SheSearch] Input value: se
[SheSearch] Calling SearchEmployees with query: se
[SheSearch] PageMethods available: true
[SheSearch] SearchEmployees available: function
[SheSearch] SUCCESS - Returned: Array(1)
[SheSearch] Rendered 1 results
```

---

## Common Issues & Solutions

### Issue 1: "PageMethods not available"
**Console shows:** `[SheSearch] PageMethods available: false`

**Cause:** ScriptManager not properly configured

**Solution:**
1. Open `Admin/Admin.Master`
2. Find: `<asp:ScriptManager ID="ScriptManager1" runat="server" />`
3. Change to: `<asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />`
4. Clear browser cache and reload

### Issue 2: "SearchEmployees not available"
**Console shows:** `[SheSearch] SearchEmployees available: false`

**Cause:** WebMethod not decorated correctly

**Solution:**
1. Open `UserPrivilege.aspx.cs`
2. Verify SearchEmployees method has `[WebMethod]` attribute
3. Verify it's a `public static` method
4. Rebuild solution

### Issue 3: "Returned empty array"
**Console shows:** `[SheSearch] SUCCESS - Returned: Array(0)`

**Cause:** Either:
- No employees in database with "Inventory" department
- Query doesn't match any names/emails

**Solution:**
1. Check database for employees in Inventory department:
   - Go to MongoDB Atlas
   - Navigate to: HumanResourcesDB ? Employees collection
   - Filter: `{ "department": "Inventory" }`
   - Should see at least some documents
2. Test with exact name from database
3. Check if department value is exactly "Inventory" (case-sensitive)

### Issue 4: "ERROR callback fired"
**Console shows:** `[SheSearch] ERROR callback: Error...`

**Cause:** WebMethod threw an exception or connection failed

**Solution:**
1. Check the error message in console for details
2. Open browser's Network tab (F12 ? Network)
3. Look for request to `/WebPages/UserPrivilege.aspx/SearchEmployees`
4. Click on it and check Response tab for error details
5. Common errors:
   - **MongoDB connection timeout:** Check Web.config HumanResourcesConnection string
   - **Collection doesn't exist:** Ensure HumanResourcesDB.Employees collection exists
   - **Department filter error:** Verify "Inventory" matches database exactly

---

## Network Debugging (F12 ? Network Tab)

1. Open Developer Tools (F12)
2. Click **Network** tab
3. Type in autocomplete search box (e.g., "ser")
4. Look for POST request to: `UserPrivilege.aspx/SearchEmployees`
5. Click on it to see:
   - **Request Headers:** Shows the query being sent
   - **Response:** Shows the JSON data returned
   - **Timing:** Shows how long the request took

### Expected Response Format
```json
[
  {
    "Id": "60e5b954efe85662...",
    "FirstName": "Seriosa",
    "LastName": "Willoby",
    "Name": "Seriosa Willoby",
    "Email": "seriosa.willobby@example.com",
    "Role": "Inventory Control Specialist",
    "Department": "Inventory",
    "IsEmailVerified": false
  }
]
```

---

## Server-Side Debugging

### Check Server Logs
1. Open Visual Studio Output window (View ? Output)
2. In the dropdown, select "Debug"
3. Look for messages starting with `[SearchEmployees]`

### Expected Debug Output
```
[SearchEmployees] Found 1 employees for query: ser
```

### If You See Errors
```
[SearchEmployees] Error: Connection timeout - ...
[SearchEmployees] Error: Collection not found - ...
```

---

## Database Verification

### Check HumanResourcesDB Connection
1. Open Web.config
2. Verify `HumanResourcesConnection` exists:
   ```xml
   <add name="HumanResourcesConnection" connectionString="mongodb+srv://..." />
   ```

### Check Employees Collection
1. Go to MongoDB Atlas
2. Database: `HumanResourcesDB`
3. Collection: `Employees`
4. Query: `{ "department": "Inventory" }`
5. Should return documents with:
   - `firstName` field
   - `lastName` field
   - `email` field
   - `department: "Inventory"` field

### Sample Employee Document
```json
{
  "_id": ObjectId("60e5b954efe85662..."),
  "employeeId": "SHE-026",
  "firstName": "Seriosa",
  "lastName": "Willoby",
  "email": "seriosa.willobby@example.com",
  "contactNo": "+6309828205863",
  "address": "Metro Manila",
  "department": "Inventory",
  "role": "Inventory Control Specialist",
  "isActive": true,
  "hireDate": ISODate("2025-01-17T..."),
  "contractType": "Regular"
}
```

---

## Manual Testing in Postman/cURL

### Test the WebMethod Directly

**Using cURL:**
```bash
curl -X POST "https://your-app.com/WebPages/UserPrivilege.aspx/SearchEmployees" \
  -H "Content-Type: application/json" \
  -d '{"q":"seriosa"}'
```

**Expected Response:**
```json
[
  {
    "Id": "60e5b954efe85662...",
    "FirstName": "Seriosa",
    "LastName": "Willoby",
    "Name": "Seriosa Willoby",
    "Email": "seriosa.willobby@example.com",
    "Role": "Inventory Control Specialist",
    "Department": "Inventory",
    "IsEmailVerified": false
  }
]
```

---

## Complete Test Checklist

- [ ] Browser console shows `[SheSearch] Autocomplete initialized`
- [ ] After typing, console shows `[SheSearch] Input value: ...`
- [ ] Console shows `PageMethods available: true`
- [ ] Console shows `SearchEmployees available: function`
- [ ] Network tab shows POST to `SearchEmployees` with 200 status
- [ ] Response contains array of employees
- [ ] All employees have `department: "Inventory"`
- [ ] Results display in dropdown below search box
- [ ] Clicking result auto-fills Name and Email fields
- [ ] Verified badge shows if email is verified

---

## Code Changes Made

### 1. UserPrivilege.aspx.cs
- Enhanced SearchEmployees method with debug logging
- Added IsEmailVerified field for consistency
- Added try-catch with detailed error logging

### 2. UserPrivilege.aspx
- Enhanced JavaScript with detailed console logging
- Better error handling
- Result validation before rendering
- Debug output for PageMethods availability

### 3. Web.config
- HumanResourcesConnection configured (should already be there)
- HumanResourcesDatabase setting configured

---

## Performance Considerations

- **Debounce delay:** 250ms (waits 250ms after user stops typing)
- **Result limit:** 20 items maximum
- **Search fields:** FirstName, LastName, Email (all case-insensitive)
- **Department filter:** Exact match on "Inventory"

---

## Contact for Support

If you're still seeing issues:
1. Open Developer Tools (F12)
2. Go to Console tab
3. Screenshot the console output with errors
4. Go to Network tab and check SearchEmployees request
5. Check MongoDB Atlas for employee data with "Inventory" department
6. Verify Web.config has HumanResourcesConnection

Then share the error details with the development team.
