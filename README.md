# Crick

Playable offline-first Flutter + Flame cricket game for Android and iOS. App ID: `com.dysonc.cricket`.

The repository currently delivers a complete offline MVP: 12-ball timing gameplay, scoring, combos, statistics, coins, daily rewards, cosmetic unlocks, settings, and automatic local saves. Firebase, online leaderboards, production audio/art atlases, and store signing remain integration work and are not falsely presented as finished.

## Validate on Windows

Install Flutter stable and Android Studio first, then open PowerShell:

```powershell
git clone https://github.com/RD4U-Privy/crick.git
cd crick
Set-ExecutionPolicy -Scope Process Bypass
.\tool\setup_windows.ps1
```

The command generates Android/iOS native projects, installs packages, formats code, runs static analysis and tests, and builds `build\app\outputs\flutter-apk\app-debug.apk`. It stops immediately if any check fails.

## Run from VS Code

Start an Android emulator or connect a phone with USB debugging, then:

```powershell
flutter devices
code .
flutter run
```

You can also press F5 in VS Code after selecting a device in the status bar.

## Run a specific device

```powershell
flutter devices
flutter run -d <device-id>
```

## Test only

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Build Android

```powershell
flutter build apk --debug
```

## iOS

Clone the repo on macOS with Xcode, run the setup steps, then:

```sh
flutter build ios --debug --no-codesign
flutter run -d <ios-device-id>
```

A physical iPhone requires an Apple development team and signing profile. Windows cannot compile iOS.

GitHub Actions runs the same analysis, tests, and Android build on every push and uploads a debug APK when green.
