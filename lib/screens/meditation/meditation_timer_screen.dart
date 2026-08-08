import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class MeditationTimerScreen extends StatefulWidget {
  final String type;
  final int durationMinutes;

  const MeditationTimerScreen({
    super.key,
    required this.type,
    required this.durationMinutes,
  });

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  String? _selectedSound;
  // Guided meditation voice guidance
  int _cueIndex = 0;
  int _elapsedSeconds = 0;
  String? _currentCue;
  // How often (in seconds) a fresh guidance cue is spoken. Derived from the
  // session length so the full script fits any duration (clamped 20-60s).
  int _cueInterval = 45;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Voice guidance scripts (English + Hindi; other locales fall back to English)
  // Structured phases: intro -> breathing rhythm -> body scan -> letting go
  // -> heart/mantra -> stillness, cycling every 45 seconds.
  static const Map<String, List<String>> _guidedScript = {
    'en': [
      'Welcome. Find a comfortable seated position. Gently close your eyes, and take a deep breath in, then slowly let it out.',
      'Breathe in slowly through your nose, counting one, two, three, four. Now breathe out gently through your mouth, counting one, two, three, four, five, six.',
      'Again. Breathe in for four. One, two, three, four. And breathe out for six. One, two, three, four, five, six. Let the exhale be longer than the inhale.',
      'Let go of any tension in your shoulders. Relax your jaw, soften your face, and unclench your hands.',
      'Scan your body from head to toe. Notice your forehead, your eyes, your neck. Soften anywhere you feel tightness.',
      'If your mind wanders, that is okay. Gently bring your attention back to the sound of your breath.',
      'Feel your body becoming calm and peaceful with each breath. With every exhale, release a little more.',
      'Let your thoughts pass by like clouds in the sky, without holding on to them. Simply watch them drift.',
      'Now focus your awareness on your heart. Feel gratitude, kindness, and peace growing within you.',
      'Silently repeat in your mind: Om Shanti, Shanti, Shanti. Let the peace spread through your whole body.',
      'Stay present in this moment. There is nowhere else to be, and nothing else to do. You are safe and at peace.',
      'Take one final deep breath in. Hold it gently. And as you breathe out, smile softly to yourself.',
    ],
    'hi': [
      'स्वागत है। आरामदायक स्थिति में बैठ जाइए। धीरे से अपनी आँखें बंद कीजिए, और गहरी साँस अंदर लीजिए, फिर धीरे से छोड़ दीजिए।',
      'अपनी नाक से धीरे-धीरे साँस अंदर लीजिए, एक, दो, तीन, चार की गिनती करते हुए। अब मुँह से धीरे से छोड़िए, एक, दो, तीन, चार, पाँच, छह की गिनती करते हुए।',
      'फिर से। चार तक साँस अंदर लीजिए। एक, दो, तीन, चार। और छह तक छोड़िए। एक, दो, तीन, चार, पाँच, छह। छोड़ने की साँस को अंदर लेने से लंबा रखिए।',
      'अपने कंधों का तनाव छोड़ दीजिए। अपना जबड़ा ढीला कीजिए, चेहरा नरम कीजिए, और हाथों की मुट्ठी खोल दीजिए।',
      'अपने शरीर को सिर से पैर तक महसूस कीजिए। माथा, आँखें, गर्दन पर ध्यान दीजिए। जहाँ भी तनाव लगे, उसे नरम कीजिए।',
      'यदि मन भटके, तो कोई बात नहीं। धीरे से अपना ध्यान वापस अपनी साँस की आवाज़ पर लाइए।',
      'हर साँस के साथ अपने शरीर को शांत और शांतिपूर्ण महसूस कीजिए। हर साँस छोड़ने के साथ, थोड़ा और ढीला हो जाइए।',
      'अपने विचारों को आकाश में बादलों की तरह बहने दीजिए, बिना उन्हें पकड़े। बस उन्हें गुज़रते देखिए।',
      'अब अपना ध्यान अपने हृदय पर केंद्रित कीजिए। भीतर कृतज्ञता, दया और शांति बढ़ती हुई महसूस कीजिए।',
      'अपने मन में धीरे से दोहराइए: ॐ शांति, शांति, शांति। यह शांति अपने पूरे शरीर में फैलने दीजिए।',
      'इस क्षण में उपस्थित रहिए। और कहीं जाना नहीं है, और कुछ करना नहीं है। आप सुरक्षित और शांत हैं।',
      'एक आखिरी गहरी साँस अंदर लीजिए। धीरे से रोकिए। और जब साँस छोड़ें, तो अपने आप पर धीरे से मुस्कुराइए।',
    ],
  };

  static const Map<String, String> _guidedClosing = {
    'en': 'Well done. Slowly bring your awareness back to the room. When you are ready, gently open your eyes, and carry this peace with you.',
    'hi': 'बहुत बढ़िया। धीरे से अपनी चेतना को वापस कमरे में लाइए। जब तैयार हों, तो धीरे से आँखें खोलिए, और यह शांति अपने साथ ले जाइए।',
  };

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    AudioService.instance.ttsPlaying.addListener(_onTtsStateChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    // Stop any ongoing voice guidance (restores the music volume via listener)
    AudioService.instance.stopSpeaking();
    AudioService.instance.ttsPlaying.removeListener(_onTtsStateChanged);
    // Stop the sound only if this timer session started it
    if (_selectedSound != null) {
      AudioService.instance.stopAudio();
    }
    super.dispose();
  }

  bool get _isGuided => widget.type == 'guided';

  /// Locale used for the voice guidance ('hi' or 'en' fallback).
  String get _guidanceLocale {
    final code = Provider.of<LocaleProvider>(context, listen: false).localeCode;
    return code == 'hi' ? 'hi' : 'en';
  }

  /// Derive the cue cadence from the session duration so every phase of the
  /// script (intro, breathing, body scan, mantra, closing breath) is reached
  /// within the session. Clamped between 20 and 60 seconds.
  int get _computedCueInterval {
    final total = widget.durationMinutes * 60;
    final cues = _guidedScript[_guidanceLocale]!.length;
    final interval = (total / cues).round();
    return interval.clamp(20, 60);
  }

  /// Emoji icon of the currently selected sound, or null when none selected.
  String? get _selectedSoundIcon {
    if (_selectedSound == null) return null;
    for (final sound in AppConstants.ambientSounds) {
      if (sound['name'] == _selectedSound) return sound['icon'];
    }
    return null;
  }

  /// Duck the background music while the voice is speaking.
  void _onTtsStateChanged() {
    if (!mounted) return;
    AudioService.instance
        .setVolume(AudioService.instance.ttsPlaying.value ? 0.25 : 1.0);
  }

  /// Speak a guidance cue (index cycles through the script).
  Future<void> _speakCue(int index) async {
    if (!mounted) return;
    final isHindi = _guidanceLocale == 'hi';
    final cues = _guidedScript[_guidanceLocale]!;
    final text = cues[index % cues.length];
    setState(() => _currentCue = text);
    try {
      await AudioService.instance.stopSpeaking();
      await AudioService.instance.speak(
        text,
        language: isHindi ? 'hi-IN' : 'en-US',
        speechRate: 0.45,
      );
    } catch (e) {
      debugPrint('Error speaking guidance cue: $e');
    }
  }

  /// Speak the closing message when the session completes.
  void _speakClosing() {
    final isHindi = _guidanceLocale == 'hi';
    final text = _guidedClosing[_guidanceLocale]!;
    setState(() => _currentCue = text);
    AudioService.instance.speak(
      text,
      language: isHindi ? 'hi-IN' : 'en-US',
      speechRate: 0.45,
    );
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      // If the previous session already completed, start a fresh session
      if (_isCompleted) {
        _remainingSeconds = widget.durationMinutes * 60;
        _isCompleted = false;
        _elapsedSeconds = 0;
        _cueIndex = 0;
        _currentCue = null;
      }
      _cueInterval = _computedCueInterval;
    });
    // Resume the ambient sound together with the timer
    if (_selectedSound != null) {
      AudioService.instance.resumeAudio();
    }
    if (_isGuided) {
      if (_elapsedSeconds == 0) {
        // Fresh start (or restart after completion): speak the intro cue
        _cueIndex = 0;
        _speakCue(0);
      } else {
        // Resume: re-speak the cue that was interrupted by the pause
        _speakCue(_cueIndex);
      }
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _isCompleted = true;
        });
        // End the session: stop the ambient, stop the voice and ring a chime
        if (_selectedSound != null) {
          AudioService.instance.stopAudio();
        }
        AudioService.instance.stopSpeaking();
        AudioService.instance.playSfx('assets/sounds/chime.mp3', isAsset: true);
        if (_isGuided) {
          _speakClosing();
        }
        return;
      }
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
      });
      // Speak a fresh guidance cue on the adaptive cadence
      if (_isGuided &&
          _elapsedSeconds > 1 &&
          _elapsedSeconds % _cueInterval == 0) {
        _cueIndex++;
        _speakCue(_cueIndex);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    // Pause the ambient sound together with the timer
    if (_selectedSound != null && AudioService.instance.isPlaying) {
      AudioService.instance.pauseAudio();
    }
    if (_isGuided) {
      AudioService.instance.stopSpeaking();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    // User explicitly stopped the session, so stop the sound and the voice
    AudioService.instance.stopAudio();
    AudioService.instance.stopSpeaking();
    setState(() {
      _remainingSeconds = widget.durationMinutes * 60;
      _isRunning = false;
      _isCompleted = false;
      _elapsedSeconds = 0;
      _cueIndex = 0;
      _currentCue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locCode = context.watch<LocaleProvider>().localeCode;
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF111827),
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.type == 'guided'
                            ? Translations.get('guided_badge', locale: locCode)
                            : widget.type == 'breath'
                                ? Translations.get('breath_badge', locale: locCode)
                                : Translations.get('focus_badge', locale: locCode),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const LanguageSwitcherButton(
                      size: 36,
                      borderRadius: 12,
                      fontSize: 10,
                    ),
                    const SizedBox(width: 8),
                    // Sound selector (shows the currently selected sound)
                    GestureDetector(
                      onTap: () => _showSoundPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedSoundIcon ?? '🔇',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                _selectedSound ??
                                    Translations.get('none_option',
                                        locale: locCode),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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

              const Spacer(),

              // Timer
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRunning ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.durationMinutes} min',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Show the current voice guidance cue while meditating
              if (_isGuided && _currentCue != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    _currentCue!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],

              if (_isCompleted) ...[
                const SizedBox(height: 32),
                const Text(
                  '🙏',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  Translations.get('meditation_complete', locale: locCode),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  Translations.get('peace_with_you', locale: locCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],

              const Spacer(),

              // Controls
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Play/Pause
                    GestureDetector(
                      onTap: _isRunning ? _pauseTimer : _startTimer,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Stop
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.stop_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundTile(
    BuildContext ctx, {
    required String name,
    required String icon,
    required String? file,
  }) {
    final isSelected = _selectedSound == name;
    final locCode =
        Provider.of<LocaleProvider>(context, listen: false).localeCode;
    return ListTile(
      onTap: () {
        setState(() => _selectedSound = file == null ? null : name);
        Navigator.pop(ctx);
        if (file == null) {
          AudioService.instance.stopAudio();
        } else {
          AudioService.instance.playAmbientSound(file, isAsset: true).then((ok) {
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Translations.t('could_not_play_sound',
                      locale: locCode, params: {'sound': name})),
                ),
              );
            }
          });
        }
      },
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showSoundPicker(BuildContext context) {
    final locCode =
        Provider.of<LocaleProvider>(context, listen: false).localeCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get('ambient_sounds', locale: locCode),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildSoundTile(ctx,
                  name: Translations.get('none_option', locale: locCode),
                  icon: '🔇',
                  file: null),
              ...AppConstants.ambientSounds.map((sound) => _buildSoundTile(
                    ctx,
                    name: sound['name']!,
                    icon: sound['icon']!,
                    file: sound['file']!,
                  )),
            ],
          ),
        );
      },
    );
  }
}
