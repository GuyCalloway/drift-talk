import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/core/network/webrtc_client.dart';
import '../../lib/features/voice_chat/data/datasources/mock_voice_chat_datasource.dart';

class MockWebRTCClient extends Mock implements WebRTCClient {}

void main() {
  group('MockVoiceChatDataSource', () {
    late MockVoiceChatDataSource mockDataSource;
    late MockWebRTCClient mockWebRTCClient;

    setUp(() {
      mockWebRTCClient = MockWebRTCClient();
      mockDataSource = MockVoiceChatDataSource(mockWebRTCClient);
    });

    group('Connection Management', () {
      test('should connect successfully', () async {
        await mockDataSource.connect();
        
        final connectionStream = mockDataSource.connectionState;
        expect(await connectionStream.first, WebRTCConnectionState.connected);
      });

      test('should disconnect successfully', () async {
        await mockDataSource.connect();
        await mockDataSource.disconnect();
        
        final connectionStream = mockDataSource.connectionState;
        expect(await connectionStream.first, WebRTCConnectionState.disconnected);
      });
    });

    group('Mock Responses', () {
      setUp(() async {
        await mockDataSource.connect();
      });

      test('should generate museum response for museum context', () async {
        const message = 'What is interesting here?';
        const context = 'Standing outside the British Museum';
        
        final responseStream = await mockDataSource.sendMessage(message, context);
        final responses = await responseStream.toList();
        
        expect(responses.isNotEmpty, true);
        expect(responses.first.transcript, isNotNull);
        expect(responses.first.transcript!.toLowerCase(), contains('museum'));
      });

      test('should generate bridge response for bridge context', () async {
        const message = 'Tell me about this';
        const context = 'Looking at Tower Bridge in London';
        
        final responseStream = await mockDataSource.sendMessage(message, context);
        final responses = await responseStream.toList();
        
        expect(responses.isNotEmpty, true);
        expect(responses.first.transcript, isNotNull);
        expect(responses.first.transcript!.toLowerCase(), contains('bridge'));
      });

      test('should generate history response for history questions', () async {
        const message = 'What is the history of this place?';
        const context = 'Central London street';
        
        final responseStream = await mockDataSource.sendMessage(message, context);
        final responses = await responseStream.toList();
        
        expect(responses.isNotEmpty, true);
        expect(responses.first.transcript, isNotNull);
        
        // Should contain historical information
        final transcript = responses.first.transcript!.toLowerCase();
        expect(
          transcript.contains('history') || 
          transcript.contains('roman') || 
          transcript.contains('medieval') ||
          transcript.contains('fire'),
          true
        );
      });

      test('should generate default response for unknown context', () async {
        const message = 'What about this?';
        const context = 'Some random location';
        
        final responseStream = await mockDataSource.sendMessage(message, context);
        final responses = await responseStream.toList();
        
        expect(responses.isNotEmpty, true);
        expect(responses.first.transcript, isNotNull);
        expect(responses.first.transcript!.isNotEmpty, true);
      });

      test('should stream audio data in chunks', () async {
        const message = 'Test message';
        
        final responseStream = await mockDataSource.sendMessage(message, null);
        final responses = await responseStream.toList();
        
        // Should have multiple chunks
        expect(responses.length, greaterThan(1));
        
        // Each chunk should have audio data
        for (final response in responses) {
          expect(response.audioData.isNotEmpty, true);
          expect(response.format, 'pcm16');
          expect(response.sampleRate, 24000);
          expect(response.bitRate, 16);
        }
        
        // First chunk should have transcript
        expect(responses.first.transcript, isNotNull);
        
        // Other chunks should not have transcript
        for (int i = 1; i < responses.length; i++) {
          expect(responses[i].transcript, isNull);
        }
      });

      test('should handle concurrent requests correctly', () async {
        const message = 'First message';
        
        // Start first request
        final firstStream = mockDataSource.sendMessage(message, null);
        
        // Second request should fail
        expect(
          () async => await mockDataSource.sendMessage('Second message', null),
          throwsException,
        );
        
        // Complete first request
        await firstStream;
      });
    });
  });
}