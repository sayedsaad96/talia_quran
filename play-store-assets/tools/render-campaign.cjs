/* Render only original runtime screenshots. Quran and UI remain raster pixels. */
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const deps = process.env.TALIA_NODE_MODULES || 'C:/Users/Sayed Saad/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const { chromium } = require(path.join(deps, 'playwright'));
const sharp = require(path.join(deps, 'sharp'));
const root = path.resolve(__dirname, '..');
const repo = path.resolve(root, '..');
const plans = [
  {id:'01-talia-hero', source:'clean-home', screen:'الصفحة الرئيسية للأطفال', feature:'رفيقة التعلم، المهمة الحالية، المصحف ورحلة الحفظ', message:'عالم قرآني يومي يرحب بالطفل', title:['رحلة قرآنية','يحبّها طفلك'], theme:'mint', x:90, y:402, w:900, crop:[32,1792], mascot:'talia_wave', concept:'واجهة كبيرة وشخصية تاليا خارجها؛ الدخول إلى عالم الطفل', focus:'رفيقة الطفل والمهمة الحالية وأزرار الرحلة والمصحف'},
  {id:'02-talia-journey', source:'clean-map', screen:'خريطة الحفظ', feature:'بيوت حفظ متتابعة ومراحل مغلقة إلى حين التقدم', message:'الحفظ مسار مرئي يمكن اكتشافه خطوة بخطوة', title:['الحفظ رحلة','مليئة بالاكتشاف'], theme:'night', x:40, y:468, w:1000, crop:[440,1780], concept:'تكبير الخريطة حتى تظهر المرحلة الحالية والتالية كاملتين', focus:'بيت الحفظ 1 والمسار إلى البيت 2'},
  {id:'03-talia-listen-repeat', source:'clean-listen-ready', screen:'استمع وكرر', feature:'الاستماع للآية والتكرار ثم الانتقال إلى التذكر', message:'ابدأ التعلم بالاستماع والترديد', title:['اسمع وردّد','خطوة بخطوة'], theme:'honey', x:70, y:380, w:940, crop:[0,1710], concept:'واجهة كاملة حتى زر تجربة الذاكرة؛ نغمات عسلية تدعم لون الاستماع', focus:'الآية، مؤشر التكرار وزر التشغيل'},
  {id:'04-talia-kids-mushaf', source:'clean-reader', screen:'مصحف الأطفال', feature:'قراءة صفحة القرآن والاستماع إليها وتسجيل قراءتها', message:'مساحة واضحة للقراءة بهدوء', title:['اقرأ القرآن','على مهلك'], theme:'teal', x:40, y:420, w:1000, crop:[480,1910], concept:'قص الفراغ أعلى صفحة المصحف؛ إبقاء السورة كاملة وأزرار الصفحة', focus:'سورة الفاتحة كاملة بأرقام الآيات ومؤشر القراءة والاستماع'},
  {id:'05-talia-recall', source:'clean-recall', screen:'التذكر والتلاوة', feature:'محاولة تذكر الآية مع التسجيل وطلب البداية', message:'انتقل من الترديد إلى محاولة الحفظ', title:['جرّب الحفظ','من ذاكرتك'], theme:'lavender', x:105, y:374, w:870, crop:[0,1840], concept:'عرض حالة إخفاء الآية كاملة؛ خلفية بنفسجية مرتبطة بزر الذاكرة', focus:'بطاقة التذكر، الميكروفون وزر أعطني البداية'},
  {id:'06-talia-treasures', source:'clean-treasures', screen:'كنوزي', feature:'مناطق التقدم في حفظ السور', message:'وجهات جديدة تنتظر التقدم في الرحلة', title:['كنوز تنتظر','رحلتك'], theme:'peach', x:50, y:435, w:980, crop:[0,1510], concept:'مناطق الكنوز الخمس كاملة مع حذف الفراغ أسفلها؛ ختام دافئ', focus:'أسماء المناطق وأشرطة التقدم الحقيقية دون اختلاق إنجاز'},
];
const colors = {
  mint:['#F3FAEE','#D2F1E4','#A8DBC9','#0B574D','#DDAA41'],
  night:['#124E47','#092E34','#0B3D3C','#FFF5DB','#EDC870'],
  honey:['#FFFAEB','#F4E2B5','#E9C879','#0B574D','#D99A26'],
  teal:['#176B60','#0D4F48','#267D6E','#FFF8E7','#E3C476'],
  lavender:['#F4F1FD','#DFD5F3','#C8BAE8','#0C564D','#9D78C1'],
  peach:['#FFF6E9','#F3DBC4','#E9C299','#0B574D','#DCA04D'],
};
const data = p => 'data:image/png;base64,'+fs.readFileSync(p).toString('base64');
for(const p of plans) fs.copyFileSync(path.join(root,'evidence',p.source+'.png'),path.join(root,'screenshots-raw',p.id+'.png'));
const font = fs.readFileSync(path.join(repo,'assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf')).toString('base64');
const spark = (x,y,size,color,rot=0) => `<svg class="spark" style="left:${x}px;top:${y}px;width:${size}px;height:${size}px;transform:rotate(${rot}deg)" viewBox="0 0 100 100"><path d="M50 2C56 34 66 44 98 50C66 56 56 66 50 98C44 66 34 56 2 50C34 44 44 34 50 2Z" fill="${color}"/></svg>`;
const slides = plans.map((p,i) => {
  const c=colors[p.theme], s=p.w/1080, h=(p.crop[1]-p.crop[0])*s;
  return `<section class="slide ${p.theme}" id="${p.id}" style="--bg:${c[0]};--end:${c[1]};--blob:${c[2]};--ink:${c[3]};--accent:${c[4]}">
    <div class="orb orb-a"></div><div class="orb orb-b"></div>
    <svg class="land" viewBox="0 0 1080 800"><path fill="${c[2]}" opacity=".35" d="M-120 670C40 260 324 980 650 485S1190 300 1250 520V850H-120Z"/><path fill="${c[0]}" opacity=".25" d="M-110 750C215 420 420 920 722 650S1080 650 1210 450V850H-110Z"/></svg>
    ${spark(66,105,30,c[4],10)}${spark(981,266,44,c[4],-8)}${spark(25,1280,20,c[4])}${spark(1010,1670,30,c[4])}
    <div class="brand" dir="rtl"><span>تاليا</span><i></i><b>TALIA</b></div>
    <h1 dir="rtl">${p.title[0]}<br><em>${p.title[1]}</em></h1>
    ${p.mascot?`<img class="mascot" src="${data(path.join(repo,'assets/images/talia',p.mascot+'.png'))}" alt="شخصية تاليا الأصلية"/>`:''}
    <div class="frame" style="left:${p.x}px;top:${p.y}px;width:${p.w}px;height:${h}px"><img class="ui" src="${data(path.join(root,'screenshots-raw',p.id+'.png'))}" style="width:${p.w}px;top:${-p.crop[0]*s}px" alt="${p.screen}"/></div>
    ${i===1?'<div class="trail"><span></span><span></span><span></span></div>':''}
  </section>`;
}).join('\n');
const html = `<!doctype html><html lang="ar"><head><meta charset="utf-8"><title>تاليا — حملة Google Play</title><style>
@font-face{font-family:Reem;src:url(data:font/ttf;base64,${font}) format('truetype');font-weight:400 700;font-display:block}
*{box-sizing:border-box}body{margin:0;background:#D8E0DC;font-family:Reem,sans-serif}.slide{position:relative;width:1080px;height:1920px;overflow:hidden;background:radial-gradient(ellipse at 48% 28%,var(--bg) 0,transparent 60%),linear-gradient(150deg,var(--bg),var(--end));margin:0 0 40px;isolation:isolate}.brand{position:absolute;top:52px;left:72px;right:72px;display:flex;justify-content:center;align-items:center;gap:16px;color:var(--ink)}.brand span{font-size:43px;font-weight:700;line-height:1.4}.brand b{font:600 19px Arial,sans-serif;letter-spacing:5px}.brand i{height:23px;width:2px;background:var(--ink);opacity:.25}h1{position:absolute;left:72px;right:72px;top:145px;margin:0;text-align:center;font-size:86px;font-weight:700;line-height:1.28;color:var(--ink);z-index:3}h1 em{font-style:normal}.mint h1{left:230px;right:70px;font-size:80px;top:156px}.mascot{position:absolute;left:37px;top:165px;width:185px;height:185px;object-fit:contain;z-index:3}.frame{position:absolute;overflow:hidden;border-radius:44px;box-shadow:0 20px 60px #163E3429,0 0 0 9px #FFFFFF99;z-index:2}.ui{position:absolute;left:0;height:auto;display:block}.orb{position:absolute;border-radius:50%;border:2px solid #FFFFFF66;pointer-events:none}.orb-a{width:580px;height:580px;top:-310px;right:-200px;background:radial-gradient(circle at 40% 50%,#ffffff55,transparent)}.orb-b{width:950px;height:950px;bottom:-540px;left:-400px;background:radial-gradient(circle at 70% 10%,#ffffff77,transparent)}.land{position:absolute;bottom:-50px;width:100%;height:800px;z-index:-1}.spark{position:absolute;z-index:1}.night .frame,.teal .frame{box-shadow:0 24px 72px #001F2C45,0 0 0 8px #F6D99488}.trail{position:absolute;bottom:116px;left:380px;display:flex;gap:32px;align-items:center}.trail span{width:30px;height:30px;transform:rotate(45deg);border-radius:7px;background:var(--accent)}.trail span:nth-child(2){width:44px;height:44px}.trail span:last-child{opacity:.5}
@media print{.slide{margin:0;break-after:page}}
</style></head><body>${slides}</body></html>`;
fs.writeFileSync(path.join(root,'campaign.html'),html);
fs.writeFileSync(path.join(root,'campaign-plan.json'),JSON.stringify(plans,null,2));
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,args:['--allow-file-access-from-files']});
 const page=await browser.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
 await page.goto(pathToFileURL(path.join(root,'campaign.html')).href);
 await page.evaluate(async()=>{await document.fonts.ready;await Promise.all(Array.from(document.images).map(img=>img.decode()));});
 const results=[];
 for(const p of plans){
   const buffer=await page.locator('[id="'+p.id+'"]').screenshot({animations:'disabled'});
   const out=path.join(root,'screenshots-final',p.id+'.png');
   await sharp(buffer).removeAlpha().png({compressionLevel:9}).toFile(out);
   const m=await sharp(out).metadata();
   if(m.width!==1080||m.height!==1920||m.hasAlpha||fs.statSync(out).size>8*1024*1024) throw Error('Invalid export '+p.id);
   results.push({file:p.id+'.png',width:m.width,height:m.height,channels:m.channels,bytes:fs.statSync(out).size});
 }
 await browser.close();
 const contact=[];
 for(let i=0;i<plans.length;i++) contact.push({input:await sharp(path.join(root,'screenshots-final',plans[i].id+'.png')).resize(360,640).toBuffer(),left:(i%3)*384+24,top:Math.floor(i/3)*664+24});
 await sharp({create:{width:1176,height:1352,channels:3,background:'#E8EDE6'}}).composite(contact).png().toFile(path.join(root,'campaign-preview.png'));
 const strip=[];
 for(let i=0;i<plans.length;i++) strip.push({input:await sharp(path.join(root,'screenshots-final',plans[i].id+'.png')).resize(270,480).toBuffer(),left:i*282+12,top:12});
 await sharp({create:{width:1704,height:504,channels:3,background:'#E8EDE6'}}).composite(strip).png().toFile(path.join(root,'campaign-strip.png'));
 fs.writeFileSync(path.join(root,'export-validation.json'),JSON.stringify(results,null,2));
 console.log(JSON.stringify(results,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
