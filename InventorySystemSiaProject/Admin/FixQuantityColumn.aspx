<%@ Page Title="Fix Quantity Column" Language="C#" MasterPageFile="~/Admin/Admin.Master" AutoEventWireup="true" %>
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
            DiagnoseDatabase();
        }
    }
    
    protected void DiagnoseDatabase()
    {
        try
        {
            var collection = Helpers.DatabaseHelper.GetCollection<MongoDB.Bson.BsonDocument>("EmployeeActivities");
            
            // Check total count
            var totalCount = collection.CountDocuments(MongoDB.Driver.FilterDefinition<MongoDB.Bson.BsonDocument>.Empty);
            lblTotalRecords.Text = totalCount.ToString();
            
            // Count records with missing quantity
            var missingFilter = MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Or(
                MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Not(
                    MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Exists("quantity")),
                MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Eq("quantity", MongoDB.Bson.BsonNull.Value)
            );
            
            var missingCount = collection.CountDocuments(missingFilter);
            lblMissingQuantity.Text = missingCount.ToString();
            lblPercentage.Text = totalCount > 0 ? ((missingCount * 100.0) / totalCount).ToString("F1") : "0";
        }
        catch (Exception ex)
        {
            lblError.Text = "Diagnosis error: " + ex.Message;
            lblError.Visible = true;
        }
    }
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="PageTitle" runat="server">
    Fix Quantity Column
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div style="max-width: 1200px; margin: 40px auto; padding: 20px; background: #fff; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
        <h1 style="color: #A86D6A; margin-bottom: 20px;">?? Fix Quantity Column in Activity Log</h1>
        
        <asp:Label ID="lblError" runat="server" Visible="false" style="background: #f8d7da; color: #721c24; padding: 15px; border-radius: 8px; margin-bottom: 20px; display: block;"></asp:Label>
        
        <!-- Diagnosis Panel -->
        <div style="background: #f9f6f8; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #A86D6A;">
            <h3 style="color: #A86D6A; margin-top: 0;">?? Database Diagnosis</h3>
            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; margin-top: 10px;">
                <div style="background: white; padding: 12px; border-radius: 6px; text-align: center;">
                    <div style="font-size: 14px; color: #666; margin-bottom: 5px;">Total Records</div>
                    <div style="font-size: 28px; color: #A86D6A; font-weight: bold;"><asp:Label ID="lblTotalRecords" runat="server" Text="0"></asp:Label></div>
                </div>
                <div style="background: white; padding: 12px; border-radius: 6px; text-align: center;">
                    <div style="font-size: 14px; color: #666; margin-bottom: 5px;">Missing Quantity</div>
                    <div style="font-size: 28px; color: #dc3545; font-weight: bold;"><asp:Label ID="lblMissingQuantity" runat="server" Text="0"></asp:Label></div>
                </div>
                <div style="background: white; padding: 12px; border-radius: 6px; text-align: center;">
                    <div style="font-size: 14px; color: #666; margin-bottom: 5px;">Percentage Affected</div>
                    <div style="font-size: 28px; color: #ffc107; font-weight: bold;"><asp:Label ID="lblPercentage" runat="server" Text="0"></asp:Label>%</div>
                </div>
            </div>
        </div>

        <!-- Issue Description -->
        <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #2196F3;">
            <h3 style="color: #1976D2; margin-top: 0;">?? Issue Description</h3>
            <p>The <strong>Quantity column</strong> in the Employee Activities table shows empty values because MongoDB records don't have the <code>quantity</code> field populated.</p>
        </div>

        <!-- Fix Section -->
        <div style="margin: 30px 0;">
            <h3 style="color: #A86D6A;">??? Apply Fix</h3>
            <button type="button" onclick="fixQuantityColumn()" id="btnFix" style="padding: 12px 24px; background: #A86D6A; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 16px; font-weight: 600;">
                ?? Fix Missing Quantity Values
            </button>
        </div>

        <!-- Results Section -->
        <div id="resultContainer" style="display: none; margin-top: 20px; padding: 15px; border-radius: 8px; border-left: 4px solid #4CAF50;">
            <h3 id="resultTitle" style="margin-top: 0;"></h3>
            <p id="resultMessage"></p>
            <pre id="resultDetails" style="background: #f5f5f5; padding: 10px; border-radius: 4px; overflow-x: auto; max-height: 300px;"></pre>
        </div>

        <!-- Instructions -->
        <div style="background: #d4edda; padding: 15px; border-radius: 8px; margin-top: 30px; border-left: 4px solid #28a745;">
            <h3 style="color: #155724; margin-top: 0;">? After Fixing</h3>
            <ol style="color: #155724;">
                <li>Click the <strong>"?? Fix Missing Quantity Values"</strong> button above</li>
                <li>Wait for the success message</li>
                <li>Visit <a href="~/WebPages/ActivityLog.aspx" style="color: #155724; font-weight: 600;">Activity Log</a> and refresh the page</li>
                <li>The Quantity column should now display values</li>
            </ol>
        </div>
    </div>

    <script>
        function fixQuantityColumn() {
            var btn = document.getElementById('btnFix');
            btn.disabled = true;
            btn.textContent = "?? Processing...";

            // Make request to the handler
            fetch('/Handlers/FixEmployeeActivityQuantity.ashx', {
                method: 'GET',
                credentials: 'include'
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('HTTP ' + response.status + ': ' + response.statusText);
                }
                return response.json();
            })
            .then(data => {
                console.log('Fix response:', data);
                var resultContainer = document.getElementById('resultContainer');
                var resultTitle = document.getElementById('resultTitle');
                var resultMessage = document.getElementById('resultMessage');
                var resultDetails = document.getElementById('resultDetails');

                resultContainer.style.display = 'block';

                if (data.success) {
                    resultTitle.style.color = '#155724';
                    resultTitle.textContent = '? Successfully Fixed!';
                    resultContainer.style.borderLeftColor = '#4CAF50';
                    resultContainer.style.background = '#d4edda';
                    resultMessage.innerHTML = `<strong>${data.message}</strong><br>Records matched: ${data.matched}<br>Records modified: ${data.modified}`;
                    resultMessage.style.color = '#155724';
                    
                    // Show follow-up instructions
                    resultMessage.innerHTML += '<br><br><strong>Next steps:</strong><br>1. Go to Activity Log page<br>2. Refresh the page (Ctrl+F5)<br>3. The Quantity column should now show values';
                } else {
                    resultTitle.style.color = '#721c24';
                    resultTitle.textContent = '? Error Occurred';
                    resultContainer.style.borderLeftColor = '#dc3545';
                    resultContainer.style.background = '#f8d7da';
                    resultMessage.textContent = data.message;
                    resultMessage.style.color = '#721c24';
                }

                resultDetails.textContent = JSON.stringify(data, null, 2);

                btn.disabled = false;
                btn.textContent = '?? Fix Missing Quantity Values';
            })
            .catch(error => {
                console.error('Error:', error);
                var resultContainer = document.getElementById('resultContainer');
                var resultTitle = document.getElementById('resultTitle');
                var resultMessage = document.getElementById('resultMessage');

                resultContainer.style.display = 'block';
                resultTitle.style.color = '#721c24';
                resultTitle.textContent = '? Error';
                resultContainer.style.borderLeftColor = '#dc3545';
                resultContainer.style.background = '#f8d7da';
                resultMessage.textContent = 'Failed to fix records: ' + error.message;
                resultMessage.style.color = '#721c24';

                btn.disabled = false;
                btn.textContent = '?? Fix Missing Quantity Values';
            });
        }
    </script>
</asp:Content>
