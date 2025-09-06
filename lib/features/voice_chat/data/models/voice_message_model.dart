import '../../domain/entities/voice_message.dart';

class VoiceMessageModel extends VoiceMessage {
  const VoiceMessageModel({
    required super.id,
    required super.content,
    required super.type,
    required super.status,
    required super.timestamp,
    super.audioUrl,
    super.audioDuration,
    super.errorMessage,
  });

  factory VoiceMessageModel.fromJson(Map<String, dynamic> json) {
    return VoiceMessageModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.user,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration_ms'] != null
          ? Duration(milliseconds: json['audio_duration_ms'])
          : null,
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'audio_url': audioUrl,
      'audio_duration_ms': audioDuration?.inMilliseconds,
      'error_message': errorMessage,
    };
  }

  factory VoiceMessageModel.fromEntity(VoiceMessage message) {
    return VoiceMessageModel(
      id: message.id,
      content: message.content,
      type: message.type,
      status: message.status,
      timestamp: message.timestamp,
      audioUrl: message.audioUrl,
      audioDuration: message.audioDuration,
      errorMessage: message.errorMessage,
    );
  }

  VoiceMessage toEntity() {
    return VoiceMessage(
      id: id,
      content: content,
      type: type,
      status: status,
      timestamp: timestamp,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      errorMessage: errorMessage,
    );
  }
}