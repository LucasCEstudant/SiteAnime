using AnimeHub.Domain.Entities;
using AnimeHub.Domain.Interfaces;
using AnimeHub.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AnimeHub.Infrastructure.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly AppDbContext _db;
        public UserRepository(AppDbContext db) => _db = db;

        public Task<User?> GetByEmailAsync(string email, CancellationToken ct)
            => _db.Users.FirstOrDefaultAsync(x => x.Email == email, ct);

        public Task<User?> GetByIdAsync(int id, CancellationToken ct)
            => _db.Users.FirstOrDefaultAsync(x => x.Id == id, ct);

        public Task<List<User>> GetAllAsync(CancellationToken ct)
            => _db.Users.OrderBy(x => x.Id).ToListAsync(ct);

        public async Task<User> AddAsync(User user, CancellationToken ct)
        {
            _db.Users.Add(user);
            await _db.SaveChangesAsync(ct);
            return user;
        }

        public async Task<bool> UpdateAsync(User user, CancellationToken ct)
        {
            _db.Users.Update(user);
            await _db.SaveChangesAsync(ct);
            return true;
        }

        public async Task<bool> DeleteAsync(User user, CancellationToken ct)
        {
            _db.Users.Remove(user);
            await _db.SaveChangesAsync(ct);
            return true;
        }
    }
}