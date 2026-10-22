# Similar-ayah calibration candidates

هذه قائمة مرشحة للمراجعة، ولم يُعتمد أي زوج منها بعد. افتح موضعي كل زوج
في المصحف داخل التطبيق، وقارن نص الآية الأصلي بعد فصل البسملة بالطريقة
المعتادة في القارئ. سجّل لكل زوج: «متقارب لفظيًا»، أو «غير متقارب»، أو
«يحتاج مراجعة»، مع اسم المراجع وتاريخ المراجعة وسبب مختصر بلا نسخ نص الآيات.

القياسات في الجدول وسائل للمراجعة وليست حكمًا على التشابه أو على خطأ القارئ.
القبول في قائمة المقارنة لا يكفي لإسناد التباس أثناء التلاوة؛ فالتكرار بين عدة
آيات قد يوجب امتناع الكاشف عن اختيار آية بعينها. تتطلب المعايرة أيضًا أمثلة
سلبية مستقلة؛ لا تكفي الموافقة على الأزواج الثلاثين وحدها لحساب الدقة.

Status: **pending human review**. This is a discovery shortlist, not a
ground-truth fixture. It contains no human labels, no precision or recall
claim, and no Quran text.

The paired IDs are in
[`test/fixtures/similar_ayah_calibration_candidates.json`](../../../test/fixtures/similar_ayah_calibration_candidates.json).
They contain 30 unreviewed discovery candidates and six separate
raw-basmalah-only candidates. The latter are included to test the review
procedure's ability to reject pairs that arise from the raw leading prefix;
they are **not** negative ground truth until a reviewer labels them.

The transient discovery helper
[`build_e0_calibration_candidates.dart`](../../../.superpowers/sdd/2026-10-18-roadmap-phase-2/build_e0_calibration_candidates.dart)
imports `QuranBasmalah.split` and `ArabicNormalizer.normalize` directly from
the runtime source. Its input is the immutable corpus. It emits identifiers
and mechanical fields only; it never writes Quran text or a final index.

## Mechanical inventory

| Item | Count |
| --- | ---: |
| Candidate ID pairs | 30 |
| Raw-basmalah-only ID pairs | 6 |
| Human-reviewed labels | 0 |
| Precision / recall | Not measured |

The selection strata are discovery aids only. They do not establish a
lexical threshold, a user-confusion outcome, a detector attribution, or a
religious classification. Reviewer approval and independent labels remain
required before tuning or feature activation.

## Review worksheet

Mechanical metrics were computed from runtime ayah bodies using the existing splitter and normalizer. They are not human labels or precision/recall. Fill the final column only after comparing the original ayahs.

| # | A | B | Shared run | Token similarity | Reviewer label |
|---:|---|---|---:|---:|---|
| 1 | 2:1 | 3:1 | 1 | 1 | pending |
| 2 | 3:1 | 29:1 | 1 | 1 | pending |
| 3 | 29:1 | 32:1 | 1 | 1 | pending |
| 4 | 54:17 | 54:22 | 7 | 1 | pending |
| 5 | 54:22 | 54:32 | 7 | 1 | pending |
| 6 | 54:32 | 54:40 | 7 | 1 | pending |
| 7 | 55:13 | 55:16 | 4 | 1 | pending |
| 8 | 77:15 | 77:19 | 3 | 1 | pending |
| 9 | 109:3 | 109:5 | 5 | 1 | pending |
| 10 | 2:136 | 3:84 | 10 | 0.806452 | pending |
| 11 | 2:255 | 3:2 | 7 | 0.14 | pending |
| 12 | 2:285 | 4:136 | 4 | 0 | pending |
| 13 | 3:26 | 35:13 | 1 | 0 | pending |
| 14 | 3:133 | 57:21 | 6 | 0.28 | pending |
| 15 | 4:1 | 33:70 | 1 | 0.071429 | pending |
| 16 | 5:32 | 6:151 | 1 | 0 | pending |
| 17 | 6:59 | 27:75 | 4 | 0.21875 | pending |
| 18 | 7:54 | 10:3 | 14 | 0.4375 | pending |
| 19 | 9:111 | 61:10 | 1 | 0.026316 | pending |
| 20 | 10:62 | 41:30 | 1 | 0.157895 | pending |
| 21 | 11:18 | 46:10 | 1 | 0.083333 | pending |
| 22 | 12:64 | 21:89 | 1 | 0.058824 | pending |
| 23 | 14:10 | 35:3 | 1 | 0.088235 | pending |
| 24 | 16:97 | 40:40 | 8 | 0.304348 | pending |
| 25 | 17:111 | 25:2 | 8 | 0.333333 | pending |
| 26 | 19:65 | 20:14 | 0 | 0 | pending |
| 27 | 21:30 | 24:45 | 2 | 0.032258 | pending |
| 28 | 23:1 | 70:22 | 0 | 0 | pending |
| 29 | 39:53 | 42:25 | 0 | 0 | pending |
| 30 | 87:1 | 56:96 | 1 | 0.25 | pending |
