<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="InventorySystemSiaProject.Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Dashboard - Inventory System</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            text-align: center;
        }
        .welcome-section {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            border-left: 4px solid #007bff;
        }
        .user-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .info-card {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #ddd;
            text-align: center;
        }
        .info-card h3 {
            margin: 0 0 10px 0;
            color: #333;
        }
        .info-card p {
            margin: 5px 0;
            color: #666;
        }
        .logout-section {
            text-align: center;
            margin-top: 30px;
            padding-top: 30px;
            border-top: 1px solid #eee;
        }
        .btn {
            background-color: #dc3545;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            text-decoration: none;
            display: inline-block;
        }
        .btn:hover {
            background-color: #c82333;
        }
        .navigation {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 30px 0;
        }
        .nav-link {
            background-color: #007bff;
            color: white;
            padding: 15px;
            text-decoration: none;
            border-radius: 8px;
            text-align: center;
            transition: background-color 0.3s;
        }
        .nav-link:hover {
            background-color: #0056b3;
            color: white;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="container">
            <div class="header">
                <h1>?? Inventory Management System</h1>
                <p>Face Recognition Enabled Dashboard</p>
            </div>

            <div class="welcome-section">
                <h2>Welcome back, <asp:Label ID="lblUserName" runat="server" />! ??</h2>
                <p>You have successfully logged in to the system.</p>
            </div>

            <div class="user-info">
                <div class="info-card">
                    <h3>?? User Information</h3>
                    <p><strong>Name:</strong> <asp:Label ID="lblName" runat="server" /></p>
                    <p><strong>Email:</strong> <asp:Label ID="lblEmail" runat="server" /></p>
                    <p><strong>Role:</strong> <asp:Label ID="lblRole" runat="server" /></p>
                </div>
                
                <div class="info-card">
                    <h3>?? Session Information</h3>
                    <p><strong>Login Time:</strong> <asp:Label ID="lblLoginTime" runat="server" /></p>
                    <p><strong>Session ID:</strong> <asp:Label ID="lblSessionId" runat="server" /></p>
                    <p><strong>Last Activity:</strong> <asp:Label ID="lblLastActivity" runat="server" /></p>
                </div>
            </div>

            <div class="navigation">
                <a href="Register.aspx" class="nav-link">?? User Registration</a>
                <a href="SaleExample.aspx" class="nav-link">?? Sales Management</a>
                <a href="#" class="nav-link">?? Inventory</a>
                <a href="#" class="nav-link">?? Reports</a>
                <a href="#" class="nav-link">?? Settings</a>
                <a href="#" class="nav-link">?? Profile</a>
            </div>

            <div class="logout-section">
                <asp:Button ID="btnLogout" runat="server" CssClass="btn" Text="?? Logout" OnClick="btnLogout_Click" 
                    OnClientClick="return confirm('Are you sure you want to logout?');" />
            </div>
        </div>
    </form>

    <script>
        // Update last activity time every minute
        setInterval(function() {
            document.getElementById('<%= lblLastActivity.ClientID %>').innerText = new Date().toLocaleString();
        }, 60000);

        // Show welcome animation
        window.addEventListener('load', function() {
            const welcomeSection = document.querySelector('.welcome-section');
            welcomeSection.style.transform = 'translateY(-20px)';
            welcomeSection.style.opacity = '0';
            
            setTimeout(function() {
                welcomeSection.style.transition = 'all 0.5s ease';
                welcomeSection.style.transform = 'translateY(0)';
                welcomeSection.style.opacity = '1';
            }, 100);
        });
    </script>
</body>
</html>