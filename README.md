# NIGHTMARE RUN — Klencod IDE starter project

This is a Flutter endless-runner prototype with a horror atmosphere and perspective-style 3D presentation drawn with Flutter Canvas. It is **not a full 3D engine game** and does not include external 3D character models or recorded sound assets yet.

## Build in Klencod IDE

1. Create a new Flutter project in Klencod IDE named `nightmare_run`.
2. Replace the project's `pubspec.yaml` with the one in this ZIP.
3. Replace `lib/main.dart` with the `lib/main.dart` from this ZIP.
4. Run `flutter pub get` if the IDE provides a terminal/dependency action.
5. Run the project in preview/device mode.
6. Build the APK using Klencod IDE's APK/GitHub Actions build option.

If your Klencod version imports ZIP projects, you can try importing this ZIP. Otherwise, create the Flutter project first and copy these files into it.

## Controls
- Swipe left/right: change lanes
- Swipe up: jump
- Swipe down: slide
- On-screen arrows also work

## Included
- Main menu and game-over screen
- Three-lane perspective road
- Increasing speed, score, coins
- Obstacles and collision logic
- Jump/slide actions and touch controls
- No external package dependencies beyond Flutter

## Important
I have not run a Flutter/Android build in your Klencod environment, so this source package cannot be represented as already compiled or tested. A successful APK build depends on the Flutter SDK and Android build setup available to Klencod IDE.
