# Production Build Configuration Guide

## Current Status Analysis

### ✅ Android Configuration
- **Application ID**: `com.vrm.vrm_app` (configured)
- **Compile SDK**: Using Flutter default
- **Min SDK**: Using Flutter default (typically API 21 - Android 5.0)
- **Target SDK**: Using Flutter default (latest)
- **Java Version**: Java 17
- **Build Type**: Release signing needed (currently using debug config)

### ✅ iOS Configuration
- **Project Structure**: Standard Flutter iOS setup
- **Config Files**: Debug.xcconfig, Release.xcconfig present
- **Icons**: Already configured

---

## Android Production Build Setup

### Step 1: Generate Signing Key (First Time Only)

**Windows (PowerShell or CMD):**
```powershell
cd d:\Develop\Personal\vrm\android\app

keytool -genkey -v -keystore vrm-app-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vrm-app
```

**You'll be prompted for:**
- Keystore password: `[Choose a strong password]`
- First and last name: `[Your Name or Company]`
- Organizational unit: `[Optional]`
- Organization: `[Your Company or Name]`
- City: `[Your City]`
- State: `[Your State]`
- Country code: `[e.g., US, ES, etc.]`

**⚠️ IMPORTANT: Securely store these credentials!**
- Keystore file: `vrm-app-release-key.jks`
- Keystore password
- Key alias: `vrm-app`
- Key password

**Add to `.gitignore` immediately:**
```
# Already in your .gitignore, but verify:
*.jks
*.keystore
```

### Step 2: Configure Signing in build.gradle.kts

Create `android/key.properties`:
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=vrm-app
storeFile=vrm-app-release-key.jks
```

**Update `android/app/build.gradle.kts`:**

```kotlin
// Add at the top, after plugins
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vrm.vrm_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.vrm.vrm_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support multiple languages
        resConfigs("en", "es")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Enable code shrinking and resource optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

### Step 3: Add ProGuard Rules (Optional but Recommended)

Create `android/app/proguard-rules.pro`:
```pro
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Camera & Video
-keep class com.google.android.exoplayer2.** { *; }

# SQLite
-keep class * extends java.util.ListResourceBundle {
    protected java.lang.Object[][] getContents();
}

# Keep static fields of inner classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep native methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
```

### Step 4: Optimize Android Build

**Update `android/app/src/main/AndroidManifest.xml`** - Add permissions for production:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    
    <!-- For Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <application
        android:label="VRM App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:screenOrientation="portrait">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>
</manifest>
```

---

## iOS Production Build Setup

### Step 1: Configure iOS Signing (Xcode)

1. **Open project in Xcode:**
```bash
open ios/Runner.xcworkspace
```

2. **Select Runner target → Signing & Capabilities**

3. **Enable Automatic Signing:**
   - ✅ Check "Automatically manage signing"
   - Select your Team (Apple Developer account)

4. **Set Bundle Identifier:**
   - Current: `com.vrm.vrm-app` (or similar)
   - Make it unique: `com.yourcompany.vrmapp` or `com.vrm.atomiccamera`

5. **Set Version and Build Number:**
   - Version: `1.0.0`
   - Build: `1`

### Step 2: Configure iOS Build Settings

**In Xcode, select Runner target → Build Settings:**

```
Deployment Target: iOS 13.0+ (or higher)
Devices: iPhone (or Universal if iPad support needed)
Bitcode: No (deprecated in Xcode 14+)
Strip Style: Non-Global Symbols
Enable Bitcode: NO
```

**Update `ios/Runner/Info.plist`** - Add required permissions:

```xml
<key>NSCameraUsageDescription</key>
<string>VRM App needs camera access to record videos for your content creation.</string>

<key>NSMicrophoneUsageDescription</key>
<string>VRM App needs microphone access to record audio with your videos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>VRM App needs photo library access to save and retrieve your content.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>VRM App needs speech recognition to provide voice commands and assistance.</string>
```

### Step 3: Optimize iOS Build

**Update `ios/Flutter/Release.xcconfig`:**

```
#include "Generated.xcconfig"

// Enable optimizations
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -Osize
SWIFT_COMPILATION_MODE = wholemodule

// Strip debug symbols
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
STRIP_INSTALLED_PRODUCT = YES
STRIP_STYLE = all
```

---

## Version Management

### Update Version in pubspec.yaml

```yaml
version: 1.0.0+1
# Format: <semantic_version>+<build_number>
# Examples:
# 1.0.0+1     - Initial release
# 1.0.1+2     - Bug fix release
# 1.1.0+3     - Feature release
# 2.0.0+4     - Major release
```

### Version Naming Strategy

```
MAJOR.MINOR.PATCH+BUILD

MAJOR: Breaking changes (2.0.0)
MINOR: New features (1.1.0)
PATCH: Bug fixes (1.0.1)
BUILD: Incrementing number (1, 2, 3...)
```

---

## Build Commands

### Android Release Build (AAB - Google Play)

```bash
# Navigate to project root
cd d:\Develop\Personal\vrm

# Clean previous builds
flutter clean
flutter pub get

# Build Android App Bundle (AAB)
flutter build appbundle --release

# OR build APK (for testing)
flutter build apk --release
```

**Output location:**
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Release Build (IPA - App Store)

```bash
# Navigate to project root
cd d:\Develop\Personal\vrm

# Clean previous builds
flutter clean
flutter pub get

# Build iOS IPA
flutter build ipa --release
```

**This will:**
1. Build the iOS app
2. Create an Xcode archive
3. Output IPA file

**Output location:**
- IPA: `build/ios/ipa/*.ipa`
- Xcode Archive: `~/Library/Developer/Xcode/Archives/`

---

## Pre-Build Checklist

### Before Building Release

- [ ] Update version in `pubspec.yaml`
- [ ] Test app thoroughly in release mode: `flutter run --release`
- [ ] Remove all `print()` statements used for debugging
- [ ] Remove debug-only features/code
- [ ] Verify app works without debugger attached
- [ ] Test on physical devices (Android & iOS)
- [ ] Check for hardcoded test credentials
- [ ] Verify all API keys are production keys
- [ ] Update privacy policy URL
- [ ] Verify app icons and splash screens
- [ ] Run `flutter analyze` and fix all issues
- [ ] Run tests: `flutter test`

### Code Quality Checks

```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Check for outdated dependencies
flutter pub outdated

# Update dependencies (optional)
flutter pub upgrade
```

---

## Post-Build Verification

### After Building

1. **Verify build output:**
   - Android: `.aab` file is 150MB or less (Google Play limit)
   - iOS: `.ipa` file is reasonable size

2. **Test the build:**
   - Android: Install AAB on device using `bundletool` or upload to Play Console internal testing
   - iOS: Use TestFlight or install IPA via Xcode

3. **Check app size:**
   - Aim for < 50MB download size
   - Use `flutter build apk --analyze-size` to analyze

4. **Verify functionality:**
   - Onboarding flow works
   - Camera/recording features work
   - No console errors
   - All navigation works
   - Localizations work (English & Spanish)

---

## App Store Optimizations

### Reduce App Size

1. **Remove unused assets:**
```yaml
# In pubspec.yaml, only include necessary assets
flutter:
  assets:
    - lib/core/schemas/
```

2. **Enable code shrinking** (already configured above)

3. **Use WebP for images** (smaller than PNG/JPG)

4. **Remove unused dependencies:**
```bash
flutter pub deps  # List all dependencies
```

5. **Split APKs by ABI** (optional):
```kotlin
// In android/app/build.gradle.kts
splits {
    abi {
        isEnable = true
        reset()
        include("armeabi-v7a", "arm64-v8a", "x86_64")
        isUniversalApk = true
    }
}
```

### Performance Optimizations

1. **Use deferred loading for large features:**
```dart
// Load heavy libraries on demand
import 'package:heavy_feature/heavy_feature.dart' deferred as heavy;

Future<void> loadFeature() async {
  await heavy.loadLibrary();
}
```

2. **Optimize images for different screen densities**

3. **Use caching for network requests**

---

## Troubleshooting

### Common Android Build Issues

**Issue: "Signing certificate fingerprint doesn't match"**
- Solution: Verify keystore credentials match what's registered

**Issue: "App too large for Google Play"**
- Solution: Enable code shrinking, remove unused assets, use App Bundle

**Issue: "Missing permissions at runtime"**
- Solution: Request permissions dynamically using `permission_handler` package

### Common iOS Build Issues

**Issue: "Code signing error"**
- Solution: Check signing certificate in Xcode, ensure developer account is active

**Issue: "IPA rejected for missing permissions"**
- Solution: Add all required permission strings to Info.plist

**Issue: "Bitcode error"**
- Solution: Disable bitcode in Xcode build settings

---

## Next Steps After Building

1. ✅ Test the release build on physical devices
2. ✅ Upload to Google Play Console (internal testing track first)
3. ✅ Upload to App Store Connect (TestFlight first)
4. ✅ Gather feedback from beta testers
5. ✅ Fix any critical issues
6. ✅ Submit for review

---

## Quick Build Commands Reference

```bash
# ===== ANDROID =====
# Build AAB for Google Play
flutter build appbundle --release

# Build APK for testing
flutter build apk --release

# Analyze APK size
flutter build apk --analyze-size

# ===== iOS =====
# Build IPA for App Store
flutter build ipa --release

# ===== GENERAL =====
# Clean and rebuild
flutter clean && flutter pub get && flutter build appbundle --release

# Run in release mode
flutter run --release

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## Security Best Practices

### Before Publishing

1. **Never commit keystore files to Git**
2. **Never commit key.properties with passwords**
3. **Use environment variables for CI/CD:**
```bash
# In CI/CD pipeline
$ANDROID_KEYSTORE_PASSWORD
$ANDROID_KEY_PASSWORD
$ANDROID_KEY_ALIAS
```

4. **Backup keystore securely:**
   - Store in password manager
   - Keep offline backup
   - Never lose it (can't update app without it!)

5. **Use HTTPS for all API calls**
6. **Validate all user inputs**
7. **Implement secure local storage for sensitive data**

---

**Remember:** Once you publish with a signing key, you MUST use the same key for all updates. Losing it means you can't update your app and would need to publish as a new app!
