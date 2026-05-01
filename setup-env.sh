#!/bin/bash

# Environment Setup Script for Typhoon OCR
# Run this script once per machine to set up all required environment variables for macOS/Linux

API_KEY=""
MODE="production"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --api-key|-k) API_KEY="$2"; shift ;;
        --mode|-m) MODE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo -e "\033[0;36m🔧 Typhoon OCR Environment Setup\033[0m"
echo -e "\033[0;36m=================================\033[0m"

# Prompt for API Key if not provided
if [ -z "$API_KEY" ]; then
    echo -e "\033[0;33m⚠️  No API Key provided\033[0m"
    echo -e "\033[0;37m💡 Usage: ./setup-env.sh --api-key 'sk-your-api-key-here'\033[0m"
    echo -e "\033[0;37m💡 Or enter it now:\033[0m"
    read -p "Enter your OpenTyphoon API Key: " API_KEY
fi

if [ -z "$API_KEY" ]; then
    echo -e "\033[0;31m❌ API Key is required!\033[0m"
    exit 1
fi

# Determine shell config file
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bash_profile"
    if [ ! -f "$SHELL_CONFIG" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
else
    SHELL_CONFIG="$HOME/.profile"
fi

# Remove existing key if present to avoid duplicates
if [ -f "$SHELL_CONFIG" ]; then
    sed -i.bak '/export TYPHOON_API_KEY=/d' "$SHELL_CONFIG" 2>/dev/null || sed -i '' '/export TYPHOON_API_KEY=/d' "$SHELL_CONFIG"
    sed -i.bak '/export OCR_DEBUG_MODE=/d' "$SHELL_CONFIG" 2>/dev/null || sed -i '' '/export OCR_DEBUG_MODE=/d' "$SHELL_CONFIG"
fi

# Append to shell config
echo "export TYPHOON_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
echo -e "\033[0;32m✅ TYPHOON_API_KEY set\033[0m"

DEBUG_VALUE="false"
if [ "$MODE" = "debug" ]; then
    DEBUG_VALUE="true"
fi
echo "export OCR_DEBUG_MODE=\"$DEBUG_VALUE\"" >> "$SHELL_CONFIG"
echo -e "\033[0;32m✅ OCR_DEBUG_MODE set to: $DEBUG_VALUE\033[0m"

echo ""
echo -e "\033[0;32m🎉 Setup Complete!\033[0m"
echo -e "\033[0;32m==================\033[0m"
echo -e "\033[0;36m📝 Summary:\033[0m"
echo -e "\033[0;37m   - API Key: ${API_KEY:0:10}...\033[0m"
echo -e "\033[0;37m   - Debug Mode: $MODE\033[0m"
echo ""
echo -e "\033[0;36m🔄 Next Steps:\033[0m"
echo -e "\033[0;33m   1. Apply changes: source $SHELL_CONFIG (or reopen terminal)\033[0m"
echo -e "\033[0;33m   2. Run: cd Typhoon.Console\033[0m"
echo -e "\033[0;33m   3. Run: dotnet run\033[0m"
echo ""
echo -e "\033[0;32m✨ Your environment is now ready for Typhoon OCR!\033[0m"
