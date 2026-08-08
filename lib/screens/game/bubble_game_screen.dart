import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/locale_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../utils/translations.dart';

class BubbleGameScreen extends StatefulWidget {
  const BubbleGameScreen({super.key});

  @override
  State<BubbleGameScreen> createState() => _BubbleGameScreenState();
}

class _BubbleGameScreenState extends State<BubbleGameScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _divineNames = [
    '🕉️ ॐ',
    'राम',
    'कृष्ण',
    'शिव',
    'हनुमान',
    'गणेश',
    'लक्ष्मी',
    'सरस्वती',
    'दुर्गा',
    'नारायण',
  ];

  final List<_FallingBubble> _bubbles = [];
  final List<_Particle> _particles = [];
  final List<_ScorePopup> _scorePopups = [];
  int _score = 0;
  int _highScore = 0;
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

  late AnimationController _gameLoopController;
  Timer? _spawnTimer;
  final Random _random = Random();
  late double _screenWidth;
  late double _screenHeight;

  // Pre-generated star positions for background
  final List<Map<String, double>> _stars = [];

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateGame);

    // Pre-generate stars
    for (int i = 0; i < 30; i++) {
      _stars.add({
        'x': _random.nextDouble(),
        'y': _random.nextDouble(),
        'opacity': 0.2 + _random.nextDouble() * 0.5,
        'size': 1.0 + _random.nextDouble() * 2.0,
      });
    }

    // Load persisted settings
    _loadHighScore();
    _loadMuteSetting();

    // Preload rewarded ad so the extra-life option is ready on game over
    AdService.instance.loadRewarded();
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
      _isGameOver = false;
      _isGameStarted = true;
      _baseSpeed = 1.0;
      _missedCount = 0;
      _wasManualQuit = false;
    });

    // Start gentle ambient meditation music on loop
    AudioService.instance.playAmbientSound('assets/sounds/ambient.mp3', isAsset: true);

    // Preload interstitial so it's ready when the game ends
    AdService.instance.loadInterstitial();

    _gameLoopController.repeat();

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isGameOver && mounted) {
        _spawnBubble();
      }
    });

    // Spawn initial bubbles
    _spawnBubble();
    Future.delayed(const Duration(milliseconds: 400), _spawnBubble);
    Future.delayed(const Duration(milliseconds: 800), _spawnBubble);
  }

  void _spawnBubble() {
    if (_screenWidth <= 0) return;

    final name = _divineNames[_random.nextInt(_divineNames.length)];
    final bubbleSize = 50.0 + _random.nextDouble() * 30;
    final x = _random.nextDouble() * (_screenWidth - bubbleSize - 20) + 10;

    setState(() {
      _bubbles.add(_FallingBubble(
        name: name,
        x: x,
        y: -bubbleSize,
        size: bubbleSize,
        speed: _baseSpeed + _random.nextDouble() * 0.5,
        color: _getRandomDivineColor(),
      ));
    });

    _baseSpeed += 0.05;
  }

  Color _getRandomDivineColor() {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFA78BFA),
      const Color(0xFFF97316),
      const Color(0xFF34D399),
      const Color(0xFF60A5FA),
      const Color(0xFFF472B6),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _updateGame() {
    if (_isGameOver || !_isGameStarted) return;

    bool changed = false;
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final bubble = _bubbles[i];

      // Skip position update for popping bubbles but still trigger rebuilds for animation
      if (bubble.isPopping) {
        changed = true;
        continue;
      }

      bubble.y += bubble.speed;

      // Check if bubble reached bottom
      if (bubble.y > _screenHeight + 20) {
        _bubbles.removeAt(i);
        _missedCount++;
        changed = true;
        if (_missedCount >= _maxMissed) {
          _endGame();
          return;
        }
      } else {
        changed = true;
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

    if (!changed && (_particles.isNotEmpty || _scorePopups.isNotEmpty)) changed = true;

    if (changed) setState(() {});
  }

  void _popBubble(_FallingBubble bubble) {
    if (_isGameOver || bubble.isPopping) return;

    // Play pop sound (via SFX player so ambient continues uninterrupted)
    if (!_isMuted) {
      AudioService.instance.playSfx('assets/sounds/pop.mp3', isAsset: true);
    }

    final cx = bubble.x + bubble.size / 2;
    final cy = bubble.y + bubble.size / 2;

    // Spawn floating +1 score text
    _scorePopups.add(_ScorePopup(
      x: cx - 12,
      y: cy,
      color: bubble.color,
    ));

    // Spawn particle burst at bubble's center
    final particleCount = 8 + _random.nextInt(6);

    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 2.0 + _random.nextDouble() * 4.0;
      _particles.add(_Particle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 3.0 + _random.nextDouble() * 4.0,
        color: bubble.color,
      ));
    }

    // Start pop animation
    bubble.isPopping = true;
    bubble.popStartTime = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _score++;
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
      AudioService.instance.playSfx('assets/sounds/game_over.mp3', isAsset: true);
    }

    setState(() {
      _particles.clear();
      _scorePopups.clear();
      _isGameOver = true;
    });

    // Show interstitial shortly after the game-over screen renders
    // (cancelled if the player restarts before it fires). If the ad hasn't
    // finished loading yet (very fast game), retry once after another delay.
    _interstitialTimer?.cancel();
    _interstitialTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (AdService.instance.isInterstitialReady) {
        AdService.instance.showInterstitial();
      } else {
        _interstitialTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) AdService.instance.showInterstitial();
        });
      }
    });
  }

  void _showGameLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
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
                    Translations.get('select_language', locale: localeProvider.localeCode),
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
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                  // Language list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (filteredLocales.length * 60 + 20)
                          .clamp(0.0, MediaQuery.of(context).size.height * 0.5).toDouble(),
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
                            onTap: () {
                              localeProvider.setLocale(code);
                              textController.dispose();
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                          color: isSelected ? Colors.black : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          native,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                            color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
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
                            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade600),
                            const SizedBox(height: 8),
                            Text(
                              'No languages found',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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

  /// Watch a rewarded ad to get an extra life (miss forgiveness).
  Future<void> _watchAdForExtraLife() async {
    final messenger = ScaffoldMessenger.of(context);

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

    if (!AdService.instance.isEnabled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reward ads are not available in this build',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    if (!AdService.instance.isRewardedReady) {
      // Queue one up and ask the user to tap again once it's loaded
      AdService.instance.loadRewarded();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Preparing your reward ad — please tap again in a moment 🙏',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    // Cancel the pending interstitial so it doesn't interrupt the rewarded ad
    _interstitialTimer?.cancel();

    final earned = await AdService.instance.showRewarded();
    if (!mounted) return;

    if (earned) {
      _reviveGame();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF34D399),
          content: const Text(
            '🙏 Extra life granted! Keep going!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ad is not available right now. Please try again.',
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
    AudioService.instance.playAmbientSound('assets/sounds/ambient.mp3', isAsset: true);

    // Resume the game loop
    _gameLoopController.repeat();

    // Restart the spawn timer (missed bubbles during the ad are forgiven)
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isGameOver && mounted) {
        _spawnBubble();
      }
    });

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
                if (!_isGameStarted) _buildStartScreen()
                else if (_isGameOver) _buildGameOverScreen()
                else _buildGameScreen(),
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
        // Full-screen gradient background using Positioned.fill
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a0a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                  Color(0xFF1a1a2e),
                ],
              ),
            ),
          ),
        ),
        // Twinkling stars
        ..._stars.map((star) => Positioned(
          left: star['x']! * (_screenWidth),
          top: star['y']! * (_screenHeight * 0.6),
          child: Container(
            width: star['size']!,
            height: star['size']!,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(star['opacity']!),
              shape: BoxShape.circle,
            ),
          ),
        )),
      ],
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
            child: const Center(
              child: Text('🕉️', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Divine Bubbles',
            style: TextStyle(
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
            'Pop the divine names before they fall!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Miss one and the game is over!',
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Start Game',
                    style: TextStyle(
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
        // Bubbles
        ..._bubbles.map((bubble) {
          double opacity = 1.0;
          double scale = 1.0;

          if (bubble.isPopping) {
            final elapsed = now - bubble.popStartTime;
            final progress = (elapsed / 350.0).clamp(0.0, 1.0);
            scale = 1.0 + progress * 0.8;
            opacity = 1.0 - progress;
          }

          return Positioned(
            left: bubble.x,
            top: bubble.y,
            child: GestureDetector(
              onTap: () => _popBubble(bubble),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: bubble.size,
                    height: bubble.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          bubble.color.withOpacity(0.9),
                          bubble.color.withOpacity(0.6),
                          bubble.color.withOpacity(0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: bubble.color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        bubble.name,
                        style: TextStyle(
                          fontSize: bubble.size * 0.22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        // Floating score text
        ..._scorePopups.map((s) => Positioned(
          left: s.x,
          top: s.y + s.yOffset,
          child: Opacity(
            opacity: s.opacity.clamp(0.0, 1.0),
            child: Text(
              '+1',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: s.color,
                shadows: [
                  Shadow(
                    color: s.color.withOpacity(0.6),
                    blurRadius: 12,
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        )),

        // Particle burst effects
        ..._particles.map((p) => Positioned(
          left: p.x - p.size / 2,
          top: p.y - p.size / 2,
          child: Opacity(
            opacity: p.opacity.clamp(0.0, 1.0),
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                color: p.color.withOpacity(p.opacity.clamp(0.0, 1.0)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: p.color.withOpacity(p.opacity.clamp(0.0, 0.5)),
                    blurRadius: p.size * 0.5,
                  ),
                ],
              ),
            ),
          ),
        )),

        // UI overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 17),
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 13),
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
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom danger zone
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
              child: const Center(
                child: Text('😇', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A bubble was missed...',
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
                  const Text(
                    'Your Score',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
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
                  if (_score >= _highScore && _score > 0) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'New High Score!',
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, color: Color(0xFFFF6B6B), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Watch Ad • Extra Life',
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Play Again',
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
              child: const Text(
                'Back to Menu',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallingBubble {
  final String name;
  double x;
  double y;
  final double size;
  final double speed;
  final Color color;
  bool isPopping;
  int popStartTime;

  _FallingBubble({
    required this.name,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    this.isPopping = false,
    this.popStartTime = 0,
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
  double yOffset;
  double opacity;
  double lifetime;

  _ScorePopup({
    required this.x,
    required this.y,
    required this.color,
    this.yOffset = 0,
    this.opacity = 1.0,
    this.lifetime = 0.0,
  });
}
