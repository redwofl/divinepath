import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  static AudioService get instance => _instance;
  AudioService._internal();

  // Background music / ambient player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Sound effects player (separate so SFX don't interrupt ambient)
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();

  // Volume
  double _volume = 1.0;

  // Current state
  bool _isPlaying = false;
  String? _currentTrack;
  bool _isTtsPlaying = false;

  // Getters
  bool get isPlaying => _isPlaying;
  String? get currentTrack => _currentTrack;
  bool get isTtsPlaying => _isTtsPlaying;
  double get volume => _volume;

  /// Notifies when TTS starts/stops speaking so callers can duck background
  /// music while a voice is talking.
  final ValueNotifier<bool> ttsPlaying = ValueNotifier<bool>(false);

  // Streams
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Initialize audio service
  Future<void> initialize() async {
    await _clearAssetCache();

    // Initialize TTS
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set TTS completion handler
    _flutterTts.setCompletionHandler(() {
      _isTtsPlaying = false;
      ttsPlaying.value = false;
    });
  }

  /// just_audio caches asset files by path and never notices when the
  /// underlying asset changes between app updates (e.g. replaced sounds).
  /// Wipe that cache on every startup so the app always plays the audio
  /// bundled in the current build. Safe: it is only a copy-on-first-play
  /// cache and is recreated automatically.
  Future<void> _clearAssetCache() async {
    if (kIsWeb) return; // no file-system asset cache on web
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/just_audio_cache');
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing just_audio asset cache: $e');
    }
  }

  /// Set volume (applies to BOTH background music and sound effects)
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _audioPlayer.setVolume(volume);
    try {
      await _sfxPlayer.setVolume(volume);
    } catch (_) {}
  }

  /// Set the audio source on a player.
  ///
  /// On web, `setAsset` loads the whole file into a base64 data URL which is
  /// slow and fragile for larger files. Instead we stream the asset's real
  /// HTTP URL, which the browser serves directly.
  Future<void> _setSource(
      AudioPlayer player, String source, {required bool isAsset}) async {
    if (isAsset && kIsWeb) {
      // Normalize so callers can pass either 'sounds/x.mp3' or 'assets/sounds/x.mp3'
      final normalized =
          source.startsWith('assets/') ? source : 'assets/$source';
      await player.setUrl(Uri.base.resolve(normalized).toString());
    } else if (isAsset) {
      await player.setAsset(source);
    } else {
      await player.setUrl(source);
    }
  }

  /// Play sound effect (uses dedicated SFX player, won't interrupt ambient)
  /// [speed] adjusts playback speed/pitch (e.g. >1 raises the pitch).
  Future<bool> playSfx(String source,
      {bool isAsset = false, double speed = 1.0}) async {
    try {
      await _sfxPlayer.setSpeed(speed);
      await _setSource(_sfxPlayer, source, isAsset: isAsset);
      await _sfxPlayer.seek(Duration.zero);
      _startPlayback(_sfxPlayer, onError: (e) {
        debugPrint('Error starting SFX: $e');
      });
      return true;
    } catch (e) {
      debugPrint('Error playing SFX: $e');
      return false;
    }
  }

  /// Play background audio from URL or asset (uses main player)
  /// Returns true if playback started successfully.
  Future<bool> playAudio(String source, {bool isAsset = false}) async {
    try {
      _currentTrack = source;
      await _setSource(_audioPlayer, source, isAsset: isAsset);
      // One-shot playback: make sure a previous ambient's LoopMode.one
      // doesn't leak into this track.
      await _audioPlayer.setLoopMode(LoopMode.off);
      _isPlaying = true;
      _startPlayback(_audioPlayer, onError: (e) {
        debugPrint('Error starting audio: $e');
        _isPlaying = false;
      });
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
      return false;
    }
  }

  /// Play local file
  Future<void> playLocal(String filePath) async {
    try {
      _currentTrack = filePath;
      await _audioPlayer.setFilePath(filePath);
      _isPlaying = true;
      _startPlayback(_audioPlayer, onError: (e) {
        debugPrint('Error playing local audio: $e');
        _isPlaying = false;
      });
    } catch (e) {
      debugPrint('Error playing local audio: $e');
    }
  }

  /// Start playback without blocking.
  ///
  /// just_audio's [AudioPlayer.play] future only completes when playback
  /// ends or pauses (notably on web), so awaiting it would leave the player
  /// stuck in a "not playing" state and delay anything that runs after it.
  void _startPlayback(AudioPlayer player, {required void Function(Object) onError}) {
    unawaited(player.play().catchError((Object e, StackTrace st) {
      onError(e);
    }));
  }

  /// Pause audio
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  /// Resume audio
  Future<void> resumeAudio() async {
    if (_currentTrack == null) return;
    _isPlaying = true;
    _startPlayback(_audioPlayer, onError: (e) {
      debugPrint('Error resuming audio: $e');
      _isPlaying = false;
    });
  }

  /// Stop audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    // Clear any lingering loop mode from an ambient session.
    try {
      await _audioPlayer.setLoopMode(LoopMode.off);
    } catch (e) {
      debugPrint('Error clearing loop mode: $e');
    }
    _isPlaying = false;
    _currentTrack = null;
  }

  /// Seek to position
  Future<void> seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Get audio duration
  Future<Duration?> getAudioDuration() async {
    return _audioPlayer.duration;
  }

  /// Set audio speed
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  /// Set loop mode
  Future<void> setLoopMode(bool loop) async {
    await _audioPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }

  /// Play ambient sound with looping (uses main player)
  /// Returns true if playback started successfully.
  ///
  /// Loop mode is enabled BEFORE playback begins so the sound loops from the
  /// very first playthrough (on web, setting it after play() would only apply
  /// after the track has already ended).
  Future<bool> playAmbientSound(String source, {bool isAsset = false}) async {
    try {
      _currentTrack = source;
      await _setSource(_audioPlayer, source, isAsset: isAsset);
      try {
        await _audioPlayer.setLoopMode(LoopMode.one);
      } catch (e) {
        debugPrint('Error setting loop mode: $e');
      }
      _isPlaying = true;
      _startPlayback(_audioPlayer, onError: (e) {
        debugPrint('Error starting audio: $e');
        _isPlaying = false;
      });
      return true;
    } catch (e) {
      debugPrint('Error playing ambient audio: $e');
      _isPlaying = false;
      return false;
    }
  }

  // ==================== TEXT TO SPEECH ====================

  /// Set TTS language
  Future<void> setTtsLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  /// Set TTS speech rate
  Future<void> setTtsSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Fallback so ducked volume is always restored, even on platforms (notably
  /// web) where the TTS completion handler may never fire.
  Timer? _ttsFallbackTimer;

  /// Speak text. Optionally override the TTS language and speech rate.
  Future<void> speak(String text, {String? language, double? speechRate}) async {
    try {
      if (language != null) {
        await _flutterTts.setLanguage(language);
      }
      if (speechRate != null) {
        await _flutterTts.setSpeechRate(speechRate);
      }
      _isTtsPlaying = true;
      ttsPlaying.value = true;
      _ttsFallbackTimer?.cancel();
      await _flutterTts.speak(text);
      // Safety net: if the platform never reports completion, clear the
      // speaking flag after a generous window so ambient volume is restored.
      _ttsFallbackTimer = Timer(const Duration(seconds: 60), () {
        if (_isTtsPlaying) {
          _isTtsPlaying = false;
          ttsPlaying.value = false;
        }
      });
    } catch (e) {
      debugPrint('Error speaking: $e');
      _isTtsPlaying = false;
      ttsPlaying.value = false;
    }
  }

  /// Stop TTS
  Future<void> stopSpeaking() async {
    _ttsFallbackTimer?.cancel();
    await _flutterTts.stop();
    _isTtsPlaying = false;
    ttsPlaying.value = false;
  }

  /// Pause TTS
  Future<void> pauseSpeaking() async {
    await _flutterTts.pause();
    _isTtsPlaying = false;
    ttsPlaying.value = false;
  }

  /// Resume TTS
  Future<void> resumeSpeaking() async {
    await _flutterTts.speak('');
  }

  /// Check if TTS is speaking
  Future<bool> isSpeaking() async {
    final result = await _flutterTts.isLanguageAvailable('en-US');
    return result == true;
  }

  /// Get available TTS languages
  Future<Set<String>> getAvailableLanguages() async {
    final result = await _flutterTts.getLanguages;
    if (result is Set<String>) {
      return result;
    }
    return <String>{};
  }

  /// Set TTS voice
  Future<void> setTtsVoice(String voice) async {
    // Implementation depends on platform
  }

  /// Read story aloud with TTS
  Future<void> readStoryAloud(String title, String content) async {
    final text = '$title. $content';
    await speak(text);
  }

  // ==================== CLEANUP ====================

  /// Dispose audio players
  Future<void> dispose() async {
    await stopAudio();
    await _sfxPlayer.stop();
    await stopSpeaking();
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
    await _flutterTts.stop();
  }
}
