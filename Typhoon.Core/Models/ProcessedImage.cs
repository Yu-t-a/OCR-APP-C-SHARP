using Typhoon.Core.Enums;

namespace Typhoon.Core.Models;

public class ProcessedImage
{
    public required byte[] ProcessedData { get; set; }
    public ImageFormat Format { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
}
