# Gap Ear Frontend

> **Assistive pronunciation training** for people with hearing loss  
> A Flutter‐based mobile UI that records your voice/video, performs speech‐to‐text, and displays AI-driven pronunciation advice and visual guide videos.

---

## 📂 Project Structure

<details>
<summary>Click to expand</summary>

```text
frontend/
├── lib/
│   ├── main.dart
│   ├── splash_screen.dart    # Splash animation & logo
│   ├── menu_screen.dart      # Scenario selection (Psychiatry, Medical, Pharmacy, Custom)
│   ├── practice_screen.dart  # 8-second audio/video capture
│   └── result_screen.dart    # Show “correct” vs “your” pronunciation, AI advice, guide video
├── assets/
│   └── screens/              # Screenshots for README
│       ├── splash.png
│       ├── menu.png
│       ├── practice_voice.png
│       ├── practice_video.png
│       ├── result_voice.png
│       └── result_video.png
├── pubspec.yaml              # Dependencies: flutter, camera, speech_to_text, video_player…
└── README.md 
```
</details>

## 🚀 Getting Started
Clone & install

```bash

git clone https://github.com/SKKU-GDG/frontend.git
cd frontend
flutter pub get
flutter run
```

## 🔍 How It Works
Splash → Menu
App launch animation, then select a medical scenario or custom prompt.

Practice Screen

Displays the target sentence (original text)

Toggle VOICE / VIDEO mode

Tap the big button to record 8 seconds of audio or video

Result Screen

Correct pronun. shows the original text

Your pronun. shows STT transcript or “[See your video below]”

AI Solution

Fetched from Gemini API (step-by-step tips)

Displays in a bordered text box

AI Pronunciation Guide

Placeholder spinner in voice mode

Deepfake video in video mode

## ✨ Features
Scenario Selection
Psychiatry, Medical Treatment, Pharmacy, or Custom input.

8-Second Recording
One-tap automatic start/stop for audio or video.

Real-Time STT
Displays recognized English text as “Your Pronun”.

AI Pronunciation Advice
Calls Gemini API to generate personalized, step-by-step improvement tips.

Visual Guide
AI-generated deepfake video showing correct mouth movements.

