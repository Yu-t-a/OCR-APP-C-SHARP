namespace Typhoon.Core.Data.Entities;

public class OcrJob
{
    public Guid Id { get; set; }
    public Guid? FileId { get; set; }
    public int? DocumentTypeId { get; set; }
    public string SourceFileName { get; set; } = string.Empty;
    public string? SourceFilePath { get; set; }
    public string Status { get; set; } = "Pending";
    public DateTime CreatedAt { get; set; }
    public DateTime? ProcessedAt { get; set; }

    public OcrFile? File { get; set; }
    public DocumentType? DocumentType { get; set; }
    public ICollection<OcrDocument> OcrDocuments { get; set; } = new List<OcrDocument>();
    public ICollection<OcrErrorLog> OcrErrorLogs { get; set; } = new List<OcrErrorLog>();
}
