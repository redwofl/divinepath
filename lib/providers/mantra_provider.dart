import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/mantra_model.dart';
import '../utils/constants.dart';

class MantraProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  // Current session state
  int _currentCount = 0;
  int _sessionCount = 0;
  int _totalMalasInSession = 0;
  bool _isCounting = false;
  bool _autoMode = false;
  int _selectedMantraIndex = 0;
  int _dailyCount = 0;
  final int _weeklyCount = 0;
  final int _monthlyCount = 0;
  int _totalCount = 0;
  int _totalMalas = 0;
  bool _isSessionTimerRunning = false;
  int _sessionSeconds = 0;
  Timer? _sessionTimer;
  Timer? _timer;

  // Mantra lists
  List<MantraModel> _mantras = [];
  List<MantraSession> _recentSessions = [];
  final Map<String, int> _dailyHistory = {};

  // Favorites
  Set<int> _favoriteIndices = {};

  // Getters
  int get currentCount => _currentCount;
  int get sessionCount => _sessionCount;
  int get totalMalasInSession => _totalMalasInSession;
  bool get isCounting => _isCounting;
  bool get autoMode => _autoMode;
  int get selectedMantraIndex => _selectedMantraIndex;
  int get dailyCount => _dailyCount;
  int get weeklyCount => _weeklyCount;
  int get monthlyCount => _monthlyCount;
  int get totalCount => _totalCount;
  int get totalMalas => _totalMalas;
  int get sessionSeconds => _sessionSeconds;
  bool get isSessionTimerRunning => _isSessionTimerRunning;
  List<MantraModel> get mantras => _mantras;
  List<MantraSession> get recentSessions => _recentSessions;
  Map<String, int> get dailyHistory => _dailyHistory;

  /// Beads filled in the current mala — full (108) at completion, then resets to 0
  /// the moment the next mala begins so the circle visibly restarts.
  int get currentMalaProgress {
    if (_currentCount <= 0) return 0;
    final mod = _currentCount % AppConstants.malaCount;
    return mod == 0 ? AppConstants.malaCount : mod;
  }

  /// Circle fill from 0 → 1.0 across a mala, resetting to 0 when the next mala starts.
  double get progress => currentMalaProgress / AppConstants.malaCount;
  bool get isMalaComplete => _currentCount > 0 && _currentCount % AppConstants.malaCount == 0;
  MantraModel get selectedMantra => _mantras.isNotEmpty ? _mantras[_selectedMantraIndex] : MantraModel(id: 'default', name: 'Om');

  /// Favorite mantras — sorted by original index order
  List<MantraModel> get favoriteMantras {
    final sorted = _favoriteIndices.toList()..sort();
    return sorted.map((i) => _mantras[i]).toList();
  }

  bool isFavorite(int index) => _favoriteIndices.contains(index);

  /// Toggle a mantra's favorite status and persist
  Future<void> toggleFavorite(int index) async {
    if (_favoriteIndices.contains(index)) {
      _favoriteIndices.remove(index);
    } else {
      _favoriteIndices.add(index);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_mantra_indices',
      _favoriteIndices.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  /// Initialize mantras
  Future<void> initialize() async {
    _mantras = AppConstants.defaultMantras.map((m) => MantraModel(
      id: m['name']!.toLowerCase().replaceAll(' ', '_'),
      name: m['name']!,
      translation: m['translation'],
    )).toList();

    await _loadFromLocal();
    await _loadFromFirestore();
  }

  /// Load data from local storage
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyCount = prefs.getInt('daily_count') ?? 0;
    _totalCount = prefs.getInt('total_count') ?? 0;
    _totalMalas = prefs.getInt('total_malas') ?? 0;

    // Load favorite indices
    final favStrings = prefs.getStringList('favorite_mantra_indices') ?? [];
    _favoriteIndices = favStrings.map((e) => int.tryParse(e) ?? -1)
        .where((i) => i >= 0 && i < _mantras.length)
        .toSet();
  }

  /// Load data from Firestore
  Future<void> _loadFromFirestore() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final doc = await _firebaseService.getUserData(user.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _totalCount = data['totalChants'] ?? _totalCount;
        _totalMalas = data['totalMalas'] ?? _totalMalas;
      }

      // Load recent sessions
      final sessionsSnapshot = await _firebaseService.queryCollection('mantra_sessions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      _recentSessions = sessionsSnapshot.docs.map((doc) =>
          MantraSession.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from Firestore: $e');
    }
  }

  /// Start counting session
  void startCounting() {
    _sessionCount = 0;
    _currentCount = 0;
    _totalMalasInSession = 0;
    _isCounting = true;
    _sessionSeconds = 0;

    // Start session timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionSeconds++;
      _isSessionTimerRunning = true;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Add one chant
  Future<void> addChant() async {
    if (!_isCounting) return;

    _currentCount++;
    _sessionCount++;
    _dailyCount++;
    _totalCount++;

    // Check if mala completed
    if (_currentCount % AppConstants.malaCount == 0) {
      _totalMalas++;
      _totalMalasInSession++;
    }

    // Save to local
    await _saveToLocal();
    notifyListeners();
  }

  /// Add bonus chants earned from a rewarded ad (keeps session running).
  /// Returns true if a full mala was completed.
  Future<bool> addBonusChants(int count) async {
    if (count <= 0) return false;
    if (!_isCounting) startCounting();

    final before = _currentCount ~/ AppConstants.malaCount;
    _currentCount += count;
    _sessionCount += count;
    _dailyCount += count;
    _totalCount += count;
    final after = _currentCount ~/ AppConstants.malaCount;
    final malasGained = after - before;
    if (malasGained > 0) {
      _totalMalas += malasGained;
      _totalMalasInSession += malasGained;
    }

    await _saveToLocal();
    notifyListeners();
    return malasGained > 0;
  }

  /// Auto-add chants (for auto mode)
  void startAutoMode() {
    _autoMode = true;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await addChant();
    });
    notifyListeners();
  }

  /// Stop auto mode
  void stopAutoMode() {
    _autoMode = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// End counting session and save
  Future<void> endSession() async {
    _timer?.cancel();
    _sessionTimer?.cancel();
    _isCounting = false;
    _isSessionTimerRunning = false;
    _autoMode = false;

    if (_sessionCount > 0) {
      // Create session record
      final session = MantraSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mantraId: selectedMantra.id,
        mantraName: selectedMantra.name,
        count: _sessionCount,
        durationSeconds: _sessionSeconds,
        timestamp: DateTime.now(),
        isMalaComplete: _sessionCount >= AppConstants.malaCount,
      );

      _recentSessions.insert(0, session);

      // Save to Firestore
      await _saveToFirestore(session);
    }

    await _saveToLocal();
    notifyListeners();
  }

  /// Reset session counter
  void resetSession() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    _currentCount = 0;
    _sessionCount = 0;
    _totalMalasInSession = 0;
    _isCounting = false;
    _isSessionTimerRunning = false;
    _autoMode = false;
    _sessionSeconds = 0;
    notifyListeners();
  }

  /// Select mantra
  void selectMantra(int index) {
    _selectedMantraIndex = index;
    notifyListeners();
  }

  /// Add custom mantra
  Future<void> addCustomMantra(String name, {String? translation}) async {
    final mantra = MantraModel(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      translation: translation,
      isCustom: true,
    );
    _mantras.add(mantra);
    notifyListeners();
  }

  /// Update daily statistics
  Future<void> updateDailyStats() async {
    // Check if day changed
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('last_active_date') ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != today) {
      // Save yesterday's count to history
      if (lastDate.isNotEmpty) {
        _dailyHistory[lastDate] = _dailyCount;
      }
      _dailyCount = 0;
      await prefs.setString('last_active_date', today);
    }

    await _saveToLocal();
    notifyListeners();
  }

  /// Save to local storage
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_count', _dailyCount);
    await prefs.setInt('total_count', _totalCount);
    await prefs.setInt('total_malas', _totalMalas);
  }

  /// Save session to Firestore
  Future<void> _saveToFirestore(MantraSession session) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      // Save session
      await _firebaseService.addDocument('mantra_sessions', {
        ...session.toMap(),
        'userId': user.uid,
      });

      // Update user stats
      await _firebaseService.setUserData(user.uid, {
        'totalChants': _totalCount,
        'totalMalas': _totalMalas,
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }
}
