# Eyeris Function Flows

This document describes in detail how each major function in Eyeris flows from user input to output.

---

## Table of Contents

1. [Voice Control (Speak to Control)](#1-voice-control-speak-to-control)
2. [Color Detection](#2-color-detection)
3. [Scene Description](#3-scene-description)
4. [Text-to-Speech (TTS)](#4-text-to-speech-tts)

---

## 1. Voice Control (Speak to Control)

### Overview
Allows users to control the app using voice commands. Uses a hybrid approach: AI-powered intent recognition when online, keyword-based matching when offline.

### Flow Diagram
```
User Press & Hold Mic Button
         │
         ▼
┌─────────────────────────┐
│  VoiceControlManager    │
│  startListening()       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  SpeechRecognitionService│
│  startListening()        │
│  (speech_to_text plugin) │
└───────────┬─────────────┘
            │
            ▼
    User Speaks Command
    (e.g., "what color is this")
            │
            ▼
┌─────────────────────────┐
│  SpeechRecognitionService│
│  onResult callback       │
│  Returns: SpeechResult   │
└───────────┬─────────────┘
            │
            ▼
User Releases Mic Button
         │
         ▼
┌─────────────────────────┐
│  VoiceControlManager    │
│  stopListening()        │
│  _processTranscript()   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│     IntentRouter        │
│     parseIntent()       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────┐
│  Step 1: Try Keyword Match (Instant)        │
│  KeywordIntentService.parseIntent()         │
│  - Removes filler words                     │
│  - Matches against keyword patterns         │
│  - Returns if confidence ≥ 0.65             │
└───────────┬─────────────────────────────────┘
            │
            ▼ (if no confident match)
┌─────────────────────────────────────────────┐
│  Step 2: Check Connectivity (Cached 10s)    │
│  _checkConnectivity()                       │
└───────────┬─────────────────────────────────┘
            │
    ┌───────┴───────┐
    │               │
    ▼               ▼
 ONLINE          OFFLINE
    │               │
    ▼               ▼
┌──────────────┐  ┌──────────────────┐
│ AIIntentService│  │ Return keyword   │
│ parseIntent()  │  │ match result     │
│ (OpenAI API)   │  └──────────────────┘
│ 2s timeout     │
└───────┬────────┘
        │
        ▼
┌─────────────────────────┐
│  VoiceCommand returned  │
│  - intent (navigation/  │
│    action/setting)      │
│  - target               │
│  - confidence           │
│  - response text        │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  VoiceControlManager    │
│  _executeCommand()      │
│  - Triggers callback    │
│  - onNavigate/onAction/ │
│    onSetting            │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  AudioFeedbackService   │
│  speak(response)        │
│  (Confirmation TTS)     │
└─────────────────────────┘
```

### Key Files
| File | Purpose |
|------|---------|
| [`voice_control_manager.dart`](../lib/services/voice/voice_control_manager.dart) | Orchestrates the entire voice control flow |
| [`speech_recognition_service.dart`](../lib/services/voice/speech_recognition_service.dart) | Handles microphone input and speech-to-text |
| [`intent_router.dart`](../lib/services/voice/intent_router.dart) | Routes to AI or keyword service based on connectivity |
| [`ai_intent_service.dart`](../lib/services/voice/ai_intent_service.dart) | OpenAI-powered natural language understanding |
| [`keyword_intent_service.dart`](../lib/services/voice/keyword_intent_service.dart) | Offline keyword pattern matching |
| [`audio_feedback_service.dart`](../lib/services/voice/audio_feedback_service.dart) | TTS feedback and sound effects |
| [`voice_command.dart`](../lib/models/voice_command.dart) | Data model for parsed commands |

### Keyword Patterns
```dart
// Navigation
'read': ['read', 'scan', 'document', 'text', ...]
'colorDetect': ['what color is this', 'what color', 'color', ...]
'sceneDescribe': ['describe', 'scene', 'what is this', ...]
'communicate': ['call', 'message', 'emergency', 'help', 'sos']
'back': ['back', 'go back', 'previous', 'return']
'home': ['home', 'main', 'menu', 'go home']

// Settings
'torch': ['torch on', 'light on', 'too dark', 'torch off', ...]
'speechRate': ['faster', 'slower', 'speed up', 'slow down']
```

### Performance Optimizations
- **Keyword-first**: Instant response for confident matches (≥65% confidence)
- **AI timeout**: 2 seconds max wait for OpenAI response
- **Connectivity cache**: 10-second cache to avoid repeated network checks
- **Non-blocking audio**: Actions execute before TTS confirmation

---

## 2. Color Detection

### Overview
Detects and identifies colors from the camera feed. Uses multi-region sampling for accurate color detection with AI-enhanced descriptions.

### Flow Diagram
```
User Opens Color Detect Screen
            │
            ▼
┌─────────────────────────┐
│  ColorDetectCameraScreen│
│  initState()            │
│  - _initTts()           │
│  - _initCamera()        │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Camera Permission      │
│  Request                │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  CameraController       │
│  startImageStream()     │
│  (Continuous frames)    │
└───────────┬─────────────┘
            │
            ▼
    User Taps "DETECT"
            │
            ▼
┌─────────────────────────┐
│  _detectColor()         │
│  Uses latest CameraImage│
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────┐
│  ColorService.analyseMultiColor()           │
│                                             │
│  Step 1: Sample 9 regions (3x3 grid)        │
│  ┌─────┬─────┬─────┐                        │
│  │ TL  │ TOP │ TR  │                        │
│  ├─────┼─────┼─────┤                        │
│  │LEFT │ CTR │RIGHT│                        │
│  ├─────┼─────┼─────┤                        │
│  │ BL  │ BOT │ BR  │                        │
│  └─────┴─────┴─────┘                        │
│                                             │
│  Step 2: For each region:                   │
│  - _sampleRegion() → Color (RGB)            │
│  - Handle YUV420 (Android) or BGRA (iOS)    │
│                                             │
│  Step 3: _nearestNamed() for each color     │
│  - Convert RGB → LAB color space            │
│  - Calculate CIE76 distance to 150+ palette │
│  - Return closest named color               │
│                                             │
│  Step 4: Group similar colors               │
│  - Count occurrences per color name         │
│  - Calculate percentages                    │
│                                             │
│  Step 5: Return MultiColorResult            │
│  - dominant: DetectedColor                  │
│  - secondary: List<DetectedColor>           │
│  - all: List<DetectedColor>                 │
└───────────┬─────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────┐
│  OpenAIService.describeColors()             │
│                                             │
│  Input:                                     │
│  - dominantColor: "Navy Blue"               │
│  - dominantHex: "#000080"                   │
│  - dominantPercentage: 60%                  │
│  - secondaryColors: [("White", "#FFF", 30%)]│
│                                             │
│  Output (AI-generated):                     │
│  "Deep navy blue like a midnight sky,       │
│   with crisp white accents"                 │
└───────────┬─────────────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  FlutterTts.speak()     │
│  Speaks description     │
│  aloud to user          │
└─────────────────────────┘
```

### Key Files
| File | Purpose |
|------|---------|
| [`color_detect_camera_screen.dart`](../lib/ui/camera/color_detect_camera_screen.dart) | UI and camera handling |
| [`color_service.dart`](../lib/services/color_service.dart) | Color sampling and matching |
| [`openai_service.dart`](../lib/services/openai_service.dart) | AI-enhanced color descriptions |

### Color Matching Algorithm
```
1. Sample pixels from camera image
2. Convert to RGB values
3. Transform RGB → LAB color space (perceptually uniform)
4. Calculate CIE76 distance to each palette color
5. Return closest match with confidence score
```

### Color Palette
- 150+ named colors organized by category:
  - Whites & Greys (neutral)
  - Reds, Pinks, Oranges (warm)
  - Yellows, Browns (warm)
  - Greens, Teals, Cyans (cool)
  - Blues, Purples (cool)
  - Metallics, Skin Tones (neutral)

---

## 3. Scene Description

### Overview
Describes the scene in front of the camera using a hybrid approach: OpenAI Vision API when online, TFLite object detection when offline.

### Flow Diagram
```
User Opens Scene Describe Screen
            │
            ▼
┌─────────────────────────────────────────────┐
│  SceneDescribeCameraScreen.initState()      │
│  - _loadModel() (TFLite for offline)        │
│  - _initTts()                               │
│  - _initCamera()                            │
│  - _initVoiceControl()                      │
└───────────┬─────────────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  TFLite Model Loading   │
│  object_labeler.tflite  │
│  (COCO 90 classes)      │
└───────────┬─────────────┘
            │
            ▼
    User Taps "DESCRIBE"
    (or says "describe scene")
            │
            ▼
┌─────────────────────────┐
│  _runSceneNarration()   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Check Connectivity     │
└───────────┬─────────────┘
            │
    ┌───────┴───────┐
    │               │
    ▼               ▼
 ONLINE          OFFLINE
    │               │
    ▼               ▼
┌──────────────┐  ┌──────────────────────────┐
│ _captureImage()│  │ _detectOnce()            │
│ Take photo     │  │ TFLite object detection  │
└───────┬────────┘  └───────────┬──────────────┘
        │                       │
        ▼                       ▼
┌───────────────────┐  ┌──────────────────────────┐
│ OpenAIService     │  │ _convertCameraImage      │
│ .analyzeImage()   │  │ ToInputTensor()          │
│                   │  │ - YUV420 → RGB           │
│ GPT-4o Vision API │  │ - Resize to 300x300      │
│ - Base64 image    │  │ - Normalize pixels       │
│ - Context prompt  │  └───────────┬──────────────┘
└───────┬───────────┘              │
        │                          ▼
        │              ┌──────────────────────────┐
        │              │ TFLite Interpreter       │
        │              │ .run()                   │
        │              │ - Boxes, Classes, Scores │
        │              └───────────┬──────────────┘
        │                          │
        │                          ▼
        │              ┌──────────────────────────┐
        │              │ _parseOutput()           │
        │              │ - Filter by confidence   │
        │              │ - _prioritizeDetections()│
        │              │ - Return top 5 labels    │
        │              └───────────┬──────────────┘
        │                          │
        │                          ▼
        │              ┌──────────────────────────┐
        │              │ OpenAIService            │
        │              │ .generateAIText(labels)  │
        │              │ (Text-based description) │
        │              └───────────┬──────────────┘
        │                          │
        └──────────┬───────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Scene Description Generated                │
│                                             │
│  Example outputs:                           │
│  - "You're in a kitchen with a counter      │
│     and appliances to your right"           │
│  - "A street scene with buildings and       │
│     a sidewalk in front of you"             │
└───────────┬─────────────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  FlutterTts.speak()     │
│  Speaks description     │
│  aloud to user          │
└─────────────────────────┘
```

### Key Files
| File | Purpose |
|------|---------|
| [`scene_describe_camera_screen.dart`](../lib/ui/camera/scene_describe_camera_screen.dart) | UI, camera, and TFLite integration |
| [`openai_service.dart`](../lib/services/openai_service.dart) | Vision API and text generation |
| [`object_labeler.tflite`](../assets/ml/object_labeler.tflite) | SSD MobileNet model for offline detection |

### TFLite Object Detection
```
Input: 300x300 RGB image tensor
Model: SSD MobileNet (COCO dataset)
Output:
  - Bounding boxes [N, 4]
  - Class IDs [N]
  - Confidence scores [N]
  - Number of detections

Post-processing:
  - Filter by confidence > 0.15
  - Filter by area > 0.3% of image
  - Prioritize by importance weights
  - Return top 5 detections
```

### Object Priority Weights
```dart
'person': 2.0      // Highest priority
'car': 1.8
'bus': 1.7
'traffic light': 1.3
'stop sign': 1.3
'chair': 1.1
'tv': 0.9
'book': 0.7
// ... etc
```

---

## 4. Text-to-Speech (TTS)

### Overview
Converts text to spoken audio for accessibility. Uses platform-native TTS engines with customizable voice and speed.

### Flow Diagram
```
Text to Speak
      │
      ▼
┌─────────────────────────┐
│  FlutterTts / VoiceService│
│  speak(text)             │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────────────────────────┐
│  Platform-Specific Engine                   │
│                                             │
│  iOS:                                       │
│  - AVSpeechSynthesizer                      │
│  - Voice: "Evan (Enhanced)" en-US           │
│                                             │
│  Android:                                   │
│  - Google TTS Engine                        │
│  - Voice: Default en-US                     │
└───────────┬─────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────┐
│  Speech Rate (from UserPreferences)         │
│                                             │
│  'slow':   0.3                              │
│  'normal': 0.5                              │
│  'fast':   0.7                              │
│                                             │
│  Adjustable via voice command:              │
│  "speak faster" / "speak slower"            │
└───────────┬─────────────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│  Audio Output           │
│  (Device Speaker)       │
└─────────────────────────┘
```

### Key Files
| File | Purpose |
|------|---------|
| [`voice_service.dart`](../lib/services/voice_service.dart) | TTS wrapper with profile-based settings |
| [`audio_feedback_service.dart`](../lib/services/voice/audio_feedback_service.dart) | TTS + sound feedback for voice control |
| [`user_preferences.dart`](../lib/models/user_preferences.dart) | Stores voice speed preference |

---

## Summary

| Function | Input | Processing | Output |
|----------|-------|------------|--------|
| **Voice Control** | Spoken command | Speech-to-text → Intent parsing (AI/Keywords) | Navigation/Action/Setting |
| **Color Detection** | Camera frame | Multi-region sampling → LAB color matching → AI description | Spoken color name + description |
| **Scene Description** | Camera frame | Vision API (online) or TFLite detection (offline) → AI text | Spoken scene description |
| **TTS** | Text string | Platform TTS engine | Audio output |

---

## Architecture Principles

1. **Hybrid Online/Offline**: All major features work offline with graceful degradation
2. **Accessibility-First**: All outputs are spoken aloud via TTS
3. **Low Latency**: Keyword matching provides instant responses; AI has timeouts
4. **Perceptual Accuracy**: Color matching uses LAB color space for human-like perception
5. **Context Awareness**: Time of day, torch state, and user preferences influence outputs
