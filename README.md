# Gap Ear Frontend

> **Assistive pronunciation training** for people with hearing loss  
> A Flutter-based mobile UI that records your voice/video, performs speech-to-text, and displays AI-driven pronunciation advice and guidance videos.

---

## 📁 Project Structure
lib/
├── main.dart
├── splash_screen.dart # App launch animation & logo
├── menu_screen.dart # Scenario selection (Psychiatry, Medical, Pharmacy, Custom)
├── practice_screen.dart # Record 8-second audio or video session
└── result_screen.dart # Show “correct” vs “your” pronunciation, AI advice, and guide video
assets/
├── screens/ # Screenshots for README
│ ├── splash.png
│ ├── menu.png
│ ├── practice_voice.png
│ ├── practice_video.png
│ ├── result_voice.png
│ └── result_video.png
pubspec.yaml # Dependencies: flutter, camera, speech_to_text, video_player, etc.

## 🚀 Getting Started

1. **Clone & install**  
   ```bash
   git clone https://github.com/your-org/gap-ear-frontend.git
   cd gap-ear-frontend
   flutter pub get
   flutter run

## 🔧 How It Works
Splash → Menu

Logo and slogan

Choose a medical scenario or custom prompt

Practice Screen

Displays the target sentence

Toggle VOICE / VIDEO

Tap the big button → 8-second recording (audio or video)

Result Screen

Correct pronun.: shows original text

Your pronun.: STT transcript or “[See your video below]”

AI Solution: fetched from Gemini API (step-by-step tips)

AI Guide:

Voice mode: placeholder for future video

Video mode: plays user’s video + AI deepfake guide

