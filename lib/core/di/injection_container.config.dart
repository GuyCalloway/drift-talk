// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:voice_ai_app/core/network/connection_manager.dart' as _i6;
import 'package:voice_ai_app/core/network/webrtc_client.dart' as _i883;
import 'package:voice_ai_app/core/services/conversation_summarizer.dart'
    as _i490;
import 'package:voice_ai_app/core/services/cost_optimizer.dart' as _i285;
import 'package:voice_ai_app/core/services/location_context_service.dart'
    as _i1042;
import 'package:voice_ai_app/core/services/logo_selection_service.dart'
    as _i251;
import 'package:voice_ai_app/core/services/mock_location_text_service.dart'
    as _i542;
import 'package:voice_ai_app/core/services/optimized_audio_service.dart'
    as _i504;
import 'package:voice_ai_app/core/services/smart_conversation_manager.dart'
    as _i1025;
import 'package:voice_ai_app/core/services/text_to_speech_service.dart'
    as _i210;
import 'package:voice_ai_app/core/storage/secure_storage.dart' as _i204;
import 'package:voice_ai_app/features/voice_chat/data/datasources/mock_voice_chat_datasource.dart'
    as _i136;
import 'package:voice_ai_app/features/voice_chat/data/datasources/openai_webrtc_datasource.dart'
    as _i16;
import 'package:voice_ai_app/features/voice_chat/data/repositories/voice_chat_repository_impl.dart'
    as _i900;
import 'package:voice_ai_app/features/voice_chat/domain/repositories/voice_chat_repository.dart'
    as _i1063;
import 'package:voice_ai_app/features/voice_chat/domain/usecases/send_message_usecase.dart'
    as _i85;
import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_bloc.dart'
    as _i30;

const String _mock = 'mock';
const String _test = 'test';
const String _production = 'production';

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i204.SecureStorage>(() => _i204.SecureStorage());
    gh.singleton<_i883.WebRTCClient>(() => _i883.WebRTCClient());
    gh.singleton<_i490.ConversationSummarizer>(
        () => _i490.ConversationSummarizer());
    gh.singleton<_i504.OptimizedAudioService>(
        () => _i504.OptimizedAudioService());
    gh.singleton<_i1025.SmartConversationManager>(
        () => _i1025.SmartConversationManager());
    gh.singleton<_i285.CostOptimizer>(() => _i285.CostOptimizer());
    gh.lazySingleton<_i251.LogoSelectionService>(
        () => _i251.LogoSelectionService());
    gh.lazySingleton<_i1042.LocationContextService>(
        () => _i1042.LocationContextService());
    gh.lazySingleton<_i210.TextToSpeechService>(
        () => _i210.TextToSpeechService());
    gh.lazySingleton<_i542.MockLocationTextService>(
        () => _i542.MockLocationTextService());
    gh.singleton<_i6.ConnectionManager>(
        () => _i6.ConnectionManager(gh<_i883.WebRTCClient>()));
    gh.lazySingleton<_i16.OpenAIWebRTCDataSource>(
      () => _i136.MockVoiceChatDataSource(gh<_i883.WebRTCClient>()),
      registerFor: {
        _mock,
        _test,
      },
    );
    gh.lazySingleton<_i16.OpenAIWebRTCDataSource>(
      () => _i16.OpenAIWebRTCDataSourceImpl(
        gh<_i883.WebRTCClient>(),
        gh<_i204.SecureStorage>(),
        gh<_i6.ConnectionManager>(),
        gh<_i1025.SmartConversationManager>(),
      ),
      registerFor: {_production},
    );
    gh.lazySingleton<_i1063.VoiceChatRepository>(
        () => _i900.VoiceChatRepositoryImpl(
              gh<_i16.OpenAIWebRTCDataSource>(),
              gh<_i1042.LocationContextService>(),
            ));
    gh.factory<_i85.SendMessageUseCase>(
        () => _i85.SendMessageUseCase(gh<_i1063.VoiceChatRepository>()));
    gh.factory<_i30.VoiceChatBloc>(() => _i30.VoiceChatBloc(
          gh<_i85.SendMessageUseCase>(),
          gh<_i1063.VoiceChatRepository>(),
          gh<_i490.ConversationSummarizer>(),
        ));
    return this;
  }
}
