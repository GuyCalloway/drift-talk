import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_bloc.dart';
import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_event.dart';
import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_state.dart';
import 'package:voice_ai_app/features/voice_chat/domain/usecases/send_message_usecase.dart';
import 'package:voice_ai_app/features/voice_chat/domain/repositories/voice_chat_repository.dart';
import 'package:voice_ai_app/features/voice_chat/domain/entities/voice_message.dart';
import 'package:voice_ai_app/features/voice_chat/domain/entities/audio_response.dart';
import 'package:voice_ai_app/core/errors/failures.dart';
import 'package:voice_ai_app/core/services/conversation_summarizer.dart';

import 'voice_chat_bloc_test.mocks.dart';

@GenerateMocks([SendMessageUseCase, VoiceChatRepository, ConversationSummarizer])
void main() {
  group('VoiceChatBloc', () {
    late VoiceChatBloc voiceChatBloc;
    late MockSendMessageUseCase mockSendMessageUseCase;
    late MockVoiceChatRepository mockRepository;
    late MockConversationSummarizer mockConversationSummarizer;

    setUp(() {
      mockSendMessageUseCase = MockSendMessageUseCase();
      mockRepository = MockVoiceChatRepository();
      mockConversationSummarizer = MockConversationSummarizer();
      
      // Set up default mock behaviors
      when(mockConversationSummarizer.buildContextWithHistory(any, any, any))
          .thenReturn('Enhanced context with history');
      when(mockRepository.connectionStatus)
          .thenAnswer((_) => Stream.value(ConnectionStatus.connected));
      
      voiceChatBloc = VoiceChatBloc(
        mockSendMessageUseCase,
        mockRepository,
        mockConversationSummarizer,
      );
    });

    tearDown(() {
      voiceChatBloc.close();
    });

    test('initial state is VoiceChatInitial', () {
      expect(voiceChatBloc.state, equals(const VoiceChatInitial()));
    });

    group('VoiceChatConnectRequested', () {
      blocTest<VoiceChatBloc, VoiceChatState>(
        'emits [VoiceChatLoading, VoiceChatConnected] when connection succeeds',
        build: () => voiceChatBloc,
        act: (bloc) => bloc.add(const VoiceChatConnectRequested()),
        expect: () => [
          const VoiceChatLoading(),
          const VoiceChatConnected(
            messages: [],
            connectionStatus: ConnectionStatus.connected,
          ),
        ],
      );
    });

    group('VoiceChatMessageSent', () {
      const testMessage = 'Hello, AI!';
      final testMessageParams = SendMessageParams(message: testMessage);
      
      final testAudioResponse = AudioResponse(
        id: 'test-id',
        audioData: [1, 2, 3, 4],
        format: AudioFormat.wav,
        sampleRate: 16000,
        bitRate: 16,
        duration: const Duration(seconds: 5),
        createdAt: DateTime(2023, 1, 1),
      );

      blocTest<VoiceChatBloc, VoiceChatState>(
        'emits correct states when message is sent successfully',
        setUp: () {
          when(mockSendMessageUseCase.call(any))
              .thenAnswer((_) async => Right(Stream.value(testAudioResponse)));
          when(mockPlayAudioUseCase.call(any))
              .thenAnswer((_) async => const Right(null));
        },
        build: () => voiceChatBloc,
        seed: () => const VoiceChatConnected(
          messages: [],
          connectionStatus: ConnectionStatus.connected,
        ),
        act: (bloc) => bloc.add(const VoiceChatMessageSent(message: testMessage)),
        expect: () => [
          isA<VoiceChatMessageSending>(),
          isA<VoiceChatConnected>().having(
            (state) => state.isProcessingMessage,
            'isProcessingMessage',
            true,
          ),
        ],
        verify: (bloc) {
          verify(mockSendMessageUseCase.call(
            argThat(predicate<SendMessageParams>((params) =>
                params.message == testMessage)),
          )).called(1);
        },
      );

      blocTest<VoiceChatBloc, VoiceChatState>(
        'emits error state when send message fails',
        setUp: () {
          when(mockSendMessageUseCase.call(any))
              .thenAnswer((_) async => const Left(NetworkFailure('Connection failed')));
        },
        build: () => voiceChatBloc,
        seed: () => const VoiceChatConnected(
          messages: [],
          connectionStatus: ConnectionStatus.connected,
        ),
        act: (bloc) => bloc.add(const VoiceChatMessageSent(message: testMessage)),
        expect: () => [
          isA<VoiceChatMessageSending>(),
          isA<VoiceChatError>().having(
            (state) => state.message,
            'message',
            'Connection failed',
          ),
        ],
      );
    });

    group('VoiceChatDisconnectRequested', () {
      blocTest<VoiceChatBloc, VoiceChatState>(
        'emits VoiceChatDisconnected when disconnect is requested',
        build: () => voiceChatBloc,
        seed: () => const VoiceChatConnected(
          messages: [],
          connectionStatus: ConnectionStatus.connected,
        ),
        act: (bloc) => bloc.add(const VoiceChatDisconnectRequested()),
        expect: () => [
          isA<VoiceChatDisconnected>().having(
            (state) => state.reason,
            'reason',
            'User requested disconnect',
          ),
        ],
      );
    });

    group('VoiceChatAudioReceived', () {
      const testAudioData = [1, 2, 3, 4, 5];
      const testMessageId = 'audio-message-id';

      blocTest<VoiceChatBloc, VoiceChatState>(
        'processes audio and plays it successfully',
        setUp: () {
          when(mockPlayAudioUseCase.call(any))
              .thenAnswer((_) async => const Right(null));
        },
        build: () => voiceChatBloc,
        seed: () => const VoiceChatConnected(
          messages: [],
          connectionStatus: ConnectionStatus.connected,
        ),
        act: (bloc) => bloc.add(const VoiceChatAudioReceived(
          audioData: testAudioData,
          messageId: testMessageId,
        )),
        expect: () => [
          isA<VoiceChatAudioPlaying>(),
          isA<VoiceChatConnected>().having(
            (state) => state.messages.length,
            'messages length',
            1,
          ),
        ],
        verify: (bloc) {
          verify(mockPlayAudioUseCase.call(any)).called(1);
        },
      );

      blocTest<VoiceChatBloc, VoiceChatState>(
        'emits error state when audio playback fails',
        setUp: () {
          when(mockPlayAudioUseCase.call(any))
              .thenAnswer((_) async => const Left(AudioFailure('Playback failed')));
        },
        build: () => voiceChatBloc,
        seed: () => const VoiceChatConnected(
          messages: [],
          connectionStatus: ConnectionStatus.connected,
        ),
        act: (bloc) => bloc.add(const VoiceChatAudioReceived(
          audioData: testAudioData,
          messageId: testMessageId,
        )),
        expect: () => [
          isA<VoiceChatAudioPlaying>(),
          isA<VoiceChatError>().having(
            (state) => state.message,
            'message',
            contains('Failed to play audio'),
          ),
        ],
      );
    });

    group('VoiceChatHistoryCleared', () {
      blocTest<VoiceChatBloc, VoiceChatState>(
        'clears message history',
        build: () => voiceChatBloc,
        seed: () => VoiceChatConnected(
          messages: [
            VoiceMessage(
              id: '1',
              content: 'Test message',
              type: MessageType.user,
              status: MessageStatus.sent,
              timestamp: DateTime.now(),
            ),
          ],
          connectionStatus: ConnectionStatus.connected,
        ),
        act: (bloc) => bloc.add(const VoiceChatHistoryCleared()),
        expect: () => [
          const VoiceChatConnected(
            messages: [],
            connectionStatus: ConnectionStatus.connected,
          ),
        ],
      );
    });
  });
}