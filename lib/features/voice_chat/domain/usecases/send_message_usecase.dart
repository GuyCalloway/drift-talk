import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/audio_response.dart';
import '../repositories/voice_chat_repository.dart';

@injectable
class SendMessageUseCase {
  final VoiceChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, Stream<AudioResponse>>> call(
    SendMessageParams params,
  ) async {
    return await repository.sendMessage(
      message: params.message,
      context: params.context,
    );
  }
}

class SendMessageParams {
  final String message;
  final String? context;

  SendMessageParams({
    required this.message,
    this.context,
  });
}