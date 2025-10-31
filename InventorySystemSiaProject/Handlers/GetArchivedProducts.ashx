<%@ WebHandler Language="C#" Class="InventorySystemSiaProject.Handlers.GetArchivedProducts" %>

using System;
using System.Web;
using System.Text;
using System.Linq;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using System.Collections.Generic;

namespace InventorySystemSiaProject.Handlers
{
    public class GetArchivedProducts : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            try
            {
                var productsCollection = DatabaseHelper.GetProductsCollection();
                var suppliersCollection = DatabaseHelper.GetSuppliersCollection();
                var productVariantsCollection = DatabaseHelper.GetProductVariantsCollection();
                var filterBuilder = Builders<Product>.Filter;
                // Updated: Use regex to match all variants of "inactive" and "in active" (case/space insensitive)
                var filter = filterBuilder.Regex(p => p.Status, new MongoDB.Bson.BsonRegularExpression("^(in\\s*active|inactive)$", "i"));
                var products = productsCollection.Find(filter).ToList();
                // Fetch all suppliers and build a dictionary for quick lookup
                var allSuppliers = suppliersCollection.Find(Builders<Supplier>.Filter.Empty).ToList();
                var supplierDict = allSuppliers.ToDictionary(s => s.SupplierID, s => s.SupName);
                var result = products.Select(p => {
                    var stockCount = productVariantsCollection
                        .Find(Builders<ProductVariant>.Filter.Eq("productId", p.Id))
                        .ToList()
                        .Sum(v => v.StockQuantity);
                    return new {
                        ProductId = p.Id,
                        p.ProductName,
                        p.ProductCategory,
                        SupplierName = (p.SupplierId != null && supplierDict.ContainsKey(p.SupplierId))
                            ? supplierDict[p.SupplierId]
                            : string.Empty,
                        ProductImg = (!string.IsNullOrWhiteSpace(p.ProductImg)) ? p.ProductImg : "/Content/images/sample-generic.png",
                        p.ProductVal,
                        StockCount = stockCount,
                        p.Status // Added Status so frontend can filter
                    };
                }).OrderByDescending(p => p.ProductName).ToList();
                context.Response.Write(Newtonsoft.Json.JsonConvert.SerializeObject(new { success = true, products = result }));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"success\":false,\"error\":\"" + ex.Message + "\"}");
            }
        }

        public bool IsReusable { get { return false; } }
    }
}
