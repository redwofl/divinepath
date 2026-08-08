import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/gita_verse_data.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class VerseSearchScreen extends StatefulWidget {
  const VerseSearchScreen({super.key});

  @override
  State<VerseSearchScreen> createState() => _VerseSearchScreenState();
}

class _VerseSearchScreenState extends State<VerseSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<VerseSearchResult> _results = const [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() {
      _searched = true;
      _results = GitaVerseData.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final locCode = context.watch<LocaleProvider>().localeCode;
    final query = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.get('search_gita', locale: locCode)),
        actions: const [
          LanguageSwitcherButton(),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 15,
                fontFamily: isHindi ? 'Mukta' : null,
              ),
              decoration: InputDecoration(
                hintText: Translations.get('search_hint', locale: locCode),
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.textPrimary.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context, locCode, isHindi, query),
    );
  }

  Widget _buildBody(
      BuildContext context, String locCode, bool isHindi, String query) {
    // Initial state: prompt the user to type something.
    if (!_searched || query.isEmpty) {
      return _buildInitialState(context, locCode, isHindi);
    }

    // No matches.
    if (_results.isEmpty) {
      return _buildEmptyState(context, locCode, query);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              Translations.t('results_count',
                  locale: locCode, params: {'count': '${_results.length}'}),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final result = _results[index - 1];
        return _VerseResultCard(result: result, isHindi: isHindi);
      },
    );
  }

  Widget _buildInitialState(BuildContext context, String locCode, bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.sunsetGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.manage_search_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              Translations.get('search_prompt', locale: locCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
                fontFamily: isHindi ? 'Mukta' : null,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['karma', 'dharma', 'yoga', 'soul', 'आत्मा']
                  .map(
                    (chip) => ActionChip(
                      label: Text(chip),
                      labelStyle: const TextStyle(fontSize: 13),
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      side: BorderSide.none,
                      onPressed: () {
                        _controller.text = chip;
                        _onChanged(chip);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String locCode, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textLight),
            const SizedBox(height: 14),
            Text(
              Translations.get('no_results', locale: locCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseResultCard extends StatelessWidget {
  final VerseSearchResult result;
  final bool isHindi;

  const _VerseResultCard({required this.result, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final chapterName = _chapterName(result.chapterNumber);
    final translation = isHindi && result.translationHindi.isNotEmpty
        ? result.translationHindi
        : result.translationEnglish;
    final displayShloka = result.shloka.isNotEmpty
        ? result.shloka
        : result.transliteration;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(
              '/gita/${result.chapterNumber}/${result.verseNumber}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isHindi
                            ? 'अध्याय ${result.chapterNumber} • श्लोक ${result.verseNumber}'
                            : 'Ch. ${result.chapterNumber} • Verse ${result.verseNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  displayShloka,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: isHindi ? 'Mukta' : null,
                  ),
                ),
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    translation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                      fontFamily: isHindi ? 'Mukta' : null,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  chapterName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _chapterName(int chapterNumber) {
    if (chapterNumber < 1 ||
        chapterNumber > AppConstants.gitaChapters.length) {
      return 'Chapter $chapterNumber';
    }
    final chapter = AppConstants.gitaChapters[chapterNumber - 1];
    return isHindi && chapter['nameHindi'] != null
        ? chapter['nameHindi']!
        : chapter['name']!;
  }
}
