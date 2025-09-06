import 'package:equatable/equatable.dart';

enum MessageType { user, assistant }

enum MessageStatus { sending, sent, received, error }

class VoiceMessage extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? audioUrl;
  final Duration? audioDuration;
  final String? errorMessage;

  const VoiceMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.audioUrl,
    this.audioDuration,
    this.errorMessage,
  });

  VoiceMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? audioUrl,
    Duration? audioDuration,
    String? errorMessage,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        type,
        status,
        timestamp,
        audioUrl,
        audioDuration,
        errorMessage,
      ];
}