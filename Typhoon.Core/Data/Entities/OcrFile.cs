namespace Typhoon.Core.Data.Entities;

public class OcrFile
{
    public Guid Id { get; set; }
    public string OriginalFileName { get; set; } = string.Empty;
    public string StoredFilePath { get; set; } = string.Empty;
    public long? FileSizeBytes { get; set; }
    public string? MimeType { get; set; }
    public Guid? UploadedBy { get; set; }
    public DateTime UploadedAt { get; set; }

    public ICollection<OcrJob> OcrJobs { get; set; } = new List<OcrJob>();
}
