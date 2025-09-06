import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration management
/// Handles environment-specific settings and feature flags
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();
  
  AppConfig._();

  /// Initialize configuration from environment
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    _instance = AppConfig._();
  }

  /// Whether to use mock data instead of real OpenAI API
  bool get useMockData {
    final mockValue = dotenv.env['USE_MOCK_DATA']?.toLowerCase();
    return mockValue == 'true' || mockValue == '1';
  }

  /// Environment type (development, staging, production)
  String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  /// Whether running in development mode
  bool get isDevelopment => environment == 'development';

  /// Whether running in production mode  
  bool get isProduction => environment == 'production';

  /// OpenAI API key (only used if not using mock data)
  String? get openAiApiKey {
    if (useMockData) return null;
    return dotenv.env['OPENAI_API_KEY'];
  }

  /// Enable detailed logging
  bool get enableLogging {
    final logValue = dotenv.env['ENABLE_LOGGING']?.toLowerCase();
    return logValue == 'true' || logValue == '1' || isDevelopment;
  }

  /// Log level (debug, info, warning, error)
  String get logLevel {
    return dotenv.env['LOG_LEVEL'] ?? (isDevelopment ? 'debug' : 'info');
  }

  /// Mock response delay in milliseconds
  int get mockResponseDelay {
    final delay = dotenv.env['MOCK_RESPONSE_DELAY'];
    return delay != null ? int.tryParse(delay) ?? 500 : 500;
  }

  /// Mock audio duration in seconds
  int get mockAudioDuration {
    final duration = dotenv.env['MOCK_AUDIO_DURATION'];
    return duration != null ? int.tryParse(duration) ?? 2 : 2;
  }

  /// Print configuration summary
  void printConfig() {
    print('🔧 App Configuration:');
    print('   Environment: $environment');
    print('   Use Mock Data: $useMockData');
    print('   Enable Logging: $enableLogging');
    print('   Log Level: $logLevel');
    
    if (useMockData) {
      print('   Mock Response Delay: ${mockResponseDelay}ms');
      print('   Mock Audio Duration: ${mockAudioDuration}s');
      print('🎭 Running in MOCK MODE - No OpenAI API calls will be made');
    } else {
      print('   OpenAI API Key: ${openAiApiKey != null ? '***configured***' : 'NOT SET'}');
      print('🔴 Running in LIVE MODE - OpenAI API calls will be made');
    }
    print('');
  }
}