import 'dart:math';

import 'package:injectable/injectable.dart';

/// Service for randomly selecting a logo at app startup
/// Provides one of two available logos (person1.png or person2.png)
@lazySingleton
class LogoSelectionService {
  static const List<String> _availableLogos = [
    'assets/person1.png',
    'assets/person2.png',
  ];
  
  late final String _selectedLogo;
  
  LogoSelectionService() {
    _selectRandomLogo();
  }
  
  /// Gets the randomly selected logo path
  String get selectedLogoPath => _selectedLogo;
  
  /// Randomly selects one of the available logos
  void _selectRandomLogo() {
    final random = Random();
    final index = random.nextInt(_availableLogos.length);
    _selectedLogo = _availableLogos[index];
  }
}