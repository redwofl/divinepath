import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  // Keeps the play/pause icons in sync with the real audio state.
  StreamSubscription<PlayerState>? _audioSub;

  @override
  void initState() {
    super.initState();
    _audioSub = AudioService.instance.playerStateStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    // Stop audio only if this screen started it (don't kill audio from
    // other screens, e.g. the bubble game's ambient sound).
    final track = AudioService.instance.currentTrack;
    if (track != null &&
        AppConstants.ambientSounds.any((s) => s['file'] == track)) {
      AudioService.instance.stopAudio();
    }
    super.dispose();
  }

  bool _isSoundPlaying(String file) {
    return AudioService.instance.isPlaying &&
        AudioService.instance.currentTrack == file;
  }

  void _toggleSound(Map<String, String> sound) {
    final file = sound['file']!;
    if (_isSoundPlaying(file)) {
      AudioService.instance.stopAudio();
      return;
    }
    AudioService.instance.playAmbientSound(file, isAsset: true).then((ok) {
      if (!ok && mounted) {
        final locCode = Provider.of<LocaleProvider>(context, listen: false)
            .localeCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.t('could_not_play_sound',
                locale: locCode, params: {'sound': sound['name']!})),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locCode = context.watch<LocaleProvider>().localeCode;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Translations.get('meditation_title', locale: locCode),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const LanguageSwitcherButton(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Translations.get('meditation_subtitle', locale: locCode),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Meditation types
              _buildMeditationType(
                context,
                icon: Icons.self_improvement_rounded,
                title: Translations.get('guided_meditation', locale: locCode),
                subtitle:
                    Translations.get('guided_meditation_sub', locale: locCode),
                color: const Color(0xFF7C3AED),
                type: 'guided',
              ),
              const SizedBox(height: 12),
              _buildMeditationType(
                context,
                icon: Icons.air_rounded,
                title: Translations.get('breath_focus', locale: locCode),
                subtitle: Translations.get('breath_focus_sub', locale: locCode),
                color: const Color(0xFF059669),
                type: 'breath',
              ),
              const SizedBox(height: 12),
              _buildMeditationType(
                context,
                icon: Icons.trip_origin_rounded,
                title: Translations.get('focus_timer', locale: locCode),
                subtitle: Translations.get('focus_timer_sub', locale: locCode),
                color: AppColors.primary,
                type: 'focus',
              ),
              const SizedBox(height: 12),
              _buildMeditationType(
                context,
                icon: Icons.music_note_rounded,
                title: Translations.get('ambient_sounds', locale: locCode),
                subtitle: Translations.get('ambient_sounds_sub', locale: locCode),
                color: const Color(0xFF2563EB),
                type: 'ambient',
              ),
              const SizedBox(height: 32),

              // Quick start
              Text(
                Translations.get('quick_duration', locale: locCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDurationChip(
                      context, '5 ${Translations.get('min_short', locale: locCode)}', 5, 'focus'),
                  const SizedBox(width: 12),
                  _buildDurationChip(
                      context, '10 ${Translations.get('min_short', locale: locCode)}', 10, 'focus'),
                  const SizedBox(width: 12),
                  _buildDurationChip(
                      context, '15 ${Translations.get('min_short', locale: locCode)}', 15, 'focus'),
                  const SizedBox(width: 12),
                  _buildDurationChip(
                      context, '30 ${Translations.get('min_short', locale: locCode)}', 30, 'focus'),
                ],
              ),
              const SizedBox(height: 32),

              // Ambient sounds
              Text(
                Translations.get('ambient_sounds', locale: locCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...AppConstants.ambientSounds.map((sound) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                // Whole row is tappable: tapping anywhere on the tile toggles
                // the sound, not just the small play button.
                child: GestureDetector(
                  onTap: () => _toggleSound(sound),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(sound['icon']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sound['name']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isSoundPlaying(sound['file']!)
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationType(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => _showDurationPicker(context, type, title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(
      BuildContext context, String label, int minutes, String type) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/meditation/timer/$type/$minutes'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Let the user enter any meditation duration (1–180 minutes).
  void _showCustomDurationPicker(
      BuildContext context, String type, String title) {
    final locCode = Provider.of<LocaleProvider>(context, listen: false)
        .localeCode;
    final controller = TextEditingController(text: '20');
    String? errorText;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('$title — '
              '${Translations.get('custom_duration', locale: locCode)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Translations.get('custom_duration_hint', locale: locCode)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: Translations.get('minutes_label', locale: locCode),
                  suffixText: Translations.get('min_short', locale: locCode),
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                onSubmitted: (_) => _confirmCustomDuration(
                  dialogCtx,
                  controller,
                  type,
                  context,
                  (String? e) => setDialogState(() => errorText = e),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(Translations.get('cancel', locale: locCode)),
            ),
            FilledButton(
              onPressed: () => _confirmCustomDuration(
                dialogCtx,
                controller,
                type,
                context,
                (String? e) => setDialogState(() => errorText = e),
              ),
              child: Text(Translations.get('start', locale: locCode)),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  /// Validates the entered minutes, shows an inline error if invalid, and
  /// only closes the dialog (navigating to the timer) when valid.
  void _confirmCustomDuration(
    BuildContext dialogCtx,
    TextEditingController controller,
    String type,
    BuildContext navCtx,
    void Function(String?) setError,
  ) {
    final minutes = int.tryParse(controller.text.trim());
    if (minutes == null || minutes < 1 || minutes > 180) {
      final locCode =
          Provider.of<LocaleProvider>(navCtx, listen: false).localeCode;
      setError(Translations.get('duration_invalid', locale: locCode));
      return;
    }
    Navigator.pop(dialogCtx);
    navCtx.push('/meditation/timer/$type/$minutes');
  }

  void _showDurationPicker(BuildContext context, String type, String title) {
    final locCode = Provider.of<LocaleProvider>(context, listen: false)
        .localeCode;
    showModalBottomSheet(
      context: context,
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
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Translations.get('choose_duration', locale: locCode),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: AppConstants.meditationDurations.map((d) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/meditation/timer/$type/$d');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$d',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                Translations.get('min_short', locale: locCode),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCustomDurationPicker(context, type, title);
                  },
                  child: Text(
                      Translations.get('custom_duration', locale: locCode)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
