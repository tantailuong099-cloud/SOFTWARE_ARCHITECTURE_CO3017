
# ✨ Daily Crew 📸

### 🌈 Capture your day. Share your moments. Challenge your friends.

Daily Snap is a mobile social application focused on sharing everyday moments, creating personal vlogs, and participating in fun photo challenges with friends.

The goal is to make daily sharing simple, spontaneous, and engaging through a lightweight social experience.

> 💫 Small moments, great memories. Let's make every day worth sharing!

---

## 🌟 About the Project

Daily Snap is being developed as a Flutter mobile application for the **Mobile Application Development (CO3043)** course.

The application aims to bring friends closer through everyday photo sharing, personal vlogs, and interactive challenges.

### 🎯 Planned Core Features

- 📷 **Daily Snaps** — Capture and share moments from everyday life.
- 🎬 **Friend Vlogs** — Explore and share personal video-style updates.
- 🎯 **Snap Challenges** — Participate in fun daily or group challenges.
- 👥 **Friends & Social** — Connect with friends and discover their moments.
- 👤 **User Profiles** — Manage personal information and shared content.

*Note: These are planned product features. They are not necessarily implemented in the current codebase.*

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| 🐦 Flutter | Cross-platform mobile application framework |
| 🎯 Dart | Main programming language |
| 🔀 GoRouter | Application navigation and route management |
| 🌱 Riverpod | State management and dependency injection |
| 🌐 Dio | HTTP client for backend communication |
| 🔐 Flutter Secure Storage | Secure local storage for sensitive values, such as authentication tokens |
| 🖼️ Image Picker | Selecting images from the device |
| 🎨 Material 3 | UI components and theming |

### 🧩 Backend Integration

The planned backend stack is:

- **NestJS** — REST API and application logic
- **PostgreSQL** — Relational database
- **Sequelize** — ORM for database operations

The Flutter application communicates with the backend through HTTP APIs. The backend is maintained separately from this repository.

---

## 📂 Project Structure

The frontend follows a **feature-first architecture with layered organization**.

This approach groups code by business feature while separating UI, data access, and business logic when needed.

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
│
├── core/
│   ├── config/
│   │   └── api_config.dart
│   ├── network/
│   │   └── dio_client.dart
│   └── errors/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── feed/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── challenge/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── friends/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── screens/
│           └── widgets/
│
└── shared/
    ├── widgets/
    └── utils/
```

> 📌 The tree describes the intended organization. Some directories may still be empty, and feature implementations will be added incrementally.

### 🗺️ Directory Responsibilities

| Directory | Responsibility |
|---|---|
| `main.dart` | Application entry point; initializes the root widget and Riverpod scope. |
| `app/` | Application-wide configuration, routing, and theme. |
| `app/router/` | Defines application routes using GoRouter. |
| `app/theme/` | Defines shared visual styles and Material theme configuration. |
| `core/config/` | Shared application configuration, including the API base URL. |
| `core/network/` | Shared Dio client and common HTTP configuration. |
| `core/errors/` | Shared error types and error-handling utilities when needed. |
| `features/` | Contains individual business features. |
| `presentation/` | Screens, feature-specific widgets, UI state, and controllers/providers. |
| `data/` | API data sources, data models/DTOs, and repository implementations. |
| `domain/` | Business entities, repository contracts, and use cases when the feature needs them. |
| `shared/widgets/` | Reusable UI components used by multiple features. |
| `shared/utils/` | General-purpose utilities shared across features. |

### 🧱 How the Layers Work Together

A typical data flow looks like this:

```text
User Interaction
      ↓
Presentation (Screen / Provider)
      ↓
Data Layer (Repository / Data Source)
      ↓
Core Network (Dio Client)
      ↓
NestJS REST API
      ↓
PostgreSQL Database
```

The response then travels back to the presentation layer, where the UI updates accordingly.

**Architecture rules:**

- Keep feature-specific code inside its corresponding feature.
- Use `core/` for shared infrastructure, not feature-specific business logic.
- Use `shared/` only for components or utilities genuinely reused across features.
- Keep HTTP requests out of screen widgets.
- Introduce domain abstractions when they provide value; not every feature needs every layer from day one.

---

## 🚀 Getting Started

### 1. Prerequisites

Make sure the following tools are installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) — included with Flutter
- [Android Studio](https://developer.android.com/studio) or another supported IDE
- [Visual Studio Code](https://code.visualstudio.com/) with Flutter and Dart extensions
- An Android emulator or a physical Android device

Verify your Flutter installation:

```powershell
flutter doctor
```

### 2. Clone the Repository

```powershell
git clone https://github.com/tantailuong099-cloud/Mobile_Application_Development_CO3043.git
cd Mobile_Application_Development_CO3043
```

### 3. Install Dependencies

```powershell
flutter pub get
```

### 4. Run Static Analysis and Tests

```powershell
flutter analyze
flutter test
```

### 5. Run the Application

```powershell
flutter run
```

Make sure an emulator or a connected device is available:

```powershell
flutter devices
```

---


## 💖 Team & Contribution

Daily Crew is a collaborative student project. Contributions should follow the shared architecture, naming conventions, and Git workflow.

Before starting a feature, coordinate with the team on:

- Feature ownership
- API endpoints and JSON contracts
- Route names and navigation behavior
- State management and error handling
- Shared component requirements

Good communication and consistent conventions help the team move faster without creating unnecessary integration conflicts. 🚀

---

<p align="center">
  Made with 💜 Flutter, ☕ and a little bit of ✨ magic.
  <br />
  <b>Daily Crew — Every moment has a story. 📸</b>
</p>
