param([string]$Name,[int]$X=-1,[int]$Y=-1,[switch]$Back,[switch]$Scroll,[switch]$NoXml,[string]$Device='127.0.0.1:5555')
$ErrorActionPreference='Stop'
$adbTool='D:\Android\Sdk\platform-tools\adb.exe'
if($X -ge 0) { & $adbTool -s $device shell input tap $X $Y }
if($Back) { & $adbTool -s $device shell input keyevent 4 }
if($Scroll) { & $adbTool -s $device shell input swipe 550 1500 550 550 400 }
Start-Sleep -Milliseconds 900
if (!$NoXml) {
& $adbTool -s $device shell uiautomator dump /sdcard/talia_marketing.xml | Out-Null
& $adbTool -s $device pull /sdcard/talia_marketing.xml (Join-Path $PSScriptRoot "evidence\$Name.xml") 2>&1 | Out-Null
[xml]$ui=Get-Content (Join-Path $PSScriptRoot "evidence\$Name.xml")
$ui.SelectNodes('//node') | Where-Object { $_.'content-desc' -or $_.text } | ForEach-Object { '{0}{1} {2}' -f $_.text,$_.'content-desc',$_.bounds }
}
& $adbTool -s $device shell screencap -p /sdcard/talia_marketing.png
& $adbTool -s $device pull /sdcard/talia_marketing.png (Join-Path $PSScriptRoot "evidence\$Name.png") 2>&1 | Out-Null
