class AppConstants {
  static const String appName = 'Voice AI App';
  static const String appVersion = '1.0.0';
  
  static const String openaiRealtimeApiUrl = 'wss://api.openai.com/v1/realtime?model=gpt-realtime';
  static const String openaiApiVersion = 'v1';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  static const int maxRecordingDuration = 300; // 5 minutes in seconds
  static const int audioSampleRate = 16000;
  static const int audioBitRate = 16;
  
  static const String secureStorageOpenAIKey = 'openai_api_key';
  static const String secureStorageUserSettings = 'user_settings';
  
  static const List<String> supportedAudioFormats = ['wav', 'mp3', 'opus'];
  
  static const Map<String, String> openaiHeaders = {
    'Content-Type': 'application/json',
    'OpenAI-Beta': 'realtime=v1',
  };
  
  static const String defaultErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please check your API key.';
  static const String audioErrorMessage = 'Audio processing error. Please check your microphone permissions.';
}