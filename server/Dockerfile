# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy solution và project files trước để tận dụng Docker cache
COPY *.slnx .
COPY SeaChess.API/*.csproj SeaChess.API/
COPY SeaChess.Application/*.csproj SeaChess.Application/
COPY SeaChess.Domain/*.csproj SeaChess.Domain/
COPY SeaChess.Infrastructure/*.csproj SeaChess.Infrastructure/
COPY SeaChess.Tests/*.csproj SeaChess.Tests/
RUN dotnet restore SeaChess.server.slnx

# Copy toàn bộ code còn lại và build
COPY . .
RUN dotnet publish SeaChess.API/SeaChess.API.csproj -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Cài đặt Stockfish trực tiếp vào trong Docker container
RUN apt-get update && apt-get install -y stockfish && rm -rf /var/lib/apt/lists/*

EXPOSE 5039
ENV ASPNETCORE_URLS=http://+:5039
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "SeaChess.API.dll"]