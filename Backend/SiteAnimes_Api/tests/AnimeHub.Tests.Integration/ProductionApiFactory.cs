using Microsoft.AspNetCore.Hosting;

namespace AnimeHub.Tests.Integration;
public sealed class ProductionApiFactory : ApiFactory
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Production");
        base.ConfigureWebHost(builder);
    }
}