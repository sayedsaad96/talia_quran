# TALIA AUDIT SYSTEM — README
# كيفية استخدام الـ 5 Prompts

---

## الخريطة

```
PROMPT 1 → TALIA_AUDIT_PHASE1_MAP.md
             ↓
PROMPT 2 → TALIA_AUDIT_PHASE2_FEATURES.md   (Feature Completeness + Smart Coach + Flows)
             ↓
PROMPT 3 → TALIA_AUDIT_PHASE3_BUGS.md       (Bug Hunt + Architecture Violations)
             ↓
PROMPT 4 → TALIA_AUDIT_PHASE4_SOURCE_OF_TRUTH.md   (Data Fragmentation Audit)
             ↓
PROMPT 5 → TALIA_AUDIT_FINAL_REPORT.md      (Synthesis + Release Decision)
```

كل prompt يقرأ output اللي قبله ويكمّل عليه.

---

## ليه 5 وليس 4؟

الـ Source of Truth Audit (Prompt 4) هو الأهم.

يجاوب على:
- "لو الـ Home Screen اتقرأ الـ streak من مكان واحد والـ Profile من مكان تاني — مين الصح؟"
- "لو Hifz و Memorization Plus كلاهما بيكتب Progress — في Isar واحد ولا اتنين؟"
- "لو user عنده data كـ guest وعمل account — هيتعمل migrate ولا هيتمسح؟"

ده النوع من المشاكل اللي بيبقى hidden في الكود وظهر
بعد ما آلاف المستخدمين يستخدموا التطبيق.

---

## إزاي تشغّلهم في Cursor Agent

### الخطوة 1 — افتح مشروع Talia

```
File → Open Folder → [مجلد talia]
```

### الخطوة 2 — تأكد من Agent Mode

```
Ctrl+Shift+P → "Cursor: New Agent Session"
```

مش Chat mode — لازم يكون Agent mode عشان يشغّل terminal commands.

### الخطوة 3 — شغّل Prompt 1

انسخ `AUDIT_01_REVERSE_ENGINEER.md` كاملاً والصقه.

اسمحله يشتغل. هياخد 10-20 دقيقة.

لما يخلص:
```
Save this as TALIA_AUDIT_PHASE1_MAP.md in the project root.
```

### الخطوات 4-7 (Prompts 2-5)

نفس الطريقة. كل session جديدة:

```
Read [output files from previous prompts] first, then proceed.
```

---

## إزاي تستخدمهم في Claude.ai

Claude مش عنده access مباشر للـ codebase.

### للـ Prompt 1:

شغّل الـ command ده في terminal:
```bash
find lib/ -type f -name "*.dart" \
  | grep -v ".g.dart" | grep -v ".freezed.dart" \
  | sort > talia_file_list.txt

cat pubspec.yaml >> talia_file_list.txt
```

ارفع `talia_file_list.txt` مع الملفات التالية:
- `lib/main.dart`
- ملف الـ router
- ملف الـ DI registration
- `pubspec.yaml`

### للـ Prompts 2-5:

ارفع:
- الـ output files من الـ prompts السابقة
- الملفات الـ Dart المتعلقة بالـ phase الحالي

---

## إزاي تستخدمهم في Codex / AGENTS.md

أنشئ `AGENTS.md` في root:

```markdown
# TALIA AUDIT AGENTS

## Full Audit (5 prompts in sequence):

1. audit-prompts/AUDIT_01_REVERSE_ENGINEER.md → output: TALIA_AUDIT_PHASE1_MAP.md
2. audit-prompts/AUDIT_02_FEATURES_AND_FLOWS.md → output: TALIA_AUDIT_PHASE2_FEATURES.md
3. audit-prompts/AUDIT_03_BUGS_AND_ARCHITECTURE.md → output: TALIA_AUDIT_PHASE3_BUGS.md
4. audit-prompts/AUDIT_04_SOURCE_OF_TRUTH.md → output: TALIA_AUDIT_PHASE4_SOURCE_OF_TRUTH.md
5. audit-prompts/AUDIT_05_FINAL_REPORT.md → output: TALIA_AUDIT_FINAL_REPORT.md

Each prompt reads all previous outputs before running.
Save all outputs to: audit-outputs/
```

---

## نصايح عملية

### لو الـ agent وقف في النص

```
Continue from where you stopped.
We were at [section name].
Don't restart from the beginning.
```

### لو الـ agent بدأ يـhallucinate

علامات الـ hallucination:
- بيقول "this feature is implemented" بدون file:line
- بيذكر class names مش موجودة في الـ file list من Phase 1
- بيعطيك نتائج بسرعة بدون terminal commands

لو حصل:
```
Stop. Show me the exact command you ran and its actual output
before stating that finding. If you cannot show evidence, remove the finding.
```

### الـ grep الصح

الـ Prompt 3 بيوضح ده بالتفصيل.
الفكرة: ابدأ من الـ class names اللي لقيتهم في Phase 1.
متبدأش بـ `grep -rn "progress"` — هيجيب 300 نتيجة معظمها noise.

---

## الملفات المتوقعة بعد الـ 5 Prompts

```
project-root/
├── TALIA_AUDIT_PHASE1_MAP.md               ← Feature + Navigation + Dependency maps
├── TALIA_AUDIT_PHASE2_FEATURES.md          ← Feature completeness + Smart Coach + Flows
├── TALIA_AUDIT_PHASE3_BUGS.md              ← Confirmed bugs + Architecture violations
├── TALIA_AUDIT_PHASE4_SOURCE_OF_TRUTH.md  ← Data fragmentation map (NEW)
└── TALIA_AUDIT_FINAL_REPORT.md             ← Final verdict + Release decision
```

---

## وقت تقريبي

| Prompt | المحتوى | وقت متوقع |
|--------|---------|-----------|
| 1 | Reverse engineering | 15-20 دقيقة |
| 2 | Features + Smart Coach + Flows | 20-25 دقيقة |
| 3 | Bug hunt + Architecture | 15-20 دقيقة |
| 4 | Source of Truth (8 entities) | 15-20 دقيقة |
| 5 | Final synthesis | 5-10 دقيقة |
| **Total** | | **~75-90 دقيقة** |

---

## متى تعيد تشغيل الـ audit

- قبل أي release
- بعد أي refactor للـ data layer
- لما تضيف feature جديدة تكتب data
- كل شهر كـ health check

---

*Talia Audit System v2.0*
*5-prompt sequential audit with Source of Truth analysis*
