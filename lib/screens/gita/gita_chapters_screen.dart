import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common/language_switcher_button.dart';

class GitaChaptersScreen extends StatelessWidget {
  const GitaChaptersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isHindi ? 'श्रीमद्भगवद्गीता' : 'Bhagavad Gita',
                              style: TextStyle(
                                 fontSize: 28,
                                 fontWeight: FontWeight.bold,
                                 color: textPrimary,
                               ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      context.push('/verse-search'),
                                   icon: Icon(
                                     Icons.search_rounded,
                                     color: textPrimary,
                                   ),
                                  tooltip:
                                      isHindi ? 'श्लोक खोजें' : 'Search verses',
                                ),
                                const LanguageSwitcherButton(),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHindi
                              ? 'भगवान का गीत - सम्पूर्ण 18 अध्याय'
                              : 'The Song of the Lord - Complete 18 Chapters',
                          style: TextStyle(
                             fontSize: 14,
                             color: textSecondary,
                           ),
                        ),
                    const SizedBox(height: 20),

                    // Featured verse card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.sunsetGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isHindi ? 'गीता ज्ञान' : 'Gita Wisdom',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '"Yoga-sthah kuru karmani\nsangam tyaktva dhananjaya\nsiddhy-asiddhyoh samo bhutva\nsamatvam yoga ucyate"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isHindi
                                ? 'हे अर्जुन! योग में स्थिर होकर कर्म करो और सफलता-असफलता में समान रहो। यह समत्व ही योग कहलाता है।'
                                : 'Be steadfast in yoga, O Arjuna. Perform your duty and abandon all attachment to success or failure. Such evenness of mind is called yoga.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isHindi ? '- अध्याय 2, श्लोक 48' : '- Chapter 2, Verse 48',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chapters
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chapter = AppConstants.gitaChapters[index];
                    final chapterNum = int.parse(chapter['number']!);
                    final chapterName = chapter['name']!;
                    final verses = chapter['verses']!;

                    // Chapter colors
                    final colors = [
                      AppColors.primary,
                      const Color(0xFF7C3AED),
                      const Color(0xFF059669),
                      const Color(0xFFDB2777),
                      const Color(0xFF2563EB),
                      const Color(0xFFD97706),
                    ];
                    final color = colors[index % colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => context.push('/gita/$chapterNum'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Chapter number
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    chapter['number']!,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [                    Text(
                      isHindi ? 'अध्याय ${chapter['number']}' : 'Chapter ${chapter['number']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi && chapter['nameHindi'] != null
                          ? chapter['nameHindi']!
                          : chapterName,
                      style: TextStyle(
                         fontSize: 15,
                         fontWeight: FontWeight.w600,
                         color: textPrimary,
                       ),
                    ),
                                  ],
                                ),
                              ),
                              Text(
                                isHindi ? '$verses श्लोक' : '$verses verses',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textLight, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: AppConstants.gitaChapters.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
