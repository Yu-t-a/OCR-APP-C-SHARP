using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Typhoon.Core.Data;

public static class OcrDbContextFactory
{
    public static OcrDbContext Create()
    {
        LoadDotEnv();

        var config = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        var connectionString = BuildConnectionString(config);
        var options = new DbContextOptionsBuilder<OcrDbContext>()
            .UseSqlServer(connectionString)
            .Options;

        return new OcrDbContext(options);
    }

    public static OcrDbContext Create(string connectionString)
    {
        var options = new DbContextOptionsBuilder<OcrDbContext>()
            .UseSqlServer(connectionString)
            .Options;

        return new OcrDbContext(options);
    }

    private static string BuildConnectionString(IConfiguration config)
    {
        var host = config["DB_HOST"] ?? "localhost";
        var port = config["DB_PORT"] ?? "1433";
        var dbName = config["DB_NAME"] ?? "TyphoonOcrDB";
        var dbUser = config["DB_USER"] ?? "sa";
        var dbPass = config["DB_PASSWORD"] ?? config["MSSQL_SA_PASSWORD"] ?? string.Empty;

        return $"Server={host},{port};Database={dbName};User Id={dbUser};Password={dbPass};TrustServerCertificate=True;";
    }

    private static void LoadDotEnv()
    {
        var candidates = new[] { ".env", "../.env", "../../.env" };
        var envFile = candidates
            .Select(p => Path.GetFullPath(p))
            .FirstOrDefault(File.Exists);

        if (envFile == null) return;

        foreach (var line in File.ReadAllLines(envFile))
        {
            if (string.IsNullOrWhiteSpace(line) || line.TrimStart().StartsWith('#')) continue;

            var parts = line.Split('=', 2);
            if (parts.Length != 2) continue;

            var key = parts[0].Trim();
            var value = parts[1].Trim();

            if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable(key)))
                Environment.SetEnvironmentVariable(key, value);
        }
    }
}
