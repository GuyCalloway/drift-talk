import 'package:injectable/injectable.dart';

import '../../features/voice_chat/domain/entities/voice_message.dart';
import '../utils/logger.dart';

@singleton
class ConversationSummarizer {
  static const int _maxSummaryLength = 80; // Keep summary very short for token efficiency
  static const int _maxRecentMessages = 6; // Last 3 exchanges (user + assistant pairs)

  /// Create a concise summary of recent conversation for context building
  String summarizeRecentHistory(List<VoiceMessage> messages) {
    if (messages.isEmpty) return '';
    
    try {
      // Get only recent messages to keep context relevant
      final recentMessages = messages.length > _maxRecentMessages 
          ? messages.sublist(messages.length - _maxRecentMessages)
          : messages;
      
      final locations = _extractLocations(recentMessages);
      final themes = _extractKeyThemes(recentMessages);
      
      // Build ultra-concise summary
      final parts = <String>[];
      
      if (locations.isNotEmpty) {
        parts.add('Discussed: ${locations.take(2).join(', ')}');
      }
      
      if (themes.isNotEmpty) {
        parts.add('Topics: ${themes.take(2).join(', ')}');
      }
      
      final summary = parts.join('. ');
      
      // Ensure we stay within token limits
      final truncatedSummary = summary.length > _maxSummaryLength 
          ? '${summary.substring(0, _maxSummaryLength - 3)}...'
          : summary;
      
      AppLogger.debug('📝 Conversation summary: "$truncatedSummary"');
      return truncatedSummary;
      
    } catch (e) {
      AppLogger.error('Failed to summarize conversation history', e);
      return '';
    }
  }

  /// Extract location names from conversation messages
  Set<String> _extractLocations(List<VoiceMessage> messages) {
    final locations = <String>{};
    
    for (final message in messages) {
      final content = message.content.toLowerCase();
      
      // Look for common location indicators
      final locationPatterns = [
        // Direct location mentions
        RegExp(r'\b(monument|borough|southwark|george|guy|marshalsea|lant|trinity)\b'),
        // Location types
        RegExp(r'\b(church|market|inn|prison|hospital|bridge|station)\b'),
        // Street/place indicators
        RegExp(r'\b(street|yard|square|place|cathedral|steps)\b'),
      ];
      
      for (final pattern in locationPatterns) {
        final matches = pattern.allMatches(content);
        for (final match in matches) {
          final location = match.group(0);
          if (location != null && location.length > 3) {
            locations.add(_capitalizeFirst(location));
          }
        }
      }
    }
    
    return locations;
  }

  /// Extract key themes and topics from conversation
  Set<String> _extractKeyThemes(List<VoiceMessage> messages) {
    final themes = <String>{};
    
    for (final message in messages) {
      final content = message.content.toLowerCase();
      
      // Look for thematic keywords
      final themePatterns = {
        'dickens': RegExp(r'\b(dickens|charles|novelist|author|writer)\b'),
        'history': RegExp(r'\b(history|historical|century|past|old|ancient)\b'),
        'literature': RegExp(r'\b(novel|book|story|character|writing)\b'),
        'architecture': RegExp(r'\b(building|church|gothic|wren|design)\b'),
        'social': RegExp(r'\b(prison|poor|society|victorian|conditions)\b'),
        'commerce': RegExp(r'\b(market|trade|merchant|business|shop)\b'),
      };
      
      for (final entry in themePatterns.entries) {
        if (entry.value.hasMatch(content)) {
          themes.add(entry.key);
        }
      }
    }
    
    return themes;
  }

  /// Get conversation flow indicators for natural transitions
  String getConversationFlow(List<VoiceMessage> messages) {
    if (messages.length < 2) return '';
    
    try {
      final lastUserMessage = messages
          .where((m) => m.type == MessageType.user)
          .lastOrNull;
      
      final lastAssistantMessage = messages
          .where((m) => m.type == MessageType.assistant)
          .lastOrNull;
      
      if (lastUserMessage == null || lastAssistantMessage == null) return '';
      
      // Determine conversation flow type
      final userContent = lastUserMessage.content.toLowerCase();
      final assistantContent = lastAssistantMessage.content.toLowerCase();
      
      // Check if last AI response was a landmark prompt (ended with "look for" or "notice")
      final wasLandmarkPrompt = assistantContent.contains('look for') || 
                               assistantContent.contains('notice') ||
                               assistantContent.contains('spot the') ||
                               assistantContent.contains('find the');
      
      if (wasLandmarkPrompt && (userContent.contains('found') || userContent.contains('see') || userContent.contains('spotted'))) {
        return 'Landmark confirmed';
      } else if (userContent.contains('continue') || userContent.contains('more') || userContent.contains('tell me')) {
        return 'Want more details';
      } else if (userContent.contains('what') && userContent.contains('visiting')) {
        return 'New location';
      } else if (wasLandmarkPrompt) {
        return 'Awaiting landmark confirmation';
      } else {
        return 'Exploring';
      }
      
    } catch (e) {
      AppLogger.error('Failed to determine conversation flow', e);
      return '';
    }
  }

  /// Build context-aware prompt that includes conversation history
  String buildContextWithHistory(
    String baseContext,
    String currentMessage,
    List<VoiceMessage> messages,
  ) {
    final summary = summarizeRecentHistory(messages);
    final flow = getConversationFlow(messages);
    
    // For landmark-focused interactions, keep it very concise
    if (flow == 'New location') {
      // First visit to a location - give landmark spotting prompt
      final locationOnly = _extractLocationName(baseContext);
      return 'Location: $locationOnly\n\nGive landmark to look for. End with "Look for..." then stop.';
    } else if (flow == 'Want more details' || flow == 'Landmark confirmed') {
      // User wants more info after seeing landmark
      return '$baseContext\n\nPrevious: $summary\nFlow: User ready for details\n\nProvide brief historical context.';
    } else if (flow == 'Awaiting landmark confirmation') {
      // Don't send new request if AI already asked to look for something
      return 'Wait for user to confirm they found the landmark or ask for help.';
    }
    
    // Default context building for other cases
    if (summary.isEmpty && flow.isEmpty) {
      return baseContext.isNotEmpty ? '$baseContext\n\n$currentMessage' : currentMessage;
    }
    
    final contextParts = <String>[];
    
    if (baseContext.isNotEmpty) {
      // Extract just the location name for conciseness
      final locationName = _extractLocationName(baseContext);
      contextParts.add('Location: $locationName');
    }
    
    if (summary.isNotEmpty) {
      contextParts.add('Previous: $summary');
    }
    
    if (flow.isNotEmpty) {
      contextParts.add('Flow: $flow');
    }
    
    contextParts.add('Give one landmark to spot. End with "Look for..." then stop.');
    
    final fullContext = contextParts.join('\n\n');
    
    AppLogger.debug('🧠 Built context with history (${fullContext.length} chars)');
    return fullContext;
  }

  /// Extract just the location name from full context
  String _extractLocationName(String fullContext) {
    // Look for "Current Location: [Name]" pattern
    final locationMatch = RegExp(r'Current Location: ([^\n]+)').firstMatch(fullContext);
    if (locationMatch != null) {
      return locationMatch.group(1) ?? 'Unknown Location';
    }
    
    // Look for "Location: [Name]" pattern  
    final simpleMatch = RegExp(r'Location: ([^\n]+)').firstMatch(fullContext);
    if (simpleMatch != null) {
      return simpleMatch.group(1) ?? 'Unknown Location';
    }
    
    // Fallback - try to extract location from first line
    final lines = fullContext.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.isNotEmpty && !firstLine.startsWith('Context:')) {
        return firstLine.replaceFirst('Current Location:', '').trim();
      }
    }
    
    return 'This location';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

extension _ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}