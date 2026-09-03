import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mantra_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/admob_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mantraProvider = context.read<MantraProvider>();
      mantraProvider.updateDailyStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final mantraProvider = context.watch<MantraProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = userProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final localeProvider = context.watch<LocaleProvider>();
    final locCode = localeProvider.localeCode;
    final greeting = Helpers.getGreeting(locale: locCode);
    final userName = user?.name ?? Translations.get('seeker', locale: locCode);
    final streak = user?.streak ?? 0;
    final dailyCount = mantraProvider.dailyCount;
    final totalCount = mantraProvider.totalCount;
    final totalMalas = mantraProvider.totalMalas;
    final dailyGoal = user?.dailyGoal ?? 108;

    // Get today's verse (localized to current language)
    final today = DateTime.now().day;
    final dailyQuote = Translations.getDailyQuote(today, locale: locCode);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textLight : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Language switcher
                      GestureDetector(
                        onTap: () => _showLanguagePicker(context, localeProvider),
                        child:                       Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            localeProvider.badge,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              height: 3.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Theme toggle
                      GestureDetector(
                        onTap: () => themeProvider.toggleDarkMode(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Streak & Stats Row
              Row(
                children: [
                  // Streak
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            Helpers.getStreakEmoji(streak),
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$streak',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                      Translations.get('day_streak', locale: locCode),
                      style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textLight : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Today's chants
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                Helpers.formatNumber(dailyCount),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Translations.get('todays_chants', locale: locCode),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textLight : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Aarti section card
              GestureDetector(
                onTap: () => context.push('/aarti'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('🪔', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Translations.get('aartis', locale: locCode),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Translations.get('aarti_home_subtitle', locale: locCode),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Daily Quote Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                gradient: AppColors.sunsetGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote_rounded,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                      Translations.get('daily_wisdom', locale: locCode),
                      style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${dailyQuote.split(' - ').first}"',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                    if (dailyQuote.contains(' - ')) ...[
                      const SizedBox(height: 8),
                      Text(
                        '- ${dailyQuote.split(' - ').last}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daily Goal Progress
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                      Translations.get('daily_goal', locale: locCode),
                      style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$dailyCount / $dailyGoal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: dailyGoal > 0 ? dailyCount / dailyGoal : 0,
                          minHeight: 8,
                          backgroundColor: isDark ? AppColors.darkCard : AppColors.secondary,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dailyCount >= dailyGoal)
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 18),
                            const SizedBox(width: 8),
                            Text(
                      Translations.get('daily_goal_completed', locale: locCode),
                      style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Text(
                Translations.get('your_journey', locale: locCode),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Icons.auto_awesome_rounded,
                      label: Translations.get('total_chants', locale: locCode),
                      value: Helpers.formatNumber(totalCount),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.linear_scale_rounded,
                      label: Translations.get('total_malas', locale: locCode),
                      value: '$totalMalas',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Icons.local_fire_department_rounded,
                      label: Translations.get('longest_streak', locale: locCode),
                      value: '${user?.longestStreak ?? 0}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.star_rounded,
                      label: Translations.get('level', locale: locCode),
                      value: '${Helpers.getLevel(user?.xp ?? 0)['name']}',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                Translations.get('quick_actions', locale: locCode),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.auto_awesome_rounded,
                    label: Translations.get('chant', locale: locCode),
                    color: AppColors.primary,
                    onTap: () => context.go('/mantra'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.self_improvement_rounded,
                    label: Translations.get('meditate', locale: locCode),
                    color: AppColors.info,
                    onTap: () => context.push('/meditation'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.menu_book_rounded,
                    label: Translations.get('read', locale: locCode),
                    color: AppColors.success,
                    onTap: () => context.go('/stories'),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.chat_bubble_rounded,
                    label: Translations.get('ask_ai', locale: locCode),
                    color: const Color(0xFF7C3AED),
                    onTap: () => context.go('/chat'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Banner ad below Quick Actions
              if (AdmobService.instance.isSupported)
                Center(
                  child: AdmobService.instance.getBannerWidget(
                    width: double.infinity,
                    height: 50,
                  ),
                ),

              const SizedBox(height: 24),

              // Recent Activity
              if (mantraProvider.recentSessions.isNotEmpty) ...[
                Text(
                  Translations.get('recent_activity', locale: locCode),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...mantraProvider.recentSessions.take(3).map((session) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Translations.t('chanted_times', locale: locCode, params: {'count': '${session.count}'}),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              session.mantraName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textLight : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Helpers.timeAgo(session.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLight : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              const SizedBox(height: 24),

              // Home banner ad
              AdmobService.instance.getBannerWidget(
                width: double.infinity,
                height: 50,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
    final locCode = localeProvider.localeCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                Translations.get('select_language', locale: locCode),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...Translations.supportedLocales.map((lang) {
                final code = lang['code']!;
                final native = lang['native']!;
                final badge = lang['badge']!;
                final isSelected = localeProvider.localeCode == code;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      localeProvider.setLocale(code);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : (isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
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
                                  ? AppColors.primary
                                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              native,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? Colors.white : AppColors.textPrimary),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
