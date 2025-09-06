import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/voice_message.dart';
import '../entities/audio_response.dart';

abstract class VoiceChatRepository {
  Future<Either<Failure, Stream<AudioResponse>>> sendMessage({
    required String message,
    String? context,
  });

  Future<Either<Failure, void>> connect();
  
  Future<Either<Failure, void>> disconnect();
  
  Future<Either<Failure, void>> wrapUpCurrentResponse();
  
  Stream<ConnectionStatus> get connectionStatus;
  
  Future<Either<Failure, List<VoiceMessage>>> getChatHistory();
  
  Future<Either<Failure, void>> clearChatHistory();
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}