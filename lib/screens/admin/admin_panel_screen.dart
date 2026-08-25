import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/language_switcher_button.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontSize: 16)),
        actions: const [
          LanguageSwitcherButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Manage Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              icon: Icons.menu_book_rounded,
              title: 'Manage Stories',
              subtitle: 'Add, edit, or remove sacred stories',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              icon: Icons.format_quote_rounded,
              title: 'Daily Quotes',
              subtitle: 'Update daily spiritual quotes',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              icon: Icons.emoji_events_rounded,
              title: 'Challenges',
              subtitle: 'Create and manage daily challenges',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            const Text(
              'User Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              icon: Icons.people_rounded,
              title: 'Users',
              subtitle: 'View and manage app users',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              icon: Icons.flag_rounded,
              title: 'Reports',
              subtitle: 'View user reports and feedback',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            const Text(
              'Communication',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              icon: Icons.campaign_rounded,
              title: 'Announcements',
              subtitle: 'Send app-wide announcements',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildAdminCard(
              icon: Icons.notifications_active_rounded,
              title: 'Push Notifications',
              subtitle: 'Send notifications to users',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Stats
            const Text(
              'App Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('1,234', 'Users'),
                const SizedBox(width: 12),
                _buildStatCard('45,678', 'Chants'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('890', 'Stories'),
                const SizedBox(width: 12),
                _buildStatCard('12', 'Admins'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
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

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textLight.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
