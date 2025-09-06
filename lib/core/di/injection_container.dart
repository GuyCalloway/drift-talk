import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import 'injection_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Initialize app configuration
  await AppConfig.initialize();
  
  
  // Determine environment for dependency injection
  final environment = AppConfig.instance.useMockData ? 'mock' : 'production';
  
  // Print configuration
  AppConfig.instance.printConfig();
  
  getIt.init(environment: environment);
}