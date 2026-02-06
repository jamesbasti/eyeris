// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/splash_screen.dart';  // ← update path if you used different folder

Future<void> main() async {
  await dotenv.load(); // Load environment variables from .env file
  print('API Key: ${dotenv.env['OPENAI_API_KEY']}');
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