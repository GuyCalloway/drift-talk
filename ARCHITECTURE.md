# Flutter Voice AI Application Architecture

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  VoiceChatPage  │  ModeToggle          │  ErrorDisplay     │
│  DynamicLogo    │  PulsatingAnimation  │  LoadingStates    │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
┌─────────────────┴───────────────────────┴───────────────────┐
│                      BLOC LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  VoiceChatBloc  │  DualModeLogic       │  AnimationControl  │
│  - AI States    │  - TTS Integration   │  - AI Animation    │
│  - TTS States   │  - Mode Switching    │  - TTS Animation   │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
┌─────────────────┴───────────────────────┴───────────────────┐
│                     DOMAIN LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  UseCases       │  Entities            │  Repositories      │
│  - SendMessage  │  - VoiceMessage      │  - AudioRepository │
│  - PlayAudio    │  - AudioResponse     │  - OpenAIRepository│
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
┌─────────────────┴───────────────────────┴───────────────────┐
│                      DATA LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  DataSources    │  Models              │  Services          │
│  - WebRTC       │  - MessageModel      │  - LogoSelection   │
│  - MockLocation │  - AudioModel        │  - TextToSpeech    │
│  - TTS Content  │  - LocationData      │  - LocationContext │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### AI Mode Flow
1. **User Interaction**: User taps central logo button
2. **Location Selection**: App cycles through Dickens tour locations
3. **State Management**: VoiceChatBloc receives interaction event
4. **Context Building**: LocationContextService provides historical context
5. **WebRTC**: Message sent to OpenAI Realtime API via WebRTC
6. **Audio Response**: Receives audio stream from OpenAI
7. **Animation**: Logo pulsates while AI is speaking
8. **UI Update**: Bloc updates UI with response states

### TTS Mode Flow
1. **User Interaction**: User taps central logo button
2. **Content Selection**: MockLocationTextService provides curated content
3. **TTS Processing**: TextToSpeechService converts text to speech
4. **Animation Monitoring**: Timer monitors TTS speaking state
5. **Logo Animation**: Pulsating animation during TTS playback
6. **Completion**: Animation stops when TTS finishes

### Mode Switching Flow
1. **Mode Toggle**: User switches between AI/TTS modes
2. **Connection Management**: Auto-disconnect/reconnect appropriate services
3. **Animation Control**: Start/stop relevant animation monitoring
4. **UI State Update**: Update interface to reflect current mode

## Component Responsibilities

### Presentation Layer
- **VoiceChatPage**: Main UI screen with mode toggle, dynamic logo, and controls
- **Mode Toggle**: Switch between AI and TTS modes in app bar
- **Dynamic Logo**: Random selection between person1.png/person2.png at startup
- **Pulsating Animation**: Unified animation system for both AI and TTS states
- **Shared Widgets**: Reusable UI components

### Business Logic (BLoC)
- **VoiceChatBloc**: Dual-mode state management for AI/TTS operations
- **Mode Management**: Smart switching between AI WebRTC and TTS systems
- **Animation Control**: Monitors both AI processing and TTS speaking states
- **Connection Lifecycle**: WebRTC connect/disconnect based on active mode

### Domain Layer
- **Entities**: Core business objects (VoiceMessage, AudioResponse)
- **Use Cases**: Business logic operations
- **Repository Interfaces**: Contracts for data operations

### Data Layer
- **WebRTC Service**: Real-time communication with OpenAI Realtime API
- **TextToSpeech Service**: Flutter TTS integration with optimized settings
- **LogoSelection Service**: Random startup logo selection system
- **LocationContext Service**: 16 pre-loaded Dickens tour locations
- **MockLocation Service**: Curated TTS content (4 Riga tour segments)
- **Security Service**: Secure key storage and authentication

## Technology Stack

- **State Management**: Flutter BLoC (dual-mode architecture)
- **Dependency Injection**: GetIt + Injectable
- **WebRTC**: flutter_webrtc (OpenAI Realtime API)
- **Text-to-Speech**: flutter_tts (optimized speech rate)
- **Animation**: Flutter AnimationController with Timer monitoring
- **Asset Management**: Random logo selection from assets
- **HTTP**: Dio (for future API endpoints)
- **Security**: flutter_secure_storage
- **Testing**: bloc_test + mockito