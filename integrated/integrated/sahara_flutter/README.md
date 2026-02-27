# Sahara Flutter Frontend

A complete Flutter frontend for the Sahara grief companion app.

## Project Structure

```
lib/
├── main.dart                        ← App entry point + navigation shell
├── theme/
│   └── sahara_theme.dart            ← Warm sand/ember colour palette, fonts
├── models/
│   └── models.dart                  ← ChatMessage, Memory, JournalEntry, UserProfile, enums
├── services/
│   ├── app_state.dart               ← Global ChangeNotifier state provider
│   ├── api_service.dart             ← HTTP calls to Flask backend (/generate, /voice_query, /health)
│   └── biometric_service.dart       ← Face ID / fingerprint auth singleton
├── screens/
│   ├── onboarding_screen.dart       ← 4-step onboarding (welcome, profile, language, import)
│   ├── home_screen.dart             ← Mood check-in, breathing card, memory strip, streak
│   ├── chat_screen.dart             ← AI chat with memory cards, voice input, crisis SOS
│   ├── journal_screen.dart          ← 7-day mood chart + scrollable journal entries
│   ├── settings_screen.dart         ← Dark mode, biometrics, notifications, privacy, crisis resources
│   └── lock_screen.dart             ← Biometric lock screen with orb animation
└── widgets/
    ├── widgets.dart                 ← CrisisBanner, MemoryCard, MoodChip, BreathingCard, etc.
    └── auth_gate.dart               ← App lifecycle wrapper for auto-lock
```

## Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Start the backend** (Python Flask server from your project):
   ```bash
   python app.py  # should run on localhost:5000
   ```
   The app uses demo responses automatically if the backend is offline.

3. **Android permissions** — add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   ```

4. **iOS permissions** — add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Sahara uses Face ID to protect your private memories.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Sahara uses the microphone for voice queries.</string>
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## Key Features Implemented

| Feature | Screen | Notes |
|---|---|---|
| 4-step onboarding | `onboarding_screen.dart` | Welcome, profile, language, WhatsApp import |
| Mood check-in | `home_screen.dart` | 6-mood chips, logged to journal |
| Breathing exercise | `home_screen.dart` | Animated orb, inhale/exhale |
| Memory of the day | `home_screen.dart` | Shows after import |
| AI chat | `chat_screen.dart` | Calls `/generate`, demo fallback offline |
| Memory cards in chat | `chat_screen.dart` | Inline retrieved memories |
| Voice input | `chat_screen.dart` | Hold mic, calls `/voice_query` |
| Crisis SOS button | `chat_screen.dart` | Always visible, shows helplines |
| 7-day mood chart | `journal_screen.dart` | fl_chart line chart |
| Journal entries | `journal_screen.dart` | Log with notes, emoji, tags |
| Dark mode | `settings_screen.dart` | Full palette swap |
| Language toggle | `home_screen.dart` | EN / HI / MR / Hinglish |
| Face lock | `lock_screen.dart` + `auth_gate.dart` | 5-min auto-relock |
| Safety disclaimers | Every AI message | iCall + Vandrevala numbers |

## Backend API Contract

```
POST /generate
  Body: { "query": string }
  Response: { "response": string, "retrieved_count": int, "memories_sample": Memory[] }

POST /voice_query
  Body: multipart/form-data with "audio" WAV file
  Response: { "transcription": string, "response": string, "is_distressed": bool, "is_crisis": bool, ... }

GET /health
  Response: { "llm_loaded": bool }
```

## Crisis Resources (Always Present)

- **iCall:** 9152987821
- **Vandrevala Foundation:** 1860-2662-345

These are embedded in every AI response disclaimer, the crisis sheet, and the Settings screen.
