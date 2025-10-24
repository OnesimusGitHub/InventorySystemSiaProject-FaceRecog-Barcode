# ?? Quick Fix Reference - Compilation Errors

## Problem: Missing Designer Files

### Symptoms:
```
CS0103: The name 'controlName' does not exist in the current context
```

### Cause:
ASP.NET Web Forms requires a `.designer.cs` file that declares all the controls used in the ASPX page.

### Solution:
Create a designer file with the following template:

```csharp
namespace YourNamespace
{
    public partial class YourPage
    {
        protected global::System.Web.UI.WebControls.ControlType controlName;
    }
}
```

### Example:
```csharp
// CreateIndexes.aspx.designer.cs
namespace InventorySystemSiaProject.Admin
{
    public partial class CreateIndexes
    {
        protected global::System.Web.UI.WebControls.Panel pnlMessage;
        protected global::System.Web.UI.WebControls.Label lblMessage;
    }
}
```

---

## Problem: Missing Properties in Model

### Symptoms:
```
CS1061: 'ClassName' does not contain a definition for 'PropertyName'
```

### Cause:
Code is trying to access a property that doesn't exist in the model class.

### Solution:
Add the missing property to the model:

```csharp
public class Sale
{
    // Add the missing property
    [BsonElement("isActive")]
    public bool IsActive { get; set; } = true;
}
```

---

## Quick Checklist for ASP.NET Web Forms

When creating a new ASPX page:

1. ? Create the `.aspx` file (markup)
2. ? Create the `.aspx.cs` file (code-behind)
3. ? Create the `.aspx.designer.cs` file (control declarations)
4. ? Ensure all controls in ASPX have `runat="server"`
5. ? Ensure all controls have unique `ID` attributes
6. ? Declare all controls in the designer file

---

## Common Control Types

```csharp
// Panels
protected global::System.Web.UI.WebControls.Panel pnlName;

// Labels
protected global::System.Web.UI.WebControls.Label lblName;

// Buttons
protected global::System.Web.UI.WebControls.Button btnName;

// TextBoxes
protected global::System.Web.UI.WebControls.TextBox txtName;

// Literals
protected global::System.Web.UI.WebControls.Literal litName;

// DropDownLists
protected global::System.Web.UI.WebControls.DropDownList ddlName;

// GridViews
protected global::System.Web.UI.WebControls.GridView gvName;

// HtmlForm
protected global::System.Web.UI.HtmlControls.HtmlForm form1;
```

---

## Automatic Designer File Generation

In Visual Studio, you can regenerate designer files:

1. Right-click on the `.aspx` file
2. Select "Convert to Web Application"
3. Designer file will be auto-generated

**Note:** This only works if the ASPX file is properly formatted with all controls having `runat="server"`.

---

## Troubleshooting

### Designer file not being recognized?

1. Clean and rebuild solution
2. Close and reopen Visual Studio
3. Check that the designer file namespace matches the code-behind
4. Verify the `partial class` name matches across all three files

### Controls still not found?

1. Check ASPX directive: `Inherits="InventorySystemSiaProject.Admin.CreateIndexes"`
2. Verify namespace in designer file matches code-behind
3. Ensure control ID in ASPX matches declaration in designer
4. Make sure `runat="server"` is present on the control

---

## Files Fixed in This Session

| File | Issue | Status |
|------|-------|--------|
| `Models/Sale.cs` | Missing IsActive property | ? Fixed |
| `Admin/CreateIndexes.aspx.designer.cs` | File missing | ? Created |

---

**Last Updated:** ${new Date().toLocaleString()}
