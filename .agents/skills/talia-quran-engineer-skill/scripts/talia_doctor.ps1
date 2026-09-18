param(
  [switch]$SkipTests
)

$ErrorActionPreference = "Continue"

Write-Host "Talia diagnostic baseline (non-destructive)"

function Section($name) {
  Write-Host ""
  Write-Host "===== $name ====="
}

Section "Flutter"
flutter --version

Section "Dart"
dart --version

Section "Flutter Doctor"
flutter doctor -v

Section "Dependency Status"
flutter pub outdated

Section "Static Analysis"
flutter analyze

if (-not $SkipTests) {
  Section "Tests"
  flutter test
}

Section "Git Status"
git status --short

Write-Host ""
Write-Host "Talia baseline finished. This non-destructive script does not modify dependencies or project files."
