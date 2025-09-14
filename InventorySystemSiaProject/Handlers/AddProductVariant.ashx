<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.AddProductVariant" %>

using System;
using System.Web;
using System.Web.Script.Serialization; // fixed namespace
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Handlers
{
    public class AddProductVariant : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            var serializer = new JavaScriptSerializer();

            try
            {
                context.Request.InputStream.Position = 0;
                using (var reader = new System.IO.StreamReader(context.Request.InputStream))
                {
                    var raw = reader.ReadToEnd();
                    var variantData = serializer.Deserialize<ProductVariant>(raw);

                    if (variantData == null || string.IsNullOrWhiteSpace(variantData.ProductId))
                    {
                        throw new ArgumentException("Invalid variant data or missing Product ID.");
                    }

                    if (string.IsNullOrWhiteSpace(variantData.VariantImg))
                    {
                        variantData.VariantImg = "/Content/images/sample-generic.png"; // default placeholder
                    }

                    var variantsColl = DatabaseHelper.GetProductVariantsCollection();
                    variantData.CreatedAt = DateTime.UtcNow;
                    variantData.UpdatedAt = DateTime.UtcNow;
                    variantData.IsActive = true;

                    variantsColl.InsertOne(variantData);

                    context.Response.Write(serializer.Serialize(new { success = true, message = "Variant added successfully." }));
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write(serializer.Serialize(new { error = ex.Message }));
            }
        }

        public bool IsReusable { get { return false; } }
    }
}