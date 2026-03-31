using Typhoon.Core.Enums;

namespace Typhoon.Core.Models;

public class OcrRequest
{
    public required string JobId { get; set; }
    public required byte[] ImageData { get; set; }
    public required string FileName { get; set; }
    public ImageFormat Format { get; set; }
    public OcrLanguage Language { get; set; } = OcrLanguage.ThaiAndEnglish;
}
