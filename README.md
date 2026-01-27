"# eyeris" 

## Iris: AI-Powered Visual Assistant 👁️

Iris is a real-time mobile assistant designed to empower the visually impaired. By combining on-device computer vision for speed and cloud-based generative AI for context, Iris provides a natural, spoken narrative of the user's environment.

## 🚀 The Vision

Traditional tools for the blind often provide disconnected labels (e.g., "chair," "person"). Iris bridges the gap between detection and understanding by narrating the "why" and "how" of a scene using a "Narrator-first" approach.

## ✨ Key Features

- Live Scene Interpretation: Uses Gemini 3 Flash to describe complex environments (e.g., "A friend is waving at you near the entrance").
- Instant Object Detection: Powered by Google ML Kit to provide lag-free obstacle warnings even without internet.
- Color Recognition: Helps users identify clothing or objects with descriptive color names.
- Voice-First UX: A gesture-based, button-free interface designed specifically for screen-reader accessibility.

## 🛠️ The Tech Stack

- Frontend: Flutter (Dart)
- Computer Vision (Local): Google ML Kit
- Deep Intelligence (Cloud): Gemini 3 Flash API
- Voice Synthesis: Google Cloud Text-to-Speech (Neural2)
- Backend & Logic: Firebase

## 📂 Project Structure (Planned)

lib/
- main.dart           # App entry point
- ui/                 # Accessible Quadrant Interface
- services/           # ML Kit & Gemini API wrappers
- models/             # Data structures for vision results
- utils/              # Color mapping and audio constants

## 🚦 Getting Started

1. Prerequisites:

- Flutter SDK (3.x or higher)
- A Gemini API Key from Google AI Studio

2. Installation:

- git clone https://github.com/[Your-Username]/iris-ai-assistant.git
- cd iris-ai-assistant
- flutter pub get

3. Running the App:

- flutter run

## 🛡️ License

This project is licensed under the MIT License - see the LICENSE file for details.