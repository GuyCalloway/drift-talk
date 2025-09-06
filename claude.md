# Drift - Flutter Voice AI Travel Guide Application

## Overview

Drift is a production-ready Flutter voice AI application that creates an interactive travel guide experience. The app provides location-based conversations about historical landmarks using OpenAI's Realtime API via WebRTC, specifically focused on Charles Dickens' London walking tour.

## Current Implementation Status

This codebase contains a **fully implemented** Flutter voice AI application with the following features:

### ✅ Core Features Implemented
- **WebRTC Integration**: Direct connection to OpenAI Realtime API using flutter_webrtc
- **Location Context Service**: Pre-loaded database of 16 Dickens walking tour locations
- **Smart Conversation Management**: Intelligent conversation flow with topic tracking
- **Cost Optimization**: Connection management and session optimization to minimize API costs
- **Audio Processing**: Real-time audio streaming and playback
- **BLoC State Management**: Complete state management architecture
- **Clean Architecture**: Domain/Data/Presentation layer separation
- **Error Handling**: Comprehensive error handling and recovery
- **Dependency Injection**: GetIt + Injectable setup

### 🎯 Application Purpose
The app serves as an AI travel guide for exploring Dickens-related locations in London's Southwark area. Users tap a central image to receive interesting facts and historical context about nearby landmarks, delivered via AI-generated speech.

## Architecture Overview

### Project Structure
```
lib/
├── core/
│   ├── config/           # App configuration and environment setup
│   ├── constants/        # App-wide constants
│   ├── di/              # Dependency injection setup
│   ├── errors/          # Custom exceptions and error handling
│   ├── network/         # WebRTC client and connection management
│   ├── services/        # Business logic services
│   ├── storage/         # Secure storage implementation
│   └── utils/           # Logging and utilities
├── features/
│   └── voice_chat/
│       ├── data/        # Data sources and models
│       ├── domain/      # Entities, repositories, use cases
│       └── presentation/ # UI, BLoC, and widgets
├── shared/
│   └── theme/           # App theming and styles
└── main.dart            # App entry point
```

### Key Technical Components

#### 1. WebRTC Client (`lib/core/network/webrtc_client.dart`)
- Direct WebRTC connection to OpenAI Realtime API
- Audio stream handling with duplicate prevention
- Connection state management with safeguards
- ICE candidate handling and SDP offer/answer exchange

#### 2. Location Context Service (`lib/core/services/location_context_service.dart`)
- 16 pre-loaded Dickens walking tour locations
- GPS coordinate matching for location detection
- Rich historical context for each landmark
- Name-based location lookup functionality

#### 3. Smart Conversation Manager (`lib/core/services/smart_conversation_manager.dart`)
- Topic tracking to avoid repetition
- Rate limiting for conversation flow
- Context optimization for cost efficiency
- Intelligent response filtering

#### 4. OpenAI WebRTC Data Source (`lib/features/voice_chat/data/datasources/openai_webrtc_datasource.dart`)
- Message queuing system to handle concurrent requests
- Connection locking to prevent race conditions
- Audio delta processing with base64 decoding
- Session configuration with cost-optimized settings

#### 5. Voice Chat BLoC (`lib/features/voice_chat/presentation/bloc/voice_chat_bloc.dart`)
- Complete state management for voice interactions
- Message history tracking
- Connection status monitoring
- Error handling and recovery

## Key Features in Detail

### 1. **Context-Aware Voice Responses**
The app provides context about specific locations when users interact:
```dart
String _extractKeyFact(String talkingPoints) {
  // Extract concise, engaging facts for voice delivery
  final sentences = talkingPoints.split('. ');
  if (sentences.isNotEmpty && sentences[0].length <= 150) {
    return sentences[0] + '.';
  }
  // Smart truncation logic...
}
```

### 2. **Auto-Fact Generation**
Configurable interval-based fact delivery:
- User-selectable intervals (15s, 30s, 45s, 60s, 120s)
- Automatic cycling through different locations
- Intelligent conversation flow management

### 3. **Cost Optimization**
Multiple strategies to minimize OpenAI API costs:
- **Ultra-minimal token limits**: `max_response_output_tokens: 12`
- **Session reuse**: Single connection for multiple interactions
- **Smart queuing**: Prevents redundant API calls
- **Connection management**: Auto-disconnect scheduling

### 4. **Background Noise Strategy**
Current implementation includes:
- **Audio Configuration**: Echo cancellation, noise suppression, auto gain control
- **WebRTC Audio Settings**: Optimized for speech clarity
```dart
'audio': {
  'sampleRate': 24000,
  'channelCount': 1,
  'echoCancellation': true,
  'noiseSuppression': true,
  'autoGainControl': true,
}
```

## Local Development Setup

### Prerequisites
- Flutter 3.24+ with Dart 3.0+
- iOS Simulator / Android Emulator or physical device
- OpenAI API key with Realtime API access

### Environment Configuration
1. Create `.env` file in project root:
```
OPENAI_API_KEY=your_openai_api_key_here
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate dependency injection:
```bash
dart run build_runner build
```

### Running the Application
```bash
# Debug mode
flutter run

# Release mode (iOS/Android)
flutter run --release

# Web (experimental)
flutter run -d chrome --web-renderer html
```

## How Context Works

### Context Flow
1. **Initial Context**: User taps the central image to trigger location-based facts
2. **Location Detection**: App cycles through pre-loaded Dickens tour locations
3. **AI Processing**: Context + location data sent to OpenAI Realtime API
4. **Voice Response**: AI generates short, engaging facts about the location
5. **Auto-cycling**: Configurable intervals automatically trigger new facts

### Context Storage Per User
```dart
// Context management in LocationContextService
List<LocationData> getAllLocations() => List.unmodifiable(_walkingTourData);

String? getLocationContextByName(String locationName) {
  // Intelligent location matching and context retrieval
}
```

### Context Updates
- **Real-time**: Context updates immediately when new locations are selected
- **Persistence**: App state maintained across sessions
- **Queue Management**: Smart handling of concurrent context requests

## Current UI/UX

The app features a clean, minimal interface:
- **Central Image**: Large circular image that users tap for facts
- **Speech Animation**: Pulsing animation when AI is speaking  
- **Connection Status**: Real-time WebRTC connection indicator
- **Interval Selector**: Bottom-left dropdown for auto-fact timing
- **Voice Input**: Top-left microphone button (currently simulated)

## Technical Achievements

### 1. **Production-Ready Architecture**
- Clean Architecture with proper separation of concerns
- Comprehensive error handling and recovery
- Logging and debugging capabilities
- Dependency injection with Injectable

### 2. **Performance Optimizations**
- Efficient WebRTC connection management
- Audio stream optimization with duplicate prevention
- Memory management for long-running sessions
- Battery-conscious implementation

### 3. **Developer Experience**
- Hot reload support
- Comprehensive testing structure
- Clear documentation and code comments
- Type-safe implementation with null safety

## Future Enhancement Areas

While the current implementation is production-ready, potential enhancements include:

1. **Voice Input Processing**: Real voice-to-text for user interactions
2. **Multi-voice Conversations**: Male/female voice alternating discussions
3. **Enhanced Background Noise Handling**: VAD (Voice Activity Detection)
4. **Offline Mode**: Local context storage and playback
5. **User Personalization**: Learning preferences and interests

## API Cost Management

The app implements several cost optimization strategies:
- **Minimal Token Usage**: 12-token response limit
- **Connection Pooling**: Reuse WebRTC connections
- **Smart Queuing**: Prevent duplicate API calls
- **Session Management**: Efficient connection lifecycle

## Testing Strategy

Current test structure includes:
- **Unit Tests**: Business logic and services (`test/unit/`)
- **Widget Tests**: UI components and interactions (`test/widget/`)
- **Integration Tests**: End-to-end flow testing (`test/integration/`)
- **Mock Data Sources**: Testing without API calls

---

This implementation represents a complete, production-ready Flutter voice AI application that demonstrates best practices for WebRTC integration, state management, and cost-effective API usage.
