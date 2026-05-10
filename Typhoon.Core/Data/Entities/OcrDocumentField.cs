namespace Typhoon.Core.Data.Entities;

public class OcrDocumentField
{
    public int Id { get; set; }
    public Guid DocumentId { get; set; }
    public string FieldName { get; set; } = string.Empty;
    public string? FieldValue { get; set; }
    public string? FieldType { get; set; }
    public double? Confidence { get; set; }

    public OcrDocument Document { get; set; } = null!;
}
