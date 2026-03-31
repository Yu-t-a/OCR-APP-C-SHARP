using Tesseract;
using Typhoon.Core.Enums;
using Typhoon.Core.Exceptions;
using Typhoon.Core.Interfaces;
using Typhoon.Core.Models;

namespace Typhoon.Core.Services;

public class TesseractOcrEngine : IOcrEngine
{
    private readonly string _tessDataPath;

    public TesseractOcrEngine(string tessDataPath)
    {
        _tessDataPath = tessDataPath;
    }

    public Task<ExtractionResult> ExtractTextAsync(ProcessedImage image, OcrLanguage language, CancellationToken cancellationToken = default)
    {
        // TODO: Implement actual Tesseract OCR logic
        throw new NotImplementedException("Tesseract implementation will be added here.");
    }
}
