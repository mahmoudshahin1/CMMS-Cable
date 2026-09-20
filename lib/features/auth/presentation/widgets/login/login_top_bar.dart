import 'package:flutter/material.dart';
import 'package:orning_and_evening_remembrances/core/localization/app_strings.dart';

/// Floating top action bar for language switching and theme toggling.
class LoginTopBar extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final VoidCallback onToggleTheme;

  const LoginTopBar({
    super.key,
    required this.isDark,
    required this.isArabic,
    required this.onToggleLanguage,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageActionButton(context),
                const SizedBox(width: 10),
                _buildThemeActionButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageActionButton(BuildContext context) {
    final label = isArabic ? 'English' : 'عربي';
    final tooltip = isArabic ? 'Switch to English' : 'التحويل إلى العربية';
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleLanguage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeActionButton(BuildContext context) {
    final tooltip = isDark
        ? context.tr('toggle_theme_to_light')
        : context.tr('toggle_theme_to_dark');

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleTheme,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
