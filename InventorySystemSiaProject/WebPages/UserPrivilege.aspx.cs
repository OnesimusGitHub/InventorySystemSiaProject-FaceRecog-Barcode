using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using System.Text.RegularExpressions; // for Regex.Escape
using MongoDB.Bson; // ensure Bson types available
using System.Security.Cryptography;
using System.Text;

namespace InventorySystemSiaProject.WebPages
{
    public partial class UserPrivilege : System.Web.UI.Page
    {
        private IMongoCollection<User> _usersCol => DatabaseHelper.GetUsersCollection();

        protected void Page_Load(object sender, EventArgs e)
        {
            var role = Session["UserRole"] as string;
            if (string.IsNullOrEmpty(role) || !role.Equals("Admin", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/WebPages/Login.aspx");
                return;
            }

            // Explicitly disable browser autofill on name fields to avoid email being inserted
            if (txtAddName != null) { txtAddName.Attributes["autocomplete"] = "off"; txtAddName.Attributes["autocapitalize"] = "none"; }
            if (txtName != null) { txtName.Attributes["autocomplete"] = "off"; txtName.Attributes["autocapitalize"] = "none"; }

            if (!IsPostBack)
            {
                BindUsers();
            }
        }

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            if (btnSaveUser != null) btnSaveUser.Click += btnSaveUser_Click;
            if (btnCancelEdit != null) btnCancelEdit.Click += btnCancelEdit_Click;
            if (gvUsers != null)
            {
                gvUsers.RowEditing += gvUsers_RowEditing;
                gvUsers.RowCancelingEdit += gvUsers_RowCancelingEdit;
                gvUsers.RowUpdating += gvUsers_RowUpdating;
                gvUsers.RowDeleting += gvUsers_RowDeleting;
                gvUsers.RowCommand += gvUsers_RowCommand;
            }
            if (btnAddUserSave != null) btnAddUserSave.Click += btnAddUserSave_Click;
            if (btnSearch != null) btnSearch.Click += btnSearch_Click;
        }

        private void ShowMessage(string msg)
        {
            if (lblMessage != null)
            {
                lblMessage.Text = msg;
                lblMessage.Visible = true;
            }
            if (lblError != null) lblError.Visible = false;
        }
        private void ShowError(string msg)
        {
            if (lblError != null)
            {
                lblError.Text = msg;
                lblError.Visible = true;
            }
            if (lblMessage != null) lblMessage.Visible = false;
        }

        private void BindUsers()
        {
            try
            {
                var list = _usersCol.Find(FilterDefinition<User>.Empty)
                                     .SortByDescending(u => u.CreatedAt)
                                     .ToList();
                gvUsers.DataSource = list;
                gvUsers.DataBind();
            }
            catch (Exception ex)
            {
                ShowError("Failed to load users: " + ex.Message);
            }
        }

        private void AddUser(string name, string email, string role, string password)
        {
            var user = new User
            {
                Name = name,
                Email = email,
                Role = role,
                PasswordHash = HashPassword(password), // ✅ NOW HASHING (removed duplicate line)
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };
            _usersCol.InsertOne(user);
        }

        private void UpdateUser(string id, string name, string email, string role, string password)
        {
            var update = Builders<User>.Update
                .Set(u => u.Name, name)
                .Set(u => u.Email, email)
                .Set(u => u.Role, role);

            // Only hash if password is provided
            if (!string.IsNullOrWhiteSpace(password))
                update = update.Set(u => u.PasswordHash, HashPassword(password)); // ✅ HASH IT (removed duplicate line)

            _usersCol.UpdateOne(u => u.Id == id, update);
        }

        private void DeleteUser(string id)
        {
            _usersCol.DeleteOne(u => u.Id == id);
        }

        // Button events
        protected void btnSaveUser_Click(object sender, EventArgs e)
        {
            try
            {
                var id = hfUserId.Value;
                if (string.IsNullOrWhiteSpace(txtName.Text) || string.IsNullOrWhiteSpace(txtEmail.Text))
                {
                    ShowError("Name and Email required.");
                    return;
                }
                if (string.IsNullOrEmpty(id))
                {
                    AddUser(txtName.Text.Trim(), txtEmail.Text.Trim(), ddlRole.SelectedValue, txtPassword.Text.Trim());
                    ShowMessage("User added.");
                }
                else
                {
                    UpdateUser(id, txtName.Text.Trim(), txtEmail.Text.Trim(), ddlRole.SelectedValue, txtPassword.Text.Trim());
                    ShowMessage("User updated.");
                }
                ClearForm();
                BindUsers();
            }
            catch (Exception ex)
            {
                ShowError(ex.Message);
            }
        }

        protected void btnCancelEdit_Click(object sender, EventArgs e)
        {
            ClearForm();
        }

        private void ClearForm()
        {
            hfUserId.Value = string.Empty;
            txtName.Text = string.Empty;
            txtEmail.Text = string.Empty;
            ddlRole.SelectedValue = "User";
            txtPassword.Text = string.Empty;
            btnSaveUser.Text = "Add User";
            btnCancelEdit.Visible = false;
        }

        // GridView events
        protected void gvUsers_RowEditing(object sender, GridViewEditEventArgs e)
        {
            gvUsers.EditIndex = e.NewEditIndex;
            BindUsers();
        }

        protected void gvUsers_RowCancelingEdit(object sender, GridViewCancelEditEventArgs e)
        {
            gvUsers.EditIndex = -1;
            BindUsers();
        }

        protected void gvUsers_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {
            try
            {
                string id = gvUsers.DataKeys[e.RowIndex].Value.ToString();
                GridViewRow row = gvUsers.Rows[e.RowIndex];
                string name = ((TextBox)row.Cells[0].Controls[0]).Text.Trim();
                string email = ((TextBox)row.Cells[1].Controls[0]).Text.Trim();
                string role = ((TextBox)row.Cells[2].Controls[0]).Text.Trim();
                bool isActive = ((CheckBox)row.Cells[3].Controls[0]).Checked;

                var update = Builders<User>.Update
                    .Set(u => u.Name, name)
                    .Set(u => u.Email, email)
                    .Set(u => u.Role, role)
                    .Set(u => u.IsActive, isActive);
                _usersCol.UpdateOne(u => u.Id == id, update);

                gvUsers.EditIndex = -1;
                BindUsers();
                ShowMessage("User updated.");
            }
            catch (Exception ex)
            {
                ShowError(ex.Message);
            }
        }

        protected void gvUsers_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            try
            {
                string id = gvUsers.DataKeys[e.RowIndex].Value.ToString();
                DeleteUser(id);
                BindUsers();
                ShowMessage("User deleted.");
            }
            catch (Exception ex)
            {
                ShowError(ex.Message);
            }
        }

        protected void gvUsers_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "EditUser")
            {
                var id = e.CommandArgument.ToString();
                var user = _usersCol.Find(u => u.Id == id).FirstOrDefault();
                if (user != null)
                {
                    hfEditUserId.Value = user.Id;
                    txtEditName.Text = user.Name;
                    txtEditEmail.Text = user.Email;
                    ddlEditRole.SelectedValue = user.Role ?? "User";
                    txtEditFaceEncoding.Text = user.FaceEncoding;
                    txtEditFaceHash.Text = user.FaceHash;
                    chkEditActive.Checked = user.IsActive;
                    // show modal via script
                    ScriptManager.RegisterStartupScript(this, GetType(), "showEditModal", "document.getElementById('editUserModal').style.display='flex';", true);
                }
            }
        }

        private void btnUpdateUser_Click(object sender, EventArgs e)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(hfEditUserId.Value)) { ShowError("No user selected"); return; }

                var upd = Builders<User>.Update
                    .Set(u => u.Name, txtEditName.Text.Trim())
                    .Set(u => u.Email, txtEditEmail.Text.Trim())
                    .Set(u => u.Role, ddlEditRole.SelectedValue)
                    .Set(u => u.IsActive, chkEditActive.Checked);

                // Hash password if provided
                if (!string.IsNullOrWhiteSpace(txtEditPassword.Text))
                    upd = upd.Set(u => u.PasswordHash, HashPassword(txtEditPassword.Text.Trim())); // ✅ HASH IT

                _usersCol.UpdateOne(u => u.Id == hfEditUserId.Value, upd);
                ShowMessage("User updated.");
                ScriptManager.RegisterStartupScript(this, GetType(), "hideEditModal", "document.getElementById('editUserModal').style.display='none';", true);
                BindUsers();
            }
            catch (Exception ex)
            {
                ShowError("Update failed: " + ex.Message);
            }
        }

        private string HashPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
                return string.Empty;

            using (var rng = new RNGCryptoServiceProvider())
            {
                byte[] salt = new byte[16];
                rng.GetBytes(salt);

                using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256))
                {
                    byte[] hash = pbkdf2.GetBytes(20);
                    byte[] hashWithSalt = new byte[36];
                    Array.Copy(salt, 0, hashWithSalt, 0, 16);
                    Array.Copy(hash, 0, hashWithSalt, 16, 20);

                    return Convert.ToBase64String(hashWithSalt);
                }
            }
        }

        protected void btnAddUserSave_Click(object sender, EventArgs e)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(txtAddName.Text) || string.IsNullOrWhiteSpace(txtAddEmail.Text)) { ShowError("Name & Email required"); return; }
                var rawSnapshot = hfAddFaceSnapshot != null ? hfAddFaceSnapshot.Value : null;
                string faceEncoding = txtAddFaceEncoding.Text.Trim();
                string faceHash = txtAddFaceHash.Text.Trim();
                string faceImageUrl = null;
                string userFaceImageHash = null;
                if (!string.IsNullOrWhiteSpace(rawSnapshot))
                {
                    try
                    {
                        var faceService = new Services.FaceDetectionService();
                        faceEncoding = faceService.GenerateEncoding(rawSnapshot);
                        using (var sha = System.Security.Cryptography.SHA256.Create())
                        {
                            var bytes = sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(faceEncoding));
                            var sb = new System.Text.StringBuilder();
                            foreach (var b in bytes) sb.Append(b.ToString("x2"));
                            faceHash = sb.ToString();
                            // derive image hash too (hash of raw snapshot base64 for duplicate detection)
                            var imgBytes = sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(rawSnapshot.Substring(0, Math.Min(rawSnapshot.Length, 5000))));
                            var imgHash = BitConverter.ToString(imgBytes).Replace("-", string.Empty).ToLowerInvariant();
                            faceImageUrl = Helpers.CloudinaryHelper.UploadBase64(rawSnapshot, "faces");
                            if (!string.IsNullOrWhiteSpace(faceImageUrl) && rawSnapshot.Length > 25000) rawSnapshot = null;
                        }
                    }
                    catch { }
                }
                var user = new User
                {
                    Name = txtAddName.Text.Trim(),
                    Email = txtAddEmail.Text.Trim(),
                    Role = ddlAddRole.SelectedValue,
                    PasswordHash = HashPassword(txtAddPassword.Text.Trim()), // ✅ NOW HASHING
                    FaceEncoding = faceEncoding,
                    FaceHash = faceHash,
                    FaceImage = rawSnapshot,
                    FaceImageUrl = faceImageUrl,
                    FaceImageHash = userFaceImageHash,
                    FaceEncodingAlgorithm = "sha256-simulated",
                    FaceEncodingVersion = 1,
                    FaceEncodingUpdatedAt = DateTime.UtcNow,
                    IsActive = chkAddActive.Checked,
                    CreatedAt = DateTime.UtcNow
                };
                _usersCol.InsertOne(user);
                ShowMessage("User added");
                
                // Send credentials email to the new user
                try
                {
                    Services.SendEmaikService.SendUserCredentialsEmail(
                        userEmail: txtAddEmail.Text.Trim(),
                        userName: txtAddName.Text.Trim(),
                        password: txtAddPassword.Text.Trim(),
                        role: ddlAddRole.SelectedValue
                    );
                    System.Diagnostics.Debug.WriteLine($"✅ Credentials email queued for {txtAddEmail.Text.Trim()}");
                }
                catch (Exception emailEx)
                {
                    System.Diagnostics.Debug.WriteLine($"⚠️ Email notification failed: {emailEx.Message}");
                    // Continue even if email fails - user was still created
                }
                
                ClearAddModal();
                ScriptManager.RegisterStartupScript(this, GetType(), "hideAdd", "document.getElementById('addUserModal').style.display='none';", true);
                BindUsers();
            }
            catch (Exception ex) { ShowError("Add failed: " + ex.Message); }
        }

        private void ClearAddModal()
        {
            txtAddName.Text = txtAddEmail.Text = txtAddPassword.Text = string.Empty;
            ddlAddRole.SelectedValue = "User";
            txtAddFaceEncoding.Text = txtAddFaceHash.Text = string.Empty;
            chkAddActive.Checked = true;
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            ApplyFilter();
        }

        private void ApplyFilter()
        {
            try
            {
                var filter = Builders<User>.Filter.Empty;
                if (!string.IsNullOrWhiteSpace(txtSearch.Text))
                {
                    var term = txtSearch.Text.Trim();
                    filter &= Builders<User>.Filter.Or(
                        Builders<User>.Filter.Regex(u => u.Name, new MongoDB.Bson.BsonRegularExpression(term, "i")),
                        Builders<User>.Filter.Regex(u => u.Email, new MongoDB.Bson.BsonRegularExpression(term, "i"))
                    );
                }
                if (!string.IsNullOrWhiteSpace(ddlFilterRole.SelectedValue))
                {
                    filter &= Builders<User>.Filter.Eq(u => u.Role, ddlFilterRole.SelectedValue);
                }
                var list = _usersCol.Find(filter).SortByDescending(u => u.CreatedAt).ToList();
                gvUsers.DataSource = list; gvUsers.DataBind();
            }
            catch (Exception ex) { ShowError("Filter failed: " + ex.Message); }
        }

        [WebMethod]
        public static List<object> SearchTblUsers(string q)
        {
            try
            {
                q = (q ?? string.Empty).Trim();
                var col = DatabaseHelper.GetTblUserCollection(); // points to SheEssentials
                if (string.IsNullOrWhiteSpace(q))
                {
                    return new List<object>();
                }

                var escaped = Regex.Escape(q);
                var startsWith = col
                    .Find(Builders<TblUser>.Filter.Regex(u => u.FirstName, new MongoDB.Bson.BsonRegularExpression("^" + escaped, "i")))
                    .SortBy(u => u.FirstName)
                    .Limit(20)
                    .ToList();

                var results = new List<TblUser>(startsWith);

                if (results.Count < 20)
                {
                    var remaining = 20 - results.Count;
                    var containsFilter = Builders<TblUser>.Filter.Or(
                        Builders<TblUser>.Filter.Regex(u => u.FirstName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                        Builders<TblUser>.Filter.Regex(u => u.MiddleName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                        Builders<TblUser>.Filter.Regex(u => u.LastName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                        Builders<TblUser>.Filter.Regex(u => u.Email, new MongoDB.Bson.BsonRegularExpression(q, "i"))
                    );
                    var excludeIds = results.Select(r => r.Id).ToList();
                    if (excludeIds.Count > 0)
                    {
                        containsFilter &= Builders<TblUser>.Filter.Nin(u => u.Id, excludeIds);
                    }
                    var contains = col
                        .Find(containsFilter)
                        .SortBy(u => u.FirstName)
                        .Limit(remaining)
                        .ToList();
                    results.AddRange(contains);
                }

                // Build safe strings to avoid undefined in UI
                return results.Select(u => new
                {
                    u.Id,
                    Name = string.Join(" ", new[] { u.FirstName, u.MiddleName, u.LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim(),
                    FullName = string.Join(" ", new[] { u.FirstName, u.MiddleName, u.LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim(),
                    Display = string.Join(" ", new[] { u.FirstName, u.MiddleName, u.LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim(),
                    Email = u.Email ?? string.Empty,
                    IsEmailVerified = u.IsEmailVerified,
                    Role = u.Role ?? string.Empty
                }).Cast<object>().ToList();
            }
            catch
            {
                return new List<object>();
            }
        }

        [WebMethod]
        public static List<object> SearchEmployees(string q)
        {
            try
            {
                q = (q ?? string.Empty).Trim();
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] START - Query: '{q}'");

                if (string.IsNullOrWhiteSpace(q))
                    return new List<object>();

                // Get the HumanResourcesDB connection directly
                var hrConnString = System.Configuration.ConfigurationManager.ConnectionStrings["HumanResourcesConnection"]?.ConnectionString;
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] HR Connection available: {!string.IsNullOrEmpty(hrConnString)}");

                if (string.IsNullOrEmpty(hrConnString))
                {
                    System.Diagnostics.Debug.WriteLine($"[SearchEmployees] ERROR: HumanResourcesConnection not found in config");
                    return new List<object>();
                }

                var settings = MongoDB.Driver.MongoClientSettings.FromConnectionString(hrConnString);
                settings.ConnectTimeout = TimeSpan.FromSeconds(10);
                settings.ServerSelectionTimeout = TimeSpan.FromSeconds(10);
                var client = new MongoDB.Driver.MongoClient(settings);
                var db = client.GetDatabase("HumanResourcesDB");
                var col = db.GetCollection<Employee>("Employees");

                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] Collection retrieved");

                // Count total employees
                var totalCount = col.CountDocuments(FilterDefinition<Employee>.Empty);
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] Total employees: {totalCount}");

                // Count Inventory employees
                var inventoryCount = col.CountDocuments(e => e.Department == "Inventory");
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] Inventory employees: {inventoryCount}");

                // Build search filter
                var nameFilter = Builders<Employee>.Filter.Or(
                    Builders<Employee>.Filter.Regex(e => e.FirstName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                    Builders<Employee>.Filter.Regex(e => e.LastName, new MongoDB.Bson.BsonRegularExpression(q, "i")),
                    Builders<Employee>.Filter.Regex(e => e.Email, new MongoDB.Bson.BsonRegularExpression(q, "i"))
                );

                var deptFilter = Builders<Employee>.Filter.Eq(e => e.Department, "Inventory");
                var combinedFilter = Builders<Employee>.Filter.And(deptFilter, nameFilter);

                var results = col.Find(combinedFilter)
                    .SortBy(e => e.FirstName)
                    .Limit(20)
                    .ToList();

                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] Found {results.Count} matching employees");

                foreach (var emp in results)
                {
                    System.Diagnostics.Debug.WriteLine($"[SearchEmployees] Result: {emp.FirstName} {emp.LastName} - {emp.Email} ({emp.Department})");
                }

                return results.Select(u => new
                {
                    Id = u.Id ?? string.Empty,
                    FirstName = u.FirstName ?? string.Empty,
                    LastName = u.LastName ?? string.Empty,
                    Name = string.Join(" ", new[] { u.FirstName, u.MiddleName, u.LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim(),
                    Email = u.Email ?? string.Empty,
                    Role = u.Role ?? string.Empty,
                    Department = u.Department ?? string.Empty,
                    IsEmailVerified = false
                }).Cast<object>().ToList();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] EXCEPTION: {ex.GetType().Name}");
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] MESSAGE: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[SearchEmployees] STACK: {ex.StackTrace}");
                return new List<object>();
            }
        }
    }
}