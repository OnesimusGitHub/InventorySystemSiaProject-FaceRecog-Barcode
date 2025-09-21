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
            }
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
    }
}