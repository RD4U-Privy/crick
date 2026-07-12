$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter is not available in PATH.'
}

$devices = flutter devices
Write-Host $devices
Write-Host ''
Write-Host 'Starting Crick on the selected Flutter device...' -ForegroundColor Green
flutter run
