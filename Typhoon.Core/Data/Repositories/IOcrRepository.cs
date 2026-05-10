using Typhoon.Core.Data.Entities;

namespace Typhoon.Core.Data.Repositories;

public interface IOcrRepository
{
    Task<List<DocumentType>> GetDocumentTypesAsync();
    Task<OcrJob> CreateJobAsync(string sourceFileName, string? sourceFilePath, int? documentTypeId = null);
    Task<OcrDocument> SaveResultAsync(Guid jobId, string rawText, string? extractedData, double confidence, int documentTypeId = 1);
    Task UpdateJobStatusAsync(Guid jobId, string status);
    Task LogErrorAsync(Guid? jobId, string errorCode, string errorMessage, string? stackTrace = null);
    Task<List<OcrJob>> GetRecentJobsAsync(int count = 10);
}
