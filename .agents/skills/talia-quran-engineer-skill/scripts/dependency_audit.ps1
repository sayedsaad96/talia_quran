$ErrorActionPreference = "Continue"
Write-Host "Talia dependency audit (non-destructive)"
Write-Host "===== Flutter / Dart ====="
flutter --version
dart --version
Write-Host "===== Outdated Dependencies ====="
flutter pub outdated
Write-Host "===== pubspec constraints ====="
if (Test-Path "pubspec.yaml") { Get-Content "pubspec.yaml" } else { Write-Host "pubspec.yaml not found in current directory." }
Write-Host "No dependencies were changed."
