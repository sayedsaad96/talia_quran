param(
  [string]$ProjectRoot = (Join-Path $PSScriptRoot '../../../..'),
  [string[]]$AnalyzePaths = @('lib'),
  [string[]]$TestPaths = @(),
  [switch]$FullTests,
  [switch]$SkipTests,
  [switch]$CheckOutdated,
  [switch]$Doctor
)

# Non-destructive: no cleanup, upgrades, corpus rewrite or DB mutation.
# Tooling can write build/cache files; --no-pub avoids implicit pub get.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $taskRoot 'pubspec.yaml'))) {
  throw 'ProjectRoot must be the Talia repository root.'
}
if ($SkipTests -and ($FullTests -or $TestPaths.Count -gt 0)) {
  throw 'SkipTests cannot be combined with FullTests or TestPaths.'
}
$taskResults = [System.Collections.Generic.List[object]]::new()

function Invoke-TaskCheck([string]$Executable, [string[]]$Arguments) {
  Write-Host "Running: $Executable $($Arguments -join ' ')"
  $checkExit = 1
  try {
    if (-not (Get-Command $Executable -ErrorAction SilentlyContinue)) {
      throw "Tool unavailable: $Executable"
    }
    & $Executable @Arguments
    $checkExit = $LASTEXITCODE
    if ($null -eq $checkExit) { $checkExit = 1 }
  } catch {
    Write-Warning $_.Exception.Message
  }
  $taskResults.Add([pscustomobject]@{
    Command = "$Executable $($Arguments -join ' ')"
    ExitCode = $checkExit
  })
}

Push-Location -LiteralPath $taskRoot
try {
  Write-Host 'Talia diagnostic baseline (non-destructive; scoped checks)'
  Invoke-TaskCheck -Executable 'git' -Arguments @('-c', 'core.fsmonitor=false', 'rev-parse', 'HEAD')
  Invoke-TaskCheck -Executable 'git' -Arguments @('-c', 'core.fsmonitor=false', 'status', '--short')
  Invoke-TaskCheck -Executable 'flutter' -Arguments @('--version')
  Invoke-TaskCheck -Executable 'dart' -Arguments @('--version')
  if ($Doctor) { Invoke-TaskCheck -Executable 'flutter' -Arguments @('doctor', '-v') }
  if ($CheckOutdated) { Invoke-TaskCheck -Executable 'flutter' -Arguments @('pub', 'outdated') }
  Invoke-TaskCheck -Executable 'flutter' -Arguments (@('analyze', '--no-pub') + $AnalyzePaths)
  if (-not $SkipTests) {
    if ($FullTests) {
      Invoke-TaskCheck -Executable 'flutter' -Arguments @('test', '--no-pub')
    } elseif ($TestPaths.Count -gt 0) {
      Invoke-TaskCheck -Executable 'flutter' -Arguments (@('test', '--no-pub') + $TestPaths)
    } else {
      Write-Host 'Tests not run: provide TestPaths or opt into FullTests.'
    }
  } else {
    Write-Host 'Tests not run: SkipTests selected.'
  }
  $taskResults | Format-Table -AutoSize | Out-Host
} finally {
  Pop-Location
}
if (@($taskResults | Where-Object { $_.ExitCode -ne 0 }).Count -gt 0) { exit 1 }
exit 0
