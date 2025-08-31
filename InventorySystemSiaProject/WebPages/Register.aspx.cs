using System;
using System.Threading.Tasks;
using System.Web.UI;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.WebPages
{
    public partial class Register : System.Web.UI.Page
    {
        private UserAuthenticationService _authService;

        protected void Page_Load(object sender, EventArgs e)
        {
            _authService = new UserAuthenticationService();
            
            if (!Page.IsPostBack)
            {
                // Focus on name field
                txtName.Focus();
            }
        }

        protected async void btnRegister_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
            {
                ShowMessage("Please correct the errors and try again.", "error");
                return;
            }

            try
            {
                // Get form data
                string name = txtName.Text.Trim();
                string email = txtEmail.Text.Trim().ToLower();
                string password = txtPassword.Text;
                string shortPass = txtShortPass.Text.Trim();
                string faceEncoding = hfFaceEncoding.Value;

                // Additional validation
                if (string.IsNullOrEmpty(name))
                {
                    ShowMessage("Name is required.", "error");
                    return;
                }

                if (string.IsNullOrEmpty(email))
                {
                    ShowMessage("Email is required.", "error");
                    return;
                }

                if (string.IsNullOrEmpty(password))
                {
                    ShowMessage("Password is required.", "error");
                    return;
                }

                if (password != txtConfirmPassword.Text)
                {
                    ShowMessage("Passwords do not match.", "error");
                    return;
                }

                if (string.IsNullOrEmpty(shortPass) || shortPass.Length != 4)
                {
                    ShowMessage("Short pass must be exactly 4 digits.", "error");
                    return;
                }

                // Validate short pass is numeric
                if (!int.TryParse(shortPass, out _))
                {
                    ShowMessage("Short pass must contain only numbers.", "error");
                    return;
                }

                // Register user
                var result = await _authService.RegisterUserAsync(name, email, password, faceEncoding, shortPass);

                if (result.Success)
                {
                    ShowMessage($"Registration successful! Welcome {name}. You can now login with your email/password, 4-digit short pass, or face recognition.", "success");
                    
                    // Clear form
                    ClearForm();
                    
                    // Optionally redirect to login page after delay
                    ClientScript.RegisterStartupScript(this.GetType(), "redirect", 
                        "setTimeout(function(){ window.location.href = 'Login.aspx'; }, 3000);", true);
                }
                else
                {
                    ShowMessage(result.Message, "error");
                }
            }
            catch (Exception ex)
            {
                ShowMessage($"Registration failed: {ex.Message}", "error");
                System.Diagnostics.Debug.WriteLine($"Registration error: {ex}");
            }
        }

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

        private void ClearForm()
        {
            txtName.Text = "";
            txtEmail.Text = "";
            txtPassword.Text = "";
            txtConfirmPassword.Text = "";
            txtShortPass.Text = "";
            hfFaceEncoding.Value = "";
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            // Add JavaScript for enhanced UX
            string script = @"
                // Auto-format short pass input
                document.getElementById('" + txtShortPass.ClientID + @"').addEventListener('input', function(e) {
                    this.value = this.value.replace(/[^0-9]/g, '').substring(0, 4);
                });

                // Real-time password match validation
                function checkPasswordMatch() {
                    var password = document.getElementById('" + txtPassword.ClientID + @"').value;
                    var confirmPassword = document.getElementById('" + txtConfirmPassword.ClientID + @"').value;
                    var matchIndicator = document.getElementById('passwordMatch');
                    
                    if (!matchIndicator) {
                        matchIndicator = document.createElement('div');
                        matchIndicator.id = 'passwordMatch';
                        matchIndicator.style.fontSize = '12px';
                        matchIndicator.style.marginTop = '5px';
                        document.getElementById('" + txtConfirmPassword.ClientID + @"').parentNode.appendChild(matchIndicator);
                    }
                    
                    if (confirmPassword.length > 0) {
                        if (password === confirmPassword) {
                            matchIndicator.innerHTML = '✅ Passwords match';
                            matchIndicator.style.color = 'green';
                        } else {
                            matchIndicator.innerHTML = '❌ Passwords do not match';
                            matchIndicator.style.color = 'red';
                        }
                    } else {
                        matchIndicator.innerHTML = '';
                    }
                }

                document.getElementById('" + txtPassword.ClientID + @"').addEventListener('input', checkPasswordMatch);
                document.getElementById('" + txtConfirmPassword.ClientID + @"').addEventListener('input', checkPasswordMatch);

                // Show/hide password functionality
                function addPasswordToggle() {
                    var passwordFields = ['" + txtPassword.ClientID + @"', '" + txtConfirmPassword.ClientID + @"'];
                    
                    passwordFields.forEach(function(fieldId) {
                        var field = document.getElementById(fieldId);
                        var toggleBtn = document.createElement('button');
                        toggleBtn.type = 'button';
                        toggleBtn.innerHTML = '👁️';
                        toggleBtn.style.position = 'absolute';
                        toggleBtn.style.right = '10px';
                        toggleBtn.style.top = '50%';
                        toggleBtn.style.transform = 'translateY(-50%)';
                        toggleBtn.style.border = 'none';
                        toggleBtn.style.background = 'none';
                        toggleBtn.style.cursor = 'pointer';
                        toggleBtn.style.fontSize = '16px';
                        
                        field.parentNode.style.position = 'relative';
                        field.style.paddingRight = '40px';
                        field.parentNode.appendChild(toggleBtn);
                        
                        toggleBtn.addEventListener('click', function() {
                            if (field.type === 'password') {
                                field.type = 'text';
                                toggleBtn.innerHTML = '🙈';
                            } else {
                                field.type = 'password';
                                toggleBtn.innerHTML = '👁️';
                            }
                        });
                    });
                }
                
                // Initialize enhancements
                setTimeout(addPasswordToggle, 100);
            ";

            ClientScript.RegisterStartupScript(this.GetType(), "enhanceForm", script, true);
        }
    }
}