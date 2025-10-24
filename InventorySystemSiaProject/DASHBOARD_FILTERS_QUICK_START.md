# Quick Start: Dashboard Filtering

## How to Use the New Dashboard Filters

### Basic Usage

#### 1. Filter by Product Category
```
1. Navigate to Dashboard page
2. Look for "Product Category" dropdown in filter controls
3. Select a category (Skincare, Makeup, Haircare, etc.)
4. Click "Apply Filters" button
5. Dashboard updates to show only that category's data
```

#### 2. Filter by Date Range
```
1. Click on "Start Date" picker
2. Select your desired start date
3. Click on "End Date" picker
4. Select your desired end date
5. Click "Apply Filters" button
6. Dashboard updates to show data for that date range
```

#### 3. Combine Filters
```
1. Select a category from dropdown
2. Choose start and end dates
3. Click "Apply Filters" button
4. Dashboard shows data for that category within that date range
```

#### 4. Remove Filters
```
Option 1 - Remove All:
  - Click "Reset" button

Option 2 - Remove Individual Filter:
  - Click the X icon on the filter tag you want to remove
  - Dashboard automatically updates
```

### Generating Filtered PDF Reports

#### Standard Report with Filter
```
1. Apply your desired filters (category and/or date range)
2. Click "Print PDF Report" button
3. Select "Standard Periods" option
4. Click "Generate PDF"
5. PDF opens in new tab with filtered data
6. Filename includes category (e.g., Dashboard_Skincare_Report_20231215.pdf)
```

#### Custom Date Range Report with Category
```
1. Apply category filter first
2. Click "Print PDF Report" button
3. Select "Custom Date Range" option
4. Choose date range in the modal
5. Click "Generate PDF"
6. PDF includes both category and date range in title
```

## Visual Guide

### Filter Controls Location
```
???????????????????????????????????????????????????????
? Dashboard Header                                    ?
?   Current Date: December 15, 2023                  ?
?   Overall Sales                [Print PDF Report]   ?
???????????????????????????????????????????????????????
? FILTER CONTROLS:                                    ?
?                                                     ?
? Product Category  Start Date    End Date           ?
? [All Categories?] [?? Select] [?? Select]          ?
?                   [Apply Filters] [Reset]           ?
???????????????????????????????????????????????????????
? Active Filters:                                     ?
? [Category: Skincare X] [From: Jan 1, 2023 X]       ?
???????????????????????????????????????????????????????
? Sales Chart                                         ?
? ...                                                 ?
???????????????????????????????????????????????????????
```

### Filter Tags
When filters are active, you'll see tags like:
- `[Category: Skincare X]`
- `[From: Jan 15, 2023 X]`
- `[To: Mar 31, 2023 X]`

Click the `X` to remove individual filters.

## Common Scenarios

### Scenario 1: Monthly Performance Review
**Goal**: See how Skincare products performed in November 2023
```
Steps:
1. Category: Select "Skincare"
2. Start Date: 2023-11-01
3. End Date: 2023-11-30
4. Click "Apply Filters"
5. Review dashboard metrics
6. Generate PDF for records
```

### Scenario 2: Quarterly Analysis
**Goal**: Compare Makeup sales Q1 vs Q2
```
Q1 Analysis:
1. Category: "Makeup"
2. Start Date: 2023-01-01
3. End Date: 2023-03-31
4. Apply and note metrics
5. Generate PDF

Q2 Analysis:
1. Keep Category: "Makeup"
2. Change Start Date: 2023-04-01
3. Change End Date: 2023-06-30
4. Apply and compare
5. Generate PDF
```

### Scenario 3: Year-over-Year Comparison
**Goal**: Compare 2022 vs 2023 for all products
```
2022 Data:
1. Category: "All Categories"
2. Start Date: 2022-01-01
3. End Date: 2022-12-31
4. Review and save PDF

2023 Data:
1. Keep Category: "All Categories"
2. Start Date: 2023-01-01
3. End Date: 2023-12-31
4. Review and compare
```

### Scenario 4: Category Performance Snapshot
**Goal**: Quick view of each category's current month
```
For each category (Skincare, Makeup, etc.):
1. Select category
2. Use default date range (last 30 days)
3. Click "Apply Filters"
4. Note key metrics
5. Generate PDF
6. Repeat for next category
```

## Understanding the Data

### Statistics Shown
- **Total Sales**: Sum of all sales in filtered period/category
- **Sales Growth**: % change vs previous period
- **Total Orders**: Number of transactions
- **Order Growth**: % change in order count
- **Total Products**: Number of products in category
- **Low Stock Items**: Variants below minimum stock
- **Active Variants**: Currently active product variants

### Charts Display
- **Daily View**: Shows last 7 days of filtered data
- **Weekly View**: Shows last 4 weeks of filtered data
- **Monthly View**: Shows last 12 months of filtered data
- **Comparison**: Current period vs previous year (blue vs green lines)

## Tips & Tricks

### Tip 1: Default Date Range
If you don't select dates, the system defaults to **last 30 days**.

### Tip 2: Quick Category Switch
To compare categories quickly:
1. Apply first category filter
2. Note the metrics
3. Just change the category dropdown
4. Click "Apply Filters" (date range persists)
5. Compare the results

### Tip 3: Bookmark Common Filters
Once you apply filters, the dashboard state updates. You can:
- Generate PDFs for records
- Take screenshots
- Share URL (future enhancement)

### Tip 4: Troubleshooting
**No data showing after filter?**
- Check if the category has sales in that date range
- Try expanding the date range
- Verify data exists with "Reset" to see all data

**Charts not updating?**
- Click "Apply Filters" again
- Refresh the page
- Check browser console for errors

### Tip 5: Best Practices
- Always apply filters before generating PDFs
- Use descriptive date ranges (full months, quarters)
- Keep PDFs organized by category/date
- Compare similar time periods for accurate trends

## Keyboard Shortcuts (Future)
- `Ctrl + R`: Reset filters
- `Ctrl + P`: Open PDF dialog
- `Ctrl + F`: Focus category filter

## Mobile Usage
Filters are responsive and work on mobile devices:
- Dropdowns adapt to mobile UI
- Date pickers use native mobile datepicker
- Filter tags wrap to multiple lines
- Buttons stack vertically on small screens

## Data Export Options

### Current: PDF Reports
- Standard periods (daily, weekly, monthly)
- Custom date ranges
- Category-specific reports

### Future: Additional Formats
- Excel/CSV export (coming soon)
- JSON data export for analysis
- Email scheduled reports

## Need Help?

### Common Questions

**Q: Can I filter by multiple categories?**
A: Currently, you can select one category at a time. Multi-select is planned for future release.

**Q: What's the maximum date range?**
A: No hard limit, but performance is best with ranges under 2 years.

**Q: Do filters affect PDF reports?**
A: Yes! Active filters automatically apply to PDF generation.

**Q: Can I save my filter settings?**
A: Not yet, but this feature is planned for future release.

**Q: How do I see all data again?**
A: Click the "Reset" button to clear all filters.

## Support

For issues or feature requests:
1. Check the main documentation: `DASHBOARD_FILTERING_IMPLEMENTATION.md`
2. Review the code comments in `Dashboard.aspx.cs`
3. Contact your system administrator

---

**Last Updated**: December 2023
**Version**: 1.0
**Compatibility**: .NET Framework 4.8, MongoDB 4.4+
