using Microsoft.EntityFrameworkCore;
using Typhoon.Core.Data.Entities;

namespace Typhoon.Core.Data.Repositories;

public class OcrRepository : IOcrRepository
{
    private readonly OcrDbContext _db;

    public OcrRepository(OcrDbContext db)
    {
        _db = db;
    }

    public async Task<OcrJob> CreateJobAsync(string sourceFileName, string? sourceFilePath, int? documentTypeId = null)
    {
        var job = new OcrJob
        {
            SourceFileName = sourceFileName,
            SourceFilePath = sourceFilePath,
            DocumentTypeId = documentTypeId,
            Status = "Processing",
            CreatedAt = DateTime.UtcNow
        };

        _db.OcrJobs.Add(job);
        await _db.SaveChangesAsync();
        return job;
    }

    public async Task<OcrDocument> SaveResultAsync(Guid jobId, string rawText, string? extractedData, double confidence, int documentTypeId = 1)
    {
        var document = new OcrDocument
        {
            JobId = jobId,
            DocumentTypeId = documentTypeId,
            RawText = rawText,
            ExtractedData = extractedData,
            Confidence = confidence,
            CreatedAt = DateTime.UtcNow
        };

        _db.OcrDocuments.Add(document);
        await _db.SaveChangesAsync();
        return document;
    }

    public async Task UpdateJobStatusAsync(Guid jobId, string status)
    {
        var job = await _db.OcrJobs.FindAsync(jobId);
        if (job != null)
        {
            job.Status = status;
            job.ProcessedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }
    }

    public async Task LogErrorAsync(Guid? jobId, string errorCode, string errorMessage, string? stackTrace = null)
    {
        var log = new OcrErrorLog
        {
            JobId = jobId,
            ErrorCode = errorCode,
            ErrorMessage = errorMessage,
            StackTrace = stackTrace,
            CreatedAt = DateTime.UtcNow
        };

        _db.OcrErrorLogs.Add(log);
        await _db.SaveChangesAsync();
    }

    public async Task<List<OcrJob>> GetRecentJobsAsync(int count = 10)
    {
        return await _db.OcrJobs
            .Include(j => j.OcrDocuments)
            .OrderByDescending(j => j.CreatedAt)
            .Take(count)
            .ToListAsync();
    }

    public async Task<List<DocumentType>> GetDocumentTypesAsync()
    {
        return await _db.DocumentTypes
            .Where(dt => dt.IsActive)
            .OrderBy(dt => dt.TypeName)
            .ToListAsync();
    }
}
