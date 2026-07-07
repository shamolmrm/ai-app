# AI Assistant

A production-ready AI personal assistant mobile app built with Flutter and a Firebase backend — chat with an AI assistant, manage your profile, and get help on the go.

## Features

- Conversational AI chat interface
- Firebase authentication
- User profile management
- Firestore-backed data with security rules

## Tech Stack

| | |
|---|---|
| Framework | Flutter / Dart |
| Backend | Firebase (Auth, Firestore) |
| Architecture | Feature-based, repository pattern |

## Project Structure

```
lib/
├── app/            # app entry & routing
├── core/           # constants, theme, utils, shared widgets
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
└── features/
    ├── auth/
    ├── chat/
    ├── home/
    └── profile/
```

## Getting Started

```bash
flutter pub get
flutter run
```

Firebase setup is required before running — see `FIREBASE_SETUP.md` for step-by-step configuration.
