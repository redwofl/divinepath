import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mantra_provider.dart';
import '../../screens/game/bubble_game_screen.dart' show bubbleGameTabPaused;
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';

class MainNavScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBarItem(
                      icon: Icons.home_rounded,
                      label: Translations.get('nav_home', locale: context.watch<LocaleProvider>().localeCode),
                      isSelected: widget.navigationShell.currentIndex == 0,
                      onTap: () => _goToBranch(0),
                    ),
                    _NavBarItem(
                      icon: Icons.auto_awesome_rounded,
                      label: Translations.get('nav_mantra', locale: context.watch<LocaleProvider>().localeCode),
                      isSelected: widget.navigationShell.currentIndex == 1,
                      onTap: () => _goToBranch(1),
                    ),
                    _NavBarItem(
                      icon: Icons.sports_esports_rounded,
                      label: Translations.get('nav_game', locale: context.watch<LocaleProvider>().localeCode),
                      isSelected: widget.navigationShell.currentIndex == 2,
                      onTap: () => _goToBranch(2),
                    ),
                    _NavBarItem(
                      icon: Icons.menu_book_rounded,
                      label: Translations.get('nav_stories', locale: context.watch<LocaleProvider>().localeCode),
                      isSelected: widget.navigationShell.currentIndex == 3,
                      onTap: () => _goToBranch(3),
                    ),
                    _NavBarItem(
                      icon: Icons.auto_stories_rounded,
                      label: Translations.get('nav_gita', locale: context.watch<LocaleProvider>().localeCode),
                      isSelected: widget.navigationShell.currentIndex == 4,
                      onTap: () => _goToBranch(4),
                    ),
                    _NavBarItem(
                      icon: Icons.chat_bubble_rounded,
                      label: Translations.get('nav_chat', locale: context.watch<LocaleProvider>().localeCode),
                      isSelected: widget.navigationShell.currentIndex == 5,
                      onTap: () => _goToBranch(5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goToBranch(int index) {
    // Never let auto-mode chanting keep running in the background when the
    // user leaves the Mantra tab.
    if (index != 1) {
      context.read<MantraProvider>().stopAutoMode();
    }
    // Freeze/unfreeze a running bubble-game round when leaving/entering the
    // Game tab — the screen stays alive inside the IndexedStack shell, so it
    // would otherwise keep animating and playing music in the background.
    bubbleGameTabPaused.value = index != 2;
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textLight,
                size: isSelected ? 26 : 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
