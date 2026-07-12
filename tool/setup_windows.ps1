$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter is not available in PATH. Install Flutter stable, restart PowerShell, then run flutter doctor -v.'
}

Write-Host 'Checking Flutter toolchain...' -ForegroundColor Cyan
flutter doctor -v

Write-Host 'Generating Android and iOS platform projects...' -ForegroundColor Cyan
flutter create --platforms=android,ios --org com.dysonc --project-name cricket .

# Normalize two num-returning clamp expressions for strict Dart SDKs.
$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
$source = Get-Content $mainPath -Raw
$source = $source.Replace(
  "final int reward = 50 + (streak - 1).clamp(0, 6) * 10;",
  "final int reward = 50 + (streak - 1).clamp(0, 6).toInt() * 10;"
)
$source = $source.Replace(
  "double get progress => (elapsed / duration).clamp(0, 1);",
  "double get progress => (elapsed / duration).clamp(0.0, 1.0).toDouble();"
)
Set-Content -Path $mainPath -Value $source -NoNewline

Write-Host 'Installing packages...' -ForegroundColor Cyan
flutter pub get

Write-Host 'Formatting and analyzing...' -ForegroundColor Cyan
dart format lib test
dart format --output=none --set-exit-if-changed lib test
flutter analyze

Write-Host 'Running automated tests...' -ForegroundColor Cyan
flutter test

Write-Host 'Building Android debug APK...' -ForegroundColor Cyan
flutter build apk --debug

$apk = Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path $apk)) {
  throw 'Android build finished without producing app-debug.apk.'
}

Write-Host ''
Write-Host "Crick validated. APK: $apk" -ForegroundColor Green
Write-Host 'Open VS Code with: code .' -ForegroundColor Green
Write-Host 'Run on a device with: flutter run' -ForegroundColor Green
