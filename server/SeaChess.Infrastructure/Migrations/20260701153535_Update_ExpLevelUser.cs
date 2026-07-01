using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SeaChess.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Update_ExpLevelUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Experience",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Experience",
                table: "Users");
        }
    }
}
