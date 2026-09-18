$ErrorActionPreference = "Continue"
Write-Host "Talia project snapshot (non-destructive)"
Write-Host "===== Git ====="
git rev-parse HEAD
git status --short
Write-Host "===== Top-Level ====="
Get-ChildItem -Force | Select-Object Name, Mode
Write-Host "===== lib directories ====="
if (Test-Path "lib") { Get-ChildItem "lib" -Directory -Recurse | Select-Object FullName }
Write-Host "===== test directories ====="
if (Test-Path "test") { Get-ChildItem "test" -Directory -Recurse | Select-Object FullName }
Write-Host "===== Config filenames only ====="
Get-ChildItem -Recurse -File -Include "pubspec.yaml","analysis_options.yaml","*.gradle","AndroidManifest.xml","Info.plist" | Select-Object FullName
Write-Host "Snapshot intentionally excludes file contents that may contain secrets. This helper is non-destructive."
