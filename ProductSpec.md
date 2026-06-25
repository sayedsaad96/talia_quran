# Talia Memorization V2 – Product Specification

## 1. Vision

هدف Talia في الإصدار الجديد هو:

> تمكين المستخدم من حفظ القرآن الكريم بطريقة تدريجية واضحة تعتمد على: تعلم → حفظ → تسميع → مراجعة → تثبيت.

بدون تشويش Features، وبدون خلط بين الحفظ والمراجعة.

---

## 2. Core Principle

أي رحلة حفظ داخل التطبيق تتكون من:

* Learning (تعلم)
* Memorization (بناء الحفظ)
* Recitation (تسميع)
* Block Review (مراجعة مقطع)
* Completion (إنهاء الجلسة)

لا يوجد Quiz مستقل، ولا Hifz Flow مستقل، ولا Daily Plan كواجهة.

---

## 3. Adult Journey

### Flow

1. Home (Next Mission)
2. Session Brief
3. Learning Phase
4. Memorization Phase
5. Recitation Phase
6. Result Screen
7. Block Review (if applicable)
8. Session Completed

---

### Rules

* لا يوجد نص أثناء التسميع
* لا يوجد تلميحات أثناء Recitation إلا بمستويات Hint
* النجاح يعتمد على التسجيل الصوتي + تقييم النظام
* الآية تعتبر محفوظة فقط بعد Recitation Pass

---

## 4. Kids Journey

نفس الـ Core Flow لكن مع تغيير العرض:

* Learning → 🎧 استمع
* Memorization → 🎮 جرّب تتذكر
* Recitation → 🎤 تحدي
* Block Review → ⭐ لعبة المراجعة

لا تغيير في المنطق الداخلي.

---

## 5. Hint System

3 مستويات فقط:

* Level 0: بدون أي مساعدة
* Level 1: أول كلمة فقط
* Level 2: إظهار الآية كاملة

كل استخدام يتم تسجيله ويؤثر على التقييم.

---

## 6. Block Review Rules

بعد عدد N من الآيات (5 / 8 / 10):

* يتم اختبار المقطع كاملًا
* بدون تقسيم أو تلميحات
* نجاح أو فشل فقط
* عند الفشل يتم إعادة الآيات الضعيفة فقط

---

## 7. Completion Rules

الجلسة تنتهي عندما:

* يتم إنهاء جميع الآيات في الـ block
* اجتياز Block Review
* حفظ النتائج في Progress + Review Engine

---

## 8. Non-Goals

* لا يوجد تغيير في Smart Review Engine
* لا يوجد إعادة تصميم للـ Progress
* لا يوجد تعديل على Guardian System
* لا يوجد تعديل على Kids Infrastructure (فقط UI)
