param([string]$ProjectRoot = (Join-Path $PSScriptRoot '../../../..'))

# Non-destructive dependency inventory; pub outdated may use network/SDK caches.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $taskRoot 'pubspec.yaml'))) {
  throw 'ProjectRoot must contain pubspec.yaml.'
}
Push-Location -LiteralPath $taskRoot
try {
  & flutter --version
  if ($LASTEXITCODE -ne 0) { throw 'Flutter version check failed.' }
  & dart --version
  if ($LASTEXITCODE -ne 0) { throw 'Dart version check failed.' }
  & flutter pub outdated
  if ($LASTEXITCODE -ne 0) { throw 'Dependency inventory failed; availability remains unverified.' }
  Write-Host 'Declared constraints (resolved versions remain in pubspec.lock):'
  Get-Content -LiteralPath (Join-Path $taskRoot 'pubspec.yaml')
  Write-Host 'No upgrade was requested or applied.'
} finally {
  Pop-Location
}
