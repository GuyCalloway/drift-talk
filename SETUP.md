# Flutter Voice AI App - Mac Development Setup

## Prerequisites

### 1. Install Flutter SDK
```bash
# Using Homebrew (recommended)
brew install flutter

# Or download directly from: https://flutter.dev/docs/get-started/install/macos
```

### 2. Install Xcode (for iOS development)
- Install from Mac App Store
- Accept Xcode license: `sudo xcodebuild -license accept`
- Install Xcode command line tools: `xcode-select --install`

### 3. Install Android Studio (for Android development)
- Download from: https://developer.android.com/studio
- Install Android SDK and create virtual device (AVD)

## Project Setup

### 1. Clone and Setup
```bash
git clone <repository-url>
cd drift-talk
flutter pub get
```

### 2. Environment Configuration
Create a `.env` file in the project root:
```bash
# .env
OPENAI_API_KEY=your_openai_api_key_here
```

**Never commit this file to version control!**

### 3. Generate Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Running on Different Platforms

### Web (Primary Platform)
```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port 8080
```

### iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"
```

### Android Emulator
```bash
# List available devices
flutter devices

# Start emulator
flutter emulators --launch <emulator_name>

# Run on Android
flutter run -d <device_id>
```

### Physical Devices

#### iOS Device
1. Connect iPhone/iPad via USB
2. Open Xcode and sign the app with your Apple Developer account
3. Trust developer certificate on device: Settings > General > VPN & Device Management
4. Run: `flutter run -d <device_name>`

#### Android Device
1. Enable Developer Options and USB Debugging
2. Connect via USB and accept debugging prompt
3. Run: `flutter run -d <device_name>`

## Development Workflow

### Hot Reload
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Testing
```bash
# Run unit tests
flutter test

# Run specific test
flutter test test/unit/voice_chat_bloc_test.dart

# Run with coverage
flutter test --coverage
```

### Building

#### Web
```bash
flutter build web --release
```

#### iOS
```bash
flutter build ios --release
```

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

## WebRTC Considerations

### Browser Support
- **Chrome/Edge**: Full WebRTC support ✅
- **Safari**: Limited support, may have issues ⚠️
- **Firefox**: Good support ✅

### Network Requirements
- HTTPS required for microphone access in browsers
- Firewall may need to allow WebRTC ports
- Corporate networks may block WebRTC

### Testing Audio
1. **Web**: Browser will prompt for microphone permission
2. **iOS**: App will request microphone permission
3. **Android**: Manifest includes microphone permission

## Troubleshooting

### Common Issues

#### 1. Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

#### 2. iOS Signing Issues
- Ensure valid Apple Developer account
- Update bundle identifier in `ios/Runner/Info.plist`
- Use Xcode to resolve signing issues

#### 3. Android Build Issues
- Update Android SDK and build tools
- Check `android/app/build.gradle` for version conflicts
- Ensure Java 11+ is installed

#### 4. WebRTC Connection Issues
- Check OpenAI API key is valid
- Verify network connectivity
- Test on different browsers

### Logs and Debugging
```bash
# View detailed logs
flutter run --verbose

# Debug mode with DevTools
flutter run --debug
```

## Performance Tips

### Development
- Use web for rapid iteration
- iOS Simulator for iOS-specific testing
- Physical devices for final testing

### Optimization
- Profile app performance: `flutter run --profile`
- Check bundle size: `flutter build web --analyze-size`
- Monitor WebRTC connection quality in browser DevTools

## Production Deployment

### Web Hosting
- Deploy `build/web` to any static hosting service
- Ensure HTTPS for WebRTC functionality
- Configure CORS headers if needed

### App Stores
- **iOS**: Use Xcode to upload to App Store Connect
- **Android**: Upload AAB to Google Play Console

## Security Notes

- Never commit API keys to version control
- Use environment variables or secure storage
- Review OpenAI API usage and billing
- Enable proper authentication in production

## Support

For issues specific to:
- **Flutter**: https://flutter.dev/docs
- **WebRTC**: https://webrtc.org/
- **OpenAI API**: https://platform.openai.com/docs

---

*This setup guide assumes macOS with admin privileges. Some commands may require `sudo`.*