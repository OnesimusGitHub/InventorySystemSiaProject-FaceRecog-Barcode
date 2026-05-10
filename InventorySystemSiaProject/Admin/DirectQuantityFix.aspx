<%@ Page Title="Direct Quantity Fix" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        var role = Session["UserRole"] as string;
        if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
        {
            Response.Redirect("~/WebPages/Login.aspx");
            return;
        }

        if (!IsPostBack)
        {
            btnApplyFix.Text = "?? Apply Quantity Fix Now";
        }
    }

    protected void btnApplyFix_Click(object sender, EventArgs e)
    {
        try
        {
            lblStatus.Text = "Processing... Connecting to database...";
            lblStatus.Visible = true;
            lblStatus.ForeColor = System.Drawing.Color.Blue;

            var collection = Helpers.DatabaseHelper.GetCollection<MongoDB.Bson.BsonDocument>("EmployeeActivities");

            // Total count
            var totalCount = collection.CountDocuments(MongoDB.Driver.FilterDefinition<MongoDB.Bson.BsonDocument>.Empty);

            // Create filter for missing or null quantity
            var filter = MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Or(
                MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Not(
                    MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Exists("quantity")),
                MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Eq("quantity", MongoDB.Bson.BsonNull.Value)
            );

            var matchedCount = collection.CountDocuments(filter);

            if (matchedCount == 0)
            {
                lblStatus.Text = $"? All {totalCount} records already have quantity field. No updates needed.";
                lblStatus.ForeColor = System.Drawing.Color.Green;
                return;
            }

            // Update
            var update = MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Update.Set("quantity", 0);
            var result = collection.UpdateMany(filter, update);

            lblStatus.Text = $"? SUCCESS! Fixed {result.ModifiedCount} out of {matchedCount} records.<br/>Total records: {totalCount}";
            lblStatus.ForeColor = System.Drawing.Color.Green;

            System.Diagnostics.Debug.WriteLine($"[DirectFix] Modified: {result.ModifiedCount}, Matched: {matchedCount}");
        }
        catch (Exception ex)
        {
            lblStatus.Text = $"? ERROR: {ex.Message}<br/><br/>Details: {ex.StackTrace}";
            lblStatus.ForeColor = System.Drawing.Color.Red;

            System.Diagnostics.Debug.WriteLine($"[DirectFix] ERROR: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"[DirectFix] Stack: {ex.StackTrace}");
        }
    }
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Direct Quantity Fix
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div style="max-width: 1000px; margin: 40px auto; padding: 30px; background: #fff; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        
        <h1 style="color: #A86D6A; margin-bottom: 20px;">?? Direct Quantity Column Fix</h1>

        <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #2196F3;">
            <h3 style="color: #1976D2; margin-top: 0;">? Quick Fix</h3>
            <p>This page will directly update your MongoDB database to add the missing <code>quantity</code> field to all EmployeeActivity records.</p>
            <p><strong>What it does:</strong></p>
            <ul>
                <li>Finds all EmployeeActivity records without a quantity field</li>
                <li>Sets their quantity to 0</li>
                <li>Reports how many records were fixed</li>
            </ul>
        </div>

        <div style="margin: 30px 0;">
            <asp:Button ID="btnApplyFix" runat="server" Text="?? Apply Quantity Fix Now" 
                OnClick="btnApplyFix_Click"
                style="padding: 15px 30px; background: #A86D6A; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 18px; font-weight: 600; box-shadow: 0 2px 6px rgba(0,0,0,0.15);" />
        </div>

        <asp:Label ID="lblStatus" runat="server" Visible="false" 
            style="display: block; padding: 15px; border-radius: 8px; margin: 20px 0; font-size: 16px; line-height: 1.6; white-space: pre-wrap;"></asp:Label>

        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin-top: 30px; border-left: 4px solid #ffc107;">
            <h3 style="color: #856404; margin-top: 0;">?? Next Steps</h3>
            <ol style="color: #856404;">
                <li>Click the button above to apply the fix</li>
                <li>Wait for the success message</li>
                <li>Go to <a href="~/WebPages/ActivityLog.aspx" style="color: #856404; font-weight: 600;">Activity Log</a></li>
                <li>Press Ctrl+F5 to refresh</li>
                <li>Check the Quantity column - it should now show numeric values!</li>
            </ol>
        </div>

        <div style="background: #d4edda; padding: 15px; border-radius: 8px; margin-top: 20px; border-left: 4px solid #28a745;">
            <h3 style="color: #155724; margin-top: 0;">? Important Notes</h3>
            <ul style="color: #155724;">
                <li>This operation is <strong>safe</strong> - no data is deleted</li>
                <li>It's <strong>non-destructive</strong> - only adds missing fields</li>
                <li>It can be <strong>run multiple times</strong> with the same result</li>
                <li>All records will get quantity = 0 (representing historical data)</li>
            </ul>
        </div>
    </div>
</asp:Content>
