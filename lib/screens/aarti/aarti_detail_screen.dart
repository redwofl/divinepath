import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/aarti_data.dart';

/// Reading screen for a single aarti, with adjustable font size.
class AartiDetailScreen extends StatefulWidget {
  final String aartiId;

  const AartiDetailScreen({super.key, required this.aartiId});

  @override
  State<AartiDetailScreen> createState() => _AartiDetailScreenState();
}

class _AartiDetailScreenState extends State<AartiDetailScreen> {
  double _fontSize = 17;

  @override
  Widget build(BuildContext context) {
    final aarti = AartiData.byId(widget.aartiId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = aarti.color;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar with gradient header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.25),
                      color.withOpacity(0.06),
                      scheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.85),
                          border: Border.all(
                            color: color.withOpacity(0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(aarti.icon,
                              style: const TextStyle(fontSize: 42)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 50,
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    aarti.titleHindi,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aarti.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    aarti.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textLight : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Font size controls
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.textLight.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _fontSize > 14
                                ? () => setState(() => _fontSize -= 1.5)
                                : null,
                            icon: const Icon(Icons.text_decrease_rounded,
                                size: 18),
                            color: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: _fontSize < 24
                                ? () => setState(() => _fontSize += 1.5)
                                : null,
                            icon: const Icon(Icons.text_increase_rounded,
                                size: 18),
                            color: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Verses
                  ...aarti.verses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final verse = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ornamental separator for verse 0
                          if (index == 0) ...[
                            Center(
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                size: 22,
                                color: color.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: color.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              verse,
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 1.7,
                                color: isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '🙏 जय श्री कृष्णा 🙏',
                      style: TextStyle(
                        fontSize: 13,
                        color: color.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
