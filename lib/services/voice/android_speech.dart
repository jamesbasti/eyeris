import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'speech_interface.dart';

/// Android speech recognition using speech_to_text package
class AndroidSpeechRecognition implements ISpeechRecognition {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  
  final StreamController<String> _resultController = StreamController<String>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();

  @override
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: true,
      );
      
      return _isAvailable;
    } catch (e) {
      _errorController.add('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  void _onStatus(String status) {
    switch (status) {
      case 'listening':
        _isListening = true;
        _listeningController.add(true);
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        _listeningController.add(false);
        break;
    }
  }

  void _onError(SpeechRecognitionError error) {
    _errorController.add(error.errorMsg);
  }

  @override
  Future<void> startListening() async {
    if (!_isAvailable) {
      _errorController.add('Speech recognition not available');
      return;
    }
    
    if (_isListening) {
      return;
    }
    
    try {
      await _speech.listen(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _resultController.add(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      _errorController.add('Failed to start listening: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        _errorController.add('Failed to stop listening: $e');
      }
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_isListening) {
      try {
        await _speech.cancel();
      } catch (e) {
        _errorController.add('Failed to cancel listening: $e');
      }
    }
  }

  @override
  Stream<String> get onResult => _resultController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
  Stream<bool> get onListeningChanged => _listeningController.stream;

  @override
  bool get isAvailable => _isAvailable;

  @override
  void dispose() {
    _resultController.close();
    _errorController.close();
    _listeningController.close();
    _speech.cancel();
  }
}
