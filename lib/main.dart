// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_theme.dart';
import 'ui/splash_screen.dart';

Future<void> main() async {
  await dotenv.load(); // Load environment variables from .env file
  runApp(const EyerisApp());
}

class EyerisApp extends StatelessWidget {
  const EyerisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyeris',
      debugShowCheckedModeBanner: false,
      theme: buildEyerisTheme(),
      home: const SplashScreen(),
    );
  }
}
