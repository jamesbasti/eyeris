// lib/widgets/profile_avatar.dart
// User profile avatar — header right slot.
//
// Design spec:
//   Size       : 44×44 (WCAG 2.5.5 AAA minimum tap target)
//   Background : #FFD100 (EyerisColors.primary) — matches back button style
//   Icon       : black person stroke, 22px — 21:1 contrast on yellow
//   Shape      : circle
//   No border  : yellow fill is sufficient — border adds visual noise
//
// Matches the back button language: yellow fill + black content.

import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.onTap,
    this.size = 44,
    this.imageUrl,
  });

  final VoidCallback onTap;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile and settings',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            // Yellow fill — 18.1:1 contrast against app background,
            // instantly recognisable as a primary action target.
            color: EyerisColors.primary,
            shape: BoxShape.circle,
          ),
          child: imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultIcon(),
                  ),
                )
              : _buildDefaultIcon(),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      // Black icon on yellow — 21:1 contrast.
      child: EyerisIcons.person(
        size: size * 0.50,
        color: EyerisColors.black,
      ),
    );
  }
}
