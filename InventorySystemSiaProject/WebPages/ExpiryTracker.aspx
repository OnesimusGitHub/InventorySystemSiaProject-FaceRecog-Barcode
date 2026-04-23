<%@ Page Language="C#" MasterPageFile="~/Admin/Admin.master" AutoEventWireup="true" CodeBehind="ExpiryTracker.aspx.cs" Inherits="InventorySystemSiaProject.WebPages.ExpiryTracker" %>

<asp:Content ID="HeadContentExpiry" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../Content/ProductPage.css" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        .expiry-table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
        .expiry-table th, .expiry-table td { padding: 10px; border: 1px solid #e9ecef; text-align: left; }
        .expiry-table th { background: #f8f9fa; }
        .text-muted { color: #666; }
        .badge-warning { background: #ff9800; color: white; padding: 4px 8px; border-radius: 12px; }
        .badge-danger { background: #f44336; color: white; padding: 4px 8px; border-radius: 12px; }
        .badge-info { background: #2196F3; color: white; padding: 4px 8px; border-radius: 12px; }
    </style>
</asp:Content>

<asp:Content ID="MainContentExpiry" ContentPlaceHolderID="MainContent" runat="server">
    <header class="page-header">
        <h1>Expiry Tracker</h1>
        <p>Track products and ingredients nearing expiry</p>
    </header>

    <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="error-container">
        <asp:Label ID="lblMessage" runat="server" />
    </asp:Panel>

    <section>
        <h2>Near-Expiry Packages</h2>
        <p class="text-muted">Items from package stock entries which are near expiry.</p>
        <div class="table-wrapper">
            <table class="expiry-table" id="tblPackages">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Product</th>
                        <th>Variant / Batch</th>
                        <th>Quantity</th>
                        <th>Expiry Date</th>
                        <th>Days Left</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <tr><td colspan="7" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </section>

    <section>
        <h2>Near-Expiry Ingredients</h2>
        <p class="text-muted">Ingredient stocks that will expire soon.</p>
        <div class="table-wrapper">
            <table class="expiry-table" id="tblIngredients">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Ingredient</th>
                        <th>Batch / Source</th>
                        <th>Quantity</th>
                        <th>Expiry Date</th>
                        <th>Days Left</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <tr><td colspan="7" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading...</td></tr>
                </tbody>
            </table>
        </div>
    </section>
</asp:Content>

<asp:Content ID="ScriptsContentExpiry" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
    $(function () {
        function renderPackages(list) {
            var tbody = $('#tblPackages tbody');
            if (!Array.isArray(list) || list.length === 0) {
                tbody.html('<tr><td colspan="7" class="text-center">No near-expiry packages found.</td></tr>');
                return;
            }
            var html = list.map(function (p, i) {
                var daysLeft = p.DaysLeft || Math.ceil((new Date(p.ExpiryDate) - new Date()) / (1000*60*60*24));
                var badge = daysLeft <= 7 ? '<span class="badge-danger">' + daysLeft + 'd</span>' : '<span class="badge-warning">' + daysLeft + 'd</span>';
                return '<tr>' +
                    '<td>' + (i + 1) + '</td>' +
                    '<td>' + (p.ProductName || p.Product || '-') + '</td>' +
                    '<td>' + (p.VariantName || p.Batch || '-') + '</td>' +
                    '<td>' + (p.Quantity || '-') + '</td>' +
                    '<td>' + (p.ExpiryDate ? new Date(p.ExpiryDate).toLocaleDateString() : '-') + '</td>' +
                    '<td>' + badge + '</td>' +
                    '<td><button class="btn-animated btn-secondary" onclick="viewPackage(\'' + (p.Id || p.PackageId || '') + '\')">View</button></td>' +
                    '</tr>';
            }).join('');
            tbody.html(html);
        }

        function renderIngredients(list) {
            var tbody = $('#tblIngredients tbody');
            if (!Array.isArray(list) || list.length === 0) {
                tbody.html('<tr><td colspan="7" class="text-center">No near-expiry ingredients found.</td></tr>');
                return;
            }
            var html = list.map(function (p, i) {
                var daysLeft = p.DaysLeft || Math.ceil((new Date(p.ExpiryDate) - new Date()) / (1000*60*60*24));
                var badge = daysLeft <= 7 ? '<span class="badge-danger">' + daysLeft + 'd</span>' : '<span class="badge-warning">' + daysLeft + 'd</span>';
                return '<tr>' +
                    '<td>' + (i + 1) + '</td>' +
                    '<td>' + (p.Name || p.IngredientName || '-') + '</td>' +
                    '<td>' + (p.Batch || '-') + '</td>' +
                    '<td>' + (p.Quantity || '-') + '</td>' +
                    '<td>' + (p.ExpiryDate ? new Date(p.ExpiryDate).toLocaleDateString() : '-') + '</td>' +
                    '<td>' + badge + '</td>' +
                    '<td><button class="btn-animated btn-secondary" onclick="viewIngredient(\'' + (p.Id || p.IngredientId || '') + '\')">View</button></td>' +
                    '</tr>';
            }).join('');
            tbody.html(html);
        }

        function fetchPackages() {
            return $.ajax({
                url: '/Handlers/GetNearExpiryPackages.ashx',
                method: 'GET',
                dataType: 'json'
            }).then(function (res) {
                var list = res && res.success && Array.isArray(res.packages) ? res.packages : (Array.isArray(res) ? res : []);
                renderPackages(list);
            }).fail(function () {
                $('#tblPackages tbody').html('<tr><td colspan="7" class="text-center text-muted">Failed to load packages.</td></tr>');
            });
        }

        function fetchIngredients() {
            return $.ajax({
                url: '/Handlers/GetNearExpiryIngredients.ashx',
                method: 'GET',
                dataType: 'json'
            }).then(function (res) {
                var list = res && res.success && Array.isArray(res.ingredients) ? res.ingredients : (Array.isArray(res) ? res : []);
                renderIngredients(list);
            }).fail(function () {
                $('#tblIngredients tbody').html('<tr><td colspan="7" class="text-center text-muted">Failed to load ingredients.</td></tr>');
            });
        }

        // Actions
        window.viewPackage = function (id) {
            if (!id) return; 
            window.location.href = '/WebPages/ProductProfile.aspx?packageId=' + encodeURIComponent(id);
        };
        window.viewIngredient = function (id) {
            if (!id) return; 
            window.location.href = '/WebPages/IngredientsPage.aspx?ingredientId=' + encodeURIComponent(id);
        };

        // Initial load
        fetchPackages();
        fetchIngredients();

        // Auto refresh every 5 minutes
        setInterval(function () { fetchPackages(); fetchIngredients(); }, 300000);
    });
</script>
</asp:Content>