import 'package:flutter/material.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';
import 'package:eyeris/services/voice_service.dart';

// ─────────────────────────────────────────────
// PROFILE NOTIFIER
//
// Global state management for user profile
// Allows widgets to listen to profile changes without navigation
// Also updates VoiceService when profile changes
// ─────────────────────────────────────────────

class ProfileNotifier extends ChangeNotifier {
  OnboardingProfile? _profile;

  OnboardingProfile? get profile => _profile;

  void updateProfile(OnboardingProfile profile) {
    print('ProfileNotifier: Updating profile to: ${profile.voiceSpeed} speed');
    _profile = profile;
    
    // Initialize VoiceService if not already initialized, then update profile
    if (!VoiceService.instance.isInitialized) {
      print('ProfileNotifier: Initializing VoiceService');
      VoiceService.instance.initialize(profile: profile);
    } else {
      print('ProfileNotifier: Updating existing VoiceService');
      VoiceService.instance.updateProfile(profile);
    }
    
    print('ProfileNotifier: Notifying listeners');
    notifyListeners();
  }
}

// Global instance
final profileNotifier = ProfileNotifier();
