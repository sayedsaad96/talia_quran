$ErrorActionPreference = 'Stop'

function Assert-Equal([string] $Label, [AllowNull()] [string] $Expected, [AllowNull()] [string] $Actual) {
  if ($Actual -cne $Expected) {
    throw "$Label expected <$Expected> but was <$Actual>."
  }
}

function Assert-True([string] $Label, [bool] $Condition) {
  if (-not $Condition) { throw "Assertion failed: $Label" }
}

function Get-EnvironmentSnapshot([string[]] $Names) {
  $snapshot = @{}
  foreach ($name in $Names) {
    $item = Get-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    $snapshot[$name] = @{
      Exists = $null -ne $item
      Value = if ($null -ne $item) { $item.Value } else { $null }
    }
  }
  return $snapshot
}

function Restore-EnvironmentSnapshot([hashtable] $Snapshot) {
  foreach ($name in $Snapshot.Keys) {
    $item = $Snapshot[$name]
    if ($item.Exists) {
      Set-Item -LiteralPath "Env:$name" -Value $item.Value
    } else {
      Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
  }
}

function Set-TestEnvironment([string[]] $Names, [hashtable] $Values) {
  foreach ($name in $Names) {
    if ($Values.ContainsKey($name)) {
      Set-Item -LiteralPath "Env:$name" -Value $Values[$name]
    } else {
      Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    }
  }
}

function Assert-EnvironmentRestored([string] $Label, [hashtable] $Expected) {
  foreach ($name in $Expected.Keys) {
    $actual = Get-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    Assert-Equal "$Label $name existence" $Expected[$name].Exists ($null -ne $actual)
    if ($Expected[$name].Exists) {
      Assert-Equal "$Label $name value" $Expected[$name].Value $actual.Value
    }
  }
}

function Read-CapturedEnvironment([string] $CaptureDirectory) {
  $captured = @{}
  foreach ($line in Get-Content -LiteralPath (Join-Path $CaptureDirectory 'environment.txt')) {
    $parts = $line -split '=', 2
    $captured[$parts[0]] = if ($parts.Count -eq 2) { $parts[1] } else { '' }
  }
  return $captured
}

function Read-CapturedInvocations([string] $CaptureDirectory) {
  $path = Join-Path $CaptureDirectory 'invocations.jsonl'
  Assert-True 'fake psql captured at least one invocation' (Test-Path -LiteralPath $path)
  $records = @(
    foreach ($line in Get-Content -LiteralPath $path) {
      $record = $line | ConvertFrom-Json
      Assert-True 'fake psql record has a numeric sequence' ($record.sequence -is [int] -or $record.sequence -is [long])
      Assert-True 'fake psql record has an argv array' ($record.argv -is [array])
      Assert-True 'fake psql record has a numeric exit code' ($record.exitCode -is [int] -or $record.exitCode -is [long])
      $record
    }
  )
  return $records
}

function Assert-SafeInvocationRecords(
  [string] $Label,
  [object[]] $Records,
  [string] $DatabaseUrl,
  [string[]] $Secrets
) {
  Assert-True "$Label captured invocations" ($Records.Count -gt 0)
  $expectedSequence = 1
  foreach ($record in $Records) {
    Assert-Equal "$Label invocation sequence" $expectedSequence.ToString() $record.sequence.ToString()
    foreach ($argument in @($record.argv)) {
      Assert-True "$Label invocation $($record.sequence) argv excludes the database URL" (-not ([string]$argument).Contains($DatabaseUrl))
      foreach ($secret in $Secrets) {
        if (-not [string]::IsNullOrEmpty($secret)) {
          Assert-True "$Label invocation $($record.sequence) argv excludes a decoded secret" (-not ([string]$argument).Contains($secret))
        }
      }
    }
    $expectedSequence++
  }
}

function Test-InvocationToken([object] $Record, [string] $Token) {
  $arguments = @($Record.argv)
  if ($arguments -contains $Token) { return $true }
  return (($arguments -join ' ') -match "(?<!\S)$([regex]::Escape($Token))(?!\S)")
}

function Assert-InvocationShape(
  [string] $Label,
  [object[]] $Records,
  [int] $ExpectedCount,
  [int] $ExpectedExitCode,
  [bool] $Fresh
) {
  Assert-Equal "$Label invocation count (first argv=$(@($Records[0].argv) -join '|') first fake exit=$($Records[0].exitCode))" $ExpectedCount.ToString() $Records.Count.ToString()
  foreach ($record in $Records) {
    Assert-Equal "$Label fake psql exit code" $ExpectedExitCode.ToString() $record.exitCode.ToString()
    $arguments = @($record.argv)
    Assert-True "$Label invocation $($record.sequence) keeps ON_ERROR_STOP" (Test-InvocationToken $record 'ON_ERROR_STOP=1')
    if ($Fresh -and ($record.sequence -le $ExpectedCount)) {
      $hasFile = Test-InvocationToken $record '--file'
      $hasCommand = Test-InvocationToken $record '--command'
      Assert-True "$Label fresh file invocation has --file or contract invocation has --command" ($hasFile -or $hasCommand)
    }
  }
}

function Assert-FreshInvocationPatterns(
  [string] $Label,
  [object[]] $Records,
  [int] $ExpectedFileCount,
  [int] $ExpectedQueryCount
) {
  $fileRecords = @($Records | Where-Object { @($_.argv) -contains '--file' })
  $queryRecords = @($Records | Where-Object { @($_.argv) -contains '--command' })
  Assert-Equal "$Label migration/test file invocation count" $ExpectedFileCount.ToString() $fileRecords.Count.ToString()
  Assert-Equal "$Label contract query invocation count" $ExpectedQueryCount.ToString() $queryRecords.Count.ToString()
  foreach ($record in $fileRecords) {
    $arguments = @($record.argv)
    Assert-True "$Label file invocation has --set" (Test-InvocationToken $record '--set')
    Assert-True "$Label file invocation has a SQL path" (Test-InvocationToken $record '--file')
    Assert-True "$Label file invocation is not a query invocation" (-not (Test-InvocationToken $record '--command'))
  }
  foreach ($record in $queryRecords) {
    $arguments = @($record.argv)
    Assert-True "$Label query invocation has --tuples-only" (Test-InvocationToken $record '--tuples-only')
    Assert-True "$Label query invocation has --no-align" (Test-InvocationToken $record '--no-align')
    Assert-True "$Label query invocation has --quiet" (Test-InvocationToken $record '--quiet')
  }
}

function Assert-QueryInvocationPatterns([string] $Label, [object[]] $Records, [int] $ExpectedCount) {
  Assert-Equal "$Label query invocation count" $ExpectedCount.ToString() $Records.Count.ToString()
  foreach ($record in $Records) {
    $arguments = @($record.argv)
    Assert-True "$Label query invocation has --command" (Test-InvocationToken $record '--command')
    Assert-True "$Label query invocation has --tuples-only" (Test-InvocationToken $record '--tuples-only')
    Assert-True "$Label query invocation has --no-align" (Test-InvocationToken $record '--no-align')
    Assert-True "$Label query invocation has --quiet" (Test-InvocationToken $record '--quiet')
  }
}

function Assert-CapturedEnvironment(
  [string] $Label,
  [hashtable] $Captured,
  [string] $Name,
  [AllowNull()] [object] $Expected
) {
  if ($null -eq $Expected) {
    Assert-True "$Label $Name is absent" (-not $Captured.ContainsKey($Name))
  } else {
    Assert-True "$Label $Name is present" $Captured.ContainsKey($Name)
    Assert-Equal "$Label $Name" $Expected $Captured[$Name]
  }
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$verifier = Join-Path $repositoryRoot 'scripts\verify_supabase_contract.ps1'
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("talia-pg-contract-{0}" -f [guid]::NewGuid().ToString('N'))
$fakeBin = Join-Path $testRoot 'bin'
$captureRoot = Join-Path $testRoot 'captures'
$priorPassfile = Join-Path $testRoot 'prior.pgpass'
$connectionEnvironmentNames = @(
  'PGHOST',
  'PGHOSTADDR',
  'PGPORT',
  'PGDATABASE',
  'PGUSER',
  'PGPASSWORD',
  'PGPASSFILE',
  'PGSSLMODE'
)
$outerEnvironmentNames = $connectionEnvironmentNames + @('PATH', 'PATHEXT', 'CAPTURE_DIR')
$outerEnvironmentNames += 'FAKE_PSQL_EXIT_CODE'
$outerEnvironment = Get-EnvironmentSnapshot $outerEnvironmentNames

try {
  New-Item -ItemType Directory -Path $fakeBin, $captureRoot | Out-Null
  [System.IO.File]::WriteAllText($priorPassfile, "prior-passfile`n")
  $fakePsqlScript = @'
$captureDirectory = $env:CAPTURE_DIR
$invocationsPath = Join-Path $captureDirectory 'invocations.jsonl'
  $existing = @()
  if (Test-Path -LiteralPath $invocationsPath) {
    $existing = @(Get-Content -LiteralPath $invocationsPath)
  }
$exitCode = [int]$env:FAKE_PSQL_EXIT_CODE
$record = [ordered]@{
  sequence = $existing.Count + 1
  argv = @($args)
  exitCode = $exitCode
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::AppendAllText($invocationsPath, (($record | ConvertTo-Json -Compress) + [Environment]::NewLine), $utf8)

$environmentLines = @(Get-ChildItem Env:PG* | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" })
[System.IO.File]::WriteAllLines((Join-Path $captureDirectory 'environment.txt'), $environmentLines, $utf8)
if ($env:PGPASSFILE -and (Test-Path -LiteralPath $env:PGPASSFILE)) {
  Copy-Item -LiteralPath $env:PGPASSFILE -Destination (Join-Path $captureDirectory 'pgpass.txt') -Force
}
if (@($args) -contains '--command') { Write-Output 't' }
exit $exitCode
'@
  Set-Content -LiteralPath (Join-Path $fakeBin 'psql.ps1') -Value $fakePsqlScript -Encoding UTF8
  $env:PATH = "$fakeBin;$($outerEnvironment['PATH'].Value)"
  $env:PATHEXT = ".PS1;$($outerEnvironment['PATHEXT'].Value)"
  $probeDirectory = Join-Path $captureRoot 'fake-exit-probe'
  New-Item -ItemType Directory -Path $probeDirectory | Out-Null
  $env:CAPTURE_DIR = $probeDirectory
  $env:FAKE_PSQL_EXIT_CODE = '17'
  & (Join-Path $fakeBin 'psql.ps1') --command 'SELECT 1' 1> $null 2> $null
  Assert-Equal 'fake psql failure exit code is numeric and nonzero' '17' $LASTEXITCODE.ToString()

  function Invoke-VerifierCase(
    [string] $Name,
    [string] $DatabaseUrl,
    [hashtable] $PriorEnvironment,
    [string[]] $Arguments = @(),
    [int] $FakeExitCode = 17,
    [string[]] $Secrets = @(),
    [int] $ExpectedInvocationCount = 54,
    [bool] $Fresh = $false
  ) {
    $captureDirectory = Join-Path $captureRoot $Name
    New-Item -ItemType Directory -Path $captureDirectory | Out-Null
    Set-TestEnvironment $connectionEnvironmentNames $PriorEnvironment
    $expectedRestoration = Get-EnvironmentSnapshot $connectionEnvironmentNames
    $env:CAPTURE_DIR = $captureDirectory
    $env:FAKE_PSQL_EXIT_CODE = $FakeExitCode.ToString()

    $failed = $false
    $failureMessage = ''
    $verifierExitCode = $null
    try {
      if ($Fresh) {
        & $verifier -DatabaseUrl $DatabaseUrl -FreshDatabase 2> $null 1> $null 6> $null
      } else {
        & $verifier -DatabaseUrl $DatabaseUrl @Arguments 2> $null 1> $null 6> $null
      }
      $verifierExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    } catch {
      $failed = $true
      $failureMessage = $_.Exception.Message
      $verifierExitCode = if ($null -eq $LASTEXITCODE) { 1 } else { [int]$LASTEXITCODE }
    }

    if ($FakeExitCode -eq 0) {
      Assert-True "$Name verifier completed successfully ($failureMessage)" (-not $failed)
      Assert-Equal "$Name verifier exit code" '0' $verifierExitCode.ToString()
    } else {
      Assert-True "$Name verifier exercised the failing psql boundary ($failureMessage)" $failed
      Assert-True "$Name verifier exit code is nonzero" ($verifierExitCode -ne 0)
    }
    Assert-EnvironmentRestored "$Name restores environment after verifier completion" $expectedRestoration

    Assert-True `
      "$Name reaches psql with a valid PostgreSQL URI ($failureMessage)" `
      (Test-Path -LiteralPath (Join-Path $captureDirectory 'invocations.jsonl'))
    $records = Read-CapturedInvocations $captureDirectory
    Assert-InvocationShape $Name $records $ExpectedInvocationCount $FakeExitCode $Fresh
    Assert-SafeInvocationRecords $Name $records $DatabaseUrl $Secrets
    $argumentsText = (@($records[-1].argv) -join ' ')

    return @{
      Directory = $captureDirectory
      Arguments = $argumentsText
      Records = $records
      Environment = Read-CapturedEnvironment $captureDirectory
      ExitCode = $verifierExitCode
    }
  }

  $credentialedUrl = 'postgresql://qa%3Auser:pa%3Ass%5Cword@db.example.test:6543/db%3Aname?sslmode=require'
  $credentialed = Invoke-VerifierCase `
    -Name 'credentialed-host-failure' `
    -DatabaseUrl $credentialedUrl `
    -PriorEnvironment @{} `
    -Arguments @('-FreshDatabase') `
    -FakeExitCode 17 `
    -Secrets @('pa:ss\word') `
    -ExpectedInvocationCount 1 `
    -Fresh $true
  Assert-CapturedEnvironment 'credentialed-host-failure' $credentialed.Environment 'PGHOST' 'db.example.test'
  Assert-CapturedEnvironment 'credentialed-host-failure' $credentialed.Environment 'PGPORT' '6543'
  Assert-CapturedEnvironment 'credentialed-host-failure' $credentialed.Environment 'PGDATABASE' 'db:name'
  Assert-CapturedEnvironment 'credentialed-host-failure' $credentialed.Environment 'PGUSER' 'qa:user'
  Assert-CapturedEnvironment 'credentialed-host-failure' $credentialed.Environment 'PGPASSWORD' $null
  Assert-CapturedEnvironment 'credentialed-host-failure' $credentialed.Environment 'PGSSLMODE' 'require'
  Assert-Equal `
    'credentialed-host-failure escaped pgpass entry' `
    'db.example.test:6543:db\:name:qa\:user:pa\:ss\\word' `
    ((Get-Content -Raw -LiteralPath (Join-Path $credentialed.Directory 'pgpass.txt')).Trim())
  $credentialedPgPassPath = $credentialed.Environment['PGPASSFILE']
  Assert-True `
    'credentialed-host-failure PGPASSFILE is outside the repository' `
    (-not $credentialedPgPassPath.StartsWith($repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase))
  Assert-True 'credentialed-host-failure PGPASSFILE is deleted after failure' (-not (Test-Path -LiteralPath $credentialedPgPassPath))

  $migrationCount = @(Get-ChildItem (Join-Path $repositoryRoot 'supabase\migrations') -Filter '*.sql' -File).Count
  $databaseTestCount = @(Get-ChildItem (Join-Path $repositoryRoot 'supabase\tests') -Filter '*.sql' -File).Count
  $expectedContractQueryCount = 54
  $freshSuccessUrl = 'postgresql://fresh-user:fresh%3Apassword@fresh.example.test:6545/freshdb'
  $freshSuccess = Invoke-VerifierCase `
    -Name 'credentialed-host-success' `
    -DatabaseUrl $freshSuccessUrl `
    -PriorEnvironment @{} `
    -Arguments @('-FreshDatabase') `
    -FakeExitCode 0 `
    -Secrets @('fresh:password') `
    -ExpectedInvocationCount ($migrationCount + $databaseTestCount + $expectedContractQueryCount) `
    -Fresh $true
  Assert-FreshInvocationPatterns `
    'credentialed-host-success' `
    $freshSuccess.Records `
    ($migrationCount + $databaseTestCount) `
    $expectedContractQueryCount
  $freshSuccessPgPassPath = $freshSuccess.Environment['PGPASSFILE']
  Assert-True 'credentialed-host-success PGPASSFILE is deleted after success' (-not (Test-Path -LiteralPath $freshSuccessPgPassPath))

  $localDefault = Invoke-VerifierCase 'passwordless-local-default' 'postgresql:///mydb' @{}
  Assert-CapturedEnvironment 'passwordless-local-default' $localDefault.Environment 'PGHOST' $null
  Assert-CapturedEnvironment 'passwordless-local-default' $localDefault.Environment 'PGPORT' $null
  Assert-CapturedEnvironment 'passwordless-local-default' $localDefault.Environment 'PGDATABASE' 'mydb'
  Assert-CapturedEnvironment 'passwordless-local-default' $localDefault.Environment 'PGUSER' $null
  Assert-CapturedEnvironment 'passwordless-local-default' $localDefault.Environment 'PGPASSWORD' $null
  Assert-CapturedEnvironment 'passwordless-local-default' $localDefault.Environment 'PGPASSFILE' $null

  $inheritedEnvironment = @{
    PGHOST = 'inherited-host'
    PGPORT = '7654'
    PGUSER = 'inherited-user'
    PGPASSWORD = 'inherited-password'
    PGPASSFILE = $priorPassfile
    PGSSLMODE = 'prefer'
  }
  $queryHost = Invoke-VerifierCase `
    'query-local-socket' `
    'postgresql:///mydb?host=%2Fvar%2Frun%2Fpostgresql' `
    $inheritedEnvironment
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGHOST' '/var/run/postgresql'
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGPORT' '7654'
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGDATABASE' 'mydb'
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGUSER' 'inherited-user'
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGPASSWORD' 'inherited-password'
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGPASSFILE' $priorPassfile
  Assert-CapturedEnvironment 'query-local-socket' $queryHost.Environment 'PGSSLMODE' 'prefer'
  Assert-True 'query-local-socket inherited passfile remains' (Test-Path -LiteralPath $priorPassfile)

  $queryTcpHost = Invoke-VerifierCase `
    'query-tcp-host' `
    'postgresql:///mydb?host=localhost' `
    @{}
  Assert-CapturedEnvironment 'query-tcp-host' $queryTcpHost.Environment 'PGHOST' 'localhost'
  Assert-CapturedEnvironment 'query-tcp-host' $queryTcpHost.Environment 'PGDATABASE' 'mydb'

  $ipv6Url = 'postgres://ipv6-user:ipv6-pass@[::1]:6544/ipv6db'
  $ipv6 = Invoke-VerifierCase 'ipv6-host' $ipv6Url @{}
  Assert-CapturedEnvironment 'ipv6-host' $ipv6.Environment 'PGHOST' '::1'
  Assert-CapturedEnvironment 'ipv6-host' $ipv6.Environment 'PGPORT' '6544'
  Assert-Equal `
    'ipv6-host pgpass uses unbracketed escaped address' `
    '\:\:1:6544:ipv6db:ipv6-user:ipv6-pass' `
    ((Get-Content -Raw -LiteralPath (Join-Path $ipv6.Directory 'pgpass.txt')).Trim())

  $queryUrl = 'postgresql:///path-db?host=query.example.test&hostaddr=2001%3Adb8%3A%3A5&port=7444&dbname=query%20db&user=query%20user&password=query%3Apass%5Cword&sslmode=verify-full'
  $query = Invoke-VerifierCase `
    -Name 'allowlisted-query-parameters-failure' `
    -DatabaseUrl $queryUrl `
    -PriorEnvironment @{} `
    -FakeExitCode 17 `
    -Secrets @('query:pass\word') `
    -ExpectedInvocationCount $expectedContractQueryCount
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGHOST' 'query.example.test'
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGHOSTADDR' '2001:db8::5'
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGPORT' '7444'
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGDATABASE' 'query db'
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGUSER' 'query user'
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGPASSWORD' $null
  Assert-CapturedEnvironment 'allowlisted-query-parameters-failure' $query.Environment 'PGSSLMODE' 'verify-full'
  Assert-Equal `
    'allowlisted-query-parameters-failure escaped pgpass entry' `
    'query.example.test:7444:query db:query user:query\:pass\\word' `
    ((Get-Content -Raw -LiteralPath (Join-Path $query.Directory 'pgpass.txt')).Trim())

  $querySuccess = Invoke-VerifierCase `
    -Name 'allowlisted-query-parameters-success' `
    -DatabaseUrl $queryUrl `
    -PriorEnvironment @{} `
    -FakeExitCode 0 `
    -Secrets @('query:pass\word') `
    -ExpectedInvocationCount $expectedContractQueryCount
  Assert-QueryInvocationPatterns 'allowlisted-query-parameters-success' $querySuccess.Records $expectedContractQueryCount
  $selfCheckRecords = @(
    [pscustomobject]@{ sequence = 1; argv = @('safe', $queryUrl); exitCode = 0 },
    [pscustomobject]@{ sequence = 2; argv = @('safe-last'); exitCode = 0 }
  )
  $selfCheckRejectedEarlierLeak = $false
  try {
    Assert-SafeInvocationRecords 'self-check earlier leak' $selfCheckRecords $queryUrl @()
  } catch {
    $selfCheckRejectedEarlierLeak = $true
  }
  Assert-True 'self-check rejects a leak in an earlier invocation even when the last is safe' $selfCheckRejectedEarlierLeak

  $queryPassfile = Invoke-VerifierCase `
    'allowlisted-query-passfile' `
    'postgresql:///mydb?passfile=C%3A%5Csecure%5Cpgpass.conf' `
    @{ PGPASSWORD = 'inherited-password' }
  Assert-CapturedEnvironment 'allowlisted-query-passfile' $queryPassfile.Environment 'PGPASSFILE' 'C:\secure\pgpass.conf'
  Assert-CapturedEnvironment 'allowlisted-query-passfile' $queryPassfile.Environment 'PGPASSWORD' 'inherited-password'

  $invalidCaptureDirectory = Join-Path $captureRoot 'reject-arbitrary-query-key'
  New-Item -ItemType Directory -Path $invalidCaptureDirectory | Out-Null
  Set-TestEnvironment $connectionEnvironmentNames @{ PGHOST = 'must-survive' }
  $invalidExpectedRestoration = Get-EnvironmentSnapshot $connectionEnvironmentNames
  $env:CAPTURE_DIR = $invalidCaptureDirectory
  $invalidRejected = $false
  try {
    & $verifier -DatabaseUrl 'postgresql:///mydb?path=C%3A%5Cattacker' 2> $null 1> $null 6> $null
  } catch {
    $invalidRejected = $_.Exception.Message.Contains('Unsupported PostgreSQL URI query parameter')
  }
  Assert-True 'arbitrary query key is rejected by the explicit allowlist' $invalidRejected
  Assert-True `
    'arbitrary query key is rejected before psql' `
    (-not (Test-Path -LiteralPath (Join-Path $invalidCaptureDirectory 'invocations.jsonl')))
  Assert-EnvironmentRestored 'arbitrary query rejection preserves environment' $invalidExpectedRestoration

  Write-Host 'PASS: verify_supabase_contract safely applies libpq URI settings and restores the process environment'
} finally {
  Restore-EnvironmentSnapshot $outerEnvironment
  if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
  }
}
