# Flutter Voice AI Application Architecture

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────┤
│  VoiceChatPage  │  AudioVisualization  │  ErrorDisplay     │
│  TextInputField │  PlaybackControls    │  LoadingStates    │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
┌─────────────────┴───────────────────────┴───────────────────┐
│                      BLOC LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  VoiceChatBloc  │  AudioBloc           │  ConnectionBloc    │
│  - States       │  - Recording         │  - WebSocket       │
│  - Events       │  - Playback          │  - Authentication  │
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
│  - WebSocket    │  - MessageModel      │  - AudioService    │
│  - Local Cache  │  - AudioModel        │  - SecurityService │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

1. **User Input**: User enters text in the input field
2. **State Management**: VoiceChatBloc receives input event
3. **Use Case**: SendMessage use case processes the request
4. **WebSocket**: Message sent to OpenAI Realtime API via WebSocket
5. **Audio Response**: Receives audio stream from OpenAI
6. **Audio Processing**: AudioService processes and plays audio
7. **UI Update**: Bloc updates UI with loading, success, or error states

## Component Responsibilities

### Presentation Layer
- **VoiceChatPage**: Main UI screen with text input and audio controls
- **AudioVisualization**: Real-time audio waveform display
- **Shared Widgets**: Reusable UI components

### Business Logic (BLoC)
- **VoiceChatBloc**: Manages conversation state and OpenAI communication
- **AudioBloc**: Handles audio recording and playback states
- **ConnectionBloc**: Manages WebSocket connection lifecycle

### Domain Layer
- **Entities**: Core business objects (VoiceMessage, AudioResponse)
- **Use Cases**: Business logic operations
- **Repository Interfaces**: Contracts for data operations

### Data Layer
- **WebSocket Service**: Real-time communication with OpenAI
- **Audio Service**: Platform-specific audio operations
- **Security Service**: Secure key storage and authentication

## Technology Stack

- **State Management**: Flutter BLoC
- **Dependency Injection**: GetIt + Injectable
- **Audio**: record + just_audio + audio_waveforms
- **WebSocket**: web_socket_channel
- **HTTP**: Dio
- **Security**: flutter_secure_storage
- **Testing**: bloc_test + mockito