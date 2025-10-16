# Dashboard PDF Report Feature

## Overview
A comprehensive PDF report generation feature has been added to the Dashboard page. Users can now generate professional PDF reports of their sales data with customizable options.

## Features

### 1. **Report Button**
- Orange "Print PDF Report" button added to the dashboard header
- Eye-catching gradient design with icon
- Opens a modal dialog for report configuration

### 2. **Modal Dialog**
The PDF report modal provides two report types:

#### Standard Periods Report
- Generates PDF with current period selection (Daily, Weekly, or Monthly)
- Includes the sales chart for the selected period
- Shows comparison with last year's data
- Pre-selected by default

#### Custom Date Range Report
- Allows users to specify a custom start and end date
- Generates daily breakdown for the selected range
- Includes top products sold in that period
- Date validation ensures start date is before end date

### 3. **Generated PDF Contents**

#### Standard Report Includes:
1. **Header Section**
   - BELLE logo and branding
   - Report title
   - Generation timestamp
   - Report type and period information

2. **Key Metrics Dashboard**
   - Total Sales (with styling)
   - Total Orders
   - Total Products
   - Low Stock Items
   - Color-coded cards for easy reading

3. **Sales Performance Chart**
   - Bar chart visualization of sales data
   - Shows selected period (daily/weekly/monthly)
   - Grid lines and value labels
   - Y-axis with currency formatting
   - X-axis with period labels

4. **Product Inventory Summary**
   - List of up to 15 products
   - Shows product name, variant count, total stock, and status
   - Color-coded status indicators (Green = Normal, Red = Low Stock)

#### Custom Range Report Includes:
1. **Header Section** (same as standard)
2. **Period Statistics**
   - Total Sales for the range
   - Total Orders
   - Average Order Value
   - Product Count

3. **Sales Breakdown Chart**
   - Daily sales visualization for the custom range
   - Bar chart with date labels

4. **Top Products Section**
   - Top 10 products by sales in the selected period
   - Shows quantity sold and total sales value
   - Sorted by highest sales first

## Technical Implementation

### Files Modified/Created:

#### 1. **Dashboard.aspx**
- Added PDF report button to dashboard header
- Added modal dialog HTML structure
- Added CSS styling for button and modal
- Added JavaScript functions for modal interactions

#### 2. **GenerateDashboardPDF.ashx** (NEW)
- HTTP handler for PDF generation
- Handles both standard and custom report types

#### 3. **GenerateDashboardPDF.ashx.cs** (NEW)
- Main PDF generation logic using PDFsharp library
- Async processing for better performance
- Multiple helper methods for different report sections

### Key Technologies:
- **PDFsharp**: PDF document generation
- **PdfSharp.Drawing**: Graphics and drawing operations
- **MongoDB**: Data retrieval from Sales, Products, and ProductVariants collections
- **ASP.NET Async Handlers**: For efficient async PDF generation

## User Flow

1. User clicks "Print PDF Report" button on dashboard
2. Modal opens with report type selection
3. User selects either:
   - **Standard Periods**: Automatically uses current dashboard period
   - **Custom Date Range**: User selects start and end dates
4. User clicks "Generate PDF"
5. PDF is generated on the server
6. Browser opens PDF in new tab for viewing/downloading
7. Modal closes automatically after generation

## PDF Features

### Design Elements:
- **Color Scheme**: Matches BELLE brand colors (#A64D79 purple)
- **Professional Layout**: Clean A4 format with proper margins
- **Typography**: Arial font family for readability
- **Visual Elements**:
  - Logo in header
  - Color-coded stat cards
  - Bar charts with gridlines
  - Tables with alternating rows

### Data Visualizations:
- **Bar Charts**: Sales data visualization with proper scaling
- **Stat Cards**: Key metrics with color accents
- **Tables**: Product listings with formatted data
- **Status Indicators**: Color-coded stock status

### Error Handling:
- Graceful fallback for missing data
- Validation of date ranges
- Error messages for invalid inputs
- Default values when no data is available

## Usage Examples

### Generating a Monthly Report:
1. Ensure "Monthly" is selected on dashboard
2. Click "Print PDF Report"
3. Select "Standard Periods"
4. Click "Generate PDF"
5. PDF opens with monthly sales data for last 12 months

### Generating a Custom Period Report:
1. Click "Print PDF Report"
2. Select "Custom Date Range"
3. Set start date (e.g., 2024-01-01)
4. Set end date (e.g., 2024-03-31)
5. Click "Generate PDF"
6. PDF opens with Q1 2024 data

## Browser Compatibility
- ? Chrome/Edge (Chromium)
- ? Firefox
- ? Safari
- ? Opera

## Performance Considerations
- Async processing prevents UI blocking
- Efficient MongoDB queries
- Pagination for large product lists (max 15 per page)
- Optimized chart rendering

## Future Enhancements (Possible)
- Add email functionality to send PDF directly
- Multiple period comparison reports
- Export to other formats (Excel, CSV)
- Scheduled automatic report generation
- Report templates with customizable branding
- Product variant detailed breakdown
- Sales by category analysis
- Supplier performance reports

## Notes
- PDF generation uses server-side rendering (no client-side dependencies)
- Reports are generated on-demand (not cached)
- Date ranges are converted to UTC for consistency
- Charts automatically scale based on data values
- Product images are not included in PDF to keep file size manageable

## Support
For issues or questions about the PDF report feature, please check:
1. Browser console for JavaScript errors
2. Server logs for PDF generation errors
3. Verify MongoDB connection is active
4. Ensure PDFsharp package is properly installed

## Version History
- **v1.0** (Current): Initial release with standard and custom reports
