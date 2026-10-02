param([string]$Name,[int]$X=-1,[int]$Y=-1,[switch]$Back,[switch]$Screenshot,[switch]$Scroll)
$ErrorActionPreference='Stop'
$adbTool='D:\Android\Sdk\platform-tools\adb.exe'
$device='127.0.0.1:5555'
if($X -ge 0) { & $adbTool -s $device shell input tap $X $Y }
if($Back) { & $adbTool -s $device shell input keyevent 4 }
if($Scroll) { & $adbTool -s $device shell input swipe 550 1530 550 550 350 }
& $adbTool -s $device shell uiautomator dump /sdcard/talia_audit_ui.xml | Out-Null
$xmlFile=Join-Path $PSScriptRoot ($Name+'.xml')
& $adbTool -s $device pull /sdcard/talia_audit_ui.xml $xmlFile 2>&1 | Out-Null
[xml]$ui=Get-Content -LiteralPath $xmlFile
$ui.SelectNodes('//node') | Where-Object { $_.'content-desc' -or $_.text } | ForEach-Object { '{0}{1} {2}' -f $_.text,$_.'content-desc',$_.bounds }
if($Screenshot) { & $adbTool -s $device shell screencap -p /sdcard/talia_audit.png; & $adbTool -s $device pull /sdcard/talia_audit.png (Join-Path $PSScriptRoot ($Name+'.png')) 2>&1 | Out-Null }
