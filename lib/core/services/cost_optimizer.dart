import 'package:injectable/injectable.dart';
import '../utils/logger.dart';

@singleton
class CostOptimizer {
  // Track API usage for monitoring
  int _totalTokensUsed = 0;
  int _totalConnections = 0;
  int _messagesFiltered = 0;
  DateTime? _sessionStart;
  
  void startSession() {
    _sessionStart = DateTime.now();
    AppLogger.info('💰 Cost optimization session started');
  }
  
  void recordTokenUsage(int tokens) {
    _totalTokensUsed += tokens;
  }
  
  void recordConnection() {
    _totalConnections++;
  }
  
  void recordFilteredMessage() {
    _messagesFiltered++;
  }
  
  void endSession() {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!);
      AppLogger.info('''
💰 COST OPTIMIZATION SUMMARY:
   • Session duration: ${duration.inMinutes}min ${duration.inSeconds % 60}s
   • Total tokens used: $_totalTokensUsed (ultra-minimal prompts)
   • Connections made: $_totalConnections (on-demand only)
   • Messages filtered: $_messagesFiltered (smart filtering)
   • Estimated cost saved: ${_estimateSavings()}%
      ''');
    }
    
    _reset();
  }
  
  String _estimateSavings() {
    // Rough estimate based on optimizations
    final baselineMessages = _messagesFiltered + (_totalConnections * 2);
    final savingsPercent = (_messagesFiltered / (baselineMessages + 1) * 100).round();
    return savingsPercent.toString();
  }
  
  void _reset() {
    _totalTokensUsed = 0;
    _totalConnections = 0;
    _messagesFiltered = 0;
    _sessionStart = null;
  }
}