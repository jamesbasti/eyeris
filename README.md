<div align="center">

# 👁️ Eyeris

### AI-Powered Visual Assistant for the Blind & Low-Vision

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o-412991?logo=openai)](https://openai.com)
[![TensorFlow Lite](https://img.shields.io/badge/TFLite-ML-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)]()

</div>

---

## 📖 Overview

**Eyeris** is a real-time mobile assistant designed to empower blind and low-vision users. By combining on-device machine learning for speed with cloud-based AI for rich understanding, Eyeris provides natural, spoken descriptions of the user's environment.

### 🎯 Vision

Traditional accessibility tools provide disconnected labels (e.g., "chair", "person"). Eyeris bridges the gap between detection and understanding:

- **Narrator-first design** — Smooth, conversational audio experience
- **Context-aware explanations** — Beyond "what" to "why" and "how"
- **Navigation awareness** — Focus on safety and orientation
- **Hybrid online/offline** — Works without internet connection

---

## ✨ Features

| Feature | Description | Status |
|---------|-------------|--------|
| **🎤 Voice Control** | Control the app with natural voice commands | ✅ Complete |
| **🎨 Color Detection** | Identify colors with AI-enhanced descriptions | ✅ Complete |
| **🖼️ Scene Description** | Describe surroundings using Vision AI or TFLite | ✅ Complete |
| **📖 Text Reading** | OCR and document scanning | 🚧 In Progress |
| **🆘 Emergency SOS** | Quick access to emergency contacts | ✅ Complete |
| **🔦 Torch Control** | Voice-activated flashlight | ✅ Complete |

---

## 🛠️ Tech Stack

### Languages
| Language | Usage |
|----------|-------|
| **Dart** | Primary application language (Flutter) |
| **Swift** | iOS native integrations |
| **Kotlin** | Android native integrations |
| **XML** | Android layouts and configurations |

### Frameworks & Libraries

| Category | Technology | Purpose |
|----------|------------|---------|
| **Frontend** | Flutter 3.x | Cross-platform UI framework |
| **State Management** | StatefulWidget, ValueNotifier | Reactive state handling |
| **Camera** | `camera` | Live camera feed and image capture |
| **ML (On-device)** | `tflite_flutter` | TensorFlow Lite for offline object detection |
| **AI (Cloud)** | OpenAI GPT-4o, GPT-4o-mini | Vision analysis and natural language |
| **Speech-to-Text** | `speech_to_text` | Voice command recognition |
| **Text-to-Speech** | `flutter_tts` | Spoken audio output |
| **Networking** | `http` | REST API communication |
| **Connectivity** | `connectivity_plus` | Network status detection |
| **Permissions** | `permission_handler` | Camera, microphone access |
| **Storage** | `shared_preferences` | User preferences persistence |
| **Environment** | `flutter_dotenv` | Secure API key management |

### AI & ML Services

| Service | Model | Purpose |
|---------|-------|---------|
| **OpenAI Vision** | GPT-4o | Rich scene analysis from images |
| **OpenAI Chat** | GPT-4o-mini | Intent parsing, color descriptions |
| **TensorFlow Lite** | SSD MobileNet V1 | Offline object detection (90 COCO classes) |

### Color Science
- **CIE LAB Color Space** — Perceptually uniform color matching
- **CIE76 Distance** — Human-like color similarity calculation
- **150+ Named Colors** — Comprehensive palette with categories

---

## 📁 Project Structure

```
eyeris/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # Route configuration
│   ├── core/
│   │   ├── app_theme.dart        # Design system & typography
│   │   └── routes.dart           # Named routes
│   ├── models/
│   │   ├── voice_command.dart    # Voice command data model
│   │   └── user_preferences.dart # User settings model
│   ├── services/
│   │   ├── openai_service.dart   # OpenAI API integration
│   │   ├── color_service.dart    # Color detection & matching
│   │   ├── voice_service.dart    # TTS management
│   │   └── voice/
│   │       ├── voice_control_manager.dart    # Voice control orchestration
│   │       ├── speech_recognition_service.dart # Speech-to-text
│   │       ├── intent_router.dart            # AI/keyword routing
│   │       ├── ai_intent_service.dart        # OpenAI intent parsing
│   │       ├── keyword_intent_service.dart   # Offline keyword matching
│   │       └── audio_feedback_service.dart   # Audio feedback
│   ├── ui/
│   │   ├── splash_screen.dart    # Branded splash
│   │   ├── home_screen.dart      # Main dashboard
│   │   ├── onboarding/           # User onboarding flow
│   │   ├── dashboard/            # Feature screens
│   │   └── camera/
│   │       ├── color_detect_camera_screen.dart  # Color detection
│   │       └── scene_describe_camera_screen.dart # Scene description
│   └── widgets/                  # Reusable UI components
├── assets/
│   ├── ml/
│   │   └── object_labeler.tflite # TFLite model
│   └── eyeris_icon.png           # App icon
├── docs/
│   └── FUNCTION_FLOWS.md         # Detailed function documentation
└── .env                          # API keys (not in repo)
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / Xcode
- OpenAI API Key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/jamesbasti/eyeris.git
   cd eyeris
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   echo "OPENAI_API_KEY=your_api_key_here" > .env
   ```

4. **Run on device**
   ```bash
   flutter run
   ```

---

## 🎤 Voice Commands

Eyeris supports natural voice commands:

| Command | Action |
|---------|--------|
| "What color is this" | Open color detection |
| "Describe scene" | Describe surroundings |
| "Read this" | Open text reader |
| "Go back" | Navigate back |
| "Go home" | Return to home screen |
| "Torch on/off" | Toggle flashlight |
| "Speak faster/slower" | Adjust speech rate |
| "Help" / "Emergency" | Open communicate screen |

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        USER INPUT                           │
│              (Voice / Touch / Camera)                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Voice   │   │  Camera  │   │  Touch   │
    │ Control  │   │  Input   │   │  Input   │
    └────┬─────┘   └────┬─────┘   └────┬─────┘
         │              │              │
         ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ IntentRouter│  │ColorService │  │OpenAIService│         │
│  │ (AI/Keyword)│  │(LAB Matching)│ │(Vision/Chat)│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      OUTPUT                                 │
│              (TTS / UI Update / Navigation)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Screenshots

*Coming soon*

---

## 🗺️ Roadmap

- [x] Voice control with AI intent parsing
- [x] Color detection with multi-region sampling
- [x] Scene description with Vision API
- [x] Offline fallback with TFLite
- [ ] OCR text reading
- [ ] Navigation mode with obstacle detection
- [ ] Multi-language support
- [ ] Wearable device integration

---

## 📄 Documentation

- [Function Flows](docs/FUNCTION_FLOWS.md) — Detailed flow diagrams for each feature

---

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

---

## 📜 License

This project is licensed under the MIT License.

---

<div align="center">

**Built with ❤️ for accessibility**

</div>
