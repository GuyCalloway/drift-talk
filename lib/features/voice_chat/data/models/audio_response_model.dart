import '../../domain/entities/audio_response.dart';

class AudioResponseModel extends AudioResponse {
  const AudioResponseModel({
    required super.id,
    required super.audioData,
    required String format,
    required super.sampleRate,
    required super.bitRate,
    required super.duration,
    super.transcript,
    required super.createdAt,
  }) : super(
          format: format == 'pcm16' ? AudioFormat.wav :
                format == 'mp3' ? AudioFormat.mp3 :
                AudioFormat.opus,
        );

  factory AudioResponseModel.fromJson(Map<String, dynamic> json) {
    return AudioResponseModel(
      id: json['id'] ?? '',
      audioData: json['audio_data'] is List
          ? List<int>.from(json['audio_data'])
          : <int>[],
      format: json['format'] ?? 'wav',
      sampleRate: json['sample_rate'] ?? 16000,
      bitRate: json['bit_rate'] ?? 16,
      duration: Duration(
        milliseconds: json['duration_ms'] ?? 0,
      ),
      transcript: json['transcript'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio_data': audioData,
      'format': format.name,
      'sample_rate': sampleRate,
      'bit_rate': bitRate,
      'duration_ms': duration.inMilliseconds,
      'transcript': transcript,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AudioResponse toEntity() {
    return AudioResponse(
      id: id,
      audioData: audioData,
      format: format,
      sampleRate: sampleRate,
      bitRate: bitRate,
      duration: duration,
      transcript: transcript,
      createdAt: createdAt,
    );
  }
}