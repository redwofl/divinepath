import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common/language_switcher_button.dart';

class GitaVersesScreen extends StatelessWidget {
  final int chapterNumber;

  const GitaVersesScreen({super.key, required this.chapterNumber});

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final chapter = AppConstants.gitaChapters[chapterNumber - 1];
    final totalVerses = int.parse(chapter['verses']!);
    final chapterName = isHindi && chapter['nameHindi'] != null
        ? chapter['nameHindi']!
        : chapter['name']!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi ? 'अध्याय ${chapter['number']}' : 'Chapter ${chapter['number']}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: const [
          LanguageSwitcherButton(),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              chapterName,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontFamily: isHindi ? 'Mukta' : null,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: totalVerses,
        itemBuilder: (context, index) {
          final verseNum = index + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => context.push('/gita/$chapterNumber/$verseNum'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$verseNum',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'श्लोक $verseNum' : 'Verse $verseNum',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              fontFamily: isHindi ? 'Mukta' : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHindi
                                ? 'अध्याय ${chapter['number']}, श्लोक $verseNum'
                                : 'Chapter ${chapter['number']}, Verse $verseNum',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontFamily: isHindi ? 'Mukta' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
