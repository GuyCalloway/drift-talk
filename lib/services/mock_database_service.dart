import 'dart:async';
import 'dart:math';

class LocationData {
  final String location;
  final double latitude;
  final double longitude;
  final String description;
  final String historicalContext;

  LocationData({
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.historicalContext,
  });
}

class MockDatabaseService {
  static final MockDatabaseService _instance = MockDatabaseService._internal();
  factory MockDatabaseService() => _instance;
  MockDatabaseService._internal();

  final Random _random = Random();
  bool _isDevMode = true;

  // Mock location data with Dickens-era London context
  final List<LocationData> _dickensLocations = [
    LocationData(
      location: "Thames Embankment, London",
      latitude: 51.5074,
      longitude: -0.1278,
      description: "The great river Thames, dark and mysterious in the fog",
      historicalContext: "In Dickens' time, the Thames was London's lifeline - a bustling highway of commerce, but also a source of disease and danger. The mudlarks scavenged its shores at low tide, while gentlemen avoided its noxious fumes.",
    ),
    LocationData(
      location: "Whitechapel, East London",
      latitude: 51.5188,
      longitude: -0.0730,
      description: "Narrow cobblestone streets shrouded in industrial smoke",
      historicalContext: "The East End was where London's poorest congregated in overcrowded tenements. Dickens often walked these streets, observing the harsh realities that would inspire his tales of social injustice.",
    ),
    LocationData(
      location: "Covent Garden, London",
      latitude: 51.5129,
      longitude: -0.1240,
      description: "Market square bustling with vendors and street performers",
      historicalContext: "Once London's principal fruit and vegetable market, Covent Garden in Dickens' era was a maze of narrow streets filled with flower girls, street entertainers, and the occasional pickpocket - like the Artful Dodger.",
    ),
    LocationData(
      location: "Marshalsea Prison Site, Southwark",
      latitude: 51.5016,
      longitude: -0.0935,
      description: "Former debtors' prison, now marked only by a small plaque",
      historicalContext: "Where Dickens' own father was imprisoned for debt when Charles was just 12. This traumatic experience shaped his understanding of poverty and social inequality, themes that permeate his novels.",
    ),
    LocationData(
      location: "Chancery Lane, London",
      latitude: 51.5154,
      longitude: -0.1109,
      description: "Legal district with ancient buildings and gaslit corners",
      historicalContext: "The heart of London's legal system, immortalized in Bleak House as a place where justice moved at glacial pace and lawyers grew rich while clients grew poor and desperate.",
    ),
    LocationData(
      location: "Rochester High Street, Kent",
      latitude: 51.3875,
      longitude: 0.5047,
      description: "Medieval high street with timber-framed buildings",
      historicalContext: "Dickens spent his happiest childhood years here and returned as an adult. Rochester appears in several novels, most notably as 'Mudfog' and the setting for much of Great Expectations.",
    ),
    LocationData(
      location: "Seven Dials, London",
      latitude: 51.5145,
      longitude: -0.1281,
      description: "Notorious slum with seven streets radiating from a central pillar",
      historicalContext: "In Dickens' time, this was one of London's most dangerous rookeries - a maze of crime and poverty. He described it as a place where 'dirty men, filthy women, squalid children, fluttered on and off the door-steps.'",
    ),
    LocationData(
      location: "Gad's Hill, Kent",
      latitude: 51.4089,
      longitude: 0.4394,
      description: "Country house on the hill where Dickens spent his final years",
      historicalContext: "Dickens bought this house in 1856 - the same house he had admired as a poor child, when his father told him he might live there if he worked very hard. It became his writing retreat and final home.",
    ),
  ];

  // Additional Dickens quotes and context for atmospheric text
  final List<String> _dickensAtmosphericTexts = [
    "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness...",
    "The fog came pouring in at every chink and keyhole, and was so dense without, that although the court was of the narrowest, the houses opposite were mere phantoms.",
    "London. Michaelmas term lately over, and the Lord Chancellor sitting in Lincoln's Inn Hall. Implacable November weather.",
    "It is a far, far better thing that I do, than I have ever done; it is a far, far better rest that I go to than I have ever known.",
    "The streets were thronged with working people. The hum of labour resounded from every house, lights gleamed from the long casement windows in the attic storeys.",
    "Annual income twenty pounds, annual expenditure nineteen six, result happiness. Annual income twenty pounds, annual expenditure twenty pound ought and six, result misery.",
    "There was a long hard time when I kept far from me the remembrance of what I had thrown away when I was quite ignorant of its worth.",
    "I loved her against reason, against promise, against peace, against hope, against happiness, against all discouragement that could be.",
  ];

  Future<LocationData> fetchLocationData() async {
    // Simulate database call delay
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
    
    if (_isDevMode) {
      return _dickensLocations[_random.nextInt(_dickensLocations.length)];
    }
    
    // In production, this would make a real database call
    throw UnimplementedError('Production database integration not implemented');
  }

  String getRandomDickensText() {
    return _dickensAtmosphericTexts[_random.nextInt(_dickensAtmosphericTexts.length)];
  }

  void setDevMode(bool isDevMode) {
    _isDevMode = isDevMode;
  }

  bool get isDevMode => _isDevMode;
}