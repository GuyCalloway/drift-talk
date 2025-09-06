# Development Guide

## Project Structure Deep Dive

### Core Layer (`lib/core/`)

**Purpose**: Shared infrastructure and utilities used across the entire application.

#### `constants/` - Application Constants
- `app_constants.dart`: API endpoints, timeouts, audio settings, error messages
- Centralized configuration makes the app maintainable and testable

#### `errors/` - Error Management
- `exceptions.dart`: Custom exceptions for different error types
- `failures.dart`: Domain-layer failure objects following Either pattern
- `error_handler.dart`: Centralized error handling with user-friendly messages

#### `network/` - Network Infrastructure  
- `websocket_client.dart`: WebSocket client with connection management
- Handles connection lifecycle, message streaming, and error recovery

#### `utils/` - Shared Utilities
- `logger.dart`: Centralized logging with different log levels
- Provides consistent logging across the application

#### `di/` - Dependency Injection
- `injection_container.dart`: GetIt service locator configuration
- Auto-generated code for dependency registration

### Feature Layers

Each feature follows Clean Architecture with three sublayers:

#### Data Layer (`data/`)
- **DataSources**: External data access (APIs, local storage)
- **Models**: Data transfer objects with JSON serialization  
- **Repositories**: Implementation of domain repository interfaces

#### Domain Layer (`domain/`)
- **Entities**: Core business objects (immutable, framework-independent)
- **Use Cases**: Application business rules and orchestration
- **Repositories**: Abstract interfaces defining data contracts

#### Presentation Layer (`presentation/`)
- **BLoC**: State management with events and states
- **Pages**: Screen-level widgets and navigation
- **Widgets**: Reusable UI components

## State Management Deep Dive

### BLoC Pattern Implementation

We use **flutter_bloc** for predictable state management:

#### VoiceChatBloc
**Responsibilities**:
- Managing conversation state and message history
- Orchestrating WebSocket communication with OpenAI
- Handling audio response streaming and playback
- Connection lifecycle management

**Key States**:
- `VoiceChatInitial`: App startup state
- `VoiceChatConnected`: Active connection with message history
- `VoiceChatMessageSending`: Processing outgoing message
- `VoiceChatAudioPlaying`: Playing received audio response
- `VoiceChatError`: Error state with recovery options

#### AudioBloc  
**Responsibilities**:
- Managing audio recording and playback state
- Handling device permissions
- Monitoring audio progress and duration
- Audio device lifecycle management

**Key States**:
- `AudioReady`: Default state with permission granted
- `AudioRecording`: Active recording with progress tracking
- `AudioPlaying`: Audio playback with controls
- `AudioPermissionRequired`: Requesting microphone access

### State Flow Examples

#### Sending a Message
```
User Input → VoiceChatMessageSent event → VoiceChatMessageSending state
  → SendMessageUseCase → WebSocket API → Audio stream response
    → VoiceChatAudioReceived event → AudioBloc playback → VoiceChatConnected
```

#### Recording Audio
```
Record Button → AudioRecordingStartRequested → Check permissions
  → AudioRecording state → Monitor progress → Stop recording
    → AudioRecordingCompleted with file path
```

## WebSocket Integration

### Connection Management

The `WebSocketClient` provides:
- **Automatic Reconnection**: Handles network interruptions
- **Message Queuing**: Buffers messages during reconnection
- **Error Recovery**: Graceful handling of connection failures
- **Lifecycle Management**: Clean connection/disconnection

### OpenAI Realtime API Integration

#### Message Flow
1. **Session Configuration**: Establish audio formats and settings
2. **Text Input**: Send user message as conversation item
3. **Response Generation**: Request AI response with audio output
4. **Audio Streaming**: Receive chunked audio data via WebSocket
5. **Audio Processing**: Decode and play audio chunks

#### Message Types
- `session.update`: Configure session parameters
- `conversation.item.create`: Add user message
- `response.create`: Request AI response
- `response.audio.delta`: Receive audio chunks
- `response.done`: Response completion signal

## Audio System Architecture

### Recording Pipeline
```
Microphone → AudioRecorder → PCM16 format → File storage
  → Recording progress updates → UI feedback
```

### Playback Pipeline  
```
Audio data/file → AudioPlayer → Device speakers
  → Playback progress updates → UI controls
```

### Permissions Handling
- **Request Strategy**: Just-in-time permission requests
- **Graceful Degradation**: UI adapts when permissions denied
- **User Education**: Clear explanations for permission needs

## Security Implementation

### API Key Management
- **Secure Storage**: Flutter Secure Storage with platform encryption
- **Key Rotation**: Support for updating keys without app reinstall
- **Environment Separation**: Different keys for dev/staging/production

### Data Protection
- **No Persistent Audio**: Temporary files cleaned after playback
- **Network Security**: HTTPS/WSS only, certificate validation
- **Error Sanitization**: Sensitive data removed from logs

## Testing Strategy

### Unit Tests (`test/unit/`)
**Focus**: Business logic in isolation
- BLoC state transitions
- Use case implementations  
- Repository pattern validation
- Error handling scenarios

**Example**: Testing VoiceChatBloc message sending logic

### Widget Tests (`test/widget/`)
**Focus**: UI behavior and user interactions
- Widget rendering correctness
- User input handling
- State-dependent UI changes
- Navigation flows

**Example**: Testing VoiceChatPage message input and display

### Integration Tests (`test/integration/`)
**Focus**: End-to-end workflows
- Complete user journeys
- Cross-feature interactions
- Performance under load
- Real device capabilities

### Mock Strategy
- **Repository Mocking**: Mock data layer for isolated testing
- **Use Case Mocking**: Mock business logic for UI testing
- **External Service Mocking**: Mock OpenAI API responses

## Performance Optimization

### Memory Management
- **Audio Buffer Limits**: Prevent memory leaks from large recordings
- **Stream Disposal**: Proper cleanup of WebSocket streams
- **Widget Optimization**: Efficient rebuilds with BlocBuilder

### Network Efficiency
- **Connection Pooling**: Reuse WebSocket connections
- **Compression**: Enable WebSocket compression for large payloads
- **Timeout Tuning**: Optimized timeouts for different connection types

### Battery Optimization
- **Background Limits**: Minimal processing when app backgrounded
- **Recording Limits**: Maximum duration caps for recordings
- **Efficient Codecs**: Use platform-optimized audio formats

## Code Quality Standards

### Architecture Guidelines
- **Single Responsibility**: Each class/function has one clear purpose
- **Dependency Inversion**: Depend on abstractions, not concretions
- **Clean Interfaces**: Simple, focused public APIs
- **Error Handling**: Comprehensive error scenarios covered

### Naming Conventions
- **Classes**: PascalCase with descriptive names
- **Methods**: camelCase with verb-based names
- **Variables**: camelCase with meaningful names
- **Constants**: SCREAMING_SNAKE_CASE for compile-time constants

### Documentation Requirements
- **Public APIs**: Full documentation with examples
- **Complex Logic**: Inline comments explaining the "why"
- **Architecture Decisions**: ADRs for significant design choices
- **README Updates**: Keep setup instructions current

## Development Workflow

### Feature Development Process
1. **Design Review**: Architecture and UI/UX approval
2. **Branch Creation**: Feature branch from main
3. **TDD Implementation**: Tests first, then implementation
4. **Code Review**: Peer review focusing on architecture
5. **Integration Testing**: End-to-end validation
6. **Documentation**: Update relevant docs
7. **Merge**: Squash and merge to main

### Code Review Checklist
- [ ] Follows clean architecture patterns
- [ ] Comprehensive error handling
- [ ] Unit tests for business logic
- [ ] Widget tests for UI components
- [ ] Performance considerations addressed
- [ ] Security requirements met
- [ ] Documentation updated

### Release Process
1. **Version Bump**: Update pubspec.yaml version
2. **Changelog**: Document new features and fixes
3. **Build Testing**: Verify release builds work
4. **Integration Testing**: Full end-to-end validation
5. **Tag Release**: Git tag with version number
6. **Deploy**: Platform-specific deployment process

## Environment Configuration

### Development Environment
- Detailed logging enabled
- Debug UI indicators
- Mock services for testing
- Hot reload optimizations

### Staging Environment
- Production-like configuration
- Real API endpoints
- Performance monitoring
- Limited logging

### Production Environment
- Optimized builds
- Minimal logging
- Error reporting
- Performance analytics

## Troubleshooting Guide

### Common Development Issues

#### BLoC-Related Problems
**Issue**: States not emitting
**Solution**: Check event handling, verify stream subscriptions

**Issue**: Memory leaks from BLoCs
**Solution**: Ensure proper stream disposal in close() method

#### Audio-Related Problems  
**Issue**: Recording not working
**Solution**: Verify permissions, check audio format compatibility

**Issue**: Playback stuttering
**Solution**: Check buffer sizes, verify device audio capabilities

#### WebSocket Problems
**Issue**: Connection dropping
**Solution**: Check network stability, verify API key validity

**Issue**: Message ordering issues  
**Solution**: Implement message queuing, check timestamp handling

### Debug Tools and Techniques

#### Flutter Inspector
- Widget tree inspection
- Property modification
- Performance profiling

#### BLoC Observer
- State transition logging  
- Performance monitoring
- Debug information gathering

#### Network Debugging
- Charles Proxy for traffic inspection
- WebSocket message logging
- Connection timing analysis

## Contributing Guidelines

### Code Style
- Follow official Dart style guide
- Use `flutter analyze` for static analysis
- Format code with `flutter format`
- Document public APIs thoroughly

### Git Workflow
- Feature branches for all changes
- Conventional commit messages
- Rebase before merging
- Squash commits for clean history

### Testing Requirements
- Unit tests for all business logic
- Widget tests for complex UI
- Integration tests for critical paths
- Maintain >80% code coverage

---

This development guide should evolve with the project. Keep it updated as the architecture and tooling mature.