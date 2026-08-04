# 🎯 UI/UX Execution Plan — تطبيق تالية للقرآن الكريم
> **الهدف:** تحويل التجربة البصرية من "جيد" إلى "استثنائي" مع الحفاظ على سلامة المشروع الكاملة.
> **المنفذ المقصود:** AI Agent يعمل على Flutter project في `d:\Sayed\Flutter\talia_quran`

---

## 📋 فهرس الخطة

| المرحلة | الهدف | الأولوية | الوقت التقديري |
|---------|-------|----------|----------------|
| **Phase 1** | الأساس البصري — Colors + Decorations | 🔴 Critical | 90 دقيقة |
| **Phase 2** | الشاشة الرئيسية — Home | 🔴 Critical | 3 ساعات |
| **Phase 3** | نظام التنقل — Navigation | 🔴 Critical | 90 دقيقة |
| **Phase 4** | المكونات الأساسية — Core Widgets | 🟡 High | 2 ساعة |
| **Phase 5** | التجربة الروحانية — Celebrations | 🟡 High | ساعة |
| **Phase 6** | مسار الأطفال — Kids Mode | 🔴 Critical | 7 ساعات |
| **Phase 7** | صفحة التقدم — Progress | 🟡 High | 3 ساعات |
| **Phase 8** | مسار الكبار — Adult Memorization | 🟡 High | 2 ساعة |
| **Phase 9** | الأذكار والأدعية — Azkar | 🟡 High | 2.5 ساعة |

---

## 🛡️ قواعد السلامة الإلزامية (يجب الالتزام بها في كل تغيير)

### قبل أي تعديل

```bash
# 1. تأكد من أن المشروع يُبنى بنجاح
flutter analyze
flutter build apk --debug

# 2. افهم الملف قبل تعديله — اقرأه كاملاً
# 3. لا تحذف أي widget أو function موجودة — أضف فقط أو استبدل بحذر
```

### قواعد التعديل الآمن

| القاعدة | التفسير |
|---------|---------|
| **لا تعديل على Business Logic** | UI فقط — لا تلمس Cubit/Repository/UseCase |
| **احتفظ بكل المفاتيح** | `key:` على كل widget تفاعلي — لا تحذفها |
| **لا تغيير في Route Names** | `AppRoutes.*` — لا تعدّل ثوابت التوجيه |
| **اختبر الوضعين** | كل تغيير يجب أن يعمل في Dark + Light mode |
| **اختبر RTL** | التطبيق عربي أولاً — `Directionality.of(context)` |
| **لا تكسر Responsiveness** | اختبر على شاشات صغيرة (360px) وكبيرة (430px) — **portrait + landscape** |
| **احتفظ بـ Semantics** | لا تحذف `Semantics` أو `Tooltip` موجودة |
| **لا magic numbers** | استخدم `AppSpacing.*` دائماً |
| **احترم Reduced Motion** | كل animation يجب أن يحترم `MediaQuery.of(context).disableAnimations` — لا تفرض حركة على من يطلب إيقافها |
| **اختبر Text Scaling** | اختبر مع `textScaler` 1.5x — لا نص مقطوع، لا overflow |
| **لا تداخل Gestures** | لا `GestureDetector` داخل `Dismissible` — gesture واحد رئيسي لكل منطقة |
| **Scrim كافٍ للـ Modals** | أي `BottomSheet` أو `Dialog` يحتاج scrim بين 40-60% opacity |

### بعد كل تغيير

```bash
flutter analyze
# يجب أن تكون النتيجة: "No issues found"
# إذا وجد warning — أصلحه قبل الانتقال للتالي
```

---

## 📐 مبادئ البرمجة الإلزامية

### Clean Code
```dart
// ✅ صح: تسمية واضحة وكاملة
final isStreakMilestone = streak >= 7;
Widget _buildStreakBadge() { ... }

// ❌ خطأ: أسماء مختصرة أو غامضة
final isSM = s >= 7;
Widget _bSB() { ... }
```

### DRY — Don't Repeat Yourself
```dart
// ✅ إذا استخدمت نفس الـ BoxDecoration أكثر من مرة — استخرجها
// في AppDecorations أو KidsTheme حسب الموقع
static BoxDecoration get spiritualCard => BoxDecoration(...)

// ❌ لا تنسخ نفس الـ BoxDecoration في 3 أماكن
```

### KISS — Keep It Simple
```dart
// ✅ Animation بسيطة وواضحة
.animate().fadeIn(duration: 300.ms).slideY(begin: 0.05)

// ❌ لا تبالغ في تعقيد الـ animation
// لا أكثر من 3 effects متداخلة في نفس الوقت
```

### Single Responsibility
```dart
// ✅ كل widget مسؤولة عن شيء واحد
class _StreakFlameIcon extends StatelessWidget { ... }
class _StreakCounter extends StatelessWidget { ... }

// ❌ لا تضع كل شيء في widget واحدة ضخمة
```

### Responsive & Adaptive
```dart
// ✅ استخدم LayoutBuilder أو MediaQuery للتكيف
final screenWidth = MediaQuery.of(context).size.width;
final isCompact = screenWidth < 400;
final cardHeight = isCompact ? 80.0 : 100.0;

// ✅ استخدم Flexible/Expanded بدلاً من قيم ثابتة حيثما أمكن
// ✅ اختبر على: 360px (صغير), 390px (iPhone 14), 430px (Plus)
```

### Performance First
```dart
// ✅ const constructors دائماً حيثما أمكن
const SizedBox(height: AppSpacing.md)
const Icon(Icons.star_rounded, size: 24)

// ✅ RepaintBoundary للـ animations الثقيلة
RepaintBoundary(child: _AnimatedStarCounter())

// ✅ لا تعمل حسابات في build() — افعلها في initState أو الـ Cubit
```

---

## 🏗️ معمارية المشروع (اقرأها قبل البدء)

```
lib/
├── core/
│   ├── theme/           ← AppColors, AppTypography, AppDecorations
│   ├── widgets/         ← Shared widgets: AppButton, AppCard, SectionHeader
│   ├── constants/       ← AppSpacing (استخدمه دائماً بدلاً من أرقام)
│   └── extensions/      ← context.isDark, context.l10n, context.isArabic
├── features/
│   ├── home/            ← الشاشة الرئيسية
│   ├── memorization_plus/ ← مسارات الحفظ (أطفال + كبار)
│   ├── progress/        ← صفحة التقدم
│   └── azkar/           ← الأذكار والأدعية
```

**قواعد الـ Import:**
- الـ core widgets متاحة لكل features
- الـ features لا تستورد من بعضها مباشرةً
- `KidsTheme` خاص بـ `memorization_plus` فقط

---

## 🎨 نظام التصميم (المرجع)

### الألوان الرئيسية
```dart
// من AppColors:
AppColors.primary       // Teal الرئيسي
AppColors.primaryLight  // Teal فاتح
AppColors.gold          // الذهبي
AppColors.success       // الأخضر
AppColors.warning       // البرتقالي
AppColors.error         // الأحمر

// الخلفيات:
AppColors.darkBackground  // Dark mode
AppColors.lightBackground // Light mode
AppColors.darkCard        // Dark card
AppColors.lightCard       // Light card
```

### المسافات
```dart
// من AppSpacing — استخدمها دائماً (القيم الفعلية):
AppSpacing.xs    // 4px
AppSpacing.sm    // 8px
AppSpacing.md    // 16px
AppSpacing.lg    // 24px
AppSpacing.xl    // 32px
AppSpacing.xxl   // 48px
AppSpacing.xxxl  // 64px
AppSpacing.pagePadding  // 20px (هامش الصفحة)
AppSpacing.sectionGap   // 32px (فراغ بين الأقسام)
AppSpacing.cardPadding  // 20px (هامش داخل البطاقة)
AppSpacing.itemGap      // 12px (فراغ بين العناصر)
AppSpacing.iconTextGap  // 8px (فراغ بين أيقونة ونص)
AppSpacing.buttonHeight // 56px
AppSpacing.bottomNavHeight // 72px

// Border Radius:
AppSpacing.radiusXs   // 4px
AppSpacing.radiusSm   // 8px
AppSpacing.radiusMd   // 12px
AppSpacing.radiusLg   // 16px
AppSpacing.radiusXl   // 24px
AppSpacing.radiusXxl  // 32px
AppSpacing.radiusFull // 999px (دائري)
```

### الخطوط
```dart
// من AppTypography:
AppTypography.displayLarge    // عنوان ضخم
AppTypography.headlineLarge   // عنوان كبير
AppTypography.headlineSmall   // عنوان صغير
AppTypography.titleLarge      // عنوان card
AppTypography.bodyMedium      // نص عادي
AppTypography.labelSmall      // تسمية صغيرة
AppTypography.azkarText       // نص الأذكار العربي
```

---

## 📦 Phase 1 — الأساس البصري

> **قاعدة:** هذه المرحلة تضيف فقط — لا تعدّل قيم موجودة.

### 1.1 ترقية `lib/core/theme/app_colors.dart`

**أضف داخل class AppColors بعد الألوان الموجودة:**

```dart
// ─── Glow & Ambient Colors ────────────────────────────────────────────────────
static const Color ambientTeal    = Color(0xFF1A6B5A);
static const Color ambientGold    = Color(0xFFD4A017);
static const Color shimmerBase    = Color(0xFF2A3540);
static const Color shimmerHighlight = Color(0xFF3D5060);

// ─── Spiritual Palette ────────────────────────────────────────────────────────
static const Color parchmentWarm  = Color(0xFFF5EDD6); // كالرق الدافئ — light
static const Color inkDeep        = Color(0xFF1C2B2F); // حبر عميق — dark
static const Color moonlight      = Color(0xFFE8F4F0); // ضوء القمر
static const Color desertSand     = Color(0xFFC8A97A); // رمال الصحراء

// ─── Radial Glow Gradients ────────────────────────────────────────────────────
static RadialGradient get radialGlowPrimary => const RadialGradient(
  colors: [Color(0x4D1A6B5A), Colors.transparent],
  radius: 0.9,
);

static RadialGradient get radialGlowGold => const RadialGradient(
  colors: [Color(0x33D4A017), Colors.transparent],
  radius: 0.9,
);
```

### 1.2 ترقية `lib/core/theme/app_decorations.dart`

> ⚠️ **تبعية إلزامية:** هذه الدوال تستخدم `AppColors.desertSand` و`AppColors.ambientTeal` و`AppColors.shimmerBase` — تأكد من إضافتهم في Phase 1.1 أولاً. **ترتيب التنفيذ: 1.1 قبل 1.2 إلزامي.**

**أضف Methods جديدة داخل class AppDecorations:**

```dart
/// بطاقة روحانية بـ gradient مستوحى من الرق والمخطوطات
static BoxDecoration spiritualCard({required bool isDark}) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? [const Color(0xFF1C2B2F), const Color(0xFF0F1E22)]
        : [const Color(0xFFF5EDD6), const Color(0xFFEDE4C8)],
  ),
  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
  border: Border.all(
    color: isDark
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.desertSand.withValues(alpha: 0.4),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: AppColors.ambientTeal.withValues(alpha: isDark ? 0.15 : 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ],
);

/// بطاقة بإطار ذهبي للمحتوى المميز
static BoxDecoration goldRimCard({required bool isDark}) => BoxDecoration(
  color: isDark ? AppColors.darkCard : AppColors.lightCard,
  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
  border: Border.all(
    color: AppColors.gold.withValues(alpha: 0.35),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ],
);

/// بطاقة shimmer-ready — تُستخدم أثناء التحميل
static BoxDecoration shimmerCard({required bool isDark}) => BoxDecoration(
  color: isDark ? AppColors.shimmerBase : AppColors.lightCard,
  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
);
```

**✅ تحقق:** `flutter analyze` — يجب أن يمر بدون errors.

---

## 🏠 Phase 2 — الشاشة الرئيسية

> **قاعدة:** اقرأ `home_page_widgets.dart` كاملاً قبل البدء.
> **قاعدة:** لا تعدّل منطق `BlocBuilder` — عدّل الـ widget داخله فقط.

### 2.1 ترقية `_HeroHeader`
**الملف:** `lib/features/home/presentation/pages/home_page_widgets.dart`

> ⚠️ **`_HeroHeader` حالياً `StatelessWidget`** — يجب تحويلها إلى `StatefulWidget` لإضافة AnimationController.

**خطوات التحويل الآمن:**
```dart
// 1. احتفظ بكل parameters في الـ Widget class
// 2. انقل build() body إلى State class
// 3. أضف TickerProviderStateMixin
// 4. أضف AnimationController في initState + dispose

class _HeroHeader extends StatefulWidget {
  // احتفظ بكل الـ parameters الموجودة كما هي
  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState(); // ← إلزامي
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose(); // ← إلزامي
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدم widget.xxx بدلاً من this.xxx للوصول للـ parameters
    // ...
    // أضف AnimatedBuilder حول الشعار:
    AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: _buildLogo(),
    )
  }
}
```

**قواعد `_HeroHeader`:**
- لا تحذف `SafeArea` الموجود
- حافظ على نفس الـ `expandedHeight`
- الـ gradient يجب أن يعمل في Dark + Light

### 2.2 ترقية `_QuickActionsGrid`
**تحويل إلى Bento Grid:**

```dart
// استبدل GridView.count بـ:
// سطر واحد: بطاقة كبيرة (Quran) + بطاقة صغيرة (Memorization)
// سطر ثانٍ: بطاقتان متساويتان (Progress + Settings)
Row(
  children: [
    // بطاقة القرآن — 60% العرض
    Expanded(flex: 3, child: _QuranActionCard(...)),
    const SizedBox(width: AppSpacing.sm),
    // بطاقة الحفظ — 40% العرض
    Expanded(flex: 2, child: _MemorizationActionCard(...)),
  ],
),
const SizedBox(height: AppSpacing.sm),
Row(
  children: [
    Expanded(child: _ProgressActionCard(...)),
    const SizedBox(width: AppSpacing.sm),
    Expanded(child: _SettingsActionCard(...)),
  ],
),
```

**قواعد Bento Grid:**
- استخدم `Expanded` و `flex` بدلاً من قيم عرض ثابتة
- كل بطاقة لها `onTap` محفوظ بالضبط كما كان
- أضف `HapticFeedback.lightImpact()` في `onTap` (لم يكن موجوداً)

### 2.3 Skeleton Loader للشاشة الرئيسية
**ملف جديد:** `lib/core/widgets/skeleton_loader.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Skeleton loader عام — يُستخدم كـ base
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius});
  final double width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2D35) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF2A3F4B) : const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius ?? AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

/// Skeleton للشاشة الرئيسية
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero area
          _SkeletonBox(width: double.infinity, height: 180, radius: AppSpacing.radiusXl),
          const SizedBox(height: AppSpacing.lg),
          // Bento grid
          Row(
            children: [
              Expanded(flex: 3, child: _SkeletonBox(width: double.infinity, height: 140, radius: AppSpacing.radiusXl)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 2, child: _SkeletonBox(width: double.infinity, height: 140, radius: AppSpacing.radiusXl)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 80, radius: AppSpacing.radiusLg)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 80, radius: AppSpacing.radiusLg)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton لصفحة التقدم
class ProgressSkeletonLoader extends StatelessWidget {
  const ProgressSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 100, radius: AppSpacing.radiusLg)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 100, radius: AppSpacing.radiusLg)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SkeletonBox(width: double.infinity, height: 180, radius: AppSpacing.radiusXl),
          const SizedBox(height: AppSpacing.lg),
          _SkeletonBox(width: double.infinity, height: 180, radius: AppSpacing.radiusXl),
        ],
      ),
    );
  }
}
```

---

## 🧭 Phase 3 — نظام التنقل

### 3.1 ترقية Bottom Navigation
**الملف:** `lib/core/widgets/app_shell.dart`

> ⚠️ **بنية الكود الفعلية:**
> - `AppShell` — **StatelessWidget** (لا تلمسه!)
> - `_TaliaBottomNav` — **StatelessWidget** (حوّلها فقط إذا احتجت AnimationController)
> - `_NavItem` — StatelessWidget فيه `AnimatedContainer` + `.animate()`
> - `HapticFeedback.selectionClick()` — **موجود أصلاً** في `_onTap`
> - لا يوجد `_AppShellState` — لا تبحث عنه!

**إضافة golden dot indicator متحرك:**
```dart
// الخيار 1 (آمن - بدون تحويل):
// عدّل _NavItem فقط — أضف نقطة ذهبية أسفل الأيقونة باستخدام AnimatedContainer:
if (isSelected)
  AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      color: isDark ? AppColors.gold : AppColors.primary,
      shape: BoxShape.circle,
    ),
  )

// الخيار 2 (إذا أردت spring animation):
// حوّل _TaliaBottomNav فقط (ليس AppShell!) إلى StatefulWidget:
// أضف TickerProviderStateMixin + AnimationController
// لا تلمس AppShell أو StatefulNavigationShell
```

**ترقية blur:**
```dart
// في _TaliaBottomNav.build() — ارفع blur من 16 إلى 20:
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // كان 16
  ...
)
```

**قواعد Bottom Nav:**
- لا تغيّر `_onTap` logic أو `navigationShell.goBranch` binding
- لا تغيّر `AppRoutes` المرتبطة بكل tab
- الـ destinations labels يجب أن تبقى كما هي (ترجمة)
- `HapticFeedback` موجود أصلاً — لا تضيفه مرة أخرى

### 3.2 Page Transitions
**الملف:** `lib/core/theme/app_theme.dart`

```dart
// أضف custom page transitions theme:
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _FadeSlideTransitionBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
),

// أضف class خارج ThemeData:
class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
```

---

## 🧩 Phase 4 — المكونات الأساسية

### 4.1 ترقية `lib/core/widgets/app_button.dart`

```dart
// أضف variant جديد (لا تحذف الموجودين!):
enum AppButtonVariant { primary, secondary, ghost, danger, goldPrimary }
// ↑ danger موجود أصلاً ومستخدم في switch statements — لا تحذفه!

// في build() أضف shimmer للـ goldPrimary:
if (variant == AppButtonVariant.goldPrimary)
  ShaderMask(
    shaderCallback: (bounds) => LinearGradient(
      colors: [AppColors.gold, Colors.white, AppColors.gold],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(bounds),
    child: /* button content */,
  )

// أضف animated dots لـ isLoading:
// بدلاً من CircularProgressIndicator:
if (isLoading)
  Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) => _LoadingDot(delay: i * 200)),
  )
```

**قواعد AppButton:**
- حافظ على كل الـ variants الموجودة
- `key:` يجب أن يبقى محفوظاً
- `onPressed: null` عند التعطيل يجب أن يعمل

### 4.2 ترقية `lib/core/widgets/app_card.dart`

```dart
// أضف factory constructors بدلاً من تعديل الموجود:
factory AppCard.spiritual({
  required Widget child,
  required bool isDark,
  EdgeInsets? padding,
  VoidCallback? onTap,
}) {
  return AppCard._(
    decoration: AppDecorations.spiritualCard(isDark: isDark),
    child: child,
    padding: padding,
    onTap: onTap,
  );
}

factory AppCard.achievement({
  required Widget child,
  required bool isDark,
  EdgeInsets? padding,
  VoidCallback? onTap,
}) {
  return AppCard._(
    decoration: AppDecorations.goldRimCard(isDark: isDark),
    child: child,
    padding: padding,
    onTap: onTap,
  );
}
```

---

## ✨ Phase 5 — التجربة الروحانية

### 5.1 ترقية Empty States
**الملف:** `lib/core/widgets/state_widgets.dart`

```dart
// عدّل ErrorStateWidget لتكون أكثر دفئاً:
// بدلاً من: "حدث خطأ"
// استخدم: رسالة أكثر إنسانية مع زر واضح

// أضف EmptyJourneyWidget لبداية الرحلة:
class EmptyJourneyWidget extends StatelessWidget {
  const EmptyJourneyWidget({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // أيقونة قرآن بسيطة بـ gentle pulse
          const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.gold)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ابدأ رحلتك مع القرآن',
            style: AppTypography.headlineSmall.copyWith(fontFamily: 'Amiri'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onStart,
            child: const Text('ابدأ الآن'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧒 Phase 6 — مسار الأطفال (أولوية قصوى)

> **قاعدة ذهبية للأطفال:** كل تغيير يجب أن يختبر على طفل حقيقي في الذهن.
> هل سيفهمه طفل 6 سنوات؟ هل سيجذبه؟ هل سيحفزه للاستمرار؟

### 6.1 ترقية `KidsTheme`
**الملف:** `lib/features/memorization_plus/presentation/theme/kids_theme.dart`

**أضف الألوان والـ gradients الجديدة — لا تحذف الموجودة:**

```dart
// ─── Sky Palette (جديد) ───────────────────────────────────────────────────────
static const Color skyBlueDeep = Color(0xFF0B1437);
static const Color skyBlueMid  = Color(0xFF1A2E5A);
static const Color emeraldGlow = Color(0xFF00C97A);
static const Color warmSunset  = Color(0xFFFFAA44);

// ─── Kids Card Gradient (جديد) ────────────────────────────────────────────────
static LinearGradient get kidsCardGradient => const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A2E5A), Color(0xFF0F1E3A)],
);

// ─── Background Gradient (عدّل الموجود بحذر) ─────────────────────────────────
// قبل التعديل: تأكد من اسم الـ property الحالي في الكود
// عدّل القيم فقط — لا تحذف الـ property
static LinearGradient get backgroundGradient => const LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF0B1437), // أزرق ليلي دافئ
    Color(0xFF1A2E5A), // أزرق متوسط
    Color(0xFF0D3320), // أخضر داكن دافئ (يوحي بالحديقة)
  ],
  stops: [0.0, 0.5, 1.0],
);
```

### 6.2 الشاشة الرئيسية للأطفال — `KidsGamifiedHomePage`
**الملف:** `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart`

**ترقية `_KidsHomeBottomNav`:**
```dart
// ابحث عن NavigationBar وعدّل:
// 1. أيقونات أكبر: size 32 بدلاً من 24
// 2. ألوان مختلفة لكل tab
// 3. indicator يتحرك بـ spring
// احتفظ بـ destinations كما هي تماماً
```

**إضافة عناصر ديكورية خلف المحتوى:**
```dart
// في Scaffold.body — أضف Stack:
Stack(
  children: [
    // الخلفية المزخرفة
    _KidsBackgroundDecor(), // widget جديد
    // المحتوى الأصلي
    _originalContent,
  ],
)

// _KidsBackgroundDecor — نجوم وهلال ثابتة خفيفة:
class _KidsBackgroundDecor extends StatelessWidget {
  const _KidsBackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer( // مهم! لا تلتقط events
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _StarFieldPainter(),
        ),
      ),
    );
  }
}
```

**قاعدة `IgnorePointer`:** أي عنصر ديكوري خلفي يجب أن يُغلّف بـ `IgnorePointer`.

### 6.3 ترقية `KidsProgressHeader`
**الملف:** `lib/features/memorization_plus/presentation/widgets/kids_progress_header.dart`

```dart
// عدّل _StarCounter ليكون أكبر وأكثر وضوحاً:
// من: Container صغير
// إلى: Row(Icon.star + Text) بحجم 150% + shimmer animation

// progress bar → progress stars row:
// احسب عدد النجوم = عدد مراحل السورة الحالية
// اعرضهم كـ Row من أيقونات نجمة (فارغة/ممتلئة)
```

### 6.4 ترقية `KidsJourneyMap`
**الملف:** `lib/features/memorization_plus/presentation/widgets/kids_journey_map.dart`

**تحسينات بصرية فقط — لا تعدّل CustomPainter logic:**
```dart
// 1. بطاقات locked: أضف opacity overlay 0.5 + رسالة نصية صغيرة
// 2. بطاقات current: أضف pulse animation حول البطاقة
// 3. بطاقات completed: أضف نجمة صغيرة تدور فوق البطاقة
// 4. staggered entry: كل بطاقة تدخل بـ (index * 60ms) delay
```

### 6.5 ترقية `KidsHouseCard`
**الملف:** `lib/features/memorization_plus/presentation/widgets/kids_house_card.dart`

```dart
// أضف حالات واضحة:
// locked: overlay ضبابي + نص "أكمل السابق أولاً"
// current: pulse animation موجودة + سهم "أنت هنا"
// completed: crown icon صغير + glow أكثر كثافة
// needsReview: أيقونة ساعة رملية بدلاً من refresh icon
```

### 6.6 شاشة الاستماع — `KidsGamifiedListenPage`
**الملف:** `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart`

**الأولويات:**
1. تحويل loop indicator من `dots` إلى `نجوم تمتلئ`
2. تكبير زر التشغيل إلى 96×96 مع موجات دائرية
3. استبدال SnackBar بـ inline tooltip
4. تحسين `_RecordingActivePanel` بدائرة pulsing حمراء كبيرة

```dart
// الـ Tooltip الـ inline:
AnimatedOpacity(
  opacity: _showGuidance ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: Container(
    // tooltip بسيط فوق الزر
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    ),
    child: Text(
      _guidanceText, // "استمع أولاً" / "الآن سجّل صوتك"
      style: AppTypography.bodySmall.copyWith(color: Colors.white),
    ),
  ),
)
// Timer لإخفاء التلميح بعد 3 ثوان:
Timer(const Duration(seconds: 3), () {
  if (mounted) setState(() => _showGuidance = false);
});
```

### 6.7 شاشة المكافأة — `KidsGamifiedCompletionPage`
**الملف:** `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart`

```dart
// 1. تغيير خلفية الصفحة إلى gradient ذهبي احتفالي
// 2. تفعيل confetti بأشكال نجمة + هلال (ألوان: ذهبي، أخضر، أبيض فقط)
// 3. نص "أحسنت" بخط Amiri 48px + shimmer sweep
// 4. نجوم تنزل بـ staggered animation
// 5. زر "التالي" بـ pulse animation
// 6. HapticFeedback.heavyImpact() عند دخول الشاشة
```

### 6.8 `KidsMissionCard`
**الملف:** `lib/features/memorization_plus/presentation/widgets/kids_mission_card.dart`

```dart
// 1. تكبير ribbon إلى 80px + تسريع shake animation
// 2. زر "استمر الآن" → "ابدأ المغامرة!" مع pulse نبضة كل 3 ثوان
// 3. نص تحفيزي صغير أسفل البطاقة
```

### 6.9 `KidsLoadingWidget` — ملف جديد
**الملف الجديد:** `lib/features/memorization_plus/presentation/widgets/kids_loading_widget.dart`

```dart
class KidsLoadingWidget extends StatelessWidget {
  const KidsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 48, color: KidsTheme.goldStar)
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 2000.ms)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جاري التحضير...',
            style: AppTypography.titleSmall.copyWith(
              fontFamily: 'Amiri',
              color: KidsTheme.goldStar,
            ),
          ),
        ],
      ),
    );
  }
}

class KidsErrorWidget extends StatelessWidget {
  const KidsErrorWidget({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_rounded, size: 64, color: KidsTheme.goldStar),
          const SizedBox(height: AppSpacing.md),
          Text(
            'يبدو أن شيئاً ما حدث!',
            style: AppTypography.titleMedium.copyWith(fontFamily: 'Amiri'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: KidsTheme.goldStar),
            child: const Text('حاول مرة أخرى'),
          ),
        ],
      ),
    );
  }
}
```

**استبدل كل `LoadingWidget()` في ملفات kids بـ `KidsLoadingWidget()`**
**استبدل `ErrorStateWidget` في ملفات kids بـ `KidsErrorWidget(...)`**

---

## 📊 Phase 7 — صفحة التقدم

### 7.1 App Bar في `progress_page.dart`

```dart
// غيّر ألوان الـ gradient من أزرق إلى Teal متوافق مع الهوية:
isDark
    ? const LinearGradient(
        colors: [Color(0xFF0A2A22), Color(0xFF0D1117)],
      )
    : const LinearGradient(
        colors: [Color(0xFF1A6B5A), Color(0xFF2E4B3A)],
      )
```

### 7.2 `_StreakCard` في `progress_stat_cards.dart`

```dart
// أضف flame animation:
Icon(Icons.local_fire_department_rounded, ...)
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scale(
      begin: const Offset(1, 1),
      end: const Offset(1.15, 1.15),
      duration: 800.ms,
    )

// أضف count-up:
// استخدم TweenAnimationBuilder<int>:
TweenAnimationBuilder<int>(
  tween: IntTween(begin: 0, end: streakDays),
  duration: const Duration(milliseconds: 800),
  curve: Curves.easeOut,
  builder: (context, value, _) => Text('$value', ...),
)

// لافتة "متميز!" عند >= 7 أيام (بدون emoji — استخدم Icon):
if (streakDays >= 7)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 12, color: Colors.white),
        const SizedBox(width: AppSpacing.xs),
        Text('متميز!', style: AppTypography.labelSmall.copyWith(color: Colors.white)),
      ],
    ),
  )
```

### 7.3 `_DetailedProgressCard` في `progress_detailed_card.dart`

```dart
// أعد هيكلة Layout من أفقي إلى عمودي:
// العلوي: دائرة كبيرة (72px) + عنوان + نسبة
// السفلي: progress bars كاملة

// رفع سمك _ProgressBarRow من 4px إلى 8px:
LinearPercentIndicator(
  lineHeight: 8, // كان 4
  ...
)

// تكبير Info Chips نص من 9px إلى 11px:
style: AppTypography.labelSmall.copyWith(
  fontSize: 11, // كان 9
  ...
)
```

### 7.4 `_CertificateCard` في `progress_certificates.dart`

```dart
// حالة فارغة — استبدل:
// الأيقونة الصغيرة → دائرة shimmer + نص "اكسب أول شهادة"

// تأثير دخول على بطاقات الشهادات:
itemBuilder: (context, index) {
  return SizedBox(
    width: 240,
    child: _CertificateCard(cert: certs[index], isDark: isDark)
        .animate(delay: (index * 100).ms)
        .slideX(begin: 0.3)
        .fadeIn(),
  );
}
```

### 7.5 `_AchievementTile` في `progress_achievements.dart`

```dart
// الإنجازات المحقوقة تتميز بـ glow:
if (unlocked)
  Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.25),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    ),
    child: _tileContent,
  )
else
  Opacity(opacity: 0.5, child: _tileContent)

// staggered entry:
.animate(delay: (index * 30).ms)
.fadeIn()
.slideY(begin: 0.1)
```

---

## 📚 Phase 8 — مسار الكبار

### 8.1 `_HubDailyPlanSummaryCard`

```dart
// استبدل Card العادي بـ:
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.08),
        AppColors.primary.withValues(alpha: 0.03),
      ],
    ),
    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.2),
    ),
  ),
  child: /* نفس المحتوى الحالي */,
)

// استبدل LinearProgressIndicator بـ نقاط:
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(plan.totalItems, (i) {
    final done = i < plan.requiredCompletedCount;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: done ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: done ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }),
)
```

### 8.2 `_HubActionCard` — تمييز بصري

```dart
// أضف ألوان مختلفة للـ icon background حسب الوظيفة:
// "أكمل خطة اليوم" → primary @ 12% (موجود، جيد)
// "تدرّب بالسورة"  → Teal @ 8%
// "مراجعة بالتسميع" → gold @ 8%
// "إعدادات الخطة"  → surface عادي (بدون تغيير)

// staggered delay:
.animate(delay: (cardIndex * 50).ms)
.fadeIn()
.slideY(begin: 0.03)
```

### 8.3 `_UnifiedPathChoiceCard` — تحسين اختيار المسار

```dart
// أضف bullets صغيرة للبالغ:
Column(
  children: [
    '✔ خطة يومية مخصصة',
    '✔ مراجعة ذكية بالتسميع',
    '✔ تتبع التقدم التفصيلي',
  ].map((text) => _BulletPoint(text: text)).toList(),
)

// خلفية gradient حسب الاختيار:
// بالغ → gradient Teal
// طفل → gradient Gold (منسجم مع KidsTheme)

// تأثير دخول من الجهة المعاكسة:
// بطاقة البالغ: slideX من اليمين
// بطاقة الطفل: slideX من اليسار
```

---

## 🤲 Phase 9 — الأذكار والأدعية

### 9.1 App Bar في `azkar_page.dart`

```dart
// غيّر colors من أزرق فاتح إلى Teal داكن:
isDark
    ? const LinearGradient(
        colors: [Color(0xFF0A1E2A), Color(0xFF071520)],
      )
    : const LinearGradient(
        colors: [Color(0xFF0F4C5C), Color(0xFF0A3545)],
      )
// أيقونة المسجد في الخلفية — احتفظ بها كما هي (جيدة!)
```

### 9.2 بطاقات الفئات في `azkar_page.dart`

```dart
// بطاقة الصباح — غيّر gradient:
gradientColors: const [Color(0xFFC07820), Color(0xFFE8A020)]

// بطاقة المساء — احتفظ بالأزرق الداكن (جيد) + أضف نجوم خفيفة في الخلفية
// بطاقة العام — احتفظ بـ Teal (متسق مع هوية التطبيق)
// بطاقة الأدعية — غيّر من أحمر إلى بنفسجي دافئ:
gradientColors: const [Color(0xFF8B5CF6), Color(0xFF5B21B6)]

// أضف شريط تقدم صغير (6px) أسفل كل بطاقة:
// يحتاج استعلام عن completedCount من الـ cache — اختياري
```

### 9.3 `_ZikrReaderPage` في `azkar_category_page.dart`

```dart
// أضف tinted background حسب الفئة:
Color _getTintColor(AzkarCategory category) => switch (category) {
  AzkarCategory.morning => const Color(0xFFE8A020),
  AzkarCategory.evening => const Color(0xFF2D5A8E),
  AzkarCategory.general => AppColors.primary,
  AzkarCategory.duas    => const Color(0xFF8B5CF6),
};

// في build():
decoration: BoxDecoration(
  color: isDark ? AppColors.darkCard : AppColors.lightCard,
  // أضف tint خفيف جداً:
  gradient: LinearGradient(
    colors: [
      _getTintColor(category).withValues(alpha: 0.03),
      isDark ? AppColors.darkCard : AppColors.lightCard,
    ],
  ),
  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
  border: Border.all(
    color: _getTintColor(category).withValues(alpha: 0.15), // بدلاً من borderColor العادي
  ),
  ...
)

// حجم الخط الافتراضي: 26 بدلاً من 22:
// _fontSizes = [22.0, 26.0, 30.0]
// _fontSizeIndex = 1 (يبدأ بـ 26)
// هذا التغيير بسيط وآمن
```

### 9.4 زر العداد في `azkar_category_page.dart`

```dart
// تحويل لون الدائرة حسب الفئة:
// ابحث عن AnimatedContainer الذي يحتوي الـ gradient الحالي
// عدّل gradient colors حسب الفئة:
gradient: session.isDone
    ? const LinearGradient(colors: [AppColors.success, Color(0xFF1E5D46)])
    : _getCounterGradient(widget.category, isDark),

// أضف ripple عند الضغط:
// استخدم Stack + AnimatedContainer أو TweenAnimationBuilder
// مع InkWell (لكن بدون تغيير onTap logic)
```

---

## 🔍 قائمة التحقق النهائية (مبنية على Pro-Rules Canonical Checklist)

قبل إعلان اكتمال كل Phase، تأكد من:

### Technical Checks
- [ ] `flutter analyze` — صفر errors, صفر warnings
- [ ] `flutter build apk --debug` — يُبنى بنجاح
- [ ] لا `RenderFlex overflow` في أي شاشة
- [ ] لا `setState called after dispose` في الـ logs
- [ ] كل `AnimationController` له `dispose()` مقابل

### Visual Quality (pro-rules §Visual)
- [ ] لا emojis كأيقونات — استخدم `Icons.*` أو SVG
- [ ] أيقونات من نفس العائلة وبنفس السُمك
- [ ] الضغط (pressed state) لا يحرّك layout المحيط
- [ ] ألوان من semantic tokens فقط — لا hex مباشر في widgets

### Interaction (pro-rules §Interaction)
- [ ] كل عنصر تفاعلي فيه pressed feedback (ripple/opacity/scale)
- [ ] Touch targets >= 48×48dp (Material standard)
- [ ] Micro-interactions بين 150-300ms مع native easing
- [ ] Disabled states واضحة بصرياً وغير تفاعلية
- [ ] ترتيب Screen Reader focus يطابق الترتيب البصري

### Light/Dark Mode (pro-rules §Contrast)
- [ ] Primary text contrast >= 4.5:1 في الوضعين
- [ ] Secondary text contrast >= 3:1 في الوضعين
- [ ] Borders/dividers مرئية في الوضعين
- [ ] Modal scrim بين 40-60% opacity
- [ ] الوضعان مختبران **فعلياً** وليس مُفترضان

### Layout (pro-rules §Layout)
- [ ] Safe areas محترمة (headers, tab bars, bottom CTAs)
- [ ] Scroll content لا يختفي خلف fixed bars
- [ ] مختبر على: 360px, 390px, 430px — **portrait + landscape**
- [ ] Horizontal insets تتكيف مع حجم الجهاز
- [ ] 4/8dp spacing rhythm في components, sections, pages
- [ ] Long text لا يمتد edge-to-edge على شاشات كبيرة

### Accessibility (pro-rules §Accessibility)
- [ ] كل الأيقونات والصور لها `Semantics` labels
- [ ] حقول الإدخال لها labels و hints و error messages
- [ ] اللون ليس المؤشر الوحيد (أيقونة/نص مساعد)
- [ ] **Reduced motion مدعوم** بدون كسر layout
- [ ] **Dynamic Type / Text Scaling 1.5x** مدعوم بدون overflow

### Performance
- [ ] `const` على كل widget ثابتة
- [ ] لا حسابات ثقيلة في `build()`
- [ ] `RepaintBoundary` حول animations ثقيلة
- [ ] `dispose()` لكل AnimationController
- [ ] `CustomPaint` يستخدم `shouldRepaint` بشكل صحيح
- [ ] Lists بأكثر من 50 عنصر تستخدم `ListView.builder`

---

## 🚨 أخطاء شائعة يجب تجنبها

```dart
// ❌ خطأ: نسيان dispose
class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  // لا يوجد dispose! → memory leak

// ✅ صح:
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ❌ خطأ: استخدام BuildContext بعد async gap
onPressed: () async {
  await someAsyncOperation();
  context.pop(); // قد يكون الـ context غير صالح!

// ✅ صح:
  await someAsyncOperation();
  if (!context.mounted) return;
  context.pop();

// ❌ خطأ: تعديل State في init بدون addPostFrameCallback
void initState() {
  setState(() { ... }); // ← خطأ في initState!

// ✅ صح:
void initState() {
  super.initState(); // ← إلزامي أولاً
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() { ... });
  });
}

// ❌ خطأ: hardcoded colors
color: Color(0xFF1A6B5A) // في مكان عشوائي في الكود

// ✅ صح:
color: AppColors.primary // أو KidsTheme.forestGreen

// ❌ خطأ: تجاهل reduced motion
widget.animate().fadeIn().slideY() // يتحرك حتى لو المستخدم طلب إيقاف الحركة

// ✅ صح (flutter_animate يحترم هذا تلقائياً):
// تأكد من عدم override لـ Animate.restartOnHotReload أو تعطيل الاحترام
// إذا استخدمت AnimationController مباشرةً:
final reduceMotion = MediaQuery.of(context).disableAnimations;
if (!reduceMotion) {
  _controller.repeat(reverse: true);
}
```

---

## 📁 هيكل الملفات المتوقع بعد التنفيذ

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         ← [محدّث] + ambient colors, spiritual palette
│   │   ├── app_decorations.dart    ← [محدّث] + spiritualCard, goldRimCard, shimmerCard
│   │   └── app_theme.dart          ← [محدّث] + custom page transitions
│   └── widgets/
│       ├── skeleton_loader.dart    ← [جديد] Home + Progress skeletons
│       ├── app_button.dart         ← [محدّث] + goldPrimary variant (danger محفوظ!)
│       ├── app_card.dart           ← [محدّث] + spiritual, achievement constructors
│       └── state_widgets.dart      ← [محدّث] + EmptyJourneyWidget
└── features/
    ├── memorization_plus/
    │   └── presentation/
    │       ├── theme/
    │       │   └── kids_theme.dart          ← [محدّث] + Sky palette
    │       └── widgets/
    │           └── kids_loading_widget.dart  ← [جديد]
    └── (باقي الملفات محدّثة في مكانها)
```

---

## 🔗 خريطة التبعيات بين المراحل

```
Phase 1.1 (AppColors) ─┐
                       ├─→ Phase 1.2 (AppDecorations) ← يعتمد على 1.1 إلزامياً
                       │
Phase 1 ──────────────→ Phase 4 (Core Widgets) ← يعتمد على ألوان وdecorations جديدة
                       │
Phase 1 + 4 ──────────→ Phase 2 (Home) ← يستخدم skeleton + spiritual cards
                       │
Phase 1 ──────────────→ Phase 3 (Navigation) ← مستقل عن Phase 2
                       │
Phase 1 + 4 ──────────→ Phase 5 (Celebrations) ← مستقل
                       │
Phase 1 ──────────────→ Phase 6 (Kids) ← أطول phase، مستقل عن 2-5
                       │
Phase 1 + 4 ──────────→ Phase 7 (Progress) ← يستخدم skeleton
                       │
Phase 1 ──────────────→ Phase 8 (Adults) ┐
                                         ├─ يمكن بالتوازي
Phase 1 ──────────────→ Phase 9 (Azkar)  ┘
```

## 🎯 ترتيب التنفيذ الموصى به

```
Phase 1.1 → Phase 1.2 → Phase 4 → Phase 3 → Phase 2 → Phase 5
    ↓
Phase 6 (أطفال - كامل)
    ↓
Phase 7 (تقدم)
    ↓
Phase 8 (كبار) + Phase 9 (أذكار) [يمكن بالتوازي]
```

**Phase 1.1 أولاً دائماً** ← كل الـ Phases تعتمد على الألوان الجديدة.
**Phase 4 قبل Phase 2** ← Home تستخدم skeleton + spiritual cards.

---

> **ملاحظة:** هذا الملف مرجع للتنفيذ — القرار النهائي لكل تفصيل يعود لمن ينفذه.
> الأولوية دائماً: **لا تكسر ما يعمل** ثم **حسّن ما لا يعمل** ثم **أضف ما يُبهج**.
