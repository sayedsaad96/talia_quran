# تدقيق Google Play قبل النشر — Talia Quran

**تاريخ التدقيق:** 9 أكتوبر 2026، Africa/Cairo.  
**القرار الموصى به: NO-GO للتقديم الآن؛ يمكن إعادة تقييمه بعد إغلاق بوابات التحقق أدناه.**  
**النطاق:** امتثال النشر ومخاطر الرفض، وليس تدقيق جودة الشيفرة أو الأداء أو مراجعة شرعية جديدة.  
**مرجع المستودع:** `07be03f323a0c303e93568538c31edf81738775e`؛ كانت حالة Git نظيفة عند بدء الفحص. لم يُعدّل التطبيق أو إعداداته أو أصوله أو اعتمادياته.

## 1. الملخص التنفيذي

التطبيق رفيق قرآني فعلي للبالغين والأطفال، يتيح القراءة والحفظ والمراجعة والتلاوات والأذكار والختمات والتقدم والشهادات، مع حسابات ومزامنة Supabase وربط ولي الأمر. ليست تجربة الأطفال مجرد زخرفة؛ لها إعداد ملف وعمر ومسارات تعلم وتسميع ومكافآت ومتابعة أسرية. لذلك يجب تقييم Families Policy عند اختيار الجمهور المستهدف.

الجاهزية التقنية الأولية أفضل من الجاهزية التوثيقية والقانونية: ملفات الإصدار الموجودة تشير إلى `targetSdk=36`، وتوجد حزمة AAB بها ملفات توقيع ومكتبات 64-bit؛ صلاحية التوقيع نفسها لم تُتحقق تشفيريًا. توجد سياسة خصوصية داخل التطبيق ومسار حذف حساب وصفحات ويب معدّة للنشر. لم يظهر تنفيذ إعلانات أو AdMob أو Firebase Analytics/Crashlytics أو Billing أو خدمة توليد محتوى بالذكاء الاصطناعي. لا ينفي ذلك SDK telemetry، راجع GP-18.

أقوى أسباب التحفظ قبل التقديم:

1. مسار التسميع يطلب الميكروفون ويشغّل التعرف الصوتي دون إفصاح بارز مثبت قبل الاستخدام عن احتمال معالجة الصوت خارج الجهاز، خصوصًا للأطفال.
2. لم تُثبت ملاءمة مقدمي الخدمات لمعالجة بيانات الأطفال، أو الأساس القانوني والموافقة الأبوية عند لزومها. التسجيل والمزامنة يمكن أن يسبقا ربط ولي الأمر، ويمكن متابعة المسار دون الربط.
3. لا يوجد دليل متاح على روابط الخصوصية والحذف العامة أو اكتمال Data Safety وTarget Audience وApp Access وForeground Service declarations في Play Console؛ وتحتاج بيانات ML Kit التشخيصية إلى مطابقة مستقلة مع الإفصاحات.
4. حقوق مجموعات التلاوة وبعض مواد الأذكار ودعاء الختم وتسجيلات الأذان تحتاج مستندات؛ إشعار Tanzil المعروض مختصر.
5. يوجد تحميل مسبق للصوت عند فتح جلسة حفظ، دون عرض حجم التنزيل أو تأكيد مستقل في المسار المفحوص.

**هذه توصية تحفظية للجاهزية، وليست إعلانًا بأن Google سيرفض التطبيق حتمًا.** لا توجد مخالفة نهائية مثبتة لكل نقطة؛ بعض السلوك مثبت بالكود، لكن انطباق بند السياسة أو حالة الخدمات أو الإقرارات الخارجية ما زال غير متحقق. لا يجوز تحويل غياب دليل Play Console إلى ادعاء أن النموذج لم يُملأ.

## 2. المنهج وحدود الإثبات

استُخدم حصر مستقل للمسارات والاعتماديات والأذونات، ثم مراجعات منفصلة للأجهزة والإصدار، والأطفال والخصوصية، وحقوق المحتوى، وتدفقات Flutter ذات الصلة بالسياسة، ومواد المتجر. جرى الرجوع إلى صفحات Google الرسمية الحالية، لا إلى تقارير المشروع وحدها. استُخدمت الوثائق السابقة كدلائل للوصول إلى التنفيذ، لا كإثبات تلقائي على نجاحه.

تمت قراءة [مهارة Google الرسمية Play Policy Insights](https://github.com/android/skills/blob/main/play/play-policy-insights/SKILL.md) كمرجع إضافي، خصوصًا لمحاور Data Safety وبيانات دخول المراجع والأذونات. لم تُثبّت أو تُشغّل أتمتتها لأنها تُنتج ملفات وسيطة، بينما يقتصر التفويض على حفظ هذا التقرير. لم يُشغّل Android Studio Policy Insights lint؛ لا يُدّعى نجاحه.

**ما لم يُنفّذ:** اختبار تشغيل جديد على جهاز، تثبيت من Internal Track، تسجيل حساب أو حذف حساب حي، التقاط حركة شبكة، تدقيق إعدادات Supabase الحية، دخول Play Console، أو اختبار وصول إلى روابط عامة لم يُقدّم عنوانها. لم تُشغّل build/analyze/test جديدة؛ لا يلزم تعديل مخرجات المشروع لتقرير امتثال استدلالي. لذلك لا يُدّعى أن جميع الرحلات اجتازت مراجعة تشغيلية.

تعريف الحالات:

- **CONFIRMED:** حقيقة أو فجوة مثبتة مباشرة في المواد المفحوصة؛ لا تعني دائمًا مخالفة Play محسومة.
- **POTENTIAL:** خطر له دليل تطبيقي، لكن تأكيد المخالفة يعتمد على انطباق السياسة أو سلوك المزوّد أو التشغيل.
- **NOT VERIFIED:** عنصر لا تحسمه الأدلة المتاحة، خصوصًا Play Console والخدمات الحية.

الخطورة المطلوبة هنا: **BLOCKER / HIGH / MEDIUM / LOW**. تعني BLOCKER بوابة لا يمكن تجاوزها إذا لم تُستوفَ، ولا تُحوّل عنصرًا خارجيًا مجهولًا إلى مخالفة مؤكدة. لا يوجد في هذا التقرير ادعاء جديد بفساد نص القرآن؛ مسائل إعادة الاستخدام منفصلة عن سلامة النص.

## 3. التطبيق الفعلي وتغطية الفحص

| المجال | الميزات/الرحلات المثبتة | الأدلة الرئيسية | حد التغطية |
|---|---|---|---|
| البداية والحساب | الترحيب، اختيار بالغ/طفل، ضيف، تسجيل/دخول، تحقق بريد واستعادة كلمة مرور، مزامنة وحذف | `lib/core/router/app_router.dart:149`، `lib/features/auth/presentation/pages/login_page.dart:69`، `lib/features/auth/data/repositories/auth_repository_impl.dart` | قراءة التنفيذ؛ لا دخول حي |
| القرآن | فهرس سور/أجزاء، مصحف QCF، بحث، علامات، ورد يومي، استئناف، استماع ومشاركة | `lib/features/quran/`، `lib/core/services/quran_reciter.dart`، routes عند `app_router.dart:598` وما بعدها | لا فحص بصري جديد لكل صفحة |
| حفظ البالغين | مركز الحفظ، تدريب بالسورة، خطط يومية/مخصصة، جلسة V2، تسميع وتقييم يدوي ومراجعة استماع | `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart`، `data/listening/listening_recitation_capture.dart` | جرى تتبع الصوت والبيانات والتنزيل؛ لا تقييم دقة صوتية |
| الأطفال | ملف لقب/عمر، رحلة وخريطة ومراحل، استماع وتكرار واسترجاع، مصحف، كنوز وإنجازات وتقدم | `path_selection_page.dart`، `kids_mode_cubit.dart`، `kids_progress_page.dart`، `kids_quran_reader_page.dart` | تتبع سياسة وبيانات؛ لا اختبار كل مرحلة |
| الأسرة | PIN، جلسة ولي أمر، QR، ربط/فك ربط، لوحة الأسرة وتفاصيل الطفل والمكافآت | `family_dashboard_access.dart`، `guardian_linking_page.dart`، `kids_policy_controller.dart`، `family_activity_publisher.dart` | علاقة الحسابات والخادم لم تُختبر حيًا |
| التعبد اليومي | أذكار وورد ذكي، إعداد/لوحة/تاريخ/إتمام ختمة ودعاء الختم | `lib/features/azkar/`، `lib/features/khatmah/`، `assets/data/`، route inventory | فحص مصدر وحقوق وحدود البيانات، وليس إصدار حكم شرعي جديد |
| الصلاة والإشعارات | مدينة/إحداثيات يدوية، مواقيت، تذكير وأذان، تأكيدات صلاة محلية، تشغيل خلفي واستعادة تنبيهات | `lib/features/prayer_companion/`، `lib/core/prayer_delivery/`، `packages/talia_prayer_delivery/`، Android manifest | لا إذن GPS ظاهر؛ السلوك الخلفي يحتاج جهازًا |
| التقدم والتصدير | إحصاءات وإنجازات وشهادات، PNG/PDF، حفظ معرض، OS Sharesheet | `lib/features/progress/`، `lib/features/certificate/presentation/pages/certificate_page.dart`، `lib/core/widgets/social_share/` | لا شبكة اجتماعية داخلية مثبتة |
| الإعدادات والمواد القانونية | لغة/مظهر وتذكيرات وملف، خصوصية ومصادر وتراخيص ودليل | `lib/features/settings/`، `docs/legal/`، `privacy-policy/index.html` | النص موجود؛ الاستضافة والإقرارات خارج النطاق المتاح |
| أصول المتجر | شعار وأيقونة ومجموعات صور قديمة وحديثة ومسودات تسليم | `play-store-assets/`، `marketing/google-play-2026-10-08/heritage-reem/` | المجموعة المرفوعة فعليًا غير معلومة |

**اعتماديات تستلزم مراعاة بيانات/أذونات:** Supabase Auth/REST، `speech_to_text`، `mobile_scanner`/ML Kit، `share_plus`، `gal`، `printing`، `audio_service`/`just_audio`/cache manager، `workmanager` وlocal notifications، Isar وSharedPreferences وsecure storage. وجود الاعتمادية لا يثبت وحده جمعًا خارج الجهاز أو عدم ملاءمة للأطفال. القائمة والإصدارات المقفلة في `pubspec.yaml` و`pubspec.lock`؛ إعادة تقييم SDK Index تكون على النسخة النهائية.

لا يوجد دليل على إعلانات أو اشتراكات أو مدفوعات أو دردشة عامة أو رفع منشورات عامة داخل التطبيق. شخصية تالية والتقييم الصوتي لا يثبتان وجود Generative AI؛ لا تُفرض متطلبات الإبلاغ عن مخرجات AI لمجرد وصف التطبيق بأنه «ذكي». مرجع نطاق السياسة: [AI-Generated Content](https://support.google.com/googleplay/android-developer/answer/14094294?hl=en).

## 4. مصادر السياسة الحالية والمواعيد

جميع الروابط التالية رسمية؛ تاريخ الرجوع 9 أكتوبر 2026. عند تقديم نسخة لاحقة يجب إعادة فتح الصفحات لأنها تتغير.

| المرجع | الأثر على هذا التطبيق |
|---|---|
| [Target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) | التطبيقات الجديدة والتحديثات الهاتفية تحتاج API 36 منذ 31 أغسطس 2026. احتمال امتداد حتى 1 نوفمبر لا يُفترض دون موافقة Console. الأدلة المحلية هنا تشير إلى 36 بالفعل. |
| [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en) | المرجع للإفصاح وأمن البيانات والخصوصية والحذف؛ البنود المشار إليها في النتائج أدناه. |
| [Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) | مطابقة جمع البيانات ونقلها وممارسات SDK مع النموذج، بما فيها المعالجة المؤقتة والاستثناءات. أمكن الاطلاع على مقتطفات Google المفهرسة؛ تعذر تحميل الصفحة الكاملة عبر أداة الويب، فلا تُفترض منها استثناءات غير مثبتة. |
| [Families Policy Requirements](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en) | الجمهور، بيانات الطفل، الخدمات والإعلانات والميزات الاجتماعية والالتزام بالقانون. |
| [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en) | مسار التطبيق والوسيلة الخارجية، ونطاق البيانات المحذوفة والاستثناءات المشروعة. |
| [Permissions and APIs](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en) | ضرورة الأذونات وفرق `USE_EXACT_ALARM` عن `SCHEDULE_EXACT_ALARM`. |
| [Foreground services](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en) | تصريح خدمات الخلفية واستخداماتها وأدلة المراجعة. |
| [Metadata](https://support.google.com/googleplay/android-developer/answer/9898842?hl=en)، [Deceptive Behavior](https://support.google.com/googleplay/android-developer/answer/17006354?hl=en) | دقة الصور والادعاءات والتنزيلات الإضافية. |
| [Intellectual Property](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en) | حقوق المحتوى والتسجيلات والأصول. |
| [Reviewer sign-in](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en)، [Prepare for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en) | إتاحة الميزات المحمية للمراجع وتعبئة App content. |
| [Content Ratings](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en) | استبيان IARC دقيق ومحدّث؛ تصنيف المحتوى لا يحل محل Target Audience. |
| [New personal accounts testing](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en) | إذا كان الحساب الشخصي منشأ بعد 13 نوفمبر 2023: اختبار مغلق بـ12 مختبرًا لمدة 14 يومًا متصلة، ثم طلب Production access؛ نوع الحساب غير متحقق. |

### الجاري والقادم

- [Policy Deadlines](https://support.google.com/googleplay/android-developer/table/12921780?hl=en): يلزم التحقق من تسجيل التطبيق ضمن Android developer verification؛ موعد التغيير المنشور 30 سبتمبر 2026 مضى. لا يثبت المستودع حالة الحساب أو التسجيل.
- [16 KB page sizes](https://developer.android.com/guide/practices/page-sizes): الصفحة الحالية تحدد دعم 16 KB للتطبيقات المستهدفة Android 15+ وتذكر منع تحديثات غير داعمة من **1 فبراير 2027**. يجب التحقق من الحزمة الحالية؛ لا نكرر موعدًا تاريخيًا كحكم آلي على هذه النسخة.
- [Play Console technical quality requirements](https://support.google.com/googleplay/android-developer/answer/17492799?hl=en): متطلبات ذاكرة وتحسين DEX من فبراير 2027، مع عتبة DEX غير مهملة للتطبيقات، وZero-Tap Sign-In Restoration من أبريل 2027 للتطبيقات ذات تسجيل الدخول ضمن النطاق. تُراقب مستقبلًا، ولا تُصنّف عيوب أداء حالية دون قياس.
- تغييرات Contacts/Location المعلنة لموعد 27 يناير 2027 تحتاج متابعة عند انطباق الإذن/target؛ لم يظهر إذن contacts أو location هنا. توسعة قواعد anonymous chat في أغسطس 2026 لا تثبت انطباقها على تطبيق لا يحتوي هذه الميزة.

## 5. نتائج الامتثال التفصيلية

### GP-01 — روابط الخصوصية وحذف الحساب العامة غير مثبتة

- **الخطورة:** BLOCKER؛ **الحالة:** NOT VERIFIED.
- **السياسة:** User Data / Privacy Policy وAccount Deletion Requirement. [Google User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)، [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
- **الدليل:** `docs/legal/privacy-policy.html` و`docs/legal/delete-account.html` موجودان. `docs/legal/STORE_PRIVACY_READINESS.md:11-20` يميز صراحة بين الملفات المحلية والاستضافة، ويذكر أن عنوان النشر لم يُقدّم. توجد نسخة `privacy-policy/index.html` أيضًا، دون إثبات أنها النسخة المنشورة أو أن Console يشير إليها.
- **سبب الرفض المحتمل:** رابط مطلوب مفقود/معطل/محجوب أو صفحة حذف غير متاحة خارج التطبيق، إن كانت تلك حالة التقديم الفعلية. النص الداخلي وحده لا يغلق هذه البوابة.
- **الإجراء:** اختبار URL عام فعال غير محجوب جغرافيًا ولا يتطلب دخولًا، صفحة HTML لا PDF، وتطابق النص وهوية التطبيق؛ إدخال رابط الخصوصية ورابط الحذف في مواضعهما. طلب حذف عبر البريد يمكن أن يكون وسيلة خارجية صالحة إذا كانت الصفحة تشرح الخطوات ويُنفّذ الطلب؛ لا يُشترط اختراع نموذج آلي.
- **إغلاق النتيجة:** URLان مع إثبات الوصول ولقطة الحقول في Console، والتحقق من صندوق البريد المسؤول.
- **المالك:** Play Console + Legal or Content Verification؛ **إلزامي قبل النشر:** نعم.

### GP-02 — معالجة بيانات الأطفال دون إثبات أساس قانوني وضبط الخدمات

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL.
- **السياسة:** Families، البنود Data practices وAPIs and SDKs وLegal compliance. [المصدر الرسمي](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en).
- **الدليل:** `path_selection_page.dart:199-209,307-346,547-557` يجمع لقب الطفل وعمره وPIN اختياريًا. `login_page.dart:69-84,110-180` يتيح التسجيل والمزامنة قبل التوجيه للربط. `guardian_linking_page.dart:48-68,252-285` يتيح المتابعة دون ولي أمر. `app_en.arb:3219-3221` نفسه يوضح أن QR لا يثبت الموافقة القانونية. جميع هذه الملفات تحت `lib/features/memorization_plus/presentation/pages/` عدا صفحة الدخول تحت `lib/features/auth/presentation/pages/`.
- **سبب الفحص/الرفض:** التطبيق يعالج بيانات طفل فعلية؛ لا يكفي تسمية التجربة تعليمية أو وجود PIN لإثبات صلاحية الجمع السحابي. لا يوجد هنا إثبات أن Supabase أو مزوّد Speech Recognition محظور للأطفال؛ المطلوب فحص شروطهما وسلوكهما.
- **الإجراء:** تحديد البلدان والفئات العمرية والأساس القانوني بالتعاون القانوني، وإثبات الموافقة الأبوية عندما تلزم، أو مسار طفل محلي يقلل المعالجة. مراجعة عقود الخدمات وآليات البيانات قبل تفعيلها للأطفال. شاشة «بالغ/طفل» ليست تلقائيًا Neutral Age Screen. الحاجة لشاشة محايدة تتحدد بالخدمات غير الصالحة للأطفال أو الإعلانات؛ ليست إلزامًا شكليًا لكل تطبيق مختلط.
- **إعادة التتبع:** اختيار طفل ← إعداد لقب/عمر ← التسجيل/المزامنة ← الربط أو المتابعة بدونه؛ فحص ما خرج للجهاز في كل خطوة بحساب اختباري.
- **المالك:** Legal or Content Verification + Application + Play Console؛ **إلزامي:** إغلاق قانونية المعالجة وملاءمة الخدمات قبل نشر مسار الأطفال.

### GP-03 — الإفصاح قبل التسميع واحتمال نقل صوت الطفل

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL؛ طلب الإذن والتعرف الصوتي مثبتان، ونقل الصوت الفعلي لم يُقَس.
- **السياسة:** User Data / Prominent Disclosure & Consent؛ Families / Data practices. [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)، [Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en).
- **الدليل:** `lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart:1160-1303` يطلب `Permission.microphone` ثم يهيئ ويشغل STT. البالغ: `memorization_session_cubit.dart:676-704`؛ مراجعة الاستماع: `data/listening/listening_recitation_capture.dart:43-81`. سياسة الإعدادات `app_en.arb:3213,3221` تذكر احتمال المعالجة البعيدة، لكن لا يظهر إفصاح مماثل قبل أول تسميع في المسارات المفحوصة. [Android SpeechRecognizer](https://developer.android.com/reference/android/speech/SpeechRecognizer) يوضح احتمال إرسال الصوت للخوادم.
- **سبب الرفض المحتمل:** قد يفهم الطفل/الوالد أن الميكروفون لتقييم محلي؛ طلب Android يشرح الوصول للعتاد ولا يثبت شرح الجهة والمعالجة الخارجية. إذا انطبق شرط المعالجة غير المتوقعة، لا يكفي دفن البيان في الإعدادات.
- **الإجراء:** إثبات سلوك مزوّد التعرف على الأجهزة المستهدفة وشروط استخدام الطفل؛ تقديم إفصاح سياقي سابق للطلب عن الصوت والغرض والجهة واحتمال الإرسال، وموافقة إيجابية عند لزومها، مع خيار تقييم يدوي واضح. عدم وصف التقييم بأنه Offline ما لم يُثبت ذلك.
- **إغلاق النتيجة:** فيديو أول استخدام نظيف للبالغ والطفل، فحص الشبكة/المزوّد، رفض الإذن والبديل اليدوي، ومطابقة Data Safety. لا دليل أن التطبيق يحتفظ بملفات صوت خام على خادمه.
- **المالك:** Application + Legal or Content Verification؛ **إلزامي:** التحقق قبل التقديم؛ الإفصاح والموافقة واجبان إذا انطبق الشرط.

### GP-04 — Data Safety والجمهور وتصريحات المحتوى غير متاحة للتحقق

- **الخطورة:** BLOCKER؛ **الحالة:** NOT VERIFIED.
- **السياسة:** Data Safety وFamilies وContent Ratings. [Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)، [Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)، [IARC](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en).
- **الدليل:** `pubspec.yaml:31-75` وتنفيذ Auth والمزامنة يثبتان حسابات وخدمات سحابية؛ الصور الحديثة تعرض بالغًا وطفلًا؛ لا تصدير للنماذج المرسلة أو وصول Console. خريطة البيانات في القسم 6 أدناه تساعد التعبئة ولا تقوم مقامها.
- **سبب الرفض المحتمل:** اختيار «لا نجمع بيانات» أو جمهور بالغين فقط مع هذه التجربة، أو إجابات محتوى/مشاركة لا تصف النسخة الفعلية. هذه أمثلة مشروطة؛ لم يثبت أن صاحب التطبيق اختارها.
- **الإجراء:** اعتماد الفئات العمرية المقصودة ومطابقة نموذج موحد مع كل المسارات، بما فيها الطفل والضيف والخدمات العابرة. إبقاء Content Rating منفصلًا عن تحديد الجمهور. إثبات التصريحات النهائية ومراجعتها مع الحزمة.
- **المالك:** Play Console + Legal or Content Verification؛ **إلزامي:** نعم.

### GP-05 — معرّف تثبيت يُرسل إلى الخدمة ويحتاج إفصاحًا محددًا

- **الخطورة:** MEDIUM؛ **الحالة:** POTENTIAL؛ توليد المعرّف ونقله مثبتان.
- **السياسة:** User Data / transparency وData Safety. [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)، [تعريفات البيانات](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).
- **الدليل:** `lib/features/memorization_plus/data/datasources/install_device_id.dart:5-23` يولّد UUID عشوائيًا ثابتًا للتثبيت ويخزنه. `data/repositories/collaborators/family_activity_publisher.dart:96-101` يرسله باسم `p_device_id` مع snapshot؛ يستخدمه أيضًا `parent_pin_recovery_service.dart:32,51`. فقرة `privacyTechnicalData` في `app_en.arb:3209` عامة ولا تسمي هذا المعرّف.
- **سبب الفحص:** عبارة «بيانات تقنية» قد لا تكفي لتوضيح هذا الاستخدام العائلي، وقد تُغفل فئة Device or other IDs من النموذج. هذا **ليس AAID أو IMEI**، ولا تثبت هنا مخالفة منع تلك المعرّفات للأطفال.
- **الإجراء:** توثيق الغرض والربط بالحساب ودورة الحياة/الحذف؛ تحديد انطباق Device or other IDs، وتوضيح سياسة الخصوصية عند الحاجة. اختبار ما إذا كان معرف التثبيت يبقى بعد حذف الحساب وما البيانات التي تبقى مرتبطة به.
- **المالك:** Application + Play Console؛ **إلزامي:** دقة الإفصاح والنموذج قبل التقديم؛ لا يلزم إزالة UUID لمجرد وجوده.

### GP-06 — حذف الحساب والاحتفاظ يحتاجان إثبات تشغيل وخادم

- **الخطورة:** HIGH؛ **الحالة:** NOT VERIFIED.
- **السياسة:** Account Deletion Requirement. [مرجع Google](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
- **الدليل:** مسار حقيقي في `lib/features/settings/presentation/widgets/settings_account_tiles.dart:743-830`؛ التنفيذ `auth_repository_impl.dart:379-547`. المهاجرة `supabase/migrations/20261001235630_harden_delete_current_user_session.sql:6-49` تحذف `auth.users` للمالك ذي الجلسة. `docs/legal/STORE_PRIVACY_READINESS.md:17,20,44-49` يذكر حدود التحقق السابق والحاجة لاختبار حي. سياسة الاحتفاظ `app_en.arb:3228` عامة بشأن backups/logs والدعم.
- **سبب الرفض المحتمل:** زر موجود مع RPC غير منشور أو حذف جزئي لا يزيل البيانات المرتبطة، أو احتفاظ يناقض الوعد للمستخدم. لم يُثبت حدوث أي منها في الإنتاج.
- **الإجراء:** على حساب اختبار مخصص، إثبات حذف Auth والجداول والروابط والملفات إن وجدت، انتهاء الجلسة، وتنظيف المحلي والعمليات المعلقة؛ تحقق من جميع الأجهزة المستهدفة. اعتماد استثناءات الاحتفاظ ومواعيدها أو معاييرها الواقعية مع المزوّد؛ لا نفترض أن Play يفرض رقم أيام موحدًا. حذف حساب ولي الأمر لا يعني حذف حساب طفل مستقل، ويجب بقاء هذا الفرق واضحًا.
- **المالك:** Application + Legal or Content Verification؛ **إلزامي:** نعم؛ لا حذف حسابات حقيقية ضمن هذا التدقيق.

### GP-07 — مشاركة شهادة/اسم طفل دون حماية ظاهرة في المسار

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL.
- **السياسة:** Families / Social Apps & Features عند انطباق تعريفها، مع حماية بيانات الطفل. [المصدر](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en).
- **الدليل:** `lib/features/memorization_plus/presentation/pages/kids_progress_page.dart:577` يفتح شهادة دون بوابة ظاهرة. `lib/core/router/app_router.dart:542-590` يستخرج اسم الملف للشهادة. `lib/features/certificate/presentation/pages/certificate_page.dart:68-113` يصدر صورة باسم المستخدم إلى SharePlus. `lib/core/widgets/social_share/social_share_sheet.dart:83-117,127-130,212-235,296-303` يحدد جمهور الطفل، لكنه يعرض الاسم افتراضيًا ويشارك دون gate داخل المكوّن.
- **سبب الفحص:** يمكن إخراج الاسم والإنجاز إلى تطبيقات خارجية. لا توجد دردشة داخلية مثبتة، وOS Sharesheet لبطاقات محددة مسبقًا لا يثبت وحده انطباق تعريف social feature الخاص بتبادل freeform content/المجموعات؛ لذلك ليست مخالفة مؤكدة لذلك البند.
- **الإجراء:** تحقق تشغيلًا من الوصول والبوابات الخارجية للمكوّن؛ حصر مشاركة بيانات الطفل في ولي الأمر، أو Adult action مناسب، وإخفاء الاسم افتراضيًا في سياق الطفل. يجب تغطية مشاركة PNG المباشرة للشهادة ومشاركة SocialShareSheet معًا؛ تعديل toggle الأخير وحده لا يغلق المسار الأول. الاسم المعروض يأتي من ملف المستخدم وليس دليلًا على الاسم القانوني للطفل. إذا انطبق social feature، يلزم تقييم متطلبات تنبيه السلامة وإدارة البالغ أيضًا؛ لا تُضاف اشتراطات دردشة غير موجودة.
- **المالك:** Application + Legal or Content Verification + Play Console؛ **إلزامي:** حسم الانطباق والحماية قبل التقديم، والتنفيذ الملائم وفق النتيجة.

### GP-08 — تحميل تلاوات مسبق دون حجم أو تأكيد في المسار المفحوص

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL؛ التحميل الآلي مثبت بالكود.
- **السياسة:** Deceptive Behavior، القسم 3.2 والتنزيلات عبر CDN. [المصدر الرسمي](https://support.google.com/googleplay/android-developer/answer/17006354?hl=en).
- **الدليل:** فتح/استعادة جلسة بالغ يؤدي إلى `_prefetchBlockAudio` في `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart:462,527,1356-1358`؛ `lib/core/services/audio_cache_service.dart:79-105` ينزل ملفات الآيات عبر `getSingleFile` في دفعات. لا تأكيد أو حجم في هذا المسار. `getAudioSource:42-59` يضيف cache عند التشغيل أيضًا.
- **سبب الرفض المحتمل:** شرط الموارد الإضافية يطلب تنبيه المستخدم وحجم التنزيل قبله. فتح جلسة لا يساوي بالضرورة اختيار تحميل offline لعدة ملفات. التخزين المرافق لتدفق طلبه المستخدم حالة مختلفة ولا نصف كل streaming بأنه مخالفة.
- **الإجراء:** التحقق على تثبيت نظيف وcache فارغ؛ جعل التحميل المسبق اختيارًا مع الحجم والموافقة، أو قصر الاتصال على الصوت المطلوب. مراجعة تنزيلات الأذان بالطريقة نفسها دون افتراض أنها جميعًا تتصرف بالمثل.
- **المالك:** Application؛ **إلزامي:** إغلاق تفسير/معالجة تنزيل الموارد قبل التقديم إذا انطبق البند.

### GP-09 — إثبات اكتمال إشعار Tanzil

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL، فجوة الترخيص منفصلة عن سلامة النص.
- **السياسة:** Intellectual Property. [Google](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)، [Tanzil Text License](https://tanzil.net/docs/Text_License).
- **الدليل:** `lib/features/settings/presentation/pages/sources_licenses_page.dart:18-22,31-38` يعرض اسم Tanzil ورابطه وعنوان الإشعار والترخيص، دون بقية إشعار TERMS OF USE. `assets/data/quran.json:1` يحتوي corpus دون إشعار داخل الملف. البحث في مواد التطبيق المفحوصة لم يجد النص الكامل. `assets/data/content_manifest.json:24-40` يسجل إعادة الاستيراد الحرفي والتحقق السابق بتاريخ 7 أكتوبر.
- **سبب الفحص:** Tanzil يشترط نسخ النص دون تغيير وإسناد المصدر والرابط وإعادة إشعار الحقوق على نحو مناسب في النسخ والملفات ذات الجزء الجوهري. الإسناد الجزئي موجود، لكن كفايته للتوزيع بحاجة إغلاق.
- **الإجراء:** اعتماد موضع وصيغة تضمين الإشعار الكامل في التوزيع بما يطابق الشروط، والتحقق من كل corpus مشتق. لا تُعدّل النص القرآني لإضافة إشعار ولا تُولّد نصًا بديلًا؛ الحل في مادة الترخيص/التغليف المناسبة.
- **المالك:** Legal or Content Verification + Application؛ **إلزامي:** نعم لإغلاق حقوق الاستخدام؛ لا دليل جديد هنا على تحريف النص.

### GP-10 — حقوق تسجيلات القرآن غير مثبتة لكل مجموعة

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL.
- **السياسة:** Intellectual Property. [Google](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)، [فهرس المصدر EveryAyah](https://everyayah.com/recitations_ayat.html).
- **الدليل:** `lib/core/services/quran_reciter.dart:3-36` يحدد ست مجموعات: العفاسي وعبدالباسط والسديس والمنشاوي والحصري والشريم. `audio_cache_service.dart:11-18,34-45,79-105` يثبت التخزين المؤقت والتحميل المسبق. الإسناد موجود في `sources_licenses_page.dart:45-50`؛ لم يظهر إذن موثق لكل تسجيل/مجموعة ضمن المواد المفحوصة.
- **سبب الفحص:** إتاحة رابط MP3 والاعتراف بالمصدر لا يثبتان حق إعادة الاستخدام والتخزين. لا يعني ذلك إثبات تعدٍ من صاحب التطبيق.
- **الإجراء:** مستند شروط أو إذن من الجهة صاحبة الحق يغطّي الاستخدام الفعلي والبلدان وstream/cache، مع نسب المحتوى المطلوبة؛ أو مصدر بديل مثبت الحقوق.
- **المالك:** Legal or Content Verification؛ **إلزامي:** إثبات الحق قبل النشر.

### GP-11 — حقوق النسخ المستخدمة للأذكار ودعاء الختم

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL.
- **السياسة:** Intellectual Property. [Google](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en).
- **الدليل:** `assets/data/content_manifest.json:63-75` يصرح `licenseStatus=unknown_review_scope_does_not_establish_license` لأذكار الإصدار، ويذكر فجوات sourceUrl. `lib/features/azkar/data/datasources/azkar_local_datasource.dart:48-52` يقرأ ملف الإصدار. `content_manifest.json:78-91` و`assets/data/khatm_dua.json` يثبتان المصدر والموافقة الشرعية لدعاء الختم، لا ترخيص إعادة نشر النسخة.
- **سبب الفحص:** الموافقة الشرعية الموثقة لا تثبت حقوق صياغة أو ترجمة أو طبعة حديثة. النصوص التراثية ليست كلها أعمالًا محمية تلقائيًا؛ لا يفترض التقرير وجود حق حصري على القرآن أو كل دعاء.
- **الإجراء:** تحديد الأعمال المنقولة فعليًا والطبعات والحق فيها، ومسوغ public domain إن انطبق، وأذونات الترجمات/التحقيقات إن كانت معروضة. لا تطلب مراجعة شرعية خارجية جديدة لإغلاق فجوة قانونية.
- **المالك:** Legal or Content Verification؛ **إلزامي:** إثبات مشروعية النسخ التي تُنشر؛ لا اتهام بانتهاك قائم.

### GP-12 — إسناد الأذان المتعدد لا يطابق مستندًا لكل ملف

- **الخطورة:** MEDIUM؛ **الحالة:** POTENTIAL.
- **السياسة:** Intellectual Property ودقة الإسناد. [Google](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)، [المصدر المنسوب](https://archive.org/details/adhan.notifications).
- **الدليل:** توجد خمسة مقاطع اختيارية وملف افتراضي في `android/app/src/main/res/raw/adhan*.mp3`. `lib/core/l10n/app_en.arb:3255` ينسب التسجيلات إلى Internet Archive وPDM 1.0. `docs/licenses/AWQAT_AUDIO_LICENSE.md:3-17` يغطي الافتراضي فقط. عرض عنصر Archive لا يكفي لإثبات تطابق جميع الملفات الأخرى وحقوق مصدرها.
- **سبب الفحص:** Blanket attribution قد يصف حقوق مقاطع لا يثبتها؛ ووسم رافع خارجي لا يحسم ملكيته للحق.
- **الإجراء:** جدول file/hash/source/right لكل مقطع على Android وiOS، وتعديل الإسناد إن ثبت اختلافه.
- **المالك:** Legal or Content Verification ثم Application؛ **إلزامي:** حقوق جميع المقاطع قبل النشر.

### GP-13 — تصريح Foreground Service في Console غير متحقق

- **الخطورة:** HIGH؛ **الحالة:** NOT VERIFIED.
- **السياسة:** Foreground service requirements. [المصدر](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en).
- **الدليل:** `android/app/src/main/AndroidManifest.xml:13-14` وخدمتا AudioService وAdhanPlaybackService بنوع `mediaPlayback`. المانيفست المدمج للإصدار: `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml:161-170,183-187`.
- **سبب الرفض المحتمل:** تشغيل خلفي مشروع لا يغني عن إعلان النوع المستخدم وشرحه وإتاحة فيديو الإثبات في App content للتطبيق المستهدف 34+. لم يُفحص النموذج الفعلي.
- **الإجراء:** توثيق تشغيل القرآن والأذان ومتى يبدأان وكيف يوقفهما المستخدم، وإكمال declaration والفيديو حسب طلب النموذج. `shortService` يظهر في مكوّن WorkManager مدمج؛ وجوده وحده لا يثبت استخدامه فعليًا أو نقص تصريح له.
- **المالك:** Play Console + Application لتوفير الأدلة؛ **إلزامي:** نعم للأنواع المستخدمة.

### GP-14 — App Access وإتاحة الأسرة للمراجع

- **الخطورة:** HIGH؛ **الحالة:** NOT VERIFIED.
- **السياسة:** Requirements for providing sign-in details. [المصدر](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en).
- **الدليل:** مسارات القراءة والخصوصية والعديد من الميزات عامة في `app_router.dart:149-190`؛ لوحة الأسرة ضمن `_remoteProtectedRoutes` وتحتاج حسابًا/جلسة ولي أمر. `family_dashboard_access.dart` و`guardian_linking_page.dart` يضيفان PIN وQR. لا توجد حزمة تعليمات مراجعة مع بيانات Console مؤكدة؛ ولا تُطلب أو تُدرج كلمات مرور في هذا التقرير.
- **سبب الرفض المحتمل:** الضيف لا يكشف جميع الوظائف السحابية والعائلية. مطالبة المراجع بإنشاء طفل/تأكيد بريد/انتظار طرف آخر أو رمز متغير قد تمنعه من المراجعة.
- **الإجراء:** حسابات اصطناعية مستمرة للبالغ والطفل وولي الأمر، وتعليمات English للمسارات وPIN/الربط والميزات المقفلة، ووسيلة وصول قابلة لإعادة الاستخدام لا تتطلب بريد شخص حقيقي أو OTP مؤقتًا. وضع الأسرار فقط في App Access. لا تضف تجاوزًا عامًا إلى التطبيق.
- **المالك:** Play Console + Application؛ **إلزامي:** نعم.

### GP-15 — الحزمة النهائية والتوقيع و16 KB وحساب النشر

- **الخطورة:** MEDIUM؛ **الحالة:** NOT VERIFIED جزئيًا؛ توجد تحققّات إيجابية في القسم 8.
- **السياسة/المتطلبات:** [16 KB](https://developer.android.com/guide/practices/page-sizes)، [Prepare release](https://developer.android.com/studio/publish/preparing)، [اختبار الحسابات الشخصية](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)، [مواعيد التسجيل](https://support.google.com/googleplay/android-developer/table/12921780?hl=en).
- **الدليل:** توجد AAB بها ملفات توقيع، وصلاحية التوقيع غير متحققة؛ لم تُثبت مطابقتها لـcommit ولا تسجيل upload key ولا قبولها في Console. Native libs موجودة؛ لم يُفحص ELF/ZIP alignment أو جهاز 16 KB. `versionCode=1` لا يُقارن بمسارات Play غير المتاحة. `docs/release/v1/physical-android-checklist.md:3-25` ما زال `NOT RUN/PENDING`؛ هذه وثيقة وليست برهانًا أن كل الاختبارات لم تُنفذ في أي مكان.
- **سبب التأخير:** رفض upload أو versionCode مكرر أو متطلب اختبار/هوية غير مكتمل، أو عدم توافق native artifact؛ لا نفترض حصول أي منها.
- **الإجراء:** مطابقة hash/commit، اختبار upload وApp Bundle Explorer، إثبات Play App Signing وتسجيل المطوّر والتطبيق، فحص 16 KB رسميًا، وتحديد أهلية Production access حسب نوع الحساب وتاريخه. لا تُستنتج حدود تنزيل Play من حجم ZIP المحلي وحده.
- **المالك:** Play Console + Application؛ **إلزامي:** نعم لعناصر التقديم المنطبقة؛ موعد تحديثات 16 KB المذكور في المصدر الحالي 1 فبراير 2027.

### GP-16 — اعتماد مواد المتجر النهائية والادعاءات

- **الخطورة:** MEDIUM؛ **الحالة:** NOT VERIFIED.
- **السياسة:** Metadata وMisleading Claims. [Metadata](https://support.google.com/googleplay/android-developer/answer/9898842?hl=en)، [Deceptive Behavior](https://support.google.com/googleplay/android-developer/answer/17006354?hl=en).
- **الدليل:** مجموعات متعددة في `play-store-assets/` و`marketing/google-play-2026-10-08/heritage-reem/`؛ `campaign-plan.json:11-18` يمنع اختلاق تقدم أو دقة صوتية ويبين أن دليل لوحة الأسرة محلي. `DELIVERY-ar.md` يوضح أن الصور لم تُنشر. لا title/short description/full description نهائية مؤكدة من Console.
- **سبب الفحص:** قد تُختار نسخة قديمة، أو يُفهم من عرض الأسرة ادعاء cloud tracking لم يُختبر، أو يضاف وصف «تصحيح تجويد معتمد»/«دقة مضمونة»/«Offline بالكامل» بلا دليل. لم يثبت وجود تلك العبارات في الوصف المرسل.
- **الإجراء:** اعتماد مجموعة واحدة مرتبطة بالحزمة؛ تحقق من الاسم بحد 30 حرفًا والأوصاف والأيقونة واللقطات ومواصفاتها. صياغة دقيقة للاعتماد على الشبكة وSTT وحدود التقييم، وعدم نسب اعتماد رسمي أو شهادات أكاديمية لا يقدمها التطبيق. إطار الهاتف أو العنوان التسويقي ليسا ممنوعين تلقائيًا إذا كان العرض صادقًا.
- **المالك:** Play Console + Legal or Content Verification لحقوق الأصول؛ **إلزامي:** دقة النسخة المرسلة وحقوقها قبل التقديم.

### GP-17 — الروابط الخارجية في تجربة الطفل تحتاج تحقق وصول ومحتوى

- **الخطورة:** MEDIUM؛ **الحالة:** NOT VERIFIED.
- **السياسة:** Families / Content requirements. [المصدر الرسمي](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en).
- **الدليل:** `lib/features/settings/presentation/pages/sources_licenses_page.dart:36-70,136-151` يفتح Tanzil وGitHub وEveryAyah وInternet Archive عبر `LaunchMode.externalApplication`؛ نقطة الدخول في `lib/features/settings/presentation/pages/subpages/about_settings_page.dart:26-33`. وصول الطفل الفعلي لهذه الروابط ومحتوى وجهاتها الحالي لم يُختبرا.
- **سبب الفحص:** لا تثبت أسماء المصادر أن كل محتوى خارجي يمكن للطفل الوصول إليه مناسب. لا توجد هنا قرينة على محتوى مخالف في وجهة محددة، ولا قاعدة عامة تحظر كل رابط خارجي.
- **الإجراء:** اختبار الوصول من ملف طفل، وفحص الوجهات النهائية والتحويلات؛ عند الحاجة جعل فتح الويب تحت إشراف ولي الأمر. لا يُطلب حظر إسناد المصادر الشرعي/الترخيصي.
- **المالك:** Application + Legal or Content Verification؛ **إلزامي:** التحقق من انطباق Families وملاءمة الروابط قبل التقديم؛ gate توصية بحسب النتيجة.

### GP-18 — بيانات ML Kit التشخيصية ليست مساوية لمعالجة QR المحلية

- **الخطورة:** HIGH؛ **الحالة:** POTENTIAL؛ وجود SDK في أدلة البناء مثبت، ونقل telemetry في تشغيل هذه النسخة لم يُقَس.
- **السياسة:** User Data / third-party SDK disclosure وData Safety. [Google User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)، [ML Kit Data disclosure](https://developers.google.com/ml-kit/android-data-disclosure)، [ML Kit Terms & Privacy](https://developers.google.com/ml-kit/terms).
- **الدليل:** `pubspec.yaml:67` يستخدم mobile_scanner؛ `lib/features/memorization_plus/presentation/pages/family_dashboard_access.dart:355-405` يشغله لمسح QR. سجل البناء الموجود `build/app/outputs/logs/manifest-merger-release-report.txt:17-22,51-54,118-119` يبين مكتبات barcode-scanning وML Kit common وData Transport. `lib/core/l10n/app_en.arb:3209,3223` يصف بيانات خدمات الحساب والصوت ويسمي Supabase/STT/EveryAyah والبريد، دون بيان محدد لـGoogle ML Kit metrics. المسار الثالث `third_party/mobile_scanner` ليس دليلًا كافيًا وحده على plugin المستخدم؛ metadata تشير إلى Pub cache، فلا نعتمد نسخة vendored لإثبات التهيئة الفعلية.
- **سبب الفحص:** توضح Google أن صور الإدخال ونتائج ML Kit تُعالج محليًا، بينما تُرسل مقاييس استخدام/أداء، وقد تشمل بيانات جهاز/تطبيق ومعرّفات تثبيت وتشخيص. لذلك لا يثبت غياب رفع الصور غياب جمع SDK. ولا يعني ذلك وجود Firebase Analytics أو إعلانات أو رفع صور الأطفال.
- **الإجراء:** حصر dependency graph/تهيئة artifact النهائية وسلوك الاستدعاء، ومطابقة الفئات والأغراض في Data Safety وتوضيح المزوّد والمعالجة في الخصوصية. تحقق أيضًا من ظهور ماسح QR خلف Adult action وما إن كان يتلقى بيانات طفل. وصف «لا أدوات تحليلات سلوكية» ليس كاذبًا تلقائيًا لأن diagnostics تختلف، لكنه لا يغني عن الإفصاح المناسب.
- **المالك:** Application + Play Console + Legal or Content Verification؛ **إلزامي:** مطابقة SDK وإفصاحاته قبل التقديم.

## 6. خريطة Data Safety المقترحة للتحقق

ليست هذه إجابات نهائية للنموذج. «Optional» يحدد لكل نوع حسب القدرة الفعلية على استخدامه أو رفضه. وجود ضيف لا يجعل كل جمع اختياريًا داخل الحساب. Collection وSharing مصطلحان لهما تعريفات؛ Supabase كـservice provider قد يدخل استثناء مشاركة، لكنه لا يلغي الجمع. لا تُفترض exemption للمعالجة المؤقتة دون دليل.

| البيانات | التدفق المثبت/المحتمل | فئة نموذج مرشحة وإجراء |
|---|---|---|
| Email، الاسم/اللقب، User ID | Auth وملف حساب Supabase؛ اسم/لقب مرتبط بشهادات وأسرة | Personal info / Email / Name / User IDs؛ account management/functionality. تحقق من optional لكل مسار. |
| عمر الطفل | إعداد طفل؛ متابعة ولي الأمر وفق policy والتنفيذ | Other personal info حسب التعريف؛ تحقق من الحقول المرفوعة ومبرر جمع العمر الدقيق. |
| قراءة، bookmarks، حفظ ومراجعات وتقييمات وخطط وجلسات، XP وإنجازات | بيانات محلية ثم مزامنة الميزات المدعومة؛ عرض جزء لولي أمر مرتبط | App activity / App interactions وOther user-generated content بحسب الحقول. قد تكشف نشاطًا دينيًا؛ لا تفترض أن التطبيق يسأل صراحة عن المعتقد، لكن راجع فئة Religious beliefs إن انطبقت. |
| UUID التثبيت | `p_device_id` مع snapshot والاستعادة الأسرية | Device or other IDs مرشح قوي؛ الغرض functionality/security، ليس Advertising ID. |
| صوت التسميع/النص المعترف به | OS recognizer؛ احتمال صوت خارج الجهاز؛ تقييم داخل التطبيق؛ النتيجة قد تحفظ | Audio files/Voice recordings بحسب السلوك وتعريف Collection. افحص مزود النظام والنصوص المرسلة والاحتفاظ؛ لا تجزم «لا جمع» لأن خادم Talia لا يستقبل الخام. |
| صورة الكاميرا ورمز QR | تصوير/فك رمز محلي؛ الرمز يرسل للربط | وصول محلي للصورة لا يساوي رفع صور. تحقق من mobile_scanner/ML Kit وأفصح عن بيانات الربط المرسلة. |
| بيانات ML Kit التقنية | SDK في سجل البناء؛ Google توثق telemetry مستقلة عن الصور المحلية | Device or other IDs / Diagnostics وبيانات الاستخدام بحسب النسخة والتعريف؛ تحقق من التهيئة والفئات والغرض قبل تعبئة النموذج. |
| IP وتوقيت وبيانات الطلب | Supabase وEveryAyah ومزوّد التعرف وفق الاستخدام | راجع سجلات المزوّدين وتصنيف IDs/diagnostics إن انطبق؛ لا تتحول جميع عناوين IP تلقائيًا إلى location. |
| بيانات الصلاة، المدينة/الإحداثيات | سياسة النسخة وتنفيذ المرافق يصفان معالجة محلية؛ لا GPS permission | ليست Location collection لمجرد إدخال موقع يُعالج محليًا. تحقق من عدم رفعها قبل اختيار إجابة نهائية. |
| PNG/PDF والشهادات والمشاركة | تصدير بطلب المستخدم إلى التخزين أو تطبيق مختار | راجع استثناء User-initiated transfer قبل اختيار Sharing؛ وضّح اسم الطفل والتقدم والنسخ الخارجة. |
| الدعم والبريد | تواصل خارجي عند اختيار المستخدم | سياسة الخصوصية تشمل الدعم؛ انطباق النموذج يعتمد على جمع التطبيق وتعريفات Google، لا مجرد وجود mailto. |
| بيانات محلية بحتة | Isar/preferences/PIN secure store، تأكيدات الصلاة وبعض التفضيلات | لا تُدرج كجمع خارج الجهاز دون نقل؛ تبقى التزامات الحماية والإذن والوصف. |

تحقق أيضًا من purposes وephemeral processing وencryption in transit وdeletion request، وجميع الإصدارات النشطة التي يشملها النموذج. لا تثبت HTTPS للخدمة الرئيسية أن كل SDK/endpoint يستخدم التشفير؛ هذه إجابة تحتاج تغطية تدفقات النسخة النهائية.

## 7. قائمة Play Console قبل التقديم

كل مربع فارغ **غير متحقق** في هذا التدقيق، وليس إعلانًا بأنه غير مكتمل في الحساب الحقيقي.

### الحساب والإصدار

- [ ] هوية المطوّر والاتصال وبلد/نوع الحساب والتسجيل المطلوب لـAndroid developer verification مكتملة؛ التطبيق مسجل وفق المتطلبات الحالية.
- [ ] تثبيت `com.talia.quran` كهوية المنتج النهائية، واسم المطوّر يطابق النص القانوني أو اسم التطبيق فيه.
- [ ] AAB نهائية مع hash وcommit موثقين؛ upload key وPlay App Signing، versionCode غير مستخدم، وفحص أي تحذيرات SDK/Bundle Explorer.
- [ ] `targetSdk>=36` مثبت من artifact المرفوعة، وnative ABIs و16 KB والحدود الفعلية للحجم مقبولة.
- [ ] المتطلبات الخاصة بحساب شخصي جديد منطبقة/غير منطبقة موثقة؛ عند انطباقها استكمال 12 مختبرًا/14 يومًا متصلة وطلب Production access.
- [ ] Internal Track وPre-launch report على نفس الحزمة، ومراجعة أعطال تمنع مراجع Play من استخدام الميزات.

### App content والخصوصية

- [ ] URL سياسة الخصوصية وURL حذف الحساب فعالان للجمهور دون دخول أو حجب؛ النسخة العربية والإنجليزية متطابقتان.
- [ ] Data Safety معتمدة وفق خريطة التدفقات، وتشمل الحساب/الطفل/الصوت/UUID وML Kit telemetry والمزوّدين عند انطباقهم.
- [ ] Target Audience age groups دقيقة؛ لا استبعاد صوري للأطفال مع وجود تجربة ورسائل موجهة لهم.
- [ ] Families requirements ومناسبـة SDK موثقتان، والأساس القانوني لمعالجة الأطفال والموافقة اللازمة محسومان.
- [ ] IARC questionnaire يتناول المحتوى والتبادل والمشاركة الفعليين؛ لا افتراض Everyone أو 3+ من نوع التطبيق وحده.
- [ ] Ads declaration مبنية على artifact؛ الأدلة الحالية تدعم عدم وجود إعلانات. مراجعة أي cross-promotion تجاري إن أضيف.
- [ ] إقرار Foreground Service لكل نوع مستخدم، مع الوصف والأثر والفيديو؛ لا إعلان تلقائي عن أنواع لم تُستخدم.
- [ ] مراجعة permission declarations التي يعرضها Console بعد الرفع؛ لا اختراع طلب restricted exact alarm أو full-screen intent مع غياب الإذنين.
- [ ] App Access يفتح حساب البالغ والطفل والولي والربط وPIN والبيانات السحابية للمراجع، بتعليمات English قابلة لإعادة الاستخدام.
- [ ] إقرارات أخرى يعرضها Console حسب الفئة/البلدان أُجيبت بصدق؛ لا تُفرض Health/Financial/News/AI/social declarations بلا ميزة منطبقة.

### مواد المتجر والقانون

- [ ] title بحد 30 حرفًا، short/full descriptions دقيقة، تصنيف App مناسب، بريد دعم مراقب، وروابط فعالة.
- [ ] أيقونة وfeature graphic ولقطات مختارة بمواصفات Google؛ صور بالغين وأطفال تمثل الوظائف الموجودة، بلا ادعاء دقة/اعتماد غير مثبت.
- [ ] لا بيانات حقيقية لطفل أو بريد أو QR حساب حقيقي في صور المتجر؛ تدقيق اللقطات المختارة نفسها قبل الرفع.
- [ ] الوصول للروابط الخارجية من ملف الطفل وملاءمة وجهاتها متحققان؛ لا اعتماد على اسم الموقع وحده.
- [ ] حقوق كل أصل مرئي وخط وشعار وصوت، وإشعارات Tanzil وQCF والتراخيص مفتوحة المصدر محفوظة في التوزيع المناسب.
- [ ] حقوق EveryAyah والأذان ومسوغ إعادة نشر الأذكار ودعاء الختم مغلقة ومستنداتها قابلة للتقديم إذا طلبتها Google.
- [ ] البلدان المستهدفة وشروط الأطفال ونقل البيانات والاحتفاظ مدروسة قانونيًا؛ لا إعلان شامل عن COPPA/GDPR compliance بلا إثبات.

## 8. أدلة Android والتحقق المنفذ

| الفحص | النتيجة وحدودها |
|---|---|
| `android/app/build.gradle.kts` | `applicationId=com.talia.quran`، `compileSdk=37`، signingConfig الفعلي هو `release`. التعليق القديم عن debug signing لا يطابق الإعداد ولا يُستعمل كعيب. |
| Flutter SDK المحلي | `D:/dev/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:34` يحدد `targetSdkVersion=36`؛ لا نساوي compileSdk مع targetSdk. |
| المانيفست المدمج | `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml:4-9` يبين `1.0.0+1` وminSdk24 وtargetSdk36. ملف ناتج سابق؛ مطابقة AAB/commit النهائية تحتاج توثيقًا إضافيًا. |
| AAB الموجودة | `build/app/outputs/bundle/release/app-release.aab`، 200,656,735 bytes؛ وقت الملف المحلي 9 أكتوبر 2026 01:35:47. لا يُستنتج منه حجم تنزيل Play. |
| SHA-256 | `FE1F16EE50BF7A2D0638DDBF7DE4D3D8385D4A7C155DF20614097F0B56CC0064`؛ هوية الملف المفحوص، لا إثبات مصدره أو قبوله. |
| فهرس الأرشيف | توجد `META-INF/UPLOAD.RSA` و`UPLOAD.SF`، ومكتبات arm64-v8a/x86_64 وarmeabi-v7a. وجود ملفات توقيع لا يعادل تحققًا تشفيريًا من الشهادة أو تسجيلها لدى Play. |
| الأذونات | Microphone/Camera/Notifications/legacy write storage≤28/Internet/boot/wakelock/FGS mediaPlayback/SCHEDULE_EXACT_ALARM. لا USE_EXACT_ALARM ولا USE_FULL_SCREEN_INTENT ولا GPS/Contacts/SMS/Call log/AD_ID/All-files/broad media-read في المانيفست المفحوص. |
| Exact alarms | فحوص `canScheduleExactAlarms` وfallback وجدول طلب special access في `packages/talia_prayer_delivery/` و`lib/core/services/notification_service.dart:212-274`. لا مخالفة restricted USE_EXACT_ALARM مستنتجة. |
| التشغيل/الشبكة/حذف الحساب | لم تُنفذ اختبارات حية في هذا التدقيق؛ مستقبلية لإغلاق النتائج، لا نجاحات مفترضة. |

الأوامر الناجحة ذات الصلة: `git -c core.fsmonitor=false status --porcelain`، `git rev-parse HEAD`، قراءات `Get-Content` وعمليات `rg` على الملفات المذكورة، فحص الأرشيف عبر `System.IO.Compression`، و`Get-FileHash ... -Algorithm SHA256`؛ exit code 0 للفحوص الناجحة. محاولة `jar tf` لم تعمل لأن jar غير متاح (exit 1)، واستُخدم فهرس الأرشيف البديل. حدثت أيضًا قراءات استكشافية لمسارات غير موجودة ومشكلة Git fsmonitor؛ تم تجاوزها بقراءة المسارات الصحيحة وتعطيل fsmonitor للأمر فقط، دون تغيير إعدادات Git. لا يُعد أي منها فشل بناء للتطبيق.

نقاط لصالح الجاهزية: نص الخصوصية لا يزعم أن STT محلي دائمًا، يبين تبادل بيانات الولي، ويصف حذف الحساب وحدوده. يذكر عدم وجود أدوات إعلانات/تحليلات سلوكية؛ لا تُفسر العبارة كدليل على انعدام telemetry التشخيصية، راجع GP-18. `lib/main.dart:82` يمنع runtime fetching لـGoogle Fonts. تراخيص الخطوط وLucide وإسناد QCF موجودة؛ لا توجد قرينة كافية لإعلان أي أصل آخر مسروق. راجع متخصص الصور عينات `campaign-preview.png` الحديثة والقديمة و`recommended-8/08-campaign-16.png` والأيقونة؛ لم يجد ادعاءً مضللًا مؤكدًا في العينات، وهذا لا يعتمد الوصف النهائي غير المتاح.

## 9. محاكاة قرار المراجع

| سؤال المراجع | التقييم |
|---|---|
| هل أصل إلى كل الميزات؟ | الضيف يغطي كثيرًا من الوظائف العامة؛ الأسرة والمزامنة والحساب تحتاج App Access. الإتاحة الكاملة غير مثبتة. |
| هل الغرض يطابق التنفيذ؟ | نعم على مستوى النطاق: قرآن وحفظ وتعليم ومتابعة أسرية. دقة الوصف المرفوع غير متحققة. |
| ما الشاشة الأرجح لإثارة سؤال؟ | بدء تسميع طفل وإذن الميكروفون، إعداد طفل ثم التسجيل/المزامنة، مشاركة شهادة باسمه، وإعدادات الحساب/حذفه. |
| هل الأذونات مناسبة؟ | الاستخدامات المفحوصة مرتبطة بوظائف حقيقية؛ لا دليل على restricted permission abuse. تبقى الموافقة والتصريحات والتشغيل غير مثبتة. |
| هل تجربة الأطفال مستوفاة؟ | لا يمكن اعتمادها حاليًا: قانونية البيانات وملاءمة الخدمات والإفصاح والمشاركة تحتاج إغلاقًا. لا دليل على إعلانات موجهة للأطفال. |
| هل الوثائق موجودة؟ | نصوص وملفات موجودة؛ روابط المتجر العامة والاحتفاظ الفعلي والإقرارات غير مثبتة. |
| هل المحتوى مرخص؟ | بعض تراخيص الشيفرة والخطوط واضحة؛ التلاوات وبعض المحتوى والأذان تحتاج سجل حقوق. لا اتهام بتعدٍ محسوم. |
| هل هناك مانع API مؤكد؟ | target 36 في الأدلة المحلية يطابق المطلوب؛ تحقق من الملف الذي سيُرفع. |

## 10. ترتيب مخاطر الرفض

الاحتمالات نوعية مشروطة بالأدلة، وليست نسبًا أو تنبؤًا بقرار Google.

| الأولوية | النتائج | الشدة/الاحتمال | سبب الترتيب |
|---|---|---|---|
| 1 | GP-01، GP-04 | BLOCKER إذا كانت ناقصة؛ الحالة الفعلية مجهولة | متطلبات تقديم أساسية؛ يستطيع صاحب Console حسمها سريعًا. |
| 2 | GP-02، GP-03، GP-18 | HIGH؛ مرجح أن تستدعي فحصًا عند مراجعة الطفل/البيانات | تجربة أطفال فعلية وصوت/حساب/مزامنة وSDK أصلي له إفصاح بيانات؛ السلوك ليس فرضية عن ميزة غير موجودة. |
| 3 | GP-06، GP-14، GP-13 | HIGH؛ رفض محتمل إذا فشل الحذف أو الوصول أو التصريح | وظائف تتطلب إثباتًا خارج قراءة الكود، مع قواعد مراجعة واضحة. |
| 4 | GP-09، GP-10، GP-11 | HIGH؛ طلب حقوق/شكوى محتمل، لا انتهاك مثبت | فجوات مستندات وإشعار محددة. المخاطر قد تستمر بعد قبول أول إصدار. |
| 5 | GP-07، GP-08 | HIGH؛ احتمال متوسط وانطباق يحتاج تحققًا | مشاركة اسم طفل وتحميل مسبق ثابتان، لكن تعريف social feature/حدود resource download يحتاجان تقييمًا دقيقًا. |
| 6 | GP-05، GP-12، GP-15، GP-16، GP-17 | MEDIUM؛ يتغير مع النسخة والإقرارات | اكتمال الإفصاح والحقوق ومطابقة الحزمة ومواد النشر وملاءمة الروابط لم تُثبت. |

## 11. خطة النشر

### 1) Must fix before publishing — التصحيح الواجب بعد تأكيد الانطباق

1. إغلاق إفصاح التسميع والموافقة اللازمة قبل أول التقاط، خصوصًا الطفل، أو تقييد المعالجة لمسار صالح مثبت.
2. معالجة أي تدفق طفل لا يملك أساسًا قانونيًا/مزوّدًا مناسبًا؛ لا يبدأ جمعه ثم تؤخذ الموافقة لاحقًا.
3. استكمال صيغة إشعار Tanzil وحقوق المواد التي لا يمكن إثبات مشروعية توزيعها. لا تغيير للنص القرآني ضمن حل الترخيص.
4. معالجة تنزيل موارد الصوت دون الحجم/التنبيه حيث ينطبق البند، وضبط مشاركة بيانات الطفل بناءً على نتيجة GP-07.
5. إذا لم تكن الصفحات منشورة، نشرها وتوفير قناة حذف عاملة ومطابقة النص المعتمد.

### 2) Must verify before submission — بوابات الإثبات

1. Play Console: URLان، Data Safety، Target Audience/Families، IARC، Ads، FGS، App Access، هوية المطوّر والتطبيق، Production access.
2. مزودو الطفل والصوت وSupabase وML Kit: الشروط والبلدان والاحتفاظ وعقود المعالجة والتدفقات الحقيقية وtelemetry. توثيق الإفصاحات على تثبيت نظيف، والتحقق من الروابط الخارجية المتاحة للطفل.
3. حذف حساب اصطناعي كاملًا على الخدمة المعدّة للإصدار، مع أدلة من الجداول والجلسات والملفات والمحلي والمزامنة.
4. رفع الحزمة ذات hash موثق، ومراجعة merged manifest الخاص بها، والتوقيع/versionCode و16 KB وتحذيرات SDK/Pre-launch.
5. تشغيل الضيف والبالغ والطفل والولي والحسابات المقدمة للمراجع، بما فيها الرفض الاختياري للأذونات والتقييم اليدوي.
6. اعتماد وصف وصور وأصول واحدة، بلا بيانات طفل حقيقية أو ادعاءات صوتية/اعتماد غير مثبتة؛ إغلاق مستندات الحقوق.

### 3) Recommended improvements

- سجل بيانات واحد يربط الحقل بالمزوّد والغرض والتصريح والاحتفاظ والحذف، وسجل حقوق يربط كل ملف بمصدره وإذنه.
- تقليل الاسم والعمر والبيانات السحابية في تجربة الطفل حيث لا تحتاجها الوظيفة، وإظهار حد التقييم الصوتي بصورة مفهومة للوالد.
- تجربة دورية للوصول العام للخصوصية والحذف وإشعارات انتهاء/فشل الطلبات، وتوثيق مسؤول بديل للبريد.
- تحديث قائمة الإصدار بالإثبات الفعلي وhash؛ فصل اعتماد المحتوى الشرعي عن ترخيص النسخة ومواد النشر.

### 4) Post-publication compliance monitoring

- متابعة Policy Deadlines وتنبيهات Play Console وSDK Index وتغييرات مزوّدي STT/Supabase؛ إعادة التدقيق عند إضافة إعلان أو اشتراك أو UGC أو Generative AI.
- اختبار الحذف والاستجابة لطلبات الحقوق، وتحديث Data Safety والسياسة عند تغير أي تدفق أو احتفاظ.
- متابعة Android vitals والمتطلبات المعلنة لفبراير/أبريل 2027 ضمن النطاق، دون اعتبار نجاح البناء دليلًا على الامتثال.
- مراقبة حقوق ومصادر تسجيلات الصوت والروابط الخارجية وتحديثات Tanzil، والمحافظة على corpus معتمد دون تعديل آلي.

## 12. الحكم النهائي للمراجع

**«لو قُدّم Talia Quran إلى Google Play اليوم، فما أقوى أسباب رفضه المحتملة، وما الذي يجب عمله لتقليلها؟»**

أقواها معالجة صوت وبيانات أطفال دون إثبات الإفصاح والموافقة/الأساس القانوني وملاءمة الخدمات، ثم أي نقص فعلي في روابط الخصوصية والحذف وData Safety وTarget Audience وFGS وApp Access، أو إغفال telemetry الخاصة بـML Kit. توجد كذلك مخاطر مستقلة في إشعار وحقوق المحتوى والتلاوات والأذان، وتنزيل الموارد المسبق ومشاركة اسم الطفل. لا يدعم الفحص ادعاء رفض بسبب API قديم أو إعلانات للأطفال أو `USE_EXACT_ALARM` أو توقيع debug.

لتقليل المخاطر: أغلق GP-01 إلى GP-18 بالدليل المطلوب حسب انطباق كل منها، واختبر النسخة المعدة للرفع وحسابات المراجع، وقدّم الإقرارات والروابط وسجل الحقوق المتطابق معها. **NO-GO حاليًا هو حكم على كفاية الأدلة والجاهزية للتقديم؛ موافقة Google النهائية تبقى قرارها ولا يضمنها هذا التدقيق.** لم تُنفّذ إصلاحات تلقائية، ولا يتطلب هذا التقرير نشر تغييرات قبل مراجعة نتائج الامتثال.
