# Progress Protection Implementation Plan — حماية التقدم واستعادته

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** توسيع التعافي المحلي، وإتاحة انتقال موضع المصحف بين أجهزة الحساب، وإظهار حدود الحماية دون تعريض تقدم أحدث للفقد.

**Architecture:** توسيع backup v4 إلى v5 بواجهات مملوكة لكل مخزن، مع تعاف مستديم متعدد المخازن. موضع القراءة له repository ومزامنة منفصلان عن اتحاد `read_pages`. استعادة الحساب محافظة ومحدودة بالمجالات ذات سياسة دمج مثبتة.

**Tech Stack:** Flutter/Dart، Cubit، Isar، SharedPreferences، التخزين المشفر وCloudSyncCoordinator وSupabase الحاليون.

**Spec:** `docs/superpowers/specs/2026-10-31-three-initiatives-design.md`، القسم A.

**حالة 2026-11-01:** A1 منفذ ومختبر؛ A2 إصلاحات التعافي منفذة لكن الاستبدال الكامل محجوب في إعداد الإنتاج لعدم اكتمال عزل جميع الكتابات؛ A3/A4 منفذان محليًا مع اختبارات، دون قبول SQL الحي أو الأجهزة. التفاصيل والأدلة في [سجل التنفيذ](../../release/2026-10-31-three-initiatives-validation.md).

## Global Constraints

- Dart `^3.12.0` وFlutter `>=3.44.0`؛ دون ترقية حزم أو نشر قاعدة إنتاج.
- لا نقل مفاتيح/PIN/هوية/مسار جلسة/نص قرآن داخل الأقسام الجديدة؛ مراجع canonical فقط.
- القراءة العادية صفحة 1..604؛ الختمة والحفظ لهما سلطتهما الحالية ولا يعاد تفسيرهما.
- لا تعديل معاني `read_pages` أو RPC الحالي، ولا إعادة توليد نقاط/جوائز من ملف مستورد.
- كل مهمة: اختبار يفشل للسبب المتوقع، تنفيذ أدنى، اختبار ناجح، مراجعة، ثم commit محدد الملفات عند التنفيذ فقط.

## Review Focus

1. مخزن علامات مشفر غير مقروء: فشل ظاهر لا نسخة فارغة — A1/A2.
2. انقطاع العملية وسط مخازن متعددة: استرداد عند التشغيل قبل عرض التقدم — A2.
3. حساب A→B→A أو حذف أثناء الاستعادة: لا عبور ملكية أو deadlock — A2/A4.
4. تعارض موضع جهازين مع ساعة خاطئة: اختلاف معلوم لا overwrite صامت — A3.
5. ملف أقدم يعيد علامة محذوفة أو نقاطًا: لا إحياء/مكافأة صامتين — A4.

## Task A1: عقد بيانات الحماية والمراجع المحمولة

**Files:**
- Create: `lib/core/backup/portable_reading_data.dart`, `test/core/backup/portable_reading_data_test.dart`.
- Modify: `lib/features/quran/data/datasources/bookmark_service.dart`, `lib/core/services/app_session_service.dart`.
- Test: `test/features/quran/bookmark_service_test.dart`, `test/core/services/app_session_service_test.dart`.

**Interfaces:**
- Produce `PortableBookmark(int surahId, int ayahNumber, DateTime savedAt)`؛ لا نص أو sync flags أو ownerId.
- Produce `QuranReadingCheckpoint(int pageNumber)` مع تحقق 1..604.
- Add `Future<List<PortableBookmark>> BookmarkService.exportPortable({required String expectedOwnerId})` يقرأ durable state داخل تسلسل المالك ويفشل عند عدم القراءة.
- Add `Future<QuranReadingCheckpoint?> AppSessionService.exportQuranCheckpoint({required String expectedOwnerId})`؛ لا تحويل لموضع سورة فقط إلى صفحة مفترضة. يجب أن يملك الموضع الجديد نطاق مالك مثبتًا؛ لا ينسب legacy route تلقائيًا لحساب.

- [ ] اكتب اختبارات: المرجع `(2,255)` صالح من corpus الحالي؛ `(2,9999)` مرفوض؛ الصفحتان 0 و605 مرفوضتان؛ export غير المقروء يفشل؛ الحذف المنطقي لا يصدر؛ الأسماء والنص يعاد اشتقاقهما من المرجع عند العرض.
- [ ] نفذ `flutter test test/core/backup/portable_reading_data_test.dart test/features/quran/bookmark_service_test.dart test/core/services/app_session_service_test.dart` وتحقق من فشل الحالات الجديدة قبل التنفيذ.
- [ ] نفذ الأنواع والواجهات مع owner/generation checks؛ لا استخدام `getAll()` المخبأ كمصدر export. استخرج helper صغير بدل تضخيم الملفات الحالية.
- [ ] أعد الأمر نفسه؛ النجاح PASS مع بقاء اختبارات الملكية والبيانات القديمة ناجحة. راجع ثم commit للمهمة فقط.

## Task A2: نسخ v5 وتعاف محلي قابل للاستكمال

**Files:**
- Modify: `lib/core/backup/backup_file_format.dart`, `backup_sections.dart`, `backup_collector.dart`, `backup_restorer.dart`, `lib/core/services/app_initializer.dart`, `lib/core/di/injection.dart`.
- Create: `lib/core/backup/restore_recovery_journal.dart`, `lib/core/backup/restore_operation_gate.dart`, `lib/core/backup/portable_reading_backup_adapter.dart`.
- Test: `test/core/backup/backup_file_format_test.dart`, `backup_roundtrip_test.dart`, `restore_recovery_journal_test.dart`, `restore_operation_gate_test.dart`.

**Interfaces:**
- v5 sections: `bookmarks` (قائمة A1) و`readingCheckpoint` (صفحة أو null)، مع بقاء أقسام v1–v4 كما هي.
- `Future<T> RestoreOperationGate.run<T>({required String expectedOwnerId, required Future<T> Function() operation})` ينسق الكتابات والهوية؛ ترتيب locks موثق: بوابة العملية ثم حواجز المالك ثم طوابير المخازن، دون إعادة دخول معكوسة.
- `Future<void> RestoreRecoveryJournal.recoverBeforeReady()` عند بدء التطبيق قبل السماح بالتقدم أو المزامنة؛ snapshots الداخلية تحتفظ بالمراجعات/tombstones ولا تدخل ملف export.
- قبل التنفيذ سجل inventory ملزم بكل writer يلمس أقسام BackupSections: Isar reviews/progress/XP/streak/dailyActivity/notes/confusionPairs/prayerReview، وprefs المشمولة، والعلامات والموضع والكاش، إضافة إلى reset/delete/cloud callbacks/sign-out. كل writer إما يشارك في البوابة أو يثبت أنه متوقف/معزول؛ أي مسار غير محسوم يمنع إطلاق restore الجديدة.
- journal عقد مستديم: restoreId + destinationOwner + state (`prepared`/`committed`) + hashes + snapshots. جهز snapshots محمية في EncryptedAccountPreferencesStore بمفاتيح restoreId وأجزاء لا تتجاوز 16 KiB UTF-8، واقرأها ثانية للتحقق قبل نشر manifest prepared في كتابة واحدة. سقف snapshots مجتمعة 50 MiB؛ فشل السعة/المفتاح/التحقق يرفض العملية قبل تعديل البيانات. اختبر سعة المنصة فعليًا ولا تفترض أنها تتحمل حد الملف؛ يمكن رفض استعادة كبيرة برسالة واضحة بدل تخفيف الأمان.
- بعد prepared ابدأ الكتابات، ثم committed بعد نجاحها جميعًا؛ عند startup: prepared→rollback كامل، committed→تحقق/إكمال تنظيف فقط. manifest ينشر أخيرًا، ولا تحذف snapshots قبل اكتمال التحقق. المفاتيح اليتيمة قبل prepared تنظف دون اعتبارها restore. لا تعتمد delete best-effort الحالية كدليل نجاح تنظيف؛ سجل علامة تنظيف قابلة لإعادة المحاولة.
- المالك المخزن في journal هو سلطة التعافي لا المالك النشط الجديد. نفذ recovery قبل الانتقال لحساب جديد، وإذا تعذر الوصول للمفتاح أو اختلط المالك أبق الحالة محجوبة دون استرجاع بيانات A إلى B. حذف الحساب يفوز ولا يعاد إنشاؤه من journal؛ احتفظ بقرار إلغاء/حذف مستديم قبل تنظيف الأجزاء.

- [ ] اختبر v1–v4 تحفظ العلامات والموضع الحاليين؛ v5 roundtrip يعيد المراجع؛ فساد أي قسم يمنع كل الكتابات. اختبر payload كبير/إصدار أحدث باستخدام حد الحجم الحالي 50 MiB دون تخفيفه.
- [ ] اختبر إغلاق العملية بعد كل خطوة كتابة ثم إعادة تشغيل: إما حالة ما قبل الاستعادة كاملة أو حالة commit كاملة؛ فشل rollback يبقي الحالة محجوبة قابلة للتعافي. لا يكفي اختبار exception في الذاكرة.
- [ ] اختبر فشل تخزين الجزء الأخير، ومفتاحًا غير متاح، وحد snapshots الزائد، وmanifest مقطوعًا، وcommit نجح ثم تعطل التنظيف؛ كلها دون نجاح وهمي أو مزامنة لحالة جزئية. وثق نتائج تحمل حجم snapshot على Android المستهدف قبل فتح الميزة.
- [ ] شغل `flutter test test/core/backup`؛ سجل الفشل المقصود.
- [ ] نفذ prevalidation ثم journal مستديم ثم store writes ثم commit marker ثم cache refresh؛ اجعل snapshots الحساسة محمية بالتخزين المشفر القائم ولا تسرب النصوص/المالك للسجلات. اربط جميع writers المتأثرة: bookmark toggle/pull/push، checkpoint، reset/delete، وsign-out flush، لا coordinator وحده.
- [ ] اختبر الكاتب المتأخر وتغيير المالك والمزامنة المعلقة، وأعد `flutter test test/core/backup test/core/identity test/features/quran/bookmark_service_test.dart`.
- [ ] أضف تنبيه أن ملف التصدير غير مشفر، ومعاينة للنطاق قبل الاستعادة. اترك الاستبدال للمسجل محجوبًا. راجع ثم commit.

## Task A3: موضع مصحف محلي ومزامنة بإصدار خادم

**Files:**
- Create: `lib/features/quran/domain/repositories/reading_checkpoint_repository.dart`, `lib/features/quran/domain/usecases/reading_checkpoint_usecases.dart`, `lib/features/quran/data/repositories/reading_checkpoint_repository_impl.dart`.
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart`, `lib/features/quran/presentation/widgets/continue_reading_card.dart`, `lib/features/auth/application/cloud_sync_coordinator.dart`, `lib/core/di/injection.dart`.
- Create migration: `supabase/migrations/20261031010000_reading_checkpoints.sql` (تحقق من عدم تصادم الترتيب عند التنفيذ).
- Create tests: `supabase/tests/20261031010000_reading_checkpoints_test.sql`, `test/features/quran/reading_checkpoint_repository_test.dart`, `test/supabase/reading_checkpoint_contract_test.dart`.

**Interfaces:**
- `Future<void> saveLocal({required String expectedOwnerId, required int pageNumber})` يحفظ فورًا local mutation id ونسخة الخادم المعروفة.
- `Future<CheckpointSyncResult> sync({required String expectedOwnerId})`؛ النتائج `synced`, `pending`, `conflict`, `unavailable`، ولا يستدل بالنجاح من مجرد اكتمال Future.
- جدول مستقل `quran_reading_checkpoints`: user_id PK وpage_number CHECK 1..604 وrevision bigint وupdated_at من الخادم.
- RPC `put_quran_reading_checkpoint(p_page integer, p_expected_revision bigint, p_mutation_id uuid)`؛ يشتق المالك من auth.uid()، ويتحقق ذريًا من revision، ويعالج retry لنفس mutation id دون revision جديد. تعارض يعيد current page/revision. يلزم سجل قبول mutation محدود بمالك في معاملة الخادم مع سياسة احتفاظ موثقة؛ لا يكفي مقارنة آخر mutation فقط.
- RPC `get_quran_reading_checkpoint()` للحساب الحالي فقط؛ رفض anon، وRLS وصلاحيات ضيقة. لا تغيير RPC `upsert_reading_progress(p_pages)`.

- [ ] اختبر جهازين عند revision=7؛ أول قبول ينتج 8، والثاني conflict ويحفظ pending المحلي. اختبار response مفقود ثم retry، وتغيير محلي جديد أثناء رفع سابق، وعميل قديم لا يعرف الجدول، وساعة جهاز خاطئة.
- [ ] شغل اختبارات Dart أعلاه لتفشل قبل إضافة الواجهات. نفذ SQL tests على قاعدة تطوير معزولة؛ سجل الهدف المنقح والأوامر وexit code دون أسرار. استخدم طريقة المستودع في scripts/verify_supabase_migrations.ps1 بعد قراءة معاملاته، لا تفترض بيئة جاهزة.
- [ ] نفذ المحلي أولًا وack مطابقًا mutation id فقط. تعارض لا يحذف الموضع المحلي؛ تعرض الواجهة الموضعين وخيار «هذا الجهاز/المحفوظ للحساب»، ثم retry بالإصدار الذي شاهده المستخدم. لا اختيار اعتمادًا على max(page) أو ساعة العميل.
- [ ] تحقق من RLS بين حسابين، auth.uid null، تكرار mutation، وطلب page غير صالح. شغل `flutter test test/features/quran/reading_checkpoint_repository_test.dart test/supabase/reading_checkpoint_contract_test.dart test/features/auth/cloud_sync_coordinator_test.dart`.
- [ ] تحقق runtime على جهازين، offline→restart→online، واستمرار المصحف العادي دون نسبة قراءة للختمة. راجع ثم commit؛ لا نشر إنتاج تلقائيًا.

## Task A4: واجهة الحماية واستعادة الحساب المحافظة

**Files:**
- Create: `lib/features/settings/domain/entities/data_protection_status.dart`, `lib/features/settings/presentation/cubits/data_protection_cubit.dart`, `lib/features/settings/presentation/widgets/data_protection_panel.dart`.
- Modify: `lib/features/settings/presentation/pages/backup_page.dart`, `lib/features/auth/application/cloud_sync_coordinator.dart`, `lib/features/quran/data/datasources/bookmark_service.dart`, `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb`, `lib/core/di/injection.dart`.
- Test: `test/features/settings/presentation/pages/backup_page_test.dart`, new `test/features/settings/data_protection_cubit_test.dart`, `test/integration/progress_recovery_test.dart`.

**Interfaces:**
- `DataProtectionStatus` يعرض حالة كل مجال: progress/review evidence/bookmarks/checkpoint، pending count إن كان معلومًا، وآخر نجاح حقيقي لكل مجال؛ unknown يظل unknown.
- `Future<BookmarkImportPreview> previewPortableImport(List<PortableBookmark> entries)` يعرض additions/existing/deletedConflicts/invalid، دون كتابة.
- `Future<void> applyPortableImport(BookmarkImportPreview preview)` يتطلب current-owner fence/تطابق المراجعة؛ الإضافات mutations جديدة، والحذف السابق لا يلغى تلقائيًا. عند stale preview تعاد المعاينة.

- [ ] اختبر نجاح progress وفشل bookmarks: الحالة ليست «كل البيانات متزامنة». timestamp لا يحدث عند failure أو مجرد بدء الطلب. signed-out يظهر «محفوظ على الجهاز» لا «محفوظ سحابيًا».
- [ ] اختبر signed-in file import: يسمح بعد المعاينة بالعلامات الجديدة وموضع القراءة المختار فقط؛ تبقى مراجعات/نقاط/جوائز الحساب القائمة بلا تغيير. استعادة تقدم الحساب تتم من مسار cloud reconciliation الحالي، ويصرح باستثناء بقية مجالات الملف.
- [ ] اختبر علامتين موجودتين وإضافة جديدة وعلامة tombstone: يحتفظ بالوجهة، يضيف الجديدة مرة واحدة، ويعرض تعارض المحذوفة دون إحيائها. تغير الحساب أثناء المعاينة يلغيها.
- [ ] شغل `flutter test test/features/settings/presentation/pages/backup_page_test.dart test/features/settings/data_protection_cubit_test.dart test/features/quran/bookmark_service_test.dart` ثم نفذ الواجهة والملاحظة الصريحة لنطاق الاستعادة، وتوليد l10n عبر `flutter gen-l10n`.
- [ ] أعد الأوامر واختبارات runtime على Android: import/checkpoint conflict/offline/restart/TalkBack/200%. لا تفتح استبدال تقدم حساب كامل؛ ذلك توسع يتطلب مواصفات دمج لكل مجال ومراجعة مستقلة قبل تنفيذه.
- [ ] راجع الأمن/الملكية والتعافي، ثم commit للمهمة. أضف أدلة التحقق إلى سجل G.

## تسلسل الإطلاق والتراجع

A1→A2 بوابة تعاف ضيف؛ ثم A3 نشر additive على بيئة تحقق قبل العميل؛ ثم A4 استعادة حساب محدودة صريحة. لا تفعيل قبل اجتياز kill/restart واختبارات الحسابين. rollback يعطل الواجهة/الرفع الجديد دون حذف الجدول أو v5 decoder أو journal recovery.
