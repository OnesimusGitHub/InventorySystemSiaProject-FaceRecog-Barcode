# Stock Status Filter - Testing Guide

## ?? Quick Test Checklist

### Initial Load
- [ ] Navigate to Dashboard page
- [ ] Verify pie chart shows real stock numbers
- [ ] Check "All" button is active by default
- [ ] Confirm chart shows all three segments (Normal/Low/Out)

### Test "Low" Filter
1. Click the **"Low"** button
2. Expected behavior:
   - ? Button becomes active (highlighted)
   - ? Chart updates to show only Low + Out of Stock
   - ? Normal stock segment grays out
   - ? Counter updates to show: "X low/out of stock items"
   - ? Console shows: "?? Stock filter changed to: Low"

### Test "Normal" Filter
1. Click the **"Normal"** button
2. Expected behavior:
   - ? Button becomes active (highlighted)
   - ? Chart updates to show only Normal stock
   - ? Low and Out segments gray out
   - ? Counter updates to show: "X items in normal stock"
   - ? Console shows: "?? Stock filter changed to: Normal"

### Test "All" Filter
1. Click the **"All"** button
2. Expected behavior:
   - ? Button becomes active (highlighted)
   - ? Chart shows all segments in full color
   - ? Counter shows: "X items need attention"
   - ? Console shows: "?? Stock filter changed to: All"

## ?? Visual Indicators

### All Filter (Default)
```
Chart Colors:
- Normal: Dark grey (#333) ???????
- Low: Medium grey (#999) ????
- Out: Light grey (#ccc) ??

Counter: Shows (Low + Out) items
Text: "X items need attention"
```

### Low Filter
```
Chart Colors:
- Normal: Disabled (#e0e0e0) ???????
- Low: Medium grey (#999) ????
- Out: Light grey (#ccc) ??

Counter: Shows (Low + Out) items
Text: "X low/out of stock items"
```

### Normal Filter
```
Chart Colors:
- Normal: Dark grey (#333) ???????
- Low: Disabled (#e0e0e0) ????
- Out: Disabled (#e0e0e0) ??

Counter: Shows Normal items only
Text: "X items in normal stock"
```

## ?? Developer Testing (F12 Console)

### Check Filter Parameter
```javascript
// After clicking a button, check the fetch URL
Network tab ? Find GetStockStats.ashx request
Should see: ?filter=Low or ?filter=Normal or ?filter=All
```

### Check Response Data
```javascript
// Console should show:
? Stock stats loaded: {
    success: true,
    normalStock: 45,
    lowStock: 12,
    outOfStock: 3,
    totalItems: 60,
    filteredCount: 15,
    appliedFilter: "Low"
}
```

### Check Chart Update
```javascript
// Console should show:
? Stock status chart updated with filter: Low
```

## ?? Troubleshooting

### Chart not updating?
1. Check console for errors
2. Verify `window.stockStatusChart` exists
3. Check button has correct `data-period` attribute
4. Verify handler is returning data

### Wrong numbers showing?
1. Check handler logic for filter parameter
2. Verify database has correct stock levels
3. Check variant IsActive flags
4. Verify product Status is "Active" or null

### Filter button not working?
1. Check button event listener in `setupPeriodSelectors()`
2. Verify `loadStockStats()` is being called
3. Check button CSS classes (should have `.active`)
4. Verify `data-period` attribute matches filter values

## ?? Test Scenarios

### Scenario 1: Empty Stock
- Set all variants to 0 stock
- Expected: All items in "Out of Stock"
- Low filter: Shows all items
- Normal filter: Shows 0 items

### Scenario 2: All Normal Stock
- Set all variants above minimum
- Expected: All items in "Normal"
- Low filter: Shows 0 items
- Normal filter: Shows all items

### Scenario 3: Mixed Stock
- Some variants normal, some low, some out
- Expected: Pie chart shows distribution
- Each filter shows correct subset

## ?? Test Results Template

```
Test Date: ____________
Tester: ____________

Initial Load:
- Pie chart displays: [ ] Pass [ ] Fail
- Real numbers shown: [ ] Pass [ ] Fail
- All button active: [ ] Pass [ ] Fail

Low Filter:
- Button activates: [ ] Pass [ ] Fail
- Chart updates: [ ] Pass [ ] Fail
- Text changes: [ ] Pass [ ] Fail
- Numbers correct: [ ] Pass [ ] Fail

Normal Filter:
- Button activates: [ ] Pass [ ] Fail
- Chart updates: [ ] Pass [ ] Fail
- Text changes: [ ] Pass [ ] Fail
- Numbers correct: [ ] Pass [ ] Fail

All Filter:
- Button activates: [ ] Pass [ ] Fail
- Chart updates: [ ] Pass [ ] Fail
- Text changes: [ ] Pass [ ] Fail
- Numbers correct: [ ] Pass [ ] Fail

Notes:
_________________________________
_________________________________
_________________________________
```

## ? Success Criteria

All filters must:
1. ? Update button active state
2. ? Fetch new data from handler
3. ? Update pie chart visually
4. ? Update counter number
5. ? Update info text
6. ? Log to console
7. ? Complete in < 1 second
8. ? Handle errors gracefully

## ?? Quick Manual Test

```javascript
// Paste in browser console to test:

// Test Low filter
document.querySelector('[data-period="Low"]').click();

// Test Normal filter  
document.querySelector('[data-period="Normal"]').click();

// Test All filter
document.querySelector('[data-period="All"]').click();

// Check chart instance
console.log('Chart exists:', !!window.stockStatusChart);

// Check current data
console.log('Current chart data:', window.stockStatusChart.data.datasets[0].data);
```

## ?? Support

If issues persist:
1. Check browser console (F12)
2. Verify MongoDB connection
3. Check handler response in Network tab
4. Verify product/variant data in database
5. Clear browser cache and reload
