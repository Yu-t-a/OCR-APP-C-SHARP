namespace Typhoon.Core.Data.Entities;

public class DocumentType
{
    public int Id { get; set; }
    public string TypeCode { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string? SchemaTemplate { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<OcrJob> OcrJobs { get; set; } = new List<OcrJob>();
    public ICollection<OcrDocument> OcrDocuments { get; set; } = new List<OcrDocument>();
}
