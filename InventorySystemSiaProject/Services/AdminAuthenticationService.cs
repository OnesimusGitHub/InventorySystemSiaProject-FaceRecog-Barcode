using System;

namespace InventorySystemSiaProject.Handlers
{
    public static class AdminAuthenticationService
    {
        // Simple admin password validation
        // In a production environment, this should be more secure
        private const string ADMIN_PASSWORD = "admin123"; // Change this to a secure password

        public static bool ValidateAdminPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
                return false;

            // In production, you should hash and compare passwords securely
            return password == ADMIN_PASSWORD;
        }
    }
}