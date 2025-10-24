# Quick Start: Testing Dashboard Filters

## ? Pre-Flight Checklist

Before testing, ensure:
- [ ] Solution is rebuilt (Build ? Rebuild Solution)
- [ ] Browser cache is cleared (Ctrl+Shift+Delete)
- [ ] You're logged into the application
- [ ] Browser console is open (F12) to see debug messages

## ?? Quick Test Steps

### 1. Default State (No Filters)
```
Action: Just open the dashboard
Expected: See monthly chart with data, period buttons active
Time: Immediate
```

### 2. Single Filter Test
```
Action: Select "Haircare" from category dropdown
Expected: Chart updates automatically within 1-2 seconds
         Filter tag appears below filters
         Period buttons are dimmed
Time: 1-2 seconds
```

### 3. Reset Test
```
Action: Click "Reset" button
Expected: All filters clear
         Return to monthly view
         Period buttons active again
Time: Immediate
```

### 4. Period Button Test
```
Action: With filters active, click "Daily" button
Expected: Filters automatically clear
         Chart shows daily view
         Filter tags disappear
Time: Immediate
```

## ?? If Still Shows "Loading..."

### Option 1: Hard Refresh
1. Press `Ctrl + Shift + R` (Windows) or `Cmd + Shift + R` (Mac)
2. Wait 2-3 seconds
3. Try applying filter again

### Option 2: Check Browser Console
1. Press `F12` to open developer tools
2. Go to "Console" tab
3. Apply a filter
4. Look for error messages (red text with ?)
5. Copy any error messages

### Option 3: Check Network Tab
1. Press `F12`
2. Go to "Network" tab
3. Apply a filter
4. Find request to `GetFilteredDashboardData`
5. Click on it
6. Check "Response" tab
7. Should see JSON data, not HTML

### Option 4: Verify WebMethod is Working
Open URL directly in browser:
```
http://localhost:[your-port]/WebPages/Dashboard.aspx/GetFilteredDashboardData
```
Should see: "Method Not Allowed" or similar (this is OK - means it exists)
Should NOT see: 404 error

## ?? Expected Console Output

When working correctly, you should see:
```
Applying filters: {category: "Haircare", startDate: "", endDate: ""}
?? Loading filtered dashboard data...
?? Sending request payload: {category: "Haircare", ...}
?? Response status: 200 OK
? Updated filtered data
? Dashboard updated with filtered data
```

## ?? Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Loading..." never goes away | Check console for errors, verify WebMethod exists |
| Chart is blank | Check if there's any sales data in database |
| Filters don't apply | Make sure to select a value and wait 1-2 seconds |
| Period buttons don't work | They should be dim when filters are active (this is correct!) |
| Tags don't appear | Check displayActiveFilters() is being called |

## ?? Success Indicators

You know it's working when:
- ? Chart updates within 1-2 seconds of selecting filter
- ? "Loading..." changes to a percentage (e.g., "12.5% vs last period")
- ? Filter tags appear below the filter controls
- ? Period buttons dim out when filters are active
- ? Clicking period buttons clears filters
- ? Reset button clears everything

## ?? Testing Checklist

- [ ] Open dashboard ? See default monthly view
- [ ] Select category ? Chart updates automatically
- [ ] Select date range ? Chart updates automatically
- [ ] See filter tags appear
- [ ] Click X on filter tag ? That filter removes
- [ ] Click Reset ? All filters clear
- [ ] Apply filters ? Click Daily button ? Filters reset
- [ ] Switch between Daily/Weekly/Monthly ? Works correctly

## ?? If Nothing Works

1. **Stop** the application
2. **Clean** solution (Build ? Clean Solution)
3. **Rebuild** solution (Build ? Rebuild Solution)
4. **Start** application again
5. **Hard refresh** browser (Ctrl+Shift+R)
6. Try again

If still not working, check:
- Is `Dashboard.aspx.cs` in the project?
- Does `GetFilteredDashboardData` WebMethod exist?
- Is the method marked as `[WebMethod(EnableSession = true)]`?
- Are you logged in? (Check Session["UserId"])

---
**Ready to test? Start with step 1 above!** ??
