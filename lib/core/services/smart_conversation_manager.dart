import 'dart:async';
import 'package:injectable/injectable.dart';
import '../utils/logger.dart';

@singleton
class SmartConversationManager {
  // Track interesting topics to avoid repetition
  final Set<String> _spokenTopics = {};
  final List<String> _contextKeywords = [];
  
  static const _minTimeBetweenResponses = Duration(seconds: 10);
  DateTime? _lastResponseTime;
  
  // Extract key talking points from context
  void setContext(String context) {
    _contextKeywords.clear();
    _spokenTopics.clear();
    
    // Extract potential interesting keywords/topics
    final keywords = _extractKeywords(context);
    _contextKeywords.addAll(keywords);
    AppLogger.info('🧠 Context loaded with ${keywords.length} key topics');
  }
  
  // Decide if we should respond to this prompt
  bool shouldRespond(String userPrompt) {
    final now = DateTime.now();
    
    // Rate limiting - don't respond too frequently
    if (_lastResponseTime != null && 
        now.difference(_lastResponseTime!) < _minTimeBetweenResponses) {
      AppLogger.info('⏳ Rate limited - too soon since last response');
      return false;
    }
    
    // Check if this relates to our context keywords
    final prompt = userPrompt.toLowerCase();
    final hasRelevantKeyword = _contextKeywords.any(
      (keyword) => prompt.contains(keyword.toLowerCase())
    );
    
    // Direct questions always get response
    final isDirectQuestion = _isDirectQuestion(prompt);
    
    // Check if we've already covered this topic
    final topicAlreadyCovered = _spokenTopics.any(
      (topic) => prompt.contains(topic.toLowerCase())
    );
    
    if (isDirectQuestion) {
      AppLogger.info('❓ Direct question detected - will respond');
      return true;
    }
    
    if (hasRelevantKeyword && !topicAlreadyCovered) {
      AppLogger.info('💡 Relevant new topic detected - will respond');
      return true;
    }
    
    AppLogger.info('🔇 Not responding - irrelevant or already covered');
    return false;
  }
  
  // Get optimized prompt that focuses on specific points
  String optimizePrompt(String originalPrompt, String? context) {
    // Find the most specific/interesting part of the prompt
    final focusedPrompt = _extractMostInteresting(originalPrompt);
    
    // Add context only if it's short and relevant
    if (context != null && context.length < 200) {
      return '$context\n\nFocus: $focusedPrompt';
    }
    
    return focusedPrompt;
  }
  
  void markTopicCovered(String topic) {
    _spokenTopics.add(topic.toLowerCase());
    _lastResponseTime = DateTime.now();
    AppLogger.info('✅ Topic marked as covered: $topic');
  }
  
  List<String> _extractKeywords(String context) {
    // Simple keyword extraction - could be enhanced with NLP
    final words = context
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((w) => w.length > 4)  // Only longer words
        .toList();
    
    // Remove common words
    const commonWords = {
      'that', 'this', 'with', 'have', 'will', 'from', 'they', 'been', 
      'said', 'each', 'which', 'their', 'would', 'there', 'could'
    };
    
    return words.where((w) => !commonWords.contains(w)).take(10).toList();
  }
  
  bool _isDirectQuestion(String prompt) {
    return prompt.contains('?') || 
           prompt.startsWith(RegExp(r'(what|how|why|when|where|who|tell|explain)', 
                                  caseSensitive: false));
  }
  
  String _extractMostInteresting(String prompt) {
    // Look for superlatives, numbers, specific nouns - signs of interesting content
    final sentences = prompt.split(RegExp(r'[.!?]'));
    
    for (final sentence in sentences) {
      if (sentence.contains(RegExp(r'(most|best|worst|first|last|\d+|amazing|incredible|unique)', 
                                  caseSensitive: false))) {
        return sentence.trim();
      }
    }
    
    // Fallback to first sentence if nothing interesting found
    return sentences.isNotEmpty ? sentences.first.trim() : prompt;
  }
}