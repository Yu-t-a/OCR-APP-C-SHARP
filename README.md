# Typhoon OCR - OCR System

![Project Views](https://img.shields.io/badge/Project_Views-1-blue?style=flat-square)
![GitHub Stars](https://img.shields.io/github/stars/Yu-t-a/Typhoon-OCR-C-Sharp?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## 📖 Project Overview

**Typhoon OCR** is an Optical Character Recognition (OCR) system developed in C# utilizing the **Typhoon OCR API** to extract digital text from images and paper documents. The system is designed with a Clean Architecture, enabling scalability for future Web UI integrations and structured database storage.

### 🎯 Main Objectives
- Extract and convert text from images and documents into structured digital data.
- Provide highly accurate OCR services using the Typhoon OCR Engine.
- Support multiple platforms (starting with a CLI and expanding to a Web UI).

### ✨ Current Capabilities
- Accept image inputs from users via the Command Line Interface (CLI).
- Connect to and process images through the Typhoon OCR API.
- Display OCR extraction results along with Confidence Scores.

---

## 🛠 Tech Stack & Dependencies

- **Framework:** .NET 10.0 (C#)
- **Architecture:** Clean Architecture (Layered Architecture)
- **OCR Engine:**
  - **Primary:** Typhoon OCR API
  - **Fallback:** Tesseract (v5.2.0)
- **Key Libraries:**
  - `Microsoft.Extensions.Http` (v10.0.5) - For HTTP Client operations
  - `SixLabors.ImageSharp` (v3.1.12) - For image processing
  - `System.Text.Json` - For JSON serialization and parsing

---

## 🏗 Architecture & Project Structure

The system is strictly divided into layers for high maintainability:
`Typhoon.Console` (or `Web`) → `Typhoon.Core`

```text
Typhoon OCR/
├── Typhoon.Core/              # 🧠 Logic Layer - Core business logic and OCR Engine
│   ├── Interfaces/            # Contracts for DI (e.g., IOcrEngine.cs)
│   ├── Models/                # Data structures (e.g., ProcessedImage.cs, ExtractionResult.cs)
│   ├── Services/              # Core services (e.g., TyphoonCloudOcrEngine, TyphoonOcrApiClient)
│   └── Enums/                 # Constants and enums (e.g., OcrLanguage)
│
├── Typhoon.Console/           # 💻 Presentation Layer - CLI Application
│   └── Program.cs             # CLI entry point
│
└── Typhoon.Web/               # 🌐 Web UI Layer (Future roadmap)
    └── Pages/                 # Web pages for uploading and displaying results
```

**Data Flow:**  
`User Input` → `Console/Web App` → `OCR Engine` → `API Client` → `OpenTyphoon API` → `Database` (Future)

---

## 🚀 Installation & Setup

### 1. Prerequisites
- **.NET 10.0 SDK** or higher (`dotnet --version`)
- **Git** (for cloning the repository)
- **API Key** from Typhoon OCR

### 2. Project Installation

**Method 1: Clone the Repository**
```bash
git clone <repository-url>
cd OCR-APP-C-SHARP
dotnet restore
```

**Method 2: Create a New Project from Scratch (Quick Start)**
<details>
<summary>Click to view project creation commands</summary>

```bash
dotnet new sln -n Typhoon-OCR
dotnet new classlib -n Typhoon.Core --force
dotnet new webapp -n Typhoon.Web --force
dotnet sln add Typhoon.Web/Typhoon.Web.csproj Typhoon.Core/Typhoon.Core.csproj
dotnet add Typhoon.Web/Typhoon.Web.csproj reference Typhoon.Core/Typhoon.Core.csproj
dotnet add Typhoon.Core/Typhoon.Core.csproj package Tesseract
dotnet add Typhoon.Core/Typhoon.Core.csproj package SixLabors.ImageSharp
dotnet add Typhoon.Core/Typhoon.Core.csproj package System.Text.Json
dotnet add Typhoon.Core/Typhoon.Core.csproj package Microsoft.Extensions.Http
```
</details>

### 3. Configuration
Set up the API Key for the connection. For a complete guide on how to configure your API key securely across different operating systems, please read the **[API Key Setup Guide](API_KEY_SETUP.md)**.

```bash
# Windows (PowerShell)
.\setup-env.ps1 -ApiKey "sk-your-key" -Mode "production"

# macOS / Linux (Terminal)
chmod +x setup-env.sh
./setup-env.sh --api-key "sk-your-key" --mode "production"
```

Or configure it in the `appsettings.json` file (for the future Web App structure):
```json
{
  "OcrSettings": {
    "TesseractDataPath": "./tessdata",
    "DefaultLanguage": "tha+eng",
    "MaxFileSize": 10485760
  }
}
```

---

## 💻 Usage Guide (CLI)

1. Navigate to the CLI folder and run the application:
```bash
cd Typhoon.Console
dotnet run
```
2. Follow the on-screen prompts:
   - **Press `Enter`** to test with a demo image.
   - **Enter the filename** (e.g., `image.jpg`) to use an image from the `images` folder.
   - **Enter the full path** (e.g., `D:\path\image.jpg`) to specify a specific image location.

<div style="display: flex; gap: 20px; flex-wrap: wrap;">
  <div style="text-align: center;">
    <img src="images/1197876_0.jpg" alt="OCR Sample Image" width="400">
    <p><em>Sample Image</em></p>
  </div>
  <div style="text-align: center;">
    <img src="snapshot/Screenshot%202026-03-31%20114024.png" alt="CLI Application" width="400">
    <p><em>CLI Application Execution</em></p>
  </div>
</div>

---

## 🛣 Future Development Plan (Roadmap)

- **Phase 1: Core OCR Library** (Status: Core structure completed)
  - Integrate Tesseract as an offline fallback system.
  - Add multi-language support and comprehensive error handling.
- **Phase 2: Web Interface**
  - Create a UI for uploading images and validating files.
- **Phase 3: Background Worker & Database**
  - Implement a queue system using `BackgroundService` for OCR processing.
  - Connect a Database (SQLite for Dev / PostgreSQL for Production) to store OCR history.
- **Phase 4: Advanced Features**
  - Implement Batch Processing (handling multiple files simultaneously).
  - Add Excel/CSV export capabilities and expose a RESTful API.

---

## ❓ Troubleshooting

| Issue | Cause & Solution |
|---|---|
| `Invalid API Key` | Verify if the API Key is correct. Try running the `setup-env.ps1` script again. |
| `File not found` | The image does not exist. Ensure the file is in the `images` folder or provide the correct full path. |
| `Connection timeout` | Network issue. Check your internet connection or the Typhoon OCR server status. |

*Development Note: The system is planned to include a file cleanup mechanism for the temp folder.*

---

## 📚 Appendix: `dotnet new` Command Guide (Reference)

<details>
<summary>Click to view commonly used commands</summary>

The `dotnet new` command is used to create project templates in .NET via the CLI:

| Command | Description |
|---|---|
| `dotnet new sln -n <Name>` | Create a Solution file |
| `dotnet new console -n <Name>` | Create a Console App project |
| `dotnet new classlib -n <Name>` | Create a Class Library project |
| `dotnet new webapi -n <Name>` | Create a Web API project |
| `dotnet sln add <Project.csproj>`| Add a project to the Solution |

View all templates: `dotnet new list` or learn more using `dotnet new <template> --help`
</details>

---

