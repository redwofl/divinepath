import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/locale_provider.dart';
import '../../services/ad_service.dart';
import '../../services/admob_service.dart';
import '../../services/audio_service.dart';
import '../../utils/translations.dart';
import '../../utils/helpers.dart';

class BubbleGameScreen extends StatefulWidget {
  const BubbleGameScreen({super.key});

  @override
  State<BubbleGameScreen> createState() => _BubbleGameScreenState();
}

/// Global pause signal for the bubble game. The game lives inside an
/// IndexedStack shell route, so switching bottom-nav tabs does NOT dispose it
/// — without this, a running round (and its ambient music) keeps going in the
/// background. MainNavScreen sets this to true when the user leaves the Game
/// tab and false when they come back.
final ValueNotifier<bool> bubbleGameTabPaused = ValueNotifier<bool>(false);

class _BubbleGameScreenState extends State<BubbleGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const List<String> _divineNames = [
    'ॐ',
    'राम',
    'कृष्ण',
    'शिव',
    'हनुमान',
    'गणेश',
    'लक्ष्मी',
    'सरस्वती',
    'माँ दुर्गा',
    'नारायण',
    'साईं बाबा',
  ];

  final List<_FallingBubble> _bubbles = [];
  final List<_Particle> _particles = [];
  final List<_ScorePopup> _scorePopups = [];
  int _score = 0;
  int _highScore = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _totalPopped = 0;
  bool _isGameOver = false;
  bool _isGameStarted = false;
  double _baseSpeed = 1.0;
  int _missedCount = 0;
  static const int _maxMissed = 1;

  /// True when the player quit via the X button (revive not offered)
  bool _wasManualQuit = false;

  bool _isMuted = false;

  // Pending interstitial delay so it can be cancelled on restart/dispose
  Timer? _interstitialTimer;

  // ── Background pause bookkeeping ──
  // The game keeps running when the user switches tabs (IndexedStack shell)
  // or backgrounds the app. These flags track WHY we're paused so the round
  // only resumes when every reason has cleared.
  bool _navPaused = false;
  bool _lifecyclePaused = false;
  bool _roundPausedByUs = false;

  // Debounce for double-taps: after popping a bubble, ignore a second tap that
  // lands within a short window at (nearly) the same spot, so a rapid
  // double-tap doesn't also pop the next bubble that falls into place.
  int? _lastPopTimestamp;
  Offset? _lastPopPosition;
  // Where the current tap's finger first touched down. Fast bubbles travel
  // tens of pixels between touch-down and touch-up; hit-testing against the
  // whole down→up sweep lets edge/side taps on fast bubbles still connect.
  Offset? _pendingTapStart;
  // Window is longer than the 350ms pop animation: a rapid re-tap on the same
  // spot lands AFTER the first bubble is removed, so it would hit the next
  // bubble that fell into place. 600ms covers a natural double-tap / re-tap.
  // Debounce for accidental double-fires of ONE physical tap (some devices
  // bounce the gesture). Deliberately tight: a loose guard here used to eat
  // legitimate taps on nearby falling bubbles ("my tap did nothing!").
  static const int _doubleTapWindowMs = 280;
  static const double _doubleTapRadius = 28;

  /// Extra forgiving margin added around every bubble during hit-testing.
  /// Fingertips are imprecise; small bubbles (~44px ≈ 4mm on phones) were
  /// easy to miss by a few pixels, which felt like "taps don't register".
  static const double _hitSlop = 16.0;

  /// Absolute minimum tappable radius, so even the smallest orbs stay
  /// comfortable to hit on high-DPI screens.
  static const double _minHitRadius = 32.0;

  late AnimationController _gameLoopController;
  Timer? _spawnTimer;
  final Random _random = Random();
  late double _screenWidth;
  late double _screenHeight;

  // Pre-generated star positions for background
  final List<Map<String, double>> _stars = [];
  // A few larger standout stars with a soft sparkle cross
  final List<Map<String, double>> _brightStars = [];
  // Pre-generated floating golden motes for background
  final List<Map<String, double>> _goldenMotes = [];

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateGame);

    // Pre-generate a dense starfield — mostly white, with a scattering of
    // pale blue and warm gold stars for a realistic, richly-populated
    // universe look (colorIndex: 0 = white, 1 = pale blue, 2 = pale gold).
    for (int i = 0; i < 160; i++) {
      final colorRoll = _random.nextDouble();
      _stars.add({
        'x': _random.nextDouble(),
        'y': _random.nextDouble(),
        'opacity': 0.15 + _random.nextDouble() * 0.65,
        'size': 0.6 + _random.nextDouble() * 2.6,
        'colorIndex': colorRoll < 0.72 ? 0.0 : (colorRoll < 0.88 ? 1.0 : 2.0),
      });
    }

    // A handful of larger "bright" stars scattered on top, each with a
    // soft four-point sparkle cross for a few standout focal points.
    for (int i = 0; i < 10; i++) {
      _brightStars.add({
        'x': _random.nextDouble(),
        'y': _random.nextDouble() * 0.85,
        'size': 3.0 + _random.nextDouble() * 2.5,
        'phase': _random.nextDouble() * 2 * pi,
      });
    }

    // Pre-generate floating golden motes
    for (int i = 0; i < 12; i++) {
      _goldenMotes.add({
        'x': _random.nextDouble(),
        'y': _random.nextDouble(),
        'size': 1.5 + _random.nextDouble() * 2.5,
        'speed': 0.02 + _random.nextDouble() * 0.04,
        'phase': _random.nextDouble() * 2 * pi,
      });
    }

    // Load persisted settings
    _loadHighScore();
    _loadMuteSetting();

    // Preload AdMob rewarded ad so the extra-life option is ready on game over
    AdmobService.instance.loadRewarded();

    // Preload AdMob interstitial ad so it's ready when the game ends
    AdmobService.instance.loadInterstitial();

    // Pause/resume with tab switches and app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    bubbleGameTabPaused.addListener(_onTabPauseSignal);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecyclePaused =
        state == AppLifecycleState.paused || state == AppLifecycleState.inactive;
    _applyRoundPause();
  }

  void _onTabPauseSignal() {
    _navPaused = bubbleGameTabPaused.value;
    _applyRoundPause();
  }

  /// Freezes or unfreezes a running round. Freezing stops the game ticker,
  /// bubble spawning and the ambient music; resuming restarts all three.
  void _applyRoundPause() {
    final shouldPause = _navPaused || _lifecyclePaused;
    if (shouldPause) {
      if (!_roundPausedByUs && _isGameStarted && !_isGameOver) {
        _roundPausedByUs = true;
        _gameLoopController.stop();
        _spawnTimer?.cancel();
        AudioService.instance.stopAudio();
      }
      return;
    }
    // Resuming — only if WE froze a round and it's still in progress
    if (_roundPausedByUs) {
      _roundPausedByUs = false;
      if (mounted && _isGameStarted && !_isGameOver) {
        _gameLoopController.repeat();
        _scheduleNextSpawn();
        AudioService.instance
            .playAmbientSound('assets/sounds/ambient.mp3', isAsset: true);
      }
    }
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('game_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('game_high_score', score);
  }

  Future<void> _loadMuteSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMuted = prefs.getBool('game_muted') ?? false;
      if (_isMuted) {
        AudioService.instance.setVolume(0);
      }
    });
  }

  Future<void> _toggleMute() async {
    final newMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('game_muted', newMuted);

    if (newMuted) {
      AudioService.instance.setVolume(0);
    } else {
      AudioService.instance.setVolume(1.0);
    }

    setState(() {
      _isMuted = newMuted;
    });
  }

  @override
  void dispose() {
    bubbleGameTabPaused.removeListener(_onTabPauseSignal);
    WidgetsBinding.instance.removeObserver(this);
    _interstitialTimer?.cancel();
    AudioService.instance.stopAudio();
    _gameLoopController.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _bubbles.clear();
      _particles.clear();
      _scorePopups.clear();
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _totalPopped = 0;
      _isGameOver = false;
      _isGameStarted = true;
      _baseSpeed = 1.0;
      _missedCount = 0;
      _wasManualQuit = false;
    });

    // Reset double-tap debounce so the first tap of a new round always counts
    _lastPopTimestamp = null;
    _lastPopPosition = null;

    // Start gentle ambient meditation music on loop
    AudioService.instance
        .playAmbientSound('assets/sounds/ambient.mp3', isAsset: true);

    // Preload interstitial so it's ready when the game ends
    AdService.instance.loadInterstitial();

    _gameLoopController.repeat();

    _scheduleNextSpawn();

    // Spawn just ONE initial bubble; the spawn timer adds more slowly after
    _spawnBubble(xOverride: _screenWidth * 0.4);
  }

  /// Schedules the next bubble spawn using the CURRENT `_spawnInterval`.
  ///
  /// Bug fix: `Timer.periodic(_spawnInterval, ...)` only reads `_spawnInterval`
  /// once, at the moment the timer is created — the interval is then locked in
  /// for the rest of the game, so spawn rate never actually responded to score
  /// (it felt "off": either stuck slow the whole game, or stuck at whatever
  /// rate was captured on revive). Using a single-shot `Timer` that reschedules
  /// itself after every fire means `_spawnInterval` is re-evaluated against the
  /// live score each time, so the spawn rate ramps smoothly as intended.
  void _scheduleNextSpawn() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer(_spawnInterval, () {
      if (!_isGameOver && mounted) {
        _spawnBubble();
      }
      if (!_isGameOver && mounted) {
        _scheduleNextSpawn();
      }
    });
  }

  /// Spawn cadence based on score for smooth difficulty progression.
  /// Score 0-10: 1500ms, 11-25: 1200ms, 26-50: 900ms, 50+: 700ms min.
  Duration get _spawnInterval {
    int ms;
    if (_score <= 10) {
      ms = 1500;
    } else if (_score <= 25) {
      ms = 1200;
    } else if (_score <= 50) {
      ms = 900;
    } else {
      ms = 700; // Minimum spawn delay
    }
    return Duration(milliseconds: ms);
  }

  void _spawnBubble({double? xOverride}) {
    if (_screenWidth <= 0) return;

    // Keep the screen calm: never more than 5 bubbles at once
    if (_bubbles.length >= 5) return;

    final isGolden = _random.nextDouble() < 0.12;
    final name =
        isGolden ? 'ॐ' : _divineNames[_random.nextInt(_divineNames.length)];

    // Three size classes: Small / Medium / Large
    final sizeRoll = _random.nextDouble();
    final double bubbleSize;
    if (sizeRoll < 0.4) {
      bubbleSize = 44.0 + _random.nextDouble() * 8; // Small
    } else if (sizeRoll < 0.8) {
      bubbleSize = 60.0 + _random.nextDouble() * 10; // Medium
    } else {
      bubbleSize = 82.0 + _random.nextDouble() * 14; // Large
    }

    final x = xOverride ??
        (_random.nextDouble() * (_screenWidth - bubbleSize - 20) + 10);
    // Horizontal drifting; larger bubbles sway more slowly, so bubbles
    // spread across the screen instead of stacking into vertical trains
    final dx = (_random.nextDouble() - 0.5) * (bubbleSize < 55 ? 1.2 : 0.8);
    final phase = _random.nextDouble() * 2 * pi;

    // Smaller bubbles fall slightly faster than large ones (gentle difference
    // so the pack separates without any bubble feeling unfair)
    final sizeFactor = bubbleSize < 55
        ? 1.2
        : bubbleSize < 72
            ? 1.05
            : 0.9;

    final bubble = _FallingBubble(
      name: name,
      x: x,
      y: -bubbleSize,
      dx: dx,
      size: isGolden ? bubbleSize * 1.12 : bubbleSize,
      // Gentle falling speed: slow and comfortable at start, only a small
      // increase as _baseSpeed grows (capped below).
      speed:
          (1.5 + _baseSpeed * 0.35 + _random.nextDouble() * 0.8) * sizeFactor,
      phase: phase,
      color: isGolden ? const Color(0xFFF5C531) : _getRandomDivineColor(),
      seed: _random.nextInt(1 << 20),
      isGolden: isGolden,
    );

    setState(() {
      _bubbles.add(bubble);
    });

    // Very gradual difficulty ramp, capped so it never gets crazy fast
    if (_baseSpeed < 2.5) {
      _baseSpeed += 0.02;
    }
    _buildOrbImage(bubble);
  }

  /// Extra margin (as a multiple of bubble size) given to the cached orb
  /// image. The rim glow rings inside _BubblePainter use blur that spreads
  /// past the drawn circle's edge; without this margin, that blur got
  /// hard-cropped at the image's square boundary — visible as a faint square
  /// outline around the bubble. 1.6x gives the blur room to fade to nothing
  /// before it reaches the image edge.
  // Covers the glass fill, crisp rings, and the layered-circle rim glow
  // (which extends slightly past the bubble's own radius). No blur is used
  // anywhere in _BubblePainter anymore, so caching the whole thing is safe
  // on every renderer — there's no blur-clamping artifact to worry about.
  static const double _orbCanvasPad = 1.35;

  /// Pre-renders the static glass orb to an image once per bubble, so
  /// the per-frame canvas only has to rotate/draw the cached picture instead
  /// of re-executing paint operations for every bubble, every frame.
  Future<void> _buildOrbImage(_FallingBubble b) async {
    try {
      final padded = b.size * _orbCanvasPad;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Centre the true-size bubble inside the padded capture canvas.
      canvas.translate((padded - b.size) / 2, (padded - b.size) / 2);
      _BubblePainter(
        color: b.color,
        seed: b.seed,
        tick: 0,
        rotation: 0,
      ).paint(canvas, Size(b.size, b.size));
      final picture = recorder.endRecording();
      final image = await picture.toImage(padded.ceil(), padded.ceil());
      if (!mounted) return;
      b.orbImage = image;
    } catch (_) {
      // Fall back to direct painting if image capture fails
    }
  }

  Color _getRandomDivineColor() {
    final colors = [
      const Color(0xFF9F7AEA), // Purple / Violet
      const Color(0xFF3B82F6), // Royal Blue
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFFF97316), // Saffron / Orange
      const Color(0xFFF59E0B), // Golden Yellow
      const Color(0xFFEC4899), // Pink / Magenta
      const Color(0xFF22D3EE), // Cyan / Sky Blue
      const Color(0xFFDC2626), // Deep Red
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _updateGame() {
    if (_isGameOver || !_isGameStarted) return;

    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final bubble = _bubbles[i];

      // Skip position update for popping bubbles (canvas animates them)
      if (bubble.isPopping) {
        continue;
      }

      // Slowly fall downward with gentle horizontal drifting
      bubble.y += bubble.speed;
      bubble.x += bubble.dx;

      // Side walls: bubbles must stay FULLY visible. The old clamp allowed
      // them to slide until half the orb was off-screen (looked like the
      // bubble vanished into the phone's side edge). Now they bounce off an
      // invisible wall just inside the screen edge instead.
      const wallMargin = 4.0;
      if (bubble.x < wallMargin) {
        bubble.x = wallMargin;
        bubble.dx = bubble.dx.abs(); // nudge back right
      } else if (bubble.x > _screenWidth - bubble.size - wallMargin) {
        bubble.x = _screenWidth - bubble.size - wallMargin;
        bubble.dx = -bubble.dx.abs(); // nudge back left
      }

      // Game over the moment a bubble touches the bottom danger line
      if (bubble.y + bubble.size >= _screenHeight) {
        _bubbles.removeAt(i);
        _missedCount++;
        _combo = 0;
        Helpers.heavyHaptic();
        if (_missedCount >= _maxMissed) {
          _endGame();
          return;
        }
      }
    }

    // Update particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.1; // gravity
      p.lifetime += 0.04;
      p.opacity = 1.0 - p.lifetime;

      if (p.lifetime >= 1.0) {
        _particles.removeAt(i);
      }
    }

    // Update score popups
    for (int i = _scorePopups.length - 1; i >= 0; i--) {
      final s = _scorePopups[i];
      s.yOffset -= 1.5; // float upward
      s.lifetime += 0.035;
      s.opacity = 1.0 - s.lifetime;

      if (s.lifetime >= 1.0) {
        _scorePopups.removeAt(i);
      }
    }

    // No setState here: the shared game canvas repaints itself from the
    // controller every frame, so we only mutate the lists for free.
  }

  void _handleTapDown(TapDownDetails details) {
    _pendingTapStart = details.localPosition;
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isGameOver || !_isGameStarted) return;
    final up = details.localPosition;
    // Sweep from where the finger landed to where it lifted. On fast-falling
    // bubbles these differ a lot, and judging only the lift point made side
    // taps miss even though the finger clearly crossed the orb.
    final down = _pendingTapStart ?? up;
    _pendingTapStart = null;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Hit-test the top-most bubble whose inflated circle intersects the
    // tap sweep (reverse order). The hit radius is padded with touch slop
    // and a minimum size so near-miss taps on small bubbles still pop them.
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      if (b.isPopping) continue;

      final scale =
          b.isPopping ? 1.0 : 0.995 + 0.035 * sin(now / 420 + b.phase);
      final r =
          max((b.size / 2) * scale + _hitSlop, _minHitRadius);
      final cx = b.x + b.size / 2;
      final cy = b.y + b.size / 2;
      if (_distanceToSegment(cx, cy, down, up) <= r) {
        _popBubble(b);
        return;
      }
    }
  }

  /// Shortest distance from point (px, py) to the segment [a]→[b]. A tap is
  /// accepted when the bubble's center lies within its hit radius of ANY
  /// point along the finger's down→up sweep.
  double _distanceToSegment(double px, double py, Offset a, Offset b) {
    final vx = b.dx - a.dx;
    final vy = b.dy - a.dy;
    final l2 = vx * vx + vy * vy;
    double t = 0.0;
    if (l2 > 0) {
      t = ((px - a.dx) * vx + (py - a.dy) * vy) / l2;
      t = t.clamp(0.0, 1.0);
    }
    final ex = px - (a.dx + vx * t);
    final ey = py - (a.dy + vy * t);
    return sqrt(ex * ex + ey * ey);
  }

  void _popBubble(_FallingBubble bubble) {
    if (_isGameOver || bubble.isPopping) return;

    final cx = bubble.x + bubble.size / 2;
    final cy = bubble.y + bubble.size / 2;

    // Swallow only a bounced duplicate of the SAME physical tap (a few ms
    // apart at the same spot). The window/radius are intentionally tight so
    // deliberate taps on nearby bubbles always register.
    final now = DateTime.now().millisecondsSinceEpoch;
    final tapPosition = Offset(cx, cy);
    if (_lastPopTimestamp != null &&
        now - _lastPopTimestamp! < _doubleTapWindowMs &&
        _lastPopPosition != null &&
        (tapPosition - _lastPopPosition!).distance < _doubleTapRadius) {
      return;
    }
    _lastPopTimestamp = now;
    _lastPopPosition = tapPosition;

    // ── Combo & scoring ───────────────────────────────────────────────────
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _totalPopped++;
    final multiplier = 1 + ((_combo - 1) ~/ 5).clamp(0, 4);
    final points = (bubble.isGolden ? 5 : 1) * multiplier;
    final isMilestone = _combo > 1 && _combo % 5 == 0;

    // ── Audio: pitched pop chime; bell ring on combo milestones ───────────
    if (!_isMuted) {
      if (bubble.isGolden) {
        AudioService.instance
            .playSfx('assets/sounds/temple_bells.mp3', isAsset: true);
      } else if (isMilestone) {
        AudioService.instance.playSfx('assets/sounds/chime.mp3',
            isAsset: true, speed: 1.0 + (multiplier - 1) * 0.1);
      } else {
        // Pitch rises with the combo streak for a satisfying climb
        AudioService.instance.playSfx('assets/sounds/pop.mp3',
            isAsset: true, speed: (1.0 + _combo * 0.04).clamp(1.0, 1.6));
      }
    }

    // ── Haptics ───────────────────────────────────────────────────────────
    if (bubble.isGolden || isMilestone) {
      Helpers.mediumHaptic();
    } else {
      Helpers.lightHaptic();
    }

    // Spawn floating +points text
    _scorePopups.add(_ScorePopup(
      x: cx - (bubble.isGolden ? 16 : 12),
      y: cy,
      color: bubble.isGolden ? const Color(0xFFF5C531) : bubble.color,
      text: bubble.isGolden ? '+$points ॐ' : '+$points',
    ));

    // Spawn particle burst at bubble's center (golden pop = bigger burst)
    final particleCount = (bubble.isGolden ? 18 : 10) + _random.nextInt(8);
    const gold = Color(0xFFFCD34D);
    const goldPale = Color(0xFFFFF0C9);

    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = (bubble.isGolden ? 3.0 : 2.0) + _random.nextDouble() * 4.5;
      final roll = _random.nextDouble();
      final Color pColor;
      if (bubble.isGolden || roll < 0.55) {
        pColor = gold; // golden burst
      } else if (roll < 0.75) {
        pColor = goldPale;
      } else {
        pColor = bubble.color;
      }
      _particles.add(_Particle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 2.5 + _random.nextDouble() * 4.0,
        color: pColor,
      ));
    }

    // Start pop animation
    bubble.isPopping = true;
    bubble.popStartTime = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _score += points;
      if (_score > _highScore) {
        _highScore = _score;
        _saveHighScore(_highScore);
      }
    });

    // Remove after animation completes
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _bubbles.remove(bubble);
        });
      }
    });
  }

  void _endGame({bool manual = false}) {
    _gameLoopController.stop();
    _spawnTimer?.cancel();
    _wasManualQuit = manual;

    // Stop ambient background music
    AudioService.instance.stopAudio();

    // Play game over sound (via SFX player)
    if (!_isMuted) {
      AudioService.instance
          .playSfx('assets/sounds/game_over.mp3', isAsset: true);
    }

    setState(() {
      _particles.clear();
      _scorePopups.clear();
      _isGameOver = true;
    });

    // Show AdMob interstitial ad on game over
    _interstitialTimer?.cancel();
    _interstitialTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (AdmobService.instance.isInterstitialReady) {
        AdmobService.instance.showInterstitial();
      } else {
        _interstitialTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) AdmobService.instance.showInterstitial();
        });
      }
    });
  }

  void _showGameLanguagePicker(
      BuildContext context, LocaleProvider localeProvider) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = textController.text.toLowerCase().trim();
            final filteredLocales = query.isEmpty
                ? Translations.supportedLocales
                : Translations.supportedLocales.where((lang) {
                    final native = (lang['native'] ?? '').toLowerCase();
                    final name = (lang['name'] ?? '').toLowerCase();
                    final code = (lang['code'] ?? '').toLowerCase();
                    return native.contains(query) ||
                        name.contains(query) ||
                        code.contains(query);
                  }).toList();

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Translations.get('select_language',
                        locale: localeProvider.localeCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search field
                  TextField(
                    controller: textController,
                    onChanged: (_) => setSheetState(() {}),
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search language...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade400),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.grey.shade400),
                              onPressed: () {
                                textController.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade800.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Results count
                  if (query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${filteredLocales.length} ${filteredLocales.length == 1 ? 'language' : 'languages'} found',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                  // Language list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (filteredLocales.length * 60 + 20)
                          .clamp(0.0, MediaQuery.of(context).size.height * 0.5)
                          .toDouble(),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: filteredLocales.map((lang) {
                        final code = lang['code']!;
                        final native = lang['native']!;
                        final badge = lang['badge']!;
                        final isSelected = localeProvider.localeCode == code;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () async {
                              await localeProvider.setLocale(code);
                              textController.dispose();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF59E0B).withOpacity(0.15)
                                    : Colors.grey.shade800.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : Colors.grey.shade700,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF59E0B)
                                          : Colors.grey.shade700,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        badge,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          native,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? const Color(0xFFF59E0B)
                                                : Colors.white,
                                          ),
                                        ),
                                        if (query.isNotEmpty)
                                          Text(
                                            lang['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (query.isNotEmpty && filteredLocales.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 40, color: Colors.grey.shade600),
                            const SizedBox(height: 8),
                            Text(
                              'No languages found',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _restartGame() {
    _interstitialTimer?.cancel();
    _spawnTimer?.cancel();
    _gameLoopController.stop();
    _bubbles.clear();
    _startGame();
  }

  /// True while a rewarded ad (extra life / +1 mala) is loading or playing, so
  /// a single tap opens exactly one ad.
  bool _isWatchingAd = false;

  /// Ensures an AdMob rewarded ad is loaded and ready to show. If it isn't
  /// ready yet it is queued and this waits for it (up to ~20s), then returns
  /// true so the caller can present it automatically — no "tap again" needed.
  Future<bool> _ensureRewardedAdReady(ScaffoldMessengerState messenger) async {
    final admob = AdmobService.instance;

    if (!admob.isSupported) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reward ads are only available in the mobile app',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return false;
    }

    if (admob.isRewardedReady) return true;

    admob.loadRewarded(force: true);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Preparing your reward ad… 🙏',
          textAlign: TextAlign.center,
        ),
      ),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (!admob.isRewardedReady) {
      if (DateTime.now().isAfter(deadline)) break;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return false;
    }
    if (!admob.isRewardedReady) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ad is not available right now. Please try again.',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return false;
    }
    return true;
  }

  /// Watch a rewarded ad to get an extra life (miss forgiveness).
  Future<void> _watchAdForExtraLife() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_isWatchingAd) return; // one ad at a time

    // Revive is only offered when the game ended from a missed bubble,
    // not when the player quit manually via the X button.
    if (_wasManualQuit) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'You ended this game — start a new one to play again',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    setState(() => _isWatchingAd = true);
    final ready = await _ensureRewardedAdReady(messenger);
    if (!mounted) return;
    if (!ready) {
      setState(() => _isWatchingAd = false);
      return;
    }

    // Cancel the pending interstitial so it doesn't interrupt the rewarded ad
    _interstitialTimer?.cancel();

    final earned = await AdmobService.instance.showRewarded();
    if (!mounted) return;
    setState(() => _isWatchingAd = false);

    if (earned) {
      _reviveGame();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF34D399),
          content: Text(
            Translations.get('extra_life_granted',
                locale: context.read<LocaleProvider>().localeCode),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            Translations.get('ad_not_available',
                locale: context.read<LocaleProvider>().localeCode),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  /// Resume the current game after a rewarded extra life: clear the missed
  /// counter, restart the game loop + spawn timer + ambient music.
  /// Score, bubbles already on screen, and difficulty are all preserved.
  void _reviveGame() {
    _interstitialTimer?.cancel();
    setState(() {
      _missedCount = 0;
      _isGameOver = false;
    });

    // Resume ambient music
    AudioService.instance
        .playAmbientSound('assets/sounds/ambient.mp3', isAsset: true);

    // Resume the game loop
    _gameLoopController.repeat();

    // Restart the spawn timer (missed bubbles during the ad are forgiven).
    // Uses the same self-rescheduling timer as _startGame so the spawn rate
    // keeps tracking the live score after revive instead of locking in.
    _scheduleNextSpawn();

    // Spawn one immediately so gameplay resumes without a lull
    _spawnBubble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _screenWidth = constraints.maxWidth;
            _screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                _buildBackground(),
                if (!_isGameStarted)
                  _buildStartScreen()
                else if (_isGameOver)
                  _buildGameOverScreen()
                else
                  _buildGameScreen(),
                // Language switcher - top left (below the HUD during gameplay so they never overlap)
                Positioned(
                  top: _isGameStarted && !_isGameOver ? 72 : 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      final localeProvider = context.read<LocaleProvider>();
                      _showGameLanguagePicker(context, localeProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        context.watch<LocaleProvider>().badge,
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Mute toggle button - only floating on start/game-over screens
                // (during gameplay it lives inside the HUD row to avoid overlap)
                if (!_isGameStarted || _isGameOver)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildMuteButton(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Full-screen deep-space gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF05040F),
                  Color(0xFF1a0a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                  Color(0xFF1a1a2e),
                ],
                stops: [0.0, 0.3, 0.55, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Soft nebula cloud patches for depth. Built purely from a radial
        // gradient fading to transparent — NOT MaskFilter.blur — so there's
        // no risk of the square-edge renderer artifact; a gradient falloff
        // is naturally soft and circular on every renderer.
        Positioned(
          left: -_screenWidth * 0.25,
          top: -_screenHeight * 0.05,
          child: _nebulaPatch(_screenWidth * 0.9, const Color(0xFF7C3AED)),
        ),
        Positioned(
          right: -_screenWidth * 0.3,
          top: _screenHeight * 0.15,
          child: _nebulaPatch(_screenWidth * 1.0, const Color(0xFF2563EB)),
        ),
        Positioned(
          left: _screenWidth * 0.1,
          bottom: -_screenHeight * 0.15,
          child: _nebulaPatch(_screenWidth * 0.85, const Color(0xFFDB2777)),
        ),

        // Dense starfield — a mix of white, pale blue, and warm gold stars
        // scattered across the whole screen for a proper "universe" feel.
        ..._stars.map((star) {
          final idx = star['colorIndex']!;
          final color = idx == 1.0
              ? const Color(0xFFBFDBFE) // pale blue
              : idx == 2.0
                  ? const Color(0xFFFDE68A) // warm gold
                  : Colors.white;
          return Positioned(
            left: star['x']! * _screenWidth,
            top: star['y']! * _screenHeight,
            child: Container(
              width: star['size']!,
              height: star['size']!,
              decoration: BoxDecoration(
                color: color.withOpacity(star['opacity']!),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),

        // A few larger bright stars with a soft four-point sparkle cross
        ..._brightStars.map((s) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final twinkle = 0.55 + 0.45 * sin(nowMs / 900 + s['phase']!);
          final size = s['size']! * (0.8 + 0.3 * twinkle);
          return Positioned(
            left: s['x']! * _screenWidth - size * 2,
            top: s['y']! * _screenHeight - size * 2,
            child: SizedBox(
              width: size * 4,
              height: size * 4,
              child: CustomPaint(
                painter: _SparkleStarPainter(
                  size: size,
                  opacity: (0.5 + 0.5 * twinkle).clamp(0.0, 1.0),
                ),
              ),
            ),
          );
        }),

        // Tiny floating golden particles rising slowly (devotional accent)
        ..._goldenMotes.map((m) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final span = _screenHeight * 0.9;
          final drift = (nowMs / 1000.0) * m['speed']!;
          var y = m['y']! * span - drift;
          y = (y % span + span) % span;
          final twinkle = 0.6 + 0.4 * sin(nowMs / 650 + m['phase']!);
          return Positioned(
            left: m['x']! * _screenWidth,
            top: y,
            child: Container(
              width: m['size']! * (0.7 + 0.5 * twinkle),
              height: m['size']! * (0.7 + 0.5 * twinkle),
              decoration: BoxDecoration(
                color: const Color(0xFFFCD34D).withOpacity(0.4 * twinkle),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFCD34D).withOpacity(0.55 * twinkle),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// A large, very faint radial-gradient blob used to suggest a distant
  /// nebula cloud. Pure gradient falloff (no blur filter of any kind).
  Widget _nebulaPatch(double diameter, Color color) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.16),
              color.withOpacity(0.05),
              color.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isMuted
                ? Colors.white.withOpacity(0.2)
                : const Color(0xFFF59E0B).withOpacity(0.3),
          ),
        ),
        child: Icon(
          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: _isMuted ? Colors.white54 : const Color(0xFFF59E0B),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    final locCode = context.watch<LocaleProvider>().localeCode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFF59E0B),
                  Color(0xFFD97706),
                  Color(0xFFB45309),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/app_icon_foreground.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            Translations.get('divine_bubbles', locale: locCode),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Color(0xFFF59E0B),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Translations.get('pop_divine_names', locale: locCode),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.get('miss_one_game_over', locale: locCode),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    Translations.get('start_game', locale: locCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_highScore > 0) ...[
            const SizedBox(height: 24),
            Text(
              '🏆 High Score: $_highScore',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    final now = DateTime.now().millisecondsSinceEpoch;

    return Stack(
      children: [
        // All gameplay visuals on ONE canvas, repainted by the game
        // controller (no per-frame widget rebuilds = smooth flow)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            // Hard-clip every frame to the game canvas. Without this, the
            // painter draws outside its bounds: bubbles spawn above the
            // canvas (y < 0) and glow/pop effects overshoot, so orbs were
            // visibly painting over the status bar / notch and past the
            // screen edges instead of staying inside the game screen.
            child: ClipRect(
              child: CustomPaint(
                painter: _GameCanvasPainter(
                  bubbles: _bubbles,
                  particles: _particles,
                  scorePopups: _scorePopups,
                  repaint: _gameLoopController,
                ),
              ),
            ),
          ),
        ),

        // UI overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF59E0B), size: 17),
                    const SizedBox(width: 6),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_highScore > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Color(0xFFF59E0B), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            '$_highScore',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Mute toggle inside the HUD so it never collides with the other buttons
                  _buildMuteButton(),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _endGame(manual: true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Combo indicator (appears once the streak starts paying off)
        if (_combo >= 5)
          Positioned(
            top: 66,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: 1.0 + 0.1 * sin(now / 180),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$_combo',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '×${1 + ((_combo - 1) ~/ 5).clamp(0, 4)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Bottom danger zone (bubbles escape downward)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0),
                  Colors.red.withOpacity(0.6),
                  Colors.red.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Lives
        Positioned(
          bottom: 16,
          left: 16,
          child: Row(
            children: List.generate(
              _maxMissed - _missedCount,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.red.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    final locCode = context.watch<LocaleProvider>().localeCode;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/app_icon_foreground.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Translations.get('game_over', locale: locCode),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.get('bubble_missed', locale: locCode),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    Translations.get('your_score', locale: locCode),
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                      shadows: [
                        Shadow(
                          color: Color(0xFFF59E0B),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  if (_totalPopped > 0) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  color: Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '$_maxCombo',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Combo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF22D3EE).withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.blur_circular_rounded,
                                  color: Color(0xFF22D3EE), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '$_totalPopped',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Popped',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_score >= _highScore && _score > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          Translations.get('new_high_score', locale: locCode),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!_wasManualQuit) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _watchAdForExtraLife,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF34D399).withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399).withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: Color(0xFFFF6B6B), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        Translations.get('watch_ad_extra_life',
                            locale: locCode),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _restartGame,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.replay_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      Translations.get('play_again', locale: locCode),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                AudioService.instance.stopAudio();
                setState(() {
                  _bubbles.clear();
                  _isGameStarted = false;
                  _isGameOver = false;
                });
              },
              child: Text(
                Translations.get('back_to_menu', locale: locCode),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a soft radial glow using several concentric, decreasing-opacity
/// circles instead of `MaskFilter.blur`.
///
/// Some Flutter renderers (notably Impeller, default on iOS and rolling out
/// on Android) have a known bug where blurred shapes can render with a
/// faint but visible rectangular bounding-box edge — most noticeable at
/// larger blur radii (i.e. bigger bubbles). This happens no matter how the
/// drawing is clipped afterward, because it's an artifact of how the
/// renderer rasterizes the blur itself, not something wrong with our
/// clipping. Building the same soft look out of plain, un-blurred
/// concentric circles sidesteps the bug completely: every circle drawn
/// here is a perfect, unblurred circle on every renderer, so there is
/// nothing for that bug to latch onto.
void _drawLayeredGlow(
  Canvas canvas,
  Offset center,
  double baseRadius,
  Color color,
  double intensity, {
  int layers = 6,
  double spread = 0.35,
}) {
  for (int i = layers; i >= 1; i--) {
    final t = i / layers; // 1.0 = outermost/faintest ... ~1/layers = innermost
    final r = baseRadius * (1.0 + spread * t);
    final alpha = (intensity * (1 - t) * (1 - t)).clamp(0.0, 1.0);
    if (alpha <= 0.004) continue;
    canvas.drawCircle(center, r, Paint()..color = color.withOpacity(alpha));
  }
}

/// Paints a small four-point "sparkle" star: a bright circular core plus
/// two crossed diamond-shaped shafts (vertical + horizontal). Built purely
/// from solid Path fills — no MaskFilter.blur — so it renders as a crisp,
/// clean sparkle on every renderer with zero risk of any edge artifact.
class _SparkleStarPainter extends CustomPainter {
  final double size;
  final double opacity;

  _SparkleStarPainter({required this.size, required this.opacity});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final shaftPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.75);
    final corePaint = Paint()..color = Colors.white.withOpacity(opacity);

    final len = size * 2.0;
    final w = size * 0.16;

    // Vertical sparkle shaft (thin diamond)
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - len)
        ..lineTo(center.dx + w, center.dy)
        ..lineTo(center.dx, center.dy + len)
        ..lineTo(center.dx - w, center.dy)
        ..close(),
      shaftPaint,
    );

    // Horizontal sparkle shaft (thin diamond)
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - len, center.dy)
        ..lineTo(center.dx, center.dy - w)
        ..lineTo(center.dx + len, center.dy)
        ..lineTo(center.dx, center.dy + w)
        ..close(),
      shaftPaint,
    );

    // Bright core on top
    canvas.drawCircle(center, size * 0.4, corePaint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.size != size || oldDelegate.opacity != opacity;
}

class _FallingBubble {
  final String name;
  double x;
  double y;
  double dx;
  final double size;
  final double speed;
  final double phase;
  final Color color;
  final int seed;
  final bool isGolden;
  bool isPopping;
  int popStartTime;
  ui.Image? orbImage;

  _FallingBubble({
    required this.name,
    required this.x,
    required this.y,
    required this.dx,
    required this.size,
    required this.speed,
    required this.phase,
    required this.color,
    required this.seed,
    this.isGolden = false,
    this.isPopping = false,
    this.popStartTime = 0,
    this.orbImage,
  });
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  Color color;
  double lifetime; // 0.0 = just born, 1.0 = dead

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
    this.lifetime = 0.0,
  });
}

class _ScorePopup {
  final double x;
  final double y;
  final Color color;
  final String text;
  double yOffset;
  double opacity;
  double lifetime;

  _ScorePopup({
    required this.x,
    required this.y,
    required this.color,
    required this.text,
    this.yOffset = 0,
    this.opacity = 1.0,
    this.lifetime = 0.0,
  });
}

/// Custom painter that renders a bubble as a clean, plain glass orb:
/// - Semi-transparent glass-like core with the bubble's colour.
/// - Soft glowing rim with a thin bright edge.
/// - Top-left highlight for a floating-glass feel.
/// - No patterns inside: pure minimal soap-bubble look.
class _BubblePainter extends CustomPainter {
  final Color color;
  final int seed;
  final int tick;
  final double rotation;

  _BubblePainter({
    required this.color,
    required this.seed,
    this.tick = 0,
    this.rotation = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final time = tick * 0.1;

    // Soft breathing pulse (0.6 .. 1.0) driving the glow intensity
    final pulse = 0.7 + 0.3 * sin(time * 1.1 + (seed % 11));

    // ── Crystal-clear glass core: transparent center, colour concentrates
    // toward the rim (like real glass) instead of a solid colour fill ──────
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.05,
        colors: [
          Colors.white.withOpacity(0.24),
          color.withOpacity(0.08),
          color.withOpacity(0.10),
          color.withOpacity(0.34),
        ],
        stops: const [0.0, 0.45, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, corePaint);

    // Vertical glass tint (subtle refraction feel) — kept very light so the
    // center reads as clear glass rather than a tinted fill
    final tintPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.10),
          Colors.transparent,
          color.withOpacity(0.14),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, tintPaint);

    // ── Very subtle inner shadow for depth (darkening at the bottom) ───────
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.28, 0.42),
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.03),
          Colors.black.withOpacity(0.12),
        ],
        stops: const [0.55, 0.84, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, shadowPaint);

    // ── Soft rim glow via layered circles (NOT MaskFilter.blur — see the
    // _drawLayeredGlow doc comment for why blur is avoided entirely here).
    // Two passes approximate the old wide-soft-aura + tighter-bright-ring
    // look, and — since neither uses blur — this is now perfectly safe to
    // bake into the small cached orb image with zero risk of any square
    // edge artifact, on any renderer.
    _drawLayeredGlow(canvas, center, radius, color, 0.28 + 0.16 * pulse,
        layers: 6, spread: 0.30);
    _drawLayeredGlow(canvas, center, radius, color, 0.30 + 0.18 * pulse,
        layers: 4, spread: 0.09);

    final ringColored = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.026
      ..color = color.withOpacity(0.9 + 0.1 * pulse);
    canvas.drawCircle(center, radius * 0.99, ringColored);

    final ringBright = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.018
      ..color = Colors.white.withOpacity(0.95);
    canvas.drawCircle(center, radius * 0.993, ringBright);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.seed != seed ||
      oldDelegate.tick != tick ||
      oldDelegate.rotation != rotation;
}

/// Paints every bubble, particle burst and floating score popup onto one
/// shared canvas. Repainted each tick by the game-loop controller, so the
/// widget tree stays completely static while playing (smooth, no stutter).
class _GameCanvasPainter extends CustomPainter {
  final List<_FallingBubble> bubbles;
  final List<_Particle> particles;
  final List<_ScorePopup> scorePopups;

  _GameCanvasPainter({
    required this.bubbles,
    required this.particles,
    required this.scorePopups,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final b in bubbles) {
      _paintBubble(canvas, b, now);
    }

    // Particle bursts
    for (final p in particles) {
      final op = p.opacity.clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withOpacity(op);
      canvas.drawCircle(Offset(p.x, p.y), p.size / 2, paint);
    }

    // Floating score popups
    for (final s in scorePopups) {
      final tp = TextPainter(
        text: TextSpan(
          text: s.text,
          style: TextStyle(
            fontSize: s.text.length > 3 ? 24 : 22,
            fontWeight: FontWeight.bold,
            color: s.color.withOpacity(s.opacity.clamp(0.0, 1.0)),
            shadows: [
              Shadow(color: s.color.withOpacity(0.6), blurRadius: 12),
              Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(s.x, s.y + s.yOffset));
    }
  }

  void _paintBubble(Canvas canvas, _FallingBubble b, int now) {
    double opacity = 1.0;
    double scale = 1.0;
    double flash = 0.0;

    if (b.isPopping) {
      final elapsed = now - b.popStartTime;
      final progress = (elapsed / 350.0).clamp(0.0, 1.0);
      scale = 1.0 + progress * 1.15;
      opacity = (1.0 - progress).clamp(0.0, 1.0);
      flash = sin(progress * pi).clamp(0.0, 1.0);
    } else {
      scale = 0.995 + 0.035 * sin(now / 420 + b.phase);
    }

    final rotation = (now / 9000) * 2 * pi + b.phase;
    final cx = b.x + b.size / 2;
    final cy = b.y + b.size / 2;

    canvas.save();
    if (opacity < 1.0) {
      // Bounds must comfortably contain the glow's blur spread, or the blur
      // gets hard-clipped at this rect's edge — which shows up as a visible
      // square box behind the bubble (Rect.fromCircle's bounding box is a
      // square). The pop "flash" glow can blur out to roughly 3x its sigma
      // beyond the drawn circle, so the margin here is generous on purpose.
      canvas.saveLayer(
        Rect.fromCircle(center: Offset(cx, cy), radius: b.size * 3.5),
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Everything is drawn relative to the bubble centre, scaled for the
    // breathing / pop animation.
    canvas.translate(cx, cy);
    canvas.scale(scale);

    _paintGlow(canvas, b, flash);

    // The glass orb: draw the cached pre-rendered image when ready,
    // otherwise paint it directly while the image is still being captured.
    final img = b.orbImage;
    if (img != null) {
      canvas.save();
      canvas.rotate(rotation);
      // Draw the cached orb at the same padded scale it was captured at.
      final destSize = b.size * _BubbleGameScreenState._orbCanvasPad;
      // A simple circular clip at the image's own edge is enough here.
      // Nothing in the cached image uses MaskFilter.blur anymore (see
      // _drawLayeredGlow / _BubblePainter), so there's no blur-clamping
      // artifact that could bleed to the image's square corners in the
      // first place — this clip is just a clean safety net.
      canvas.clipPath(
        Path()
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: destSize / 2)),
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(-destSize / 2, -destSize / 2, destSize, destSize),
        Paint(),
      );
      canvas.restore();
    } else {
      canvas.save();
      canvas.translate(-b.size / 2, -b.size / 2);
      _BubblePainter(
        color: b.color,
        seed: b.seed,
        tick: now ~/ 80,
        rotation: rotation,
      ).paint(canvas, Size(b.size, b.size));
      canvas.restore();
    }

    // White glow flash overlay while popping
    if (b.isPopping && flash > 0) {
      final rect = Rect.fromCircle(center: Offset.zero, radius: b.size / 2);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.85 * flash),
            Colors.white.withOpacity(0.2 * flash),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      canvas.drawCircle(Offset.zero, b.size / 2, paint);
    }

    // Soft dark halo behind the text so the name stays clearly readable on
    // any bubble colour (drawn inside the saveLayer, so it pops/fades too).
    // Strengthened a bit since the glass core is now much more transparent.
    final haloRadius = b.size * 0.36;
    canvas.drawCircle(
      Offset.zero,
      haloRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withOpacity(0.48),
            Colors.black.withOpacity(0.28),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset.zero, radius: haloRadius)),
    );

    // Deity name perfectly centred in the orb. Font shrinks for longer names
    // so every name fits comfortably inside the circle.
    final nameLength = b.name.characters.length;
    final fontSize = b.size *
        (nameLength <= 2
            ? 0.30
            : nameLength <= 4
                ? 0.24
                : nameLength <= 5
                    ? 0.20
                    : 0.17);
    final tp = TextPainter(
      text: TextSpan(
        text: b.name,
        style: GoogleFonts.notoSerifDevanagari(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.85),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 9,
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      // Devanagari fonts reserve extra ascent space for tall matras/conjuncts
      // (े, ि, ligatures, etc.) even on glyphs that don't use them — so with
      // height:1.0 alone, tp.height is still noticeably taller than the actual
      // visible ink, and -tp.height/2 centers that padded box instead of the
      // glyphs, pushing names visibly high inside the bubble. Trimming the
      // reserved leading at the box edges makes tp.height tightly hug the
      // real glyph bounds, so -tp.height/2 lands on the true visual center —
      // this is what actually fixes centering, not the height:1.0 alone.
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout(maxWidth: b.size * 0.86);
    tp.paint(
      canvas,
      Offset(-tp.width / 2, -tp.height / 2),
    );

    if (opacity < 1.0) canvas.restore();
    canvas.restore();
  }

  void _paintGlow(Canvas canvas, _FallingBubble b, double flash) {
    final r = b.size / 2;

    // Soft neon aura via layered circles — NOT MaskFilter.blur. See the
    // _drawLayeredGlow doc comment: some renderers (Impeller) show a faint
    // square edge around blurred shapes, worse on bigger blur radii, which
    // is exactly the "square glow on round bubbles, worse on big ones"
    // symptom. Layered plain circles give the same soft look with zero
    // risk of that artifact, since no blur is ever invoked.
    _drawLayeredGlow(canvas, Offset.zero, r, b.color, 0.40,
        layers: 6, spread: 0.45);

    // Golden ॐ bubbles radiate a rich warm halo
    if (b.isGolden) {
      _drawLayeredGlow(canvas, Offset.zero, r, const Color(0xFFFFD54F), 0.42,
          layers: 5, spread: 0.35);
    }

    // Strong glow flash while popping
    if (flash > 0) {
      _drawLayeredGlow(
        canvas,
        Offset.zero,
        r * (0.6 + flash * 1.3),
        b.color,
        (0.22 + flash * 0.65).clamp(0.0, 1.0),
        layers: 6,
        spread: 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GameCanvasPainter oldDelegate) => true;
}
