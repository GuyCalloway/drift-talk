import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';

import '../utils/logger.dart';
import '../errors/exceptions.dart';

enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
  closed,
}

@singleton
class WebRTCClient {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCVideoRenderer? _remoteRenderer;
  
  final StreamController<WebRTCConnectionState> _connectionController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  
  final Dio _dio = Dio();
  String? _callId;
  
  // Safeguards
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  Timer? _connectionTimeout;

  Stream<WebRTCConnectionState> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  String? get callId => _callId;
  bool get isConnected => _peerConnection?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  Future<void> connect(String apiKey) async {
    // Safeguard 1: Prevent multiple simultaneous connections
    if (_isConnecting) {
      AppLogger.info('🛡️ Connection already in progress, ignoring duplicate request');
      return;
    }
    
    if (isConnected) {
      AppLogger.info('🛡️ Already connected, ignoring duplicate request');
      return;
    }
    
    _isConnecting = true;
    
    // Safeguard 5: Connection timeout protection
    _connectionTimeout = Timer(const Duration(seconds: 30), () {
      if (_isConnecting) {
        AppLogger.error('🛡️ Connection timeout after 30 seconds');
        _isConnecting = false;
        _connectionController.add(WebRTCConnectionState.failed);
        disconnect(); // Cleanup partial connection
      }
    });
    
    try {
      _connectionController.add(WebRTCConnectionState.connecting);
      AppLogger.info('Starting WebRTC connection to OpenAI Realtime API');

      // 1. Initialize remote audio renderer
      await _initializeAudioRenderer();

      // 2. Create RTCPeerConnection
      await _createPeerConnection();

      // 3. Get user media (audio only)
      await _getUserMedia();

      // 4. Create data channel for messaging
      await _createDataChannel();

      // 5. Create offer and connect to OpenAI
      await _createOfferAndConnect(apiKey);

      AppLogger.info('WebRTC connection established successfully');
    } catch (e) {
      AppLogger.error('Failed to establish WebRTC connection', e);
      _connectionController.add(WebRTCConnectionState.failed);
      rethrow;
    } finally {
      _connectionTimeout?.cancel();
      _connectionTimeout = null;
      _isConnecting = false;
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      AppLogger.info('WebRTC connection state: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _connectionController.add(WebRTCConnectionState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _connectionController.add(WebRTCConnectionState.failed);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _connectionController.add(WebRTCConnectionState.closed);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      AppLogger.debug('ICE candidate: ${candidate.candidate}');
      // ICE candidates are handled automatically with the SDP offer
    };

    // Use ONLY the modern onTrack handler to prevent duplicate audio
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      AppLogger.info('🎵 Received WebRTC track: ${event.track.kind} (${event.track.id})');
      if (event.track.kind == 'audio') {
        if (event.streams.isNotEmpty) {
          AppLogger.info('🔊 Setting up SINGLE audio stream - preventing duplicates');
          _cleanupPreviousAudio(); // Cleanup any existing audio first
          _remoteStream = event.streams.first;
          _setupAudioPlayback();
        }
      }
    };
  }

  Future<void> _getUserMedia() async {
    final constraints = <String, dynamic>{
      'audio': {
        'sampleRate': 24000,
        'channelCount': 1,
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    
    // Add audio track to peer connection
    _localStream!.getAudioTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    AppLogger.info('Local media stream acquired');
  }

  Future<void> _createDataChannel() async {
    final dataChannelDict = RTCDataChannelInit();
    dataChannelDict.ordered = true;
    
    _dataChannel = await _peerConnection!.createDataChannel('messages', dataChannelDict);
    
    _dataChannel!.onDataChannelState = (RTCDataChannelState state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        AppLogger.info('Data channel opened');
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        AppLogger.info('Data channel closed');
      }
    };
    
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      try {
        final data = json.decode(message.text);
        _messageController.add(data);
        AppLogger.debug('Received message: $data');
      } catch (e) {
        AppLogger.error('Failed to parse data channel message', e);
      }
    };
  }

  Future<void> _createOfferAndConnect(String apiKey) async {
    // Create SDP offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send offer to OpenAI Realtime API
    const baseUrl = 'https://api.openai.com/v1/realtime/calls';
    const model = 'gpt-realtime';
    
    final response = await _dio.post(
      '$baseUrl?model=$model',
      data: offer.sdp,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/sdp',
        },
      ),
    );

    // Extract call ID from Location header
    final location = response.headers.value('location');
    _callId = location?.split('/').last;
    AppLogger.info('Call ID: $_callId');

    // Set remote description from response
    final answerSdp = response.data as String;
    final answer = RTCSessionDescription(answerSdp, 'answer');
    await _peerConnection!.setRemoteDescription(answer);

    AppLogger.info('WebRTC offer/answer exchange completed');
  }

  void sendMessage(Map<String, dynamic> message) {
    // Safeguard 3: Validate connection state before sending
    if (_dataChannel?.state != RTCDataChannelState.RTCDataChannelOpen) {
      AppLogger.error('🛡️ Cannot send message: Data channel not open (state: ${_dataChannel?.state})');
      throw WebSocketException('Data channel not open');
    }
    
    if (_isDisconnecting || _isConnecting) {
      AppLogger.error('🛡️ Cannot send message: Connection in transition state');
      throw WebSocketException('Connection in transition');
    }
    
    try {
      final messageText = json.encode(message);
      final rtcMessage = RTCDataChannelMessage(messageText);
      _dataChannel!.send(rtcMessage);
      AppLogger.debug('Sent message: $message');
    } catch (e) {
      AppLogger.error('Failed to send message', e);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    // Safeguard 2: Prevent multiple simultaneous disconnections
    if (_isDisconnecting) {
      AppLogger.info('🛡️ Disconnect already in progress, ignoring duplicate request');
      return;
    }
    
    if (!isConnected && _peerConnection == null) {
      AppLogger.info('🛡️ Already disconnected, ignoring duplicate request');
      return;
    }
    
    _isDisconnecting = true;
    
    try {
      _connectionController.add(WebRTCConnectionState.disconnected);
      
      // Clean up audio first to prevent lingering playback
      _cleanupPreviousAudio();
      
      // Close data channel
      _dataChannel?.close();
      _dataChannel = null;

      // Stop local stream
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      _callId = null;
      AppLogger.info('WebRTC connection closed - all audio cleaned up');
    } catch (e) {
      AppLogger.error('Error during WebRTC disconnect', e);
    } finally {
      _isDisconnecting = false;
    }
  }

  Future<void> _initializeAudioRenderer() async {
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
    AppLogger.info('Remote audio renderer initialized');
  }

  void _cleanupPreviousAudio() {
    if (_remoteRenderer?.srcObject != null) {
      AppLogger.info('🧹 Cleaning up previous audio stream to prevent duplicates');
      _remoteRenderer!.srcObject = null;
    }
    
    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) {
        track.enabled = false;
        track.stop();
      });
      _remoteStream!.dispose();
      _remoteStream = null;
    }
  }

  void _setupAudioPlayback() async {
    if (_remoteStream != null && _remoteRenderer != null) {
      _remoteRenderer!.srcObject = _remoteStream;
      AppLogger.info('✅ Audio playback setup completed - remote stream has ${_remoteStream!.getAudioTracks().length} audio tracks');
      
      // For web, ensure audio playback by setting autoplay
      final audioTracks = _remoteStream!.getAudioTracks();
      for (final track in audioTracks) {
        AppLogger.info('Audio track: ${track.id}, enabled: ${track.enabled}, kind: ${track.kind}');
        track.enabled = true;
      }
    }
  }

  void dispose() {
    // Safeguard 4: Safe disposal with proper cleanup order
    AppLogger.info('🛡️ Disposing WebRTC client - cleaning up all resources');
    
    try {
      // Disconnect if still connected
      if (isConnected || _peerConnection != null) {
        disconnect();
      }
      
      // Clean up renderer
      _remoteRenderer?.dispose();
      _remoteRenderer = null;
      
      // Close controllers if not already closed
      if (!_connectionController.isClosed) {
        _connectionController.close();
      }
      if (!_messageController.isClosed) {
        _messageController.close();
      }
      
      AppLogger.info('✅ WebRTC client disposed successfully');
    } catch (e) {
      AppLogger.error('Error during WebRTC client disposal', e);
    }
  }
}