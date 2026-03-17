// lib/ui/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';

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
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => OnboardingScreen(
            onComplete: (profile) {
              // Update profile in app state
              if (widget.onProfileUpdate != null) {
                widget.onProfileUpdate!(profile);
              }
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
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