# TestFlight Setup Guide for KeyCo

This guide will walk you through getting KeyCo on TestFlight.

## Prerequisites Checklist

- [x] Xcode project configured with bundle IDs
- [x] Development team set (`F8ZMT5492T`)
- [x] Code signing configured (Automatic)
- [ ] Apple Developer account with App Store Connect access
- [ ] App Store Connect app record created
- [ ] App archived and uploaded

## Step-by-Step Process

### Step 1: Verify App Store Connect Setup

1. **Log into App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Create App Record (if not already created)**
   - Click "My Apps" → "+" → "New App"
   - Fill in:
     - **Platform**: iOS
     - **Name**: KeyCo
     - **Primary Language**: English (U.S.)
     - **Bundle ID**: Select `com.keyco.KeyCo` (must match your Xcode project)
     - **SKU**: `keyco-001` (or any unique identifier)
     - **User Access**: Full Access (or select based on your team)
   - Click "Create"

3. **Verify App Information**
   - Go to App Information section
   - Ensure bundle ID matches: `com.keyco.KeyCo`
   - Note the App ID for reference

### Step 2: Prepare Xcode Project

1. **Open the Project**
   ```bash
   cd /Users/benrobinson/KeyCo
   open KeyCo.xcodeproj
   ```

2. **Verify Build Settings**
   - Select the **KeyCo** target (main app)
   - Go to "Signing & Capabilities"
   - Verify:
     - Team: `F8ZMT5492T` (or your team name)
     - Bundle Identifier: `com.keyco.KeyCo`
     - Code Signing: Automatic
   
   - Select the **KeyCoKeyboard** target (extension)
   - Verify:
     - Team: Same team as main app
     - Bundle Identifier: `com.keyco.KeyCo.KeyCoKeyboard`
     - Code Signing: Automatic

3. **Update Version Numbers (if needed)**
   - In Xcode, select the project in navigator
   - Select KeyCo target → General tab
   - **Version**: `1.0` (Marketing Version)
   - **Build**: `1` (or increment for each upload)
   - Repeat for KeyCoKeyboard target (version numbers should match)

### Step 3: Archive the App

1. **Select Generic iOS Device**
   - In Xcode, select "Any iOS Device" or "Generic iOS Device" from the device dropdown
   - ⚠️ **Important**: You cannot archive with a simulator selected

2. **Clean Build Folder**
   - Product → Clean Build Folder (Shift + Cmd + K)

3. **Archive**
   - Product → Archive
   - Wait for the archive to complete (may take a few minutes)
   - Organizer window will open automatically

### Step 4: Upload to App Store Connect

1. **In Organizer Window**
   - Select your archive
   - Click "Distribute App"

2. **Distribution Method**
   - Select "App Store Connect"
   - Click "Next"

3. **Distribution Options**
   - Select "Upload"
   - Click "Next"

4. **Distribution Options (Upload)**
   - Leave defaults checked:
     - ✅ Include bitcode for iOS content
     - ✅ Upload your app's symbols
   - Click "Next"

5. **Signing**
   - Select "Automatically manage signing"
   - Click "Next"

6. **Review & Upload**
   - Review the summary
   - Click "Upload"
   - Wait for upload to complete (may take 5-15 minutes)

### Step 5: Process Build in App Store Connect

1. **Wait for Processing**
   - Go to App Store Connect → My Apps → KeyCo
   - Click "TestFlight" tab
   - Wait for build to appear (can take 10-60 minutes)
   - Status will show "Processing" → "Ready to Submit"

2. **If Build Fails Processing**
   - Check email notifications
   - Review build details in TestFlight
   - Common issues:
     - Missing compliance information
     - Export compliance questions
     - Missing or invalid icons/screenshots

### Step 6: Configure TestFlight

1. **Add Test Information**
   - Go to TestFlight tab
   - Select your build
   - Fill in "What to Test" (optional but recommended)
   - Add test details, known issues, etc.

2. **Export Compliance**
   - If prompted, answer export compliance questions:
     - Does your app use encryption? (Yes/No)
     - If yes, use simplified declaration if appropriate

3. **Add Internal Testers (Optional)**
   - Go to "Internal Testing" section
   - Add testers (up to 100)
   - Select build to test
   - Testers will receive email invitation

4. **Add External Testers (Beta Testing)**
   - Go to "External Testing" section
   - Create a new group (or use existing)
   - Add testers (up to 10,000)
   - Submit for Beta App Review (first time only)
   - Once approved, select build and enable testing

### Step 7: Submit for Beta Review (External Testing Only)

**Note**: Internal testing doesn't require review. External testing requires Beta App Review for the first build.

1. **Complete App Information**
   - Privacy Policy URL (required for external testing)
   - Beta App Review Information:
     - Contact information
     - Demo account (if needed)
     - Notes for reviewer

2. **Submit for Review**
   - Select build
   - Click "Submit for Review"
   - Wait for approval (usually 24-48 hours)

## Troubleshooting Common Issues

### Archive Button Grayed Out
- **Solution**: Select "Any iOS Device" instead of a simulator

### Code Signing Errors
- **Solution**: 
  - Verify team is selected in Signing & Capabilities
  - Ensure bundle IDs match App Store Connect
  - Try cleaning build folder and re-archiving

### Upload Fails
- **Solution**:
  - Check internet connection
  - Verify Apple ID has App Store Connect access
  - Try uploading via Xcode Organizer or Transporter app

### Build Processing Fails
- **Solution**:
  - Check email for specific error
  - Verify app icons are present and correct size
  - Ensure all required metadata is filled in App Store Connect

### Keyboard Extension Not Included
- **Solution**:
  - Verify KeyCoKeyboard target is included in app
  - Check "Embed Foundation Extensions" build phase
  - Ensure extension has correct bundle ID and signing

## Next Steps After Upload

1. **Test on Physical Device**
   - Install TestFlight app from App Store
   - Accept invitation if external tester
   - Install and test KeyCo

2. **Monitor Feedback**
   - Check TestFlight feedback in App Store Connect
   - Monitor crash reports and analytics

3. **Iterate**
   - Fix bugs based on feedback
   - Increment build number
   - Upload new build
   - Select new build in TestFlight groups

## Quick Reference

- **Bundle IDs**:
  - Main App: `com.keyco.KeyCo`
  - Extension: `com.keyco.KeyCo.KeyCoKeyboard`
- **Team ID**: `F8ZMT5492T`
- **Current Version**: 1.0 (Build 1)
- **Deployment Target**: iOS 17.0

## Useful Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

