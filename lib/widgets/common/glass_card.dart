import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;
  final Gradient? gradient;
  final Color? color;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool withGlow;

  const GlassCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.height,
    this.width,
    this.gradient,
    this.color,
    this.borderRadius = 20,
    this.boxShadow,
    this.onTap,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          boxShadow: boxShadow ?? [
            BoxShadow(
              color: (gradient != null
                      ? AppColors.primary
                      : AppColors.textLight)
                  .withOpacity(withGlow ? 0.08 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: withGlow ? 2 : 0,
            ),
            BoxShadow(
              color: (gradient != null
                      ? AppColors.primary
                      : Colors.black)
                  .withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: gradient == null
              ? Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.textLight.withOpacity(0.08),
                  width: 1,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}
