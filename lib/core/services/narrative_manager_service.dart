import 'dart:async';
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../utils/logger.dart';
import 'location_context_service.dart';

/// User movement patterns for adaptive storytelling
enum MovementPattern {
  slowWandering("Thorough explorer - interested in hidden details"),
  balancedExploration("Casual visitor - wants highlights and interesting discoveries"),
  directMovement("Focused traveler - heading to specific destinations");
  
  const MovementPattern(this.description);
  final String description;
}

/// User familiarity level for content depth adjustment
enum FamiliarityLevel {
  local("Local resident - skip obvious facts, focus on hidden stories"),
  repeatVisitor("Returning visitor - alternative perspectives and deeper insights"),
  tourist("First-time visitor - foundational context and cultural translation");
  
  const FamiliarityLevel(this.description);
  final String description;
}

/// Voice character roles for dual AI system
enum VoiceRole {
  analytical("Female voice - serious, historical context, analytical insights"),
  narrative("Male voice - light, humorous, surprising facts, storytelling");
  
  const VoiceRole(this.description);
  final String description;
}

/// Manages narrative flow using cinematic montage theory and gravitational field system
/// Implements the "no wrong way" philosophy with adaptive storytelling
/// Supports configurable keyword extraction for different content types
@lazySingleton
class NarrativeManagerService {
  final LocationContextService _locationService;
  
  // User profile for adaptive content
  MovementPattern _currentMovementPattern = MovementPattern.balancedExploration;
  FamiliarityLevel _userFamiliarity = FamiliarityLevel.tourist;
  
  // Configurable keywords for content adaptation
  List<String>? _customWideShotKeywords;
  List<String>? _customMediumShotKeywords;
  int? _customCloseUpSentenceCount;
  
  // Narrative state tracking
  final Set<int> _mentionedLocations = {};
  final Map<int, DateTime> _locationVisitTimes = {};
  NarrativeLayer _lastNarrativeLayer = NarrativeLayer.wideShot;
  
  // Voice alternation for dual AI system
  VoiceRole _nextVoiceRole = VoiceRole.analytical;
  
  NarrativeManagerService(this._locationService);
  
  /// Set user familiarity level for content adaptation
  void setUserFamiliarity(FamiliarityLevel level) {
    _userFamiliarity = level;
    AppLogger.info('🎯 User familiarity set to: ${level.description}');
  }
  
  /// Update movement pattern based on user behavior
  void updateMovementPattern(MovementPattern pattern) {
    _currentMovementPattern = pattern;
    AppLogger.info('🚶 Movement pattern updated: ${pattern.description}');
  }
  
  /// Configure custom keywords for content-specific narrative extraction
  /// Useful for different cities, themes, or content types
  void configureContentKeywords({
    List<String>? wideShotKeywords,
    List<String>? mediumShotKeywords, 
    int? closeUpSentenceCount,
  }) {
    _customWideShotKeywords = wideShotKeywords;
    _customMediumShotKeywords = mediumShotKeywords;
    _customCloseUpSentenceCount = closeUpSentenceCount;
    
    AppLogger.info('🔧 Narrative keywords configured:');
    if (wideShotKeywords != null) {
      AppLogger.info('   Wide shot: ${wideShotKeywords.take(3).join(", ")}${wideShotKeywords.length > 3 ? "..." : ""}');
    }
    if (mediumShotKeywords != null) {
      AppLogger.info('   Medium shot: ${mediumShotKeywords.take(3).join(", ")}${mediumShotKeywords.length > 3 ? "..." : ""}');
    }
    if (closeUpSentenceCount != null) {
      AppLogger.info('   Close-up: $closeUpSentenceCount sentences');
    }
  }
  
  /// Get contextual narrative for a location using montage theory
  /// Alternates between wide, medium, and close-up shots for visual variety
  NarrativeContent generateLocationNarrative(LocationData location, {
    LocationData? previousLocation,
    LocationData? nextSuggestedLocation,
  }) {
    final currentLayer = _selectNarrativeLayer(location, previousLocation);
    final voiceRole = _selectVoiceRole(currentLayer);
    
    final narrative = _buildNarrativeContent(
      location, 
      currentLayer, 
      voiceRole,
      previousLocation: previousLocation,
      nextLocation: nextSuggestedLocation,
    );
    
    _updateNarrativeState(location, currentLayer);
    
    return narrative;
  }
  
  /// Select appropriate narrative layer following montage theory
  NarrativeLayer _selectNarrativeLayer(LocationData location, LocationData? previousLocation) {
    // Avoid sequential close-ups (creates chaos)
    if (_lastNarrativeLayer == NarrativeLayer.closeUp) {
      return NarrativeLayer.mediumShot;
    }
    
    // Use wide shot for district transitions or high-gravity locations
    if (previousLocation != null && previousLocation.district != location.district) {
      return NarrativeLayer.wideShot;
    }
    
    // Use close-up for essential locations that warrant detail
    if (location.gravity.value >= 8) {
      return NarrativeLayer.closeUp;
    }
    
    // Default to medium shot for connections and flow
    return NarrativeLayer.mediumShot;
  }
  
  /// Select voice role based on content type and alternation
  VoiceRole _selectVoiceRole(NarrativeLayer layer) {
    VoiceRole selectedRole;
    
    switch (layer) {
      case NarrativeLayer.wideShot:
        // Analytical voice for historical context
        selectedRole = VoiceRole.analytical;
        break;
      case NarrativeLayer.mediumShot:
        // Alternate for variety in connections
        selectedRole = _nextVoiceRole;
        break;
      case NarrativeLayer.closeUp:
        // Narrative voice for intimate details
        selectedRole = VoiceRole.narrative;
        break;
    }
    
    // Alternate for next time
    _nextVoiceRole = selectedRole == VoiceRole.analytical 
        ? VoiceRole.narrative 
        : VoiceRole.analytical;
    
    return selectedRole;
  }
  
  /// Build narrative content based on user familiarity and movement pattern
  NarrativeContent _buildNarrativeContent(
    LocationData location,
    NarrativeLayer layer,
    VoiceRole voiceRole, {
    LocationData? previousLocation,
    LocationData? nextLocation,
  }) {
    // Use custom keywords if configured
    String content = location.getNarrativeForLayer(
      layer,
      wideShotKeywords: _customWideShotKeywords,
      mediumShotKeywords: _customMediumShotKeywords,
      closeUpSentenceCount: _customCloseUpSentenceCount,
    ) ?? location.talkingPoints;
    
    // Adjust content depth based on user familiarity
    content = _adjustContentForFamiliarity(content, location);
    
    // Add connecting phrases for medium shots
    if (layer == NarrativeLayer.mediumShot && previousLocation != null) {
      content = _addConnectionContext(content, previousLocation, location);
    }
    
    // Add suggestions for nearby locations based on movement pattern
    final suggestions = _generateLocationSuggestions(location);
    
    return NarrativeContent(
      text: content,
      layer: layer,
      voiceRole: voiceRole,
      gravity: location.gravity,
      suggestions: suggestions,
      connectionContext: previousLocation?.name,
    );
  }
  
  /// Adjust content depth based on user's familiarity level
  String _adjustContentForFamiliarity(String content, LocationData location) {
    switch (_userFamiliarity) {
      case FamiliarityLevel.local:
        // Focus on hidden stories, skip obvious facts
        return _extractHiddenStories(content);
      case FamiliarityLevel.repeatVisitor:
        // Provide alternative perspectives
        return _addAlternativePerspective(content, location);
      case FamiliarityLevel.tourist:
        // Full context with cultural translation
        return content; // Use full content
    }
  }
  
  /// Extract hidden stories and lesser-known facts
  String _extractHiddenStories(String content) {
    final sentences = content.split('. ');
    // Find sentences with surprising or hidden details
    return sentences.where((sentence) => 
      sentence.contains('hidden') ||
      sentence.contains('secret') ||
      sentence.contains('few know') ||
      sentence.contains('surprisingly') ||
      sentence.contains('actually')
    ).join('. ');
  }
  
  /// Add alternative perspective for repeat visitors
  String _addAlternativePerspective(String content, LocationData location) {
    final perspectives = [
      "From another angle: ",
      "What's often overlooked: ",
      "A different perspective: ",
      "Here's something interesting: ",
    ];
    final prefix = perspectives[Random().nextInt(perspectives.length)];
    return "$prefix$content";
  }
  
  /// Add connecting context between locations for narrative flow
  String _addConnectionContext(String content, LocationData from, LocationData to) {
    final connections = [
      "Moving from ${from.name}, ${to.name} connects to this story because...",
      "The journey from ${from.name} brings us to ${to.name}, where...",
      "As we transition from ${from.name}, ${to.name} reveals...",
      "Building on what we discovered at ${from.name}, ${to.name} shows...",
    ];
    
    final connector = connections[Random().nextInt(connections.length)];
    return "$connector $content";
  }
  
  /// Generate location suggestions based on gravitational field and movement pattern
  List<LocationSuggestion> _generateLocationSuggestions(LocationData currentLocation) {
    final allLocations = _locationService.getAllLocations();
    final suggestions = <LocationSuggestion>[];
    
    for (final location in allLocations) {
      if (location.id == currentLocation.id) continue;
      
      // Check if location should be mentioned based on movement pattern
      if (!location.shouldMentionForExploration(
        isSlowWandering: _currentMovementPattern == MovementPattern.slowWandering,
        isDirectMovement: _currentMovementPattern == MovementPattern.directMovement,
      )) continue;
      
      // Calculate distance (simple euclidean for demo)
      final distance = _calculateDistance(
        currentLocation.lat, currentLocation.lng,
        location.lat, location.lng,
      );
      
      // Add suggestion with context
      suggestions.add(LocationSuggestion(
        location: location,
        distance: distance,
        reason: _getSuggestionReason(location, currentLocation),
      ));
    }
    
    // Sort by gravity and distance
    suggestions.sort((a, b) {
      final gravityComparison = b.location.gravity.value.compareTo(a.location.gravity.value);
      if (gravityComparison != 0) return gravityComparison;
      return a.distance.compareTo(b.distance);
    });
    
    return suggestions.take(3).toList();
  }
  
  /// Get reason for suggesting a location
  String _getSuggestionReason(LocationData suggested, LocationData current) {
    if (suggested.connectedLocationIds.contains(current.id)) {
      return "Connected to ${current.name} by ${suggested.district}";
    }
    
    if (suggested.district == current.district) {
      return "In the same ${suggested.district} area";
    }
    
    switch (suggested.gravity) {
      case GravityLevel.essential:
      case GravityLevel.landmark:
        return "Essential landmark worth the journey";
      case GravityLevel.exceptional:
      case GravityLevel.major:
        return "Major attraction nearby";
      default:
        return "Interesting discovery if you're wandering";
    }
  }
  
  /// Calculate simple distance between two points (for demo purposes)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return ((lat2 - lat1) * (lat2 - lat1) + (lng2 - lng1) * (lng2 - lng1));
  }
  
  /// Update internal narrative state
  void _updateNarrativeState(LocationData location, NarrativeLayer layer) {
    _mentionedLocations.add(location.id);
    _locationVisitTimes[location.id] = DateTime.now();
    _lastNarrativeLayer = layer;
    
    AppLogger.info('🎬 Narrative: ${layer.name} shot for ${location.name} (gravity: ${location.gravity.value})');
  }
  
  /// Reset narrative state for new session
  void resetNarrativeState() {
    _mentionedLocations.clear();
    _locationVisitTimes.clear();
    _lastNarrativeLayer = NarrativeLayer.wideShot;
    _nextVoiceRole = VoiceRole.analytical;
    
    AppLogger.info('🔄 Narrative state reset');
  }
}

/// Complete narrative content package
class NarrativeContent {
  final String text;
  final NarrativeLayer layer;
  final VoiceRole voiceRole;
  final GravityLevel gravity;
  final List<LocationSuggestion> suggestions;
  final String? connectionContext;
  
  const NarrativeContent({
    required this.text,
    required this.layer,
    required this.voiceRole,
    required this.gravity,
    required this.suggestions,
    this.connectionContext,
  });
  
  @override
  String toString() => 'NarrativeContent(layer: ${layer.name}, voice: ${voiceRole.name}, gravity: ${gravity.value})';
}

/// Location suggestion with context
class LocationSuggestion {
  final LocationData location;
  final double distance;
  final String reason;
  
  const LocationSuggestion({
    required this.location,
    required this.distance,
    required this.reason,
  });
  
  @override
  String toString() => 'LocationSuggestion(${location.name}: $reason)';
}