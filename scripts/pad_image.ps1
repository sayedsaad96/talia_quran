Add-Type -AssemblyName System.Drawing
$srcPath = "assets\images\splash.png"
$destPath = "assets\images\splash_android12.png"
$img = [System.Drawing.Image]::FromFile((Resolve-Path $srcPath).Path)
$newWidth = [int]($img.Width * 1.5)
$newHeight = [int]($img.Height * 1.5)
$bmp = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$g.DrawImage($img, [int](($newWidth - $img.Width)/2), [int](($newHeight - $img.Height)/2), $img.Width, $img.Height)
$g.Dispose()
$bmp.Save((Join-Path (Get-Location).Path $destPath), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$img.Dispose()
