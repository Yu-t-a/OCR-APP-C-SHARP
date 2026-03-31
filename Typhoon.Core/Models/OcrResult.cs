using Typhoon.Core.Enums;

namespace Typhoon.Core.Models;

public class OcrResult
{
    public required string JobId { get; set; }
    public string ExtractedText { get; set; } = string.Empty;
    public double ConfidenceScore { get; set; }
    public ProcessingStatus Status { get; set; }
    public string? ErrorMessage { get; set; }
    public TimeSpan ProcessingTime { get; set; }
    public DateTime CompletedAt { get; set; } = DateTime.UtcNow;
}
