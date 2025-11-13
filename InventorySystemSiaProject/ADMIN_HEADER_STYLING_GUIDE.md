# Admin Header Styling Guide

## Overview
This document provides styling information for the Admin Master page header that displays the logged-in admin's information.

## Header Structure

### Layout Components
The header consists of three main sections:

1. **Logo Section** (Left)
   - SheEssentials logo with gem icon
   - Fallback text display

2. **Search Bar** (Center)
   - Full-width search input
   - Search icon on the left
   - Expands to fill available space

3. **User Profile & Notifications** (Right)
   - User profile dropdown
   - Notification bell with badge
   - User avatar and name

## CSS Classes Reference

### Header Container
```css
.admin-header
```
- Full-width white background
- Flexbox layout
- Border bottom with shadow
- Responsive padding

### Logo Section
```css
.admin-header-logo
.header-logo-fallback
```
- Displays logo or fallback text
- Gem icon with "SheEssentials" text
- Rose brown color (#A36A66)

### Search Bar
```css
.admin-header-search
.search-icon
.header-search-input
```
- Rounded input field
- Search icon positioned absolutely
- Light gray background (#F8F8F8)
- Focus state with rose brown border

### User Profile
```css
.admin-user-profile
.admin-avatar
.admin-username
.dropdown-arrow
```
- Clickable profile section
- Circular avatar with gradient
- Username display
- Chevron down icon

### User Dropdown Menu
```css
.user-dropdown-menu
.user-dropdown-header
.user-dropdown-avatar
.user-dropdown-info
.user-dropdown-item
```
- Hidden by default
- Shows on click with animation
- Contains user details and actions
- Profile Settings and Logout options

### Notifications
```css
.admin-notifications
.notification-icon
.notification-badge
```
- Bell icon
- Red badge with count
- Hover effect

## Color Scheme

| Element | Color | Hex Code |
|---------|-------|----------|
| Primary | Rose Brown | `#A36A66` |
| Secondary | Coral | `#FFA593` |
| Background | White | `#FFFFFF` |
| Light Background | Off White | `#F8F8F8` |
| Border | Light Gray | `#E5E5E5` |
| Text | Dark Gray | `#333333` |
| Secondary Text | Medium Gray | `#666666` |
| Tertiary Text | Light Gray | `#999999` |
| Error/Logout | Red | `#DC3545` |

## Typography

- **Font Family**: Poppins (with Arial, Helvetica fallbacks)
- **Logo**: 1.1rem, weight 600
- **Search Input**: 0.9rem
- **Username**: 0.9rem, weight 500
- **Dropdown Name**: 0.95rem, weight 600
- **Dropdown Email**: 0.8rem
- **Dropdown Role**: 0.75rem

## Responsive Behavior

### Desktop (> 768px)
- Full horizontal layout
- Search bar in center
- Username visible
- All elements in single row

### Mobile (? 768px)
- Stacked layout
- Logo and user profile on top row
- Search bar below (full width)
- Username hidden
- Dropdown menu adjusted position

## JavaScript Functionality

### User Dropdown Toggle
```javascript
function toggleUserDropdown(event)
```
- Toggles dropdown visibility
- Prevents event propagation
- Adds/removes 'show' class

### Click Outside Handler
- Closes dropdown when clicking outside
- Attached to document
- Checks if click is within user profile

## ASP.NET Controls

### TextBox Rendering
```aspx
<asp:TextBox ID="txtHeaderSearch" runat="server" CssClass="header-search-input" />
```
Renders as:
```html
<input type="text" id="MainContent_txtHeaderSearch" class="header-search-input" />
```

### LinkButton Rendering
```aspx
<asp:LinkButton ID="btnProfileSettings" runat="server" CssClass="user-dropdown-item" />
```
Renders as:
```html
<a id="MainContent_btnProfileSettings" class="user-dropdown-item" href="javascript:__doPostBack(...)">
```

## Troubleshooting

### Issue: CSS Not Applied
**Solution**: Clear browser cache or add cache-busting parameter
```aspx
<link href="../Content/adminmaster.css?v=<%= DateTime.Now.Ticks %>" />
```

### Issue: Search Input Not Styled
**Cause**: ASP.NET TextBox renders with additional attributes
**Solution**: Multiple CSS selectors added:
```css
html body .header-search-input,
html body input.header-search-input,
html body input[type="text"].header-search-input,
html body .admin-header-search input[type="text"]
```

### Issue: Dropdown Not Showing
**Cause**: JavaScript not executing or CSS class not toggling
**Solution**: 
1. Check browser console for errors
2. Verify JavaScript is after form closing tag
3. Ensure `toggleUserDropdown` function is defined

### Issue: User Info Not Displaying
**Cause**: Session variables not set or null
**Solution**: Check Login.aspx.cs:
```csharp
Session["UserId"] = user.Id;
Session["UserName"] = user.Name;
Session["UserEmail"] = user.Email;
Session["UserRole"] = user.Role;
```

## Session Requirements

The header requires these session variables to be set:
- `Session["UserId"]` - User authentication
- `Session["UserName"]` - Display name
- `Session["UserEmail"]` - Email address
- `Session["UserRole"]` - User role (Admin, etc.)

If `Session["UserId"]` is null, user is redirected to Login page.

## Browser Compatibility

? Chrome (Latest)
? Firefox (Latest)
? Safari (Latest)
? Edge (Latest)
?? IE11 (May require polyfills)

## Performance Notes

- CSS uses `!important` for maximum specificity
- Animations use `cubic-bezier` for smooth transitions
- Dropdown uses CSS transforms for GPU acceleration
- Icons loaded from Font Awesome CDN

## Future Enhancements

Potential improvements:
1. Real-time notification system
2. Search autocomplete functionality
3. User profile picture upload
4. Dark mode toggle
5. Keyboard shortcuts (Ctrl+K for search)
6. Mobile hamburger menu integration

## Related Files

- `Admin.master` - Master page markup
- `Admin.master.cs` - Code-behind with session properties
- `adminmaster.css` - All styling
- `Login.aspx.cs` - Sets session variables

## Support

For issues or questions, refer to:
- `ADMIN_HEADER_IMPLEMENTATION.md` - Implementation details
- ASP.NET Web Forms documentation
- Font Awesome icon reference
