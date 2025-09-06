import 'package:equatable/equatable.dart';

import '../../domain/entities/voice_message.dart';
import '../../domain/repositories/voice_chat_repository.dart';

abstract class VoiceChatState extends Equatable {
  const VoiceChatState();

  @override
  List<Object?> get props => [];
}

class VoiceChatInitial extends VoiceChatState {
  const VoiceChatInitial();
}

class VoiceChatLoading extends VoiceChatState {
  const VoiceChatLoading();
}

class VoiceChatConnected extends VoiceChatState {
  final List<VoiceMessage> messages;
  final ConnectionStatus connectionStatus;
  final bool isProcessingMessage;

  const VoiceChatConnected({
    required this.messages,
    required this.connectionStatus,
    this.isProcessingMessage = false,
  });

  VoiceChatConnected copyWith({
    List<VoiceMessage>? messages,
    ConnectionStatus? connectionStatus,
    bool? isProcessingMessage,
  }) {
    return VoiceChatConnected(
      messages: messages ?? this.messages,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isProcessingMessage: isProcessingMessage ?? this.isProcessingMessage,
    );
  }

  @override
  List<Object?> get props => [messages, connectionStatus, isProcessingMessage];
}

class VoiceChatDisconnected extends VoiceChatState {
  final List<VoiceMessage> messages;
  final String? reason;

  const VoiceChatDisconnected({
    required this.messages,
    this.reason,
  });

  @override
  List<Object?> get props => [messages, reason];
}

class VoiceChatError extends VoiceChatState {
  final String message;
  final String? code;
  final List<VoiceMessage> messages;
  final ConnectionStatus connectionStatus;

  const VoiceChatError({
    required this.message,
    this.code,
    required this.messages,
    required this.connectionStatus,
  });

  @override
  List<Object?> get props => [message, code, messages, connectionStatus];
}

class VoiceChatMessageSending extends VoiceChatState {
  final List<VoiceMessage> messages;
  final ConnectionStatus connectionStatus;
  final VoiceMessage pendingMessage;

  const VoiceChatMessageSending({
    required this.messages,
    required this.connectionStatus,
    required this.pendingMessage,
  });

  @override
  List<Object?> get props => [messages, connectionStatus, pendingMessage];
}

class VoiceChatAudioPlaying extends VoiceChatState {
  final List<VoiceMessage> messages;
  final ConnectionStatus connectionStatus;
  final VoiceMessage currentMessage;

  const VoiceChatAudioPlaying({
    required this.messages,
    required this.connectionStatus,
    required this.currentMessage,
  });

  @override
  List<Object?> get props => [messages, connectionStatus, currentMessage];
}