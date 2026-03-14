import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyeris/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — accessibility layouts are
  // designed for vertical phone orientation only.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive: hide system nav bar overlay
  // tint so the black MicBar bleeds to the edge cleanly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const EyerisApp());
}
