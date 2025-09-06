import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/network/webrtc_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/audio_response_model.dart';
import 'openai_webrtc_datasource.dart';

/// Mock data source for local testing without OpenAI API calls
/// Provides realistic responses based on context and user input
@LazySingleton(as: OpenAIWebRTCDataSource, env: ['mock', 'test'])
class MockVoiceChatDataSource implements OpenAIWebRTCDataSource {
  final WebRTCClient _webRTCClient;

  StreamController<AudioResponseModel>? _audioStreamController;
  bool _isConnected = false;
  bool _isProcessingResponse = false;
  String? _currentResponseId;

  // Dickens Walking Tour Mock Response Database
  static final Map<String, List<String>> _mockResponses = {
    // Specific London locations from the walking tour
    'monument': [
      'The Monument to the Great Fire of London, often referred to simply as "The Monument," is a striking Doric column located near the northern end of London Bridge. Designed by Sir Christopher Wren and Robert Hooke, it commemorates the devastating Great Fire of London in 1666.',
      'Standing 202 feet tall—the exact distance from the monument to the site of the baker\'s shop on Pudding Lane where the fire began—it serves as both a memorial and a viewing platform, offering sweeping views of the capital.',
      'For Dickens enthusiasts, the Monument marks an apt starting point for exploring the layers of history that shaped his London. In Dickens\'s time, this part of the city was a bustling nexus of trade and river crossings.',
    ],
    'st magnus': [
      'St Magnus the Martyr is a beautiful Baroque church rebuilt by Christopher Wren after the Great Fire. Once located at the northern end of the old London Bridge, it was an important gateway to the City of London for centuries.',
      'The church\'s interior is rich with maritime memorials, reflecting its proximity to the river and the shipping trade. Dickens references St Magnus in "Oliver Twist," evoking the atmosphere of the riverside streets around it.',
      'In earlier centuries, the approach to the bridge here would have been crowded with traders, shopkeepers, and travelers, a scene little changed until the 19th century redevelopment.',
    ],
    'london bridge': [
      'These surviving remnants of John Rennie\'s 19th-century London Bridge are tangible links to the past. The steps once led down to the water\'s edge, providing access to ferries and river traffic before the bridge crossings became the norm.',
      'For Dickens, bridges were both literal and symbolic crossings, often serving as settings for dramatic encounters between his characters. The old bridge was a bustling artery, alive with hawkers and tradesmen.',
      'The arch remains today as a silent witness to the transformations of the Thames waterfront—a place where one can pause and imagine the noise, smells, and activity that once filled this stretch of riverbank.',
    ],
    'southwark cathedral': [
      'Originally the priory church of St Mary Overie, Southwark Cathedral is one of London\'s oldest places of worship, with roots stretching back over 1,000 years. It became a parish church known as St Saviour\'s before finally achieving cathedral status in 1905.',
      'The cathedral has strong literary associations—not just with Dickens, but also with Shakespeare, whose brother Edmund is buried here. Dickens mentioned the church in "The Uncommercial Traveller."',
      'Inside, the blend of Gothic architecture and modern memorials makes it both a sacred space and a living museum of London\'s history.',
    ],
    'borough market': [
      'Borough Market is one of London\'s oldest and most famous food markets, dating back to at least the 12th century. In Dickens\'s era, it was a chaotic and earthy place, with traders hawking produce, meat, and fish from stalls and barrows.',
      'Dickens drew inspiration from such lively street scenes for novels like "The Pickwick Papers" and "Oliver Twist," where markets are depicted as microcosms of city life—full of energy, drama, and characters.',
      'Today, Borough Market has transformed into a gourmet food destination, but its cobbled lanes and railway arches still echo with history, making it an essential stop for both literary pilgrims and food lovers.',
    ],
    'george inn': [
      'The George Inn is the last remaining galleried coaching inn in London, dating back to 1677. Owned by the National Trust, it retains much of its historic charm, with wooden galleries overlooking a cobbled courtyard.',
      'Dickens mentions The George in "Little Dorrit" and was known to drink here himself. Such inns were vital waypoints for travelers and vital centers of community life.',
      'Today, it serves as both a working pub and a living relic of the coaching era, inviting visitors to step back in time.',
    ],
    'marshalsea': [
      'Marshalsea Prison is infamous in Dickensian lore as the place where the author\'s father was imprisoned for debt in 1824. This traumatic family episode had a profound effect on the young Dickens and echoes through his work, most notably in "Little Dorrit."',
      'Although the prison itself is gone, sections of its high brick wall survive in Angel Place, radiating a palpable sense of confinement and hardship.',
      'Standing here, one can feel the shadow of Victorian debtors\' prisons and their devastating impact on families.',
    ],
    'lant street': [
      'Lant Street is where a young Charles Dickens lodged while his father was in Marshalsea Prison. The experience left an indelible mark on him, deepening his empathy for the struggles of the poor.',
      'The street today is a mix of old and new buildings, but its connection to Dickens\'s personal history makes it a site of quiet pilgrimage for fans.',
      'Standing here connects you directly to the formative hardships that shaped one of literature\'s greatest voices.',
    ],
    
    // Thematic responses for Dickens walking tour
    'dickens': [
      'Charles Dickens walked these very streets, observing the bustling life of Victorian London that would inspire his greatest works.',
      'This area shaped Dickens\' understanding of social inequality and human resilience, themes that permeate his novels.',
      'The young Dickens experienced both hardship and wonder in this neighborhood, memories that would fuel his literary imagination for decades.',
    ],
    'victorian': [
      'Victorian London was a city of stark contrasts—grand monuments stood alongside slums, wealth existed steps away from desperate poverty.',
      'The streets here would have been filled with the sounds of horse-drawn carriages, street vendors calling their wares, and the constant hum of urban life.',
      'This was the London that Dickens knew intimately, a city undergoing rapid transformation during the Industrial Revolution.',
    ],
    'prison': [
      'Debtors\' prisons like Marshalsea and King\'s Bench were grim realities of Victorian life, where entire families could be imprisoned for unpaid debts.',
      'Dickens\' personal experience with his father\'s imprisonment gave him unique insight into the cruelty of the debtor system, which he criticized throughout his career.',
      'These institutions have vanished, but their legacy lives on in Dickens\' passionate advocacy for social reform.',
    ],
    'church': [
      'The churches of Southwark served not only spiritual needs but also as community centers, refuges, and landmarks in the maze of London streets.',
      'Many of these sacred spaces appear in Dickens\' novels as places where his characters find solace, sanctuary, or dramatic encounters.',
      'The blend of medieval architecture and Victorian restoration tells the story of London\'s continuous evolution through the centuries.',
    ],
    'literature': [
      'This neighborhood is a living library of Dickens\' work—every street corner and building potentially inspired scenes in his novels.',
      'Walking these paths connects you directly to the creative process of one of English literature\'s greatest authors.',
      'The places where Dickens lived, worked, and wandered continue to inspire readers and writers from around the world.',
    ],
    
    // General fallbacks with Dickens theme
    'default': [
      'You\'re walking in the footsteps of Charles Dickens himself, through streets that inspired some of literature\'s greatest works.',
      'This area of London holds countless stories from Dickens\' life and the Victorian era he so vividly portrayed.',
      'Every corner here has witnessed the social transformations that Dickens chronicled in his novels.',
      'The spirit of Victorian London lives on in these historic streets and buildings.',
      'This neighborhood shaped one of the world\'s most beloved authors and continues to captivate literary pilgrims.',
    ],
  };

  MockVoiceChatDataSource(this._webRTCClient);

  @override
  Stream<WebRTCConnectionState> get connectionState => 
      Stream.value(_isConnected ? WebRTCConnectionState.connected : WebRTCConnectionState.disconnected);

  @override
  Future<void> connect() async {
    AppLogger.info('🎭 Mock: Connecting to simulated voice service...');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate connection time
    _isConnected = true;
    AppLogger.info('✅ Mock: Connected successfully');
  }

  @override
  Future<void> disconnect() async {
    AppLogger.info('🎭 Mock: Disconnecting from simulated voice service...');
    _isConnected = false;
    _isProcessingResponse = false;
    _currentResponseId = null;
    await _audioStreamController?.close();
    _audioStreamController = null;
    AppLogger.info('✅ Mock: Disconnected successfully');
  }

  @override
  Future<void> wrapUpAndContinue() async {
    AppLogger.info('🎭 Mock: Wrap-up requested - simulating wrap-up behavior');
    // Mock implementation - just log the request
  }

  @override
  Future<Stream<AudioResponseModel>> sendMessage(String message, String? context) async {
    if (!_isConnected) {
      throw Exception('Mock service not connected');
    }

    if (_isProcessingResponse) {
      AppLogger.info('🎭 Mock: Already processing, ignoring duplicate request');
      throw Exception('Already processing request');
    }

    _isProcessingResponse = true;
    _audioStreamController = StreamController<AudioResponseModel>();
    _currentResponseId = 'mock_${DateTime.now().millisecondsSinceEpoch}';

    AppLogger.info('🎭 Mock: Processing message: "$message" with context: "$context"');

    // Simulate processing delay
    Timer(const Duration(milliseconds: 200), () async {
      try {
        final response = _generateMockResponse(message, context);
        final audioData = _generateMockAudio(response);
        
        AppLogger.info('🎭 Mock: Generated response: "$response"');
        
        // Simulate streaming audio chunks
        await _streamAudioResponse(audioData, response);
      } catch (e) {
        AppLogger.error('Mock error generating response', e);
        _audioStreamController?.addError(e);
      } finally {
        _isProcessingResponse = false;
        await Future.delayed(const Duration(milliseconds: 100));
        _audioStreamController?.close();
        _audioStreamController = null;
      }
    });

    return _audioStreamController!.stream;
  }

  /// Generate a contextual response based on user input and context
  String _generateMockResponse(String message, String? context) {
    final random = Random();
    
    // Combine message and context for analysis
    final fullInput = '${context ?? ''} $message'.toLowerCase();
    
    // Try to match keywords to response categories
    for (final category in _mockResponses.keys) {
      if (category != 'default' && fullInput.contains(category)) {
        final responses = _mockResponses[category]!;
        return responses[random.nextInt(responses.length)];
      }
    }
    
    // Check for specific location mentions with better matching
    final locationKeywords = ['at ', 'near ', 'outside ', 'inside ', 'by ', 'next to ', 'tell me about ', 'what about '];
    for (final keyword in locationKeywords) {
      if (fullInput.contains(keyword)) {
        // Extract location and try to match
        final keywordIndex = fullInput.indexOf(keyword);
        final afterKeyword = fullInput.substring(keywordIndex + keyword.length);
        
        // Try to match location names more flexibly
        for (final category in _mockResponses.keys) {
          if (category != 'default' && (afterKeyword.contains(category) || 
              afterKeyword.replaceAll(' ', '').contains(category.replaceAll(' ', '')))) {
            final responses = _mockResponses[category]!;
            return responses[random.nextInt(responses.length)];
          }
        }
      }
    }
    
    // Enhanced question type analysis with Dickens context
    if (fullInput.contains('what') || fullInput.contains('tell me') || fullInput.contains('explain')) {
      if (fullInput.contains('dickens')) return _mockResponses['dickens']![random.nextInt(_mockResponses['dickens']!.length)];
      if (fullInput.contains('victorian')) return _mockResponses['victorian']![random.nextInt(_mockResponses['victorian']!.length)];
      if (fullInput.contains('prison')) return _mockResponses['prison']![random.nextInt(_mockResponses['prison']!.length)];
      if (fullInput.contains('church')) return _mockResponses['church']![random.nextInt(_mockResponses['church']!.length)];
      if (fullInput.contains('literature') || fullInput.contains('literary')) return _mockResponses['literature']![random.nextInt(_mockResponses['literature']!.length)];
    }
    
    // Context-aware responses based on walking tour locations
    if (context != null && context.isNotEmpty) {
      final contextLower = context.toLowerCase();
      
      // Try to match context against location names
      for (final category in _mockResponses.keys) {
        if (category != 'default' && contextLower.contains(category)) {
          final responses = _mockResponses[category]!;
          return responses[random.nextInt(responses.length)];
        }
      }
      
      // Parse coordinates if provided in context (lat,lng format)
      final coordPattern = RegExp(r'lat[:\s]*(-?\d+\.?\d*)[,\s]+lng[:\s]*(-?\d+\.?\d*)');
      final match = coordPattern.firstMatch(contextLower);
      if (match != null) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lng = double.tryParse(match.group(2) ?? '');
        
        // Match coordinates to specific locations from the tour
        if (lat != null && lng != null) {
          if (_isNearLocation(lat, lng, 51.5102, -0.0857)) return _mockResponses['monument']![random.nextInt(_mockResponses['monument']!.length)];
          if (_isNearLocation(lat, lng, 51.5065, -0.0901)) return _mockResponses['southwark cathedral']![random.nextInt(_mockResponses['southwark cathedral']!.length)];
          if (_isNearLocation(lat, lng, 51.5055, -0.091)) return _mockResponses['borough market']![random.nextInt(_mockResponses['borough market']!.length)];
          if (_isNearLocation(lat, lng, 51.5027, -0.0914)) return _mockResponses['george inn']![random.nextInt(_mockResponses['george inn']!.length)];
          if (_isNearLocation(lat, lng, 51.5013, -0.093)) return _mockResponses['marshalsea']![random.nextInt(_mockResponses['marshalsea']!.length)];
          if (_isNearLocation(lat, lng, 51.501, -0.0948)) return _mockResponses['lant street']![random.nextInt(_mockResponses['lant street']!.length)];
        }
      }
    }
    
    // Fallback to default responses
    final defaultResponses = _mockResponses['default']!;
    return defaultResponses[random.nextInt(defaultResponses.length)];
  }

  /// Generate mock audio data (silent audio for now)
  Uint8List _generateMockAudio(String text) {
    // Generate ~2 seconds of silent PCM16 audio at 24kHz
    const sampleRate = 24000;
    const duration = 2; // seconds
    const bytesPerSample = 2; // 16-bit = 2 bytes
    
    final totalSamples = sampleRate * duration;
    final audioData = Uint8List(totalSamples * bytesPerSample);
    
    // Optional: Generate a subtle tone instead of silence
    // This makes it clear that audio is "playing"
    final random = Random();
    for (int i = 0; i < totalSamples; i++) {
      // Generate very quiet white noise to simulate speech
      final sample = (random.nextDouble() - 0.5) * 0.1 * 32767;
      final intSample = sample.toInt().clamp(-32767, 32767);
      
      // Write as little-endian 16-bit PCM
      audioData[i * 2] = intSample & 0xFF;
      audioData[i * 2 + 1] = (intSample >> 8) & 0xFF;
    }
    
    return audioData;
  }

  /// Check if given coordinates are near a specific location (within ~100 meters)
  bool _isNearLocation(double lat1, double lng1, double lat2, double lng2) {
    const double threshold = 0.001; // Roughly 100 meters
    final double latDiff = (lat1 - lat2).abs();
    final double lngDiff = (lng1 - lng2).abs();
    return latDiff <= threshold && lngDiff <= threshold;
  }

  /// Stream audio response in chunks to simulate real-time audio
  Future<void> _streamAudioResponse(Uint8List audioData, String text) async {
    const chunkSize = 2048; // bytes per chunk
    const chunkDelayMs = 100; // ms between chunks
    
    for (int i = 0; i < audioData.length; i += chunkSize) {
      if (_audioStreamController?.isClosed == true) break;
      
      final end = (i + chunkSize).clamp(0, audioData.length);
      final chunk = audioData.sublist(i, end);
      
      final audioResponse = AudioResponseModel(
        id: _currentResponseId!,
        audioData: chunk,
        format: 'pcm16',
        sampleRate: 24000,
        bitRate: 16,
        duration: Duration(milliseconds: chunkDelayMs),
        transcript: i == 0 ? text : null, // Include transcript in first chunk
        createdAt: DateTime.now(),
      );
      
      _audioStreamController?.add(audioResponse);
      AppLogger.debug('🎭 Mock: Streamed ${chunk.length} bytes');
      
      // Delay between chunks to simulate real-time streaming
      await Future.delayed(Duration(milliseconds: chunkDelayMs));
    }
    
    AppLogger.info('🎭 Mock: Finished streaming audio response');
  }
}