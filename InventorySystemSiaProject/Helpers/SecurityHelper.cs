using System;

namespace InventorySystemSiaProject.Helpers
{
    /// <summary>
    /// Security utilities for token generation and validation
    /// </summary>
    public static class SecurityHelper
    {
        /// <summary>
        /// Generates a security token for email links
        /// </summary>
        public static string GenerateToken(string requestId, DateTime requestDate)
        {
            // Simple token generation - in production, use more secure method
            string data = $"{requestId}:{requestDate:yyyyMMddHHmmss}:InventorySystem2024";
            return Convert.ToBase64String(
                System.Text.Encoding.UTF8.GetBytes(
                    data.GetHashCode().ToString()
                )
            ).Replace("+", "-").Replace("/", "_").Replace("=", "");
        }
    }
}
