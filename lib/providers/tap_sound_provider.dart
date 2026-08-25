import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the selected tap sound for mantra chanting.
class TapSoundProvider extends ChangeNotifier {
  static const String _prefKey = 'tap_sound';

  /// Available tap sound options
  static const List<TapSoundOption> options = [
    TapSoundOption(
      id: 'bell',
      label: 'Bell',
      icon: '🔔',
      assetPath: 'assets/sounds/chime.mp3',
    ),
    TapSoundOption(
      id: 'pop',
      label: 'Pop',
      icon: '🫧',
      assetPath: 'assets/sounds/pop.mp3',
    ),
    TapSoundOption(
      id: 'om_chant',
      label: 'OM Chant',
      icon: '🕉️',
      assetPath: 'assets/sounds/om_chant.mp3',
    ),
    TapSoundOption(
      id: 'silent',
      label: 'Silent',
      icon: '🔇',
      assetPath: null,
    ),
  ];

  String _selectedSoundId = 'bell'; // default

  String get selectedSoundId => _selectedSoundId;

  TapSoundOption get selectedOption =>
      options.firstWhere((o) => o.id == _selectedSoundId);

  /// The asset path to play, or null for silent
  String? get soundAssetPath => selectedOption.assetPath;

  bool get isSilent => _selectedSoundId == 'silent';

  /// Load saved preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedSoundId = prefs.getString(_prefKey) ?? 'bell';
    notifyListeners();
  }

  /// Set the tap sound and persist
  Future<void> setTapSound(String soundId) async {
    if (options.any((o) => o.id == soundId)) {
      _selectedSoundId = soundId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, soundId);
      notifyListeners();
    }
  }
}

/// A single tap sound option
class TapSoundOption {
  final String id;
  final String label;
  final String icon;
  final String? assetPath;

  const TapSoundOption({
    required this.id,
    required this.label,
    required this.icon,
    this.assetPath,
  });
}
