FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files to leverage Docker layer caching
COPY ["src/AnimeHub.Api/AnimeHub.Api.csproj", "src/AnimeHub.Api/"]
COPY ["src/AnimeHub.Application/AnimeHub.Application.csproj", "src/AnimeHub.Application/"]
COPY ["src/AnimeHub.Infrastructure/AnimeHub.Infrastructure.csproj", "src/AnimeHub.Infrastructure/"]
COPY ["src/AnimeHub.Domain/AnimeHub.Domain.csproj", "src/AnimeHub.Domain/"]

RUN dotnet restore "src/AnimeHub.Api/AnimeHub.Api.csproj"

# Copy remaining files and publish
COPY . .
RUN dotnet publish "src/AnimeHub.Api/AnimeHub.Api.csproj" -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends libgssapi-krb5-2 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

ENTRYPOINT ["dotnet", "AnimeHub.Api.dll"]
