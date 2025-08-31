<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="InventorySystemSiaProject.Admin.Dashboard" Async="true" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Admin Dashboard - Inventory System</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- Font Awesome for icons -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" />
    <link href="../Content/admin-dashboard.css" rel="stylesheet" type="text/css"/>
</head>
<body>
    <form id="form1" runat="server">
        <nav id="sidebar">
            <ul>
                <li>
                    <span class="logo">Beauty mo po</span>
                    <button id="toggle-btn">
                        Cause im a punk Rocker (imgnapaclose)
                    </button>
                </li>
                <li class="active">
                    <a href="#">Dashboard</a>
                </li>
                <li>
                    <a href="#">Products Page</a>
                </li>
                <li>
                    <a href="#">Employee Account Privelege</a>
                </li>
                <li>
                    <a href="#">Product Inventory</a>
                </li>
                <li>
                    <a href="#">Product Information Page</a>
                </li>
            </ul>
        </nav>
        <main>
            <div class="container">
                <h2>Hello World</h2>
                <p>I love you willowby</p>
            </div>
            <div class="container">
                <h2>You were always my world</h2>
                <p>Diana</p>
            </div>
            <div class="container">
                <h2>My heart is always be yours</h2>
                <p>Willowby</p>
            </div>
        </main>
    </form>

    <script>
        // Sidebar toggle functionality
        document.getElementById('sidebarToggle').addEventListener('click', function() {
            const sidebar = document.getElementById('sidebar');
            sidebar.classList.toggle('collapsed');
        });

        // Mobile responsive sidebar
        function handleResize() {
            const sidebar = document.getElementById('sidebar');
            if (window.innerWidth <= 768) {
                sidebar.classList.add('collapsed');
            }
        }

        window.addEventListener('resize', handleResize);
        handleResize(); // Call on page load

        // Auto-refresh statistics every 30 seconds
        setInterval(function() {
            // You can implement AJAX calls here to refresh data
            console.log('Refreshing dashboard data...');
        }, 30000);
    </script>
</body>
</html>