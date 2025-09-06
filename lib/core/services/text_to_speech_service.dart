import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

import '../utils/logger.dart';
import 'narrative_manager_service.dart';

/// Service for text-to-speech functionality
/// Provides controlled text-to-speech with dual voice support for storytelling
/// Supports analytical (female) and narrative (male) voice roles
@lazySingleton
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // Voice configuration for dual voice system
  Map<VoiceRole, Map<String, dynamic>>? _availableVoices;
  VoiceRole? _currentVoiceRole;
  
  TextToSpeechService() {
    _initialize();
  }
  
  /// Initialize TTS with optimal settings and voice discovery
  Future<void> _initialize() async {
    try {
      // Configure TTS settings
      await _flutterTts.setSpeechRate(0.4); // Slower for better comprehension
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);
      
      // Set language to English
      await _flutterTts.setLanguage("en-US");
      
      // Discover and configure available voices for dual voice system
      await _discoverVoices();
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.info('TTS: Speech completed (${_currentVoiceRole?.name ?? 'default'} voice)');
      });
      
      // Set up error handler
      _flutterTts.setErrorHandler((message) {
        _isSpeaking = false;
        AppLogger.error('TTS Error: $message');
      });
      
      _isInitialized = true;
      AppLogger.info('TTS Service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize TTS: $e');
    }
  }
  
  /// Discover available voices and map them to narrative roles
  Future<void> _discoverVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        AppLogger.warning('No voices available for dual voice system');
        return;
      }
      
      _availableVoices = {};
      
      // Find female voice for analytical role (prefer UK/US English)
      final femaleVoice = voices.firstWhere(
        (voice) => 
          voice['name'].toString().toLowerCase().contains('female') ||
          voice['name'].toString().toLowerCase().contains('woman') ||
          voice['name'].toString().toLowerCase().contains('karen') ||
          voice['name'].toString().toLowerCase().contains('susan'),
        orElse: () => voices.firstWhere(
          (voice) => voice['locale'].toString().startsWith('en-'),
          orElse: () => voices.first,
        ),
      );
      
      // Find male voice for narrative role
      final maleVoice = voices.firstWhere(
        (voice) => 
          voice['name'].toString().toLowerCase().contains('male') ||
          voice['name'].toString().toLowerCase().contains('man') ||
          voice['name'].toString().toLowerCase().contains('david') ||
          voice['name'].toString().toLowerCase().contains('alex'),
        orElse: () => voices.firstWhere(
          (voice) => 
            voice['locale'].toString().startsWith('en-') && 
            voice != femaleVoice,
          orElse: () => voices.length > 1 ? voices[1] : voices.first,
        ),
      );
      
      _availableVoices = {
        VoiceRole.analytical: femaleVoice,
        VoiceRole.narrative: maleVoice,
      };
      
      AppLogger.info('🎭 Dual voice system configured:');
      AppLogger.info('   Analytical: ${femaleVoice['name']} (${femaleVoice['locale']})');
      AppLogger.info('   Narrative: ${maleVoice['name']} (${maleVoice['locale']})');
      
    } catch (e) {
      AppLogger.error('Failed to discover voices: $e');
    }
  }
  
  /// Speak the provided text with default voice
  Future<bool> speak(String text) async {
    return speakWithVoice(text, null);
  }
  
  /// Speak the provided text with specific voice role for dual voice system
  Future<bool> speakWithVoice(String text, VoiceRole? voiceRole) async {
    if (!_isInitialized) {
      AppLogger.warning('TTS not initialized, attempting to initialize...');
      await _initialize();
    }
    
    if (text.trim().isEmpty) {
      AppLogger.warning('TTS: Empty text provided');
      return false;
    }
    
    try {
      // Stop any current speech
      await stop();
      
      // Set voice for this speech if available
      if (voiceRole != null && _availableVoices != null && _availableVoices!.containsKey(voiceRole)) {
        await _setVoice(voiceRole);
      }
      
      _isSpeaking = true;
      _currentVoiceRole = voiceRole;
      
      final voiceDesc = voiceRole?.name ?? 'default';
      AppLogger.info('TTS: Speaking with $voiceDesc voice: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      final result = await _flutterTts.speak(text);
      return result == 1; // 1 indicates success
    } catch (e) {
      _isSpeaking = false;
      _currentVoiceRole = null;
      AppLogger.error('TTS speak error: $e');
      return false;
    }
  }
  
  /// Set the TTS voice for a specific role
  Future<void> _setVoice(VoiceRole role) async {
    if (_availableVoices == null || !_availableVoices!.containsKey(role)) {
      AppLogger.warning('Voice for role ${role.name} not available');
      return;
    }
    
    try {
      final voiceConfig = _availableVoices![role]!;
      // Convert to required Map<String, String> format
      final voiceMap = <String, String>{
        'name': voiceConfig['name']?.toString() ?? '',
        'locale': voiceConfig['locale']?.toString() ?? '',
      };
      await _flutterTts.setVoice(voiceMap);
      
      // Adjust pitch for role characteristics
      switch (role) {
        case VoiceRole.analytical:
          await _flutterTts.setPitch(1.0); // Standard pitch for serious tone
          break;
        case VoiceRole.narrative:
          await _flutterTts.setPitch(0.9); // Slightly lower for storytelling
          break;
      }
      
      AppLogger.debug('Set voice for ${role.name}: ${voiceConfig['name']}');
    } catch (e) {
      AppLogger.error('Failed to set voice for ${role.name}: $e');
    }
  }
  
  /// Stop current speech
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      AppLogger.info('TTS: Speech stopped');
    }
  }
  
  /// Pause current speech
  Future<void> pause() async {
    if (_isSpeaking) {
      await _flutterTts.pause();
      AppLogger.info('TTS: Speech paused');
    }
  }
  
  /// Check if TTS is currently speaking
  bool get isSpeaking => _isSpeaking;
  
  /// Check if TTS is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get available voices (for future enhancement)
  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      AppLogger.error('Error getting voices: $e');
      return [];
    }
  }
  
  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      AppLogger.info('TTS: Speech rate set to $rate');
    } catch (e) {
      AppLogger.error('Error setting speech rate: $e');
    }
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
      AppLogger.info('TTS: Volume set to $volume');
    } catch (e) {
      AppLogger.error('Error setting volume: $e');
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _flutterTts.stop();
    _isInitialized = false;
    _isSpeaking = false;
  }
}