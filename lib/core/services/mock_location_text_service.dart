import 'dart:async';
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../utils/logger.dart';

/// Mock service that simulates an API call providing location-based text data
/// This replaces manual text input in TTS mode
@lazySingleton
class MockLocationTextService {
  static const List<LocationTextData> _mockLocationTexts = [
    LocationTextData(
      location: "Central Library of Latvia Area",
      latitude: 56.9496,
      longitude: 24.1052,
      textContent: "But the rest of the city has been preserved incredibly well. Right now, you're walking past what used to be the Central Library of Latvia—now it's just a regular apartment building. This whole district, including the library and the building across from it, was built during the Russian Empire era. Back then, Riga was considered one of the most stylish and industrially advanced cities—kind of like a mini St. Petersburg, but people actually called it the 'Paris of the North.' And you know why? Art Nouveau! Or 'Jugendstil,' as they say here. Riga has the highest concentration of Art Nouveau buildings in the entire world. Jugendstil and that whole turn-of-the-century glamour are one of Riga's signature vibes. You'll see it everywhere."
    ),
    LocationTextData(
      location: "Berga Bazaar",
      latitude: 56.9484,
      longitude: 24.1067,
      textContent: "Speaking of Berga Bazaar, it's both typical and totally unique for Riga. See all those '1887' signs everywhere? Just like most buildings we'll pass on our way to Old Town, it was built around the turn of the century. But unlike the others, this one got demolished in the 1950s and rebuilt from scratch—though they kept the original spirit of the place. Back in the day, it was packed with restaurants, barbershops, and all kinds of stores. Basically, it was Riga's first shopping mall and a real hotspot! Then, in the '90s, the great-grandchildren of Kristaps Berg (the original owner) restored it to its former glory. Oh, and by the way, from here, I'd take a right down this street."
    ),
    LocationTextData(
      location: "Benjamin's Gate",
      latitude: 56.9467,
      longitude: 24.1089,
      textContent: "Yeah, but if you take a left here and walk straight a bit, you'll reach the Benjamin's Gate—aka 'Benjamin's House.' Nowadays, it's a hotel, but the real gem is its super Instagrammable bar with these gorgeous stained-glass windows. It's not open every day, but luckily, today it should be, so you can pop in and admire the decor. Back in the day, this was the spot for Latvia's elite during the country's first independence (1918–1940). Politicians, tycoons, and members of parliament would gather in the lobby for drinks. The Benjamins—Antons and Emīlija—were literary figures and media moguls who bought this place in the 1920s and hosted lavish parties here. They mentored young artists, actors, and journalists, and the couple made it onto Latvia's list of '100 Most Outstanding People.' Fun fact: Latvia's then-president, Kārlis Ulmanis (who was single in the 1930s), often invited Emīlija Benjamin to act as the unofficial 'First Lady' at state events. But after the Soviets took over there were no more fancy parties—the building became the Latvian SSR Writers' Union."
    ),
    LocationTextData(
      location: "St. Peter's Church",
      latitude: 56.9459,
      longitude: 24.1109,
      textContent: "But if you wanna get to Old Town, just keep going straight - you can already see it a couple of blocks ahead. Oh, and by the way, you can see how this part of the city is laid out in a strict grid pattern. Back when it was built, there were rules—like, no building could be taller than six stories or 21 meters. And see this boulevard, Raiņa bulvāris? This is where the old Riga fortress walls used to be. They tore them down around the turn of the century to make the city feel more open. If you go right, you'll hit one of Riga's most famous landmarks—the Freedom Monument. But straight ahead? That's the entrance to the Old Town. It's summer, and it's Friday night, so this area's basically overrun with British stag parties. Cheap bars everywhere, barely any locals in sight. But hey, this part of town has over 800 years of history. And the oldest building—one of the main attractions—is just a little further. See that spire slightly to your right? That's St. Peter's Church. So, as you walk towards it I'll tell you more – this cathedral was built in 1209—yeah, that makes it 816 years old. And for nearly 800 years, it was the tallest structure in the city. The spire has collapsed, burned down, and been rebuilt more times than anyone can count. The last time it got destroyed? A German artillery shell hit it during WWII. They finally finished restoring it in 1973—this time, the spire was rebuilt in metal but kept the exact same design. Now, it's got two observation decks (57 and 71 meters up) with elevators and stairs for tourists. And that little rooster on top? It's not just decoration—it's a weathervane. Back in the day, they painted one side gold and the other black so merchants could tell which way the wind was blowing. Gold side facing the city? Wind from the sea - good for trade ships. Black side? Wind from land—no deals today."
    )
  ];

  final Random _random = Random();

  /// Simulates an API call that returns location-based text content
  /// In a real implementation, this would make an HTTP request
  Future<LocationTextData?> fetchLocationText({String? specificLocation}) async {
    AppLogger.info('MockLocationTextService: Simulating API call for location text');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800, microseconds: 500));
    
    try {
      LocationTextData selectedData;
      
      if (specificLocation != null) {
        // Try to find specific location
        final matches = _mockLocationTexts.where((data) => 
          data.location.toLowerCase().contains(specificLocation.toLowerCase())
        ).toList();
        
        if (matches.isNotEmpty) {
          selectedData = matches[_random.nextInt(matches.length)];
        } else {
          // Fallback to random if specific location not found
          selectedData = _mockLocationTexts[_random.nextInt(_mockLocationTexts.length)];
        }
      } else {
        // Random selection
        selectedData = _mockLocationTexts[_random.nextInt(_mockLocationTexts.length)];
      }
      
      AppLogger.info('MockLocationTextService: Retrieved text for ${selectedData.location}');
      return selectedData;
    } catch (e) {
      AppLogger.error('MockLocationTextService: Error fetching location text: $e');
      return null;
    }
  }

  /// Get all available locations (for debugging/testing)
  List<String> getAvailableLocations() {
    return _mockLocationTexts.map((data) => data.location).toList();
  }

  /// Simulate real-time location updates (for future enhancement)
  Stream<LocationTextData> getLocationStream() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      final data = await fetchLocationText();
      if (data != null) {
        yield data;
      }
    }
  }
}

/// Data model for location-based text content
class LocationTextData {
  final String location;
  final double latitude;
  final double longitude;
  final String textContent;

  const LocationTextData({
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.textContent,
  });

  @override
  String toString() {
    return 'LocationTextData(location: $location, lat: $latitude, lng: $longitude, text: ${textContent.substring(0, textContent.length > 50 ? 50 : textContent.length)}...)';
  }
}