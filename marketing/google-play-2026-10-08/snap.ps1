param([string]$Name,[int]$X=-1,[int]$Y=-1,[switch]$Back)
$adb='D:/Android/Sdk/platform-tools/adb.exe'
if($X -ge 0){& $adb -s emulator-5554 shell input tap $X $Y}
if($Back){& $adb -s emulator-5554 shell input keyevent 4}
Start-Sleep -Milliseconds 1000
& $adb -s emulator-5554 shell screencap -p /sdcard/talia_design.png
& $adb -s emulator-5554 pull /sdcard/talia_design.png (Join-Path $PSScriptRoot "raw/$Name.png") 2>&1 | Out-Null
Write-Output $Name
