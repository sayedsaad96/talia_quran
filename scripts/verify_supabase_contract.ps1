param(
  [string] $DatabaseUrl = $env:SUPABASE_DB_URL,
  [switch] $FreshDatabase
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) { throw 'SUPABASE_DB_URL (or -DatabaseUrl) is required.' }
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) { throw 'psql is required. Install PostgreSQL client tools or run this in the Supabase CLI container.' }

function Escape-PgPassField([string] $Value) {
  return $Value.Replace('\', '\\').Replace(':', '\:')
}

$postgresConnectionEnvironmentByParameter = [ordered]@{
  host = 'PGHOST'
  hostaddr = 'PGHOSTADDR'
  port = 'PGPORT'
  dbname = 'PGDATABASE'
  user = 'PGUSER'
  passfile = 'PGPASSFILE'
  sslmode = 'PGSSLMODE'
}

function ConvertFrom-PostgresUriComponent([string] $Value) {
  if ($Value -match '%(?![0-9A-Fa-f]{2})') {
    throw "Invalid percent-encoding in PostgreSQL URI component: $Value"
  }
  return [System.Uri]::UnescapeDataString($Value)
}

function Get-PostgresConnectionSettings([string] $ConnectionUri) {
  $match = [regex]::Match(
    $ConnectionUri,
    '^(postgres(?:ql)?):\/\/(.*)$',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
      [System.Text.RegularExpressions.RegexOptions]::Singleline
  )
  if (-not $match.Success -or $match.Groups[2].Value.Contains('#')) {
    throw 'Database URL must be an absolute postgres:// or postgresql:// URI.'
  }

  $parameters = @{}
  $remainder = $match.Groups[2].Value
  $query = ''
  $queryIndex = $remainder.IndexOf('?')
  if ($queryIndex -ge 0) {
    $query = $remainder.Substring($queryIndex + 1)
    $remainder = $remainder.Substring(0, $queryIndex)
  }

  $authority = $remainder
  $encodedDatabase = $null
  $slashIndex = $remainder.IndexOf('/')
  if ($slashIndex -ge 0) {
    $authority = $remainder.Substring(0, $slashIndex)
    $encodedDatabase = $remainder.Substring($slashIndex + 1)
  }

  $hostSpec = $authority
  $atIndex = $authority.LastIndexOf('@')
  if ($atIndex -ge 0) {
    $encodedUserInfo = $authority.Substring(0, $atIndex) -split ':', 2
    $parameters['user'] = ConvertFrom-PostgresUriComponent $encodedUserInfo[0]
    if ($encodedUserInfo.Count -eq 2) {
      $parameters['password'] = ConvertFrom-PostgresUriComponent $encodedUserInfo[1]
    }
    $hostSpec = $authority.Substring($atIndex + 1)
  }

  if ($hostSpec.Length -gt 0) {
    $hostValues = New-Object System.Collections.Generic.List[string]
    $portValues = New-Object System.Collections.Generic.List[string]
    $hasExplicitPort = $false
    foreach ($hostEntry in $hostSpec -split ',') {
      $encodedHost = $hostEntry
      $encodedPort = ''
      $entryHasPort = $false
      if ($hostEntry.StartsWith('[')) {
        $closingBracket = $hostEntry.IndexOf(']')
        if ($closingBracket -lt 0) {
          throw "Invalid bracketed IPv6 host in PostgreSQL URI: $hostEntry"
        }
        $encodedHost = $hostEntry.Substring(1, $closingBracket - 1)
        $suffix = $hostEntry.Substring($closingBracket + 1)
        if ($suffix.Length -gt 0) {
          if (-not $suffix.StartsWith(':')) {
            throw "Invalid bracketed IPv6 host in PostgreSQL URI: $hostEntry"
          }
          $entryHasPort = $true
          $encodedPort = $suffix.Substring(1)
        }
      } else {
        $colonCount = ([regex]::Matches($hostEntry, ':')).Count
        if ($colonCount -gt 1) {
          throw "IPv6 hosts in PostgreSQL URIs must be enclosed in brackets: $hostEntry"
        }
        if ($colonCount -eq 1) {
          $separator = $hostEntry.LastIndexOf(':')
          $encodedHost = $hostEntry.Substring(0, $separator)
          $encodedPort = $hostEntry.Substring($separator + 1)
          $entryHasPort = $true
        }
      }

      [void] $hostValues.Add((ConvertFrom-PostgresUriComponent $encodedHost))
      [void] $portValues.Add((ConvertFrom-PostgresUriComponent $encodedPort))
      if ($entryHasPort) { $hasExplicitPort = $true }
    }
    $parameters['host'] = $hostValues -join ','
    if ($hasExplicitPort) { $parameters['port'] = $portValues -join ',' }
  }

  if ($null -ne $encodedDatabase -and $encodedDatabase.Length -gt 0) {
    $parameters['dbname'] = ConvertFrom-PostgresUriComponent $encodedDatabase
  }

  if ($query.Length -gt 0) {
    foreach ($pair in $query -split '&') {
      if ([string]::IsNullOrEmpty($pair)) { continue }
      $parts = $pair -split '=', 2
      if ($parts.Count -ne 2) {
        throw "PostgreSQL URI query parameters must use name=value syntax: $pair"
      }
      $name = ConvertFrom-PostgresUriComponent $parts[0]
      $value = ConvertFrom-PostgresUriComponent $parts[1]
      if ($name -ceq 'password' -or @($postgresConnectionEnvironmentByParameter.Keys) -ccontains $name) {
        $parameters[$name] = $value
      } else {
        throw "Unsupported PostgreSQL URI query parameter: $name"
      }
    }
  }

  return @{ Parameters = $parameters }
}

function Get-PgPassMatchValue([string[]] $EnvironmentNames, [string] $DefaultValue) {
  foreach ($name in $EnvironmentNames) {
    $item = Get-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    if ($null -ne $item -and -not [string]::IsNullOrEmpty($item.Value)) {
      if ($item.Value.Contains(',')) { return '*' }
      return $item.Value
    }
  }
  return $DefaultValue
}

function New-PgPassLine([string] $Password) {
  $pgPassHost = Get-PgPassMatchValue @('PGHOST', 'PGHOSTADDR') 'localhost'
  $pgPassPort = Get-PgPassMatchValue @('PGPORT') '5432'
  $pgPassUser = Get-PgPassMatchValue @('PGUSER') ([System.Environment]::UserName)
  $pgPassDatabase = Get-PgPassMatchValue @('PGDATABASE') $pgPassUser
  return @(
    (Escape-PgPassField $pgPassHost),
    (Escape-PgPassField $pgPassPort),
    (Escape-PgPassField $pgPassDatabase),
    (Escape-PgPassField $pgPassUser),
    (Escape-PgPassField $Password)
  ) -join ':'
}

function Protect-PgPassFile([string] $Path) {
  if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $account = New-Object System.Security.Principal.NTAccount($identity.Name)
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetOwner($account)
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $account,
      [System.Security.AccessControl.FileSystemRights]::FullControl,
      [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
    return
  }

  & chmod 600 -- $Path
  if ($LASTEXITCODE -ne 0) { throw 'Could not restrict temporary pgpass permissions.' }
}

$connection = Get-PostgresConnectionSettings $DatabaseUrl
$connectionParameters = $connection.Parameters
$connectionEnvironmentNames = @(
  @($postgresConnectionEnvironmentByParameter.Values) + @('PGPASSWORD') |
    Sort-Object -Unique
)
$previousConnectionEnvironment = @{}
foreach ($name in $connectionEnvironmentNames) {
  $item = Get-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
  $previousConnectionEnvironment[$name] = @{
    Exists = $null -ne $item
    Value = if ($null -ne $item) { $item.Value } else { $null }
  }
}

$pgPassFile = $null
try {
  foreach ($parameterName in $postgresConnectionEnvironmentByParameter.Keys) {
    if ($connectionParameters.ContainsKey($parameterName)) {
      Set-Item `
        -LiteralPath "Env:$($postgresConnectionEnvironmentByParameter[$parameterName])" `
        -Value $connectionParameters[$parameterName]
    }
  }

  if ($connectionParameters.ContainsKey('password')) {
    $pgPassFile = Join-Path `
      ([System.IO.Path]::GetTempPath()) `
      ("talia-pgpass-{0}.conf" -f [guid]::NewGuid().ToString('N'))
    $pgPassLine = New-PgPassLine $connectionParameters['password']
    [System.IO.File]::WriteAllText(
      $pgPassFile,
      "$pgPassLine`n",
      (New-Object System.Text.UTF8Encoding($false))
    )
    Protect-PgPassFile $pgPassFile
    $env:PGPASSFILE = $pgPassFile
    Remove-Item -LiteralPath Env:PGPASSWORD -ErrorAction SilentlyContinue
  }

$root = Join-Path $PSScriptRoot '..'
$migrations = Get-ChildItem (Join-Path $root 'supabase\migrations') -Filter '*.sql' -File | Sort-Object Name
if ($migrations.Count -eq 0) { throw 'No migrations found.' }
if ($FreshDatabase) {
  foreach ($migration in $migrations) {
    & psql --set ON_ERROR_STOP=1 --file $migration.FullName | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Migration failed: $($migration.Name)" }
  }
  Write-Host "PASS: fresh database applied $($migrations.Count) migrations"

  $databaseTests = Get-ChildItem (Join-Path $root 'supabase\tests') -Filter '*.sql' -File | Sort-Object Name
  foreach ($databaseTest in $databaseTests) {
    & psql --set ON_ERROR_STOP=1 --file $databaseTest.FullName | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Database contract test failed: $($databaseTest.Name)" }
  }
  Write-Host "PASS: fresh database passed $($databaseTests.Count) database contract tests"
}

$anyFailed = $false
function Check([string] $label, [string] $query) {
  $value = (& psql --set ON_ERROR_STOP=1 --tuples-only --no-align --quiet --command $query).Trim()
  if ($LASTEXITCODE -ne 0 -or $value -ne 't') { Write-Host "FAIL: $label"; $script:anyFailed = $true } else { Write-Host "PASS: $label" }
}

@('profiles','parent_child_links','kids_progress_cloud','kids_session_logs','parent_rewards','streaks','xp','daily_activities','ayah_review_records_cloud','daily_plans_cloud','custom_plans_cloud','certificate_awards_cloud','reading_progress_cloud','quran_bookmarks_cloud') | ForEach-Object {
  Check "table public.$_" "SELECT to_regclass('public.$_') IS NOT NULL"
  Check "RLS public.$_" "SELECT relrowsecurity FROM pg_class WHERE oid='public.$_'::regclass"
}
@{
  'daily_plans_cloud.revision' = "SELECT atttypid::regtype::text='bigint' FROM pg_attribute WHERE attrelid='public.daily_plans_cloud'::regclass AND attname='revision' AND NOT attisdropped"
  'custom_plans_cloud.revision' = "SELECT atttypid::regtype::text='bigint' FROM pg_attribute WHERE attrelid='public.custom_plans_cloud'::regclass AND attname='revision' AND NOT attisdropped"
  'quran_bookmarks_cloud.revision' = "SELECT atttypid::regtype::text='bigint' FROM pg_attribute WHERE attrelid='public.quran_bookmarks_cloud'::regclass AND attname='revision' AND NOT attisdropped"
  'quran_bookmarks_cloud.is_deleted' = "SELECT atttypid::regtype::text='boolean' FROM pg_attribute WHERE attrelid='public.quran_bookmarks_cloud'::regclass AND attname='is_deleted' AND NOT attisdropped"
}.GetEnumerator() | ForEach-Object { Check "column $($_.Key)" $_.Value }

@{
  'delete_current_user' = "SELECT pg_get_function_result('public.delete_current_user()'::regprocedure)='void' AND has_function_privilege('authenticated','public.delete_current_user()','EXECUTE')"
  'pull_quran_bookmarks' = "SELECT pg_get_function_result('public.pull_quran_bookmarks()'::regprocedure)='SETOF public.quran_bookmarks_cloud' AND has_function_privilege('authenticated','public.pull_quran_bookmarks()','EXECUTE')"
  'upsert_quran_bookmark' = "SELECT pg_get_function_result('public.upsert_quran_bookmark(integer,integer,jsonb,bigint,boolean)'::regprocedure) LIKE 'TABLE(surah_id integer, ayah_number integer, revision bigint)' AND has_function_privilege('authenticated','public.upsert_quran_bookmark(integer,integer,jsonb,bigint,boolean)','EXECUTE')"
  'compare_and_swap_daily_plan' = "SELECT pg_get_function_result('public.compare_and_swap_daily_plan(bigint,integer,timestamp with time zone,integer,integer,jsonb)'::regprocedure)='jsonb' AND has_function_privilege('authenticated','public.compare_and_swap_daily_plan(bigint,integer,timestamp with time zone,integer,integer,jsonb)','EXECUTE')"
  'compare_and_swap_custom_plan' = "SELECT pg_get_function_result('public.compare_and_swap_custom_plan(bigint,jsonb,boolean)'::regprocedure)='jsonb' AND has_function_privilege('authenticated','public.compare_and_swap_custom_plan(bigint,jsonb,boolean)','EXECUTE')"
  'create_parent_reward' = "SELECT pg_get_function_result('public.create_parent_reward(uuid,text)'::regprocedure)='SETOF public.parent_rewards' AND has_function_privilege('authenticated','public.create_parent_reward(uuid,text)','EXECUTE')"
  'unlock_parent_reward' = "SELECT pg_get_function_result('public.unlock_parent_reward(bigint)'::regprocedure)='SETOF public.parent_rewards' AND has_function_privilege('authenticated','public.unlock_parent_reward(bigint)','EXECUTE')"
  'claim_parent_reward' = "SELECT pg_get_function_result('public.claim_parent_reward(bigint)'::regprocedure)='SETOF public.parent_rewards' AND has_function_privilege('authenticated','public.claim_parent_reward(bigint)','EXECUTE')"
  'insert_kids_session_logs_batch' = "SELECT pg_get_function_result('public.insert_kids_session_logs_batch(jsonb)'::regprocedure) LIKE 'TABLE(local_id text, surah_id integer, ayah_number integer)' AND has_function_privilege('authenticated','public.insert_kids_session_logs_batch(jsonb)','EXECUTE')"
  'revoke_guardian_link' = "SELECT pg_get_function_result('public.revoke_guardian_link(uuid)'::regprocedure)='void' AND pg_get_function_arguments('public.revoke_guardian_link(uuid)'::regprocedure)='p_counterpart_user_id uuid' AND has_function_privilege('authenticated','public.revoke_guardian_link(uuid)','EXECUTE') AND NOT has_function_privilege('anon','public.revoke_guardian_link(uuid)','EXECUTE') AND NOT has_function_privilege('service_role','public.revoke_guardian_link(uuid)','EXECUTE')"
}.GetEnumerator() | ForEach-Object { Check "RPC $($_.Key)" $_.Value }

Check 'guardian RPC denied to PUBLIC' "SELECT NOT EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f',p.proowner))) acl WHERE p.oid='public.revoke_guardian_link(uuid)'::regprocedure AND acl.grantee=0 AND acl.privilege_type='EXECUTE')"
Check 'guardian RPC empty search_path' "SELECT proconfig=ARRAY['search_path=\"\"']::text[] FROM pg_proc WHERE oid='public.revoke_guardian_link(uuid)'::regprocedure"
Check 'prune_audit_logs denied to PUBLIC' "SELECT NOT EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f',p.proowner))) acl WHERE p.oid='public.prune_audit_logs()'::regprocedure AND acl.grantee=0 AND acl.privilege_type='EXECUTE')"
Check 'prune_audit_logs denied to anon' "SELECT NOT has_function_privilege('anon','public.prune_audit_logs()','EXECUTE')"
Check 'prune_audit_logs denied to authenticated' "SELECT NOT has_function_privilege('authenticated','public.prune_audit_logs()','EXECUTE')"
Check 'prune_audit_logs granted to service_role' "SELECT has_function_privilege('service_role','public.prune_audit_logs()','EXECUTE')"

Check 'parent_rewards direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.parent_rewards','INSERT,UPDATE,DELETE')"
Check 'daily plans direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.daily_plans_cloud','INSERT,UPDATE,DELETE')"
Check 'custom plans direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.custom_plans_cloud','INSERT,UPDATE,DELETE')"
Check 'bookmark direct DML revoked' "SELECT NOT has_table_privilege('authenticated','public.quran_bookmarks_cloud','INSERT,UPDATE,DELETE')"
Check 'parent rewards child read policy' "SELECT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='parent_rewards' AND policyname='parent_rewards_child_read')"
Check 'bookmark owner read policy' "SELECT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='quran_bookmarks_cloud' AND policyname='quran_bookmarks_cloud_owner_read')"
if ($anyFailed) { throw 'Supabase contract verification failed.' }
Write-Host 'PASS: Supabase contract verified'
} finally {
  foreach ($name in $connectionEnvironmentNames) {
    $previous = $previousConnectionEnvironment[$name]
    if ($previous.Exists) {
      Set-Item -LiteralPath "Env:$name" -Value $previous.Value
    } else {
      Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
  }
  if ($null -ne $pgPassFile -and (Test-Path -LiteralPath $pgPassFile)) {
    Remove-Item -LiteralPath $pgPassFile -Force
  }
}
