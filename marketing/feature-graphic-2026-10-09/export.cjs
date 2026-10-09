const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const deps = 'C:/Users/Sayed Saad/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const { chromium } = require(path.join(deps, 'playwright'));
const sharp = require(path.join(deps, 'sharp'));
const root = __dirname;
const repo = path.resolve(root, '../..');
function data(file, mime) { return `data:${mime};base64,${fs.readFileSync(path.join(repo, file)).toString('base64')}`; }
const font = data('assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf', 'font/ttf');
const logo = data('assets/images/logo_new.png', 'image/png');
const adult = data('marketing/google-play-2026-10-08/raw/02-quran-index.png', 'image/png');
const kids = data('marketing/google-play-2026-10-08/raw/53-current-kids.png', 'image/png');
const html = `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=1024,initial-scale=1"><title>تالية القرآن — رحلة مع القرآن لكل العائلة</title><style>
@font-face{font-family:Reem;src:url('${font}') format('truetype');font-weight:400 700;font-display:block}
*{box-sizing:border-box}html,body{margin:0;width:1024px;height:500px;overflow:hidden}body{font-family:Reem,sans-serif;color:#153d32;background:#fffcf2}
#canvas{position:relative;width:1024px;height:500px;overflow:hidden;background:#fffcf2;isolation:isolate}
.pattern{position:absolute;inset:0;z-index:-3;opacity:.25;background-size:100px 100px;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100' viewBox='0 0 100 100'%3E%3Cpath d='M50 0L60 40L100 50L60 60L50 100L40 60L0 50L40 40ZM25 25L50 30L75 25L70 50L75 75L50 70L25 75L30 50Z' stroke='%23c4a365' fill='none' stroke-width='.45' opacity='.4'/%3E%3C/svg%3E")}
.wash{position:absolute;z-index:-2;left:-80px;top:-75px;width:640px;height:650px;background:radial-gradient(ellipse,#e5ecdd 0%,#f0f2e5 40%,transparent 69%)}
.arch{position:absolute;left:53px;top:44px;width:415px;height:426px;border:1px solid #c4a36566;border-radius:220px 220px 18px 18px;z-index:-1}
.arch:after{content:'';position:absolute;inset:10px;border:1px solid #c4a36530;border-radius:inherit}
.screen{position:absolute;display:block;overflow:hidden;border-radius:13px;box-shadow:0 17px 34px #1b362b26,0 3px 8px #1b362b15;outline:1px solid #ffffffb3}
.screen img{width:100%;height:auto;display:block}
.adult{left:76px;top:107px;width:186px;transform:rotate(-6deg);z-index:1}
.kids{left:272px;top:73px;width:192px;transform:rotate(5deg);z-index:2}
.brand{position:absolute;right:64px;top:68px;display:flex;align-items:center;gap:12px;height:42px;font-size:23px;font-weight:700}
.brand img{width:40px;height:40px;border-radius:9px;display:block}
.copy{position:absolute;right:64px;top:145px;width:432px;text-align:right}
h1{margin:0;font-size:52px;line-height:1.5;font-weight:700;letter-spacing:0}
.rule{width:60px;height:2px;background:#b99551;margin-top:24px;margin-bottom:18px}
p{font-size:25px;line-height:1.7;color:#605b47;font-weight:500;margin:0}
.accent{position:absolute;left:474px;top:39px;width:5px;height:5px;transform:rotate(45deg);background:#b9955177}
</style></head><body><main id="canvas" aria-label="تالية القرآن، رحلة مع القرآن لكل العائلة"><div class="pattern"></div><div class="wash"></div><div class="arch"></div><div class="accent"></div><div class="screen adult"><img src="${adult}" alt="فهرس القرآن في تالية"></div><div class="screen kids"><img src="${kids}" alt="مسار الأطفال في تالية"></div><div class="brand"><img src="${logo}" alt="شعار تالية الأصلي"><span>تالية القرآن</span></div><div class="copy"><h1>رحلة مع القرآن<br>لكل العائلة</h1><div class="rule"></div><p>قراءة • حفظ • تعلّم</p></div></main></body></html>`;
async function main() {
  fs.writeFileSync(path.join(root,'talia-feature-graphic-editable.html'), html);
  const browser = await chromium.launch({headless:true,channel:'chrome'});
  const page = await browser.newPage({viewport:{width:1024,height:500},deviceScaleFactor:1});
  await page.goto(pathToFileURL(path.join(root,'talia-feature-graphic-editable.html')).href);
  await page.evaluate(()=>document.fonts.ready);
  await page.locator('img').evaluateAll(imgs=>Promise.all(imgs.map(i=>i.decode())));
  const check = await page.evaluate(()=>({headline:document.querySelector('h1').innerText,copy:document.querySelector('p').innerText,fontLoaded:document.fonts.check('700 52px Reem'),overflow:document.documentElement.scrollWidth>1024||document.documentElement.scrollHeight>500,images:[...document.images].map(i=>({loaded:i.complete&&i.naturalWidth>0,width:i.naturalWidth,height:i.naturalHeight})),bounds:[...document.querySelectorAll('.screen,.brand,.copy')].map(el=>{const b=el.getBoundingClientRect();return {element:el.className,x:b.x,y:b.y,right:b.right,bottom:b.bottom}})}));
  if(!check.fontLoaded||check.overflow||check.images.some(i=>!i.loaded)||check.bounds.some(b=>b.x<39||b.y<39||b.right>985||b.bottom>461))throw new Error(JSON.stringify(check));
  const png = path.join(root,'talia-feature-graphic-1024x500.png');
  await sharp(await page.screenshot()).removeAlpha().toColourspace('srgb').png().toFile(png);
  const metadata = await sharp(png).metadata();
  if(metadata.width!==1024||metadata.height!==500||metadata.channels!==3||metadata.hasAlpha)throw new Error('Invalid PNG format');
  await sharp(png).resize(512,250).png().toFile(path.join(root,'small-preview.png'));
  fs.writeFileSync(path.join(root,'validation.json'), JSON.stringify({...check,format:metadata.format,width:metadata.width,height:metadata.height,channels:metadata.channels,hasAlpha:metadata.hasAlpha,bytes:fs.statSync(png).size},null,2));
  await browser.close();
  console.log(JSON.stringify({...check,width:metadata.width,height:metadata.height,channels:metadata.channels,bytes:fs.statSync(png).size}));
}
main().catch(e=>{console.error(e);process.exit(1)});
