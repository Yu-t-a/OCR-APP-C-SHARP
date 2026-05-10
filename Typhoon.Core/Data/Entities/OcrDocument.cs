namespace Typhoon.Core.Data.Entities;

public class OcrDocument
{
    public Guid Id { get; set; }
    public Guid JobId { get; set; }
    public int DocumentTypeId { get; set; }
    public int PageNumber { get; set; } = 1;
    public string? RawText { get; set; }
    public string? ExtractedData { get; set; }
    public double? Confidence { get; set; }
    public bool IsVerified { get; set; } = false;
    public string? ErrorMessage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? CreatedBy { get; set; }

    public OcrJob Job { get; set; } = null!;
    public DocumentType DocumentType { get; set; } = null!;
    public ICollection<OcrDocumentField> Fields { get; set; } = new List<OcrDocumentField>();
}
