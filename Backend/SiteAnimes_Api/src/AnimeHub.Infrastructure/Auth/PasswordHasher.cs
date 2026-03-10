using AnimeHub.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace AnimeHub.Infrastructure.Auth
{
    public static class PasswordHasher
    {
        private static readonly PasswordHasher<User> _hasher = new();

        public static string Hash(string password)
            => _hasher.HashPassword(new User(), password);

        public static bool Verify(string password, string stored)
        {
            var result = _hasher.VerifyHashedPassword(new User(), stored, password);
            return result == PasswordVerificationResult.Success
                || result == PasswordVerificationResult.SuccessRehashNeeded;
        }
    }
}