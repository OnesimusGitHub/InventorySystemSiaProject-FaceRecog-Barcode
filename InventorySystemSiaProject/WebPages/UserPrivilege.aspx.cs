using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;

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
                PasswordHash = password, // TODO: hash
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
            if (!string.IsNullOrWhiteSpace(password))
                update = update.Set(u => u.PasswordHash, password);
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
                    txtEditShortPass.Text = user.ShortPass;
                    chkEditActive.Checked = user.IsActive;
                    // show modal via script
                    ScriptManager.RegisterStartupScript(this, GetType(), "showEditModal", "document.getElementById('editUserModal').style.display='flex';", true);
                }
            }
        }

        protected void btnUpdateUser_Click(object sender, EventArgs e)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(hfEditUserId.Value)) { ShowError("No user selected"); return; }
                var rawEditSnapshot = hfEditFaceSnapshot != null ? hfEditFaceSnapshot.Value : null;
                var upd = Builders<User>.Update
                    .Set(u => u.Name, txtEditName.Text.Trim())
                    .Set(u => u.Email, txtEditEmail.Text.Trim())
                    .Set(u => u.Role, ddlEditRole.SelectedValue)
                    .Set(u => u.ShortPass, txtEditShortPass.Text.Trim())
                    .Set(u => u.IsActive, chkEditActive.Checked);
                if(!string.IsNullOrWhiteSpace(rawEditSnapshot))
                {
                    try
                    {
                        var faceService = new Services.FaceDetectionService();
                        var newEncoding = faceService.GenerateEncoding(rawEditSnapshot);
                        string newHash;
                        using(var sha=System.Security.Cryptography.SHA256.Create())
                        {
                            var bytes=sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(newEncoding));
                            var sb=new System.Text.StringBuilder();
                            foreach(var b in bytes) sb.Append(b.ToString("x2"));
                            newHash = sb.ToString();
                        }
                        var faceUrl = Helpers.CloudinaryHelper.UploadBase64(rawEditSnapshot, "faces");
                        bool keepRaw = string.IsNullOrWhiteSpace(faceUrl) || rawEditSnapshot.Length <= 25000; // keep if small or upload failed
                        upd = upd.Set(u => u.FaceEncoding, newEncoding)
                                 .Set(u => u.FaceHash, newHash)
                                 .Set(u => u.FaceImage, keepRaw ? rawEditSnapshot : null)
                                 .Set(u => u.FaceImageUrl, faceUrl)
                                 .Set(u => u.FaceEncodingUpdatedAt, DateTime.UtcNow)
                                 .Set(u => u.FaceEncodingAlgorithm, "sha256-simulated")
                                 .Set(u => u.FaceEncodingVersion, 1);
                    }
                    catch { }
                }
                if (!string.IsNullOrWhiteSpace(txtEditPassword.Text))
                    upd = upd.Set(u => u.PasswordHash, txtEditPassword.Text.Trim());
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
                if(!string.IsNullOrWhiteSpace(rawSnapshot))
                {
                    try
                    {
                        var faceService = new Services.FaceDetectionService();
                        faceEncoding = faceService.GenerateEncoding(rawSnapshot);
                        using (var sha = System.Security.Cryptography.SHA256.Create())
                        {
                            var bytes = sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(faceEncoding));
                            var sb = new System.Text.StringBuilder();
                            foreach(var b in bytes) sb.Append(b.ToString("x2"));
                            faceHash = sb.ToString();
                            // derive image hash too (hash of raw snapshot base64 for duplicate detection)
                            var imgBytes = sha.ComputeHash(System.Text.Encoding.UTF8.GetBytes(rawSnapshot.Substring(0, Math.Min(rawSnapshot.Length, 5000))));
                            var imgHash = BitConverter.ToString(imgBytes).Replace("-", string.Empty).ToLowerInvariant();
                            faceImageUrl = Helpers.CloudinaryHelper.UploadBase64(rawSnapshot, "faces");
                            if(!string.IsNullOrWhiteSpace(faceImageUrl) && rawSnapshot.Length > 25000) rawSnapshot = null;
                        }
                    }
                    catch { }
                }
                var user = new User
                {
                    Name = txtAddName.Text.Trim(),
                    Email = txtAddEmail.Text.Trim(),
                    Role = ddlAddRole.SelectedValue,
                    PasswordHash = txtAddPassword.Text.Trim(),
                    FaceEncoding = faceEncoding,
                    FaceHash = faceHash,
                    FaceImage = rawSnapshot,
                    FaceImageUrl = faceImageUrl,
                    FaceImageHash = userFaceImageHash,
                    FaceEncodingAlgorithm = "sha256-simulated",
                    FaceEncodingVersion = 1,
                    FaceEncodingUpdatedAt = DateTime.UtcNow,
                    ShortPass = txtAddShortPass.Text.Trim(),
                    IsActive = chkAddActive.Checked,
                    CreatedAt = DateTime.UtcNow
                };
                _usersCol.InsertOne(user);
                ShowMessage("User added");
                ClearAddModal();
                ScriptManager.RegisterStartupScript(this, GetType(), "hideAdd", "document.getElementById('addUserModal').style.display='none';", true);
                BindUsers();
            }
            catch (Exception ex) { ShowError("Add failed: " + ex.Message); }
        }

        private void ClearAddModal()
        {
            txtAddName.Text = txtAddEmail.Text = txtAddPassword.Text = txtAddShortPass.Text = string.Empty;
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
    }
}