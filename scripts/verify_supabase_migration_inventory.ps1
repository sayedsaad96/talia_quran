param(
  [string] $MigrationDirectory = (Join-Path $PSScriptRoot '../supabase/migrations')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $MigrationDirectory -PathType Container)) {
  throw 'Migration directory does not exist.'
}
$files = @(Get-ChildItem -LiteralPath $MigrationDirectory -File | Where-Object { $_.Extension -ieq '.sql' })
if ($files.Count -eq 0) { throw 'No SQL migrations found.' }
$versions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$hasBaseline = $false
foreach ($file in $files) {
  if ($file.Name -cnotmatch '^(\d{4}|\d{14})_([a-z0-9]+(?:_[a-z0-9]+)*)\.sql$') {
    throw "Malformed migration filename: $($file.Name)"
  }
  $version = $Matches[1]
  if (-not $versions.Add($version)) { throw "Duplicate migration version: $version" }
  if ($version -clt '0001') { throw 'The baseline must be the earliest migration.' }
  if ($file.Name -ceq '0001_baseline.sql') { $hasBaseline = $true }
  if ([string]::IsNullOrWhiteSpace([IO.File]::ReadAllText($file.FullName))) {
    throw "Empty SQL migration: $($file.Name)"
  }
}
if (-not $hasBaseline) { throw 'Required migration 0001_baseline.sql is missing.' }
Write-Host "PASS: validated $($files.Count) local migration files; database execution was not performed."
