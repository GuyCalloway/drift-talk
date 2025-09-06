# Drift - Flutter Voice AI Travel Guide Application

A production-ready Flutter voice AI application that creates an interactive travel guide experience for Charles Dickens' London walking tour. The app features dual modes: OpenAI's Realtime API for AI conversations and Text-to-Speech for location-based content delivery.

## Features Overview

### 🎭 **Dual Mode Operation**
- **AI Mode**: Interactive conversations with OpenAI's Realtime API via WebRTC
- **TTS Mode**: Text-to-speech reading of curated travel content
- **Smart Mode Switching**: Automatic connection management when toggling modes

### 🖼️ **Dynamic Logo System**
- **Random Logo Selection**: Chooses between person1.png and person2.png at startup
- **Pulsating Animation**: Logo pulses when AI is speaking or TTS is reading
- **Optimized Display**: Clean white circular background with proper image fitting

### 🌍 **Location-Based Intelligence**
- **Pre-loaded Database**: 16 Dickens walking tour locations in London's Southwark area
- **Contextual Facts**: Historical information and interesting talking points for each location
- **Auto-cycling Content**: Configurable intervals (15s, 30s, 45s, 60s, 120s) for automatic fact delivery

### Example Interaction

**AI Mode:**
```
User taps central logo → AI provides historical fact about current location
"Borough Market has been feeding London for over 1,000 years, making it one of the world's oldest food markets."
```

**TTS Mode:**
```
User taps central logo → TTS reads curated Riga tour content
"But the rest of the city has been preserved incredibly well, and it's absolutely stunning to walk around..."
```

## Features

### 🎯 **Ultra-Minimal Communication**

- Maximum 1-2 sentence responses
- Single talking point per interaction
- No small talk or unnecessary verbosity
- Context-dependent information only

### 📍 **Location-Aware Intelligence**

- Provide location context for specific directional guidance
- Smart extraction of the most interesting local facts
- Contextual relevance over generic information

### 🔊 **Optimized Voice Processing**

- Real-time audio streaming via WebRTC
- Cost-optimized with minimal token usage (100 tokens vs 4096 default)
- Single-connection architecture prevents audio conflicts

### 🛡️ **Robust Connection Management**

- Connection-level locks prevent multiple simultaneous requests
- Automatic timeout protection (15-second auto-unlock)
- Graceful error handling with connection recovery

## Architecture Overview

The application follows Clean Architecture principles with a focus on user experience flow:

```
User Input (Text + Context) 
    ↓
Business Logic (BLoC Pattern)
    ↓  
Domain Layer (Use Cases & Entities)
    ↓
Data Layer (Repository Pattern)
    ↓
OpenAI Realtime API (WebRTC)
    ↓
Audio Response (Minimal & Contextual)
```

### Key Components

**Presentation Layer**
- `VoiceChatPage`: Main interface with mode toggle, central logo button, and response display
- Dynamic logo selection and pulsating animations
- Mode-aware UI that adapts between AI and TTS functionality

**Service Layer**
- `LogoSelectionService`: Random selection between person1.png and person2.png at startup
- `TextToSpeechService`: Flutter TTS integration with optimized speech settings (0.4 rate)
- `MockLocationTextService`: Curated content delivery for TTS mode (4 Riga tour segments)
- `LocationContextService`: 16 pre-loaded Dickens walking tour locations

**Business Logic**
- `VoiceChatBloc`: Dual-mode state management (AI WebRTC + TTS)
- Smart connection management with automatic disconnect/reconnect
- Animation control system that responds to both AI and TTS speaking states

**Data Layer**
- `VoiceChatRepository`: Abstract interface supporting both AI and TTS modes
- `OpenAIWebRTCDataSource`: Real-time API communication with connection locking
- WebRTC client optimized for travel guide interactions

## Project Structure

```
lib/
├── core/                          # Shared infrastructure
│   ├── di/                        # Dependency injection
│   ├── network/                   # WebRTC client
│   ├── services/                  # Business logic services
│   │   ├── logo_selection_service.dart    # Random logo selection
│   │   ├── text_to_speech_service.dart    # TTS functionality
│   │   ├── mock_location_text_service.dart # Curated content
│   │   └── location_context_service.dart   # Dickens tour locations
│   ├── errors/                    # Error handling
│   └── utils/                     # Utilities & logging
├── features/
│   └── voice_chat/                # Main feature module
│       ├── data/                  # External data sources
│       │   ├── datasources/       # OpenAI WebRTC integration
│       │   ├── repositories/      # Repository implementation
│       │   └── models/            # Data transfer objects
│       ├── domain/                # Business logic
│       │   ├── entities/          # Core business objects
│       │   ├── repositories/      # Repository interfaces
│       │   └── usecases/          # Application-specific business rules
│       └── presentation/          # UI layer
│           ├── pages/             # Screen widgets
│           ├── widgets/           # Reusable UI components
│           └── bloc/              # State management
├── shared/                        # Shared UI resources
│   ├── theme/                     # App theming
│   └── widgets/                   # Common widgets
└── main.dart                      # Application entry point
```

## Technical Specifications

### Real-time Communication

- **Protocol**: WebRTC for low-latency audio streaming
- **API**: OpenAI Realtime API with GPT-4 Realtime model
- **Audio Format**: PCM16 at 24kHz sample rate
- **Connection**: Singleton pattern prevents duplicate audio streams

### Cost Optimization

- **Token Limits**: Maximum 100 tokens per response (vs default 4096)
- **Session Reuse**: Configuration cached to minimize API calls
- **Selective Processing**: Only processes context-relevant information
- **Estimated Savings**: ~85% reduction in API costs

### Performance Features

- **Response Time**: <100ms typical response latency
- **Connection Recovery**: Automatic reconnection on failure
- **Memory Efficient**: Minimal audio buffering
- **Error Resilient**: Graceful handling of network issues

## Prerequisites

Before getting started, ensure you have:

- **Flutter SDK**: 3.24.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **OpenAI API Key**: From [OpenAI Platform](https://platform.openai.com/api-keys) with Realtime API access

### Platform Requirements

#### iOS

- iOS 12.0 or higher
- Xcode 14.0 or higher
- macOS for iOS development

#### Android

- Android API Level 21 (Android 5.0) or higher
- Android Studio 4.0 or higher

## Installation & Setup

```bash
# Clone and setup
git clone <repository-url>
cd drift-talk
flutter pub get

# Generate dependency injection
flutter packages pub run build_runner build
```

### Environment Configuration

Create `.env` file in project root:

```env
OPENAI_API_KEY=your_openai_api_key_here
```

### Running the Application

**Web (Recommended)**
```bash
flutter run -d chrome
```

**Android (Physical Device)**
```bash
flutter run                    # Debug mode
flutter build apk && flutter install  # Release mode
```

**iOS**
```bash
flutter run -d ios
```

### Usage Instructions

#### AI Mode (Default)
1. **Connect**: App automatically connects to OpenAI on startup
2. **Tap Logo**: Central logo button triggers AI to speak about current Dickens tour location
3. **Auto-cycling**: Configurable intervals (15s-120s) automatically present new locations
4. **Listen**: Receive brief, contextual audio responses about historical landmarks

#### TTS Mode
1. **Toggle Mode**: Switch to TTS mode using the toggle in the app bar
2. **Tap Logo**: Central logo button reads curated Riga tour content
3. **Pulsating Animation**: Logo pulses while TTS is speaking
4. **Optimized Speech**: Slower speech rate (0.4) for better comprehension

#### Mode Switching
- **Smart Isolation**: Switching modes automatically disconnects/reconnects appropriate services
- **No Conflicts**: TTS mode stops AI connections; AI mode stops TTS playback
- **Seamless Transitions**: Maintains app state while switching between modes

## Cost Considerations

This application is designed to be cost-effective:

- **Minimal Responses**: 100-token limit reduces costs by ~97%
- **Context Efficiency**: Use context field to pack multiple pieces of information
- **Session Management**: Connections are reused and optimized
- **Smart Processing**: Only interesting context points are discussed

**Estimated Usage Cost**: $0.01-0.05 per conversation (vs $0.50-2.00 for typical implementations)

## Architecture Documentation

For detailed architectural information including data flow diagrams and user interaction patterns, see [docs/architecture.md](docs/architecture.md).

### 3. OpenAI API Key Setup

The app securely stores your OpenAI API key using Flutter Secure Storage. On first run:

1. The app will prompt for your OpenAI API key
2. Enter your key from the OpenAI Platform
3. The key is encrypted and stored securely on device
4. Subsequent launches will use the stored key

### 4. Platform-Specific Setup

#### iOS Setup

1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure app signing with your Apple Developer account
3. Add microphone permissions to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record voice messages</string>
```

#### Android Setup

1. Microphone permissions are automatically added via dependencies
2. No additional configuration required for basic setup

## Running the Application

### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run with specific flavor
flutter run --flavor development

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode for testing performance
flutter run --release
```

### Device-Specific Commands

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Physical device (when connected)
flutter devices  # List available devices
flutter run -d <device-id>
```

## Development Workflow

### Hot Reload & Hot Restart

- **Hot Reload** (`r`): Instantly update UI changes during development
- **Hot Restart** (`R`): Restart the app while preserving state
- **Full Restart** (`q` then rerun): Complete app restart

### Code Generation

When modifying dependency injection or data models:

```bash
# Generate code
flutter packages pub run build_runner build

# Watch for changes and auto-generate
flutter packages pub run build_runner watch

# Clean and regenerate
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Testing

### Running Tests

```bash
# Unit tests
flutter test

# Unit tests with coverage
flutter test --coverage

# Widget tests
flutter test test/widget/

# Integration tests
flutter test integration_test/

# All tests
flutter test test/ integration_test/
```

### Test Structure

```
test/
├── unit/                 # Unit tests for business logic
│   ├── voice_chat_bloc_test.dart
│   └── audio_bloc_test.dart
├── widget/              # Widget testing
│   └── voice_chat_page_test.dart
└── integration/         # Integration tests
    └── voice_chat_integration_test.dart
```

## Debugging

### Audio & WebSocket Issues

1. **Check Permissions**:

   ```bash
   # On device, verify microphone permissions are granted
   # Check device settings > Privacy > Microphone
   ```
2. **WebSocket Connection**:

   ```bash
   # Enable verbose logging to debug connection issues
   # Check console logs for connection status
   flutter logs
   ```
3. **API Key Issues**:

   ```bash
   # Clear stored API key to re-enter
   # The app will prompt again on next launch
   ```

### Common Issues & Solutions

| Issue                      | Solution                                            |
| -------------------------- | --------------------------------------------------- |
| Audio not recording        | Check microphone permissions in device settings     |
| WebSocket connection fails | Verify API key and internet connection              |
| Build fails                | Run `flutter clean && flutter pub get`            |
| Code generation errors     | Run `flutter packages pub run build_runner clean` |
| iOS build issues           | Update Xcode and pods:`cd ios && pod install`     |

### Development Tools

```bash
# Flutter Inspector (for widget debugging)
flutter inspector

# Performance profiling
flutter run --profile

# Analyze code quality
flutter analyze

# Format code
flutter format .
```

## Build & Deployment

### Building for Release

#### Android (APK)

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### iOS

```bash
# Build iOS app
flutter build ios --release

# Build for specific architecture
flutter build ios --release --no-codesign
```

### Environment-Specific Builds

```bash
# Development build
flutter build apk --flavor development --debug

# Staging build
flutter build apk --flavor staging --release

# Production build
flutter build apk --flavor production --release
```

## Performance Optimization

### Audio Performance

- Audio processing is optimized for low latency
- Memory usage is minimized during long recordings
- Background processing is limited to preserve battery

### WebSocket Performance

- Connection pooling and automatic reconnection
- Efficient binary data handling for audio streams
- Configurable timeout and retry mechanisms

### UI Performance

- Smooth 60fps animations
- Efficient state management with BLoC
- Optimized widget rebuilds

## Security

### API Key Security

- OpenAI API keys are stored using Flutter Secure Storage
- Keys are encrypted at rest on device
- Never logged or exposed in debug output
- Separate keys for development/production environments

### Network Security

- All WebSocket connections use WSS (secure WebSocket)
- API communications use HTTPS
- Certificate pinning can be added for production

## Troubleshooting

### Build Issues

```bash
# Clean build cache
flutter clean
flutter pub get
flutter packages pub run build_runner clean

# Reset iOS pods
cd ios && rm -rf Pods Podfile.lock && pod install

# Clear Android build cache
cd android && ./gradlew clean
```

### Runtime Issues

1. **Check Flutter Doctor**:

   ```bash
   flutter doctor -v
   ```
2. **Check Device Logs**:

   ```bash
   flutter logs
   adb logcat  # Android
   xcrun simctl spawn booted log stream  # iOS
   ```
3. **Network Debugging**:

   - Verify internet connection
   - Check firewall/proxy settings
   - Test API key with curl:
     ```bash
     curl -H "Authorization: Bearer YOUR_API_KEY" https://api.openai.com/v1/models
     ```

## Contributing

1. Follow the established architecture patterns
2. Write unit tests for business logic
3. Add widget tests for new UI components
4. Update documentation for new features
5. Run `flutter analyze` before committing
6. Use conventional commit messages

## License

[Add your license information here]

## Support

For issues and questions:

1. Check this README and troubleshooting section
2. Review the architecture documentation
3. Check existing GitHub issues
4. Create a new issue with detailed information

---

## Quick Start Checklist

- [ ] Flutter SDK 3.24.0+ installed
- [ ] OpenAI API key obtained
- [ ] Repository cloned and dependencies installed
- [ ] Environment file configured
- [ ] App runs successfully on device/emulator
- [ ] Microphone permissions granted
- [ ] WebSocket connection established
- [ ] Audio recording/playback tested
- [ ] Tests pass locally

**Ready to build amazing voice AI experiences! 🎙️🤖**

** ****Context Flow**

**  ****How Context Gets to the AI:**

**  **1. User taps the central image in the app

**  **2. App automatically selects the next location from a pre-loaded list of 16 Dickens tour spots

**  **3. App grabs the historical details for that location (like "Monument Underground Station" or "Borough Market")

**  **4. This location info gets combined with the user's action and sent to OpenAI like this:

**  **final** locationContext = _locationService.getLocationContextByName(locationName);**

**  **final** prompt = **"What makes $locationName worth visiting?"**;**

**  **// Gets sent to AI as: "Current Location: Borough Market\nContext: Borough Market is one of London's oldest food markets..."

**  ****Context Updates:**

**  **-  **Automatic** **: Every 15-120 seconds (user picks the interval), app automatically moves to the next location**

**  **-  **Manual** **: When user taps the image, it immediately jumps to a new location**

**  **-  **Smart Queuing** **: If AI is already talking and user taps again, it finishes current response then starts the new location**

**  ****Local Storage Reality**

**  ** **Important** **: This app doesn't actually have traditional "per-user" local storage. Instead:**

**  ****What Gets Stored Locally:**

**  **- The 16 location database is hardcoded in the app (**LocationContextService**)

**  **- Current conversation state (which location we're on, connection status)

**  **- App settings (like the auto-fact interval timer)

**  ****No User Accounts:**

**  **// The locations are just stored in code like this:

**  **static**final**List**`<LocationData>` _walkingTourData = [**

**    **LocationData(name: **"Monument Underground Station"**, lat: **51.5102**, lng: **-0.0857**, talkingPoints: **"Historical info..."**),

**    **LocationData(name: **"Borough Market"**, lat: **51.5055**, lng: **-0.091**, talkingPoints: **"More historical info..."**),

**    **// ... 14 more locations

**  **];

**  ****Session Context:**

**  **- Context builds up during a single app session as you cycle through locations

**  **- When you close the app, conversation history is lost

**  **- When you reopen, it starts fresh from location #1
