# ?? Filter Chart Not Showing - Debug Guide

## Problem
When you select "Skincare" from the category filter, the purple filter chart section does not appear.

## Quick Diagnosis

### 1. Open Browser Console (F12)

When you select "Skincare" filter, you should see these console logs:

```
?? applyFilters called: { category: "Skincare", startDate: "", endDate: "" }
?? loadFilteredDashboardData started
   Active filters: { category: "Skincare", startDate: null, endDate: null }
? PageMethods exists
? GetFilteredDashboardData method exists
?? Sending PageMethods request: { category: "Skincare", startDate: null, endDate: null }
?? SUCCESS CALLBACK - Response received
?? updateDashboardWithFilteredData START
   Step 2: Updating filter results section...
? Filter results section updated
```

### 2. If You DON'T See These Logs

**Run this in Browser Console:**

```javascript
// Test if PageMethods exists
console.log('PageMethods:', typeof PageMethods);
console.log('PageMethods.GetFilteredDashboardData:', typeof PageMethods.GetFilteredDashboardData);

// Test if filter section exists
console.log('Filter section:', document.getElementById('filterResultsSection'));

// Test if filter chart canvas exists
console.log('Filter chart canvas:', document.getElementById('filterChart'));

// Manually trigger filter (replace "Skincare" with your category)
document.getElementById('categoryFilter').value = 'Skincare';
applyFilters();
```

### 3. Check Network Tab

1. Open **Network** tab in DevTools (F12)
2. Select "Skincare" filter
3. Look for request to `/WebPages/Dashboard.aspx/GetFilteredDashboardData`
4. Check if:
   - Request is being sent ?
   - Response is successful (Status 200) ?
   - Response contains data ?

### 4. Common Issues

#### Issue A: PageMethods Not Defined
**Symptom:** `PageMethods is undefined` error

**Solution:** Make sure `ScriptManager` with `EnablePageMethods` is in your page:

```aspx
<asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />
```

**Location:** Should be in `Admin/Admin.master` or `Dashboard.aspx`

---

#### Issue B: Filter Section Not Showing (CSS Issue)
**Symptom:** Console logs show "? Filter results section updated" but nothing appears

**Solution:** Check if section is hidden by CSS:

```javascript
// Run in console
var section = document.getElementById('filterResultsSection');
console.log('Section display:', section.style.display);
console.log('Section classes:', section.className);
console.log('Section offsetHeight:', section.offsetHeight);

// Force show it
section.classList.add('show');
section.style.display = 'block';
```

---

#### Issue C: Chart Not Rendering (Chart.js Issue)
**Symptom:** Purple section appears but chart is blank

**Solution:** Check if Chart.js is loaded:

```javascript
// Run in console
console.log('Chart.js loaded:', typeof Chart);

// Check chart canvas
var canvas = document.getElementById('filterChart');
console.log('Canvas:', canvas);
console.log('Canvas context:', canvas ? canvas.getContext('2d') : 'NO CANVAS');

// Check chart instance
console.log('Filter chart instance:', filterChartInstance);
```

---

#### Issue D: WebMethod Not Being Called
**Symptom:** No network request in Network tab

**Solution:** Check if `GetFilteredDashboardData` WebMethod exists:

```csharp
// In Dashboard.aspx.cs, verify this method exists:
[WebMethod(EnableSession = true)]
[System.Web.Script.Services.ScriptMethod(ResponseFormat = System.Web.Script.Services.ResponseFormat.Json)]
public static object GetFilteredDashboardData(string category, string startDate, string endDate)
{
    // ... method body
}
```

---

## ?? Manual Testing Steps

### Step 1: Test Filter Section Visibility

```javascript
// Copy and paste this into browser console:
(function() {
    console.log('=== FILTER SECTION DEBUG ===');
    
    var section = document.getElementById('filterResultsSection');
    console.log('1. Section exists:', !!section);
    
    if (section) {
        console.log('2. Section display:', section.style.display);
        console.log('3. Section classes:', section.className);
        console.log('4. Section offsetHeight:', section.offsetHeight);
        console.log('5. Section computed display:', window.getComputedStyle(section).display);
        
        // Force show
        section.classList.add('show');
        section.style.display = 'block';
        section.style.visibility = 'visible';
        
        console.log('6. ? Manually showed section');
        console.log('7. Section offsetHeight after show:', section.offsetHeight);
    }
    
    var canvas = document.getElementById('filterChart');
    console.log('8. Canvas exists:', !!canvas);
    
    console.log('=== END DEBUG ===');
})();
```

### Step 2: Test Data Loading

```javascript
// Copy and paste this into browser console:
(function() {
    console.log('=== DATA LOADING DEBUG ===');
    
    console.log('1. PageMethods:', typeof PageMethods);
    console.log('2. GetFilteredDashboardData:', typeof PageMethods.GetFilteredDashboardData);
    
    // Test with Skincare filter
    console.log('3. Testing PageMethods call...');
    
    PageMethods.GetFilteredDashboardData(
        'Skincare',  // category
        null,        // startDate
        null,        // endDate
        function(result) {
            console.log('4. ? SUCCESS - Got result:', result);
            console.log('5. result.salesData:', result.salesData);
            console.log('6. result.dashboardStats:', result.dashboardStats);
            
            if (result.salesData && result.salesData.custom) {
                console.log('7. ? Custom data exists');
                console.log('8. Labels:', result.salesData.custom.labels);
                console.log('9. Data:', result.salesData.custom.data);
            } else {
                console.log('7. ? No custom data!');
            }
        },
        function(error) {
            console.error('4. ? ERROR:', error);
        }
    );
    
    console.log('=== END DEBUG ===');
})();
```

### Step 3: Test Chart Rendering

```javascript
// Copy and paste this into browser console:
(function() {
    console.log('=== CHART RENDERING DEBUG ===');
    
    console.log('1. Chart.js loaded:', typeof Chart);
    
    var canvas = document.getElementById('filterChart');
    console.log('2. Canvas exists:', !!canvas);
    
    if (canvas) {
        console.log('3. Canvas context:', !!canvas.getContext('2d'));
        
        // Try to create a simple test chart
        try {
            var ctx = canvas.getContext('2d');
            var testChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['Jan', 'Feb', 'Mar'],
                    datasets: [{
                        label: 'Test',
                        data: [10, 20, 30],
                        borderColor: '#FF6B35'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
            console.log('4. ? Test chart created:', testChart);
        } catch (error) {
            console.error('4. ? Chart creation failed:', error);
        }
    }
    
    console.log('=== END DEBUG ===');
})();
```

---

## ?? Expected Behavior

When you select "Skincare" filter:

1. ? **Network request** to `GetFilteredDashboardData` is made
2. ? **Response received** with filtered data
3. ? **Purple section appears** with animated slide-down
4. ? **Chart renders** showing Skincare sales data
5. ? **Stats update** showing filtered totals

---

## ?? Screenshot Checklist

If filter chart still not showing, take screenshots of:

1. **Browser Console** (F12 ? Console tab) after selecting filter
2. **Network Tab** (F12 ? Network tab) showing request/response
3. **Elements Tab** (F12 ? Elements tab) showing `#filterResultsSection` HTML
4. **Computed CSS** for `#filterResultsSection` element

Send these to developer for diagnosis.

---

## ?? Emergency Fix (Temporary)

If nothing works, add this to the page to force show the section:

```aspx
<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script>
// ?? EMERGENCY FIX: Force show filter section after 3 seconds
setTimeout(function() {
    console.log('?? Emergency fix: Showing filter section...');
    
    var section = document.getElementById('filterResultsSection');
    if (section) {
        section.classList.add('show');
        section.style.display = 'block';
        section.style.visibility = 'visible';
        
        // Create dummy data
        var dummyData = {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            data: [100, 150, 120, 180, 160, 200],
            lastYearData: [80, 120, 100, 150, 140, 180],
            dateRange: 'Test Range'
        };
        
        // Update filter chart with dummy data
        updateFilterChart(dummyData);
        
        console.log('? Emergency fix applied!');
    }
}, 3000);
</script>
</asp:Content>
```

---

## ?? Checklist

Run through these checks:

- [ ] Browser console shows no JavaScript errors
- [ ] PageMethods is defined
- [ ] GetFilteredDashboardData method exists
- [ ] Filter section HTML exists in page
- [ ] Filter chart canvas exists
- [ ] Chart.js is loaded
- [ ] Network request is being made
- [ ] Response contains valid data
- [ ] Filter section has `.show` class when active
- [ ] Chart instance is being created

---

## ?? Still Not Working?

If you've checked everything above and it still doesn't work:

1. **Clear browser cache** (Ctrl + Shift + Delete)
2. **Restart IIS** if using IIS
3. **Restart Visual Studio**
4. **Rebuild solution** (Ctrl + Shift + B)
5. **Check for JavaScript conflicts** with other libraries

---

**Need Help?** Run the diagnostic scripts above and share the console output for further analysis.
