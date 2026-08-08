import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mantra_provider.dart';
import '../../providers/tap_sound_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final mantraProvider = context.watch<MantraProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = userProvider.user;
    final locCode = localeProvider.localeCode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Translations.get('profile', locale: locCode),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const LanguageSwitcherButton(),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditProfile(context, userProvider, locCode),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSettings(context, themeProvider, locCode),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.sunsetGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white54,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name ?? 'G').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Guest',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'guest@divinepath.app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Level
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${Helpers.getLevel(user?.xp ?? 0)['icon']} ${Helpers.getLevel(user?.xp ?? 0)['name']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats grid
              Row(
                children: [
                  _buildStatCard(
                    '🔥',
                    Translations.get('streak', locale: locCode),
                    '${user?.streak ?? 0} ${Translations.get('days', locale: locCode)}',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    '📿',
                    Translations.get('total_chants_short', locale: locCode),
                    Helpers.formatNumber(mantraProvider.totalCount),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    '🕉️',
                    Translations.get('total_malas_short', locale: locCode),
                    '${mantraProvider.totalMalas}',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    '🧘',
                    Translations.get('meditation', locale: locCode),
                    '${user?.totalMeditationMinutes ?? 0} ${Translations.get('minutes', locale: locCode)}',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu items
              _buildMenuItem(
                Icons.auto_awesome_rounded,
                Translations.get('my_mantras', locale: locCode),
                Translations.get('view_favorite_mantras', locale: locCode),
                () {},
              ),
              _buildMenuItem(
                Icons.bookmark_rounded,
                Translations.get('bookmarks', locale: locCode),
                Translations.get('saved_stories_verses', locale: locCode),
                () => context.push('/saved-verses'),
              ),
              _buildMenuItem(
                Icons.emoji_events_rounded,
                Translations.get('achievements', locale: locCode),
                Translations.t('achievements_unlocked', locale: locCode, params: {'count': '${user?.achievements.length ?? 0}'}),
                () => context.push('/challenges'),
              ),
              _buildMenuItem(
                Icons.analytics_rounded,
                Translations.get('analytics', locale: locCode),
                Translations.get('spiritual_progress', locale: locCode),
                () => context.push('/analytics'),
              ),
              _buildMenuItem(
                Icons.dark_mode_rounded,
                Translations.get('dark_mode', locale: locCode),
                themeProvider.isDarkMode
                    ? Translations.get('enabled', locale: locCode)
                    : Translations.get('disabled', locale: locCode),
                () => themeProvider.toggleDarkMode(),
              ),
              _buildMenuItem(
                Icons.notifications_rounded,
                Translations.get('notifications', locale: locCode),
                Translations.get('manage_reminders', locale: locCode),
                () {},
              ),
              _buildMenuItem(
                Icons.language_rounded,
                Translations.get('language', locale: locCode),
                localeProvider.isSanskrit
                    ? Translations.get('sanskrit', locale: locCode)
                    : localeProvider.isHindi
                        ? Translations.get('hindi', locale: locCode)
                        : Translations.get('english', locale: locCode),
                () => _showLanguagePicker(context, localeProvider),
              ),
              _buildMenuItem(
                Icons.star_rounded,
                Translations.get('premium', locale: locCode),
                user?.isPremium ?? false
                    ? Translations.get('active', locale: locCode)
                    : Translations.get('upgrade', locale: locCode),
                () => context.push('/premium'),
              ),

              const SizedBox(height: 24),

              // Admin link
              if (user?.isAdmin ?? false)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: Text(Translations.get('admin_panel', locale: locCode)),
                  ),
                ),
              const SizedBox(height: 12),

              // App info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      Translations.get('appName', locale: locCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Translations.get('appTagline', locale: locCode),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Translations.get('appName', locale: locCode)} v1.0.0',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textLight.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textLight, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, UserProvider userProvider, String locCode) {
    final nameController = TextEditingController(text: userProvider.user?.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get('edit_profile', locale: locCode),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: Translations.get('name', locale: locCode),
                  hintText: Translations.get('enter_name', locale: locCode),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await userProvider.updateProfile(name: nameController.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(Translations.get('save', locale: locCode)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
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
                Translations.get('select_language', locale: localeProvider.localeCode),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...Translations.supportedLocales.map((lang) {
                final isSelected = localeProvider.localeCode == lang['code'];
                return ListTile(
                  onTap: () async {
                    await localeProvider.setLocale(lang['code']!);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        lang['code'] == 'en'
                            ? 'EN'
                            : lang['code'] == 'sa'
                                ? 'सं'
                                : 'हि',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    lang['native']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    lang['name']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 24)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context, ThemeProvider themeProvider, String locCode) {
    // Use a StatefulBuilder so the picker's selection updates live
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final tapProvider = context.read<TapSoundProvider>();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.get('settings', locale: locCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: Text(Translations.get('dark_mode', locale: locCode)),
                    subtitle: Text(Translations.get('toggle_dark_theme', locale: locCode)),
                    value: themeProvider.isDarkMode,
                    onChanged: (_) {
                      themeProvider.toggleDarkMode();
                      Navigator.pop(ctx);
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(Translations.get('notifications', locale: locCode)),
                    subtitle: Text(Translations.get('daily_reminders', locale: locCode)),
                    value: true,
                    onChanged: (value) {},
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(Translations.get('haptic_feedback', locale: locCode)),
                    subtitle: Text(Translations.get('vibration_on_chant', locale: locCode)),
                    value: true,
                    onChanged: (value) {},
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tap Sound Picker
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      Translations.get('tap_sound', locale: locCode),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: TapSoundProvider.options.map((opt) {
                        final isSelected = tapProvider.selectedSoundId == opt.id;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await tapProvider.setTapSound(opt.id);
                              setSheetState(() {});
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                      ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    opt.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${Translations.get('appName', locale: locCode)} v1.0.0',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
