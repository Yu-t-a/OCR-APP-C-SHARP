using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using Typhoon.Core.Enums;
using Typhoon.Core.Exceptions;
using Typhoon.Core.Interfaces;
using Typhoon.Core.Models;

namespace Typhoon.Core.Services;

public class ImagePreprocessor : IImageProcessor
{
    private readonly int _maxFileSize;

    public ImagePreprocessor(int maxFileSize = 10 * 1024 * 1024)
    {
        _maxFileSize = maxFileSize;
    }

    public async Task<ProcessedImage> ProcessAsync(byte[] imageData, CancellationToken cancellationToken = default)
    {
        // TODO: Implement actual image enhancement logic using ImageSharp (e.g., Grayscale, Binarize)
        using var image = Image.Load(imageData);
        
        // Example basic preprocessing: Resize if too large, Convert to grayscale
        image.Mutate(x => x.Grayscale());
        
        using var ms = new MemoryStream();
        await image.SaveAsJpegAsync(ms, cancellationToken);
        
        return new ProcessedImage
        {
            ProcessedData = ms.ToArray(),
            Format = ImageFormat.Jpeg,
            Width = image.Width,
            Height = image.Height
        };
    }

    public bool ValidateImage(byte[] imageData, string fileName)
    {
        if (imageData == null || imageData.Length == 0)
            throw new ImageValidationException("Image data cannot be empty.");

        if (imageData.Length > _maxFileSize)
            throw new ImageValidationException($"Image size exceeds the maximum limit of {_maxFileSize / 1024 / 1024}MB.");

        // TODO: Full extension/magic number validation
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        var validExts = new[] { ".jpg", ".jpeg", ".png", ".bmp", ".tiff" };
        
        if (!validExts.Contains(ext))
            throw new ImageValidationException($"Unsupported image format: {ext}");

        return true;
    }
}
