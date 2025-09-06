import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/webrtc_client.dart';
import '../../../../core/services/location_context_service.dart';
import '../../domain/entities/voice_message.dart';
import '../../domain/entities/audio_response.dart';
import '../../domain/repositories/voice_chat_repository.dart';
import '../datasources/openai_webrtc_datasource.dart';

@LazySingleton(as: VoiceChatRepository)
class VoiceChatRepositoryImpl implements VoiceChatRepository {
  final OpenAIWebRTCDataSource dataSource;
  final LocationContextService _locationContextService;
  final List<VoiceMessage> _messages = [];
  
  VoiceChatRepositoryImpl(this.dataSource, this._locationContextService);

  @override
  Future<Either<Failure, Stream<AudioResponse>>> sendMessage({
    required String message,
    String? context,
  }) async {
    try {
      // Enhance context with location data and walking tour information
      String enhancedContext = _buildEnhancedContext(message, context);
      
      final audioStream = await dataSource.sendMessage(message, enhancedContext);
      return Right(audioStream.map((model) => model.toEntity()));
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message, e.code));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message, e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code, e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connect() async {
    try {
      await dataSource.connect();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message, e.code));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await dataSource.disconnect();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<ConnectionStatus> get connectionStatus {
    return dataSource.connectionState.map((rtcState) {
      if (rtcState == WebRTCConnectionState.connected) {
        return ConnectionStatus.connected;
      } else if (rtcState == WebRTCConnectionState.connecting) {
        return ConnectionStatus.connecting;
      } else if (rtcState == WebRTCConnectionState.disconnected) {
        return ConnectionStatus.disconnected;
      } else if (rtcState == WebRTCConnectionState.failed || 
                 rtcState == WebRTCConnectionState.closed) {
        return ConnectionStatus.error;
      } else {
        return ConnectionStatus.disconnected;
      }
    });
  }

  @override
  Future<Either<Failure, List<VoiceMessage>>> getChatHistory() async {
    try {
      return Right(List.from(_messages));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearChatHistory() async {
    try {
      _messages.clear();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> wrapUpCurrentResponse() async {
    try {
      await dataSource.wrapUpAndContinue();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Build enhanced context by combining user context with location data
  String _buildEnhancedContext(String message, String? userContext) {
    // Start with general Dickens walking tour context
    String context = _locationContextService.getGeneralContext();
    
    // Try to extract coordinates from user context if provided
    if (userContext != null && userContext.isNotEmpty) {
      // Look for coordinate patterns: "lat: 51.5055, lng: -0.091" or similar
      final coordPattern = RegExp(r'lat[:\s]*(-?\d+\.?\d*)[,\s]+lng[:\s]*(-?\d+\.?\d*)');
      final match = coordPattern.firstMatch(userContext.toLowerCase());
      
      if (match != null) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lng = double.tryParse(match.group(2) ?? '');
        
        if (lat != null && lng != null) {
          final locationContext = _locationContextService.getLocationContext(lat, lng);
          if (locationContext != null) {
            context = locationContext;
          }
        }
      }
      
      // Also check for location names in the user context
      final nameContext = _locationContextService.getLocationContextByName(userContext);
      if (nameContext != null) {
        context = nameContext;
      }
      
      // If user provided additional context, append it
      context += '\n\nAdditional Context: $userContext';
    }
    
    // Try to extract location information from the message itself
    final messageLocationContext = _locationContextService.getLocationContextByName(message);
    if (messageLocationContext != null) {
      context = messageLocationContext;
    }
    
    return context;
  }
}