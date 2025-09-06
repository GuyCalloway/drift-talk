import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/voice_chat_bloc.dart';
import '../bloc/voice_chat_state.dart';
import '../bloc/voice_chat_event.dart';
import '../widgets/connection_status_widget.dart';
import '../../domain/repositories/voice_chat_repository.dart';
import '../../../../core/services/location_context_service.dart';
import '../../../../core/services/logo_selection_service.dart';
import '../../../../core/services/text_to_speech_service.dart';
import '../../../../core/services/mock_location_text_service.dart';
import '../../../../core/di/injection_container.dart';

class ScrollingTextItem {
  final int id;
  final String text;
  final AnimationController controller;
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;
  
  ScrollingTextItem({
    required this.id,
    required this.text,
    required this.controller,
    required this.slideAnimation,
    required this.fadeAnimation,
  });
}

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> with TickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  late AnimationController _speechController;
  late Animation<double> _speechAnimation;
  bool _showFlashText = false;
  String _flashMessage = '';
  Timer? _flashTimer;
  Timer? _homeReturnTimer;
  
  // Scrolling text system
  List<ScrollingTextItem> _scrollingTexts = [];
  int _nextTextId = 0;
  late final LocationContextService _locationService;
  late final LogoSelectionService _logoService;
  late final TextToSpeechService _ttsService;
  late final MockLocationTextService _mockLocationTextService;
  bool _isRefreshing = false;
  
  // Mode switching
  bool _isTTSMode = false;
  int _currentLocationIndex = 0;
  
  // Auto-fact interval selection
  int _selectedInterval = 30;
  final List<int> _intervalOptions = [15, 30, 45, 60, 120];
  Timer? _autoFactTimer;
  
  // TTS animation monitoring
  Timer? _ttsAnimationTimer;
  
  @override
  void initState() {
    super.initState();
    // Initialize services
    _locationService = getIt<LocationContextService>();
    _logoService = getIt<LogoSelectionService>();
    _ttsService = getIt<TextToSpeechService>();
    _mockLocationTextService = getIt<MockLocationTextService>();
    
    // Initialize connection
    context.read<VoiceChatBloc>().add(const VoiceChatConnectRequested());
    
    // Initialize flash animation
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
    
    // Initialize speech animation
    _speechController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _speechAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _speechController, curve: Curves.easeInOut),
    );
    
    // Start the auto-fact timer
    _startAutoFactTimer();
  }
  
  @override
  void dispose() {
    _flashController.dispose();
    _speechController.dispose();
    _flashTimer?.cancel();
    _homeReturnTimer?.cancel();
    _autoFactTimer?.cancel();
    _ttsAnimationTimer?.cancel();
    
    // Dispose scrolling text controllers
    for (var item in _scrollingTexts) {
      item.controller.dispose();
    }
    
    // Stop TTS service
    _ttsService.dispose();
    
    super.dispose();
  }
  
  void _showTemporaryFlash(String text, {bool returnToHome = false}) {
    setState(() {
      _showFlashText = true;
      _flashMessage = text;
    });
    
    _flashController.forward();
    
    // Auto-hide after 3 seconds
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _flashController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showFlashText = false;
              _flashMessage = '';
            });
            
            // Return to home screen if requested
            if (returnToHome) {
              _scheduleHomeReturn();
            }
          }
        });
      }
    });
  }
  
  void _scheduleHomeReturn() {
    _homeReturnTimer?.cancel();
    _homeReturnTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  void _startAutoFactTimer() {
    _autoFactTimer?.cancel();
    _autoFactTimer = Timer(Duration(seconds: _selectedInterval), () {
      if (mounted) {
        _triggerAutoFact();
      }
    });
  }
  
  void _resetAutoFactTimer() {
    _autoFactTimer?.cancel();
    _startAutoFactTimer();
  }
  
  void _startSpeechAnimation() {
    _speechController.repeat(reverse: true);
  }
  
  void _stopSpeechAnimation() {
    _speechController.stop();
    _speechController.reset();
  }
  
  void _startTTSAnimationMonitoring() {
    _ttsAnimationTimer?.cancel();
    _ttsAnimationTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final isTTSSpeaking = _ttsService.isSpeaking;
      
      // Control animation based on TTS state
      if (isTTSSpeaking && !_speechController.isAnimating) {
        _startSpeechAnimation();
      } else if (!isTTSSpeaking && _speechController.isAnimating) {
        // Only stop if AI is also not speaking
        final voiceChatState = context.read<VoiceChatBloc>().state;
        final isAISpeaking = voiceChatState is VoiceChatConnected && voiceChatState.isProcessingMessage;
        if (!isAISpeaking) {
          _stopSpeechAnimation();
        }
      }
    });
  }
  
  void _stopTTSAnimationMonitoring() {
    _ttsAnimationTimer?.cancel();
  }
  
  void _triggerAutoFact() {
    // Auto-trigger a new fact after the selected interval of pause
    _refreshLocationData();
    // Restart the timer for the next auto-fact
    _startAutoFactTimer();
  }
  
  void addScrollingText(String text) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    final slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));
    
    final item = ScrollingTextItem(
      id: _nextTextId++,
      text: text,
      controller: controller,
      slideAnimation: slideAnimation,
      fadeAnimation: fadeAnimation,
    );
    
    setState(() {
      _scrollingTexts.add(item);
    });
    
    // Start animation
    controller.forward();
    
    // Auto-remove after animation completes and a delay
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        controller.reverse().then((_) {
          if (mounted) {
            setState(() {
              _scrollingTexts.removeWhere((element) => element.id == item.id);
            });
            controller.dispose();
          }
        });
      }
    });
  }
  
  Future<void> _refreshLocationData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Get all locations and select one based on current index
      final allLocations = _locationService.getAllLocations();
      final selectedLocation = allLocations[_currentLocationIndex % allLocations.length];
      
      // Move to next location for future button presses
      _currentLocationIndex++;
      
      // Check if AI is currently speaking - if so, wrap up and queue the new message
      final voiceChatState = context.read<VoiceChatBloc>().state;
      final isCurrentlySpeaking = voiceChatState is VoiceChatConnected && voiceChatState.isProcessingMessage;
      
      if (isCurrentlySpeaking) {
        // Request wrap-up of current response
        context.read<VoiceChatBloc>().add(const VoiceChatWrapUpRequested());
      }
      
      // Send location context to voice chat for AI processing (will queue if busy)
      if (mounted) {
        final locationContext = _locationService.getLocationContextByName(selectedLocation.name);
        if (locationContext != null) {
          _sendLocationContextToAI(selectedLocation.name, _extractKeyFact(selectedLocation.talkingPoints));
        }
      }
    } catch (e) {
      // Handle error silently or show brief flash message
      if (mounted) {
        _showTemporaryFlash("Failed to load location data");
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  
  String _extractKeyFact(String talkingPoints) {
    // Extract the first sentence or up to 150 characters as a key fact
    final sentences = talkingPoints.split('. ');
    if (sentences.isNotEmpty && sentences[0].length <= 150) {
      return sentences[0] + '.';
    }
    
    // If first sentence is too long, truncate to 150 chars
    if (talkingPoints.length <= 150) {
      return talkingPoints;
    }
    
    final truncated = talkingPoints.substring(0, 147);
    final lastSpace = truncated.lastIndexOf(' ');
    return lastSpace > 100 ? truncated.substring(0, lastSpace) + '...' : truncated + '...';
  }
  
  void _sendLocationContextToAI(String locationName, String keyFact) {
    // Create a concise prompt for travelers exploring landmarks
    final locationContext = _locationService.getLocationContextByName(locationName);
    final prompt = "What makes $locationName worth visiting?";
    
    context.read<VoiceChatBloc>().add(
      VoiceChatMessageSent(
        message: prompt,
        context: locationContext,
      ),
    );
    
    // Reset the auto-fact timer whenever we send a message
    _resetAutoFactTimer();
  }
  
  void _handleVoiceInput() {
    // For now, simulate voice input that triggers a "continue" command
    // In production, this would process actual voice input
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _handleContinueCommand();
      }
    });
  }
  
  void _handleContinueCommand() {
    // Get current location and provide additional context
    final allLocations = _locationService.getAllLocations();
    final currentLocation = allLocations[(_currentLocationIndex - 1) % allLocations.length];
    
    // Send brief continue prompt to AI
    final continuePrompt = "What should travelers experience at ${currentLocation.name}?";
    
    context.read<VoiceChatBloc>().add(
      VoiceChatMessageSent(
        message: continuePrompt,
        context: _locationService.getLocationContextByName(currentLocation.name),
      ),
    );
    
    // Reset the auto-fact timer when user interacts
    _resetAutoFactTimer();
  }
  
  void _toggleMode(bool isTTSMode) {
    setState(() {
      _isTTSMode = isTTSMode;
    });
    
    if (isTTSMode) {
      // Switching to TTS mode: disconnect WebRTC and stop any current TTS
      context.read<VoiceChatBloc>().add(const VoiceChatDisconnectRequested());
      _ttsService.stop();
      _startTTSAnimationMonitoring();
      addScrollingText('Switched to TTS mode - AI disconnected');
    } else {
      // Switching to AI mode: stop TTS and reconnect WebRTC
      _ttsService.stop();
      _stopTTSAnimationMonitoring();
      context.read<VoiceChatBloc>().add(const VoiceChatConnectRequested());
      addScrollingText('Switched to AI mode - Reconnecting...');
    }
  }
  
  Future<void> _speakLocationText() async {
    addScrollingText('Fetching location data...');
    
    try {
      final locationData = await _mockLocationTextService.fetchLocationText();
      if (locationData == null) {
        addScrollingText('Failed to fetch location data');
        return;
      }
      
      addScrollingText('Reading about ${locationData.location}');
      final success = await _ttsService.speak(locationData.textContent);
      
      if (!success) {
        addScrollingText('Failed to speak text');
      }
    } catch (e) {
      addScrollingText('Error fetching location data');
    }
  }
  
  void _handleCentralButtonPress() {
    if (_isTTSMode) {
      // In TTS mode, fetch and speak location-based text
      _speakLocationText();
    } else {
      // In AI mode, use the original behavior (refresh location data)
      _refreshLocationData();
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        leading: BlocBuilder<VoiceChatBloc, VoiceChatState>(
          builder: (context, state) {
            final isConnected = _isConnected(state);
            return GestureDetector(
              onTap: isConnected ? _handleVoiceInput : null,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.3),
                  boxShadow: isConnected ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Drift',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Brush Script MT, cursive',
              ),
            ),
                BlocBuilder<VoiceChatBloc, VoiceChatState>(
                  builder: (context, state) {
                    final status = _getConnectionStatus(state);
                    final statusText = _getStatusText(status);
                    final statusColor = _getStatusColor(status, theme);
                    
                    return Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
        ),
        actions: [
          // Mode toggle switch
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isTTSMode ? 'TTS' : 'AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _isTTSMode,
                    onChanged: (value) => _toggleMode(value),
                    activeColor: theme.colorScheme.primary,
                    inactiveThumbColor: theme.colorScheme.primary.withOpacity(0.5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<VoiceChatBloc, VoiceChatState>(
            builder: (context, state) {
              return ConnectionStatusWidget(
                connectionStatus: _getConnectionStatus(state),
                onToggleConnection: () => _toggleConnection(context, state),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Main content - Clean minimal design with speech animation
          Center(
            child: BlocListener<VoiceChatBloc, VoiceChatState>(
              listener: (context, state) {
                // Control speech animation based on AI speaking state
                if (state is VoiceChatConnected && state.isProcessingMessage) {
                  _startSpeechAnimation();
                } else {
                  _stopSpeechAnimation();
                }
              },
              child: AnimatedBuilder(
                animation: _speechAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _speechAnimation.value,
                    child: GestureDetector(
                      onTap: _handleCentralButtonPress,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Pure white background
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              _logoService.selectedLogoPath,
                              fit: BoxFit.contain, // Show full image without cropping
                              width: 280,
                              height: 280,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Duration dropdown in bottom left
          Positioned(
            bottom: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: DropdownButton<int>(
                value: _selectedInterval,
                items: _intervalOptions.map((interval) {
                  return DropdownMenuItem<int>(
                    value: interval,
                    child: Text(
                      '${interval}s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedInterval = value;
                    });
                    // Restart the timer with the new interval
                    _resetAutoFactTimer();
                  }
                },
                underline: Container(),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                dropdownColor: theme.colorScheme.surface,
              ),
            ),
          ),
          
          // Error handling
          BlocListener<VoiceChatBloc, VoiceChatState>(
            listener: (context, state) {
              if (state is VoiceChatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onError,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(state.message)),
                      ],
                    ),
                    backgroundColor: theme.colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const SizedBox.shrink(),
          ),
          
          // Flash overlay
          if (_showFlashText)
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _flashAnimation.value,
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _flashMessage,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  ConnectionStatus _getConnectionStatus(VoiceChatState state) {
    if (state is VoiceChatConnected) {
      return state.connectionStatus;
    } else if (state is VoiceChatDisconnected) {
      return ConnectionStatus.disconnected;
    } else if (state is VoiceChatError) {
      return ConnectionStatus.error;
    } else if (state is VoiceChatLoading) {
      return ConnectionStatus.connecting;
    }
    return ConnectionStatus.disconnected;
  }


  bool _isConnected(VoiceChatState state) {
    return state is VoiceChatConnected;
  }

  void _toggleConnection(BuildContext context, VoiceChatState state) {
    if (_isConnected(state)) {
      context.read<VoiceChatBloc>().add(const VoiceChatDisconnectRequested());
    } else {
      context.read<VoiceChatBloc>().add(const VoiceChatConnectRequested());
    }
  }


  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  Color _getStatusColor(ConnectionStatus status, ThemeData theme) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.reconnecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return theme.colorScheme.onSurface.withOpacity(0.5);
      case ConnectionStatus.error:
        return Colors.red;
    }
  }
}