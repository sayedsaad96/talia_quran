param(
    [string]$Sdk = 'D:\Android\Sdk',
    [string]$Jdk = 'D:\Android Studio\jbr',
    [string]$BuildToolsVersion = '37.0.0',
    [string]$Platform = 'android-37.0',
    [string]$DebugKeystore = "$env:USERPROFILE\.android\debug.keystore",
    [string]$Serial = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$work = Join-Path $root 'build\secure-storage-regression'
$androidJar = Join-Path $Sdk "platforms\$Platform\android.jar"
$tools = Join-Path $Sdk "build-tools\$BuildToolsVersion"
$adb = Join-Path $Sdk 'platform-tools\adb.exe'
$javac = Join-Path $Jdk 'bin\javac.exe'
$jar = Join-Path $Jdk 'bin\jar.exe'
$source = Join-Path $root 'packages\flutter_secure_storage\android\src\androidTest\java\com\talia\diagnostics\SecureStorageRegression.java'
$testPackage = 'com.talia.quran.securestoragetest'
$runner = "$testPackage/com.talia.diagnostics.SecureStorageRegression"
$namespace = 'talia_secure_storage_test_' + [Guid]::NewGuid().ToString('N')
$adbArgs = @()
if ($Serial) { $adbArgs = @('-s', $Serial) }

function Check-Exit([string]$step) {
    if ($LASTEXITCODE -ne 0) { throw "$step failed (exit $LASTEXITCODE)" }
}

function Run-Phase([string]$phase) {
    $output = & $adb @adbArgs shell am instrument -w -r -e namespace $namespace -e phase $phase $runner 2>&1
    Check-Exit "Instrumentation $phase"
    $text = $output -join "`n"
    if ($text -notmatch 'INSTRUMENTATION_RESULT: result=PASS' -or $text -notmatch 'INSTRUMENTATION_CODE: -1') {
        throw "Instrumentation $phase failed: $text"
    }
    if ($phase -eq 'verify') {
        if ($text -notmatch 'default_data_unchanged=true' -or $text -notmatch 'default_keys_unchanged=true') {
            throw 'Default storage comparison did not pass.'
        }
        Write-Host 'Default data unchanged: true; default key storage unchanged: true'
    }
    Write-Host "$phase passed"
}

New-Item -ItemType Directory -Force -Path $work, "$work\classes", "$work\dex" | Out-Null
$manifest = @'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.talia.quran.securestoragetest">
  <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="28"/>
  <application android:label="Secure storage regression" android:debuggable="true"/>
  <instrumentation android:name="com.talia.diagnostics.SecureStorageRegression" android:targetPackage="com.talia.quran" android:functionalTest="true"/>
</manifest>
'@
[System.IO.File]::WriteAllText((Join-Path $work 'AndroidManifest.xml'), $manifest)
& $javac -source 8 -target 8 -bootclasspath $androidJar -d "$work\classes" $source
Check-Exit 'Java compilation'
& (Join-Path $tools 'd8.bat') --min-api 24 --lib $androidJar --output "$work\dex" "$work\classes\com\talia\diagnostics\SecureStorageRegression.class"
Check-Exit 'Dex compilation'
& (Join-Path $tools 'aapt2.exe') link -I $androidJar --manifest "$work\AndroidManifest.xml" -o "$work\unsigned.apk"
Check-Exit 'Test APK packaging'
Push-Location "$work\dex"
try {
    & $jar uf "$work\unsigned.apk" classes.dex
    Check-Exit 'Adding dex'
} finally { Pop-Location }
& (Join-Path $tools 'apksigner.bat') sign --ks $DebugKeystore --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out "$work\test.apk" "$work\unsigned.apk"
Check-Exit 'Test APK signing'

$installed = $false
try {
    & $adb @adbArgs install -t -r "$work\test.apk"
    Check-Exit 'Installing test APK'
    $installed = $true
    Run-Phase 'seed'
    Run-Phase 'verify'
} finally {
    if ($installed) {
        try { Run-Phase 'cleanup' } catch { Write-Warning "Fixture cleanup failed: $_" }
        & $adb @adbArgs uninstall $testPackage | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not uninstall the test APK.' }
    }
}
