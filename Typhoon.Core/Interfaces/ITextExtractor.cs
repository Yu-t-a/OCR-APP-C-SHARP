using Typhoon.Core.Models;

namespace Typhoon.Core.Interfaces;

public interface ITextExtractor
{
    ExtractionResult PostProcess(string rawText);
}
