// lib/models/user_preferences.dart
//
// User preferences model for storing onboarding profile and app settings.

class UserPreferences {
  final bool onboardingCompleted;
  final Set<String> visionTypes;
  final String interactionMode;
  final String voiceSpeed;

  const UserPreferences({
    this.onboardingCompleted = false,
    this.visionTypes = const {},
    this.interactionMode = 'touch',
    this.voiceSpeed = 'normal',
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'onboarding_completed': onboardingCompleted,
      'vision_types': visionTypes.toList(),
      'interaction_mode': interactionMode,
      'voice_speed': voiceSpeed,
    };
  }

  /// Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      visionTypes: (json['vision_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      interactionMode: json['interaction_mode'] as String? ?? 'touch',
      voiceSpeed: json['voice_speed'] as String? ?? 'normal',
    );
  }

  /// Create a copy with updated fields
  UserPreferences copyWith({
    bool? onboardingCompleted,
    Set<String>? visionTypes,
    String? interactionMode,
    String? voiceSpeed,
  }) {
    return UserPreferences(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      visionTypes: visionTypes ?? this.visionTypes,
      interactionMode: interactionMode ?? this.interactionMode,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
    );
  }

  /// Get TTS rate from voice speed setting
  double get ttsRate {
    switch (voiceSpeed) {
      case 'slow':
        return 0.3;
      case 'fast':
        return 0.7;
      case 'normal':
      default:
        return 0.5;
    }
  }

  /// Check if user has specific vision type
  bool hasVisionType(String type) => visionTypes.contains(type);

  /// Check if voice-first interaction is preferred
  bool get isVoiceFirst => interactionMode == 'voice';

  @override
  String toString() {
    return 'UserPreferences(completed: $onboardingCompleted, '
        'vision: $visionTypes, interaction: $interactionMode, speed: $voiceSpeed)';
  }
}
