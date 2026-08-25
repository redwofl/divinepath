import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gita_model.dart';

/// Manages locally-persisted Gita verse bookmarks.
///
/// Bookmarks are stored on-device via SharedPreferences (no account needed),
/// matching how mantra favorites / theme / locale are persisted elsewhere.
class GitaProvider extends ChangeNotifier {
  static const String _bookmarksKey = 'gita_verse_bookmarks';

  List<VerseBookmark> _bookmarks = [];

  /// Saved verses, newest first.
  List<VerseBookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// Load saved bookmarks from SharedPreferences.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_bookmarksKey) ?? const [];
      _bookmarks = raw.map((json) {
        try {
          return VerseBookmark.fromMap(
              jsonDecode(json) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<VerseBookmark>().toList();
      notifyListeners();
    } catch (e) {
      debugPrint('GitaProvider: failed to load bookmarks: $e');
    }
  }

  /// Whether the given chapter/verse is bookmarked.
  bool isBookmarked(int chapterNumber, int verseNumber) {
    return _bookmarks.any((b) =>
        b.chapterNumber == chapterNumber && b.verseNumber == verseNumber);
  }

  /// Toggle a bookmark for the given verse (upsert / remove) and persist.
  Future<void> toggleBookmark(VerseBookmark bookmark) async {
    final existing = _bookmarks.indexWhere((b) =>
        b.chapterNumber == bookmark.chapterNumber &&
        b.verseNumber == bookmark.verseNumber);
    if (existing >= 0) {
      _bookmarks.removeAt(existing);
    } else {
      _bookmarks.insert(0, bookmark);
    }
    // Notify synchronously BEFORE awaiting the disk write so widgets (e.g.
    // Dismissible cards) rebuild with the updated list immediately.
    notifyListeners();
    await _persist();
  }

  /// Remove a bookmark (no-op if it doesn't exist) and persist.
  Future<void> removeBookmark(int chapterNumber, int verseNumber) async {
    final before = _bookmarks.length;
    _bookmarks.removeWhere((b) =>
        b.chapterNumber == chapterNumber && b.verseNumber == verseNumber);
    if (_bookmarks.length != before) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _bookmarksKey,
        _bookmarks.map((b) => jsonEncode(b.toMap())).toList(),
      );
    } catch (e) {
      debugPrint('GitaProvider: failed to persist bookmarks: $e');
    }
  }
}
