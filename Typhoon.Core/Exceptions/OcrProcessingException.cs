namespace Typhoon.Core.Exceptions;

public class OcrProcessingException : Exception
{
    public OcrProcessingException() { }
    public OcrProcessingException(string message) : base(message) { }
    public OcrProcessingException(string message, Exception innerException) : base(message, innerException) { }
}
