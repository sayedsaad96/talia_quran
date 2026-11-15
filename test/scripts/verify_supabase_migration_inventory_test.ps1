$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$verifier = Join-Path $root 'scripts/verify_supabase_migration_inventory.ps1'
$tempRoot = (Resolve-Path ([IO.Path]::GetTempPath())).Path
$fixtureRoot = Join-Path $tempRoot ('talia-migration-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
$fixtureRoot = (Resolve-Path -LiteralPath $fixtureRoot).Path
if (-not $fixtureRoot.StartsWith($tempRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Fixture directory is outside the temporary directory.'
}
function New-Fixture([string] $Name) {
  $path = Join-Path $fixtureRoot $Name
  New-Item -ItemType Directory -Path $path | Out-Null
  [IO.File]::WriteAllText((Join-Path $path '0001_baseline.sql'), 'select 1;')
  return $path
}
function Assert-Rejected([string] $Path, [string] $Expected) {
  try { & $verifier -MigrationDirectory $Path } catch {
    if ($_.Exception.Message -notlike "*$Expected*") { throw }
    Write-Host "PASS: rejects $Expected"
    return
  }
  throw "Expected rejection: $Expected"
}
try {
  & $verifier -MigrationDirectory (Join-Path $root 'supabase/migrations')
  $good = New-Fixture 'valid'
  [IO.File]::WriteAllText((Join-Path $good '0002_legacy.sql'), 'select 2;')
  [IO.File]::WriteAllText((Join-Path $good '20261106143113_timestamp.sql'), 'select 3;')
  & $verifier -MigrationDirectory $good

  $duplicate = New-Fixture 'duplicate'
  [IO.File]::WriteAllText((Join-Path $duplicate '0002_first.sql'), 'select 1;')
  [IO.File]::WriteAllText((Join-Path $duplicate '0002_second.sql'), 'select 1;')
  Assert-Rejected $duplicate 'Duplicate migration version'
  $malformed = New-Fixture 'malformed'
  [IO.File]::WriteAllText((Join-Path $malformed '123_bad.sql'), 'select 1;')
  Assert-Rejected $malformed 'Malformed migration filename'
  $empty = New-Fixture 'empty'
  [IO.File]::WriteAllText((Join-Path $empty '0002_empty.sql'), " `n ")
  Assert-Rejected $empty 'Empty SQL migration'
  $missing = Join-Path $fixtureRoot 'missing'
  New-Item -ItemType Directory -Path $missing | Out-Null
  [IO.File]::WriteAllText((Join-Path $missing '0002_other.sql'), 'select 1;')
  Assert-Rejected $missing 'Required migration 0001_baseline.sql is missing'
} finally {
  Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
}
