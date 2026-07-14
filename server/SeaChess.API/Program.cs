using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SeaChess.API.Hubs;
using SeaChess.API.Workers;
using SeaChess.Application.Interfaces;
using SeaChess.Application.Services;
using SeaChess.Infrastructure.Data;
using SeaChess.Infrastructure.Repositories;
using SeaChess.Infrastructure.Services;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls("http://0.0.0.0:5039");

var connectionString =  builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options => 
    options.UseNpgsql(connectionString));

var redisConnectionString =  builder.Configuration.GetConnectionString("RedisConnection");
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
    ConnectionMultiplexer.Connect(redisConnectionString!));

var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = Encoding.ASCII.GetBytes(jwtSettings["SecretKey"]!);
builder.Services.AddAuthentication(options =>
{
   options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
   options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme; 
})
.AddJwtBearer(options =>
{
   options.RequireHttpsMetadata = false; // set true khi chạy production
   options.SaveToken = true;
   options.TokenValidationParameters = new TokenValidationParameters
   {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(secretKey),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
   }; 

   options.Events = new JwtBearerEvents
   {
       OnMessageReceived = context =>
       {
            var accessToken = context.Request.Query["access_token"];

            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs/chess"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
       }
   };
});

builder.Services.AddCors(options =>
{
   options.AddPolicy("SeaChessCorsPolicy", policy =>
   {
       policy.SetIsOriginAllowed(origin => true)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
   }) ;
});

builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();
builder.Services.AddControllers();
builder.Services.AddHostedService<MatchmakingWorker>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IMatchMakingService, MatchMakingService>();
builder.Services.AddScoped<IGameStateService, GameStateService>();
builder.Services.AddScoped<IStockfishService, StockfishService>();
builder.Services.AddScoped<IFriendshipRepository, FriendshipRepository>();
builder.Services.AddScoped<IFriendshipService, FriendshipService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapGet("/health", () =>
{
    return new { message = "server running" };
})
.WithName("health");

app.UseCors("SeaChessCorsPolicy");
app.UseAuthentication(); 
app.UseAuthorization();

// Chuẩn bị Endpoint cho SignalR Hub
app.MapHub<ChessHub>("/hubs/chess");
app.MapControllers();
app.Run();
