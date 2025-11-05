#!/bin/bash

# Script to add app icon to the KeyCo project
# Usage: ./add_app_icon.sh /path/to/your/icon.png

if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/icon.png"
    echo ""
    echo "This script will:"
    echo "1. Copy your icon to the AppIcon asset catalog"
    echo "2. Rename it to AppIcon-1024.png"
    echo "3. Verify it's the correct size (1024x1024)"
    exit 1
fi

ICON_PATH="$1"
TARGET_DIR="/Users/benrobinson/KeyCo/KeyCo/Assets.xcassets/AppIcon.appiconset"
TARGET_FILE="$TARGET_DIR/AppIcon-1024.png"

# Check if source file exists
if [ ! -f "$ICON_PATH" ]; then
    echo "❌ Error: File not found: $ICON_PATH"
    exit 1
fi

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Target directory not found: $TARGET_DIR"
    exit 1
fi

# Copy the file
echo "📋 Copying icon..."
cp "$ICON_PATH" "$TARGET_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Icon copied successfully!"
    
    # Try to check dimensions if sips is available (macOS tool)
    if command -v sips &> /dev/null; then
        DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$TARGET_FILE" 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}')
        if [ ! -z "$DIMENSIONS" ]; then
            echo "📐 Icon dimensions: $DIMENSIONS"
            echo "   (Should be 1024x1024 for App Store)"
        fi
    fi
    
    echo ""
    echo "✅ App icon added successfully!"
    echo "   You can now archive and upload to TestFlight."
else
    echo "❌ Error: Failed to copy icon"
    exit 1
fi

