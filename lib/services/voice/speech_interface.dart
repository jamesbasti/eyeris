/// Abstract interface for speech recognition
/// Allows platform-specific implementations (Android: speech_to_text, iOS: vosk_flutter)
abstract class ISpeechRecognition {
  /// Initialize speech recognition
  Future<bool> initialize();
  
  /// Start listening for speech
  Future<void> startListening();
  
  /// Stop listening
  Future<void> stopListening();
  
  /// Cancel listening
  Future<void> cancelListening();
  
  /// Stream of recognition results
  Stream<String> get onResult;
  
  /// Stream of errors
  Stream<String> get onError;
  
  /// Stream of listening state changes
  Stream<bool> get onListeningChanged;
  
  /// Check if speech recognition is available
  bool get isAvailable;
  
  /// Dispose resources
  void dispose();
}
