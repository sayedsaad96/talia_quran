$ErrorActionPreference = 'Continue'

Write-Host "=== Talia Quran Runtime QA v2.1 - Environment Check ==="
Write-Host "Repo: $(Get-Location)"

$pubspec = Join-Path (Get-Location) 'pubspec.yaml'
if (!(Test-Path $pubspec)) {
  Write-Error 'pubspec.yaml not found. Run this script from the talia_quran repository root.'
  exit 2
}

$pubspecText = Get-Content $pubspec -Raw
if ($pubspecText -notmatch '(?m)^name:\s*talia_quran\s*$') {
  Write-Error 'Project Identity Gate FAILED: pubspec.yaml is not name: talia_quran'
  exit 3
}
Write-Host '[PASS] Project Identity Gate: talia_quran'

function Check-Command($name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    Write-Host "[FAIL] $name not found"
    return $false
  }
  Write-Host "[PASS] $name -> $($cmd.Source)"
  return $true
}

$ok = $true
$ok = (Check-Command 'flutter') -and $ok
$ok = (Check-Command 'adb') -and $ok
$ok = (Check-Command 'patrol') -and $ok

Write-Host "ANDROID_HOME=$env:ANDROID_HOME"

if (Get-Command flutter -ErrorAction SilentlyContinue) {
  Write-Host "`n--- flutter devices ---"
  flutter devices
}

if (Get-Command adb -ErrorAction SilentlyContinue) {
  Write-Host "`n--- adb devices ---"
  adb devices
}

if (Get-Command patrol -ErrorAction SilentlyContinue) {
  Write-Host "`n--- patrol version/doctor ---"
  patrol --version
}

if (!$ok) { exit 4 }
Write-Host "`nEnvironment commands are available. Runtime gates still require an Android device in adb state 'device' and an actual Patrol launch."
