import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../utils/logger.dart';

@singleton
class OptimizedAudioService {
  StreamSubscription? _audioSubscription;
  bool _isPlaying = false;
  final List<Uint8List> _audioBuffer = [];
  Timer? _playbackTimer;
  
  // Optimize by buffering small chunks and playing efficiently
  static const _bufferThreshold = 5; // Only start playback after N chunks
  static const _maxBufferSize = 20; // Prevent memory bloat
  
  void processAudioStream(Stream<Uint8List> audioStream) {
    _cleanup();
    
    _audioSubscription = audioStream.listen(
      _onAudioData,
      onDone: _onStreamDone,
      onError: _onAudioError,
    );
  }
  
  void _onAudioData(Uint8List audioData) {
    // Drop data if already playing to prevent lag
    if (_isPlaying && _audioBuffer.length > _maxBufferSize) {
      AppLogger.debug('🗑️ Dropping audio data - buffer full');
      return;
    }
    
    _audioBuffer.add(audioData);
    AppLogger.debug('🎵 Buffered audio chunk (${_audioBuffer.length} total)');
    
    // Start playback once we have enough buffered
    if (!_isPlaying && _audioBuffer.length >= _bufferThreshold) {
      _startPlayback();
    }
  }
  
  void _startPlayback() {
    if (_isPlaying) return;
    
    _isPlaying = true;
    AppLogger.info('▶️ Starting optimized audio playback');
    
    // Process buffer in small intervals to prevent blocking
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 100), 
      _processAudioBuffer
    );
  }
  
  void _processAudioBuffer(Timer timer) {
    if (_audioBuffer.isEmpty) {
      return; // Wait for more data
    }
    
    // Process one chunk at a time
    final chunk = _audioBuffer.removeAt(0);
    _playAudioChunk(chunk);
    
    AppLogger.debug('🔊 Played chunk (${_audioBuffer.length} remaining)');
  }
  
  void _playAudioChunk(Uint8List audioData) {
    // Platform-specific audio playback would go here
    // For now, we're just optimizing the data flow
    AppLogger.debug('Playing ${audioData.length} bytes');
  }
  
  void _onStreamDone() {
    AppLogger.info('🏁 Audio stream completed');
    
    // Play remaining buffered audio
    _playbackTimer?.cancel();
    if (_audioBuffer.isNotEmpty) {
      AppLogger.info('🎵 Playing ${_audioBuffer.length} remaining chunks');
      for (final chunk in _audioBuffer) {
        _playAudioChunk(chunk);
      }
    }
    
    _stopPlayback();
  }
  
  void _onAudioError(error) {
    AppLogger.error('Audio stream error', error);
    _cleanup();
  }
  
  void _stopPlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _audioBuffer.clear();
    AppLogger.info('⏹️ Audio playback stopped');
  }
  
  void stopAudio() {
    _cleanup();
    AppLogger.info('🛑 Audio manually stopped');
  }
  
  void _cleanup() {
    _audioSubscription?.cancel();
    _audioSubscription = null;
    _stopPlayback();
  }
  
  bool get isPlaying => _isPlaying;
  int get bufferSize => _audioBuffer.length;
}