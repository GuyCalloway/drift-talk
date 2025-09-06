# Voice AI Assistant Architecture

## User Experience Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                             USER INTERACTION FLOW                               │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────────┐    ┌──────────────────┐    ┌──────────────┐
│    User     │    │  Context Input  │    │  Message Input   │    │ Voice Output │
│  Experience │────│  (Location/     │────│  (Questions &    │────│ (Minimal     │
│             │    │   Background)   │    │   Requests)      │    │  Responses)  │
└─────────────┘    └─────────────────┘    └──────────────────┘    └──────────────┘
       │                      │                     │                     │
       │                      │                     │                     │
       ▼                      ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            APPLICATION LAYERS                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────────────────┐  │
│  │  Voice Chat     │  │  Message Input  │  │         UI State                 │  │
│  │  Page           │  │  Widget         │  │    ┌──────────────────────────┐   │  │
│  │                 │  │                 │  │    │    Connection Status    │   │  │
│  │  • Display      │  │  • Text Input   │  │    │    Loading States       │   │  │
│  │  • Controls     │  │  • Context      │  │    │    Message History      │   │  │
│  │  • Status       │  │  • Send Actions │  │    │    Error Handling       │   │  │
│  └─────────────────┘  └─────────────────┘  └──────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────────────────────┘
                           │ User Actions (Text + Context)
                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          BUSINESS LOGIC LAYER                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                         Voice Chat BLoC                                    │  │
│  │                                                                             │  │
│  │  Message Flow:                           Connection Flow:                   │  │
│  │  ┌─────────────────┐                    ┌─────────────────┐                │  │
│  │  │ 1. Text Input   │ ──────────────────▶│ 1. Connect      │                │  │
│  │  │ 2. Add Context  │                    │ 2. Configure    │                │  │
│  │  │ 3. Send Request │                    │ 3. Authenticate │                │  │
│  │  │ 4. Handle Audio │                    │ 4. Listen       │                │  │
│  │  └─────────────────┘                    └─────────────────┘                │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────────────────────┘
                           │ Business Rules Applied
                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            DOMAIN LAYER                                         │
│  ┌─────────────────┐              ┌────────────────────────────────────────────┐  │
│  │   Use Cases     │              │              Entities                     │  │
│  │                 │              │                                            │  │
│  │  Send Message   │              │  Voice Message:                           │  │
│  │  ┌─────────────┐│              │  • Content (text + context)              │  │
│  │  │• Validation ││              │  • Status (sending/sent/error)           │  │
│  │  │• Context    ││              │  • Type (user/assistant)                 │  │
│  │  │• Routing    ││              │  • Timestamp                             │  │
│  │  └─────────────┘│              │                                            │  │
│  │                 │              │  Audio Response:                          │  │
│  │  Connect/       │              │  • Audio Data (PCM stream)               │  │
│  │  Disconnect     │              │  • Response ID                           │  │
│  │                 │              │  • Metadata                              │  │
│  └─────────────────┘              └────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────────────────────┘
                           │ Domain Rules Enforced
                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             DATA LAYER                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                        Repository Pattern                                   │  │
│  │  ┌─────────────────┐                    ┌─────────────────────────────────┐  │  │
│  │  │ Voice Chat      │                    │        Data Sources             │  │  │
│  │  │ Repository      │ ─────────────────▶ │                                 │  │  │
│  │  │                 │                    │  OpenAI WebRTC:                 │  │  │
│  │  │• Abstract       │                    │  • Real-time Connection         │  │  │
│  │  │  Interface      │                    │  • Message Exchange             │  │  │
│  │  │• Data Flow      │                    │  • Audio Streaming              │  │  │
│  │  │• Error          │                    │  • Response Processing          │  │  │
│  │  │  Handling       │                    │                                 │  │  │
│  │  └─────────────────┘                    │  Local Storage:                 │  │  │
│  │                                         │  • Message History              │  │  │
│  │                                         │  • Connection State             │  │  │
│  │                                         │  • User Preferences            │  │  │
│  │                                         └─────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## Core User Interactions

### Input Sources
```
┌─────────────────┐
│  User Inputs    │
├─────────────────┤
│ 1. Text Query   │ ──┐
│ 2. Context Info │   │
│ 3. Location     │   │
│ 4. Background   │   │
└─────────────────┘   │
                      │
                      ▼
            ┌─────────────────┐      ┌─────────────────┐
            │   Processing    │ ───▶ │  AI Response   │
            │                 │      │                 │
            │ • Context Merge │      │ • Single Point │
            │ • Query Parse   │      │ • Brief Audio  │
            │ • Intent Extract│      │ • Location Dir │
            └─────────────────┘      └─────────────────┘
```

### Response Characteristics
- **Ultra-Minimal**: Maximum 1-2 sentences
- **Context-Driven**: Only discusses information from provided context
- **Single Focus**: One interesting talking point per response
- **Location-Aware**: Provides directional guidance when location context available
- **Silent Waiting**: No follow-up questions, waits for next explicit input

### Connection States
```
Disconnected ──connect──▶ Connecting ──success──▶ Connected ──process──▶ Responding
     ▲                       │                        │                      │
     │                       │                        │                      │
     └─────disconnect─────────┘                        └──────complete───────┘
                          error                                        │
                             │                                         │
                             ▼                                         ▼
                          Failed ──retry──▶ Connecting              Ready
```

## Key Design Principles

1. **User-Centric Flow**: All architecture decisions prioritize user experience over technical complexity
2. **Context-First**: The application is designed around contextual information being the primary driver
3. **Minimal Interaction**: Reduces cognitive load with brief, focused responses
4. **Real-time Efficiency**: Optimized for low-latency audio processing and minimal API costs
5. **State Isolation**: Clear separation between connection state, message state, and UI state
6. **Error Resilience**: Graceful handling of network, API, and audio processing failures

## Data Transformation Pipeline

```
Raw Input ──▶ Context Merge ──▶ Intent Analysis ──▶ API Request ──▶ Response Processing ──▶ Audio Output
    │              │                    │               │                   │                    │
    │              │                    │               │                   │                    │
Text +         Combined            Extracted        Optimized         Minimal              Spoken
Context        Message             Intent           Payload           Response             Audio
```

This architecture emphasizes the journey of information through the system, focusing on how user intent transforms into meaningful, contextual audio responses.