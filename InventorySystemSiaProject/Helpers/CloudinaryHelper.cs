using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using System;
using System.Web;
using System.IO;

namespace InventorySystemSiaProject.Helpers
{
    public static class CloudinaryHelper
    {
        private static readonly Lazy<Cloudinary> _cloud = new Lazy<Cloudinary>(() =>
        {
            var cloud = System.Configuration.ConfigurationManager.AppSettings["CloudinaryCloudName"];            
            var key = System.Configuration.ConfigurationManager.AppSettings["CloudinaryApiKey"];            
            var secret = System.Configuration.ConfigurationManager.AppSettings["CloudinaryApiSecret"];            
            if (string.IsNullOrWhiteSpace(cloud) || string.IsNullOrWhiteSpace(key) || string.IsNullOrWhiteSpace(secret))
                throw new InvalidOperationException("Cloudinary credentials are not configured in Web.config appSettings.");
            var account = new Account(cloud, key, secret);
            var c = new Cloudinary(account) { Api = { Secure = true } };
            return c;
        });

        public static Cloudinary Instance => _cloud.Value;

        public static string UploadImage(HttpPostedFile file, string folder = "products")
        {
            if (file == null || file.ContentLength == 0) return null;
            var uploadParams = new ImageUploadParams
            {
                File = new FileDescription(file.FileName, file.InputStream),
                Folder = folder,
                UseFilename = true,
                UniqueFilename = true,
                Overwrite = false,
                Transformation = new Transformation().Quality("auto").FetchFormat("auto")
            };
            var result = Instance.Upload(uploadParams);
            if (result.StatusCode == System.Net.HttpStatusCode.OK)
                return result.SecureUrl?.ToString();
            return null;
        }

        public static string UploadBase64(string dataUrl, string folder = "faces")
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dataUrl)) return null;
                // Expect data:[mime];base64,xxxx
                var comma = dataUrl.IndexOf(',');
                if (comma > 0) dataUrl = dataUrl.Substring(comma + 1);
                // Some client sent through btoa(dataURL) previously; attempt to detect and decode nested base64
                byte[] bytes;
                try { bytes = Convert.FromBase64String(dataUrl); }
                catch { return null; }
                if (bytes.Length < 500) return null; // ignore very small images
                using (var ms = new MemoryStream(bytes))
                {
                    var uploadParams = new ImageUploadParams
                    {
                        File = new FileDescription($"face_{Guid.NewGuid():N}.png", ms),
                        Folder = folder,
                        UseFilename = true,
                        UniqueFilename = true,
                        Overwrite = false,
                        Transformation = new Transformation().Quality("auto").FetchFormat("auto")
                    };
                    var result = Instance.Upload(uploadParams);
                    if (result.StatusCode == System.Net.HttpStatusCode.OK)
                        return result.SecureUrl?.ToString();
                }
            }
            catch { }
            return null;
        }

        public static bool DeleteAsset(string publicId)
        {
            if (string.IsNullOrWhiteSpace(publicId)) return false;
            var del = new DeletionParams(publicId) { Invalidate = true };
            var result = Instance.Destroy(del);
            return result.Result == "ok";
        }
    }
}
