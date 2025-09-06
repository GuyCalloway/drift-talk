import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/services/conversation_summarizer.dart';
import '../../domain/entities/voice_message.dart';
import '../../domain/entities/audio_response.dart';
import '../../domain/repositories/voice_chat_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'voice_chat_event.dart';
import 'voice_chat_state.dart';

@injectable
class VoiceChatBloc extends Bloc<VoiceChatEvent, VoiceChatState> {
  final SendMessageUseCase _sendMessageUseCase;
  final VoiceChatRepository _repository;
  final ConversationSummarizer _conversationSummarizer;

  final List<VoiceMessage> _messages = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  StreamSubscription<AudioResponse>? _audioSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  VoiceChatBloc(
    this._sendMessageUseCase,
    this._repository,
    this._conversationSummarizer,
  ) : super(const VoiceChatInitial()) {
    on<VoiceChatConnectRequested>(_onConnectRequested);
    on<VoiceChatDisconnectRequested>(_onDisconnectRequested);
    on<VoiceChatMessageSent>(_onMessageSent);
    on<VoiceChatAudioReceived>(_onAudioReceived);
    on<VoiceChatConnectionStatusChanged>(_onConnectionStatusChanged);
    on<VoiceChatErrorOccurred>(_onErrorOccurred);
    on<VoiceChatHistoryRequested>(_onHistoryRequested);
    on<VoiceChatHistoryCleared>(_onHistoryCleared);
    on<VoiceChatWrapUpRequested>(_onWrapUpRequested);
    
    _connectionSubscription = _repository.connectionStatus.listen((status) {
      add(VoiceChatConnectionStatusChanged(status));
    });
  }

  Future<void> _onConnectRequested(
    VoiceChatConnectRequested event,
    Emitter<VoiceChatState> emit,
  ) async {
    emit(const VoiceChatLoading());
    
    final result = await _repository.connect();
    
    await result.fold(
      (failure) async {
        AppLogger.error('Failed to connect to voice chat: ${failure.message}');
        emit(VoiceChatError(
          message: failure.message,
          code: failure.code,
          messages: List.from(_messages),
          connectionStatus: ConnectionStatus.error,
        ));
      },
      (_) async {
        AppLogger.info('Voice chat connected');
        emit(VoiceChatConnected(
          messages: List.from(_messages),
          connectionStatus: _connectionStatus,
        ));
      },
    );
  }

  Future<void> _onDisconnectRequested(
    VoiceChatDisconnectRequested event,
    Emitter<VoiceChatState> emit,
  ) async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    
    final result = await _repository.disconnect();
    
    await result.fold(
      (failure) async {
        AppLogger.error('Failed to disconnect from voice chat: ${failure.message}');
        emit(VoiceChatError(
          message: failure.message,
          messages: List.from(_messages),
          connectionStatus: _connectionStatus,
        ));
      },
      (_) async {
        AppLogger.info('Voice chat disconnected');
        emit(VoiceChatDisconnected(
          messages: List.from(_messages),
          reason: 'User requested disconnect',
        ));
      },
    );
  }

  Future<void> _onMessageSent(
    VoiceChatMessageSent event,
    Emitter<VoiceChatState> emit,
  ) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMessage = VoiceMessage(
      id: messageId,
      content: event.message,
      type: MessageType.user,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);

    emit(VoiceChatMessageSending(
      messages: List.from(_messages),
      connectionStatus: _connectionStatus,
      pendingMessage: userMessage,
    ));

    try {
      // Build context that includes conversation history
      final contextWithHistory = _conversationSummarizer.buildContextWithHistory(
        event.context ?? '',
        event.message,
        _messages.where((m) => m.status == MessageStatus.sent || m.status == MessageStatus.received).toList(),
      );

      final result = await _sendMessageUseCase.call(
        SendMessageParams(
          message: event.message,
          context: contextWithHistory,
        ),
      );

      await result.fold(
        (failure) async {
          // Update message status to error
          final errorMessageIndex = _messages.indexWhere((m) => m.id == messageId);
          if (errorMessageIndex != -1) {
            _messages[errorMessageIndex] = _messages[errorMessageIndex].copyWith(
              status: MessageStatus.error,
              errorMessage: failure.message,
            );
          }

          emit(VoiceChatError(
            message: failure.message,
            code: failure.code,
            messages: List.from(_messages),
            connectionStatus: _connectionStatus,
          ));
        },
        (audioStream) async {
          // Update message status to sent
          final sentMessageIndex = _messages.indexWhere((m) => m.id == messageId);
          if (sentMessageIndex != -1) {
            _messages[sentMessageIndex] = _messages[sentMessageIndex].copyWith(
              status: MessageStatus.sent,
            );
          }

          emit(VoiceChatConnected(
            messages: List.from(_messages),
            connectionStatus: _connectionStatus,
            isProcessingMessage: true,
          ));

          // Listen to audio stream
          _audioSubscription = audioStream.listen(
            (audioResponse) {
              add(VoiceChatAudioReceived(
                audioData: audioResponse.audioData,
                messageId: audioResponse.id,
                transcript: audioResponse.transcript,
              ));
            },
            onError: (error) {
              add(VoiceChatErrorOccurred(
                error: error.toString(),
              ));
            },
          );
        },
      );
    } catch (e) {
      AppLogger.error('Failed to send message', e);
      
      // Update message status to error
      final errorMessageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (errorMessageIndex != -1) {
        _messages[errorMessageIndex] = _messages[errorMessageIndex].copyWith(
          status: MessageStatus.error,
          errorMessage: e.toString(),
        );
      }

      emit(VoiceChatError(
        message: 'Failed to send message: ${e.toString()}',
        messages: List.from(_messages),
        connectionStatus: _connectionStatus,
      ));
    }
  }

  Future<void> _onAudioReceived(
    VoiceChatAudioReceived event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      // Check if this is the first chunk with transcript
      if (event.transcript != null) {
        // Create new assistant message with transcript
        final assistantMessage = VoiceMessage(
          id: event.messageId,
          content: event.transcript!,
          type: MessageType.assistant,
          status: MessageStatus.received,
          timestamp: DateTime.now(),
          audioDuration: const Duration(seconds: 2), // Mock duration
        );

        _messages.add(assistantMessage);
        AppLogger.info('Assistant response: "${event.transcript}"');
      } else {
        // This is an audio-only chunk, message should already exist
        AppLogger.debug('Audio chunk received (${event.audioData.length} bytes)');
      }

      // Return to connected state
      emit(VoiceChatConnected(
        messages: List.from(_messages),
        connectionStatus: _connectionStatus,
        isProcessingMessage: false,
      ));
    } catch (e) {
      AppLogger.error('Failed to handle received audio', e);
      emit(VoiceChatError(
        message: 'Failed to play audio: ${e.toString()}',
        messages: List.from(_messages),
        connectionStatus: _connectionStatus,
      ));
    }
  }

  void _onConnectionStatusChanged(
    VoiceChatConnectionStatusChanged event,
    Emitter<VoiceChatState> emit,
  ) {
    _connectionStatus = event.status;
    
    if (state is VoiceChatConnected) {
      emit((state as VoiceChatConnected).copyWith(
        connectionStatus: _connectionStatus,
      ));
    }
  }

  void _onErrorOccurred(
    VoiceChatErrorOccurred event,
    Emitter<VoiceChatState> emit,
  ) {
    AppLogger.error('Voice chat error: ${event.error}');
    emit(VoiceChatError(
      message: event.error,
      code: event.code,
      messages: List.from(_messages),
      connectionStatus: _connectionStatus,
    ));
  }

  void _onHistoryRequested(
    VoiceChatHistoryRequested event,
    Emitter<VoiceChatState> emit,
  ) async {
    final result = await _repository.getChatHistory();
    
    await result.fold(
      (failure) async {
        AppLogger.error('Failed to get chat history: ${failure.message}');
      },
      (history) async {
        _messages.clear();
        _messages.addAll(history);
      },
    );
    
    emit(VoiceChatConnected(
      messages: List.from(_messages),
      connectionStatus: _connectionStatus,
    ));
  }

  void _onHistoryCleared(
    VoiceChatHistoryCleared event,
    Emitter<VoiceChatState> emit,
  ) async {
    await _repository.clearChatHistory();
    _messages.clear();
    emit(VoiceChatConnected(
      messages: [],
      connectionStatus: _connectionStatus,
    ));
  }

  Future<void> _onWrapUpRequested(
    VoiceChatWrapUpRequested event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      AppLogger.info('Wrap-up requested - signaling AI to conclude current response');
      await _repository.wrapUpCurrentResponse();
    } catch (e) {
      AppLogger.error('Failed to request wrap-up', e);
    }
  }

  @override
  Future<void> close() {
    _audioSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}