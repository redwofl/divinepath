import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';

/// A reusable circular button that shows the current language badge
/// and opens a language picker bottom sheet on tap.
/// Can be placed in any screen's AppBar or header row.
class LanguageSwitcherButton extends StatelessWidget {
  final double size;
  final double borderRadius;
  final double fontSize;

  const LanguageSwitcherButton({
    super.key,
    this.size = 40,
    this.borderRadius = 12,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    return GestureDetector(
      onTap: () => _showLanguagePicker(context, localeProvider),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Text(
            localeProvider.badge,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Show language picker bottom sheet with search filter
void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final query = textController.text.toLowerCase().trim();
          final filteredLocales = query.isEmpty
              ? Translations.supportedLocales
              : Translations.supportedLocales.where((lang) {
                  final native = (lang['native'] ?? '').toLowerCase();
                  final name = (lang['name'] ?? '').toLowerCase();
                  final code = (lang['code'] ?? '').toLowerCase();
                  return native.contains(query) ||
                      name.contains(query) ||
                      code.contains(query);
                }).toList();

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  Translations.get('select_language', locale: localeProvider.localeCode),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Search field
                TextField(
                  controller: textController,
                  onChanged: (_) => setSheetState(() {}),
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search language...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              textController.clear();
                              setSheetState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Results count
                if (query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${filteredLocales.length} ${filteredLocales.length == 1 ? 'language' : 'languages'} found',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                // Language list (limited height, scrollable)
                if (filteredLocales.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (filteredLocales.length * 60 + 20)
                          .clamp(0.0, MediaQuery.of(context).size.height * 0.5).toDouble(),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: filteredLocales.map((lang) {
                      final code = lang['code']!;
                      final native = lang['native']!;
                      final badge = lang['badge']!;
                      final isSelected = localeProvider.localeCode == code;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () async {
                            await localeProvider.setLocale(code);
                            textController.dispose();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : (isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      badge,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        native,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? Colors.white : AppColors.textPrimary),
                                        ),
                                      ),
                                      if (query.isNotEmpty)
                                        Text(
                                          lang['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey.shade500 : AppColors.textLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    ),
                  ),
                if (query.isNotEmpty && filteredLocales.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: isDark ? Colors.grey.shade600 : AppColors.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No languages found',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade500 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    },
  );
}
