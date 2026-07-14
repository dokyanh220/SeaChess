using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SeaChess.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPlayerId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PlayerId",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "AiColor",
                table: "Matches",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AiDifficulty",
                table: "Matches",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsAiGame",
                table: "Matches",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PlayerId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AiColor",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "AiDifficulty",
                table: "Matches");

            migrationBuilder.DropColumn(
                name: "IsAiGame",
                table: "Matches");
        }
    }
}
