// lib/main.dart

import 'package:flutter/material.dart';
import 'ui/splash_screen.dart';  // ← update path if you used different folder

void main() {
  runApp(const EyerisApp());
}

class EyerisApp extends StatelessWidget {
  const EyerisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyeris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}