namespace Typhoon.Core.Data.Entities;

public class OcrErrorLog
{
    public long Id { get; set; }
    public Guid? JobId { get; set; }
    public string? ErrorCode { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
    public string? StackTrace { get; set; }
    public DateTime CreatedAt { get; set; }

    public OcrJob? Job { get; set; }
}
