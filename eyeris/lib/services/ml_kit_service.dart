import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies the bundled TFLite model from assets into a readable
/// file path on the device and returns that path.
Future<String> getModelPath(String asset) async {
  final supportDir = await getApplicationSupportDirectory();
  final path = p.join(supportDir.path, asset);
  await Directory(p.dirname(path)).create(recursive: true);

  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
  }
  return file.path;
}

/// Creates an [ObjectDetector] configured to use a local custom
/// TensorFlow Lite model (e.g. a COCO-style detector that can
/// label objects like "person", "chair", "door").
Future<ObjectDetector> createLocalObjectDetector() async {
  // This path must match where you place the model in your assets.
  const assetPath = 'assets/ml/object_labeler.tflite';
  final modelPath = await getModelPath(assetPath);

  final options = LocalObjectDetectorOptions(
    mode: DetectionMode.stream,
    modelPath: modelPath,
    classifyObjects: true,
    multipleObjects: true,
  );

  return ObjectDetector(options: options);
}

