// lib/widgets/screen_header.dart
// Top navigation bar: optional back, title, optional right slot. Optional AppStatusBar.

import 'package:flutter/material.dart';

import 'package:eyeris/core/app_theme.dart';

/// Top bar: back (44×44 when [onBack] set), title, [rightElement].
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.rightElement,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? rightElement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: EyerisTheme.primary, width: EyerisTheme.borderFocus),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (onBack != null) ...[
            Semantics(
              label: 'Go back',
              hint: 'Returns to the previous screen',
              button: true,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: EyerisTheme.touchBackButton,
                  height: EyerisTheme.touchBackButton,
                  decoration: BoxDecoration(
                    color: EyerisTheme.primary,
                    borderRadius: BorderRadius.circular(EyerisTheme.radiusSmall),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '←',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontFamily: EyerisTheme.fontFamily,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: typography(
                  size: 'lg',
                  weight: FontWeight.w700,
                  color: EyerisTheme.primary,
                  letterSpacingKey: 'wider',
                ).copyWith(letterSpacing: 15 * 0.1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (rightElement != null) ...[
            const SizedBox(width: 12),
            rightElement!,
          ],
        ],
      ),
    );
  }
}

/// Decorative status bar row: 40px, time left, app name center, battery right. ExcludeSemantics.
class AppStatusBar extends StatelessWidget {
  const AppStatusBar({
    super.key,
    this.showTime = true,
    this.appName = 'EYERIS ●',
    this.batteryText = '100%',
  });

  final bool showTime;
  final String appName;
  final String batteryText;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 40,
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (showTime)
              Text(
                _formatTime(DateTime.now()),
                style: TextStyle(
                  fontSize: 11,
                  color: EyerisTheme.textPrimary,
                  fontFamily: EyerisTheme.fontFamily,
                  letterSpacing: 0.05 * 11,
                ),
              ),
            const Spacer(),
            Text(
              appName,
              style: TextStyle(
                fontSize: 11,
                color: EyerisTheme.textPrimary,
                fontFamily: EyerisTheme.fontFamily,
                letterSpacing: 0.05 * 11,
              ),
            ),
            const Spacer(),
            Text(
              batteryText,
              style: TextStyle(
                fontSize: 11,
                color: EyerisTheme.textPrimary,
                fontFamily: EyerisTheme.fontFamily,
                letterSpacing: 0.05 * 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
