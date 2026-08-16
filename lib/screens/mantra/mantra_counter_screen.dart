import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mantra_provider.dart';
import '../../providers/tap_sound_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class MantraCounterScreen extends StatefulWidget {
  const MantraCounterScreen({super.key});

  @override
  State<MantraCounterScreen> createState() => _MantraCounterScreenState();
}

class _MantraCounterScreenState extends State<MantraCounterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<_FloatingName> _floatingNames = [];
  final List<_Sparkle> _sparkles = [];
  final List<_Shockwave> _shockwaves = [];
  final List<_ScorePopup> _scorePopups = [];
  final List<_MalaCelebration> _malaCelebrations = [];
  Timer? _nameAnimationTimer;
  int _sparkleFrameCounter = 0;
  final Random _random = Random();

  // Floating names rise up from the mala circle and keep floating toward the
  // top of the screen. The cap is only a safety net so a bubble can never fly
  // off-screen — it hovers at the top and fades out. The bubbles render on a
  // back layer, so the chant count and session timer stay readable above them.
  static const double _maxNameRiseY = -430;

  // Addictive factor: combo tracking
  int _tapCombo = 0;
  DateTime _lastTapTime = DateTime.now();

  /// True while a reward ad is loading/playing for the +1 Mala bonus, so a
  /// single click opens exactly one ad (no double-tap double ads).
  bool _isWatchingAd = false;

  /// Track count of each divine name that floated up this session
  final Map<String, int> _nameCounts = {};

  /// Map each mantra to display names in Devanagari
  /// First entry = the FULL mantra text, second = short name
  static const Map<String, List<String>> _displayNameMap = {
    'Om Namah Shivaya': ['ॐ नमः शिवाय', 'शिव'],
    'Hare Krishna': ['हरे कृष्ण', 'कृष्णा'],
    'Shri Ram': ['श्री राम', 'राम'],
    'Om': ['ॐ', 'प्रणव'],
    'Gayatri Mantra': ['गायत्री मंत्र'],
    'Om Mani Padme Hum': ['ॐ मणि पद्मे हूँ', 'मणि'],
    'Radhe Radhe': ['राधे राधे', 'राधे'],
    'Sita Ram': ['सीता राम', 'राम'],
    'Hanuman Chalisa': ['हनुमान चालीसा', 'हनुमान'],
    'Om Namo Bhagavate Vasudevaya': ['ॐ नमो भगवते वासुदेवाय', 'वासुदेव'],
    'Maha Mrityunjaya Mantra': ['ॐ त्र्यम्बकं यजामहे', 'मृत्युंजय'],
    'Om Gam Ganapataye Namah': ['ॐ गं गणपतये नमः', 'गणेश'],
    'Om Shreem Maha Lakshmiyei Namah': ['ॐ श्रीं महा लक्ष्म्यै नमः', 'लक्ष्मी'],
    'Om Aim Saraswatyai Namah': ['ॐ ऐं सरस्वत्यै नमः', 'सरस्वती'],
    'Om Namo Narayanaya': ['ॐ नमो नारायणाय', 'नारायण'],
    'Jai Siya Ram': ['जय सीया राम', 'सीया राम'],
    'Om Hreem Shreem Kleem': ['ॐ ह्रीं श्रीं क्लीं', 'श्री माता'],
    'Om Dum Durgayei Namah': ['ॐ दुं दुर्गायै नमः', 'दुर्गा'],
    'Jai Shri Krishna': ['जय श्री कृष्ण', 'कृष्ण'],
    'Om Shanti Om': ['ॐ शांति ॐ', 'शांति'],
    'So Hum': ['सोऽहम्', 'सोहम'],
    'Aham Brahmasmi': ['अहं ब्रह्मास्मि', 'ब्रह्म'],
    'Shivoham': ['शिवोऽहम्', 'शिव'],
    'Sai Ram': ['साई राम', 'साई'],
    'Govinda Jaya Jaya': ['गोविंद जय जय', 'गोविंद'],
    'Radha Krishna': ['राधा कृष्ण', 'राधा'],
    'Lakshmi Narayana': ['लक्ष्मी नारायण', 'लक्ष्मी'],
    'Om Hanumate Namah': ['ॐ हनुमते नमः', 'हनुमान'],
    'Hare Murare': ['हरे मुरारे', 'मुरारी'],
    'Narayana Narayana': ['नारायण नारायण', 'नारायण'],
  };

  /// Unique deity color for each mantra's floating name
  static const Map<String, Color> _mantraColorMap = {
    'Om Namah Shivaya': Color(0xFF81D4FA),       // Shiva — pale celestial blue
    'Hare Krishna': Color(0xFF2563EB),            // Krishna — royal blue
    'Shri Ram': Color(0xFF059669),                // Rama — deep emerald green
    'Om': Color(0xFFF59E0B),                      // Om — sacred gold
    'Gayatri Mantra': Color(0xFFFFB300),          // Gayatri — radiant gold
    'Om Mani Padme Hum': Color(0xFFDB2777),       // Lotus — rose pink
    'Radhe Radhe': Color(0xFFEC4899),             // Radha — blush pink
    'Sita Ram': Color(0xFF10B981),                // Sita — forest green
    'Hanuman Chalisa': Color(0xFFEA580C),         // Hanuman — saffron orange
    'Om Namo Bhagavate Vasudevaya': Color(0xFF4F46E5), // Vasudeva — indigo
    'Maha Mrityunjaya Mantra': Color(0xFF06B6D4), // Mrityunjaya — cyan
    'Om Gam Ganapataye Namah': Color(0xFFDC2626), // Ganesha — vermillion red
    'Om Shreem Maha Lakshmiyei Namah': Color(0xFFEAB308), // Lakshmi — bright gold
    'Om Aim Saraswatyai Namah': Color(0xFFA78BFA), // Saraswati — violet
    'Om Namo Narayanaya': Color(0xFF1D4ED8),      // Narayana — deep blue
    'Jai Siya Ram': Color(0xFF047857),            // Siya Ram — rich green
    'Om Hreem Shreem Kleem': Color(0xFFEC4899),   // Divine Mother — rose pink
    'Om Dum Durgayei Namah': Color(0xFFB91C1C),   // Durga — deep crimson
    'Jai Shri Krishna': Color(0xFF2563EB),         // Krishna — royal blue
    'Om Shanti Om': Color(0xFF0EA5E9),             // Shanti — calm sky blue
    'So Hum': Color(0xFF14B8A6),                   // So Hum — breath teal
    'Aham Brahmasmi': Color(0xFF8B5CF6),           // Brahman — violet
    'Shivoham': Color(0xFF7C3AED),                 // Shiva — deep purple
    'Sai Ram': Color(0xFFF97316),                  // Sai — saffron orange
    'Govinda Jaya Jaya': Color(0xFF16A34A),        // Govinda — fresh green
    'Radha Krishna': Color(0xFFF472B6),            // Radha — pink
    'Lakshmi Narayana': Color(0xFFF59E0B),         // Lakshmi — golden
    'Om Hanumate Namah': Color(0xFFEA580C),        // Hanuman — saffron
    'Hare Murare': Color(0xFFDB2777),              // Murare — magenta
    'Narayana Narayana': Color(0xFF1E40AF),        // Narayana — royal indigo
  };

  @override
  void initState() {
    super.initState();
    // Preload the rewarded ad so the bonus button works on the first tap
    AdService.instance.loadRewarded();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameAnimationTimer?.cancel();
    // Never let auto-mode chanting continue when the screen is closed
    context.read<MantraProvider>().stopAutoMode();
    _pulseController.dispose();
    super.dispose();
  }

  /// Always show the FULL mantra text (first entry in devanagari)
  String _getDisplayName(MantraProvider provider) {
    final mantraName = provider.selectedMantra.name;
    final names = _displayNameMap[mantraName];
    if (names != null && names.isNotEmpty) {
      return names[0]; // Full mantra text only
    }
    return mantraName;
  }

  /// Spawn a floating divine name
  void _spawnFloatingName(MantraProvider provider) {
    // Random initial horizontal offset from center (-30 to +30)
    final xOffset = _random.nextDouble() * 60 - 30;
    // Random horizontal velocity: some go left (-), some right (+)
    final vx = (_random.nextDouble() * 2.0 - 1.0) * 1.5;
    // Random vertical speed: brisk rise so the names visibly float up from
    // the mala circle and travel toward the top of the screen
    final vy = -4.0 - _random.nextDouble() * 1.0; // -4.0 to -5.0
    // Random rotation speed: spin in either direction (radians per frame)
    final rotationSpeed = (_random.nextDouble() * 2.0 - 1.0) * 0.06;
    // Random font size for variety
    final fontSize = 18.0 + _random.nextDouble() * 14.0; // 18 to 32
    final displayName = _getDisplayName(provider);
    _nameCounts[displayName] = (_nameCounts[displayName] ?? 0) + 1;

    // Use deity-specific color, fall back to primary gold
    final mantraName = provider.selectedMantra.name;
    final color = _mantraColorMap[mantraName] ?? AppColors.primary;

    _floatingNames.add(_FloatingName(
      name: displayName,
      color: color,
      x: xOffset,
      vx: vx,
      vy: vy,
      yOffset: -20 - _random.nextDouble() * 15, // Start just above the button
      rotationSpeed: rotationSpeed,
      fontSize: fontSize,
      wobblePhase: _random.nextDouble() * pi * 2,
      wobbleAmplitude: 3.0 + _random.nextDouble() * 6.0,  // 3-9 px sway
      wobbleSpeed: 0.04 + _random.nextDouble() * 0.07,      // slow to medium sway
      bounceAmplitude: 1.5 + _random.nextDouble() * 2.5,    // 1.5-4 px vertical bob
    ));
    _startNameAnimation();
  }

  /// Start the floating name animation loop
  void _startNameAnimation() {
    if (_nameAnimationTimer != null) return;
    _nameAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 33), // ~30 FPS
      (_) => _updateFloatingNames(),
    );
  }

  /// Update floating name positions, opacity, and remove dead ones
  void _updateFloatingNames() {
    _sparkleFrameCounter++;

    // Update shockwaves
    for (final sw in _shockwaves) {
      sw.radius += 6.0;
      sw.opacity = (1.0 - sw.lifetime).clamp(0.0, 0.6);
      sw.lifetime += 0.04; // ~25 frames
    }
    _shockwaves.removeWhere((sw) => sw.lifetime >= 1.0);

    // Update score popups
    for (final sp in _scorePopups) {
      sp.yOffset += sp.vy;
      sp.lifetime += 0.025;
      sp.opacity = (1.0 - sp.lifetime).clamp(0.0, 1.0);
      sp.scale = 1.0 + sp.lifetime * 0.5;
    }
    _scorePopups.removeWhere((sp) => sp.lifetime >= 1.0);

    for (final n in _floatingNames) {
      n.x += n.vx;              // Drift sideways (left or right)
      n.yOffset += n.vy;        // Float upward at varied speed
      // Safety cap: never rise high enough to cover the session timer
      // above the mala — hover in place and fade out instead.
      if (n.yOffset < _maxNameRiseY) {
        n.yOffset = _maxNameRiseY;
        n.vy = 0;
      }
      n.rotation += n.rotationSpeed;  // Spin!
      n.lifetime += 0.01;       // ~100 frames = ~3 seconds
      n.opacity = (1.0 - n.lifetime).clamp(0.0, 1.0);

      // Wobble / bounce: advance phase
      n.wobblePhase += n.wobbleSpeed;

      // Entrance animation: scale in from 0 with elastic pop-in (first ~15 frames)
      if (n.entranceAge < 1.0) {
        n.entranceAge += 0.07; // completes in ~15 frames
        final t = n.entranceAge.clamp(0.0, 1.0);
        // Cubic ease-out with elastic overshoot — pops in, bounces slightly, settles
        final eased = 1.0 - pow(1.0 - t, 3);
        final overshoot = sin(t * pi * 5) * (1 - t) * 0.1;
        n.scale = eased + overshoot;
      } else {
        // Normal gentle pulse after entrance completes
        n.scale = 1.0 + sin(n.wobblePhase) * 0.04; // 0.96 – 1.04 gentle pulse
      }

      // Pop effect: rapid scale up + faster fade in last ~15 % of life
      if (n.lifetime > 0.85) {
        final popT = (n.lifetime - 0.85) / 0.15; // 0.0 -> 1.0
        final eased = popT * popT; // ease-in curve
        n.scale *= (1.0 + eased * 0.30); // Scale up by up to 30 %
        n.opacity *= (1.0 - eased * 0.7); // Fade even faster during pop
      }

      // Drop sparkles at name's current position every 2 frames
      if (_sparkleFrameCounter % 2 == 0) {
        // Use the base position for sparkles (ignore wobble)
        _spawnSparkle(n.x, n.yOffset, n.lifetime);
      }
    }
    _floatingNames.removeWhere((n) => n.lifetime >= 1.0);

    // Update sparkles
    for (final s in _sparkles) {
      s.x += s.driftX;           // Drift outward
      s.yOffset += s.driftY;     // Drift slightly
      s.size *= 0.92;            // Shrink over time
      s.lifetime += 0.04;        // ~25 frames
      s.opacity = (1.0 - s.lifetime).clamp(0.0, 1.0);
    }
    _sparkles.removeWhere((s) => s.lifetime >= 1.0 || s.size < 1.0);

    // Update mala celebrations (golden ring flash)
    for (final mc in _malaCelebrations) {
      mc.lifetime += 0.02; // ~50 frames ≈ 1.6s
      mc.opacity = (1.0 - mc.lifetime).clamp(0.0, 1.0);
      mc.ringRadius = 130 + mc.lifetime * 160; // expand outward
      mc.scale = 1.0 + mc.lifetime * 0.6; // text grows slightly
    }
    _malaCelebrations.removeWhere((mc) => mc.lifetime >= 1.0);

    // Auto-stop timer when nothing left
    if (_floatingNames.isEmpty && _sparkles.isEmpty &&
        _shockwaves.isEmpty && _scorePopups.isEmpty &&
        _malaCelebrations.isEmpty) {
      _nameAnimationTimer?.cancel();
      _nameAnimationTimer = null;
    }

    if (mounted) setState(() {});
  }

  /// Spawn a brief sparkle particle at the given position
  void _spawnSparkle(double x, double y, double nameLifetime) {
    // Fewer sparkles as the name fades out
    if (nameLifetime > 0.6 && _random.nextDouble() > 0.3) return;

    _sparkles.add(_Sparkle(
      x: x + (_random.nextDouble() * 6 - 3),   // Small random offset
      yOffset: y + (_random.nextDouble() * 6 - 3),
      size: 2.0 + _random.nextDouble() * 3.0,   // 2-5 px
      driftX: (_random.nextDouble() * 2 - 1) * 0.5,  // Gentle outward drift
      driftY: (_random.nextDouble() * 2 - 1) * 0.5,
    ));
  }

  /// Get the actual mantra index from a favorite list position
  int _getFavoriteIndex(MantraProvider provider, int favPosition) {
    final mantra = provider.favoriteMantras[favPosition];
    return provider.mantras.indexOf(mantra);
  }

  void _resetNameCounts() {
    _nameCounts.clear();
  }

  void _onTap(MantraProvider provider) {
    if (!provider.isCounting) {
      _resetNameCounts();
      provider.startCounting();
    }

    provider.addChant();
    Helpers.lightHaptic();

    // Play selected tap sound (or skip if silent)
    final tapProvider = context.read<TapSoundProvider>();
    if (!tapProvider.isSilent && tapProvider.soundAssetPath != null) {
      AudioService.instance.playSfx(tapProvider.soundAssetPath!, isAsset: true);
    }

    // Spawn floating divine name
    _spawnFloatingName(provider);

    // Spawn tap shockwave ripple (addictive visual feedback)
    _spawnShockwave();

    // Spawn score popup (+1)
    _spawnScorePopup(provider.currentCount);

    // 🕉️ Mala complete celebration — golden ring flash + text on the 108th tap
    if (provider.isMalaComplete) {
      _spawnMalaCelebration();
    }

    // Track combo for addictiveness
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 600) {
      _tapCombo++;
    } else {
      _tapCombo = 0;
    }
    _lastTapTime = now;

    // Pulse animation
    _pulseController.forward().then((_) => _pulseController.reverse());
  }

  /// Show a rewarded ad and grant +1 mala of bonus chants on completion.
  ///
  /// A single tap reliably opens exactly ONE ad: if the ad isn't loaded yet it
  /// is queued and presented automatically the moment it's ready (instead of
  /// asking the user to tap again), and [_isWatchingAd] blocks any double-tap
  /// from opening a second ad.
  Future<void> _watchAdForBonus(MantraProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_isWatchingAd) return; // one ad at a time
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

    setState(() => _isWatchingAd = true);

    // If the ad isn't ready yet, queue it and wait for it to load, then show
    // it automatically (up to ~20s so we never wait forever).
    if (!AdService.instance.isRewardedReady) {
      AdService.instance.loadRewarded();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Preparing your reward ad… 🙏',
            textAlign: TextAlign.center,
          ),
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (!AdService.instance.isRewardedReady) {
        if (DateTime.now().isAfter(deadline)) break;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
      }
      if (!AdService.instance.isRewardedReady) {
        if (mounted) setState(() => _isWatchingAd = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Ad is not available right now. Please try again.',
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }
    }

    final earned = await AdService.instance.showRewarded();
    if (!mounted) return;
    setState(() => _isWatchingAd = false);

    if (earned) {
      final malasGained = await provider.addBonusChants(AppConstants.malaCount);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            malasGained
                ? '🕉️ Bonus mala completed! +${AppConstants.malaCount} chants'
                : '🙏 +${AppConstants.malaCount} bonus chants added!',
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

  /// Spawn a circular shockwave ripple from center
  void _spawnShockwave() {
    _shockwaves.add(_Shockwave());
    // Timer already started by _spawnFloatingName()
  }

  /// Golden ring flash + "Mala Complete" text celebration on the 108th tap
  void _spawnMalaCelebration() {
    _malaCelebrations.add(_MalaCelebration());
    // Golden sparkle burst around the ring for extra joy
    for (int i = 0; i < 14; i++) {
      final angle = (2 * pi * i / 14) + _random.nextDouble() * 0.3;
      _sparkles.add(_Sparkle(
        x: cos(angle) * 120 + (_random.nextDouble() * 10 - 5),
        yOffset: sin(angle) * 120 + (_random.nextDouble() * 10 - 5),
        size: 4.0 + _random.nextDouble() * 3.0,
        driftX: cos(angle) * 1.6,
        driftY: sin(angle) * 1.6,
      ));
    }
    _startNameAnimation();
  }

  /// Spawn a floating score popup (+1, combo, or Mala!)
  void _spawnScorePopup(int count) {
    String label;
    bool isSpecial = false;
    if (count % 108 == 0) {
      label = 'Mala! 🕉️';
      isSpecial = true;
    } else if (_tapCombo > 2) {
      label = '🔥 ${_tapCombo}x';
      isSpecial = true;
    } else {
      label = '+1';
    }
    _scorePopups.add(_ScorePopup(
      x: _random.nextDouble() * 80 - 40,
      label: label,
      isMala: isSpecial,
    ));
    // Timer already started by _spawnFloatingName()
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MantraProvider>();
    final locCode = context.watch<LocaleProvider>().localeCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCount = provider.currentCount;
    final sessionCount = provider.sessionCount;
    final progress = provider.progress;
    final isCounting = provider.isCounting;
    final totalMalasInSession = provider.totalMalasInSession;
    final autoMode = provider.autoMode;

    return Scaffold(
      body: Stack(
        children: [
          // Floating divine names — drawn BEHIND the main content so the
          // chant count and session timer are always readable above them.
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Floating divine names inside circular bubbles that rise straight, drift, and wobble
                  ..._floatingNames.map((name) => Transform.translate(
                    offset: Offset(
                      name.x + sin(name.wobblePhase) * name.wobbleAmplitude,
                      name.yOffset +
                          cos(name.wobblePhase * 0.7) * name.bounceAmplitude,
                    ),
                    child: Opacity(
                      opacity: name.opacity,
                      child: Transform.scale(
                        scale: name.scale,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4444).withOpacity(0.25),
                            border: Border.all(
                              color: const Color(0xFFFF4444).withOpacity(0.6),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4444).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.2),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: const Alignment(0, 0.12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                name.name,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // Longer names shrink so the FULL mantra always fits
                                  fontSize: name.name.length <= 6
                                      ? 22
                                      : name.name.length <= 12
                                          ? 18
                                          : 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  color: Colors.white.withOpacity(name.opacity),
                                  shadows: [
                                    // Dark outline so the name is clearly readable on the red bubble
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                    Shadow(
                                      color: const Color(0xFFDC2626).withOpacity(0.7),
                                      blurRadius: 12,
                                    ),
                                    Shadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    // Subtle gradient wash behind the header
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(isDark ? 0.16 : 0.10),
                        AppColors.primary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Om symbol badge with a soft gradient + glow
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.sunsetGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'ॐ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Translations.get('mantra_chanting', locale: locCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              provider.selectedMantra.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textLight
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const LanguageSwitcherButton(),
                      const SizedBox(width: 8),
                      // Reset
                      if (isCounting)
                        GestureDetector(
                          onTap: () {
                            _resetNameCounts();
                            provider.resetSession();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: AppColors.error, size: 20),
                          ),
                        ),
                      if (isCounting) const SizedBox(width: 8),
                      // Mantra selector
                      GestureDetector(
                        onTap: () => _showMantraSelector(provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 90),
                                child: Text(
                                  provider.selectedMantra.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Session stats
                if (isCounting)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildSessionStat(
                          icon: Icons.timer_outlined,
                          value: Helpers.formatDuration(
                            Duration(seconds: provider.sessionSeconds),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildSessionStat(
                          icon: Icons.auto_awesome_rounded,
                          value: '$sessionCount chants',
                        ),
                      ],
                    ),
                  ),

                // Favorite mantras quick-select bar
                if (provider.favoriteMantras.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Favorites',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.favoriteMantras.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final favIndex = _getFavoriteIndex(
                                  provider, i);
                              final isActive =
                                  favIndex == provider.selectedMantraIndex;
                              return GestureDetector(
                                onTap: () {
                                  provider.selectMantra(favIndex);
                                  if (!isCounting) {
                                    _resetNameCounts();
                                    provider.startCounting();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.primary.withOpacity(0.15)
                                        : AppColors.secondary,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: isActive
                                        ? Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.4))
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        color: isActive
                                            ? AppColors.primary
                                            : AppColors.textLight,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        provider
                                            .favoriteMantras[i].name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isActive
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Mala visualization + tap button (no floating names here anymore)
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Circular mala beads
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: CustomPaint(
                        painter: MalaPainter(
                          progress: progress,
                          completeMalas: totalMalasInSession,
                        ),
                      ),
                    ),

                    // Tap button
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnim.value,
                          child: GestureDetector(
                            onTap: () => _onTap(provider),
                            onLongPressStart: (_) {
                              if (!autoMode) provider.startAutoMode();
                            },
                            onLongPressEnd: (_) {
                              if (autoMode) provider.stopAutoMode();
                            },
                            onLongPressCancel: () {
                              if (autoMode) provider.stopAutoMode();
                            },
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // No fill colour inside — clean transparent ring
                                color: Colors.transparent,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.7),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              // Faint inner glow — soft rim of light fading toward the centre
                              foregroundDecoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.0),
                                    AppColors.primary.withOpacity(0.0),
                                    AppColors.primary.withOpacity(0.14),
                                    AppColors.primary.withOpacity(0.05),
                                  ],
                                  stops: const [0.0, 0.7, 0.92, 1.0],
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Decorative dashed inner ring
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _DashedCirclePainter(
                                        color: AppColors.primary.withOpacity(0.4),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Count with glow effect matching the floating-name bubbles
                                      Text(
                                        '$currentCount',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.primary.withOpacity(0.6),
                                              blurRadius: 12,
                                            ),
                                            Shadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 26,
                                            ),
                                            Shadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isCounting ? 'Tap to chant' : 'Tap to start',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.primary.withOpacity(0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (autoMode)
                                        Text(
                                          'Auto mode ●',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(
                                                color: AppColors.primary.withOpacity(0.6),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Name count display
                if (isCounting && _nameCounts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: _nameCounts.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                const Spacer(),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Mala progress
                      Row(
                        children: [
                          _buildMalaStat(
                            icon: Icons.timer_outlined,
                            label: 'This Session',
                            value: '$currentCount',
                            sub: '${(progress * 100).toInt()}% of mala',
                          ),
                          const SizedBox(width: 10),
                          _buildMalaStat(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Total Malas',
                            value: '$totalMalasInSession',
                            sub: 'completed',
                          ),
                          const SizedBox(width: 10),
                          _buildMalaStat(
                            icon: Icons.wb_sunny_outlined,
                            label: 'Daily',
                            value: Helpers.formatNumber(provider.dailyCount),
                            sub: 'chants today',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Watch ad for bonus mala (rewarded)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isWatchingAd
                              ? null
                              : () => _watchAdForBonus(provider),
                          icon: _isWatchingAd
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.card_giftcard_rounded, size: 18),
                          label: Text(
                            _isWatchingAd
                                ? 'Preparing ad…'
                                : '🎁 Watch Ad • +1 Mala Bonus',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // End session button
                      if (isCounting)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => provider.endSession(),
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('End Session & Save'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => provider.startCounting(),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start Chanting'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sparkles + celebrations OVERLAY (front, above the main content)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Shockwave ripples (expand from center)
                  ..._shockwaves.map((sw) => IgnorePointer(
                    child: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Opacity(
                        opacity: sw.opacity,
                        child: Container(
                          width: sw.radius * 2,
                          height: sw.radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF4444).withOpacity(sw.opacity * 0.5),
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4444).withOpacity(sw.opacity * 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),

                  // Score popups (+1 floats up)
                  ..._scorePopups.map((sp) => IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(sp.x, sp.yOffset),
                      child: Opacity(
                        opacity: sp.opacity,
                        child: Transform.scale(
                          scale: sp.scale,
                          child: Text(
                            sp.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: sp.isMala ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: sp.isMala
                                  ? const Color(0xFFF59E0B).withOpacity(sp.opacity)
                                  : const Color(0xFFDC2626).withOpacity(sp.opacity),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFF4444).withOpacity(sp.opacity * 0.5),
                                  blurRadius: 12,
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),

                  // Sparkle particle trail
                  ..._sparkles.map((s) => Transform.translate(
                    offset: Offset(s.x, s.yOffset),
                    child: Opacity(
                      opacity: s.opacity * 0.8,
                      child: Container(
                        width: s.size,
                        height: s.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight.withOpacity(s.opacity * 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(s.opacity * 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),

                  // Mala complete celebration — golden ring flash + text
                  ..._malaCelebrations.map((mc) => IgnorePointer(
                    child: Opacity(
                      opacity: mc.opacity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Expanding golden ring
                          Container(
                            width: mc.ringRadius * 2,
                            height: mc.ringRadius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withOpacity(mc.opacity * 0.85),
                                width: 4.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(mc.opacity * 0.5),
                                  blurRadius: 28,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          // Inner soft glow fill
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF59E0B)
                                  .withOpacity(mc.opacity * 0.10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(mc.opacity * 0.35),
                                  blurRadius: 60,
                                  spreadRadius: 30,
                                ),
                              ],
                            ),
                          ),
                          // Celebration text
                          Transform.scale(
                            scale: mc.scale,
                            child: Text(
                              '🕉️ Mala Complete! 🙏',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF59E0B)
                                    .withOpacity(mc.opacity),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFF59E0B)
                                        .withOpacity(mc.opacity * 0.8),
                                    blurRadius: 18,
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStat({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMalaStat({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 6),
            // FittedBox keeps large numbers on one line so all three cards stay equal height
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMantraSelector(MantraProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // Local snapshot so UI re-renders when favorites change
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Mantra',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Favorites count
                      if (provider.favoriteMantras.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.favoriteMantras.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Scrollable list so the sheet never overflows, even with
                  // many mantras
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: provider.mantras.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (ctx, index) {
                          final mantra = provider.mantras[index];
                          final isSelected =
                              index == provider.selectedMantraIndex;
                          final isFav = provider.isFavorite(index);
                          return ListTile(
                            onTap: () {
                              provider.selectMantra(index);
                              Navigator.pop(ctx);
                            },
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : (isDark ? AppColors.darkCard : AppColors.secondary),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textLight,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              mantra.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                              ),
                            ),
                            subtitle: mantra.translation != null
                                ? Text(
                                    mantra.translation!,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textLight : AppColors.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Star toggle
                                GestureDetector(
                                  onTap: () async {
                                    await provider.toggleFavorite(index);
                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isFav
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Icon(
                                      isFav
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: isFav
                                          ? AppColors.primary
                                          : AppColors.textLight,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary, size: 24),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A circular shockwave ripple that expands from the center on each tap
class _Shockwave {
  double radius;
  double lifetime = 0;
  double opacity = 1.0;

  _Shockwave({this.radius = 10});
}

/// A floating score popup (+1 or Mala!) that rises from the tap button
class _ScorePopup {
  final String label;
  final bool isMala;
  final double x;
  double yOffset;
  double vy;
  double lifetime = 0;
  double opacity = 1.0;
  double scale = 1.0;

  _ScorePopup({
    required this.label,
    this.isMala = false,
    this.x = 0,
    this.yOffset = -80,
    this.vy = -2.5,
  });
}

/// Golden ring + text celebration shown when a mala (108 chants) completes
class _MalaCelebration {
  double lifetime = 0;
  double opacity = 1.0;
  double ringRadius = 130;
  double scale = 1.0;
}

/// A tiny sparkle particle that trails behind floating names
class _Sparkle {
  double x;
  double yOffset;
  double size = 3.0;
  final double driftX;
  final double driftY;
  double lifetime = 0;
  double opacity = 1.0;

  _Sparkle({
    required this.x,
    required this.yOffset,
    this.size = 3.0,
    this.driftX = 0,
    this.driftY = 0,
  });
}

/// A floating divine name with varied movement, speed, spin, wobble, and deity colour
class _FloatingName {
  final String name;
  final Color color;
  double x;
  final double vx;
  double vy; // mutable so the rise cap can stop a name mid-flight
  double yOffset;
  double rotation = 0;
  final double rotationSpeed;
  final double fontSize;
  double lifetime = 0;
  double opacity = 1.0;

  // Wobble / bounce physics
  double wobblePhase;
  final double wobbleAmplitude;
  final double wobbleSpeed;
  final double bounceAmplitude;
  double scale = 1.0;
  double entranceAge = 0; // 0→1 over first ~15 frames for entrance animation

  _FloatingName({
    required this.name,
    required this.color,
    required this.x,
    this.vx = 0,
    this.vy = -2.5,
    this.yOffset = 0,
    this.rotationSpeed = 0,
    this.fontSize = 24,
    required this.wobblePhase,
    required this.wobbleAmplitude,
    required this.wobbleSpeed,
    required this.bounceAmplitude,
  });
}

/// Paints a dashed circular ring — decorative inner ring on the tap button
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const dashLength = 10.0;
    const gapLength = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    // Inset well inside the solid border so the dashes read as a distinct inner ring
    final radius = size.width / 2 - strokeWidth / 2 - 12;
    final circumference = 2 * pi * radius;
    final segment = dashLength + gapLength;
    final count = (circumference / segment).floor();

    for (int i = 0; i < count; i++) {
      final start = i * segment / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashLength / radius,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class MalaPainter extends CustomPainter {
  final double progress;
  final int completeMalas;

  MalaPainter({required this.progress, required this.completeMalas});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const totalBeads = 108;
    final filledBeads = (progress * totalBeads).round();

    // Draw outer ring
    final ringPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Draw progress ring
    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Draw beads
    for (int i = 0; i < totalBeads; i++) {
      final angle = (2 * pi * i / totalBeads) - pi / 2;
      final beadX = center.dx + radius * cos(angle);
      final beadY = center.dy + radius * sin(angle);

      final isFilled = i < filledBeads;
      final beadPaint = Paint()
        ..color = isFilled ? AppColors.primary : AppColors.textLight.withOpacity(0.2);

      // Larger bead for 108th (mala marker)
      if (i == 0 || i == totalBeads - 1) {
        canvas.drawCircle(Offset(beadX, beadY), 5, beadPaint);
      } else {
        canvas.drawCircle(Offset(beadX, beadY), 3, beadPaint);
      }
    }

    // Draw complete malas count
    if (completeMalas > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${completeMalas}M',
          style: TextStyle(
            color: AppColors.primary.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      // Show the completed-malas indicator on the RIGHT side of the circle
      // so it never sits below the ring where it overlaps the name pills.
      textPainter.paint(
        canvas,
        Offset(
          center.dx + radius + 12,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MalaPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.completeMalas != completeMalas;
}
