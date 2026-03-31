namespace Typhoon.Core.Exceptions;

public class ImageValidationException : Exception
{
    public ImageValidationException() { }
    public ImageValidationException(string message) : base(message) { }
    public ImageValidationException(string message, Exception innerException) : base(message, innerException) { }
}
