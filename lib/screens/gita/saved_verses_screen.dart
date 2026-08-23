import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/gita_model.dart';
import '../../providers/gita_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/gita_verse_data.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

/// Lists every Gita verse the user has bookmarked.
///
/// Tapping a card opens the verse detail screen; swipe or the remove button
/// deletes the bookmark (persisted via [GitaProvider]).
class SavedVersesScreen extends StatelessWidget {
  const SavedVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final gitaProvider = context.watch<GitaProvider>();
    final locCode = localeProvider.localeCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final bookmarks = gitaProvider.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.get('saved_verses', locale: locCode),
          style: TextStyle(fontSize: 18, color: textPrimary),
        ),
        actions: const [
          LanguageSwitcherButton(),
          SizedBox(width: 8),
        ],
      ),
      body: bookmarks.isEmpty
          ? _buildEmptyState(context, locCode)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                final verseData =
                    GitaVerseData.find(bookmark.chapterNumber, bookmark.verseNumber);
                return Dismissible(
                  key: ValueKey(
                      '${bookmark.chapterNumber}.${bookmark.verseNumber}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    gitaProvider.removeBookmark(
                        bookmark.chapterNumber, bookmark.verseNumber);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                  ),
                  child: _VerseCard(bookmark: bookmark, verseData: verseData),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String locCode) {
    final localeProvider = context.watch<LocaleProvider>();
    final isHindi = localeProvider.isHindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: AppColors.sunsetGradient,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded,
                    size: 52, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Translations.get('no_saved_verses', locale: locCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Translations.get('saved_verses_hint', locale: locCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push('/gita'),
              icon: const Icon(Icons.explore_rounded),
              label: Text(
                isHindi ? 'गीता ब्राउज़ करें' : 'Browse the Gita',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final VerseBookmark bookmark;
  final List<String>? verseData;

  const _VerseCard({required this.bookmark, required this.verseData});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isHindi = localeProvider.isHindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final shloka = verseData != null ? verseData![0] : (bookmark.shloka ?? '');
    final translation = verseData != null
        ? (isHindi ? verseData![3] : verseData![2])
        : (bookmark.translation ?? '');

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
            '/gita/${bookmark.chapterNumber}/${bookmark.verseNumber}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              // Chapter/verse badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.sunsetGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${bookmark.chapterNumber}.${bookmark.verseNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi
                          ? 'अध्याय ${bookmark.chapterNumber}, श्लोक ${bookmark.verseNumber}'
                          : 'Chapter ${bookmark.chapterNumber}, Verse ${bookmark.verseNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (shloka.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        shloka,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                        height: 1.4,
                        fontFamily: 'Mukta',
                        fontWeight: FontWeight.w500,
                      ),
                      ),
                    ],
                    if (translation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        translation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.bookmark_rounded,
                    color: AppColors.primary),
                onPressed: () => context
                    .read<GitaProvider>()
                    .removeBookmark(bookmark.chapterNumber, bookmark.verseNumber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
