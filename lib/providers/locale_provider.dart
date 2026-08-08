import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  String get localeCode => _locale.languageCode;
  
  /// Initialize locale from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(savedCode);
    notifyListeners();
  }
  
  /// Set locale and persist to SharedPreferences
  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    
    _locale = Locale(languageCode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    
    notifyListeners();
  }
  
  /// All supported language codes in order
  static const List<String> supportedCodes = ['en', 'hi', 'mr', 'gu', 'sa'];
  
  /// Get the native display name for current locale
  String get nativeName => Translations.getNativeName(_locale.languageCode);
  
  /// Get short badge text for current locale
  String get badge => Translations.getBadge(_locale.languageCode);
  
  /// Check if current locale is Hindi
  bool get isHindi => _locale.languageCode == 'hi';
  
  /// Check if current locale is Sanskrit
  bool get isSanskrit => _locale.languageCode == 'sa';
  
  /// Check if current locale is Marathi
  bool get isMarathi => _locale.languageCode == 'mr';
  
  /// Check if current locale is Gujarati
  bool get isGujarati => _locale.languageCode == 'gu';
}
