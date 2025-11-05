#!/bin/bash

# TestFlight Pre-Flight Validation Script
# This script checks if your project is ready for TestFlight upload

echo "🔍 KeyCo TestFlight Pre-Flight Validation"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if Xcode project exists
echo "1. Checking Xcode project..."
if [ -d "KeyCo.xcodeproj" ]; then
    echo -e "${GREEN}✓${NC} Xcode project found"
else
    echo -e "${RED}✗${NC} Xcode project not found"
    ((ERRORS++))
fi
echo ""

# Check bundle identifiers
echo "2. Checking bundle identifiers..."
MAIN_BUNDLE=$(grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER = com.keyco.KeyCo" KeyCo.xcodeproj/project.pbxproj | head -1 | grep -o "com.keyco.KeyCo" | head -1)
if [ ! -z "$MAIN_BUNDLE" ]; then
    echo -e "${GREEN}✓${NC} Main app bundle ID: $MAIN_BUNDLE"
else
    echo -e "${RED}✗${NC} Main app bundle ID not found"
    ((ERRORS++))
fi

EXT_BUNDLE=$(grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER = com.keyco.KeyCo.KeyCoKeyboard" KeyCo.xcodeproj/project.pbxproj | head -1 | grep -o "com.keyco.KeyCo.KeyCoKeyboard" | head -1)
if [ ! -z "$EXT_BUNDLE" ]; then
    echo -e "${GREEN}✓${NC} Extension bundle ID: $EXT_BUNDLE"
else
    echo -e "${RED}✗${NC} Extension bundle ID not found"
    ((ERRORS++))
fi
echo ""

# Check development team
echo "3. Checking development team..."
TEAM=$(grep "DEVELOPMENT_TEAM = " KeyCo.xcodeproj/project.pbxproj | head -1 | grep -o "DEVELOPMENT_TEAM = [^;]*" | cut -d' ' -f3)
if [ ! -z "$TEAM" ]; then
    echo -e "${GREEN}✓${NC} Development team: $TEAM"
else
    echo -e "${RED}✗${NC} Development team not set"
    ((ERRORS++))
fi
echo ""

# Check version numbers
echo "4. Checking version numbers..."
VERSION=$(grep "MARKETING_VERSION = " KeyCo.xcodeproj/project.pbxproj | head -1 | grep -o "MARKETING_VERSION = [^;]*" | cut -d' ' -f3)
BUILD=$(grep "CURRENT_PROJECT_VERSION = " KeyCo.xcodeproj/project.pbxproj | head -1 | grep -o "CURRENT_PROJECT_VERSION = [^;]*" | cut -d' ' -f3)

if [ ! -z "$VERSION" ]; then
    echo -e "${GREEN}✓${NC} Marketing version: $VERSION"
else
    echo -e "${RED}✗${NC} Marketing version not set"
    ((ERRORS++))
fi

if [ ! -z "$BUILD" ]; then
    echo -e "${GREEN}✓${NC} Build number: $BUILD"
else
    echo -e "${RED}✗${NC} Build number not set"
    ((ERRORS++))
fi
echo ""

# Check app icon
echo "5. Checking app icon..."
ICON_SET="KeyCo/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ICON_SET" ]; then
    ICON_COUNT=$(find "$ICON_SET" -name "*.png" -o -name "*.jpg" | wc -l | tr -d ' ')
    if [ "$ICON_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} App icon found ($ICON_COUNT images)"
    else
        echo -e "${YELLOW}⚠${NC} App icon directory exists but no images found"
        echo "   You need to add a 1024x1024 icon for App Store Connect"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}✗${NC} App icon directory not found"
    ((ERRORS++))
fi
echo ""

# Check entitlements
echo "6. Checking entitlements..."
if [ -f "KeyCo/KeyCo.entitlements" ]; then
    echo -e "${GREEN}✓${NC} Main app entitlements found"
else
    echo -e "${YELLOW}⚠${NC} Main app entitlements not found"
    ((WARNINGS++))
fi

if [ -f "KeyCoKeyboard/KeyCoKeyboard.entitlements" ]; then
    echo -e "${GREEN}✓${NC} Extension entitlements found"
else
    echo -e "${YELLOW}⚠${NC} Extension entitlements not found"
    ((WARNINGS++))
fi
echo ""

# Check Info.plist
echo "7. Checking Info.plist..."
if [ -f "KeyCoKeyboard/Info.plist" ]; then
    echo -e "${GREEN}✓${NC} Keyboard extension Info.plist found"
    
    # Check for required keys
    if grep -q "NSExtensionPointIdentifier" "KeyCoKeyboard/Info.plist"; then
        echo -e "${GREEN}✓${NC} Extension point identifier configured"
    else
        echo -e "${RED}✗${NC} Extension point identifier missing"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} Keyboard extension Info.plist not found"
    ((ERRORS++))
fi
echo ""

# Check if can build
echo "8. Checking if project can build..."
if command -v xcodebuild &> /dev/null; then
    echo "   Attempting to validate build settings..."
    if xcodebuild -project KeyCo.xcodeproj -scheme KeyCo -showBuildSettings > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Project build settings are valid"
    else
        echo -e "${YELLOW}⚠${NC} Could not validate build settings (this may be okay)"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} xcodebuild not found in PATH"
    ((WARNINGS++))
fi
echo ""

# Summary
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open KeyCo.xcodeproj in Xcode"
    echo "2. Select 'Any iOS Device' as the target"
    echo "3. Product → Archive"
    echo "4. Follow the TESTFLIGHT_GUIDE.md for upload instructions"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    echo ""
    echo "Project should be ready, but review warnings above."
    echo "Most critical: Ensure app icon images are added before uploading."
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} error(s) and ${WARNINGS} warning(s) found${NC}"
    echo ""
    echo "Please fix the errors above before uploading to TestFlight."
    exit 1
fi

