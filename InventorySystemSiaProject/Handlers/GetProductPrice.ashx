<%@ WebHandler Language="C#" Class="GetProductPrice" %>

using System;
using System.Web;
using System.Linq;
using System.Collections.Generic;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;
using MongoDB.Driver;
using MongoDB.Bson;
using Newtonsoft.Json;

public class GetProductPrice : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        try
        {
            string productId = context.Request.QueryString["productId"];
            if (string.IsNullOrEmpty(productId))
            {
                context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = "productId is required" }));
                return;
            }

            System.Diagnostics.Debug.WriteLine("GetProductPrice called for productId=" + productId);

            var productsCollection = DatabaseHelper.GetProductsCollection();
            var productVariantsCollection = DatabaseHelper.GetProductVariantsCollection();

            Product product = null;
            try
            {
                product = productsCollection.Find(Builders<Product>.Filter.Eq(p => p.Id, productId)).FirstOrDefault();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error fetching product: " + ex.Message);
            }

            List<ProductVariant> variants = new List<ProductVariant>();

            // Try matching productId as string first, then as ObjectId if no results
            try
            {
                var filterString = Builders<ProductVariant>.Filter.Eq("productId", productId);
                variants = productVariantsCollection.Find(filterString).ToList();
                System.Diagnostics.Debug.WriteLine("Variants found using string filter: " + (variants != null ? variants.Count.ToString() : "0"));

                if ((variants == null || variants.Count == 0))
                {
                    // Try matching as ObjectId (some documents may store productId as ObjectId type)
                    try
                    {
                        var oid = new ObjectId(productId);
                        var filterObjectId = Builders<ProductVariant>.Filter.Eq("productId", oid);
                        variants = productVariantsCollection.Find(filterObjectId).ToList();
                        System.Diagnostics.Debug.WriteLine("Variants found using ObjectId filter: " + (variants != null ? variants.Count.ToString() : "0"));
                    }
                    catch (FormatException) { /* invalid ObjectId format */ }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Error trying ObjectId filter: " + ex.Message);
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error fetching variants: " + ex.Message);
                variants = new List<ProductVariant>();
            }

            int variantCount = variants != null ? variants.Count : 0;
            int totalStock = variants != null ? variants.Sum(v => v.StockQuantity) : 0;
            decimal? lowestPrice = null;
            decimal? highestPrice = null;

            if (variants != null && variants.Count > 0)
            {
                try
                {
                    lowestPrice = variants.Min(v => v.Price);
                    highestPrice = variants.Max(v => v.Price);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Error computing min/max price: " + ex.Message);
                }
            }

            decimal displayPrice = lowestPrice.HasValue ? lowestPrice.Value : (product != null ? product.productVal : 0m);
            string priceRange;
            if (lowestPrice.HasValue && highestPrice.HasValue)
            {
                if (lowestPrice.Value == highestPrice.Value)
                    priceRange = string.Format("?{0:F2}", lowestPrice.Value);
                else
                    priceRange = string.Format("?{0:F2} - ?{1:F2}", lowestPrice.Value, highestPrice.Value);
            }
            else
            {
                priceRange = string.Format("?{0:F2}", displayPrice);
            }

            bool includeRaw = context.Request.QueryString["debug"] == "1";
            object rawVariants = null;
            if (includeRaw && variants != null)
            {
                rawVariants = variants.Select(v => new { id = v.Id, price = v.Price, stock = v.StockQuantity, isActive = v.IsActive }).ToList();
            }
            System.Diagnostics.Debug.WriteLine(string.Format("GetProductPrice result: variantCount={0}, displayPrice={1}", variantCount, displayPrice));

            context.Response.Write(JsonConvert.SerializeObject(new
            {
                success = true,
                productId = productId,
                displayPrice = displayPrice,
                priceRange = priceRange,
                variantCount = variantCount,
                totalStock = totalStock,
                rawVariants = rawVariants
            }));
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            System.Diagnostics.Debug.WriteLine("GetProductPrice error: " + ex.Message + "\n" + ex.StackTrace);
            context.Response.Write(JsonConvert.SerializeObject(new { success = false, error = ex.Message }));
        }
    }

    public bool IsReusable { get { return false; } }
}