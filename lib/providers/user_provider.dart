import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Handles local user profile data — no authentication required.
/// Automatically creates a default local user on initialization.
class UserProvider extends ChangeNotifier {
  static const _onboardingKey = 'has_completed_onboarding';
  static const _profileKey = 'user_profile';

  UserModel? _user;
  bool _isInitialized = false;
  bool _hasCompletedOnboarding = false;

  // Getters
  UserModel? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// Initialize with a default local user and load saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool(_onboardingKey) ?? false;

    // Load saved profile so name/preferences survive restarts.
    final savedProfile = prefs.getString(_profileKey);
    if (savedProfile != null && savedProfile.isNotEmpty) {
      try {
        final map = jsonDecode(savedProfile) as Map<String, dynamic>;
        _user = UserModel.fromMap(map, 'local_user');
      } catch (e) {
        debugPrint('UserProvider: Failed to load saved profile: $e');
      }
    }

    _user ??= UserModel(
      uid: 'local_user',
      email: 'user@local.app',
      name: 'Seeker',
    );

    _isInitialized = true;
    debugPrint('UserProvider: Local user initialized');
    notifyListeners();
  }

  /// Persist the current user profile to SharedPreferences.
  Future<void> _saveToLocal() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_user!.toMap()));
  }

  /// Mark onboarding as completed and persist the flag
  Future<void> markOnboardingComplete() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  /// Update user name
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (_user == null) return;
    if (name != null && name.isNotEmpty) {
      _user = _user!.copyWith(name: name, photoUrl: photoUrl);
      notifyListeners();
    }
    await _saveToLocal();
  }

  /// Update onboarding preferences and mark onboarding as completed
  Future<void> updateOnboarding({
    required List<String> interests,
    String? favoriteDeity,
    String? preferredMantra,
    String? language,
    int? dailyGoal,
  }) async {
    if (_user == null) return;

    _user = _user!.copyWith(
      spiritualInterests: interests,
      favoriteDeity: favoriteDeity,
      preferredMantra: preferredMantra,
      language: language,
      dailyGoal: dailyGoal,
    );

    await markOnboardingComplete();
    await _saveToLocal();
    debugPrint('UserProvider: Onboarding saved locally');
  }
}
