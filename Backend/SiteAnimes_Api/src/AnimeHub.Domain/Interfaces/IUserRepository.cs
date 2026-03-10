using AnimeHub.Domain.Entities;

namespace AnimeHub.Domain.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetByEmailAsync(string email, CancellationToken ct);
        Task<User?> GetByIdAsync(int id, CancellationToken ct);
        Task<List<User>> GetAllAsync(CancellationToken ct);
        Task<User> AddAsync(User user, CancellationToken ct);
        Task<bool> UpdateAsync(User user, CancellationToken ct);
        Task<bool> DeleteAsync(User user, CancellationToken ct);
    }
}
