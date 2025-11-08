# Product Profile - Overall Product Performance PDF Implementation

## Overview
The "Overall Product Performance" button on the Product Profile page generates a comprehensive PDF report for ALL variants of the current product (not all products in the system).

## What's Been Done

### 1. **Button Added to ProductProfile.aspx**
? Purple "Overall Product Performance" button added to the Sales Analytics header
- Located just below the product information section
- Styled with purple gradient to differentiate from the orange single-variant PDF button

### 2. **Modal Created (NOT YET - Needs to be added)**
The modal HTML needs to be added to ProductProfile.aspx before the closing `</form>` tag.

### 3. **JavaScript Functions (NOT YET - Needs to be added)**
JavaScript functions need to be added to handle the modal and PDF generation.

### 4. **Backend Handler (ALREADY CREATED)**
? `GenerateOverallProductPerformancePDF.ashx.cs` - Handles PDF generation for ALL products
- This needs to be modified or a new handler created specifically for ProductProfile

## What Needs to Be Done

### Step 1: Add the Modal HTML to ProductProfile.aspx

Add this BEFORE the closing `</form>` tag (after the print options modal):

```html
<!-- ?? Overall Product Performance Modal -->
<div id="overallProductPerformanceModal" class="print-modal-overlay">
    <div class="print-modal-container">
        <div class="print-modal-header" style="background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%);">
            <h2 class="print-modal-title">
                <i class="fas fa-chart-line"></i>
                Overall Product Performance
            </h2>
            <button class="print-modal-close" onclick="closeOverallProductPerformanceModal()">
                <i class="fa fa-times"></i>
            </button>
        </div>
        
        <div class="print-modal-body">
            <div class="print-option-section">
                <div class="print-option-title">Select Report Type</div>
                
                <!-- Option 1: Standard Periods -->
                <div class="print-option-card" id="overallStandardPeriodsOption" onclick="selectOverallPrintOption('standard')">
                    <div class="print-option-label">
                        <i class="fas fa-calendar-alt" style="color: #9C27B0;"></i>
                        Standard Periods
                    </div>
                    <p class="print-option-description">
                        Complete report with Daily, Weekly, and Monthly analysis for all variants
                    </p>
                </div>
                
                <!-- Option 2: Custom Date Range -->
                <div class="print-option-card" id="overallCustomDateOption" onclick="selectOverallPrintOption('custom')">
                    <div class="print-option-label">
                        <i class="fas fa-calendar-week" style="color: #9C27B0;"></i>
                        Custom Date Range
                    </div>
                    <p class="print-option-description">
                        Generate report for a specific date range for all variants
                    </p>
                    
                    <!-- Date Range Inputs -->
                    <div id="overallDateRangeInputs" class="date-range-inputs">
                        <div class="date-input-group">
                            <label class="date-input-label" for="overallStartDate">
                                <i class="fas fa-calendar-day"></i> Start Date
                            </label>
                            <input type="date" id="overallStartDate" class="date-input" />
                        </div>
                        
                        <div class="date-input-group">
                            <label class="date-input-label" for="overallEndDate">
                                <i class="fas fa-calendar-check"></i> End Date
                            </label>
                            <input type="date" id="overallEndDate" class="date-input" />
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="print-modal-footer">
            <button type="button" class="print-modal-btn print-modal-btn-secondary" onclick="closeOverallProductPerformanceModal()">
                <i class="fa fa-times"></i>
                <span>Cancel</span>
            </button>
            <button type="button" class="print-modal-btn print-modal-btn-primary" id="btnGenerateOverallPDF" onclick="generateOverallProductPerformancePdf()" style="background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%); box-shadow: 0 4px 15px rgba(156, 39, 176, 0.3);">
                <i class="fas fa-file-pdf"></i>
                <span>Generate Report</span>
            </button>
        </div>
    </div>
</div>
```

### Step 2: Add JavaScript Functions

Add these functions to the existing script block in ProductProfile.aspx (before the closing `</script>` tag):

```javascript
// ===== OVERALL PRODUCT PERFORMANCE MODAL FUNCTIONS =====
var selectedOverallPrintOption = 'standard';

window.openOverallProductPerformanceModal = function(){
    var modal = document.getElementById('overallProductPerformanceModal');
    if(modal){
        modal.classList.add('show');
        document.body.style.overflow = 'hidden';
        
        // Set default option
        selectOverallPrintOption('standard');
        
        // Set default dates (last 30 days)
        var today = new Date();
        var thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(today.getDate() - 30);
        
        document.getElementById('overallEndDate').valueAsDate = today;
        document.getElementById('overallStartDate').valueAsDate = thirtyDaysAgo;
    }
};

window.closeOverallProductPerformanceModal = function(){
    var modal = document.getElementById('overallProductPerformanceModal');
    if(modal){
        modal.classList.remove('show');
        document.body.style.overflow = '';
    }
};

window.selectOverallPrintOption = function(option){
    selectedOverallPrintOption = option;
    
    var standardCard = document.getElementById('overallStandardPeriodsOption');
    var customCard = document.getElementById('overallCustomDateOption');
    var dateInputs = document.getElementById('overallDateRangeInputs');
    
    if(standardCard) standardCard.classList.remove('selected');
    if(customCard) customCard.classList.remove('selected');
    if(dateInputs) dateInputs.classList.remove('show');
    
    if(option === 'standard' && standardCard){
        standardCard.classList.add('selected');
    } else if(option === 'custom'){
        if(customCard) customCard.classList.add('selected');
        if(dateInputs) dateInputs.classList.add('show');
    }
};

window.generateOverallProductPerformancePdf = function(){
    var btn = document.getElementById('btnGenerateOverallPDF');
    if(!btn) return;
    
    // Get product ID from URL
    var urlParams = new URLSearchParams(window.location.search);
    var productId = urlParams.get('id');
    
    if(!productId){
        alert('Product ID not found. Please navigate from a product page.');
        return;
    }
    
    log('[generateOverallProductPerformancePdf] Product ID:', productId);
    
    var url = '../Handlers/GenerateProductProfilePerformancePDF.ashx?productId=' + encodeURIComponent(productId);
    
    // Validate custom date range if selected
    if(selectedOverallPrintOption === 'custom'){
        var startDate = document.getElementById('overallStartDate').value;
        var endDate = document.getElementById('overallEndDate').value;
        
        if(!startDate || !endDate){
            alert('Please select both start and end dates.');
            return;
        }
        
        var start = new Date(startDate);
        var end = new Date(endDate);
        
        if(start > end){
            alert('Start date must be before end date.');
            return;
        }
        
        url += '&type=custom&startDate=' + encodeURIComponent(startDate) + '&endDate=' + encodeURIComponent(endDate);
        log('[generateOverallProductPerformancePdf] Custom date range:', startDate, 'to', endDate);
    } else {
        url += '&type=standard';
        log('[generateOverallProductPerformancePdf] Standard periods report');
    }
    
    // Show loading state
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span> Generating...</span>';
    
    log('[generateOverallProductPerformancePdf] Opening PDF URL:', url);
    
    // Open PDF in new window
    window.open(url, '_blank');
    
    // Reset button after a short delay
    setTimeout(function(){
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-file-pdf"></i><span>Generate Report</span>';
        closeOverallProductPerformanceModal();
        log('[generateOverallProductPerformancePdf] PDF generation complete');
    }, 2000);
};
```

### Step 3: Create New Handler for Product Profile Performance

Create two files:

**File 1: `InventorySystemSiaProject/Handlers/GenerateProductProfilePerformancePDF.ashx`**

```xml
<%@ WebHandler Language="C#" CodeBehind="GenerateProductProfilePerformancePDF.ashx.cs" Class="InventorySystemSiaProject.Handlers.GenerateProductProfilePerformancePDF" %>
```

**File 2: `InventorySystemSiaProject/Handlers/GenerateProductProfilePerformancePDF.ashx.cs`**

This handler will:
1. Accept a `productId` parameter
2. Fetch all variants for that product
3. Aggregate sales data for all variants
4. Generate a comprehensive PDF report

## Key Differences from Dashboard Report

| Aspect | Dashboard Report | Product Profile Report |
|--------|-----------------|----------------------|
| **Scope** | ALL products in system | ONE product + all its variants |
| **Data** | System-wide sales | Product-specific sales |
| **Variants** | Aggregated | Individual + Combined |
| **Parameter** | None | `productId` required |
| **Color** | Orange gradient | Purple gradient |

## Usage Flow

1. User navigates to Product Profile page (e.g., `ProductProfile.aspx?id=67890b5dae81c28e2ab23456`)
2. User clicks purple "Overall Product Performance" button
3. Modal opens with two options:
   - **Standard Periods**: Daily (7 days), Weekly (4 weeks), Monthly (12 months)
   - **Custom Date Range**: User specifies start/end dates
4. User clicks "Generate Report"
5. System:
   - Extracts `productId` from URL
   - Fetches all variants for that product
   - Aggregates sales data across all variants
   - Generates PDF with:
     - Product overview
     - Combined sales across all variants
     - Individual variant performance
     - Top performing variants
     - Low stock alerts for variants
6. PDF opens in new tab

## Example PDF Content

### Title Page
```
Overall Product Performance
Glow Serum Collection

Total Variants: 3
- 30ml (Low Stock: 5 units)
- 50ml (Normal Stock: 25 units)
- 100ml (Normal Stock: 40 units)

Generated: January 10, 2025 14:30
```

### Daily Performance (Last 7 Days)
```
Date       | All Variants | 30ml | 50ml | 100ml
-----------|-------------|------|------|-------
Jan 04     | 12          | 3    | 5    | 4
Jan 05     | 15          | 4    | 6    | 5
...
```

### Monthly Performance (Last 12 Months)
```
Month    | All Variants | Top Variant
---------|-------------|-------------
Jan 2024 | 45          | 50ml (20)
Feb 2024 | 52          | 100ml (25)
...
```

### Variant Comparison
```
Variant | Total Sales | Avg/Day | Stock | Status
--------|------------|---------|-------|--------
50ml    | 145        | 20.7    | 25    | Normal
100ml   | 132        | 18.9    | 40    | Normal
30ml    | 89         | 12.7    | 5     | ?? LOW
```

## Files to Create/Modify

- [x] `ProductProfile.aspx` - Add button (DONE)
- [ ] `ProductProfile.aspx` - Add modal HTML
- [ ] `ProductProfile.aspx` - Add JavaScript functions
- [ ] `GenerateProductProfilePerformancePDF.ashx` - New handler file
- [ ] `GenerateProductProfilePerformancePDF.ashx.cs` - New handler implementation

## Testing Checklist

- [ ] Button appears on Product Profile page
- [ ] Clicking button opens purple modal
- [ ] Standard option selected by default
- [ ] Custom option shows date inputs
- [ ] Date validation works (start < end)
- [ ] PDF generates for standard periods
- [ ] PDF generates for custom date range
- [ ] PDF includes all product variants
- [ ] PDF shows correct product name
- [ ] PDF shows variant-level breakdown
- [ ] Low stock variants highlighted
- [ ] Charts render correctly
- [ ] Tables show correct totals

## Next Steps

1. ? Button added to ProductProfile.aspx
2. ? Add modal HTML to ProductProfile.aspx
3. ? Add JavaScript functions to ProductProfile.aspx
4. ? Create GenerateProductProfilePerformancePDF.ashx
5. ? Create GenerateProductProfilePerformancePDF.ashx.cs
6. ? Test with real product data

---
**Status:** In Progress (Step 1 Complete)  
**Last Updated:** January 10, 2025  
**Developer Notes:** The GenerateOverallProductPerformancePDF.ashx currently generates reports for ALL products. We need a new handler that accepts a productId parameter and generates reports only for that product's variants.
