import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/stories_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common/language_switcher_button.dart';

class StoriesListScreen extends StatefulWidget {
  const StoriesListScreen({super.key});

  @override
  State<StoriesListScreen> createState() => _StoriesListScreenState();
}

class _StoriesListScreenState extends State<StoriesListScreen>
    with SingleTickerProviderStateMixin {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  late AnimationController _staggerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  final List<Animation<double>> _cardAnimations = [];

  // Featured carousel
  late PageController _carouselController;
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;
  static const int _carouselStoryCount = 4;

  // Expanded 'Read more' summaries on story cards
  final Set<String> _expandedCardIds = {};

  @override
  void initState() {
    super.initState();
    // Preload the interstitial so it's ready when a story is opened
    AdService.instance.loadInterstitial();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOutCubic),
    ));

    _carouselController = PageController(viewportFraction: 0.85);

    // Pre-create card animations for up to 12 cards
    for (int i = 0; i < 12; i++) {
      // Each card gets 216ms to animate, with 120ms gap between starts
      // Card 0 starts at 30%, Card 1 at 40%, etc.
      final start = 0.30 + i * 0.10;
      final end = (start + 0.18).clamp(0.0, 1.0);
      _cardAnimations.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }

    _staggerController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staggerController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarouselAutoScroll(int storyCount) {
    _carouselTimer?.cancel();
    if (storyCount < 2) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentCarouselPage + 1) % storyCount.clamp(1, _carouselStoryCount);
      if (_carouselController.hasClients) {
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  /// Open a story detail — shows the (frequency-capped) interstitial first.
  /// Navigation happens after the ad is dismissed so the user lands on the
  /// story cleanly.
  Future<void> _openStory(dynamic story) async {
    await AdService.instance.showInterstitial();
    if (!mounted) return;
    context.push('/stories/${story.id}');
  }

  /// Get category color for a story
  Color _getCategoryColor(String category) {
    final match = AppConstants.storyCategories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {'color': AppColors.primary},
    );
    return match['color'] as Color;
  }

  /// Get category icon for a story
  String _getCategoryIcon(String category) {
    final match = AppConstants.storyCategories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {'icon': '📖'},
    );
    return match['icon'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoriesProvider>();
    final stories = provider.stories;
    final hasStories = stories.isNotEmpty;

    // Trigger animation when stories load
    if (hasStories && !_staggerController.isAnimating && _staggerController.value == 0) {
      _staggerController.forward();
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ========== GRADIENT HEADER ==========
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _staggerController,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _buildGradientHeader(provider),
                    ),
                  );
                },
              ),
            ),

            // Search bar
            if (_showSearch)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _buildSearchField(),
                ),
              ),

            // ========== CATEGORY CHIPS ==========
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _staggerController,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _staggerController,
                      curve: const Interval(0.08, 0.25, curve: Curves.easeOut),
                    ),
                    child: SizedBox(
                      height: 46,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: AppConstants.storyCategories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(
                                '🌟 All',
                                null,
                                provider.selectedCategory == null,
                              ),
                            );
                          }
                          final cat = AppConstants.storyCategories[index - 1];
                          final name = cat['name'] as String;
                          final icon = cat['icon'] as String;
                          final isSelected = provider.selectedCategory == name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryChip(
                              '$icon $name',
                              name,
                              isSelected,
                              color: cat['color'] as Color,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ========== FEATURED CAROUSEL ==========
            if (hasStories)
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, _) {
                    final anim = _cardAnimations.length > 0
                        ? _cardAnimations[0]
                        : AlwaysStoppedAnimation(1.0);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        )),
                        child: _buildFeaturedCarousel(stories),
                      ),
                    );
                  },
                ),
              ),

            // Ornamental divider
            if (hasStories && stories.length > _carouselStoryCount)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _buildOrnamentalDivider(),
                ),
              ),

            // Section title
            if (hasStories && stories.length > _carouselStoryCount)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'All Stories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${stories.length} stories',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ========== STORIES GRID (variable-height rows so expanded cards can grow) ==========
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, rowIndex) {
                    // Each row holds 2 stories (after skipping carousel stories)
                    final i0 = rowIndex * 2;
                    final storyIndex0 = hasStories ? i0 + _carouselStoryCount : i0;
                    if (storyIndex0 >= stories.length) return null;
                    final story0 = stories[storyIndex0];
                    final hasSecond = storyIndex0 + 1 < stories.length;
                    final animIndex0 = (i0 + 1).clamp(0, _cardAnimations.length - 1);
                    final animIndex1 = (i0 + 2).clamp(0, _cardAnimations.length - 1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildAnimatedCard(story0, animIndex0),
                            ),
                            if (hasSecond) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildAnimatedCard(
                                  stories[storyIndex0 + 1],
                                  animIndex1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: hasStories
                      ? math.max(0, (stories.length - _carouselStoryCount + 1) ~/ 2)
                      : 0,
                ),
              ),
            ),

            // ========== EMPTY STATE ==========
            if (!hasStories)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(provider),
              ),

            // ========== BANNER AD ==========
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: AdBannerWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── GRADIENT HEADER ───────────────────────────────────────────────

  Widget _buildGradientHeader(StoriesProvider provider) {
    final hasStories = provider.stories.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.08),
        ),
      ),
      child: Stack(
        children: [
          // Decorative lotus pattern
          Positioned(
            top: -20,
            right: -10,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 100,
              color: AppColors.primary.withOpacity(0.06),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 80,
                color: AppColors.primary.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lotus icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sacred Stories',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explore timeless wisdom from ancient scriptures',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search button
                    GestureDetector(
                      onTap: () => setState(() => _showSearch = !_showSearch),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasStories) ...[
                  const SizedBox(height: 14),
                  // Quick stats row
                  Row(
                    children: [
                      _buildHeaderStat(
                        Icons.menu_book_rounded,
                        '${provider.stories.length}',
                        'Stories',
                      ),
                      const SizedBox(width: 20),
                      _buildHeaderStat(
                        Icons.bookmark_rounded,
                        '${provider.bookmarks.length}',
                        'Saved',
                      ),
                      const Spacer(),
                      // Language button
                      const LanguageSwitcherButton(),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }

  // ─── SEARCH FIELD ──────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => context.read<StoriesProvider>().search(q),
        decoration: InputDecoration(
          hintText: 'Search stories...',
          hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<StoriesProvider>().search('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textLight),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─── CATEGORY CHIP ─────────────────────────────────────────────────

  Widget _buildCategoryChip(
    String label,
    String? category,
    bool isSelected, {
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () {
        context.read<StoriesProvider>().filterByCategory(category);
        // Reset expanded summaries so they don't carry across categories
        _expandedCardIds.clear();
        // Restagger animation
        _staggerController.reset();
        _staggerController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [chipColor, chipColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.textLight.withOpacity(0.2),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ─── FEATURED CAROUSEL ───────────────────────────────────────────

  Widget _buildFeaturedCarousel(List stories) {
    final carouselCount = stories.length.clamp(1, _carouselStoryCount);

    // Start auto-scroll timer when carousel is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCarouselAutoScroll(stories.length);
    });

    return Column(
      children: [
        // Section title row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Featured Stories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // See All button
              GestureDetector(
                onTap: () {
                  // Scroll down to grid section
                },
                child: Row(
                  children: [
                    Text(
                      'Swipe',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swipe_rounded,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (page) {
              setState(() => _currentCarouselPage = page);
            },
            itemCount: carouselCount,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _buildCarouselSlide(story, index == _currentCarouselPage);
            },
          ),
        ),

        // Page indicators
        const SizedBox(height: 12),
        if (carouselCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(carouselCount, (i) {
              final isActive = i == _currentCarouselPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: isActive
                      ? AppColors.primaryGradient
                      : null,
                  color: isActive ? null : AppColors.textLight.withOpacity(0.2),
                ),
              );
            }),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build a single carousel slide
  Widget _buildCarouselSlide(story, bool isActive) {
    final color = _getCategoryColor(story.category);
    final icon = _getCategoryIcon(story.category);

    return GestureDetector(
      onTap: () => _openStory(story),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 16,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(isActive ? 0.3 : 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isActive ? 0.15 : 0.08),
              blurRadius: isActive ? 20 : 10,
              offset: Offset(0, isActive ? 6 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -5,
              top: -5,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 70,
                color: color.withOpacity(0.08),
              ),
            ),
            Row(
              children: [
                // Left: Emoji icon area
                Container(
                  width: 120,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 44)),
                  ),
                ),
                // Right: Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                story.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Title
                        Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Summary
                        if (story.summary != null)
                          Text(
                            story.summary!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight.withOpacity(0.8),
                              height: 1.3,
                            ),
                          ),
                        const SizedBox(height: 6),
                        // Meta
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.textLight.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${story.readingTimeMinutes} min',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.visibility_outlined,
                              size: 13,
                              color: AppColors.textLight.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${story.reads} reads',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── ANIMATED STORY CARD ───────────────────────────────────────────

  Widget _buildAnimatedCard(story, int animIndex) {
    final anim = _cardAnimations[animIndex.clamp(0, _cardAnimations.length - 1)];
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - anim.value)),
            child: _buildStoryCard(story),
          ),
        );
      },
    );
  }

  Widget _buildStoryCard(story) {
    final color = _getCategoryColor(story.category);
    final icon = _getCategoryIcon(story.category);
    // Use the Hindi content when the app language is Hindi (and a Hindi
    // version exists), otherwise fall back to the default content.
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final displayContent = isHindi &&
            story.contentHindi != null &&
            story.contentHindi.trim().isNotEmpty
        ? story.contentHindi
        : story.content;

    return GestureDetector(
      onTap: () => _openStory(story),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with gradient
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.08),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  // Category badge top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        story.readingTimeMinutes <= 5 ? 'Quick' : '${story.readingTimeMinutes} min',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bookmark indicator right
                  if (context.read<StoriesProvider>().isBookmarked(story.id))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (story.summary != null) ...[
                    const SizedBox(height: 4),
                    _buildExpandableSummary(story.summary!, story.id, color, displayContent),
                  ],
                  const SizedBox(height: 8),
                  // Bottom row
                  Row(
                    children: [
                      // Category dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          story.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EXPANDABLE SUMMARY ─────────────────────────────────────────────

  /// Summary that shows 2 lines collapsed with a 'Read more' toggle.
  /// When expanded, reveals the FULL story content in readable paragraphs.
  Widget _buildExpandableSummary(
    String summary,
    String storyId,
    Color color,
    String content,
  ) {
    final isExpanded = _expandedCardIds.contains(storyId);
    // Show the toggle whenever there's a real story to reveal
    final needsToggle = content.length > 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
            height: 1.3,
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          // FULL story in paragraphs
          ...formatStoryContent(content).map((paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              paragraph,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          )),
        ],
        if (needsToggle)
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCardIds.remove(storyId);
                } else {
                  _expandedCardIds.add(storyId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded ? 'Show less' : 'Read full story',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── ORNAMENTAL DIVIDER ────────────────────────────────────────────

  Widget _buildOrnamentalDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.08),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────

  Widget _buildEmptyState(StoriesProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.02),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  provider.selectedCategory != null || provider.stories.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.menu_book_rounded,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              provider.selectedCategory != null
                  ? 'No stories in this category'
                  : 'No stories available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.selectedCategory != null
                  ? 'Try a different category'
                  : 'Stories will appear here once loaded',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (provider.selectedCategory != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<StoriesProvider>().filterByCategory(null);
                  _staggerController.reset();
                  _staggerController.forward();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Show All Stories'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STORY DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════

class StoryDetailScreen extends StatelessWidget {
  final String storyId;

  const StoryDetailScreen({super.key, required this.storyId});

  Color _getCategoryColor(String category) {
    final match = AppConstants.storyCategories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {'color': AppColors.primary},
    );
    return match['color'] as Color;
  }

  String _getCategoryIcon(String category) {
    final match = AppConstants.storyCategories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {'icon': '📖'},
    );
    return match['icon'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoriesProvider>();
    final story = provider.stories.firstWhere(
      (s) => s.id == storyId,
      orElse: () => provider.stories.first,
    );
    final color = _getCategoryColor(story.category);
    final icon = _getCategoryIcon(story.category);
    // Show the Hindi version of the story text when the app language is Hindi
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final displayContent = isHindi &&
            story.contentHindi != null &&
            story.contentHindi!.trim().isNotEmpty
        ? story.contentHindi!
        : story.content;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: color.withOpacity(0.1),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.05),
                      scheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative icon
                    Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                    // Gradient fade at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              scheme.surface,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Bookmark
              IconButton(
                icon: Icon(
                  provider.isBookmarked(storyId)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: provider.isBookmarked(storyId)
                      ? AppColors.primary
                      : scheme.onSurface,
                ),
                onPressed: () => provider.toggleBookmark(story),
              ),
              // Share
              IconButton(
                icon: Icon(Icons.share_rounded,
                    color: scheme.onSurface),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              const LanguageSwitcherButton(),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          story.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    story.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (story.titleHindi != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      story.titleHindi!,
                      style: TextStyle(
                        fontSize: 18,
                        color: scheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Meta row
                  Row(
                    children: [
                      _buildDetailMeta(
                        context,
                        Icons.schedule_rounded,
                        '${story.readingTimeMinutes} min read',
                      ),
                      const SizedBox(width: 20),
                      _buildDetailMeta(
                        context,
                        Icons.visibility_outlined,
                        '${story.reads} reads',
                      ),
                      if (story.audioUrl != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.headphones_rounded,
                                  size: 16,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Listen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Summary
                  if (story.summary != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.06),
                            color.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 24,
                            color: color.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              story.summary!,
                              style: TextStyle(
                                fontSize: 15,
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Content (split into readable paragraphs)
                  if (displayContent.trim().isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.12)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 36,
                            color: color.withOpacity(0.4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Story content coming soon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The full story text for this tale will be added shortly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.outline,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    ...formatStoryContent(displayContent).map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        paragraph,
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme.onSurface,
                          height: 1.8,
                        ),
                      ),
                    )),

                  // Tags
                  if (story.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Divider(color: scheme.outlineVariant, height: 1),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: story.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMeta(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }

}

/// Split long story content into readable paragraphs on sentence boundaries.
/// NOTE: uses a manual split — Dart's RegExp does NOT support lookbehind, so
/// a regex like (?<=[.!?])\s+ would silently fail to split.
List<String> formatStoryContent(String content) {
  final sentences = <String>[];
  final buffer = StringBuffer();

  for (int i = 0; i < content.length; i++) {
    final ch = content[i];
    buffer.write(ch);

    // A sentence ends at . ! ? " ' (or Devanagari danda । ॥) followed by
    // whitespace or end of string
    final isEnder = '.!?"\'\u0964\u0965'.contains(ch);
    final isLast = i == content.length - 1;
    final nextIsSpace = !isLast &&
        (content[i + 1] == ' ' || content[i + 1] == '\n' || content[i + 1] == '\t');

    if (isEnder && (isLast || nextIsSpace)) {
      final s = buffer.toString().trim();
      if (s.isNotEmpty) sentences.add(s);
      buffer.clear();
    }
  }

  final tail = buffer.toString().trim();
  if (tail.isNotEmpty) sentences.add(tail);

  if (sentences.isEmpty) return [content];

  // Group ~2-3 sentences per paragraph for a book-like feel
  final paragraphs = <String>[];
  for (int i = 0; i < sentences.length; i += 3) {
    final end = math.min(i + 3, sentences.length);
    paragraphs.add(sentences.sublist(i, end).join(' '));
  }
  return paragraphs;
}
