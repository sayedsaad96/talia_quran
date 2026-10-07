param([string]$ProjectRoot = (Join-Path $PSScriptRoot '../../../..'))

# Non-destructive navigation snapshot; no credential or configuration contents.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $taskRoot 'pubspec.yaml'))) {
  throw 'ProjectRoot must contain pubspec.yaml.'
}
Push-Location -LiteralPath $taskRoot
try {
  & git -c core.fsmonitor=false rev-parse HEAD
  if ($LASTEXITCODE -ne 0) { throw 'Cannot read repository revision.' }
  & git -c core.fsmonitor=false status --short
  if ($LASTEXITCODE -ne 0) { throw 'Cannot read working-tree status.' }
  foreach ($relative in @('lib/core', 'lib/features', 'test', 'scripts', 'supabase/migrations')) {
    Write-Host "Paths: $relative"
    $taskPath = Join-Path $taskRoot $relative
    if (Test-Path -LiteralPath $taskPath) {
      Get-ChildItem -LiteralPath $taskPath | Select-Object Name, Mode | Format-Table -AutoSize | Out-Host
    }
  }
} finally {
  Pop-Location
}
