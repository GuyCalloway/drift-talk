import 'dart:async';
import 'package:injectable/injectable.dart';
import '../utils/logger.dart';
import 'webrtc_client.dart';

@singleton
class ConnectionManager {
  final WebRTCClient _webRTCClient;
  Timer? _idleTimer;
  static const _idleTimeout = Duration(seconds: 30); // Disconnect after 30s idle
  
  bool _isConnected = false;
  String? _lastApiKey;
  
  ConnectionManager(this._webRTCClient);
  
  Future<void> ensureConnection(String apiKey) async {
    _lastApiKey = apiKey;
    
    // Cancel idle timer since we're about to use connection
    _idleTimer?.cancel();
    _idleTimer = null;
    
    if (!_isConnected) {
      await _webRTCClient.connect(apiKey);
      _isConnected = true;
      AppLogger.info('🔌 Connected on-demand');
    }
  }
  
  void scheduleDisconnect() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () async {
      if (_isConnected) {
        await _webRTCClient.disconnect();
        _isConnected = false;
        AppLogger.info('💤 Disconnected after idle timeout');
      }
    });
    AppLogger.info('⏰ Scheduled disconnect in ${_idleTimeout.inSeconds}s');
  }
  
  Future<void> forceDisconnect() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    
    if (_isConnected) {
      await _webRTCClient.disconnect();
      _isConnected = false;
      AppLogger.info('🔌 Force disconnected');
    }
  }
  
  bool get isConnected => _isConnected && _webRTCClient.isConnected;
}