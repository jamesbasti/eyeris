// lib/ui/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/core/routes.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';
import 'package:eyeris/services/user_preferences_service.dart';

class SplashScreen extends StatefulWidget {
  final Function(OnboardingProfile)? onProfileUpdate;

  const SplashScreen({super.key, this.onProfileUpdate});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Initialize user preferences service
    await UserPreferencesService.instance.initialize();

    // Wait minimum 2 seconds for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if onboarding is completed
    final isOnboardingCompleted = UserPreferencesService.instance.isOnboardingCompleted;

    // Navigate to appropriate screen
    if (isOnboardingCompleted) {
      Navigator.pushReplacementNamed(context, EyerisRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, EyerisRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisTheme.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: EyerisTheme.background,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eyeris icon - full size
              Image.asset(
                'assets/eyeris_icon.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 50),
              
              // App name with Eyeris typography
              Text(
                'EYERIS',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: EyerisTheme.primary,
                  letterSpacing: 4.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AI Vision Assistant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: EyerisTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}