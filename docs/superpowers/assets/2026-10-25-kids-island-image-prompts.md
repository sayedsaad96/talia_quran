# صور جزر رحلة القرآن للأطفال: أوامر التوليد

هذا الملف يخص المهمة 6 من خطة [إعادة تصميم رحلة القرآن](../plans/2026-10-25-kids-quran-journey-redesign.md).

الشاشة تعرض جزيرة واحدة في كل صف، وتتناوب ثماني جزر بالترتيب. الكود جاهز، ويقرأ الصور من المسارات المذكورة أدناه. إذا غابت صورة، يبقى مكانها فارغًا ولا تتعطل الشاشة.

## المواصفات المطلوبة لكل صورة

| البند | القيمة |
|---|---|
| الصيغة | PNG بخلفية **شفافة** |
| المقاس | 512 × 512 بكسل، مربعة. يمكن توليدها أكبر وسأصغّرها |
| التكوين | جزيرة واحدة في المنتصف، مع هامش فارغ حولها من كل الجهات |
| الإضاءة | نهارية محايدة، **بلا توهج** مرسوم داخل الصورة. التطبيق يضيف التوهج ليلًا بالكود |
| الأسلوب | واحد في الصور الثماني: جزيرة صخرية طائرة، سطحها عشب، بأسلوب كرتوني ثنائي ونصف الأبعاد (2.5D) |
| الحجم الكلي | يُفضّل ألا يتجاوز مجموع الصور الثماني 1.5 ميغابايت |

## ممنوع في كل الصور (شرط سياسة المحتوى)

لا نصوص، ولا حروف بأي لغة، ولا خط عربي، ولا أرقام، ولا لافتات، ولا شعارات، ولا أشخاص، ولا علامة مائية.

والكتاب في الجزيرة 6 يجب أن يكون **مغلقًا تمامًا**، بغلاف سادة بلا أي كتابة أو زخرفة حروف.

افحص كل صورة بعد التوليد. أدوات التوليد تضيف أحيانًا حروفًا مشوّهة على الأبواب أو الكتب أو الصخور، وأي صورة فيها شيء من ذلك تُعاد.

## الأوامر

### الجزء الثابت

ضعه في بداية كل أمر:

```
Storybook cartoon 2.5D game-map sprite for a children's app: a single small floating rock island with a lush grass top, rounded chunky proportions, soft neutral daylight, warm sandy-brown rock underside tapering down, no glow effects.
```

### الجزء الختامي

ضعه في نهاية كل أمر:

```
Centered with generous padding, transparent background, square. No text, no letters, no calligraphy, no numbers, no signs, no logos, no people, no watermark.
```

إذا كانت الأداة لا تدعم الخلفية الشفافة، فاستبدل `transparent background` بعبارة `isolated on a plain flat white background`، وسأزيل الخلفية البيضاء بنفسي.

إذا كانت الأداة تقبل أمرًا سلبيًا (negative prompt)، فضع فيه:

```
text, letters, words, calligraphy, arabic script, numbers, signs, logo, watermark, people, person, child, face of a human, glow, neon, night, dark background
```

### الجزر الثماني

اسم الملف يجب أن يطابق ما في الجدول حرفيًا، بما في ذلك الأحرف الكبيرة والصغيرة.

| # | اسم الملف | ما يوضع بين الجزأين الثابت والختامي |
|---|---|---|
| 1 | `island_palmsLantern.png` | `On top: two curved palm trees and a small unlit brass lantern on a wooden post, a few green bushes and pebbles.` |
| 2 | `island_domeHouse.png` | `On top: a small cream mud-brick house with a rounded dome, an arched wooden door, a little palm tree and green bushes.` |
| 3 | `island_waterfall.png` | `On top: a small waterfall pouring from mossy grey rocks into a round turquoise pool, ferns and green bushes.` |
| 4 | `island_sandFort.png` | `On top: a small sand-colored desert fort with two round crenellated towers and an arched wooden gate, one palm tree. No flags.` |
| 5 | `island_camel.png` | `On top: one cute friendly cartoon camel standing, wearing a colorful red and teal patterned saddle blanket, a small palm tree and desert shrubs. No riders.` |
| 6 | `island_mushafStand.png` | `On top: a carved wooden X-shaped book stand holding a large book that is fully closed with a plain dark green cover with no markings, beside a small palm tree and green bushes. No writing or symbols on the book.` |
| 7 | `island_oasisTent.png` | `On top: a small desert oasis with a little blue pond, two palm trees and a small striped cream and red Bedouin tent.` |
| 8 | `island_flowerGarden.png` | `On top: a colorful flower garden with pink, yellow and purple flowers around a small round tiled turquoise fountain with water.` |

### مثال على أمر كامل (الجزيرة 1)

```
Storybook cartoon 2.5D game-map sprite for a children's app: a single small floating rock island with a lush grass top, rounded chunky proportions, soft neutral daylight, warm sandy-brown rock underside tapering down, no glow effects. On top: two curved palm trees and a small unlit brass lantern on a wooden post, a few green bushes and pebbles. Centered with generous padding, transparent background, square. No text, no letters, no calligraphy, no numbers, no signs, no logos, no people, no watermark.
```

### نصائح لتوحيد الأسلوب

- ولّد الجزيرة الأولى، فإذا أعجبتك فاستخدمها صورةً مرجعية (image reference) عند توليد الباقي، إن كانت الأداة تسمح بذلك.
- راعِ أن تكون أحجام الجزر متقاربة داخل المربع. الشاشة تعرضها بعرض ثابت، فالجزيرة الصغيرة جدًا ستبدو أصغر من جاراتها.
- يجب أن يكون الجزء السفلي من الجزيرة (الصخر) ظاهرًا. البطاقة تغطي جزءًا من الجزيرة، وتقف تالية في منتصف سطحها العلوي.

## بعد التوليد

1. ضع الملفات الثمانية في المجلد `assets/images/kids/islands/` داخل المشروع.
2. أخبرني، وسأتولى الباقي:
   - إزالة الخلفية إن لم تكن شفافة، والتصغير إلى 512 بكسل.
   - تسجيل المجلد في `pubspec.yaml`.
   - كتابة ملف توثيق الأصول `generated_island_assets.md`: الأداة، والأوامر، وتاريخ الاعتماد.
   - اختبار يتحقق من وجود الصور الثماني.
   - التحقق النهائي (المهمة 7): analyze، والاختبارات، ولقطات ليل ونهار، والمراجعة.
