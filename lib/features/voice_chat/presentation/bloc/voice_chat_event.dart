import 'package:equatable/equatable.dart';
import '../../domain/repositories/voice_chat_repository.dart';

abstract class VoiceChatEvent extends Equatable {
  const VoiceChatEvent();

  @override
  List<Object?> get props => [];
}

class VoiceChatConnectRequested extends VoiceChatEvent {
  const VoiceChatConnectRequested();
}

class VoiceChatDisconnectRequested extends VoiceChatEvent {
  const VoiceChatDisconnectRequested();
}

class VoiceChatMessageSent extends VoiceChatEvent {
  final String message;
  final String? context;

  const VoiceChatMessageSent({
    required this.message,
    this.context,
  });

  @override
  List<Object?> get props => [message, context];
}

class VoiceChatAudioReceived extends VoiceChatEvent {
  final List<int> audioData;
  final String messageId;
  final String? transcript;

  const VoiceChatAudioReceived({
    required this.audioData,
    required this.messageId,
    this.transcript,
  });

  @override
  List<Object?> get props => [audioData, messageId, transcript];
}

class VoiceChatConnectionStatusChanged extends VoiceChatEvent {
  final ConnectionStatus status;

  const VoiceChatConnectionStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class VoiceChatErrorOccurred extends VoiceChatEvent {
  final String error;
  final String? code;

  const VoiceChatErrorOccurred({
    required this.error,
    this.code,
  });

  @override
  List<Object?> get props => [error, code];
}

class VoiceChatHistoryRequested extends VoiceChatEvent {
  const VoiceChatHistoryRequested();
}

class VoiceChatHistoryCleared extends VoiceChatEvent {
  const VoiceChatHistoryCleared();
}

class VoiceChatWrapUpRequested extends VoiceChatEvent {
  const VoiceChatWrapUpRequested();
}

