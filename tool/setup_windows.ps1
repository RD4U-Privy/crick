$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter is not available in PATH. Install Flutter stable, restart PowerShell, then run flutter doctor -v.'
}
flutter create --platforms=android,ios --org com.dysonc --project-name cricket .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
Write-Host 'Crick is ready. Run: code . then flutter run' -ForegroundColor Green
