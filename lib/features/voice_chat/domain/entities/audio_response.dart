import 'package:equatable/equatable.dart';

enum AudioFormat { wav, mp3, opus }

class AudioResponse extends Equatable {
  final String id;
  final List<int> audioData;
  final AudioFormat format;
  final int sampleRate;
  final int bitRate;
  final Duration duration;
  final String? transcript;
  final DateTime createdAt;

  const AudioResponse({
    required this.id,
    required this.audioData,
    required this.format,
    required this.sampleRate,
    required this.bitRate,
    required this.duration,
    this.transcript,
    required this.createdAt,
  });

  AudioResponse copyWith({
    String? id,
    List<int>? audioData,
    AudioFormat? format,
    int? sampleRate,
    int? bitRate,
    Duration? duration,
    String? transcript,
    DateTime? createdAt,
  }) {
    return AudioResponse(
      id: id ?? this.id,
      audioData: audioData ?? this.audioData,
      format: format ?? this.format,
      sampleRate: sampleRate ?? this.sampleRate,
      bitRate: bitRate ?? this.bitRate,
      duration: duration ?? this.duration,
      transcript: transcript ?? this.transcript,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        audioData,
        format,
        sampleRate,
        bitRate,
        duration,
        transcript,
        createdAt,
      ];
}