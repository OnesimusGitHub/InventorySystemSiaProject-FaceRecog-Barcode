<%@ WebHandler Language="C#" Class="GetArchivedProducts" %>

using System;
using System.Web;
using System.Text;
using System.Linq;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;
using System.Collections.Generic;
using Newtonsoft.Json;

public class GetArchivedProducts : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        try
        {
            var productsCollection = DatabaseHelper.GetProductsCollection();
            var productVariantsCollection = DatabaseHelper.GetProductVariantsCollection();
            
            var filterBuilder = Builders<Product>.Filter;
            
            // Match products with Status: "Inactive" or "In Active" (case insensitive)
            var filter = filterBuilder.Regex(p => p.Status, new BsonRegularExpression("^(in\\s*active|inactive)$", "i"));
            
            var products = productsCollection.Find(filter).ToList();
            
            var result = products.Select(p => {
                var stockCount = 0;
                try
                {
                    var variants = productVariantsCollection
                        .Find(Builders<ProductVariant>.Filter.Eq("productId", p.Id))
                        .ToList();
                    stockCount = variants.Sum(v => v.StockQuantity);
                }
                catch
                {
                    stockCount = 0;
                }
                
                return new {
                    ProductId = p.Id,
                    ProductName = p.ProductName ?? "",
                    ProductCategory = p.ProductCategory ?? "",
                    ProductImg = (!string.IsNullOrWhiteSpace(p.ProductImg)) ? p.ProductImg : "/Content/images/sample-generic.png",
                    ProductVal = p.ProductVal,
                    StockCount = stockCount,
                    Status = p.Status ?? ""
                };
            }).OrderByDescending(p => p.ProductName).ToList();
            
            context.Response.Write(JsonConvert.SerializeObject(new { success = true, products = result }));
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            var errorMessage = ex.Message + (ex.InnerException != null ? " | Inner: " + ex.InnerException.Message : "");
            context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = errorMessage }));
        }
    }

    public bool IsReusable { get { return false; } }
}
