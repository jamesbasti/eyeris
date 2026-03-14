// lib/widgets/profile_avatar.dart
// User profile avatar component for header

import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.onTap,
    this.size = 40,
    this.imageUrl,
  });

  final VoidCallback onTap;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: EyerisColors.surface,
          border: Border.all(
            color: EyerisColors.border,
            width: EyerisBorders.thin,
          ),
          borderRadius: BorderRadius.circular(EyerisRadii.medium),
        ),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(EyerisRadii.medium - 1),
                child: Image.network(
                  imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultAvatar(),
                ),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: size * 0.6,
      color: EyerisColors.textMuted,
    );
  }
}
