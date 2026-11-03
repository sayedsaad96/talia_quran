param([string]$ArchiveDir = '.tmp/content-review/b1-2026-11-03')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$out = 'assets/data/quran_study'
New-Item -ItemType Directory -Force $out | Out-Null
function Read-ZipEntry($zip, $name) {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq $name }
  if (-not $entry) { throw "Missing archive entry: $name" }
  $stream = $entry.Open()
  try { $reader = [IO.StreamReader]::new($stream, $utf8); try { return $reader.ReadToEnd() } finally { $reader.Dispose() } } finally { $stream.Dispose() }
}
function Save-Bundle($name, $blocks) {
  $json = ConvertTo-Json -InputObject ([ordered]@{blocks = @($blocks)}) -Depth 8 -Compress
  [IO.File]::WriteAllText((Join-Path (Resolve-Path $out) $name), $json, $utf8)
}
$counts = @{}
Get-Content -Raw -Encoding utf8 assets/data/surahs.json | ConvertFrom-Json | ForEach-Object { $counts[[int]$_.id] = [int]$_.ayahCount }
function Assert-Coverage($blocks) {
  $seen = @{}
  foreach ($b in $blocks) {
    $s = [int]$b.surahId; $a = [int]$b.fromAyah; $key = "$s`:$a"
    if (!$counts.ContainsKey($s) -or $a -lt 1 -or $a -gt $counts[$s] -or $b.toAyah -ne $a -or $seen.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($b.text)) { throw "Invalid mapping or empty content: $key" }
    $seen[$key] = $true
  }
  foreach ($s in $counts.Keys) { for ($a=1; $a -le $counts[$s]; $a++) { if (!$seen.ContainsKey("$s`:$a")) { throw "Missing $s`:$a" } } }
}
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path (Join-Path $ArchiveDir 'hafs_tafseerMouaser_v3.zip')))
try {
  $csv = Read-ZipEntry $zip 'hafs_tafseerMouaser_v3_data/tafseerMouaser_v03.csv'
  $rows = @($csv | ConvertFrom-Csv)
  $blocks = @($rows | ForEach-Object { [ordered]@{blockId="tafsir-$($_.id)"; surahId=[int]$_.sura_no; fromAyah=[int]$_.aya_no; toAyah=[int]$_.aya_no; text=$_.aya_tafseer; footnotes=@()} })
  Assert-Coverage $blocks
  Save-Bundle 'tafsir_ar.json' $blocks
  $saved = (Get-Content -Raw -Encoding utf8 (Join-Path $out 'tafsir_ar.json') | ConvertFrom-Json).blocks
  for ($i = 0; $i -lt $rows.Count; $i++) { if ($saved[$i].text -cne $rows[$i].aya_tafseer -or $saved[$i].blockId -cne "tafsir-$($rows[$i].id)" -or $saved[$i].surahId -ne [int]$rows[$i].sura_no -or $saved[$i].fromAyah -ne [int]$rows[$i].aya_no) { throw "Tafsir fidelity mismatch at row $i" } }
  $font = $zip.Entries | Where-Object FullName -eq 'hafs_tafseerMouaser_v3_fonts/uthmanic_hafs_v20.ttf'
  if (!$font) { throw 'Font missing' }
  [IO.Compression.ZipFileExtensions]::ExtractToFile($font, (Join-Path (Resolve-Path $out) 'uthmanic_hafs_v20.ttf'), $true)
} finally { $zip.Dispose() }
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path (Join-Path $ArchiveDir 'english_rwwad-1.0.20.zip')))
$temp = Join-Path ([IO.Path]::GetTempPath()) ("talia-study-" + [Guid]::NewGuid().ToString() + '.sqlite')
try {
  $entry = $zip.Entries | Where-Object FullName -eq 'english_rwwad.sqlite'
  if (!$entry) { throw 'Translation database missing' }
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $temp)
  $info = [Diagnostics.ProcessStartInfo]::new()
  $info.FileName = (Get-Command sqlite3.exe).Source
  $info.ArgumentList.Add('-json'); $info.ArgumentList.Add($temp); $info.ArgumentList.Add('select id,sura,aya,translation,footnotes from translations order by id')
  $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true; $info.StandardOutputEncoding = $utf8; $info.UseShellExecute = $false
  $process = [Diagnostics.Process]::Start($info); $json = $process.StandardOutput.ReadToEnd(); $err = $process.StandardError.ReadToEnd(); $process.WaitForExit()
  if ($process.ExitCode -ne 0) { throw "SQLite failed: $err" }
  $rows = @($json | ConvertFrom-Json)
  $blocks = @($rows | ForEach-Object { $notes = @(if (![string]::IsNullOrEmpty($_.footnotes)) { [string]$_.footnotes }); [ordered]@{blockId="translation-$($_.id)"; surahId=[int]$_.sura; fromAyah=[int]$_.aya; toAyah=[int]$_.aya; text=$_.translation; footnotes=$notes} })
  Assert-Coverage $blocks
  Save-Bundle 'translation_en.json' $blocks
  $saved = (Get-Content -Raw -Encoding utf8 (Join-Path $out 'translation_en.json') | ConvertFrom-Json).blocks
  for ($i = 0; $i -lt $rows.Count; $i++) { $expectedNotes = if ([string]::IsNullOrEmpty($rows[$i].footnotes)) { 0 } else { 1 }; if ($saved[$i].text -cne $rows[$i].translation -or $saved[$i].blockId -cne "translation-$($rows[$i].id)" -or $saved[$i].surahId -ne $rows[$i].sura -or $saved[$i].fromAyah -ne $rows[$i].aya -or $saved[$i].footnotes.Count -ne $expectedNotes -or ($expectedNotes -eq 1 -and $saved[$i].footnotes[0] -cne $rows[$i].footnotes)) { throw "Translation fidelity mismatch at row $i" } }
} finally { $zip.Dispose(); if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp } }
Write-Output 'Generated both bundles with complete, unique ayah mappings.'
$manifest = Get-Content -Raw -Encoding utf8 'tool/content/study_manifest.template.json' | ConvertFrom-Json
$manifest.tafsir.sha256 = (Get-FileHash (Join-Path $out 'tafsir_ar.json') -Algorithm SHA256).Hash.ToLowerInvariant()
$manifest.meaningTranslation.sha256 = (Get-FileHash (Join-Path $out 'translation_en.json') -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path (Resolve-Path $out) 'study_manifest.json'), (ConvertTo-Json -InputObject $manifest -Depth 5), $utf8)
