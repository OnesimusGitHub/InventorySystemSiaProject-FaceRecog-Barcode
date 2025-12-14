using System;
using System.Security.Cryptography;
using System.Text;

namespace InventorySystemSiaProject.TestHelpers
{
    /// <summary>
    /// Quick test helper to verify the password hash format
    /// Add this temporarily to test your specific hash
    /// </summary>
    public static class PasswordHashTester
    {
        public static void TestYourHash()
        {
            string password = "HihiAyy123!";
            string storedHash = "/km7+MLUCLA7dkBSd+XXXQ==.b5qTM3h11geJqU/aKXb31O4v1s3UmE4WFP1YvFEyL6U=";
            
            Console.WriteLine("=== PASSWORD HASH TEST ===");
            Console.WriteLine($"Password: {password}");
            Console.WriteLine($"Stored Hash: {storedHash}");
            Console.WriteLine();
            
            // Parse the hash
            var lastDotIndex = storedHash.LastIndexOf('.');
            if (lastDotIndex > 0)
            {
                string salt = storedHash.Substring(0, lastDotIndex);
                string expectedHash = storedHash.Substring(lastDotIndex + 1);
                
                Console.WriteLine($"Salt: {salt}");
                Console.WriteLine($"Expected Hash: {expectedHash}");
                Console.WriteLine($"Expected Hash Length: {expectedHash.Length}");
                Console.WriteLine();
                
                // Test SHA256(password + salt)
                using (var sha256 = SHA256.Create())
                {
                    var hash1 = Convert.ToBase64String(sha256.ComputeHash(Encoding.UTF8.GetBytes(password + salt)));
                    Console.WriteLine($"SHA256(password+salt): {hash1}");
                    Console.WriteLine($"Match: {hash1 == expectedHash}");
                    Console.WriteLine();
                }
                
                // Test SHA256(salt + password)
                using (var sha256 = SHA256.Create())
                {
                    var hash2 = Convert.ToBase64String(sha256.ComputeHash(Encoding.UTF8.GetBytes(salt + password)));
                    Console.WriteLine($"SHA256(salt+password): {hash2}");
                    Console.WriteLine($"Match: {hash2 == expectedHash}");
                    Console.WriteLine();
                }
                
                // Test SHA512(password + salt)
                using (var sha512 = System.Security.Cryptography.SHA512.Create())
                {
                    var hash3 = Convert.ToBase64String(sha512.ComputeHash(Encoding.UTF8.GetBytes(password + salt)));
                    Console.WriteLine($"SHA512(password+salt): {hash3}");
                    Console.WriteLine($"Match: {hash3 == expectedHash}");
                    Console.WriteLine();
                }
                
                // Test SHA512(salt + password)
                using (var sha512 = System.Security.Cryptography.SHA512.Create())
                {
                    var hash4 = Convert.ToBase64String(sha512.ComputeHash(Encoding.UTF8.GetBytes(salt + password)));
                    Console.WriteLine($"SHA512(salt+password): {hash4}");
                    Console.WriteLine($"Match: {hash4 == expectedHash}");
                    Console.WriteLine();
                }
            }
            
            Console.WriteLine("=== END TEST ===");
        }
    }
}
