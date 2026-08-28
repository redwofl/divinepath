import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/language_switcher_button.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final subColor = isDark ? AppColors.textLight : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const LanguageSwitcherButton(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Track your spiritual journey',
                style: TextStyle(
                  fontSize: 14,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                children: [
                  _buildSummaryCard('Today', '108', 'chants', AppColors.primary, isDark),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Week', '756', 'chants', const Color(0xFF7C3AED), isDark),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryCard('Month', '3,240', 'chants', const Color(0xFF059669), isDark),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Total', '12,580', 'chants', AppColors.primaryLight, isDark),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly chart
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Bar chart - simple representation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar('Mon', 0.6, AppColors.primary),
                        _buildBar('Tue', 0.8, AppColors.primary),
                        _buildBar('Wed', 0.4, AppColors.primary),
                        _buildBar('Thu', 0.9, AppColors.primary),
                        _buildBar('Fri', 0.7, AppColors.primary),
                        _buildBar('Sat', 0.5, AppColors.primary),
                        _buildBar('Sun', 0.3, AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Mon', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                        Text('Tue', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                        Text('Wed', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                        Text('Thu', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                        Text('Fri', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                        Text('Sat', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                        Text('Sun', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLight : AppColors.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Text(
                'Detailed Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Total Mantras Chanted', '12,580', isDark),
              _buildDetailRow('Total Malas Completed', '116', isDark),
              _buildDetailRow('Meditation Minutes', '1,240', isDark),
              _buildDetailRow('Stories Read', '24', isDark),
              _buildDetailRow('Gita Verses Read', '186', isDark),
              _buildDetailRow('Current Streak', '7 days', isDark),
              _buildDetailRow('Longest Streak', '30 days', isDark),
              _buildDetailRow('Challenges Completed', '18', isDark),
              _buildDetailRow('Achievements Unlocked', '5', isDark),
              _buildDetailRow('XP Earned', '1,250', isDark),
              _buildDetailRow('Coins Earned', '500', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, String unit, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$unit $label',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textLight : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 80 * height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: 80 * height * 0.7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      color.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
