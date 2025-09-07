<%@ Page Language="C#" AutoEventWireup="true" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        // Redirect legacy path /WebPages/SeedData.aspx to the actual Admin page
        Response.Redirect("~/Admin/SeedData.aspx", true);
    }
</script>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Redirecting…</title>
    <meta http-equiv="refresh" content="0;url=/Admin/SeedData.aspx" />
</head>
<body>
    <p>Redirecting to Seed Data page… If you are not redirected, <a href="/Admin/SeedData.aspx">click here</a>.</p>
</body>
</html>