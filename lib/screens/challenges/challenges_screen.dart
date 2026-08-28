import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/achievement_model.dart';
import '../../providers/locale_provider.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Translations.get('challenges', locale: context.watch<LocaleProvider>().localeCode),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const LanguageSwitcherButton(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Translations.get('challenges_subtitle', locale: context.watch<LocaleProvider>().localeCode),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // XP & Coins summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFFB84D)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRewardStat('⭐', 'XP', '1,250'),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildRewardStat('🪙', 'Coins', '500'),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildRewardStat('🏆', 'Level', 'Seeker'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Daily', icon: Icon(Icons.today_rounded, size: 20)),
                Tab(text: 'Achievements', icon: Icon(Icons.emoji_events_rounded, size: 20)),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyChallenges(),
                  _buildAchievements(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _startChallenge(DailyChallenge challenge) {
    switch (challenge.type) {
      case 'chant':
      case 'prayer':
        context.go('/mantra');
        break;
      case 'meditation':
        context.push('/meditation');
        break;
      case 'story':
        context.go('/stories');
        break;
      case 'verse':
        context.go('/gita');
        break;
      default:
        context.go('/home');
    }
  }

  Widget _buildDailyChallenges() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: DailyChallenge.defaultChallenges.length,
      itemBuilder: (context, index) {
        final challenge = DailyChallenge.defaultChallenges[index];
        final isCompleted = index % 3 == 0; // Sample: some completed
        final titleColor =
            isCompleted ? AppColors.success : (isDark ? AppColors.textOnDark : AppColors.textPrimary);
        final descColor =
            isDark ? AppColors.textLight : AppColors.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withOpacity(isDark ? 0.15 : 0.05)
                  : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.textLight.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : (isDark ? AppColors.darkSurface : AppColors.secondary),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(challenge.icon ?? '🎯',
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('+${challenge.xpReward} XP',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          const Icon(Icons.monetization_on_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('+${challenge.coinReward} Coins',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 28)
                else
                  GestureDetector(
                    onTap: () => _startChallenge(challenge),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievements() {
    final achievements = Achievement.defaultAchievements;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final lockedCardColor =
        isDark ? AppColors.darkSurface : Colors.white.withOpacity(0.5);
    final titleColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final lockedTitleColor =
        isDark ? AppColors.textLight : AppColors.textSecondary;
    final descriptionColor =
        isDark ? AppColors.textLight : AppColors.textSecondary;
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = index < 3; // Sample: first 3 unlocked
        final progress = index < 3 ? 1.0 : (index * 0.15);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked ? cardColor : lockedCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.textLight.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isUnlocked ? achievement.icon : '🔒',
                style: TextStyle(
                  fontSize: 32,
                  color: isUnlocked ? null : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? titleColor : lockedTitleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isUnlocked
                      ? descriptionColor
                      : (isDark ? AppColors.textLight : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.textLight.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? AppColors.success : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
