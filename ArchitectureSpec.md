# Talia Memorization V2 – Architecture Specification

## 1. Core Idea

بدل تعدد أنظمة (Hifz / Quiz / Daily Plan)، يوجد نظام واحد:

> Memorization Session Engine

---

## 2. Domain Models

### MemorizationSession

يمثل جلسة الحفظ الكاملة.

```text
id
userId
surahId
blockRange (e.g. 1–5)
state
```

---

### MemorizationBlock

مجموعة آيات يتم العمل عليها كوحدة واحدة.

```text
startAyah
endAyah
surahId
```

---

### MemorizationUnit

أصغر وحدة:

* Ayah واحدة

---

### ReviewItem

عنصر يتم إرساله إلى نظام المراجعة.

```text
ayahId
dueDate
strengthScore
```

---

## 3. Session State Machine

```text
CREATED
↓
LEARNING
↓
MEMORIZING
↓
RECITING
↓
REMEDIATION (if failed)
↓
BLOCK_REVIEW_PENDING
↓
BLOCK_REVIEW
↓
COMPLETED
```

---

## 4. Rules Engine

### Learning

* لا تقييم
* لا تسجيل نجاح/فشل

---

### Memorizing

* يسمح Hint System
* يتم تسجيل مستوى المساعدة

---

### Reciting

* تقييم أساسي (Pass/Fail)
* لا يوجد نص ظاهر

---

### Remediation

* إعادة تعليم الآية الفاشلة
* ثم إعادة Recitation

---

## 5. Reuse Strategy

### KEEP (No Change)

* Review Foundation (100%)
* Smart Review Engine
* Progress System
* Kids Infrastructure
* Guardian System
* Routing Guards

---

### REFRACTOR

* Hifz Flow → replaced by Session Engine adapter
* Quiz Flow → split into Learning/Review modes
* Daily Plan → becomes Smart Coach output only

---

### REMOVE (Gradual)

* Legacy Hifz UI
* Duplicate Quiz screens
* Mixed flow logic inside features

---

## 6. Integration Strategy

### Adapter Layer

نظام وسيط بين القديم والجديد:

```text
Smart Coach → Session Engine → Old Screens (temporarily)
```

---

### Feature Flag

```text
enable_memorization_v2
```

---

## 7. Migration Strategy

### Phase 1

Add new domain models only

### Phase 2

Introduce state machine (no UI change)

### Phase 3

New Adult flow behind feature flag

### Phase 4

Gradual screen replacement

### Phase 5

Retire legacy flows

---

## 8. Risk Control

* ممنوع حذف أي feature قديم قبل نجاح V2
* ممنوع duplication بدون adapter layer
* ممنوع تغيير Review Engine
* كل تغيير لازم يكون backward compatible
