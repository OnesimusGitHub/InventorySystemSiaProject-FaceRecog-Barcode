using System;
using System.Collections.Generic;
using System.Web.UI;
using InventorySystemSiaProject.Services;

namespace InventorySystemSiaProject.WebPages
{
    public partial class ExpiryTracker : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Nothing server-side required for now; handlers provide JSON endpoints used by client JS
        }
    }
}
