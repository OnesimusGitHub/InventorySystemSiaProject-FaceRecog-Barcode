using System;
using System.Collections.Generic;
using System.Web.UI;
using InventorySystemSiaProject.Services;
using InventorySystemSiaProject.Models;

namespace InventorySystemSiaProject.WebPages
{
    public partial class Login : System.Web.UI.Page
    {
        private UserAuthenticationService _authService;

        protected void Page_Load(object sender, EventArgs e)
        {
            _authService = new UserAuthenticationService();

            if (!Page.IsPostBack)
            {
                // Check if user is already logged in
                if (Session["UserId"] != null)
                {
                    // Check role
                    var role = Session["UserRole"] as string;
                    if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
                    {
                        ShowMessage("Invalid credentials.", "error");
                        // Do not redirect
                        return;
                    }
                    // Redirect ALL logged-in Admin users to Admin Dashboard
                    Response.Redirect("~/WebPages/Dashboard.aspx");
                }
            }
        }

        /// <summary>
        /// Email and Password Login
        /// </summary>
        protected async void btnEmailLogin_Click(object sender, EventArgs e)
        {
            try
            {
                string email = txtEmail.Text.Trim();
                string password = txtPassword.Text;

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
                {
                    ShowMessage("Please enter both email and password.", "error");
                    return;
                }

                var result = await _authService.LoginAsync(email, password);

                if (result.Success)
                {
                    // Set session
                    SetUserSession(result.User);
                    
                    ShowMessage($"Welcome back, {result.User.Name}! Redirecting...", "success");
                    
                    // Use server-side redirect for more reliable redirection
                    Response.Redirect("~/WebPages/Dashboard.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                }
                else
                {
                    ShowMessage(result.Message, "error");
                    ClearPasswordFields();
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Login failed: {ex.Message}", "error");
            }
        }

        /// <summary>
        /// Short Pass Login (4-digit PIN)
        /// </summary>
        protected async void btnShortPassLogin_Click(object sender, EventArgs e)
        {
            try
            {
                string email = txtEmailShort.Text.Trim();
                string shortPass = txtShortPassLogin.Text.Trim();

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(shortPass))
                {
                    ShowMessage("Please enter both email and 4-digit short pass.", "error");
                    return;
                }

                if (shortPass.Length != 4 || !int.TryParse(shortPass, out _))
                {
                    ShowMessage("Short pass must be exactly 4 digits.", "error");
                    return;
                }

                var result = await _authService.ShortPassLoginAsync(email, shortPass);

                if (result.Success)
                {
                    // Set session
                    SetUserSession(result.User);
                    
                    ShowMessage($"Quick login successful! Welcome {result.User.Name}!", "success");
                    
                    // Use server-side redirect for more reliable redirection
                    Response.Redirect("~/WebPages/Dashboard.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                }
                else
                {
                    ShowMessage(result.Message, "error");
                    txtShortPassLogin.Text = "";
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Short pass login failed: {ex.Message}", "error");
            }
        }

        /// <summary>
        /// Modal Short Pass Login (triggered after face recognition)
        /// </summary>
        protected async void btnModalShortPassLogin_Click(object sender, EventArgs e)
        {
            try
            {
                string userId = hfRecognizedUserId.Value;
                string shortPass = txtModalShortPass.Text.Trim();

                if (string.IsNullOrEmpty(userId) || string.IsNullOrEmpty(shortPass))
                {
                    ShowMessage("Invalid request. Please try face recognition again.", "error");
                    ClientScript.RegisterStartupScript(this.GetType(), "closeModal", "closeShortPassModal();", true);
                    return;
                }

                if (shortPass.Length != 4 || !int.TryParse(shortPass, out _))
                {
                    ShowMessage("PIN must be exactly 4 digits.", "error");
                    return;
                }

                var result = await _authService.ValidateShortPassAsync(userId, shortPass);

                if (result.Success)
                {
                    // Set session
                    SetUserSession(result.User);
                    
                    // Show success message briefly and then redirect to Admin Dashboard
                    ShowMessage($"Face + PIN login successful! Welcome {result.User.Name}!", "success");
                    
                    // Redirect ALL users to Dashboard
                    string redirectUrl = "~/WebPages/Dashboard.aspx";
                    
                    // Use JavaScript redirect
                    ClientScript.RegisterStartupScript(this.GetType(), "successLogin", $@"
                        window.markLoginSuccessful();
                        setTimeout(function(){{ 
                            window.location.href = '{redirectUrl}'; 
                        }}, 500);
                    ", true);
                    
                    // Also add meta refresh as a backup
                    Response.AddHeader("Refresh", $"2; URL={redirectUrl}");
                }
                else
                {
                    ShowMessage("Invalid PIN. Please try again.", "error");
                    txtModalShortPass.Text = "";
                    ClientScript.RegisterStartupScript(this.GetType(), "focusPin", @"
                        document.getElementById('" + txtModalShortPass.ClientID + @"').focus();
                    ", true);
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"PIN verification failed: {ex.Message}", "error");
            }
        }

        /// <summary>
        /// Face Recognition Login
        /// </summary>
        protected async void btnFaceLogin_Click(object sender, EventArgs e)
        {
            try
            {
                string faceEncoding = hfFaceLoginEncoding.Value;

                if (string.IsNullOrEmpty(faceEncoding))
                {
                    ClientScript.RegisterStartupScript(this.GetType(), "faceRecognitionFailed", "if(window.faceRecognitionFailed) window.faceRecognitionFailed();", true);
                    return;
                }

                var result = await _authService.FaceRecognitionAsync(faceEncoding);

                if (result.Success)
                {
                    // Escape quotes in user data to prevent JavaScript errors
                    string escapedName = result.User.Name.Replace("'", "\\'").Replace("\"", "\\\"");
                    string escapedEmail = result.User.Email.Replace("'", "\\'").Replace("\"", "\\\"");
                    string escapedId = result.User.Id.Replace("'", "\\'").Replace("\"", "\\\"");

                    // Show short pass modal for the recognized user
                    string script = $@"
                        setTimeout(function() {{
                            document.getElementById('recognizedUserName').textContent = '{escapedName}';
                            document.getElementById('recognizedUserEmail').textContent = '{escapedEmail}';
                            document.getElementById('{hfRecognizedUserId.ClientID}').value = '{escapedId}';
                            document.getElementById('shortPassModal').style.display = 'block';
                            document.getElementById('{txtModalShortPass.ClientID}').focus();
                            if (window.stopFaceRecognition) {{
                                window.stopFaceRecognition();
                            }}
                        }}, 100);
                    ";
                    ClientScript.RegisterStartupScript(this.GetType(), "showModal", script, true);
                }
                else
                {
                    // Face not recognized, continue scanning
                    ClientScript.RegisterStartupScript(this.GetType(), "faceRecognitionFailed", "if(window.faceRecognitionFailed) window.faceRecognitionFailed();", true);
                }
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(this.GetType(), "faceRecognitionFailed", "if(window.faceRecognitionFailed) window.faceRecognitionFailed();", true);
            }
        }

        /// <summary>
        /// Sets user session data
        /// </summary>
        private void SetUserSession(User user)
        {
            Session["UserId"] = user.Id;
            Session["UserName"] = user.Name;
            Session["UserEmail"] = user.Email;
            Session["UserRole"] = user.Role;
            Session["LoginTime"] = DateTime.Now;
            
            // Debug output for UserId
            System.Diagnostics.Debug.WriteLine($"[DEBUG] Session UserId set to: {user.Id}");
            Response.Write($"<div style='color:blue;font-weight:bold;'>[DEBUG] Session UserId: {Session["UserId"]}</div>");
        }

        /// <summary>
        /// Redirects user to appropriate page based on role
        /// </summary>
        private void RedirectAfterLogin(User user)
        {
            // Check user role and redirect accordingly
            if (user.Role == "Admin")
            {
                Response.Redirect("~/WebPages/Dashboard.aspx");
            }
            else
            {
                Response.Redirect("~/Default.aspx");
            }
        }

        /// <summary>
        /// Shows message to user
        /// </summary>
        private void ShowMessage(string message, string type)
        {
            pnlMessage.Visible = true;
            lblMessage.Text = message;
            
            // Set CSS class based on message type
            switch (type.ToLower())
            {
                case "success":
                    pnlMessage.CssClass = "message success";
                    break;
                case "error":
                    pnlMessage.CssClass = "message error";
                    break;
                case "info":
                    pnlMessage.CssClass = "message info";
                    break;
                default:
                    pnlMessage.CssClass = "message";
                    break;
            }
        }

        /// <summary>
        /// Clears password fields for security
        /// </summary>
        private void ClearPasswordFields()
        {
            txtPassword.Text = "";
            txtShortPassLogin.Text = "";
            txtModalShortPass.Text = "";
        }

        /// <summary>
        /// Page PreRender for additional JavaScript functionality
        /// </summary>
        protected void Page_PreRender(object sender, EventArgs e)
        {
            // Add enhanced security and UX features
            string script = @"
                // Prevent form resubmission on page refresh
                if (window.history.replaceState) {
                    window.history.replaceState(null, null, window.location.href);
                }

                // Auto-clear error messages after delay
                setTimeout(function() {
                    var messagePanel = document.querySelector('.message.error');
                    if (messagePanel) {
                        messagePanel.style.opacity = '0';
                        setTimeout(function() {
                            messagePanel.style.display = 'none';
                        }, 500);
                    }
                }, 5000);

                // Enhanced security: Clear sensitive data on page unload
                window.addEventListener('beforeunload', function() {
                    document.getElementById('" + txtPassword.ClientID + @"').value = '';
                    document.getElementById('" + txtShortPassLogin.ClientID + @"').value = '';
                    document.getElementById('" + txtModalShortPass.ClientID + @"').value = '';
                    document.getElementById('" + hfFaceLoginEncoding.ClientID + @"').value = '';
                });

                // Login attempt tracking (basic)
                var loginAttempts = sessionStorage.getItem('loginAttempts') || 0;
                if (loginAttempts >= 5) {
                    document.querySelectorAll('.btn').forEach(btn => {
                        btn.disabled = true;
                        btn.innerHTML = '🔒 Too many attempts. Please refresh page.';
                    });
                }

                // Track failed login attempts
                function trackFailedLogin() {
                    var attempts = parseInt(sessionStorage.getItem('loginAttempts') || 0) + 1;
                    sessionStorage.setItem('loginAttempts', attempts);
                    
                    if (attempts >= 3) {
                        alert('Multiple failed login attempts detected. Please be careful.');
                    }
                }

                // Reset attempts on successful login
                function resetLoginAttempts() {
                    sessionStorage.removeItem('loginAttempts');
                }

                // Add to failed login scenarios
                var errorMessages = document.querySelectorAll('.message.error');
                if (errorMessages.length > 0) {
                    trackFailedLogin();
                }

                // Add to successful login scenarios
                var successMessages = document.querySelectorAll('.message.success');
                if (successMessages.length > 0) {
                    resetLoginAttempts();
                }
            ";

            ClientScript.RegisterStartupScript(this.GetType(), "enhanceLogin", script, true);
        }
    }
}