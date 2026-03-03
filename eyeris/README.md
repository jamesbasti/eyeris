Eyeris: AI-Powered Visual Assistant
===================================

Eyeris is a real-time mobile assistant designed to empower the visually impaired.  
By combining on-device computer vision for speed and cloud-based generative AI for context,  
Eyeris provides a natural, spoken narrative of the user's environment.

### Vision

Traditional tools for blind and low-vision users often provide disconnected labels  
(e.g., "chair", "person"). Eyeris bridges the gap between detection and understanding by:

- **Narrator-first design**: Prioritizing a smooth, conversational audio experience.
- **Context-aware explanations**: Going beyond "what" to briefly explain the "why" and "how".
- **Navigation awareness**: Focusing on what matters most for safety and orientation.

### Key Features (Design Goals)

- **Live Scene Interpretation**  
  Uses a cloud LLM (target: Gemini Flash) to describe complex environments  
  (e.g., "A friend is waving at you near the entrance.").

- **Instant Object Detection (On-device)**  
  Powered by **Google ML Kit Object Detection** to provide low-latency, offline-capable  
  understanding of visible objects in the camera feed.

- **Color Recognition**  
  Helps users identify clothing or objects with descriptive color naming (planned).

- **Voice-First UX**  
  A gesture-based, screen-reader-friendly interface designed so the user can stay hands-free.

### Tech Stack

- **Frontend**: Flutter (Dart)
- **Camera**: `camera` plugin
- **Computer Vision (Local)**: `google_mlkit_object_detection`
- **Deep Intelligence (Cloud)**: HTTP-based LLM API (currently OpenAI; targeting Gemini Flash)
- **Config & Secrets**: `flutter_dotenv` with a local `.env` file
- **Permissions & UX**: `permission_handler`, `google_fonts`

### Project Structure

```text
lib/
  main.dart               # App entry point
  ui/
    splash_screen.dart    # Branded splash screen → routes to home
    home_screen.dart      # Launchpad, opens the camera experience
    camera_screen.dart    # Live camera preview + ML Kit object stream + AI narration text
  services/
    openai_service.dart   # HTTP client for AI narration (Prompt A logic)
  models/
    vision_result.dart    # Data structures for future vision features
```

### Current Status (as of this commit)

- **Camera**:  
  - Back camera opens successfully.  
  - Continuous frame stream is wired into Google ML Kit object detection.

- **Object Detection (Google ML Kit)**:  
  - Streaming detector is configured with `DetectionMode.stream`.  
  - Detected objects are converted into a list of labels and stored in state.

- **AI Narration (Prompt A)**:  
  - A cloud AI service (`OpenAIService`) receives the latest labels and generates a short  
    spoken-style description of the scene using rules similar to *Prompt A*  
    (calm, clear, concise, navigation-aware).
  - Narration is currently triggered from the Camera UI (scan button) instead of every frame  
    to avoid excessive network calls.

- **UI**:  
  - Camera preview fills the screen.  
  - A bottom card shows the latest narration text without blocking the camera view.

### How to Run

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Create a `.env` file** in the project root (next to `pubspec.yaml`) with your API key:

   ```bash
   echo "OPENAI_API_KEY=your_api_key_here" > .env
   ```

3. **Run on device or emulator**

   ```bash
   flutter run
   ```

> Note: The project is structured so that swapping OpenAI for Gemini Flash is mostly a matter  
> of updating `openai_service.dart` and the environment variables. The rest of the app already  
> flows through a single narration service abstraction.

### Next Steps / Roadmap

- Add a dedicated **Navigation Mode** using a stricter, obstacle-focused prompt (Prompt B).
- Integrate **text-to-speech** so narrated descriptions are spoken automatically.
- Improve **gesture controls** and haptics for a truly hands-free experience.
- Extend **color recognition** and clothing assistance workflows.

