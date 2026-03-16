import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eyeris/app.dart';

void main() async {
  debugPrint('=== Eyeris App Starting ===');
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all Flutter framework errors and print them
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('>>> FLUTTER ERROR <<<');
    debugPrint('Exception: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
  };

  // Load .env (OpenAI key etc.)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found or invalid');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Catch async errors too
  runZonedGuarded(() {
    runApp(const EyerisApp());
  }, (error, stack) {
    debugPrint('>>> ZONE ERROR <<<');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
  });
}
