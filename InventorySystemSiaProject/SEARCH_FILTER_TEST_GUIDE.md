# Quick Test Guide: Search and Filter Features

## ?? 5-Minute Functionality Test

### Test 1: Search Box ?
1. Navigate to Product Page
2. Type "cream" in the search box
3. **Expected:** Products with "cream" in name/SKU/category/supplier show up
4. Clear search box
5. **Expected:** All products reappear

### Test 2: Category Filter ?
1. Click "Filter : All" button
2. Select "Skincare"
3. **Expected:** Only Skincare products visible
4. Button text changes to "Filter : Skincare"
5. Click filter again and select "All"
6. **Expected:** All products reappear

### Test 3: Sort by Price ?
1. Click "Best Seller" button
2. Select "Price (Low to High)"
3. **Expected:** Products sorted by price, cheapest first
4. Select "Price (High to Low)"
5. **Expected:** Products sorted by price, most expensive first

### Test 4: Sort by Stock ?
1. Click sort button
2. Select "Stock (Low to High)"
3. **Expected:** Products with lowest stock appear first
4. **Note:** Good for finding low stock items quickly!

### Test 5: Combined Filters ?
1. Type "lip" in search box
2. Select "Makeup" category
3. Select "Price (Low to High)" sort
4. **Expected:** Makeup products with "lip" in name, sorted by price

### Test 6: No Results ?
1. Search for "xyzabc123" (nonsense term)
2. **Expected:** 
   - "No products found" message appears
   - Clear Filters button shows
3. Click "Clear Filters"
4. **Expected:** All products reappear

## ?? Visual Checks

### Search Box
```
??????????????????????????????????????
? ?? Search products, SKU, or cat... ?
??????????????????????????????????????
```
- Should be responsive
- Should clear on Ctrl+A + Delete
- Should show placeholder text

### Filter Dropdown
```
????????????????????????
? All                  ? ? Currently selected
????????????????????????
? Skincare             ?
? Makeup               ?
? Haircare             ?
? Fragrance            ?
? Body Care            ?
????????????????????????
```
- Should close when clicking outside
- Should highlight on hover
- Should update button text

### Sort Dropdown
```
????????????????????????????
? ?? Name (A-Z)            ?
? ?? Price (Low to High)   ?
? ?? Price (High to Low)   ?
? ?? Stock (Low to High)   ?
? ?? Stock (High to Low)   ?
? ?? Newest First          ?
? ?? Oldest First          ?
????????????????????????????
```
- Should show emoji icons
- Should close after selection
- Should update button text

## ? Performance Test

1. **Load 50+ products** (seed data if needed)
2. **Type in search box**
   - Should debounce (300ms delay)
   - Should not lag
3. **Change filters rapidly**
   - Should update smoothly
   - No JavaScript errors

## ?? Common Issues Check

### Issue: Search doesn't work
- **Check:** Browser console for errors
- **Check:** `txtSearch` control exists
- **Fix:** Refresh page (F5)

### Issue: Dropdowns don't appear
- **Check:** Click button is working
- **Check:** z-index of dropdown
- **Fix:** Inspect element and check CSS

### Issue: Sort not working
- **Check:** Product rows have data attributes
- **Check:** Console for sort errors
- **Fix:** Clear browser cache

### Issue: Filters don't reset
- **Check:** Clear Filters button exists
- **Check:** filterState object is reset
- **Fix:** Manually set filters to default

## ? Pass Criteria

All these should work without errors:
- [ ] Search box filters products
- [ ] Category filter shows correct products
- [ ] Sort reorders products correctly
- [ ] Combined filters work together
- [ ] Clear Filters resets everything
- [ ] No results message appears correctly
- [ ] Dropdowns open and close properly
- [ ] No JavaScript errors in console
- [ ] Performance is smooth
- [ ] Mobile-friendly (if testing on mobile)

## ?? Real-World Scenarios

### Scenario 1: Find Low Stock Skincare Products
```
1. Filter: Skincare
2. Sort: Stock (Low to High)
Result: Easily see which skincare items need restocking
```

### Scenario 2: Find Cheapest Makeup Products
```
1. Filter: Makeup
2. Sort: Price (Low to High)
Result: Budget-friendly makeup options appear first
```

### Scenario 3: Search Specific Product
```
1. Search: "moisturizer"
2. Filter: Skincare
Result: All skincare moisturizers shown
```

### Scenario 4: Recently Added Products
```
1. Sort: Newest First
Result: Most recently added products at top
```

## ?? Expected Results Summary

| Test | Input | Expected Output |
|------|-------|-----------------|
| Search | "serum" | Products with "serum" in name/SKU |
| Filter | "Makeup" | Only makeup category products |
| Sort Price | Low-High | Products ordered by price ? |
| Sort Stock | Low-High | Products ordered by stock ? |
| Combined | "lip" + Makeup + Price | Lip makeup sorted by price |
| No Results | "xyzabc" | "No results" message |
| Clear | Click button | All filters reset |

## ?? If Tests Fail

1. **Check Browser Console (F12)**
   - Look for JavaScript errors
   - Check network requests
   
2. **Verify Elements Exist**
   - Search box has correct ID
   - Filter/Sort buttons exist
   - Product rows have data attributes
   
3. **Clear Browser Cache**
   - Press Ctrl+Shift+Delete
   - Clear cached files
   - Reload page (F5)
   
4. **Check Browser Compatibility**
   - Use modern browser (Chrome, Firefox, Edge)
   - Update browser to latest version
   
5. **Verify Data Attributes**
   - Inspect product rows
   - Check for data-name, data-sku, etc.

## ?? Pro Tips

1. **Quick Search:** Use Ctrl+F to find search box
2. **Clear Search:** Press Escape key in search box
3. **Multiple Filters:** Combine search + category + sort for precise results
4. **Low Stock Alert:** Sort by "Stock (Low to High)" to quickly find items needing restock
5. **Price Comparison:** Sort by price to compare product costs

---

**Test Duration:** 5 minutes  
**Prerequisites:** Products loaded in database  
**Expected Result:** All tests pass ?  
**Status:** Ready to test
