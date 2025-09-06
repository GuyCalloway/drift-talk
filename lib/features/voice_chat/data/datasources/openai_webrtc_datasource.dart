import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import '../../../../core/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/network/webrtc_client.dart';
import '../../../../core/network/connection_manager.dart';
import '../../../../core/services/smart_conversation_manager.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/audio_response_model.dart';

class QueuedMessage {
  final String message;
  final String? context;
  final Completer<Stream<AudioResponseModel>> completer;
  final DateTime timestamp;

  QueuedMessage({
    required this.message,
    this.context,
    required this.completer,
    required this.timestamp,
  });
}

abstract class OpenAIWebRTCDataSource {
  Future<void> connect();
  Future<void> disconnect();
  Future<Stream<AudioResponseModel>> sendMessage(String message, String? context);
  Future<void> wrapUpAndContinue();
  Stream<WebRTCConnectionState> get connectionState;
}

@LazySingleton(as: OpenAIWebRTCDataSource, env: ['production'])
class OpenAIWebRTCDataSourceImpl implements OpenAIWebRTCDataSource {
  final WebRTCClient _webRTCClient;
  final SecureStorage _secureStorage;
  final ConnectionManager _connectionManager;
  final SmartConversationManager _conversationManager;

  String? _apiKey;
  StreamController<AudioResponseModel>? _audioStreamController;
  bool _isProcessingResponse = false;
  String? _currentResponseId;
  
  // Connection-level mutex to prevent concurrent responses
  bool _connectionLocked = false;
  QueuedMessage? _queuedMessage; // Only one queued message at a time
  Timer? _connectionLockTimeout;
  bool _processingQueue = false;
  
  // COST OPTIMIZATION: Track if session is configured to avoid redundant calls
  bool _sessionConfigured = false;

  OpenAIWebRTCDataSourceImpl(
    this._webRTCClient,
    this._secureStorage,
    this._connectionManager,
    this._conversationManager,
  );

  @override
  Stream<WebRTCConnectionState> get connectionState =>
      _webRTCClient.connectionStream;

  @override
  Future<void> connect() async {
    try {
      _apiKey = dotenv.env['OPENAI_API_KEY'];
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw const AuthenticationException('OpenAI API key not found');
      }

      await _webRTCClient.connect(_apiKey!);

      _setupMessageHandling();
      
      // COST OPTIMIZATION: Only send session config once per connection
      if (!_sessionConfigured) {
        await _sendSessionConfiguration();
        _sessionConfigured = true;
      }
      
      AppLogger.info('Connected to OpenAI Realtime API via WebRTC');
    } catch (e) {
      AppLogger.error('Failed to connect to OpenAI WebRTC', e);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _webRTCClient.disconnect();
      await _audioStreamController?.close();
      _audioStreamController = null;
      _sessionConfigured = false; // Reset for next connection
      AppLogger.info('Disconnected from OpenAI Realtime API');
    } catch (e) {
      AppLogger.error('Failed to disconnect from OpenAI WebRTC', e);
      rethrow;
    }
  }

  @override
  Future<Stream<AudioResponseModel>> sendMessage(
    String message,
    String? context,
  ) async {
    if (!_webRTCClient.isConnected) {
      throw const NetworkException('WebRTC not connected');
    }

    // If connection is busy, queue the message (replacing any existing queued message)
    if (_connectionLocked || _isProcessingResponse) {
      AppLogger.info('🔒 Connection busy - queuing message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}');
      return _queueMessage(message, context);
    }

    return _processMessage(message, context);
  }

  Future<Stream<AudioResponseModel>> _queueMessage(String message, String? context) async {
    final completer = Completer<Stream<AudioResponseModel>>();
    
    // If there's already a queued message, complete it with an error and replace
    if (_queuedMessage != null) {
      AppLogger.info('🔄 Replacing existing queued message with new one');
      _queuedMessage!.completer.completeError(
        const NetworkException('Message replaced by newer one'),
      );
    }
    
    _queuedMessage = QueuedMessage(
      message: message,
      context: context,
      completer: completer,
      timestamp: DateTime.now(),
    );
    
    AppLogger.info('📝 Message queued (replacing previous if any)');
    
    return completer.future;
  }

  Future<Stream<AudioResponseModel>> _processMessage(String message, String? context) async {
    // Lock the connection immediately
    _connectionLocked = true;
    _isProcessingResponse = true;
    _audioStreamController = StreamController<AudioResponseModel>();
    
    // Auto-unlock connection after 15 seconds to prevent permanent lock
    _connectionLockTimeout = Timer(const Duration(seconds: 15), () {
      if (_connectionLocked) {
        AppLogger.error('🚨 Connection lock timeout - auto-unlocking after 15 seconds');
        _connectionLocked = false;
        _isProcessingResponse = false;
        _currentResponseId = null;
        _processNextMessage();
      }
    });

    // Add unique event ID
    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
    final itemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    
    final messagePayload = {
      'event_id': eventId,
      'type': 'conversation.item.create',
      'item': {
        'id': itemId,
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': context != null ? '$context\n\n$message' : message,
          }
        ],
      },
    };

    try {
      // COST OPTIMIZATION: Send message and response request together
      _webRTCClient.sendMessage(messagePayload);

      // Small delay to ensure message is processed before response request
      await Future.delayed(const Duration(milliseconds: 50));

      final responseEventId = 'event_${DateTime.now().millisecondsSinceEpoch + 1}';
      _currentResponseId = responseEventId;
      
      final responsePayload = {
        'event_id': responseEventId,
        'type': 'response.create',
      };

      _webRTCClient.sendMessage(responsePayload);

      return _audioStreamController!.stream;
    } catch (e) {
      // Ensure connection is unlocked on error
      _connectionLocked = false;
      _isProcessingResponse = false;
      _currentResponseId = null;
      _connectionLockTimeout?.cancel();
      _connectionLockTimeout = null;
      AppLogger.error('Failed to send message - connection unlocked', e);
      rethrow;
    }
  }

  void _setupMessageHandling() {
    _webRTCClient.messageStream.listen((message) {
      _handleWebRTCMessage(message);
    });
  }

  void _handleWebRTCMessage(Map<String, dynamic> message) {
    final messageType = message['type'] as String?;
    final responseId = message['response_id'] as String?;
    
    // Debug all response-related messages
    if (responseId != null) {
      AppLogger.debug('📨 Handling message: $messageType for response: $responseId (current: $_currentResponseId)');
    }

    switch (messageType) {
      case 'session.created':
        _handleSessionCreated(message);
        break;
      case 'session.updated':
        _handleSessionUpdated(message);
        break;
      case 'conversation.item.created':
        _handleConversationItemCreated(message);
        break;
      case 'response.created':
        _handleResponseCreated(message);
        break;
      case 'response.audio.delta':
        _handleResponseAudioDelta(message);
        break;
      case 'response.audio.done':
        _handleAudioDone(message);
        break;
      case 'response.done':
        _handleResponseDone(message);
        break;
      case 'response.cancelled':
        _handleResponseCancelled(message);
        break;
      case 'output_audio_buffer.started':
        _handleOutputAudioBufferStarted(message);
        break;
      case 'output_audio_buffer.stopped':
        _handleOutputAudioBufferStopped(message);
        break;
      case 'output_audio_buffer.cleared':
        _handleOutputAudioBufferCleared(message);
        break;
      case 'response.output_audio_transcript.delta':
        _handleOutputAudioTranscriptDelta(message);
        break;
      case 'error':
        _handleError(message);
        break;
      default:
        AppLogger.debug('Unhandled message type: $messageType - $message');
    }
  }

  void _handleSessionCreated(Map<String, dynamic> message) {
    AppLogger.info('Session created successfully');
    final session = message['session'];
    if (session != null) {
      AppLogger.debug('Session details: $session');
    }
  }

  void _handleSessionUpdated(Map<String, dynamic> message) {
    AppLogger.info('Session updated successfully');
    final session = message['session'];
    if (session != null) {
      AppLogger.debug('Updated session details: $session');
    }
  }

  void _handleConversationItemCreated(Map<String, dynamic> message) {
    AppLogger.info('Conversation item created');
    final item = message['item'];
    if (item != null) {
      AppLogger.debug('Created item: $item');
    }
  }

  void _handleResponseCreated(Map<String, dynamic> message) {
    AppLogger.info('Response created');
    final response = message['response'];
    if (response != null) {
      AppLogger.debug('Response details: $response');
    }
  }


  void _handleResponseAudioDelta(Map<String, dynamic> message) {
    try {
      final delta = message['delta'] as String?;
      final responseId = message['response_id'] as String?;
      final itemId = message['item_id'] as String?;
      
      // Only process audio for the current response
      if (responseId != _currentResponseId) {
        AppLogger.debug('Ignoring audio delta for old response: $responseId');
        return;
      }
      
      if (delta != null && _audioStreamController != null) {
        final audioBytes = base64Decode(delta);
        final audioResponse = AudioResponseModel(
          id: responseId ?? itemId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          audioData: audioBytes,
          format: 'pcm16',
          sampleRate: 24000,
          bitRate: 16,
          duration: const Duration(milliseconds: 100),
          transcript: null,
          createdAt: DateTime.now(),
        );
        
        _audioStreamController!.add(audioResponse);
        AppLogger.info('🎵 Response audio delta processed: ${audioBytes.length} bytes');
      }
    } catch (e) {
      AppLogger.error('Failed to process response audio delta', e);
    }
  }

  void _handleAudioDone(Map<String, dynamic> message) {
    AppLogger.info('Audio response completed');
  }

  void _handleResponseDone(Map<String, dynamic> message) {
    final responseId = message['response_id'] as String?;
    
    // Only close if this is the current response
    if (responseId == null || responseId == _currentResponseId) {
      _audioStreamController?.close();
      _audioStreamController = null;
      _isProcessingResponse = false;
      _currentResponseId = null;
      _connectionLocked = false;  // UNLOCK CONNECTION
      _connectionLockTimeout?.cancel();
      _connectionLockTimeout = null;
      AppLogger.info('✅ Response completed: $responseId - Connection unlocked');
      
      // Process next message in queue if any
      _processNextMessage();
    } else {
      AppLogger.debug('Ignoring response done for old response: $responseId');
    }
  }

  void _handleResponseCancelled(Map<String, dynamic> message) {
    final responseId = message['response_id'] as String?;
    AppLogger.info('🚫 Response cancelled: $responseId');
    
    // Clean up if this was the current response
    if (responseId == _currentResponseId) {
      _audioStreamController?.close();
      _audioStreamController = null;
      _isProcessingResponse = false;
      _currentResponseId = null;
      _connectionLocked = false;  // UNLOCK CONNECTION
      _connectionLockTimeout?.cancel();
      _connectionLockTimeout = null;
      AppLogger.info('🔓 Connection unlocked after response cancellation');
      
      // Process next message in queue if any
      _processNextMessage();
    }
  }

  void _handleError(Map<String, dynamic> message) {
    final error = message['error'];
    final errorMessage = error?['message'] ?? 'Unknown error';
    AppLogger.error('OpenAI API error: $errorMessage');
    
    _audioStreamController?.addError(
      ServerException('OpenAI API error: $errorMessage'),
    );
  }

  Future<void> _sendSessionConfiguration() async {
    AppLogger.info('🎛️ Sending session configuration for audio output...');
    final sessionConfig = {
      'event_id': 'session_config_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'session.update',
      'session': {
        'type': 'realtime',
        'model': 'gpt-realtime',
        'output_modalities': ['audio', 'text'],
        'audio': {
          'input': {
            'format': 'pcm16',
            'turn_detection': null
          },
          'output': {
            'format': 'pcm16',
            'voice': 'alloy',
            'speed': 0.7
          }
        },
        'instructions': 'You are a local sightseeing guide. Give a very brief description of ONE specific landmark or historical feature the traveler should look out for at this location. End with "Look for..." or "Notice..." then STOP. Wait for the user to respond or ask for more. Keep responses under 15 words and focus only on what they can actually see.',
        'max_response_output_tokens': 20, // Slightly increased for landmark descriptions
        'input_audio_transcription': {
          'model': 'whisper-1',
          'enabled': false
        },
      },
    };

    _webRTCClient.sendMessage(sessionConfig);
  }

  void _handleOutputAudioBufferStarted(Map<String, dynamic> message) {
    final responseId = message['response_id'] as String?;
    
    // Only allow audio playback for the current response
    if (responseId != _currentResponseId) {
      AppLogger.info('🛑 Blocking audio playback for old response: $responseId (current: $_currentResponseId)');
      return;
    }
    
    AppLogger.info('🔊 Audio playback started for response: $responseId');
  }

  void _handleOutputAudioBufferStopped(Map<String, dynamic> message) {
    final responseId = message['response_id'] as String?;
    AppLogger.info('Audio playback stopped for response: $responseId');
  }

  void _handleOutputAudioBufferCleared(Map<String, dynamic> message) {
    final responseId = message['response_id'] as String?;
    AppLogger.info('Audio buffer cleared for response: $responseId');
  }

  void _handleOutputAudioTranscriptDelta(Map<String, dynamic> message) {
    final delta = message['delta'] as String?;
    final responseId = message['response_id'] as String?;
    
    // Only process transcript for the current response
    if (responseId != _currentResponseId) {
      return; // Silently ignore old responses
    }
    
    if (delta != null) {
      AppLogger.debug('🎙️ Transcript delta: "$delta"');
    }
  }

  Future<void> _processNextMessage() async {
    if (_processingQueue || _queuedMessage == null || _connectionLocked) {
      return;
    }
    
    _processingQueue = true;
    final queuedMessage = _queuedMessage!;
    _queuedMessage = null; // Clear the queue
    AppLogger.info('📤 Processing queued message');
    
    try {
      final stream = await _processMessage(queuedMessage.message, queuedMessage.context);
      queuedMessage.completer.complete(stream);
    } catch (e) {
      queuedMessage.completer.completeError(e);
    } finally {
      _processingQueue = false;
    }
  }

  Future<void> _cancelCurrentResponse() async {
    if (_currentResponseId != null) {
      AppLogger.info('🛑 Cancelling current response: $_currentResponseId');
      
      // Send single response cancel event
      final cancelEvent = {
        'event_id': 'cancel_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'response.cancel',
      };
      
      _webRTCClient.sendMessage(cancelEvent);
    }
    
    // Clean up current state immediately AND unlock connection
    _audioStreamController?.close();
    _audioStreamController = null;
    _isProcessingResponse = false;
    _currentResponseId = null;
    _connectionLocked = false;  // UNLOCK CONNECTION
    _connectionLockTimeout?.cancel();
    _connectionLockTimeout = null;
    AppLogger.info('🔓 Response cancelled');
  }

  Future<void> wrapUpAndContinue() async {
    if (_currentResponseId != null) {
      AppLogger.info('🔄 Wrapping up current response and preparing for new fact');
      
      // Send a wrap-up instruction to current response
      final wrapUpEvent = {
        'event_id': 'wrapup_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'conversation.item.create',
        'item': {
          'id': 'wrapup_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'message',
          'role': 'user',
          'content': [
            {
              'type': 'input_text',
              'text': 'Please wrap up briefly and stop.',
            }
          ],
        },
      };
      
      _webRTCClient.sendMessage(wrapUpEvent);
    }
  }
  
  void _scheduleAutoDisconnect() {
    // Schedule disconnect after response completes to save API costs
    _connectionManager.scheduleDisconnect();
  }
}