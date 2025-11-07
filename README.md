# brightness

A Flutter application for controlling monitor brightness on Linux systems using ddcutil. Provides a graphical interface to adjust brightness levels for multiple connected displays.

## Table of contents
- [About](#about)
- [Language composition](#language-composition)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Build & Run](#build--run)
- [Usage](#usage)
- [Contributing](#contributing)
- [Support / Contact](#support--contact)
- [License](#license)

## About
This repository contains a Flutter-based monitor brightness controller for Linux systems. The application uses ddcutil to communicate with monitors via DDC/CI protocol, allowing users to adjust brightness levels through an intuitive graphical interface. The app automatically detects connected displays and provides individual brightness controls for each monitor.

## Language composition
This is primarily a Flutter/Dart project with platform-specific code for multiple operating systems:
- Dart: Core application logic and UI
- C++: Platform-specific integrations (Linux, Windows)
- CMake: Build configuration for native components
- Swift: iOS platform support
- HTML: Web platform support

## Project structure
- `/lib` — Dart application code and main UI
- `/android` — Android platform-specific code
- `/ios` — iOS platform-specific code (Swift)
- `/linux` — Linux platform-specific code
- `/macos` — macOS platform-specific code
- `/windows` — Windows platform-specific code
- `/web` — Web platform support
- `/test` — Flutter widget tests
- `pubspec.yaml` — Flutter project configuration and dependencies

## Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK (included with Flutter)
- For Linux: `ddcutil` package installed (`sudo apt install ddcutil` on Ubuntu/Debian)
- Platform-specific tools:
  - Android: Android Studio and Android SDK
  - iOS/macOS: Xcode (macOS only)
  - Linux: Standard Linux development tools
  - Windows: Visual Studio with C++ support

## Build & Run

### Flutter Application
1. Install dependencies:
```bash
flutter pub get
```

2. Run on connected device or emulator:
```bash
flutter run
```

3. Build for specific platforms:
```bash
# Linux
flutter build linux

# Android
flutter build apk

# iOS (macOS only)
flutter build ios

# Web
flutter build web
```

### Linux Requirements
For the brightness control to work on Linux, ensure `ddcutil` is installed and you have proper permissions:
```bash
# Install ddcutil
sudo apt install ddcutil

# Add user to i2c group for device access
sudo usermod -aG i2c $USER
# Log out and back in for changes to take effect
```

## Usage
Once the application is running:
1. The app will automatically detect connected monitors using ddcutil
2. Each detected display will be shown with its own brightness slider
3. Adjust the sliders to change brightness levels (0-100%)
4. Use the refresh button in the app bar to re-detect displays

**Note:** This application is primarily designed for Linux systems with DDC/CI-compatible monitors. The ddcutil tool must be installed and properly configured for the brightness control to work.

## Contributing
Contributions are welcome. A suggested minimal contributing section:
1. Fork the repository
2. Create a new branch: `git checkout -b feature/my-feature`
3. Make changes and add tests where appropriate
4. Run existing tests and linters
5. Open a pull request describing your changes

If you have contribution guidelines, code style rules, or a CONTRIBUTING.md file, link to them here.

## Support / Contact
If you need help, open an issue or contact the maintainers.

## License
If this repository has a license, state it here (e.g., MIT, Apache-2.0). If no license is set, the default is "All rights reserved" — add a LICENSE file to make terms explicit.
