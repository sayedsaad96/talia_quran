param([int]$Start=2,[int]$End=5)
$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$plan=Get-Content -LiteralPath (Join-Path $root 'campaign-plan.json') -Raw|ConvertFrom-Json
$assets=@(Get-Content -LiteralPath (Join-Path $root 'superdesign-assets.json') -Raw|ConvertFrom-Json)
$assets += [pscustomobject]@{name='04-reader-clean';asset=[pscustomobject]@{nodeId='63e0a8b4-9d47-4997-9120-e247b3445308';url='https://vgbujcuwptvheqijyjbe.supabase.co/storage/v1/object/public/hmac-uploads/projects/1e8d0a36-f2e3-4302-b966-9a9a009d58e9/content-assets/2866b701e660781d85b20661e3b6c833bbaf395805c5a429eea63820821892fc/04-reader-clean.png'}}
$argsList=@('--yes','@superdesign/cli@latest','iterate-design-draft','--draft-id','50633c49-4269-41dc-8748-afad0b096ab6','--mode','branch','--device','custom','--width','1080','--height','1920','--user-request','اعتمد الصور','--json')
$refs=@('talia-official-logo')
foreach($slide in $plan.slides|Where-Object {$_.id -ge $Start -and $_.id -le $End}){
$a=($assets|Where-Object name -eq $slide.source).asset
$palette=switch($slide.theme){'cream' {'warm ivory #FFF8E7 background, deep emerald #073E37 headline, muted teal support, restrained gold accents'};'mint' {'pale mint #E5F5E8 background, deep emerald headline, warm gold small accents, joyful but restrained'};'honey' {'warm honey cream #FFF4D8 background, deep emerald headline, gold accents'};'navy' {'midnight navy #101D3D background, ivory headline, warm gold accents, subtle star points'};default {'deep emerald #073E37 background, ivory headline, muted gold support'}}
$headline=$slide.headline.Replace("`n",' / ')
$prompt="Separate poster $($slide.id.ToString('00')) $($slide.screen), 1080x1920. Inherit base typography, arches, brand logo and spacing. Palette: $palette. EXACT headline (two lines): $headline. EXACT support: $($slide.support). EXACT screenshot img: $($a.url). Preserve original pixels, proportions, Quran and numbers; no redrawn UI. Large straight screenshot in thin frame y570–1870, fully inside canvas, no clipped text or controls. Headline90px RTL Reem Kufi, support32px, margins72px. Editable HTML promotional text. No CTA, webpage chrome, animation or invented rewards. Only uniform image scaling/cropping blank space or48px statusbar allowed. Keep Quran complete. Audience $($slide.audience)."
if($slide.secondary){$sec=($assets|Where-Object name -eq $slide.secondary).asset;$prompt += " Optional small inset of actual task overview using this exact screenshot: $($sec.url); if used, keep the primary listening screenshot dominant and do not cover Quran.";$refs += $sec.nodeId}
$argsList += @('-p',$prompt);$refs += $a.nodeId
}
$argsList += @('--reference-id')+$refs
$out=& npx @argsList
if($LASTEXITCODE -ne 0){throw 'Design batch failed; do not retry automatically'}
$out|Set-Content -LiteralPath (Join-Path $root "designs/batch-$Start-$End.json") -Encoding utf8
$out
