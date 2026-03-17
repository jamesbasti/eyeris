// lib/models/voice_command.dart
//
// Data model for voice commands parsed from speech input.

/// Intent types for voice commands
enum VoiceIntent {
  navigation,
  action,
  setting,
  unknown,
}

/// Target screens for navigation
enum NavigationTarget {
  read,
  colorDetect,
  sceneDescribe,
  communicate,
  back,
  home,
}

/// Target actions that can be triggered
enum ActionTarget {
  detectColor,
  readText,
  describeScene,
}

/// Target settings that can be changed
enum SettingTarget {
  torch,
  speechRate,
}

/// Parsed voice command with intent, target, and parameters
class VoiceCommand {
  final VoiceIntent intent;
  final String target;
  final Map<String, dynamic> parameters;
  final double confidence;
  final String response;
  final String originalText;

  const VoiceCommand({
    required this.intent,
    required this.target,
    this.parameters = const {},
    this.confidence = 1.0,
    this.response = '',
    this.originalText = '',
  });

  /// Create an unknown command (failed to parse)
  factory VoiceCommand.unknown(String originalText) {
    return VoiceCommand(
      intent: VoiceIntent.unknown,
      target: '',
      confidence: 0.0,
      response: "I didn't understand that command.",
      originalText: originalText,
    );
  }

  /// Check if this is a valid, actionable command
  bool get isValid => intent != VoiceIntent.unknown && target.isNotEmpty;

  /// Get navigation target if this is a navigation command
  NavigationTarget? get navigationTarget {
    if (intent != VoiceIntent.navigation) return null;
    return NavigationTarget.values.cast<NavigationTarget?>().firstWhere(
      (t) => t?.name == target,
      orElse: () => null,
    );
  }

  /// Get action target if this is an action command
  ActionTarget? get actionTarget {
    if (intent != VoiceIntent.action) return null;
    return ActionTarget.values.cast<ActionTarget?>().firstWhere(
      (t) => t?.name == target,
      orElse: () => null,
    );
  }

  /// Get setting target if this is a setting command
  SettingTarget? get settingTarget {
    if (intent != VoiceIntent.setting) return null;
    return SettingTarget.values.cast<SettingTarget?>().firstWhere(
      (t) => t?.name == target,
      orElse: () => null,
    );
  }

  /// Get torch state parameter (on/off)
  bool? get torchState {
    if (settingTarget != SettingTarget.torch) return null;
    final state = parameters['state'];
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }

  /// Get speech rate direction (increase/decrease)
  String? get speechRateDirection {
    if (settingTarget != SettingTarget.speechRate) return null;
    return parameters['direction'] as String?;
  }

  @override
  String toString() {
    return 'VoiceCommand(intent: $intent, target: $target, '
        'params: $parameters, confidence: $confidence)';
  }
}
