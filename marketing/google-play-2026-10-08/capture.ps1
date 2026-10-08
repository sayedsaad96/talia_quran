param([string]$Name,[int]$X=-1,[int]$Y=-1,[switch]$Back,[switch]$Scroll)
$ErrorActionPreference='Stop'
$adb='D:/Android/Sdk/platform-tools/adb.exe'
if($X -ge 0){& $adb -s emulator-5554 shell input tap $X $Y}
if($Back){& $adb -s emulator-5554 shell input keyevent 4}
if($Scroll){& $adb -s emulator-5554 shell input swipe 560 1550 560 550 450}
Start-Sleep -Milliseconds 900
& $adb -s emulator-5554 shell uiautomator dump /sdcard/talia_design.xml | Out-Null
& $adb -s emulator-5554 pull /sdcard/talia_design.xml (Join-Path $PSScriptRoot "evidence/$Name.xml") 2>&1 | Out-Null
& $adb -s emulator-5554 shell screencap -p /sdcard/talia_design.png
& $adb -s emulator-5554 pull /sdcard/talia_design.png (Join-Path $PSScriptRoot "raw/$Name.png") 2>&1 | Out-Null
[xml]$ui=Get-Content -LiteralPath (Join-Path $PSScriptRoot "evidence/$Name.xml")
$ui.SelectNodes('//node') | Where-Object { $_.'content-desc' -or $_.text } | ForEach-Object { '{0}{1} {2}' -f $_.text,$_.'content-desc',$_.bounds }
