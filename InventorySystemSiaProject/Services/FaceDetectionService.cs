using System;
using System.Security.Cryptography;
using System.Text;

namespace InventorySystemSiaProject.Services
{
    public class FaceDetectionService
    {
        public string GenerateEncoding(string base64Image)
        {
            if (string.IsNullOrWhiteSpace(base64Image))
                throw new ArgumentException("Image data cannot be empty", nameof(base64Image));

            int commaIndex = base64Image.IndexOf(',');
            if (commaIndex > 0 && base64Image.Substring(0, commaIndex).Contains("base64"))
            {
                base64Image = base64Image.Substring(commaIndex + 1);
            }

            if (base64Image.Length < 1000)
                throw new InvalidOperationException("Image data too small for face encoding");

            using (var sha256 = SHA256.Create())
            {
                var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(base64Image));
                var sb = new StringBuilder();
                foreach (var b in bytes)
                {
                    sb.Append(b.ToString("x2"));
                }
                return sb.ToString();
            }
        }

        public double CompareEncodings(string encoding1, string encoding2)
        {
            if (string.IsNullOrEmpty(encoding1) || string.IsNullOrEmpty(encoding2))
                return double.MaxValue;

            int length = Math.Min(encoding1.Length, encoding2.Length);
            if (length == 0) return double.MaxValue;

            int matches = 0;
            for (int i = 0; i < length; i++)
            {
                if (encoding1[i] == encoding2[i])
                    matches++;
            }

            double similarity = (double)matches / length;
            return 1.0 - similarity;
        }

        public bool IsMatch(string encoding1, string encoding2, double threshold = 0.85)
        {
            return CompareEncodings(encoding1, encoding2) <= threshold;
        }
    }
}