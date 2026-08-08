import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/language_switcher_button.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const LanguageSwitcherButton(),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Track your spiritual journey',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                children: [
                  _buildSummaryCard('Today', '108', 'chants', AppColors.primary),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Week', '756', 'chants', const Color(0xFF7C3AED)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryCard('Month', '3,240', 'chants', const Color(0xFF059669)),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Total', '12,580', 'chants', AppColors.primaryLight),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly chart
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Mon', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('Tue', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('Wed', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('Thu', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('Fri', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('Sat', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('Sun', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              const Text(
                'Detailed Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Total Mantras Chanted', '12,580'),
              _buildDetailRow('Total Malas Completed', '116'),
              _buildDetailRow('Meditation Minutes', '1,240'),
              _buildDetailRow('Stories Read', '24'),
              _buildDetailRow('Gita Verses Read', '186'),
              _buildDetailRow('Current Streak', '7 days'),
              _buildDetailRow('Longest Streak', '30 days'),
              _buildDetailRow('Challenges Completed', '18'),
              _buildDetailRow('Achievements Unlocked', '5'),
              _buildDetailRow('XP Earned', '1,250'),
              _buildDetailRow('Coins Earned', '500'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
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
