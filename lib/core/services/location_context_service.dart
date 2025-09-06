import 'dart:async';
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../utils/logger.dart';

/// Service for providing contextual information based on location data
/// Integrates the Dickens walking tour data with gravitational field storytelling system
/// Implements narrative layering: wide shots (district), medium shots (connections), close-ups (details)
@lazySingleton
class LocationContextService {
  static final List<LocationData> _walkingTourData = [
    LocationData(
      id: 1,
      name: "Monument Underground Station",
      lat: 51.5102,
      lng: -0.0857,
      talkingPoints: "The Monument to the Great Fire of London, often referred to simply as \"The Monument,\" is a striking Doric column located near the northern end of London Bridge. Designed by Sir Christopher Wren and Robert Hooke, it commemorates the devastating Great Fire of London in 1666, which destroyed much of the medieval city. Standing 202 feet tall—the exact distance from the monument to the site of the baker's shop on Pudding Lane where the fire began—it serves as both a memorial and a viewing platform, offering sweeping views of the capital. For Dickens enthusiasts, the Monument marks an apt starting point for exploring the layers of history that shaped his London. In Dickens's time, this part of the city was a bustling nexus of trade and river crossings, and he would have walked these streets on his many explorations of the city's byways and alleys.",
    ),
    LocationData(
      id: 2,
      name: "St Magnus the Martyr",
      lat: 51.5094,
      lng: -0.0855,
      talkingPoints: "St Magnus the Martyr is a beautiful Baroque church rebuilt by Christopher Wren after the Great Fire. Once located at the northern end of the old London Bridge, it was an important gateway to the City of London for centuries. The church's interior is rich with maritime memorials, reflecting its proximity to the river and the shipping trade. Dickens references St Magnus in \"Oliver Twist,\" evoking the atmosphere of the riverside streets around it. In earlier centuries, the approach to the bridge here would have been crowded with traders, shopkeepers, and travelers, a scene little changed until the 19th century redevelopment. The church stands as a serene reminder of a bygone riverside London.",
    ),
    LocationData(
      id: 3,
      name: "London Bridge Steps & Rennie's Arch",
      lat: 51.5079,
      lng: -0.087,
      talkingPoints: "These surviving remnants of John Rennie's 19th-century London Bridge are tangible links to the past. The steps once led down to the water's edge, providing access to ferries and river traffic before the bridge crossings became the norm. For Dickens, bridges were both literal and symbolic crossings, often serving as settings for dramatic encounters between his characters. The old bridge was a bustling artery, alive with hawkers and tradesmen. The arch remains today as a silent witness to the transformations of the Thames waterfront—a place where one can pause and imagine the noise, smells, and activity that once filled this stretch of riverbank.",
    ),
    LocationData(
      id: 4,
      name: "Southwark Cathedral",
      lat: 51.5065,
      lng: -0.0901,
      talkingPoints: "Originally the priory church of St Mary Overie, Southwark Cathedral is one of London's oldest places of worship, with roots stretching back over 1,000 years. Rebuilt and restored over the centuries, it became a parish church known as St Saviour's before finally achieving cathedral status in 1905. The cathedral has strong literary associations—not just with Dickens, but also with Shakespeare, whose brother Edmund is buried here. Dickens mentioned the church in \"The Uncommercial Traveller,\" and he would have been familiar with the bustling Borough Market area right outside its doors. Inside, the blend of Gothic architecture and modern memorials makes it both a sacred space and a living museum of London's history.",
    ),
    LocationData(
      id: 5,
      name: "Borough Market",
      lat: 51.5055,
      lng: -0.091,
      talkingPoints: "Borough Market is one of London's oldest and most famous food markets, dating back to at least the 12th century. In Dickens's era, it was a chaotic and earthy place, with traders hawking produce, meat, and fish from stalls and barrows. Dickens drew inspiration from such lively street scenes for novels like \"The Pickwick Papers\" and \"Oliver Twist,\" where markets are depicted as microcosms of city life—full of energy, drama, and characters. Today, Borough Market has transformed into a gourmet food destination, but its cobbled lanes and railway arches still echo with history, making it an essential stop for both literary pilgrims and food lovers.",
      gravity: GravityLevel.exceptional,
      district: "Southwark - Borough District",
      narrativeLayers: {
        NarrativeLayer.wideShot: "Borough Market anchors Southwark's identity as London's historic food hub, representing centuries of commerce flowing from countryside to city.",
        NarrativeLayer.mediumShot: "From Borough Market, Dickens would walk to Southwark Cathedral, observing the bustling trade that connected rural England to urban London's hungry masses.",
        NarrativeLayer.closeUp: "The market's Victorian iron and glass structures house the same trading energy that Dickens captured in his novels—hawkers, characters, and urban drama.",
      },
      connectedLocationIds: [4, 6], // Southwark Cathedral, St Thomas's Church
    ),
    LocationData(
      id: 6,
      name: "St Thomas's Church",
      lat: 51.5039,
      lng: -0.0893,
      talkingPoints: "Founded in the 12th century as part of St Thomas's Hospital, this church served the spiritual needs of patients and staff. Hidden in its attic is the Old Operating Theatre Museum, the oldest surviving operating theatre in Europe. For Dickens, who had a keen interest in the medical and social conditions of his time, the hospital and its church would have been emblematic of the struggles of the urban poor. The space is evocative of Victorian medicine—complete with wooden benches, a domed skylight, and an atmosphere thick with history and human drama.",
    ),
    LocationData(
      id: 7,
      name: "Guy's Hospital Quad",
      lat: 51.5031,
      lng: -0.088,
      talkingPoints: "Founded in 1721 by the philanthropist Thomas Guy, Guy's Hospital has long been a landmark of care and charity in Southwark. Its central courtyard, flanked by elegant Georgian buildings, is dominated by a statue of Guy himself. Dickens would have known this institution well, both through personal visits and through his concern for London's underprivileged. In novels like \"Bleak House,\" hospitals appear as both places of healing and stark reminders of societal inequality. The quad remains a peaceful spot amidst the urban bustle, a reminder of enduring traditions of medical care.",
    ),
    LocationData(
      id: 8,
      name: "White Hart Yard",
      lat: 51.5021,
      lng: -0.0917,
      talkingPoints: "Once home to the White Hart Inn, this site plays a role in Dickens's \"The Pickwick Papers\" as the location where Sam Weller is introduced. Coaching inns like this were hubs of travel, gossip, and intrigue in the 18th and early 19th centuries. White Hart Yard is now a quiet backstreet, but if you stand here and listen, it's not hard to imagine the clatter of hooves, the creak of coach wheels, and the shouts of ostlers. This was the London of Dickens's youth—bustling, noisy, and full of colorful characters.",
    ),
    LocationData(
      id: 9,
      name: "The George Inn",
      lat: 51.5027,
      lng: -0.0914,
      talkingPoints: "The George Inn is the last remaining galleried coaching inn in London, dating back to 1677. Owned by the National Trust, it retains much of its historic charm, with wooden galleries overlooking a cobbled courtyard. Dickens mentions The George in \"Little Dorrit\" and was known to drink here himself. Such inns were vital waypoints for travelers and vital centers of community life. Today, it serves as both a working pub and a living relic of the coaching era, inviting visitors to step back in time.",
    ),
    LocationData(
      id: 10,
      name: "Marshalsea Prison Site",
      lat: 51.5013,
      lng: -0.093,
      talkingPoints: "Marshalsea Prison is infamous in Dickensian lore as the place where the author's father was imprisoned for debt in 1824. This traumatic family episode had a profound effect on the young Dickens and echoes through his work, most notably in \"Little Dorrit.\" Although the prison itself is gone, sections of its high brick wall survive in Angel Place, radiating a palpable sense of confinement and hardship. Standing here, one can feel the shadow of Victorian debtors' prisons and their devastating impact on families.",
      gravity: GravityLevel.essential,
      district: "Southwark - Borough High Street",
      narrativeLayers: {
        NarrativeLayer.wideShot: "Southwark housed London's debtors' prisons, where the Victorian system of justice trapped entire families in cycles of poverty and shame.",
        NarrativeLayer.mediumShot: "Young Dickens walked from his lodging near Warren's Blacking Factory to visit his father here, a journey that shaped his understanding of social injustice.",
        NarrativeLayer.closeUp: "Behind these surviving brick walls, John Dickens lived while his 12-year-old son worked in the blacking factory—the trauma that became 'Little Dorrit.'",
      },
      connectedLocationIds: [11, 12], // St George the Martyr, Trinity Church Square
    ),
    LocationData(
      id: 11,
      name: "St George the Martyr",
      lat: 51.5004,
      lng: -0.0934,
      talkingPoints: "Known as Little Dorrit's Church, St George the Martyr appears in \"Little Dorrit\" as the setting for key scenes. The real-life Dickens would have known it as a familiar landmark in the Borough area. Its interior is elegant yet understated, with strong ties to the local community. The church stands at a crossroads, both literally and in its layered history. For literary visitors, it offers a moment of reflection on the human stories—both fictional and real—that have passed through its doors.",
    ),
    LocationData(
      id: 12,
      name: "Trinity Church Square",
      lat: 51.4977,
      lng: -0.0944,
      talkingPoints: "Trinity Church Square is a beautiful Georgian square built in the early 19th century, centered around the church of Holy Trinity. The square retains much of its original charm, with period railings, cobbles, and a sense of calm. Dickens would have walked these streets, perhaps observing the genteel facades that concealed private dramas within. Today, it remains one of Southwark's architectural gems, offering a glimpse into a more refined aspect of 19th-century life.",
    ),
    LocationData(
      id: 13,
      name: "Newington Gardens",
      lat: 51.497,
      lng: -0.0936,
      talkingPoints: "Now a public park, Newington Gardens occupies the site of Horsemonger Lane Gaol, once the largest prison in Surrey. Dickens attended public executions here and wrote passionately about the brutality of capital punishment. The transformation from prison to park is a poignant reminder of changing attitudes toward justice and punishment. For those following the Dickens trail, it offers a place to pause and consider the stark contrasts of Victorian society.",
    ),
    LocationData(
      id: 14,
      name: "Scovell Estate",
      lat: 51.4956,
      lng: -0.0922,
      talkingPoints: "The Scovell Estate stands on the site of the former King's Bench Prison, another notorious debtors' prison of Dickens's time. In \"David Copperfield,\" Dickens drew upon the harsh realities of such institutions. While little remains of the prison itself, the modern housing estate is a testament to the city's ability to reinvent itself. This is a site where the ghosts of the past mingle with the rhythms of contemporary life.",
    ),
    LocationData(
      id: 15,
      name: "Lant Street",
      lat: 51.501,
      lng: -0.0948,
      talkingPoints: "Lant Street is where a young Charles Dickens lodged while his father was in Marshalsea Prison. The experience left an indelible mark on him, deepening his empathy for the struggles of the poor. The street today is a mix of old and new buildings, but its connection to Dickens's personal history makes it a site of quiet pilgrimage for fans. Standing here connects you directly to the formative hardships that shaped one of literature's greatest voices.",
    ),
    LocationData(
      id: 16,
      name: "Borough Station",
      lat: 51.5015,
      lng: -0.094,
      talkingPoints: "Borough Station serves as a convenient end point for the Southwark Dickens Walk. While the station itself is a modern transport hub, it sits amidst streets rich in history. From here, walkers can easily return to central London or explore further into South London. It's a fitting conclusion to a journey through Dickens's Southwark—a neighborhood that shaped his life and fiction in enduring ways.",
    ),
  ];

  /// Get contextual information based on coordinates
  String? getLocationContext(double? lat, double? lng) {
    if (lat == null || lng == null) return null;

    try {
      final nearestLocation = _findNearestLocation(lat, lng);
      if (nearestLocation != null) {
        AppLogger.info('📍 Found context for location: ${nearestLocation.name}');
        return _formatLocationContext(nearestLocation);
      }
      
      // If no specific location is found, provide general Dickens context
      AppLogger.info('📍 No specific location found, providing general context');
      return _getGeneralDickensContext();
    } catch (e) {
      AppLogger.error('Error getting location context', e);
      return null;
    }
  }

  /// Get contextual information based on location name
  String? getLocationContextByName(String locationName) {
    try {
      final location = _walkingTourData.firstWhere(
        (loc) => loc.name.toLowerCase().contains(locationName.toLowerCase()) ||
                 locationName.toLowerCase().contains(loc.name.toLowerCase()),
        orElse: () => throw StateError('Location not found'),
      );
      
      AppLogger.info('📍 Found context for location name: ${location.name}');
      return _formatLocationContext(location);
    } catch (e) {
      AppLogger.debug('No specific location found for: $locationName');
      return null;
    }
  }

  /// Get all available locations for reference
  List<LocationData> getAllLocations() => List.unmodifiable(_walkingTourData);

  /// Get general conversation context about the Dickens walking tour
  String getGeneralContext() {
    return '''Context: This is a conversation about Charles Dickens' London and the Southwark area where he lived and worked. The user may be following a walking tour that includes historic locations like Borough Market, Southwark Cathedral, The George Inn, Marshalsea Prison site, and other places significant to Dickens' life and works. 

Key themes to discuss include:
- Dickens' personal experiences in Southwark (especially his father's imprisonment and his own hardships)
- Victorian London social conditions and urban life
- Literary connections to his novels (Oliver Twist, Little Dorrit, The Pickwick Papers, etc.)
- Historical significance of churches, inns, markets, and prisons in the area
- Architectural and social changes from Dickens' time to today

Please provide informative, engaging responses that help bring this historic area to life for someone exploring Dickens' London.''';
  }

  /// Find the nearest location within a reasonable distance (~200 meters)
  LocationData? _findNearestLocation(double lat, double lng) {
    const double maxDistance = 0.002; // Roughly 200 meters
    LocationData? nearest;
    double minDistance = double.infinity;

    for (final location in _walkingTourData) {
      final distance = _calculateDistance(lat, lng, location.lat, location.lng);
      if (distance < maxDistance && distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }

    return nearest;
  }

  /// Calculate simple distance between two coordinates
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final latDiff = lat1 - lat2;
    final lngDiff = lng1 - lng2;
    return sqrt(latDiff * latDiff + lngDiff * lngDiff);
  }

  /// Format location context for conversation
  String _formatLocationContext(LocationData location) {
    return '''Current Location: ${location.name}
Coordinates: ${location.lat}, ${location.lng}

Context: ${location.talkingPoints}

This location is part of the Dickens walking tour through Southwark, London. Please discuss this location's significance to Charles Dickens and Victorian London, drawing connections to his life and literary works.''';
  }

  /// Get general context when no specific location is identified
  String _getGeneralDickensContext() {
    return '''Context: The user is in the Southwark area of London, which was central to Charles Dickens' life and work. This historic neighborhood includes many locations that influenced his writing and shaped his understanding of Victorian society.

Please provide information relevant to Dickens' London, including:
- Social conditions in Victorian Southwark
- Literary connections to his major works
- Historical significance of the area's churches, markets, inns, and former prisons
- How this area has changed since Dickens' time

Focus on bringing the history and literature to life for someone exploring this historic area.''';
  }
}

/// Data model for walking tour locations
/// Narrative importance levels following the gravitational field system
enum GravityLevel {
  /// Level 1-3: Hidden gems and local curiosities
  hidden(1, "Hidden gem - for wandering explorers"),
  local(2, "Local interest - worth a detour if nearby"), 
  notable(3, "Notable point - interesting discovery"),
  
  /// Level 4-6: Established attractions
  worthy(4, "Worthy visit - solid cultural value"),
  recommended(5, "Recommended stop - enriching experience"),
  significant(6, "Significant site - important to the area"),
  
  /// Level 7-10: Major landmarks and must-sees
  major(7, "Major attraction - worth planning around"),
  exceptional(8, "Exceptional site - justifies a detour"),
  landmark(9, "Iconic landmark - destination worthy"),
  essential(10, "Essential experience - worth a special journey");
  
  const GravityLevel(this.value, this.description);
  final int value;
  final String description;
}

/// Narrative perspective following montage theory
enum NarrativeLayer {
  /// Wide shot: District/neighborhood overview
  wideShot("District context and broad historical background"),
  
  /// Medium shot: Connections and transitions between locations
  mediumShot("Transitional context linking locations and themes"),
  
  /// Close-up: Specific landmark details and intimate stories
  closeUp("Detailed facts and intimate historical moments");
  
  const NarrativeLayer(this.description);
  final String description;
}

class LocationData {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final String talkingPoints;
  
  /// Gravitational field importance (1-10)
  final GravityLevel gravity;
  
  /// District/neighborhood for wide-shot context
  final String district;
  
  /// Narrative layers for montage storytelling
  final Map<NarrativeLayer, String> narrativeLayers;
  
  /// Connections to other locations for medium-shot storytelling
  final List<int> connectedLocationIds;

  const LocationData({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.talkingPoints,
    this.gravity = GravityLevel.notable,
    this.district = "Southwark",
    this.narrativeLayers = const {},
    this.connectedLocationIds = const [],
  });
  
  /// Get narrative content for specific layer with optional custom filters
  String? getNarrativeForLayer(
    NarrativeLayer layer, {
    List<String>? wideShotKeywords,
    List<String>? mediumShotKeywords,
    int? closeUpSentenceCount,
  }) {
    return narrativeLayers[layer] ?? 
           _extractLayerFromTalkingPoints(
             layer, 
             wideShotKeywords: wideShotKeywords,
             mediumShotKeywords: mediumShotKeywords,
             closeUpSentenceCount: closeUpSentenceCount,
           );
  }
  
  /// Extract narrative layer from existing talking points using flexible keyword matching
  String _extractLayerFromTalkingPoints(
    NarrativeLayer layer, {
    List<String>? wideShotKeywords,
    List<String>? mediumShotKeywords,
    int? closeUpSentenceCount,
  }) {
    final sentences = talkingPoints.split('. ');
    
    switch (layer) {
      case NarrativeLayer.wideShot:
        final keywords = wideShotKeywords ?? _getDefaultWideShotKeywords();
        final filtered = sentences.where((s) => 
          keywords.any((keyword) => s.toLowerCase().contains(keyword.toLowerCase()))
        ).join('. ');
        return filtered.isEmpty ? sentences.take(1).join('. ') : filtered;
        
      case NarrativeLayer.mediumShot:
        final keywords = mediumShotKeywords ?? _getDefaultMediumShotKeywords();
        final filtered = sentences.where((s) => 
          keywords.any((keyword) => s.toLowerCase().contains(keyword.toLowerCase()))
        ).join('. ');
        return filtered.isEmpty ? sentences.skip(1).take(2).join('. ') : filtered;
        
      case NarrativeLayer.closeUp:
        final count = closeUpSentenceCount ?? 2;
        return sentences.take(count).join('. ');
    }
  }
  
  /// Default wide shot keywords - can be overridden per content type
  List<String> _getDefaultWideShotKeywords() {
    return [
      'district', 'area', 'neighborhood', 'region', 'vicinity',
      'Victorian', 'centuries', 'period', 'era', 'time',
      'historic', 'ancient', 'traditional', 'established',
      'community', 'quarter', 'locality'
    ];
  }
  
  /// Default medium shot keywords - can be overridden per content type
  List<String> _getDefaultMediumShotKeywords() {
    return [
      'would have', 'likely', 'probably', 'might have',
      'connected', 'nearby', 'close to', 'adjacent',
      'relationship', 'link', 'association', 'ties',
      'journey', 'walk', 'path', 'route',
      'transition', 'moving', 'crossing'
    ];
  }
  
  /// Check if this location should be mentioned based on user movement pattern
  bool shouldMentionForExploration({required bool isSlowWandering, required bool isDirectMovement}) {
    if (isSlowWandering) {
      return gravity.value >= 1; // Mention everything for thorough explorers
    } else if (isDirectMovement) {
      return gravity.value >= 7; // Only major landmarks for focused travelers
    } else {
      return gravity.value >= 3; // Balanced exploration
    }
  }

  @override
  String toString() => 'LocationData(id: $id, name: $name, gravity: ${gravity.value}, district: $district)';
}