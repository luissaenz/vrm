# App Store Screenshot Guide

## Requirements

### Google Play Store
- **Minimum**: 2 screenshots
- **Maximum**: 8 screenshots
- **Format**: JPEG or PNG
- **Minimum dimension**: 320px, maximum dimension: 3840px
- **Recommended**: Phone screenshots (1080x1920 or similar)

### Apple App Store
- **iPhone 6.5" display**: Minimum 3-5 screenshots (required)
- **iPhone 5.5" display**: Optional but recommended
- **iPad**: Required if your app supports iPad
- **Format**: JPEG or PNG
- **Maximum**: 10 screenshots per device type

## Recommended Screenshots for VRM App

Based on your app features, here are the recommended screenshots to capture:

### 1. Onboarding Screen (1-2 screenshots)
**What to show**: The onboarding flow introduction
**Caption**: "Get started in minutes - Quick setup for content creation"

### 2. Dashboard Page (1-2 screenshots)
**What to show**: Main dashboard with all features accessible
**Caption**: "Your content command center - All projects at your fingertips"

### 3. Recording/Camera Feature (1-2 screenshots)
**What to show**: The recording interface with camera controls
**Caption**: "Professional recording - Atomic camera workflows"

### 4. AI Assistant (1 screenshot)
**What to show**: The assistant interface/voice interaction
**Caption**: "AI-powered assistant - Create better content faster"

### 5. Influencer Profile (1 screenshot)
**What to show**: Profile management screen
**Caption**: "Manage your brand - Influencer tools built-in"

### 6. Project Management (1 screenshot)
**What to show**: Project creation or fragment management
**Caption**: "Organize your workflow - From idea to published content"

## How to Capture Screenshots

### Method 1: Using Flutter DevTools (Recommended)

1. Run your app in release mode:
```bash
flutter run --release
```

2. Navigate to each screen you want to capture

3. Take screenshots using device emulator/simulator or physical device:
   - **Android Emulator**: Use the camera icon in the emulator toolbar
   - **iOS Simulator**: File → Save Screenshot (⌘S)
   - **Physical Device**: Use device button combinations

### Method 2: Using Automated Package

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  screenshot: ^3.0.0
```

Example code:
```dart
import 'package:screenshot/screenshot.dart';

final screenshotController = ScreenshotController();

// Wrap your widget
Screenshot(
  controller: screenshotController,
  child: YourWidget(),
)

// Capture
await screenshotController.capture();
```

### Method 3: Manual (Quick & Easy)

1. Run app on emulator/physical device
2. Navigate to each screen
3. Take screenshots manually:
   - **Windows**: Win + Shift + S
   - **Mac**: ⌘ + Shift + 4
   - **Physical Device**: Power + Volume Down (most phones)

## Screenshot Specifications

### Phone Screenshots (Both Stores)
- **Resolution**: 1080 x 1920 px (recommended)
- **Orientation**: Portrait
- **Aspect Ratio**: 9:16 or similar

### Adding Text Overlays (Optional but Recommended)

Use tools like:
- **Canva**: Free templates for app screenshots
- **Figma**: Create custom mockups
- **Photoshop**: Professional editing
- **App Store Screenshot generators**: Online automated tools

## Screenshot Checklist

Before uploading to stores:

- [ ] At least 2 screenshots for Google Play
- [ ] At least 3-5 screenshots for Apple (6.5" display)
- [ ] All screenshots are high quality (no blur)
- [ ] Show actual app functionality (no mockups)
- [ ] Include key features (onboarding, dashboard, recording)
- [ ] Remove any sensitive/test data
- [ ] Add text overlays/captions (optional but recommended)
- [ ] Consistent style across all screenshots
- [ ] No device frames (stores add these automatically)
- [ ] Saved in correct format (JPEG/PNG)

## Screenshot File Naming (Organized)

```
screenshots/
├── google_play/
│   ├── 01_onboarding.png
│   ├── 02_dashboard.png
│   ├── 03_recording.png
│   └── 04_ai_assistant.png
└── apple_app_store/
    ├── iphone_6.5_01_onboarding.png
    ├── iphone_6.5_02_dashboard.png
    ├── iphone_6.5_03_recording.png
    ├── iphone_6.5_04_ai_assistant.png
    └── iphone_6.5_05_projects.png
```

## Pro Tips

✅ **DO**:
- Show your app's unique value proposition
- Use real data (not lorem ipsum)
- Highlight what makes you different
- Keep text overlays minimal and readable
- Test screenshots with potential users

❌ **DON'T**:
- Use placeholder/mockup screens
- Include sensitive information
- Show error states or empty screens
- Use device frames (stores add these)
- Overdo text overlays

## Quick Action: Capture These 5 Screens

For your MVP, focus on these 5 essential screenshots:

1. **Onboarding** - Show ease of setup
2. **Dashboard** - Show feature richness  
3. **Recording Screen** - Show core functionality
4. **AI Assistant** - Show unique value
5. **Profile/Projects** - Show organization tools

This gives both stores enough high-quality screenshots to showcase your app!
