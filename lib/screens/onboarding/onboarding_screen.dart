import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/translations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding data
  final _nameController = TextEditingController();
  final List<String> _selectedInterests = [];
  String? _selectedDeity;
  String? _selectedMantra;
  String _selectedLanguage = 'en';
  int _dailyGoal = 108;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();

    // Update name if provided
    if (_nameController.text.trim().isNotEmpty) {
      await userProvider.updateProfile(name: _nameController.text.trim());
    }

    // Update onboarding preferences
    await userProvider.updateOnboarding(
      interests: _selectedInterests,
      favoriteDeity: _selectedDeity,
      preferredMantra: _selectedMantra,
      language: _selectedLanguage,
      dailyGoal: _dailyGoal,
    );

    // Apply the selected language so the app UI switches immediately.
    final localeProvider = context.read<LocaleProvider>();
    await localeProvider.setLocale(_selectedLanguage);

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text('Skip', style: TextStyle(color: textSecondary)),
                    )
                  else
                    const SizedBox(width: 80),

                  // Page indicator
                  Row(
                    children: List.generate(
                      4,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                   // Language switcher
                   GestureDetector(
                     onTap: () => _showOnboardingLanguagePicker(context),
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: isDark ? AppColors.darkCard : AppColors.secondary,
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         context.watch<LocaleProvider>().badge,
                         style: TextStyle(
                           fontSize: 11,
                           fontWeight: FontWeight.bold,
                           color: isDark ? AppColors.textOnDark : AppColors.primary,
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildNamePage(isDark, textPrimary, textSecondary, surfaceColor, cardColor),
                  _buildInterestsPage(isDark, textPrimary, textSecondary, surfaceColor, cardColor),
                  _buildDeityPage(isDark, textPrimary, textSecondary, surfaceColor, cardColor),
                  _buildGoalPage(isDark, textPrimary, textSecondary, surfaceColor, cardColor),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentPage < 3) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_currentPage == 3
                          ? 'Begin Your Journey'
                          : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 1: Name
  Widget _buildNamePage(bool isDark, Color textPrimary, Color textSecondary, Color surfaceColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'What should we call you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your name helps us personalize your journey',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: textPrimary, fontSize: 15),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: textSecondary),
              prefixIcon: Icon(Icons.person_outline_rounded, color: textSecondary),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildInterestIcon(Map<String, dynamic> interest) {
     final imagePath = interest['image'] as String?;
     if (imagePath != null && imagePath.isNotEmpty) {
       return Image.asset(
         imagePath,
         width: 24,
         height: 24,
         fit: BoxFit.contain,
       );
     }
     return Text(interest['icon'] as String, style: const TextStyle(fontSize: 20));
   }

   // Page 2: Spiritual Interests
   Widget _buildInterestsPage(bool isDark, Color textPrimary, Color textSecondary, Color surfaceColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'What interests you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that resonate with you',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AppConstants.spiritualInterests.length,
              itemBuilder: (context, index) {
                final interest = AppConstants.spiritualInterests[index];
                final isSelected = _selectedInterests.contains(interest['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['name']);
                      } else {
                        _selectedInterests.add(interest['name'] as String);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (interest['color'] as Color).withOpacity(0.15)
                          : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? interest['color'] as Color
                            : (isDark ? AppColors.textLight.withOpacity(0.2) : AppColors.textLight.withOpacity(0.2)),
                        width: 2,
                      ),
                    ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         _buildInterestIcon(interest),
                         const SizedBox(width: 8),
                         Text(
                           interest['name'] as String,
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                             color: isSelected
                                 ? interest['color'] as Color
                                 : textPrimary,
                           ),
                         ),
                       ],
                     ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: Favorite Deity and Mantra
  Widget _buildDeityPage(bool isDark, Color textPrimary, Color textSecondary, Color surfaceColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
          Text(
            'Your Spiritual Path',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your favorite deity or spiritual focus',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
            const SizedBox(height: 24),

            // Deity selection
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.deities.map((deity) {
                final isSelected = _selectedDeity == deity['name'];
                return ChoiceChip(
                  label: Text(deity['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDeity = selected ? deity['name'] as String : null;
                      if (selected) {
                        _selectedMantra = deity['mantra'] as String;
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  backgroundColor: cardColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.textLight.withOpacity(0.2) : AppColors.textLight.withOpacity(0.2)),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Language selection
            Text(
              'Preferred Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: AppConstants.languages.map((lang) {
                  final isSelected = _selectedLanguage == lang['code'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ChoiceChip(
                      label: Text(lang['native'] as String),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedLanguage = lang['code'] as String);
                        }
                      },
                      selectedColor: AppColors.primary.withOpacity(0.1),
                      backgroundColor: cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 4: Daily Goal
  Widget _buildGoalPage(bool isDark, Color textPrimary, Color textSecondary, Color surfaceColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Set Your Daily Goal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How many mantras would you like to chant daily?',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Goal selector
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '$_dailyGoal',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'chants per day',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _dailyGoal > 21
                          ? () => setState(() => _dailyGoal -= 21)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppColors.primary,
                      iconSize: 32,
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: _dailyGoal < 1080
                          ? () => setState(() => _dailyGoal += 21)
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.primary,
                      iconSize: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGoalChip(21, isDark, textPrimary, cardColor),
              const SizedBox(width: 8),
              _buildGoalChip(108, isDark, textPrimary, cardColor),
              const SizedBox(width: 8),
              _buildGoalChip(216, isDark, textPrimary, cardColor),
              const SizedBox(width: 8),
              _buildGoalChip(1080, isDark, textPrimary, cardColor),
            ],
          ),
        ],
      ),
    );
  }

  void _showOnboardingLanguagePicker(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final locCode = localeProvider.localeCode;
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Translations.get('select_language', locale: locCode),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
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
                      fillColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(height: 12),
                  // Results count
                  if (query.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${filteredLocales.length} ${filteredLocales.length == 1 ? 'language' : 'languages'} found',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                    ),
                  // Language list
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
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) setState(() => _selectedLanguage = code);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.1) : (isDark ? AppColors.darkCard : Colors.grey.shade50),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : (isDark ? AppColors.textLight.withOpacity(0.2) : Colors.grey.shade200),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                    child: Text(badge, style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : (isDark ? AppColors.textSecondary : Colors.grey.shade600),
                                    )),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(native, style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected ? AppColors.primary : textPrimary,
                                        )),
                                        if (query.isNotEmpty)
                                          Text(
                                            lang['name'] ?? '',
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
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
                              Icon(Icons.search_off_rounded, size: 40, color: textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'No languages found',
                                style: TextStyle(fontSize: 14, color: textSecondary),
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

  Widget _buildGoalChip(int goal, bool isDark, Color textPrimary, Color cardColor) {
    return GestureDetector(
      onTap: () => setState(() => _dailyGoal = goal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _dailyGoal == goal
              ? AppColors.primary
              : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dailyGoal == goal
                ? AppColors.primary
                : (isDark ? AppColors.textLight.withOpacity(0.2) : AppColors.textLight.withOpacity(0.2)),
          ),
        ),
        child: Text(
          goal >= 1000 ? '${goal ~/ 1000}K' : '$goal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _dailyGoal == goal ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }
}
