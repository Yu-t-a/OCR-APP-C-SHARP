using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Typhoon.Web.Pages;

public class UploadModel : PageModel
{
    private readonly ILogger<UploadModel> _logger;
    private readonly IWebHostEnvironment _environment;

    public UploadModel(ILogger<UploadModel> logger, IWebHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    [BindProperty]
    public IFormFile? UploadedFile { get; set; }

    public string? ErrorMessage { get; set; }
    public string? SuccessMessage { get; set; }
    
    public List<UploadedFileInfo> UploadedFiles { get; set; } = new();

    public class UploadedFileInfo
    {
        public string Name { get; set; } = string.Empty;
        public long Size { get; set; }
        public DateTime UploadedAt { get; set; }
    }

    public void OnGet()
    {
        LoadUploadedFiles();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (UploadedFile == null || UploadedFile.Length == 0)
        {
            ErrorMessage = "Please select a file to upload.";
            LoadUploadedFiles();
            return Page();
        }

        // Validate file type
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
        var extension = Path.GetExtension(UploadedFile.FileName).ToLowerInvariant();
        
        if (!allowedExtensions.Contains(extension))
        {
            ErrorMessage = "Invalid file type. Please upload an image file (JPG, PNG, GIF, BMP).";
            LoadUploadedFiles();
            return Page();
        }

        // Validate file size (max 10MB)
        const long maxFileSize = 10 * 1024 * 1024;
        if (UploadedFile.Length > maxFileSize)
        {
            ErrorMessage = "File size exceeds the maximum limit of 10MB.";
            LoadUploadedFiles();
            return Page();
        }

        try
        {
            var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads");
            
            // Create unique filename
            var uniqueFileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await UploadedFile.CopyToAsync(stream);
            }

            SuccessMessage = $"File '{UploadedFile.FileName}' uploaded successfully!";
            _logger.LogInformation("File uploaded: {FileName} as {UniqueFileName}", UploadedFile.FileName, uniqueFileName);
            
            LoadUploadedFiles();
            return Page();
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error uploading file: {ex.Message}";
            _logger.LogError(ex, "Error uploading file");
            LoadUploadedFiles();
            return Page();
        }
    }

    private void LoadUploadedFiles()
    {
        try
        {
            var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads");
            
            if (Directory.Exists(uploadsFolder))
            {
                var files = Directory.GetFiles(uploadsFolder)
                    .Select(f => new FileInfo(f))
                    .OrderByDescending(f => f.CreationTime)
                    .Take(10)
                    .Select(f => new UploadedFileInfo
                    {
                        Name = f.Name,
                        Size = f.Length,
                        UploadedAt = f.CreationTime
                    })
                    .ToList();

                UploadedFiles = files;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading uploaded files");
        }
    }
}
