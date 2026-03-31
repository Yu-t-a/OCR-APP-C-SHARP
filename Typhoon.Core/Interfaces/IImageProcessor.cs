using Typhoon.Core.Models;

namespace Typhoon.Core.Interfaces;

public interface IImageProcessor
{
    Task<ProcessedImage> ProcessAsync(byte[] imageData, CancellationToken cancellationToken = default);
    bool ValidateImage(byte[] imageData, string fileName);
}
