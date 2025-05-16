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

To get started with the application, follow the steps below:

### 🛠️ Clone & Install

Clone the repository and install the necessary dependencies.

```bash
git clone [https://github.com/SKKU-GDG/frontend.git](https://github.com/SKKU-GDG/frontend.git)
cd frontend
flutter pub get
flutter run
```

### ⚙️ Environment Configuration

**⚠️ Important:** Before running the application, you **must** configure the Gemini API key.

1.  Create a `.env` file in the root directory of the `frontend` project.
2.  Add your Gemini API key to the `.env` file with the following format:

  ```
    GEMINI_API_KEY=YOUR_API_KEY_HERE
   ```

   Replace `YOUR_API_KEY_HERE` with your **actual Gemini API key**.

### 🔗 Backend API Endpoint Configuration

To connect to the backend and utilize the speech recognition analysis, you need to update the API call URL in the `result_screen.dart` file.

1.  Navigate to the directory containing your Dart files (likely the `lib` directory) and open `result_screen.dart`.

2.  Locate the section of code where the API call to the backend is made. This will typically involve an HTTP request using a library like `http`.

3.  **Ensure you replace the placeholder URL** with the actual URL of your deployed backend. For example:

   ```dart
    // ... other code
    final uri = Uri.parse('[https://f680-203-252-33-7.ngrok-free.app/upload](https://f680-203-252-33-7.ngrok-free.app/upload)');
    final request = http.MultipartRequest('POST', uri);
    // ...
   ```

Replace `'https://f680-203-252-33-7.ngrok-free.app'` with the correct URL of your deployed backend service.

After completing these steps, you should be able to run the Flutter frontend and successfully connect to your backend for speech recognition analysis.



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

