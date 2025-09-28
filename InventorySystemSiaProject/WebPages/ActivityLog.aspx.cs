using System;
using System.Linq;
using System.Web.UI;
using InventorySystemSiaProject.Helpers;
using InventorySystemSiaProject.Models;
using MongoDB.Driver;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ActivityLogPage : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                BindData();
            }
        }

        private void BindData()
        {
            var coll = DatabaseHelper.GetActivityLogCollection();
            var list = coll.Find(Builders<ActivityLog>.Filter.Empty)
                           .SortByDescending(a => a.Timestamp)
                           .Limit(200)
                           .ToList();
            gvActivity.DataSource = list;
            gvActivity.DataBind();
        }
    }
}
