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
  /// Recognizes text from InputImage (from file path)
  /// Returns extracted text string or empty string if no text found
  static Future<String> recognizeTextFromInputImage(InputImage inputImage) async {
    developer.log('ML Kit: Creating recognizer...');
    final recognizer = GoogleMlKit.vision.textRecognizer();
    developer.log('ML Kit: Recognizer created');
    
    try {
      developer.log('ML Kit: InputImage metadata: ${inputImage.metadata}');
      developer.log('ML Kit: Processing image...');
      
      // Process image with text recognizer
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);
      developer.log('ML Kit: Processing completed');
      
      final result = recognizedText.text.trim();
      developer.log('ML Kit: Raw recognition result length: ${result.length}');
      developer.log('ML Kit: First 200 chars: "${result.length > 200 ? result.substring(0, 200) : result}"');
      developer.log('ML Kit: Number of blocks: ${recognizedText.blocks.length}');
      
      // Return the recognized text
      return result;
    } catch (e, stackTrace) {
      developer.log('=== ML KIT RECOGNITION ERROR ===');
      developer.log('ML Kit recognition error: $e');
      developer.log('ML Kit error type: ${e.runtimeType}');
      developer.log('ML Kit stack trace: $stackTrace');
      return '';
    } finally {
      // Always close recognizer
      try {
        await recognizer.close();
        developer.log('ML Kit: Recognizer closed successfully');
      } catch (e) {
        developer.log('ML Kit: Error closing recognizer: $e');
      }
    }
  }

  /// Recognizes text from camera image
  /// Returns extracted text string or empty string if no text found
  static Future<String> recognizeText(CameraImage cameraImage) async {
    final recognizer = GoogleMlKit.vision.textRecognizer();
    
    try {
      // Convert CameraImage to InputImage for ML Kit
      final InputImage inputImage = await _inputImageFromCameraImage(cameraImage);
      
      // Process image with text recognizer
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);
      
      // Return the recognized text
      return recognizedText.text.trim();
    } catch (e, stackTrace) {
      developer.log('Text recognition error: $e');
      developer.log('Stack trace: $stackTrace');
      return '';
    } finally {
      // Always close recognizer
      try {
        await recognizer.close();
      } catch (e) {
        developer.log('Error closing recognizer: $e');
      }
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
    // No static recognizer to dispose - we create fresh ones per scan
    developer.log('TextRecognitionService: dispose called (no static recognizer to clean up)');
  }
}
