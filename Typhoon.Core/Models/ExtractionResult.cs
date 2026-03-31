namespace Typhoon.Core.Models;

public class ExtractionResult
{
    public string RawText { get; set; } = string.Empty;
    public string CleanedText { get; set; } = string.Empty;
    public double MeanConfidence { get; set; }
}
