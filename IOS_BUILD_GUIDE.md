# ARIA iOS Build Guide

This guide explains how to build the ARIA iOS app using GitHub Actions and install it on your iPhone using AltStore.

## Prerequisites

1. **GitHub Account** (free)
2. **iPhone** with iOS 16+
3. **Windows PC** or Mac
4. **Apple ID** (free, no developer account needed)

## Step 1: Push to GitHub

1. Create a new repository on GitHub (e.g., `ARIA-App`)
2. Push this project to the repository:

```bash
git init
git add .
git commit -m "Initial ARIA commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/ARIA-App.git
git push -u origin main
```

## Step 2: GitHub Actions Build

The workflow file (`.github/workflows/build-ios.yml`) is already configured. It will:

1. Build the iOS app using Xcode on macOS runner
2. Create an unsigned IPA file
3. Upload it as an artifact

### Trigger a Build

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Build ARIA iOS App**
4. Click **Run workflow** → **Run workflow**
5. Wait ~10 minutes for build to complete

### Download the IPA

1. After build completes, click on the workflow run
2. Scroll down to **Artifacts**
3. Download `ARIA-iOS-IPA`
4. Unzip to get `ARIA.ipa`

## Step 3: Install AltStore

### On Windows:

1. Download **AltServer** from https://altstore.io/
2. Install iTunes and iCloud from Apple (NOT Microsoft Store versions)
   - iTunes: https://support.apple.com/en-us/HT210384
   - iCloud: https://support.apple.com/en-us/HT204283
3. Install AltServer
4. Connect iPhone to PC via USB
5. Click AltServer icon in system tray → **Install AltStore** → Select your iPhone
6. Enter your Apple ID when prompted

### On iPhone:

1. Open **Settings** → **General** → **VPN & Device Management**
2. Trust your Apple ID under **Developer App**
3. Open **AltStore** app

## Step 4: Install ARIA

1. Transfer `ARIA.ipa` to your iPhone (AirDrop, email, or file sharing)
2. Open **AltStore** on iPhone
3. Tap **My Apps** tab
4. Tap **+** button (top left)
5. Select `ARIA.ipa`
6. Enter your Apple ID if prompted
7. Wait for installation

## Step 5: Trust the App

1. Open **Settings** → **General** → **VPN & Device Management**
2. Find ARIA under your Apple ID
3. Tap **Trust**

## Step 6: Refresh Weekly

AltStore apps expire after 7 days. To refresh:

1. Connect iPhone to same Wi-Fi as your PC
2. Open AltServer on PC
3. Open AltStore on iPhone
4. Apps refresh automatically, or tap **Refresh All**

## Troubleshooting

### "Failed to install"
- Make sure you trusted the developer certificate
- Try restarting AltServer and iPhone

### "App expires in 7 days"
- This is normal for free Apple IDs
- Just refresh weekly with AltServer running

### "Could not connect to AltServer"
- Make sure PC and iPhone are on same Wi-Fi
- Disable VPN on both devices temporarily
- Check Windows Firewall allows AltServer

## Alternative: Xcode (if you have a Mac)

If you have access to a Mac, you can build directly:

1. Open `ARIA.xcodeproj` in Xcode
2. Connect iPhone
3. Select your iPhone as target
4. Build and run

## Next Steps

Once you have the app running:
1. Set up the backend (see backend README)
2. Configure API keys in the app
3. Start using ARIA!

## Support

For issues with:
- **Build process**: Check GitHub Actions logs
- **AltStore**: Visit https://faq.altstore.io/
- **ARIA app**: Open an issue in this repository
