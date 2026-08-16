import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class Helpers {
  // Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    // Navigator key set from main.dart
  }

  static BuildContext? getContext() => navigatorKey.currentContext;

  // Number Formatting
  static String formatNumber(int number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Streak
  static String getStreakEmoji(int streak) {
    if (streak >= 100) return '🔥';
    if (streak >= 50) return '⚡';
    if (streak >= 30) return '💫';
    if (streak >= 7) return '⭐';
    if (streak >= 3) return '✨';
    return '🌟';
  }

  // Level
  static Map<String, dynamic> getLevel(int xp) {
    Map<String, dynamic> currentLevel = AppConstants.levels.first;
    for (final level in AppConstants.levels) {
      if (xp >= (level['minXp'] as int)) {
        currentLevel = level;
      } else {
        break;
      }
    }
    return currentLevel;
  }

  static double getLevelProgress(int xp) {
    final currentLevel = getLevel(xp);
    final currentMinXp = currentLevel['minXp'] as int;

    final levelIndex = AppConstants.levels.indexOf(currentLevel);
    final nextMinXp = levelIndex < AppConstants.levels.length - 1
        ? AppConstants.levels[levelIndex + 1]['minXp'] as int
        : currentMinXp + 1000;

    if (nextMinXp == currentMinXp) return 1.0;
    return (xp - currentMinXp) / (nextMinXp - currentMinXp);
  }

  // Mala Progress
  static Map<String, int> getMalaProgress(int totalChants) {
    final malas = totalChants ~/ AppConstants.malaCount;
    final remainder = totalChants % AppConstants.malaCount;
    return {'malas': malas, 'remainder': remainder};
  }

  // Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Shimmer effect
  static Container shimmerContainer({
    double width = double.infinity,
    double height = 100,
    double radius = 20,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // Get greeting based on time and locale
  static String getGreeting({String locale = 'en'}) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      if (locale == 'hi') timeGreeting = 'सुप्रभात';
      else if (locale == 'sa') timeGreeting = 'सुप्रभातम्';
      else timeGreeting = 'Good Morning';
    } else if (hour < 17) {
      if (locale == 'hi') timeGreeting = 'शुभ दोपहर';
      else if (locale == 'sa') timeGreeting = 'शुभमध्याह्नः';
      else timeGreeting = 'Good Afternoon';
    } else {
      if (locale == 'hi') timeGreeting = 'शुभ संध्या';
      else if (locale == 'sa') timeGreeting = 'शुभसन्ध्या';
      else timeGreeting = 'Good Evening';
    }
    return timeGreeting;
  }

  // Get day suffix
  static String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // Platform info
  static bool isPremiumEnabled = false;

  // Haptic feedback
  static const String _hapticsPrefKey = 'haptics_enabled';
  static bool hapticsEnabled = true;

  /// Load the saved haptics preference (call once at startup)
  static Future<void> loadHapticsSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hapticsEnabled = prefs.getBool(_hapticsPrefKey) ?? true;
    } catch (_) {}
  }

  /// Persist the haptics preference
  static Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsPrefKey, value);
    } catch (_) {}
  }

  static void lightHaptic() {
    if (!hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  static void mediumHaptic() {
    if (!hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyHaptic() {
    if (!hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  // Share text
  static String getShareText(String text) {
    return '$text\n\nShared via DivinePath - Your Spiritual Companion';
  }
}
