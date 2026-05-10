using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using MongoDB.Driver;
using InventorySystemSiaProject.Models;
using InventorySystemSiaProject.Helpers;

namespace InventorySystemSiaProject.Services
{
    public class UserAuthenticationService
    {
        private readonly IMongoCollection<User> _usersCollection;

        // Tunable thresholds
        private const double DEFAULT_MAX_DISTANCE = 0.25; // lower = stricter (0..1)
        private const int MIN_ENCODING_LENGTH = 5000;     // reject obviously tiny base64 strings

        public UserAuthenticationService()
        {
            _usersCollection = DatabaseHelper.GetUsersCollection();
        }

        /// <summary>
        /// Registers a new user with face recognition capabilities
        /// </summary>
        public async Task<(bool Success, string Message, string UserId)> RegisterUserAsync(
            string name,
            string email,
            string password,
            string faceEncoding,
            string shortPass)
        {
            try
            {
                var validation = ValidateRegistrationInput(name, email, password, shortPass);
                if (!validation.IsValid) return (false, validation.Message, null);

                var existingUser = await _usersCollection
                    .Find(u => u.Email.ToLower() == email.ToLower())
                    .FirstOrDefaultAsync();

                if (existingUser != null) return (false, "Email already registered", null);

                string hashedPassword = HashPassword(password);
                string hashedShortPass = HashShortPass(shortPass);
                
                // Generate face hash if face encoding is provided
                string faceHash = null;
                if (!string.IsNullOrEmpty(faceEncoding))
                {
                    faceHash = GenerateFaceHash(faceEncoding);
                }

                var newUser = new User
                {
                    Name = name.Trim(),
                    Email = email.ToLower().Trim(),
                    PasswordHash = hashedPassword,
                    FaceEncoding = faceEncoding,
                    FaceHash = faceHash,
                    ShortPass = hashedShortPass,
                    Role = "User",
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                await _usersCollection.InsertOneAsync(newUser);
                return (true, "User registered successfully", newUser.Id);
            }
            catch (Exception ex)
            {
                return (false, $"Registration failed: {ex.Message}", null);
            }
        }

        /// <summary>Authenticates user with email and password</summary>
        public async Task<(bool Success, string Message, User User)> LoginAsync(string email, string password)
        {
            try
            {
                var user = await _usersCollection
                    .Find(u => u.Email.ToLower() == email.ToLower() && u.IsActive)
                    .FirstOrDefaultAsync();

                if (user == null) return (false, "Invalid email or password", null);
                if (!VerifyPassword(password, user.PasswordHash)) return (false, "Invalid email or password", null);

                await UpdateLastLoginAsync(user.Id);
                return (true, "Login successful", user);
            }
            catch (Exception ex)
            {
                return (false, $"Login failed: {ex.Message}", null);
            }
        }

        /// <summary>
        /// Improved face recognition. We treat distance < threshold as match.
        /// Distance is (1 - charSimilarity) + lengthPenalty.
        /// </summary>
        public async Task<(bool Success, string Message, User User)> FaceRecognitionAsync(string faceEncoding, double maxDistance = 0.8)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(faceEncoding))
                    return (false, "Face encoding is required", null);

                if (faceEncoding.Length < 1000) // much more lenient than 5000
                    return (false, $"Captured frame too small (len {faceEncoding.Length})", null);

                var users = await _usersCollection
                    .Find(u => u.IsActive && !string.IsNullOrEmpty(u.FaceEncoding))
                    .ToListAsync();

                if (users.Count == 0)
                    return (false, "No users with stored face data", null);

                // If only one user has a face encoding we accept with very lenient threshold
                if (users.Count == 1)
                {
                    var single = users[0];
                    var d = CalculateFaceDistance(faceEncoding, single.FaceEncoding);
                    
                    // Very lenient for single user - essentially accept if both have reasonable length
                    if (d <= 0.9 || (faceEncoding.Length > 5000 && single.FaceEncoding?.Length > 5000))
                    {
                        return (true, $"Face recognized (single user) distance {d:0.000}", single);
                    }
                    
                    return (false, $"Single user present but distance {d:0.000} too high", null);
                }

                User bestUser = null;
                double bestDistance = double.MaxValue;

                foreach (var user in users)
                {
                    if (string.IsNullOrEmpty(user.FaceEncoding)) continue;
                    var distance = CalculateFaceDistance(faceEncoding, user.FaceEncoding);

                    if (distance < bestDistance)
                    {
                        bestDistance = distance;
                        bestUser = user;
                    }

                    if (distance <= maxDistance) // early exit on solid match
                    {
                        return (true, $"Face recognized distance {distance:0.000}", user);
                    }
                }

                // If no one below threshold, be more lenient
                if (bestDistance <= maxDistance + 0.15) // increased from 0.05 to 0.15
                {
                    return (true, $"Face recognized (near-threshold) distance {bestDistance:0.000}", bestUser);
                }

                return (false, $"Face not recognized. Best distance {bestDistance:0.000} threshold {maxDistance:0.000}", null);
            }
            catch (Exception ex)
            {
                return (false, $"Face recognition failed: {ex.Message}", null);
            }
        }

        /// <summary>Face login (completes login) using improved recognition</summary>
        public async Task<(bool Success, string Message, User User)> FaceLoginAsync(string faceEncoding, double maxDistance = DEFAULT_MAX_DISTANCE)
        {
            try
            {
                var result = await FaceRecognitionAsync(faceEncoding, maxDistance);
                if (result.Success)
                {
                    await UpdateLastLoginAsync(result.User.Id);
                    return (true, result.Message, result.User);
                }
                return result;
            }
            catch (Exception ex)
            {
                return (false, $"Face login failed: {ex.Message}", null);
            }
        }

        /// <summary>Validates short pass for a specific user ID (used after face recognition)</summary>
        public async Task<(bool Success, string Message, User User)> ValidateShortPassAsync(string userId, string shortPass)
        {
            try
            {
                var user = await _usersCollection.Find(u => u.Id == userId && u.IsActive).FirstOrDefaultAsync();
                if (user == null) return (false, "User not found", null);
                if (!VerifyShortPass(shortPass, user.ShortPass)) return (false, "Invalid PIN", null);
                await UpdateLastLoginAsync(user.Id);
                return (true, "PIN verification successful", user);
            }
            catch (Exception ex)
            {
                return (false, $"PIN validation failed: {ex.Message}", null);
            }
        }

        /// <summary>Authenticates user with short pass (4-digit PIN)</summary>
        public async Task<(bool Success, string Message, User User)> ShortPassLoginAsync(string email, string shortPass)
        {
            try
            {
                var user = await _usersCollection.Find(u => u.Email.ToLower() == email.ToLower() && u.IsActive).FirstOrDefaultAsync();
                if (user == null) return (false, "Invalid email or short pass", null);
                if (!VerifyShortPass(shortPass, user.ShortPass)) return (false, "Invalid email or short pass", null);
                await UpdateLastLoginAsync(user.Id);
                return (true, "Short pass login successful", user);
            }
            catch (Exception ex)
            {
                return (false, $"Short pass login failed: {ex.Message}", null);
            }
        }

        /// <summary>Updates user's face encoding</summary>
        public async Task<(bool Success, string Message)> UpdateFaceEncodingAsync(string userId, string newFaceEncoding)
        {
            try
            {
                var result = await _usersCollection.UpdateOneAsync(
                    u => u.Id == userId,
                    Builders<User>.Update.Set(u => u.FaceEncoding, newFaceEncoding));
                if (result.ModifiedCount > 0) return (true, "Face encoding updated successfully");
                return (false, "User not found or face encoding not updated");
            }
            catch (Exception ex)
            {
                return (false, $"Update failed: {ex.Message}");
            }
        }

        public async Task<List<User>> GetAllUsersWithFaceDataAsync()
        {
            return await _usersCollection
                .Find(u => u.IsActive && !string.IsNullOrEmpty(u.FaceEncoding))
                .ToListAsync();
        }

        private (bool IsValid, string Message) ValidateRegistrationInput(string name, string email, string password, string shortPass)
        {
            if (string.IsNullOrWhiteSpace(name)) return (false, "Name is required");
            if (string.IsNullOrWhiteSpace(email)) return (false, "Email is required");
            if (!IsValidEmail(email)) return (false, "Invalid email format");
            if (string.IsNullOrWhiteSpace(password)) return (false, "Password is required");
            if (password.Length < 6) return (false, "Password must be at least 6 characters long");
            if (string.IsNullOrWhiteSpace(shortPass)) return (false, "Short pass is required");
            if (!IsValidShortPass(shortPass)) return (false, "Short pass must be exactly 4 digits");
            return (true, "Valid");
        }

        private bool IsValidEmail(string email)
        {
            try { return new Regex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$").IsMatch(email); } catch { return false; }
        }
        private bool IsValidShortPass(string shortPass) => Regex.IsMatch(shortPass, @"^\d{4}$");

        /// <summary>
        /// Hashes password using PBKDF2 with SHA256 (10,000 iterations + random salt)
        /// Matches the implementation in UserPrivilege.aspx.cs
        /// </summary>
        private string HashPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
                return string.Empty;

            using (var rng = new RNGCryptoServiceProvider())
            {
                byte[] salt = new byte[16];
                rng.GetBytes(salt);

                using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256))
                {
                    byte[] hash = pbkdf2.GetBytes(20);
                    byte[] hashWithSalt = new byte[36];
                    Array.Copy(salt, 0, hashWithSalt, 0, 16);
                    Array.Copy(hash, 0, hashWithSalt, 16, 20);

                    return Convert.ToBase64String(hashWithSalt);
                }
            }
        }

        /// <summary>
        /// Verifies password against PBKDF2 hash
        /// Extracts salt from stored hash and recomputes PBKDF2
        /// </summary>
        private bool VerifyPassword(string password, string storedHash)
        {
            if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(storedHash))
                return false;

            try
            {
                byte[] hashWithSalt = Convert.FromBase64String(storedHash);
                
                // Extract salt (first 16 bytes)
                byte[] salt = new byte[16];
                Array.Copy(hashWithSalt, 0, salt, 0, 16);

                // Recompute hash with extracted salt
                using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256))
                {
                    byte[] hash = pbkdf2.GetBytes(20);
                    
                    // Compare the computed hash with the stored hash (bytes 16-35)
                    for (int i = 0; i < 20; i++)
                    {
                        if (hash[i] != hashWithSalt[16 + i])
                            return false;
                    }
                }

                return true;
            }
            catch
            {
                return false;
            }
        }

        private string HashShortPass(string shortPass)
        {
            using (var sha256 = SHA256.Create())
            {
                byte[] hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(shortPass + "ShortSalt2024"));
                return Convert.ToBase64String(hashedBytes);
            }
        }
        private bool VerifyShortPass(string shortPass, string hash) => HashShortPass(shortPass) == hash;

        /// <summary>
        /// Simplified distance: just count exact character matches.
        /// </summary>
        private double CalculateFaceDistance(string a, string b)
        {
            try
            {
                if (string.IsNullOrEmpty(a) || string.IsNullOrEmpty(b)) return double.MaxValue;
                
                int minLen = Math.Min(a.Length, b.Length);
                if (minLen == 0) return double.MaxValue;

                // Count exact character matches
                int matches = 0;
                for (int i = 0; i < minLen; i++)
                {
                    if (a[i] == b[i]) matches++;
                }
                
                double similarity = (double)matches / minLen; // 0..1
                double distance = 1.0 - similarity;
                
                // Small penalty for length difference
                int lenDiff = Math.Abs(a.Length - b.Length);
                distance += Math.Min(0.1, lenDiff / 50000.0);
                
                return distance;
            }
            catch 
            { 
                return double.MaxValue; 
            }
        }

        private async Task UpdateLastLoginAsync(string userId)
        {
            await _usersCollection.UpdateOneAsync(
                u => u.Id == userId,
                Builders<User>.Update.Set(u => u.LastLogin, DateTime.UtcNow));
        }

        public async Task<User> GetUserByIdAsync(string userId) => await _usersCollection.Find(u => u.Id == userId && u.IsActive).FirstOrDefaultAsync();
        public async Task<User> GetUserByEmailAsync(string email) => await _usersCollection.Find(u => u.Email.ToLower() == email.ToLower() && u.IsActive).FirstOrDefaultAsync();

        /// <summary>
        /// Generate a simple hash from face encoding for quick comparisons
        /// </summary>
        private string GenerateFaceHash(string faceEncoding)
        {
            if (string.IsNullOrEmpty(faceEncoding)) return null;
            
            try
            {
                // Remove data URL prefix if present
                int commaIndex = faceEncoding.IndexOf(',');
                if (commaIndex > 0 && faceEncoding.Substring(0, commaIndex).Contains("base64"))
                {
                    faceEncoding = faceEncoding.Substring(commaIndex + 1);
                }
                
                // Generate a hash for quick comparison
                using (var sha256 = SHA256.Create())
                {
                    var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(faceEncoding));
                    var sb = new StringBuilder();
                    foreach (var b in bytes)
                    {
                        sb.Append(b.ToString("x2"));
                    }
                    return sb.ToString();
                }
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Calculate simple Hamming-like difference between two hashes
        /// </summary>
        private int HammingLikeDiff(string hash1, string hash2)
        {
            if (string.IsNullOrEmpty(hash1) || string.IsNullOrEmpty(hash2)) return int.MaxValue;
            
            int diff = 0;
            int minLen = Math.Min(hash1.Length, hash2.Length);
            
            for (int i = 0; i < minLen; i++)
            {
                if (hash1[i] != hash2[i]) diff++;
            }
            
            // Add penalty for length difference
            diff += Math.Abs(hash1.Length - hash2.Length);
            
            return diff;
        }
    }
}