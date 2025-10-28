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

        private void BindData(DateTime? startDate = null, DateTime? endDate = null)
        {
            var coll = DatabaseHelper.GetActivityLogCollection();
            var filter = Builders<Models.ActivityLog>.Filter.Empty;

            if (startDate.HasValue || endDate.HasValue)
            {
                var builder = Builders<Models.ActivityLog>.Filter;
                if (startDate.HasValue && endDate.HasValue)
                {
                    filter = builder.Gte("Timestamp", startDate.Value.Date)
                        & builder.Lte("Timestamp", endDate.Value.Date.AddDays(1).AddTicks(-1));
                }
                else if (startDate.HasValue)
                {
                    filter = builder.Gte("Timestamp", startDate.Value.Date);
                }
                else if (endDate.HasValue)
                {
                    filter = builder.Lte("Timestamp", endDate.Value.Date.AddDays(1).AddTicks(-1));
                }
            }

            var list = coll.Find(filter)
                           .SortByDescending(a => a.Timestamp)
                           .Limit(200)
                           .ToList();
            gvActivity.DataSource = list;
            gvActivity.DataBind();
        }

        protected void btnFilterDate_Click(object sender, EventArgs e)
        {
            DateTime? startDate = null;
            DateTime? endDate = null;
            DateTime temp;
            if (DateTime.TryParse(txtStartDate.Text, out temp))
                startDate = temp;
            if (DateTime.TryParse(txtEndDate.Text, out temp))
                endDate = temp;
            BindData(startDate, endDate);
        }
    }
}
