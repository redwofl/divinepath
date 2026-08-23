import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/gita_model.dart';
import '../../providers/gita_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/gita_verse_data.dart';
import '../../widgets/common/language_switcher_button.dart';

class VerseDetailScreen extends StatefulWidget {
  final int chapterNumber;
  final int verseNumber;

  const VerseDetailScreen({
    super.key,
    required this.chapterNumber,
    required this.verseNumber,
  });

  @override
  State<VerseDetailScreen> createState() => _VerseDetailScreenState();
}

class _VerseDetailScreenState extends State<VerseDetailScreen> {
  bool _showTranslation = true;

  /// The verse content for this chapter+verse, or null if not in the local dataset.
  List<String>? get _verse => GitaVerseData.find(widget.chapterNumber, widget.verseNumber);

  String get _shloka => _verse![0];
  String get _transliteration => _verse![1];
  String get _translationEnglish => _verse![2];
  String get _translationHindi => _verse![3];
  String get _commentary => _verse![4];
  String get _commentaryHindi => _verse![5];

  /// Graceful fallback shown when this verse isn't in the local dataset yet.
  Widget _buildMissingContent(BuildContext context, bool isHindi, bool isDark, Color textPrimaryColor, Color textSecondaryColor) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi
              ? 'अध्याय ${widget.chapterNumber}, श्लोक ${widget.verseNumber}'
              : 'Chapter ${widget.chapterNumber}, Verse ${widget.verseNumber}',
          style: TextStyle(fontSize: 16),
        ),
        actions: const [
          LanguageSwitcherButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                ),
              ),
              child: Column(
                children: [
                  const Text('🕉️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    isHindi
                        ? 'इस श्लोक की सामग्री जल्द ही जोड़ी जाएगी'
                        : 'This verse\'s content is coming soon',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi
                        ? 'अध्याय ${widget.chapterNumber}, श्लोक ${widget.verseNumber} — कृपया दूसरे श्लोक देखें 🙏'
                        : 'Chapter ${widget.chapterNumber}, Verse ${widget.verseNumber} — please explore other verses 🙏',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.verseNumber > 1
                      ? () => context.replace(
                          '/gita/${widget.chapterNumber}/${widget.verseNumber - 1}')
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(isHindi ? 'पिछला' : 'Previous'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final chapter = AppConstants.gitaChapters[widget.chapterNumber - 1];
                    if (widget.verseNumber < int.parse(chapter['verses']!)) {
                      context.replace(
                          '/gita/${widget.chapterNumber}/${widget.verseNumber + 1}');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(isHindi ? 'अगला' : 'Next'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondaryColor = isDark ? AppColors.textLight : AppColors.textSecondary;
    final verse = _verse;
    if (verse == null) {
      return _buildMissingContent(context, isHindi, isDark, textPrimaryColor, textSecondaryColor);
    }
    final surfaceColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.primary.withOpacity(0.3) : AppColors.textLight.withOpacity(0.1);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi
              ? 'अध्याय ${widget.chapterNumber}, श्लोक ${widget.verseNumber}'
              : 'Chapter ${widget.chapterNumber}, Verse ${widget.verseNumber}',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          const LanguageSwitcherButton(),
          const SizedBox(width: 4),
          Consumer<GitaProvider>(
            builder: (context, gitaProvider, _) {
              final isBookmarked =
                  gitaProvider.isBookmarked(widget.chapterNumber, widget.verseNumber);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => gitaProvider.toggleBookmark(VerseBookmark(
                  verseId: '${widget.chapterNumber}.${widget.verseNumber}',
                  chapterNumber: widget.chapterNumber,
                  verseNumber: widget.verseNumber,
                  shloka: _shloka,
                  translation: isHindi ? _translationHindi : _translationEnglish,
                )),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _showTranslation ? Icons.translate_rounded : Icons.text_fields_rounded,
              color: textSecondaryColor,
            ),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shloka (Sanskrit)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: SelectableText(
                _shloka,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  // The shloka card keeps its cream background in both
                  // themes, so the text must stay dark — the theme-aware
                  // color turned near-white in dark mode and vanished.
                  color: AppColors.textPrimary,
                  height: 1.8,
                  fontFamily: 'Mukta',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transliteration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: SelectableText(
                _transliteration,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondaryColor,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Translation tabs
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Column(
                children: [
                  // First translation (language-aware: Hindi first when app is Hindi)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.translate_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              isHindi ? 'हिंदी अनुवाद' : 'English Translation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontFamily: isHindi ? 'Mukta' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          isHindi ? _translationHindi : _translationEnglish,
                          style: TextStyle(
                            fontSize: 16,
                            color: textPrimaryColor,
                            height: 1.6,
                            fontFamily: isHindi ? 'Mukta' : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Second translation (other language)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isHindi ? 'English Translation' : 'हिंदी अनुवाद',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimaryColor,
                                fontFamily: isHindi ? null : 'Mukta',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                          SelectableText(
                            isHindi ? _translationEnglish : _translationHindi,
                            style: TextStyle(
                              fontSize: 16,
                              color: textPrimaryColor,
                              height: 1.6,
                              fontFamily: isHindi ? null : 'Mukta',
                            ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Commentary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        isHindi ? 'व्याख्या' : 'Commentary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    isHindi ? _commentaryHindi : _commentary,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                      height: 1.6,
                      fontFamily: isHindi ? 'Mukta' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.verseNumber > 1
                      ? () => context.replace(
                          '/gita/${widget.chapterNumber}/${widget.verseNumber - 1}')
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(isHindi ? 'पिछला' : 'Previous'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // Check if next verse exists
                    final chapter = AppConstants.gitaChapters[widget.chapterNumber - 1];
                    if (widget.verseNumber < int.parse(chapter['verses']!)) {
                      context.replace(
                          '/gita/${widget.chapterNumber}/${widget.verseNumber + 1}');
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(isHindi ? 'अगला' : 'Next'),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
