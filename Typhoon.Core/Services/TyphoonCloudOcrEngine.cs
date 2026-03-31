using Typhoon.Core.Interfaces;
using Typhoon.Core.Models;
using Typhoon.Core.Enums;

namespace Typhoon.Core.Services;

public class TyphoonCloudOcrEngine : IOcrEngine
{
    private readonly TyphoonOcrApiClient _apiClient;

    public TyphoonCloudOcrEngine(string apiKey)
    {
        _apiClient = new TyphoonOcrApiClient(apiKey);
    }

    public async Task<ExtractionResult> ExtractTextAsync(ProcessedImage image, OcrLanguage language, CancellationToken cancellationToken = default)
    {
        try
        {
            var startTime = DateTime.UtcNow;
            
            // Get proper extension
            string extension = image.Format switch
            {
                ImageFormat.Png => ".png",
                ImageFormat.Bmp => ".bmp",
                ImageFormat.Tiff => ".tiff",
                _ => ".jpg"
            };

            // Call OpenTyphoon API
            var extractedText = await _apiClient.ProcessImageAsync(image.ProcessedData, $"image{extension}");
            
            var endTime = DateTime.UtcNow;
            var processingTime = (endTime - startTime).TotalMilliseconds;

            return new ExtractionResult
            {
                RawText = extractedText,
                CleanedText = extractedText,
                MeanConfidence = 0.95
            };
        }
        catch (Exception)
        {
            return new ExtractionResult
            {
                RawText = string.Empty,
                CleanedText = string.Empty,
                MeanConfidence = 0
            };
        }
    }

    public void Dispose()
    {
        _apiClient?.Dispose();
    }
}
