using Typhoon.Core.Services;
using Typhoon.Core.Models;
using Typhoon.Core.Enums;

// Check for debug mode from command line arguments or environment
bool isDebugMode = args.Contains("--debug") || 
                  Environment.GetEnvironmentVariable("OCR_DEBUG_MODE") == "true";

if (isDebugMode)
{
    Console.WriteLine("🐛 DEBUG MODE ENABLED");
    Console.WriteLine("=======================");
}

Console.WriteLine("=== Typhoon OCR ===");
Console.WriteLine();

// Get API key from environment or user input
string apiKey = Environment.GetEnvironmentVariable("TYPHOON_API_KEY") ?? "";

// Check if API key exists and is valid
if (string.IsNullOrEmpty(apiKey) || apiKey == "your_api_key_here")
{
    Console.Write("Enter your OpenTyphoon API Key: ");
    apiKey = Console.ReadLine() ?? string.Empty;
    
    if (string.IsNullOrEmpty(apiKey))
    {
        Console.WriteLine("❌ API Key is required!");
        Console.WriteLine("Get your API key from: https://playground.opentyphoon.ai");
        Console.WriteLine("Press any key to exit...");
        Console.ReadKey();
        return;
    }
}
else
{
    if (isDebugMode)
        Console.WriteLine("🔍 Found API Key in environment variables");
    else
        Console.WriteLine("✅ Using existing API Key from environment");
}

Console.WriteLine("✅ API Key loaded");
Console.WriteLine();

// Test with a sample image path
Console.Write("Enter image filename or path (or press Enter for demo): ");
string input = Console.ReadLine() ?? string.Empty;

string imagePath;
if (string.IsNullOrEmpty(input))
{
    // Try to find a demo file in the images folder
    var imageFiles = Directory.GetFiles("../images", "*.jpg");
    if (imageFiles.Length > 0)
    {
        imagePath = imageFiles[0];
        Console.WriteLine($"📝 No input provided, using demo image: {Path.GetFileName(imagePath)}");
    }
    else
    {
        Console.WriteLine("📝 Demo mode - You need to provide an image filename or path");
        Console.WriteLine("Example: 38080.jpg or D:\\path\\to\\image.jpg");
        Console.WriteLine();
        return;
    }
}
else
{
    // Check if input is a full path or just filename
    if (Path.IsPathRooted(input) && File.Exists(input))
    {
        // Full path provided and exists
        imagePath = input;
        Console.WriteLine($"✅ Using full path: {Path.GetFileName(imagePath)}");
    }
    else if (File.Exists(input))
    {
        // Relative path or file in current directory
        imagePath = input;
        Console.WriteLine($"✅ Using file: {Path.GetFileName(imagePath)}");
    }
    else
    {
        // Try to find in images folder
        var imagesPath = Path.Combine("../images", input);
        if (File.Exists(imagesPath))
        {
            imagePath = imagesPath;
            Console.WriteLine($"✅ Found in images folder: {Path.GetFileName(imagePath)}");
        }
        else
        {
            Console.WriteLine($"❌ File not found: {input}");
            Console.WriteLine("💡 Available options:");
            Console.WriteLine("   1. Filename only: 38080.jpg (searches in images folder)");
            Console.WriteLine("   2. Full path: D:\\Typhoon-OCR-C-Sharp\\images\\38080.jpg");
            
            // Show available files in images folder
            var availableFiles = Directory.GetFiles("../images", "*.jpg");
            if (availableFiles.Length > 0)
            {
                Console.WriteLine("\n📁 Available files in images folder:");
                foreach (var file in availableFiles)
                {
                    Console.WriteLine($"   - {Path.GetFileName(file)}");
                }
            }
            return;
        }
    }
}

if (File.Exists(imagePath))
{
    try
    {
        Console.WriteLine($"🔄 Processing image: {Path.GetFileName(imagePath)}");
        
        // Create OCR engine
        var ocrEngine = new TyphoonCloudOcrEngine(apiKey);
        
        // Read and process image
        var imageData = File.ReadAllBytes(imagePath);
        
        if (isDebugMode)
            Console.WriteLine($"🔍 Image loaded: {imageData.Length} bytes");
        
        // Detect format from extension
        var ext = Path.GetExtension(imagePath).ToLowerInvariant();
        var format = ext switch
        {
            ".png" => ImageFormat.Png,
            ".bmp" => ImageFormat.Bmp,
            ".tiff" or ".tif" => ImageFormat.Tiff,
            _ => ImageFormat.Jpeg
        };

        var processedImage = new ProcessedImage 
        { 
            ProcessedData = imageData,
            Format = format 
        };
        
        // Extract text
        var result = await ocrEngine.ExtractTextAsync(processedImage, OcrLanguage.ThaiAndEnglish);
        
        Console.WriteLine();
        if (isDebugMode)
            Console.WriteLine("🔍 === DEBUG: OCR Processing Results ===");
        else
            Console.WriteLine("=== OCR Result ===");
        
        Console.WriteLine($"🔒 Confidence: {result.MeanConfidence:P1}");
        
        if (!string.IsNullOrEmpty(result.RawText))
        {
            Console.WriteLine();
            Console.WriteLine("📄 Extracted Text:");
            Console.WriteLine("----------------------------------------");
            Console.WriteLine(result.RawText);
            Console.WriteLine("----------------------------------------");
            
            if (isDebugMode)
            {
                Console.WriteLine();
                Console.WriteLine("🔍 Additional Info:");
                Console.WriteLine($"   - Cleaned Text Length: {result.CleanedText.Length}");
                Console.WriteLine($"   - Processing Mode: {(isDebugMode ? "Debug" : "Production")}");
            }
        }
        else
        {
            if (isDebugMode)
                Console.WriteLine("🔍 DEBUG: No text extracted - Check API response");
            else
                Console.WriteLine("❌ No text extracted or error occurred");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Error processing image: {ex.Message}");
    }
}
else
{
    Console.WriteLine($"❌ File not found: {imagePath}");
}

Console.WriteLine();
Console.WriteLine("Press any key to exit (auto-exit in 5 seconds)...");

// Auto-exit after 5 seconds or key press
var task = Task.Run(() => {
    Thread.Sleep(5000);
});

try
{
    Console.ReadKey(true); // true = don't display the key
}
catch (Exception)
{
    // Handle case where console input is not available
}

Environment.Exit(0);
