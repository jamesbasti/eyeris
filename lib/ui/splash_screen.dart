// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';  // ← import the home screen (add this later)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,   // ← must have this
        height: double.infinity,  // ← must have this
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000D64),
              Color(0xFF112CDF),
              Color(0xFF35F0FF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/eyeris_icon.png',
                width: 146,
                height: 146,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                'WELCOME TO',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'EYERIS',
                style: GoogleFonts.inter(
                  fontSize: 65,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 4.0,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}