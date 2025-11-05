# TestFlight Quick Start Guide

## ⚠️ Important: Before You Start

**You need to add app icons before uploading!**
- Go to `KeyCo/Assets.xcassets/AppIcon.appiconset/` in Xcode
- Add a 1024x1024 PNG icon (required for App Store Connect)
- You can do this in Xcode: Select the AppIcon asset → drag in your icon

## Quick Upload Steps

### 1. Add App Icon (Required)
- Open Xcode → Select AppIcon asset
- Add 1024x1024 icon image

### 2. Archive
```bash
# Or use Xcode GUI:
# 1. Select "Any iOS Device" (not simulator)
# 2. Product → Archive
```

### 3. Upload
- Organizer opens automatically
- Click "Distribute App"
- Select "App Store Connect" → "Upload"
- Follow prompts (use automatic signing)

### 4. Wait & Configure
- Wait 10-60 min for processing in App Store Connect
- Go to TestFlight tab
- Add testers and submit for review (external testing only)

## Current Configuration

- **Bundle IDs**: 
  - App: `com.keyco.KeyCo`
  - Extension: `com.keyco.KeyCo.KeyCoKeyboard`
- **Version**: 1.0 (Build 1)
- **Team**: F8ZMT5492T
- **Status**: ✅ Ready (except app icon)

## Validation

Run before uploading:
```bash
./validate_for_testflight.sh
```

## Full Guide

See `TESTFLIGHT_GUIDE.md` for detailed instructions.

