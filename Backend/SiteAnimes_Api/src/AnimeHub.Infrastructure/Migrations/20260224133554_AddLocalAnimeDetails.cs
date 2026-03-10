using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AnimeHub.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddLocalAnimeDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Animes",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EpisodeCount",
                table: "Animes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EpisodeLengthMinutes",
                table: "Animes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ExternalLinks",
                table: "Animes",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "StreamingEpisodes",
                table: "Animes",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EpisodeCount",
                table: "Animes");

            migrationBuilder.DropColumn(
                name: "EpisodeLengthMinutes",
                table: "Animes");

            migrationBuilder.DropColumn(
                name: "ExternalLinks",
                table: "Animes");

            migrationBuilder.DropColumn(
                name: "StreamingEpisodes",
                table: "Animes");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Animes",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50,
                oldNullable: true);
        }
    }
}
