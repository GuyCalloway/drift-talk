import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

import '../utils/logger.dart';

/// Service for text-to-speech functionality
/// Provides controlled text-to-speech capabilities with configurable settings
@lazySingleton
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  TextToSpeechService() {
    _initialize();
  }
  
  /// Initialize TTS with optimal settings
  Future<void> _initialize() async {
    try {
      // Configure TTS settings
      await _flutterTts.setSpeechRate(0.4); // Slower for better comprehension
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);
      
      // Set language to English
      await _flutterTts.setLanguage("en-US");
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.info('TTS: Speech completed');
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
  
  /// Speak the provided text
  Future<bool> speak(String text) async {
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
      
      _isSpeaking = true;
      AppLogger.info('TTS: Speaking text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      final result = await _flutterTts.speak(text);
      return result == 1; // 1 indicates success
    } catch (e) {
      _isSpeaking = false;
      AppLogger.error('TTS speak error: $e');
      return false;
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