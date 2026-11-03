[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$base = Join-Path $root '.tmp/pg-verification'
$archive = Join-Path $base 'postgresql-17.6-1-windows-x64-binaries.zip'
$portable = Join-Path $base 'portable'
$bin = Join-Path $portable 'pgsql/bin'
$run = Join-Path $base ('run-' + [Guid]::NewGuid().ToString('N'))
$cluster = Join-Path $run 'cluster'
$pwfile = Join-Path $run 'initdb-password.txt'
$log = Join-Path $run 'postgres.log'
$processes = @()
$started = $false
$startAttempted = $false
$oldPassword = $env:PGPASSWORD
$oldOptions = $env:PGOPTIONS
$oldService = $env:PGSERVICE
$env:PGOPTIONS = $null
$env:PGSERVICE = $null

function Invoke-Checked([string]$Label, [string]$Exe, [string[]]$Arguments) {
  Write-Host "RUN $Label"
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Label failed (exit $LASTEXITCODE)" }
  Write-Host "PASS $Label (exit 0)"
}
function Invoke-Query([string]$Sql) {
  $output = & $psql -X -h 127.0.0.1 -p $port -U postgres -d postgres -qAt -v ON_ERROR_STOP=1 -c $Sql
  if ($LASTEXITCODE -ne 0) { throw 'local query failed' }
  return ($output -join "`n").Trim()
}
function Start-Psql([string]$Name) {
  $info = [System.Diagnostics.ProcessStartInfo]::new()
  $info.FileName = $psql
  foreach ($arg in @('-X','-h','127.0.0.1','-p',"$port",'-U','postgres','-d','postgres','-qAt','-v','ON_ERROR_STOP=1')) { [void]$info.ArgumentList.Add($arg) }
  $info.UseShellExecute = $false
  $info.RedirectStandardInput = $true
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $info.Environment['PGAPPNAME'] = $Name
  $child = [System.Diagnostics.Process]::new()
  $child.StartInfo = $info
  if (!$child.Start()) { throw 'could not launch psql' }
  return $child
}
function Wait-DatabaseCondition([string]$Sql, [string]$Message) {
  for ($i=0; $i -lt 150; $i++) {
    if ((Invoke-Query $Sql) -eq '1') { return }
    Start-Sleep -Milliseconds 100
  }
  throw "Timed out: $Message"
}
try {
  if (!(Test-Path -LiteralPath $archive)) { throw 'Verified PostgreSQL archive is missing' }
  $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant()
  if ($actualHash -ne 'd378882abd001a186735acd6f6ba716bca6ccd192e800412d4fd15ed25376b3e') { throw 'PostgreSQL archive hash mismatch' }
  if (!(Test-Path -LiteralPath (Join-Path $bin 'postgres.exe'))) {
    New-Item -ItemType Directory -Force -Path $portable | Out-Null
    Invoke-Checked 'extract PostgreSQL binaries' 'tar.exe' @('-xf',$archive,'-C',$portable,'pgsql/bin','pgsql/share','pgsql/lib')
  }
  $initdb = Join-Path $bin 'initdb.exe'
  $ctl = Join-Path $bin 'pg_ctl.exe'
  $psql = Join-Path $bin 'psql.exe'
  $version = & (Join-Path $bin 'postgres.exe') --version
  if ($LASTEXITCODE -ne 0 -or $version -ne 'postgres (PostgreSQL) 17.6') { throw 'Expected PostgreSQL 17.6' }
  Write-Host "PostgreSQL: $version"
  New-Item -ItemType Directory -Path $run | Out-Null
  $baseResolved = (Resolve-Path -LiteralPath $base).Path.TrimEnd('\') + '\'
  $runResolved = (Resolve-Path -LiteralPath $run).Path
  if (!$runResolved.StartsWith($baseResolved, [StringComparison]::OrdinalIgnoreCase)) { throw 'Run directory outside workspace verification root' }
  $random = [byte[]]::new(32)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($random)
  $env:PGPASSWORD = [Convert]::ToHexString($random)
  [System.IO.File]::WriteAllText($pwfile, $env:PGPASSWORD, [System.Text.UTF8Encoding]::new($false))
  $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $listener.Start()
  $port = $listener.LocalEndpoint.Port
  $listener.Stop()
  Invoke-Checked 'initialize isolated cluster' $initdb @('-D',$cluster,'-U','postgres','--auth=scram-sha-256',"--pwfile=$pwfile",'--encoding=UTF8','--no-locale')
  $startAttempted = $true
  Invoke-Checked 'start isolated cluster' $ctl @('-D',$cluster,'-l',$log,'-o',"-h 127.0.0.1 -p $port",'-w','start')
  $started = $true
  $actualDirectory = Invoke-Query 'show data_directory'
  if ([IO.Path]::GetFullPath($actualDirectory).TrimEnd('\') -ine [IO.Path]::GetFullPath($cluster).TrimEnd('\')) { throw 'Connected cluster directory mismatch' }
  Invoke-Checked 'apply synthetic auth fixtures' $psql @('-X','-h','127.0.0.1','-p',"$port",'-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-f',(Join-Path $root 'supabase/tests/local_checkpoint/auth_fixture.sql'))
  Invoke-Checked 'apply checkpoint migration' $psql @('-X','-h','127.0.0.1','-p',"$port",'-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-f',(Join-Path $root 'supabase/migrations/20261031211819_reading_checkpoints.sql'))
  Invoke-Checked 'run existing checkpoint SQL test' $psql @('-X','-h','127.0.0.1','-p',"$port",'-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-f',(Join-Path $root 'supabase/tests/20261031211819_reading_checkpoints_test.sql'))
  Invoke-Checked 'run additional authorization and replay SQL tests' $psql @('-X','-h','127.0.0.1','-p',"$port",'-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1','-f',(Join-Path $root 'supabase/tests/local_checkpoint/extra_checks.sql'))
  [void](Invoke-Query "insert into auth.users(id) values ('81000000-0000-0000-0000-000000000004')")
  $a = Start-Psql 'checkpoint_race_a'; $processes += $a
  $a.StandardInput.WriteLine("begin; select set_config('request.jwt.claims','{""sub"":""81000000-0000-0000-0000-000000000004""}',true); set local role authenticated; select public.put_quran_reading_checkpoint(100,0,'82000000-0000-0000-0000-000000000021','81000000-0000-0000-0000-000000000004');")
  $a.StandardInput.Flush()
  Wait-DatabaseCondition "select count(*) from pg_stat_activity where application_name='checkpoint_race_a' and state='idle in transaction'" 'first writer holding transaction'
  $b = Start-Psql 'checkpoint_race_b'; $processes += $b
  $b.StandardInput.WriteLine("begin; select set_config('request.jwt.claims','{""sub"":""81000000-0000-0000-0000-000000000004""}',true); set local role authenticated; select public.put_quran_reading_checkpoint(200,0,'82000000-0000-0000-0000-000000000022','81000000-0000-0000-0000-000000000004'); commit; \q")
  $b.StandardInput.Close()
  Wait-DatabaseCondition "select count(*) from pg_stat_activity where application_name='checkpoint_race_b' and wait_event_type='Lock' and wait_event='advisory'" 'second writer waiting on advisory lock'
  $a.StandardInput.WriteLine('commit;')
  $a.StandardInput.WriteLine('\q')
  $a.StandardInput.Close()
  if (!$a.WaitForExit(15000) -or !$b.WaitForExit(15000)) { throw 'Race child did not finish' }
  $aOut = $a.StandardOutput.ReadToEnd(); $aErr = $a.StandardError.ReadToEnd()
  $bOut = $b.StandardOutput.ReadToEnd(); $bErr = $b.StandardError.ReadToEnd()
  if ($a.ExitCode -ne 0 -or $b.ExitCode -ne 0) { throw "Race psql failed: $aErr $bErr" }
  if (!$aOut.Contains('accepted') -or !$bOut.Contains('conflict')) { throw 'Race did not yield accepted then conflict' }
  $outcome = Invoke-Query "select page_number || ':' || revision from public.quran_reading_checkpoints where user_id='81000000-0000-0000-0000-000000000004'"
  if ($outcome -ne '100:1') { throw "Race final state mismatch: $outcome" }
  Write-Host 'PASS coordinated multi-connection advisory-lock CAS race (accepted, conflict, final 100:1)'
  Write-Host 'PASS local PostgreSQL verification; synthetic auth GUC fixtures only, not live Supabase Auth or PostgREST'
} finally {
  foreach ($child in $processes) {
    if (!$child.HasExited) { $child.Kill(); $child.WaitForExit() }
    $child.Dispose()
  }
  if (!$started -and $startAttempted) {
    & $ctl -D $cluster status *> $null
    $started = $LASTEXITCODE -eq 0
  }
  if ($started) {
    & $ctl -D $cluster -m fast -w stop
    if ($LASTEXITCODE -ne 0) { Write-Error 'Could not stop the disposable cluster' }
    else { Write-Host 'PASS stop disposable cluster (exit 0)' }
  }
  if (Test-Path -LiteralPath $pwfile) { Remove-Item -LiteralPath $pwfile -Force }
  $env:PGPASSWORD = $oldPassword
  $env:PGOPTIONS = $oldOptions
  $env:PGSERVICE = $oldService
}
