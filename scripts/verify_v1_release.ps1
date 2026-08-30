param(
  [string] $EvidenceDirectory,
  [switch] $BuildAndroidRelease
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$originalLocation = (Get-Location).Path
$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
if ([string]::IsNullOrWhiteSpace($EvidenceDirectory)) {
  $EvidenceDirectory = Join-Path $repositoryRoot "build\release-evidence\v1\$runId"
}
$runDirectory = [System.IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

$script:stepNumber = 0
$script:results = [System.Collections.Generic.List[object]]::new()
$script:head = 'UNKNOWN'
$script:branch = 'UNKNOWN'
$script:worktreeClean = $false
$script:artifactPath = $null
$script:artifactHash = $null
$script:sourceSnapshotHash = $null

function Add-Result([string] $Gate, [string] $Status, [string] $Detail) {
  $script:results.Add([pscustomobject]@{
      Gate = $Gate
      Status = $Status
      Detail = $Detail
    })
}

function ConvertTo-SafeCommand([string] $Executable, [string[]] $Arguments) {
  $safeArguments = foreach ($argument in $Arguments) {
    if ($argument -match '\s') {
      '"{0}"' -f $argument.Replace('"', '\"')
    } else {
      $argument
    }
  }
  return (@($Executable) + @($safeArguments)) -join ' '
}

function Invoke-LoggedCommand(
  [string] $Label,
  [string] $Executable,
  [string[]] $Arguments,
  [string] $DisplayCommand = ''
) {
  $script:stepNumber++
  $slug = ($Label.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
  $logPath = Join-Path $runDirectory ('{0:D2}-{1}.log' -f $script:stepNumber, $slug)
  if ([string]::IsNullOrWhiteSpace($DisplayCommand)) {
    $DisplayCommand = ConvertTo-SafeCommand $Executable $Arguments
  }
  [System.IO.File]::WriteAllText(
    $logPath,
    "COMMAND: $DisplayCommand$([Environment]::NewLine)",
    (New-Object System.Text.UTF8Encoding($false))
  )
  Write-Host "[$Label] $DisplayCommand"

  & $Executable @Arguments 2>&1 |
    Tee-Object -FilePath $logPath -Append |
    ForEach-Object { Write-Host $_ }
  $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
  Add-Content -LiteralPath $logPath -Value "EXIT_CODE: $exitCode" -Encoding UTF8

  if ($exitCode -ne 0) {
    Add-Result $Label 'FAIL' "exit $exitCode; log: $logPath"
    throw "$Label failed with exit code $exitCode."
  }
  Add-Result $Label 'PASS' "exit 0; log: $logPath"
}

function Resolve-FlutterSdk {
  $candidates = [System.Collections.Generic.List[string]]::new()
  if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) {
    $candidates.Add($env:FLUTTER_ROOT)
  }
  $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
  if ($null -ne $flutterCommand) {
    $candidates.Add((Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent))
  }
  $candidates.Add('D:\dev\flutter')

  foreach ($candidate in $candidates | Select-Object -Unique) {
    $dart = Join-Path $candidate 'bin\cache\dart-sdk\bin\dart.exe'
    $snapshot = Join-Path $candidate 'bin\cache\flutter_tools.snapshot'
    $packages = Join-Path $candidate 'packages\flutter_tools\.dart_tool\package_config.json'
    if ((Test-Path -LiteralPath $dart) -and
        (Test-Path -LiteralPath $snapshot) -and
        (Test-Path -LiteralPath $packages)) {
      return @{ Root = $candidate; Dart = $dart; Snapshot = $snapshot; Packages = $packages }
    }
  }
  throw 'A complete Flutter SDK could not be located.'
}

function Invoke-Flutter([string] $Label, [string[]] $Arguments, [string] $DisplayCommand = '') {
  $flutterArguments = @(
    "--packages=$($script:flutterSdk.Packages)",
    $script:flutterSdk.Snapshot
  ) + $Arguments
  if ([string]::IsNullOrWhiteSpace($DisplayCommand)) {
    $DisplayCommand = 'flutter ' + ($Arguments -join ' ')
  }
  Invoke-LoggedCommand $Label $script:flutterSdk.Dart $flutterArguments $DisplayCommand
}

function Get-GeneratedHashMap {
  $map = @{}
  $roots = @((Join-Path $repositoryRoot 'lib'), (Join-Path $repositoryRoot 'test'))
  $files = Get-ChildItem -LiteralPath $roots -Recurse -File | Where-Object {
    $_.Name -like '*.g.dart' -or
    $_.Name -like '*.freezed.dart' -or
    $_.Name -like '*.mocks.dart' -or
    $_.FullName -match '[\\/]lib[\\/]core[\\/]l10n[\\/]app_localizations(?:_ar|_en)?\.dart$'
  }
  foreach ($file in $files) {
    $relative = [System.IO.Path]::GetRelativePath($repositoryRoot, $file.FullName).Replace('\', '/')
    $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  return $map
}

function Assert-GeneratedFilesUnchanged([hashtable] $Before, [hashtable] $After) {
  $drift = [System.Collections.Generic.List[string]]::new()
  $allPaths = @($Before.Keys) + @($After.Keys)
  foreach ($path in @($allPaths | Sort-Object -Unique)) {
    if (-not $Before.ContainsKey($path)) {
      $drift.Add("ADDED $path")
    } elseif (-not $After.ContainsKey($path)) {
      $drift.Add("REMOVED $path")
    } elseif ($Before[$path] -cne $After[$path]) {
      $drift.Add("CHANGED $path")
    }
  }
  $logPath = Join-Path $runDirectory 'generated-drift.txt'
  if ($drift.Count -gt 0) {
    $drift | Set-Content -LiteralPath $logPath -Encoding UTF8
    Add-Result 'Generated-file drift' 'FAIL' "generated output changed; log: $logPath"
    throw 'Generated files drifted after code generation.'
  }
  'NO DRIFT' | Set-Content -LiteralPath $logPath -Encoding UTF8
  Add-Result 'Generated-file drift' 'PASS' 'generated hashes are unchanged'
}

function Test-ArchiveSuffix([string[]] $Entries, [string] $Suffix) {
  $normalized = $Suffix.Replace('\', '/')
  return @($Entries | Where-Object {
      $_ -ceq $normalized -or $_.EndsWith("/$normalized", [System.StringComparison]::Ordinal)
    }).Count -gt 0
}

function Assert-AndroidArtifactAssets([string] $Artifact) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [System.IO.Compression.ZipFile]::OpenRead($Artifact)
  try {
    $entries = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
  } finally {
    $archive.Dispose()
  }
  $entries | Sort-Object | Set-Content -LiteralPath (Join-Path $runDirectory 'android-artifact-entries.txt') -Encoding UTF8

  foreach ($required in @(
      'assets/data/quran.json',
      'assets/data/surahs.json',
      'assets/data/content_manifest.json',
      'assets/data/azkar_release.json'
    )) {
    if (-not (Test-ArchiveSuffix $entries $required)) {
      Add-Result 'Android asset allowlist' 'FAIL' "missing $required"
      throw "Built Android artifact is missing $required."
    }
  }
  foreach ($forbidden in @('assets/data/azkar.json', '.env')) {
    if (Test-ArchiveSuffix $entries $forbidden) {
      Add-Result 'Android asset allowlist' 'FAIL' "forbidden asset present: $forbidden"
      throw "Built Android artifact contains forbidden asset $forbidden."
    }
  }
  Add-Result 'Android asset allowlist' 'PASS' 'approved assets present; candidate Azkar and .env absent'
}

function Write-SourceHashes([AllowEmptyString()][string] $Artifact = '') {
  $paths = [System.Collections.Generic.List[string]]::new()
  foreach ($root in @('lib', 'supabase\migrations')) {
    $fullRoot = Join-Path $repositoryRoot $root
    if (Test-Path -LiteralPath $fullRoot) {
      Get-ChildItem -LiteralPath $fullRoot -Recurse -File | ForEach-Object { $paths.Add($_.FullName) }
    }
  }
  foreach ($relative in @(
      'pubspec.yaml',
      'pubspec.lock',
      'assets\data\quran.json',
      'assets\data\surahs.json',
      'assets\data\content_manifest.json',
      'assets\data\azkar_release.json',
      'scripts\verify_v1_release.ps1'
    )) {
    $fullPath = Join-Path $repositoryRoot $relative
    if (Test-Path -LiteralPath $fullPath) { $paths.Add($fullPath) }
  }

  $hashLines = foreach ($path in $paths | Sort-Object -Unique) {
    $relative = [System.IO.Path]::GetRelativePath($repositoryRoot, $path).Replace('\', '/')
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash`t$relative"
  }
  $hashPath = Join-Path $runDirectory 'source-hashes.tsv'
  $hashLines | Set-Content -LiteralPath $hashPath -Encoding UTF8
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($hashLines -join "`n"))
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $script:sourceSnapshotHash = ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
  if (-not [string]::IsNullOrWhiteSpace($Artifact)) {
    $script:artifactHash = (Get-FileHash -LiteralPath $Artifact -Algorithm SHA256).Hash.ToLowerInvariant()
    Add-Result 'Source and artifact identity' 'PASS' "source=$($script:sourceSnapshotHash); artifact=$($script:artifactHash)"
  } else {
    Add-Result 'Source identity' 'PASS' "source=$($script:sourceSnapshotHash); release artifact NOT RUN"
  }
}

function Invoke-BackendGate([string] $Label, [string] $EnvironmentName, [switch] $Fresh) {
  $item = Get-Item -LiteralPath "Env:$EnvironmentName" -ErrorAction SilentlyContinue
  if ($null -eq $item -or [string]::IsNullOrWhiteSpace($item.Value)) {
    Add-Result $Label 'NOT RUN' "$EnvironmentName is unavailable"
    return
  }
  if ($null -eq (Get-Command psql -ErrorAction SilentlyContinue)) {
    Add-Result $Label 'NOT RUN' 'psql is unavailable'
    return
  }

  if ($Fresh) {
    Invoke-LoggedCommand `
      $Label `
      'pwsh' `
      @('-NoProfile', '-File', (Join-Path $PSScriptRoot 'verify_supabase_migrations.ps1')) `
      'pwsh -NoProfile -File scripts/verify_supabase_migrations.ps1'
    return
  }

  $priorProductionUrl = Get-Item -LiteralPath 'Env:SUPABASE_DB_URL' -ErrorAction SilentlyContinue
  try {
    if ($EnvironmentName -cne 'SUPABASE_DB_URL') {
      $env:SUPABASE_DB_URL = $item.Value
    }
    Invoke-LoggedCommand `
      $Label `
      'pwsh' `
      @('-NoProfile', '-File', (Join-Path $PSScriptRoot 'verify_supabase_contract.ps1')) `
      'pwsh -NoProfile -File scripts/verify_supabase_contract.ps1'
  } finally {
    if ($null -ne $priorProductionUrl) {
      $env:SUPABASE_DB_URL = $priorProductionUrl.Value
    } else {
      Remove-Item -LiteralPath 'Env:SUPABASE_DB_URL' -ErrorAction SilentlyContinue
    }
  }
}

function Write-Summary([string] $OverallStatus) {
  $summaryPath = Join-Path $runDirectory 'summary.md'
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('# Talia V1 release verification run')
  $lines.Add('')
  $lines.Add("- Timestamp (UTC): $runId")
  $lines.Add("- Git HEAD: $($script:head)")
  $lines.Add("- Branch: $($script:branch)")
  $lines.Add("- Worktree: $(if ($script:worktreeClean) { 'CLEAN' } else { 'DIRTY — NOT FROZEN' })")
  $lines.Add("- Overall: $OverallStatus")
  if ($null -ne $script:artifactPath) { $lines.Add("- Artifact: $($script:artifactPath)") }
  if ($null -ne $script:artifactHash) { $lines.Add("- Artifact SHA-256: $($script:artifactHash)") }
  if ($null -ne $script:sourceSnapshotHash) { $lines.Add("- Source snapshot SHA-256: $($script:sourceSnapshotHash)") }
  $lines.Add('')
  $lines.Add('| Gate | Status | Detail |')
  $lines.Add('|---|---|---|')
  foreach ($result in $script:results) {
    $detail = ([string]$result.Detail).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
    $lines.Add("| $($result.Gate) | $($result.Status) | $detail |")
  }
  $lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8
  Write-Host "Evidence summary: $summaryPath"
}

try {
  Set-Location $repositoryRoot
  $script:flutterSdk = Resolve-FlutterSdk

  $git = (Get-Command git -ErrorAction Stop).Source
  $script:head = (& $git rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0) { throw 'Could not read Git HEAD.' }
  $script:branch = (& $git branch --show-current).Trim()
  if ([string]::IsNullOrWhiteSpace($script:branch)) { $script:branch = 'DETACHED' }
  $statusLines = @(& $git status --porcelain=v1 --untracked-files=all)
  if ($LASTEXITCODE -ne 0) { throw 'Could not read Git worktree status.' }
  $script:worktreeClean = $statusLines.Count -eq 0
  @(
    'COMMAND: git status --porcelain=v1 --untracked-files=all',
    "HEAD: $($script:head)",
    "BRANCH: $($script:branch)",
    "WORKTREE: $(if ($script:worktreeClean) { 'CLEAN' } else { 'DIRTY — NOT FROZEN' })",
    '',
    $statusLines
  ) | Set-Content -LiteralPath (Join-Path $runDirectory 'git-context.txt') -Encoding UTF8
  Add-Result 'Git identity' 'PASS' "HEAD=$($script:head); branch=$($script:branch)"
  if ($script:worktreeClean) {
    Add-Result 'Frozen candidate' 'PASS' 'worktree is clean'
  } else {
    Add-Result 'Frozen candidate' 'BLOCKED' 'worktree is dirty — NOT FROZEN'
  }

  Invoke-LoggedCommand 'Dart version' $script:flutterSdk.Dart @('--version')
  Invoke-Flutter 'Flutter version' @('--version')

  $lockHashBefore = (Get-FileHash -LiteralPath (Join-Path $repositoryRoot 'pubspec.lock') -Algorithm SHA256).Hash
  Invoke-Flutter 'Dependency restore' @('pub', 'get', '--enforce-lockfile')
  $lockHashAfter = (Get-FileHash -LiteralPath (Join-Path $repositoryRoot 'pubspec.lock') -Algorithm SHA256).Hash
  if ($lockHashBefore -cne $lockHashAfter) {
    Add-Result 'Lockfile stability' 'FAIL' 'pubspec.lock changed during dependency restore'
    throw 'Dependency restore changed pubspec.lock.'
  }
  Add-Result 'Lockfile stability' 'PASS' 'pubspec.lock unchanged'

  $generatedBefore = Get-GeneratedHashMap
  Invoke-Flutter 'Localization generation' @('gen-l10n')
  Invoke-LoggedCommand `
    'Dart build generation' `
    $script:flutterSdk.Dart `
    @('run', 'build_runner', 'build', '--delete-conflicting-outputs') `
    'dart run build_runner build --delete-conflicting-outputs'
  $generatedAfter = Get-GeneratedHashMap
  Assert-GeneratedFilesUnchanged $generatedBefore $generatedAfter

  Invoke-Flutter 'Static analysis' @('analyze', '--no-pub')
  Invoke-Flutter 'Complete Flutter test suite' @('test', '--no-pub', '--reporter', 'expanded')

  if ($BuildAndroidRelease) {
    $defineFileItem = Get-Item -LiteralPath 'Env:TALIA_RELEASE_DART_DEFINES_FILE' -ErrorAction SilentlyContinue
    $buildArguments = @('build', 'appbundle', '--release', '--no-pub')
    if ($null -eq $defineFileItem -or [string]::IsNullOrWhiteSpace($defineFileItem.Value)) {
      Add-Result 'Cloud production defines' 'NOT RUN' 'offline/guest artifact; TALIA_RELEASE_DART_DEFINES_FILE unavailable'
      $buildDisplay = 'flutter build appbundle --release --no-pub'
    } else {
      $defineFile = [System.IO.Path]::GetFullPath($defineFileItem.Value)
      if (-not (Test-Path -LiteralPath $defineFile -PathType Leaf)) {
        throw 'TALIA_RELEASE_DART_DEFINES_FILE does not point to a file.'
      }
      $repositoryPrefix = $repositoryRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
      $defineFileIsInsideRepository = $defineFile.StartsWith(
        $repositoryPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
      )
      if ($defineFileIsInsideRepository) {
        & $git check-ignore --quiet -- $defineFile
        if ($LASTEXITCODE -ne 0) {
          throw 'The production defines file is inside the repository and is not ignored.'
        }
      }
      $buildArguments += "--dart-define-from-file=$defineFile"
      Add-Result 'Cloud production defines' 'PASS' 'provided through an external or ignored file; value not logged'
      $buildDisplay = 'flutter build appbundle --release --no-pub --dart-define-from-file=<redacted>'
    }

    Invoke-Flutter 'Android release appbundle' $buildArguments $buildDisplay
    $script:artifactPath = Join-Path $repositoryRoot 'build\app\outputs\bundle\release\app-release.aab'
    if (-not (Test-Path -LiteralPath $script:artifactPath -PathType Leaf)) {
      Add-Result 'Android artifact' 'FAIL' 'expected app-release.aab was not produced'
      throw 'Android release appbundle was not produced.'
    }
    Assert-AndroidArtifactAssets $script:artifactPath
    Write-SourceHashes $script:artifactPath
  } else {
    Add-Result 'Cloud production defines' 'NOT RUN' 'Release build not requested; development-stage verification only'
    Add-Result 'Android release appbundle' 'NOT RUN' 'Release build not requested; pass -BuildAndroidRelease only at release-candidate time'
    Add-Result 'Android asset allowlist' 'NOT RUN' 'requires the explicitly requested release artifact'
    Write-SourceHashes
  }

  $androidConfig = Get-Content -LiteralPath (Join-Path $repositoryRoot 'android\app\build.gradle.kts') -Raw
  if ($androidConfig.Contains('applicationId = "com.example.talia_quran"') -or
      $androidConfig.Contains('signingConfig = signingConfigs.getByName("debug")')) {
    Add-Result 'Store identity and signing' 'BLOCKED' 'default applicationId and/or debug release signing; store artifact NOT READY'
  } else {
    Add-Result 'Store identity and signing' 'PASS' 'non-default application identity and release signing configuration detected'
  }

  Invoke-BackendGate 'Fresh Supabase contract' 'TALIA_SUPABASE_FRESH_DB_URL' -Fresh
  Invoke-BackendGate 'Staging Supabase contract' 'TALIA_SUPABASE_STAGING_DB_URL'
  Invoke-BackendGate 'Production Supabase contract' 'SUPABASE_DB_URL'
  Add-Result 'Physical Android smoke' 'NOT RUN' 'requires a real clean-install/upgrade device run'
  Add-Result 'Internal-track smoke' 'NOT RUN' 'requires a signed store candidate and internal track'
  Add-Result 'Qualified Islamic approval' 'NOT RUN' 'requires the exact frozen artifact and external reviewer'

  $blocked = @($script:results | Where-Object { $_.Status -in @('BLOCKED', 'NOT RUN') }).Count -gt 0
  $overall = if ($blocked) { 'LOCAL PASS — RELEASE NO-GO' } else { 'PASS' }
  Add-Result 'Overall release decision' $(if ($blocked) { 'BLOCKED' } else { 'PASS' }) $overall
  Write-Summary $overall
} catch {
  Add-Result 'Overall release decision' 'FAIL' $_.Exception.Message
  Write-Summary 'FAIL'
  throw
} finally {
  Set-Location $originalLocation
}
