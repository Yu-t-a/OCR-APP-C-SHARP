using System.Text;
using System.Text.Json;

namespace Typhoon.Core.Services;

public class TyphoonOcrApiClient
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private const string BaseUrl = "https://api.opentyphoon.ai/v1";

    public TyphoonOcrApiClient(string apiKey)
    {
        _apiKey = apiKey ?? throw new ArgumentNullException(nameof(apiKey));
        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
    }

    public async Task<string> ProcessImageAsync(byte[] imageData, string fileName = "image.jpg")
    {
        // Check for debug mode
        bool isDebugMode = Environment.GetEnvironmentVariable("OCR_DEBUG_MODE") == "true";
        
        try
        {
            // Convert image to base64
            var base64Image = Convert.ToBase64String(imageData);
            var mimeType = GetMimeType(fileName);

            // Debug: Show image info
            if (isDebugMode)
            {
                Console.WriteLine($"🔍 Debug: Image size = {imageData.Length} bytes");
                Console.WriteLine($"🔍 Debug: Base64 length = {base64Image.Length}");
                Console.WriteLine($"🔍 Debug: MIME type = {mimeType}");
            }

            // Standard OpenAI-compatible vision request
            var chatRequestBody = new
            {
                model = "typhoon-ocr",
                messages = new[]
                {
                    new
                    {
                        role = "user",
                        content = new object[]
                        {
                            new { type = "text", text = "Extract text from this image." },
                            new { type = "image_url", image_url = new { url = $"data:{mimeType};base64,{base64Image}" } }
                        }
                    }
                },
                temperature = 0.1,
                max_tokens = 4096
            };

            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };

            var json = JsonSerializer.Serialize(chatRequestBody, options);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            if (isDebugMode)
                Console.WriteLine($"🔍 Debug: Sending vision request to {BaseUrl}/chat/completions");
            
            var response = await _httpClient.PostAsync($"{BaseUrl}/chat/completions", content);
            
            if (isDebugMode)
                Console.WriteLine($"🔍 Debug: Response status = {response.StatusCode}");
            
            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                if (isDebugMode)
                    Console.WriteLine($"🔍 Debug: Error response = {errorContent}");
                response.EnsureSuccessStatusCode();
            }

            var responseContent = await response.Content.ReadAsStringAsync();
            
            if (isDebugMode)
                Console.WriteLine($"🔍 Debug: Response length = {responseContent.Length}");
            
            var ocrResponse = JsonSerializer.Deserialize<OcrResponse>(responseContent, options);

            return ocrResponse?.Choices?.FirstOrDefault()?.Message?.Content ?? "No text extracted";
        }
        catch (Exception ex)
        {
            if (isDebugMode)
                Console.WriteLine($"🔍 Debug: Exception = {ex.Message}");
            throw new InvalidOperationException($"OCR processing failed: {ex.Message}", ex);
        }
    }

    private static string GetMimeType(string fileName)
    {
        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        return extension switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".bmp" => "image/bmp",
            ".webp" => "image/webp",
            ".tiff" or ".tif" => "image/tiff",
            _ => "image/jpeg"
        };
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}

// Response models
public class OcrResponse
{
    public string Id { get; set; } = string.Empty;
    public string Object { get; set; } = string.Empty;
    public long Created { get; set; }
    public string Model { get; set; } = string.Empty;
    public Usage Usage { get; set; } = new();
    public List<Choice> Choices { get; set; } = new();
}

public class Choice
{
    public Message Message { get; set; } = new();
    public string FinishReason { get; set; } = string.Empty;
    public int Index { get; set; }
}

public class Message
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}

public class Usage
{
    public int PromptTokens { get; set; }
    public int CompletionTokens { get; set; }
    public int TotalTokens { get; set; }
}
