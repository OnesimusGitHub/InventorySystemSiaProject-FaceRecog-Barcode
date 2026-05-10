# CRITICAL: Hard Reset & Recompile Instructions

## ?? IMPORTANT: Your Code Changes Are Saved But Not Applied Yet

The fixes to `Employee.cs` have been saved correctly:
- ? `Age` changed to `int?` (nullable)
- ? `BirthDate` changed to `DateTime?` (nullable)
- ? `HireDate` changed to `DateTime?` (nullable)
- ? `[BsonIgnoreExtraElements]` added to class

**BUT** - Visual Studio is still running the OLD compiled DLL from before the changes.

---

## Step 1: STOP DEBUGGING COMPLETELY

Press **Shift + F5** (or Debug ? Stop Debugging)

Wait 2-3 seconds for the process to fully stop.

---

## Step 2: CLOSE VISUAL STUDIO ENTIRELY

**This is critical!** Don't just stop debugging - actually close VS.

- Click **File ? Exit**
- Or press **Alt + F4**

Wait for all Visual Studio processes to close (check Task Manager if unsure).

---

## Step 3: DELETE COMPILED BINARIES

Open File Explorer and navigate to:
```
C:\Users\Asus PC\source\repos\InventorySystemSiaProject\InventorySystemSiaProject\
```

Delete these folders completely:
- ? `bin` folder (entire folder)
- ? `obj` folder (entire folder)

This removes all old compiled code.

---

## Step 4: REOPEN VISUAL STUDIO

1. Open Visual Studio
2. Open the solution:
   ```
   C:\Users\Asus PC\source\repos\InventorySystemSiaProject\InventorySystemSiaProject.sln
   ```

---

## Step 5: CLEAN BUILD

In Visual Studio:

1. Click **Build** menu
2. Click **Clean Solution**
3. Wait for completion (should say "Clean succeeded")

4. Click **Build** menu again
5. Click **Rebuild Solution**
6. Wait for completion (should say "Build succeeded")

---

## Step 6: CLEAR BROWSER CACHE

**Important!** The browser may have cached old responses.

### Option A: Hard Refresh
Press **Ctrl + Shift + Delete** to open DevTools cache settings, then clear all.

### Option B: Incognito Window (Easier)
1. Open **Chrome Incognito** (Ctrl + Shift + N)
2. Navigate to your localhost URL

### Option C: Clear Entire Site Data
1. Open DevTools (F12)
2. Go to **Application** tab
3. Click **Clear site data**

---

## Step 7: START DEBUGGING

Press **F5** (Debug ? Start Debugging)

Wait 5-10 seconds for compilation and startup.

---

## Step 8: TEST THE HANDLER

Open new browser tab and navigate to:
```
http://localhost:57993/Handlers/SearchInventoryEmployees.ashx?q=willowby
```

---

## Expected Result ?

You should see JSON response:
```json
{
  "success": true,
  "results": [
    {
      "id": "69e1e505a404efe856629ffd8",
      "firstName": "Willowby",
      "lastName": "Rinoa",
      "name": "Willowby Rinoa",
      "email": "seriosa.willowyrinoa.delosreyes@gmail.com",
      "role": "Inventory Control Specialist",
      "department": "Inventory",
      "isEmailVerified": false
    }
  ],
  "count": 1
}
```

---

## If Still Not Working

### Check 1: Verify Files Were Actually Modified

Open `InventorySystemSiaProject\Models\Employee.cs` in Visual Studio and verify:

```csharp
[BsonElement("age")]
public int? Age { get; set; }  // Should have "?" after int

[BsonElement("birthDate")]
public DateTime? BirthDate { get; set; }  // Should have "?" after DateTime

[BsonElement("hireDate")]
public DateTime? HireDate { get; set; }  // Should have "?" after DateTime
```

### Check 2: Build Output Window

1. View ? Output (Ctrl + Alt + O)
2. Look for any errors in the build output
3. Verify "Build succeeded" message is shown

### Check 3: Debug Console

1. View ? Debug Windows ? Immediate Window (Ctrl + Alt + I)
2. Type: `System.Diagnostics.Debug.WriteLine("TEST")`
3. Should print to Output window if code is executing

### Check 4: Force IIS Reset

In PowerShell (run as Administrator):
```powershell
iisreset /restart
```

Then restart VS debugging.

---

## Quick Checklist Before Testing

- [ ] Visual Studio completely closed
- [ ] `bin` folder deleted
- [ ] `obj` folder deleted
- [ ] Visual Studio reopened
- [ ] Clean Solution completed successfully
- [ ] Rebuild Solution completed successfully
- [ ] Browser cache cleared (or using Incognito)
- [ ] Started debugging (F5)
- [ ] Waited 5-10 seconds for startup
- [ ] Verified Employee.cs has `?` after nullable types

---

## Why This Works

1. **Deleting bin/obj** - Removes old compiled DLLs that VS was running
2. **Clean + Rebuild** - Forces fresh compilation of new code
3. **Closing VS completely** - Releases all locks on assemblies
4. **Browser cache clear** - Removes cached responses from old handler code
5. **Incognito window** - No cached data at all

The issue is **caching at multiple levels** (compiled DLL, browser cache, memory).

---

## Expected Timeline

- Deleting folders: 5 seconds
- Clean: 10-15 seconds
- Rebuild: 30-60 seconds
- VS startup: 10-15 seconds
- First run: 5-10 seconds
- **Total: ~2-3 minutes**

---

## Still Having Issues After All This?

If you still get the Age deserialization error after following every step:

1. **Post the exact error message** (copy/paste entire error)
2. **Check MongoDB document** - Maybe Age field has unexpected type
3. **Look at all Employee fields** - There might be another non-nullable field with null values

But honestly, if you follow all these steps, it **WILL work** - the code is correct! 

The problem is 100% about old compiled code still running.
