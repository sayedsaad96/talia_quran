param([string] $FreshDatabaseUrl = $env:TALIA_SUPABASE_FRESH_DB_URL)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($FreshDatabaseUrl)) {
  throw 'TALIA_SUPABASE_FRESH_DB_URL is required. It must point to an empty local/staging Supabase database with the auth schema installed.'
}

& (Join-Path $PSScriptRoot 'verify_supabase_contract.ps1') -DatabaseUrl $FreshDatabaseUrl -FreshDatabase
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
