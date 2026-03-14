// lib/services/vision/text_recognition_service.dart
//
// Text recognition service using Google ML Kit for OCR
// Handles camera image processing and text extraction
// Used by Read screen for "Point and Read" functionality

import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class TextRecognitionService {
  static final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  /// Recognizes text from InputImage (from file path)
  /// Returns extracted text string or empty string if no text found
  static Future<String> recognizeTextFromInputImage(InputImage inputImage) async {
    try {
      // Process image with text recognizer
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final result = recognizedText.text.trim();
      developer.log('Text recognition completed. Found: "$result"');
      developer.log('Text length: ${result.length} characters');
      developer.log('Number of blocks: ${recognizedText.blocks.length}');
      
      // Return the recognized text
      return result;
    } catch (e) {
      developer.log('Text recognition error: $e');
      return '';
    }
  }

  /// Recognizes text from camera image
  /// Returns extracted text string or empty string if no text found
  static Future<String> recognizeText(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to InputImage for ML Kit
      final InputImage inputImage = await _inputImageFromCameraImage(cameraImage);
      
      // Process image with text recognizer
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Return the recognized text
      return recognizedText.text.trim();
    } catch (e) {
      developer.log('Text recognition error: $e');
      return '';
    }
  }

  /// Converts CameraImage to InputImage for ML Kit processing
  static Future<InputImage> _inputImageFromCameraImage(CameraImage cameraImage) async {
    final plane = cameraImage.planes.first;
    
    // Build the input image
    InputImageFormat format = InputImageFormat.yuv420;
    switch (cameraImage.format.group) {
      case ImageFormatGroup.yuv420:
        format = InputImageFormat.yuv420;
        break;
      case ImageFormatGroup.bgra8888:
        format = InputImageFormat.bgra8888;
        break;
      default:
        format = InputImageFormat.nv21;
    }
    
    // Create InputImage metadata
    final metadata = InputImageMetadata(
      size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );
    
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: metadata,
    );
  }

  /// Closes the text recognizer to free resources
  static void dispose() {
    _textRecognizer.close();
  }
}
