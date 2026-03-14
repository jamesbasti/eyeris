import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ────────// ─────────────────────────────────────
// SCREEN HEADER
// Back button (44×44) + title + optional right slot.
// Announces as a header region to screen readers.
// ─────────────────────────────────────

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;  // null = no back button (home screen)
  final Widget? rightElement;

  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.rightElement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EyerisColors.black,
        border: Border(
          bottom: BorderSide(
            color: EyerisColors.primary,
            width: EyerisBorders.header,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EyerisSpacing.lg,
        vertical: EyerisSpacing.md,
      ),
      child: Row(
        children: [
          // ── Back button
          if (onBack != null) ...[
            Semantics(
              label: 'Go back',
              hint: 'Returns to the previous screen',
              button: true,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: EyerisTouchTargets.backButton,
                  height: EyerisTouchTargets.backButton,
                  decoration: BoxDecoration(
                    color: EyerisColors.primary,
                    borderRadius: BorderRadius.circular(EyerisRadii.small),
                  ),
                  child: Center(
                    child: EyerisIcons.backArrow(
                      size: 20,
                      color: EyerisColors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: EyerisSpacing.md),
          ],

          // ── Title (screen name — announced as header)
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: EyerisText.screenTitle,
              ),
            ),
          ),

          // ── Right slot (profile avatar, settings icon, etc.)
          if (rightElement != null) rightElement!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE AVATAR
// 36×36 circle used in home screen header right slot.
// ─────────────────────────────────────────────

class ProfileAvatar extends StatelessWidget {
  final VoidCallback? onPress;

  const ProfileAvatar({super.key, this.onPress});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile and settings',
      button: true,
      child: GestureDetector(
        onTap: onPress ?? () {},
        child: Container(
          // Increased from 36 → 44 to meet WCAG minimum tap target
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // Yellow fill — high contrast, clearly tappable
            color: EyerisColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            // Black icon on yellow — 21:1 contrast
            child: EyerisIcons.person(size: 22, color: EyerisColors.black),
          ),
        ),
      ),
    );
  }
}
