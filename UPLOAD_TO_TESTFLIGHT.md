# How to Upload New Build to TestFlight

## Quick Steps

### 1. Increment Build Number
- Open `KeyCo.xcodeproj` in Xcode
- Select the **KeyCo** target (main app)
- Go to **General** tab
- Under **Identity**, change **Build** from `1` to `2`
- Repeat for **KeyCoKeyboard** target (keep build numbers matching)

### 2. Clean Build
- Product → Clean Build Folder (Shift + Cmd + K)

### 3. Archive
- Select **"Any iOS Device"** (not simulator)
- Product → Archive
- Wait for archive to complete

### 4. Upload
- Organizer window opens automatically
- Select your new archive
- Click **"Distribute App"**
- Select **"App Store Connect"**
- Click **"Next"**
- Select **"Upload"**
- Click **"Next"**
- Use **"Automatically manage signing"**
- Click **"Next"**
- Review and click **"Upload"**

### 5. Wait for Processing
- Go to App Store Connect → Keyboard Copilot → TestFlight
- Wait 10-60 minutes for processing
- Once "Ready to Submit", select it in your testing groups

## Notes
- Build number must increment each time (1 → 2 → 3 → etc.)
- Version can stay the same (1.0) unless major update
- No need to create new app record - just upload new build

