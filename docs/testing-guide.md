# Local Testing Guide - Mock Data Setup

This guide shows you how to test the Voice AI Assistant locally without making OpenAI API calls or incurring costs.

## Quick Start - Mock Mode

### 1. Setup Mock Environment
```bash
# Copy the mock environment configuration
cp .env.mock .env

# Or manually create .env with:
echo "USE_MOCK_DATA=true" > .env
```

### 2. Run the Application
```bash
flutter run -d chrome
```

### 3. Verify Mock Mode
You should see this output in your console:
```
🔧 App Configuration:
   Environment: development
   Use Mock Data: true
   Enable Logging: true
   Log Level: debug
🎭 Running in MOCK MODE - No OpenAI API calls will be made
```

## Mock Data Features

### 🎭 **Realistic Responses**
The mock system provides contextual responses based on:
- **Location keywords**: museum, bridge, park, station, restaurant, library
- **Topic keywords**: history, architecture, food, technology, art
- **Question patterns**: "what", "tell me", location-based queries

### 🔊 **Simulated Audio**
- Generates PCM16 audio data (subtle white noise simulating speech)
- Streams in real-time chunks like the actual API
- Configurable duration (default: 2 seconds)

### ⚡ **Fast Development**
- No API key required
- No network dependency
- Instant responses (configurable delay)
- No usage costs

## Testing Scenarios

### Example Test Cases

#### Location-Based Responses
```
Context: "Standing outside the British Museum"
User: "What's interesting here?"
Mock Response: "This museum houses over 8 million artifacts."
```

#### Historical Queries
```
Context: "Old London street"
User: "What's the history of this place?"
Mock Response: "Roman ruins lie 3 meters beneath the current street level."
```

#### Architecture Questions
```
Context: "Victorian building"  
User: "Tell me about the architecture"
Mock Response: "The building uses Portland stone from Dorset quarries."
```

#### Fallback Responses
```
Context: "Random location"
User: "What about this?"
Mock Response: "Interesting details are all around you."
```

## Environment Configurations

### Mock Mode (Local Testing)
```env
# .env.mock
USE_MOCK_DATA=true
ENVIRONMENT=development
ENABLE_LOGGING=true
LOG_LEVEL=debug
MOCK_RESPONSE_DELAY=300
MOCK_AUDIO_DURATION=2
```

### Development Mode (Live API)
```env  
# .env
USE_MOCK_DATA=false
ENVIRONMENT=development
ENABLE_LOGGING=true
LOG_LEVEL=debug
OPENAI_API_KEY=your_api_key_here
```

### Production Mode
```env
# .env.production  
USE_MOCK_DATA=false
ENVIRONMENT=production
ENABLE_LOGGING=false
LOG_LEVEL=info
OPENAI_API_KEY=your_production_api_key
```

## Running Tests

### Unit Tests
```bash
# Test mock data source specifically
flutter test test/data/mock_voice_chat_test.dart

# Run all tests
flutter test
```

### Integration Testing
```bash
# Test with mock data
cp .env.mock .env
flutter test integration_test/

# Test with live API (requires API key)
cp .env.production .env
flutter test integration_test/
```

## Mock Response Database

The mock system includes responses for these categories:

### 🏛️ **Locations**
- `museum`: 3 responses about artifacts, exhibits, construction
- `bridge`: 3 responses about opening, engineering, materials
- `park`: 3 responses about size, trees, water features
- `station`: 3 responses about passengers, architecture, platforms
- `restaurant`: 3 responses about history, cuisine, awards
- `library`: 3 responses about collections, architecture, famous users

### 🎨 **Topics**  
- `history`: 3 responses about fires, ruins, guilds
- `architecture`: 3 responses about materials, styles, renovations
- `food`: 3 responses about ingredients, recipes, origins
- `technology`: 3 responses about systems, innovations, improvements
- `art`: 3 responses about techniques, symbols, analysis

### 🔄 **Fallbacks**
- `default`: 5 generic responses for unmatched queries

## Customizing Mock Data

### Adding New Responses
Edit `lib/features/voice_chat/data/datasources/mock_voice_chat_datasource.dart`:

```dart
static final Map<String, List<String>> _mockResponses = {
  'your_category': [
    'First interesting fact about your topic.',
    'Second fascinating detail.',
    'Third compelling insight.',
  ],
  // ... existing responses
};
```

### Adjusting Response Logic
Modify the `_generateMockResponse()` method to add:
- New keyword matching
- Custom response patterns
- Context-specific logic

### Configuring Audio
Adjust audio generation in `_generateMockAudio()`:
- Change duration
- Add actual audio samples
- Modify audio format

## Debugging Mock Mode

### Enable Verbose Logging
```env
LOG_LEVEL=debug
ENABLE_LOGGING=true
```

### Console Output
```
🎭 Mock: Connecting to simulated voice service...
✅ Mock: Connected successfully
🎭 Mock: Processing message: "What's here?" with context: "British Museum"
🎭 Mock: Generated response: "This museum houses over 8 million artifacts."
🎭 Mock: Streamed 2048 bytes
🎭 Mock: Finished streaming audio response
```

### Common Issues
| Issue | Solution |
|-------|----------|
| Still making API calls | Verify `USE_MOCK_DATA=true` in .env |
| No responses | Check console for mock response generation logs |
| Audio not playing | Ensure browser permissions for audio playback |
| Tests failing | Run `flutter packages pub run build_runner build` |

## Performance Comparison

| Mode | Response Time | Network | Cost | Audio Quality |
|------|---------------|---------|------|---------------|
| Mock | ~300ms | None | $0 | Simulated |  
| Live API | ~100ms | Required | ~$0.01 | High |

## Development Workflow

### 1. Feature Development (Mock)
```bash
cp .env.mock .env
flutter run -d chrome
# Develop and test UI/UX without API costs
```

### 2. Integration Testing (Live)  
```bash
cp .env .env
# Add your OPENAI_API_KEY
flutter run -d chrome
# Test actual API integration
```

### 3. Production Deployment
```bash
cp .env.production .env
flutter build web --release
# Deploy with production configuration
```

## Best Practices

1. **Always start with mock mode** for UI/UX development
2. **Test edge cases** with mock data first
3. **Use live API sparingly** to minimize costs during development
4. **Verify both modes** before production deployment
5. **Keep mock responses updated** to match live API capabilities

## Extending Mock Data

To add more realistic mock data:

1. **Record actual responses** from live API during testing
2. **Extract key phrases** and interesting facts
3. **Organize by context categories**
4. **Add keyword matching logic**
5. **Test response quality** with various inputs

This mock system allows you to develop and test the complete application without any external dependencies or costs!