import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/language_switcher_button.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Connect with fellow seekers',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const LanguageSwitcherButton(),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showCreatePost(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Inspirational', icon: Icon(Icons.lightbulb_rounded, size: 20)),
                Tab(text: 'Prayer Requests', icon: Icon(Icons.self_improvement_rounded, size: 20)),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeed(),
                  _buildPrayerRequests(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    final posts = <Map<String, dynamic>>[
      {
        'user': 'Priya S.',
        'content': 'Started my morning with 108 chants of Om Namah Shivaya. Feeling blessed and peaceful! 🙏',
        'likes': 24,
        'comments': 5,
        'time': '2h ago',
      },
      {
        'user': 'Arjun M.',
        'content': 'The Bhagavad Gita says: "Yoga-sthah kuru karmani" - Be steadfast in yoga and perform your actions. This teaching has transformed my approach to work.',
        'likes': 42,
        'comments': 8,
        'time': '4h ago',
      },
      {
        'user': 'Lakshmi R.',
        'content': 'Today\'s meditation was the most profound experience. I could feel the divine energy flowing through me. Has anyone else experienced this? 🧘‍♀️',
        'likes': 56,
        'comments': 12,
        'time': '6h ago',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final userName = post['user'] as String;
        final content = post['content'] as String;
        final time = post['time'] as String;
        final likes = '${post['likes']}';
        final comments = '${post['comments']}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        userName[0],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionButton(Icons.favorite_border_rounded, likes),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.chat_bubble_outline_rounded, comments),
                    const Spacer(),
                    _buildActionButton(Icons.share_outlined, 'Share'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerRequests() {
    final prayers = <Map<String, dynamic>>[
      {
        'user': 'Rahul K.',
        'content': 'Please pray for my mother\'s speedy recovery from illness.',
        'prayers': 45,
        'time': '1h ago',
      },
      {
        'user': 'Ananya D.',
        'content': 'I\'m going through a difficult time. Please keep me in your prayers for peace and strength.',
        'prayers': 78,
        'time': '3h ago',
      },
      {
        'user': 'Vikram S.',
        'content': 'Praying for world peace and harmony. May all beings be happy.',
        'prayers': 120,
        'time': '8h ago',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: prayers.length,
      itemBuilder: (context, index) {
        final prayer = prayers[index];
        final userName = prayer['user'] as String;
        final content = prayer['content'] as String;
        final time = prayer['time'] as String;
        final prayerCount = '${prayer['prayers']}';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFDB2777).withOpacity(0.1),
                    child: Text(
                      userName[0],
                      style: const TextStyle(
                        color: Color(0xFFDB2777),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          prayerCount,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '🪷',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.self_improvement_rounded,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Pray for this person',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
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
              const Text(
                'Create Post',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 4,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'Share your spiritual experience...',
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
