import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/utils/logger.dart';
import 'features/voice_chat/presentation/pages/voice_chat_page.dart';
import 'features/voice_chat/presentation/bloc/voice_chat_bloc.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Configure dependency injection (includes AppConfig initialization)
  await configureDependencies();
  
  AppLogger.info('Application starting');
  
  runApp(const VoiceAIApp());
}

class VoiceAIApp extends StatelessWidget {
  const VoiceAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoiceChatBloc>(
      create: (context) => getIt<VoiceChatBloc>(),
      child: MaterialApp(
        title: 'Voice AI App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const VoiceChatPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}