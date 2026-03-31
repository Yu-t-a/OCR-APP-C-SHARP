using Typhoon.Core.Models;

namespace Typhoon.Core.Interfaces;

public interface IOcrEngine
{
    Task<ExtractionResult> ExtractTextAsync(ProcessedImage image, Enums.OcrLanguage language, CancellationToken cancellationToken = default);
}
