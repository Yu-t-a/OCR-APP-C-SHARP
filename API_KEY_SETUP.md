# 🔑 API Key Setup Guide

A complete guide to configuring your Typhoon OCR API Key securely on Windows and macOS.

> [!CAUTION]
> **Security First**
> - **Never commit your API Key to source control.** Always use Environment Variables.
> - **Do not share your API Key.** Keep it secret and store it securely.

---

## 🪟 Windows Setup

You can set your API key temporarily (for the current session) or permanently (recommended).

### Option 1: Permanent Setup (Recommended)
This method saves the key across reboots and new terminal sessions.

**Via PowerShell:**
```powershell
[Environment]::SetEnvironmentVariable("TYPHOON_API_KEY", "your_api_key_here", "User")
```
*(Note: You will need to restart your terminal for the changes to take effect.)*

**Via Command Prompt:**
```cmd
setx TYPHOON_API_KEY "your_api_key_here"
```

### Option 2: Temporary Setup (Current Session Only)
The key will be lost once you close the terminal.

**Via PowerShell:**
```powershell
$env:TYPHOON_API_KEY="your_api_key_here"
```

---

## 🍎 macOS & Linux Setup

### Option 1: Permanent Setup (Recommended)
Add the key to your shell profile so it loads automatically.

**For Zsh (Default on modern macOS):**
```bash
echo 'export TYPHOON_API_KEY="your_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

**For Bash:**
```bash
echo 'export TYPHOON_API_KEY="your_api_key_here"' >> ~/.bash_profile
source ~/.bash_profile
```

### Option 2: Temporary Setup (Current Session Only)
```bash
export TYPHOON_API_KEY="your_api_key_here"
```

---

## 🛠 Helper Script (PowerShell)

If you are using Windows, we have provided a convenient PowerShell script `api-key-management.ps1` to manage your keys easily.

```powershell
# Set your API Key
.\api-key-management.ps1 set "your_api_key_here"

# View your current API Key
.\api-key-management.ps1 get

# Test if the API Key is working
.\api-key-management.ps1 test

# Delete the API Key from your system
.\api-key-management.ps1 delete
```

---

## 🚀 Verifying the Setup

Once you have set the API key, you can verify that the system detects it by running the console application.

1. Navigate to the Console app directory:
   ```bash
   cd Typhoon.Console
   dotnet run
   ```
2. You should see the following success messages before the app prompts for an image:
   ```
   ✅ Using existing API Key from environment
   ✅ API Key loaded
   ```

---

## 📋 Quick Command Reference

| Action | Windows (PowerShell) | macOS / Linux (Zsh/Bash) |
|---|---|---|
| **View Key** | `$env:TYPHOON_API_KEY` | `echo $TYPHOON_API_KEY` |
| **Set Temporary** | `$env:TYPHOON_API_KEY="key"` | `export TYPHOON_API_KEY="key"` |
| **Remove Temporary** | `Remove-Item env:TYPHOON_API_KEY` | `unset TYPHOON_API_KEY` |

---

## ❓ Troubleshooting

### 1. "No API Key found"
**Cause:** The application cannot find the environment variable.  
**Solution:** Ensure you have set the API key. If you set it permanently, try restarting your terminal or IDE so it can load the latest environment variables.

### 2. "File not found" when running OCR
**Cause:** The image path provided is incorrect.  
**Solution:** Provide just the filename (e.g., `image.jpg`) if it exists in the `images` folder, or provide the full absolute path to the file.

### 3. "500 Internal Server Error"
**Cause:** Issue with the API request payload or server.  
**Solution:** 
- Check if your API Key is still valid and has sufficient quota.
- Ensure the image contains readable text and is within size limits.

### 4. "LF would be replaced by CRLF" (Git Warning)
**Cause:** Line ending differences between Windows and Unix systems.  
**Solution:** Configure Git to handle line endings properly:
```bash
git config --global core.autocrlf true
```

---

## 📚 References
- [OpenTyphoon OCR Documentation](https://docs.opentyphoon.ai/en/ocr/)
- [OpenTyphoon API Reference](https://docs.opentyphoon.ai/en/api-reference/)
