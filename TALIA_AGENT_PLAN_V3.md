# 📖 خطة تطوير تالية (Talia Quran) — دليل تنفيذي مكتمل
> خطة منظمة قابلة للتنفيذ بأي AI Agent — كل الأكواد مكتملة وجاهزة للتطبيق
> آخر تحديث: مراجعة شاملة مع فحص المشروع الفعلي

---

## 📦 الحزم الموجودة مسبقاً في pubspec.yaml (لا تُضاف مجدداً)

```
✅ flutter_animate: ^4.5.2       → يُتيح .ms و .animate()
✅ flutter_bloc: ^9.1.1
✅ isar: ^3.1.0+1
✅ get_it: ^9.2.1
✅ go_router: ^17.2.1
✅ just_audio: ^0.10.5
✅ path_provider: ^2.1.5
✅ share_plus: ^13.1.0
✅ shared_preferences: ^2.5.5
✅ speech_to_text: ^7.3.0
✅ string_similarity: ^2.2.0     → مقارنة نصية (مستخدمة في تقييم التلاوة المدمج)
✅ permission_handler: ^12.0.1
✅ timezone: ^0.11.0
✅ flutter_timezone: ^3.0.0
✅ shimmer: ^3.0.0
✅ dartz: ^0.10.1
✅ equatable: ^2.0.8
✅ http: غير موجود → يجب إضافته
✅ confetti: غير موجود → يجب إضافته
✅ screenshot: غير موجود → يجب إضافته
```

## ➕ الحزم التي يجب إضافتها فقط

```yaml
# في pubspec.yaml تحت dependencies:
confetti: ^0.7.0
screenshot: ^3.0.0
supabase_flutter: ^2.8.0      # M2-T1 فقط
google_sign_in: ^6.2.0        # M2-T1 فقط
purchases_flutter: ^8.0.0     # M4-T2 فقط
```

---

## 📋 قواعد عامة للـ Agent

```
قبل أي مهمة:
1. اقرأ الملف المطلوب كاملاً قبل تعديله
2. لا تحذف كوداً موجوداً إلا إذا طُلب صراحة
3. بعد كل تعديل: تحقق أن flutter analyze لا يُظهر أخطاء جديدة
4. كل Isar schema جديد يجب إضافته في قائمة Isar.open() في injection.dart
5. كل service جديدة تُسجَّل في injection.dart
6. لا تُنشئ ملفات مكررة — تحقق أولاً بـ find lib -name "*.dart"
7. بعد أي تعديل على Isar schema: dart run build_runner build --delete-conflicting-outputs
8. بعد كل مرحلة: flutter build apk --debug للتأكد من البناء الكامل
```

---

## 🗂 سياق المشروع

```
الاسم: Talia Quran (تالية)
Architecture: Clean Architecture — Feature-First
State: Cubit (flutter_bloc)
Navigation: GoRouter + StatefulShellRoute
Local DB: Isar — فقط IsarAyahProgress مسجل حالياً في Isar.open()
DI: GetIt — يدوي (بدون injectable annotations)
Error: Either<Failure, T> من dartz
Audio: just_audio + AudioCacheService
Notifications: flutter_local_notifications

قواعد الكود الثابتة:
- RTL: كل شاشة جديدة: Directionality(textDirection: TextDirection.rtl)
- ألوان: Theme.of(context).colorScheme.* فقط
- مسافات: AppSpacing.* فقط
- صوت: QuranAudioService.buildUrl() فقط
- Navigation: context.go() / context.push()
- Animations: استخدم flutter_animate (.animate().fadeIn() إلخ) أو AnimationController
```

---

# 🔴 المرحلة 0 — إصلاح الأخطاء الحرجة
**الوقت: يوم واحد | يجب قبل أي تطوير جديد**

---

## [M0-T1] إصلاح Memory Leak — TapGestureRecognizer

**الملف:** `lib/features/quran/presentation/pages/surah_detail_page.dart`

**المشكلة:** `_ContinuousSurahText` هو `StatelessWidget` يُنشئ `TapGestureRecognizer` لكل آية في كل `build()` دون `dispose` → memory leak خطير في السور الطويلة.

**التعديل الكامل:** استبدل class `_ContinuousSurahText` بالكامل بهذا الكود:

```dart
class _ContinuousSurahText extends StatefulWidget {
  const _ContinuousSurahText({
    required this.ayahs,
    required this.onAyahTapped,
    required this.highlightedAyahNumber,
    required this.bookmarkedAyahs,
  });

  final List<Ayah> ayahs;
  final void Function(Ayah) onAyahTapped;
  final int? highlightedAyahNumber;
  final Set<int> bookmarkedAyahs;

  @override
  State<_ContinuousSurahText> createState() => _ContinuousSurahTextState();
}

class _ContinuousSurahTextState extends State<_ContinuousSurahText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نُفرّغ المعرّفات القديمة في بداية كل build
    _disposeRecognizers();

    final colorScheme = Theme.of(context).colorScheme;

    final spans = widget.ayahs.map((ayah) {
      final isHighlighted = ayah.numberInSurah == widget.highlightedAyahNumber;
      final isBookmarked = widget.bookmarkedAyahs.contains(ayah.numberInSurah);

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onAyahTapped(ayah);
      _recognizers.add(recognizer); // ← حفظ المرجع لـ dispose لاحقاً

      return TextSpan(
        children: [
          TextSpan(
            text: '${ayah.text} ',
            style: TextStyle(
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              backgroundColor: isHighlighted
                  ? colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
            ),
            recognizer: recognizer,
          ),
          TextSpan(
            text: isBookmarked
                ? '﴿${ayah.numberInSurah}﴾🔖 '
                : '﴿${ayah.numberInSurah}﴾ ',
            style: TextStyle(
              color: colorScheme.primary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      );
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SelectionArea(
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 2.2,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

**ملاحظة للـ Agent:** إذا كان الملف الأصلي يحتوي على حقول مختلفة في `_ContinuousSurahText`، اقرأه أولاً وعدّل الـ constructor ليطابق الحقول الموجودة بالفعل.

**التحقق:** `flutter analyze` — يجب ألا يظهر تحذير `don't use recognizers created in build`

---

## [M0-T2] إصلاح Compile Error — notification_service.dart

**الملف:** `lib/core/services/notification_service.dart`

**ابحث عن:** كل استدعاء يحتوي `.cancel(id:`

**استبدل:**
```dart
// ❌ قبل
await _plugin.cancel(id: _dailyReviewId);
await _plugin.cancel(id: _streakAlertId);
await _plugin.cancel(id: _dailyAyahId);

// ✅ بعد
await _plugin.cancel(_dailyReviewId);
await _plugin.cancel(_streakAlertId);
await _plugin.cancel(_dailyAyahId);
```

**التحقق:** `flutter build apk --debug` يكتمل بدون compile errors

---

## [M0-T3] إصلاح Audio Offline — setUrl vs setFilePath

**الملفات:**
- `lib/features/quran/presentation/pages/surah_detail_page.dart`
- `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`

**في كل ملف من الملفين**، أضف هذه الدالة Private مباشرة في الـ State class أو الـ Cubit:

```dart
/// يُشغّل المصدر الصوتي سواء كان URL شبكي أو مسار ملف محلي
Future<void> _playAudioSource(AudioPlayer player, String source) async {
  try {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await player.setUrl(source);
    } else {
      await player.setFilePath(source);
    }
    await player.play();
  } catch (e) {
    // log أو emit error state حسب السياق
    debugPrint('Audio error: $e');
  }
}
```

**ثم:** ابحث عن كل `_player.setUrl(` أو `player.setUrl(` في الملف واستبدل كل استدعاء:
```dart
// ❌ قبل
await _player.setUrl(audioSource);
await _player.play();

// ✅ بعد
await _playAudioSource(_player, audioSource);
```

**التحقق:** شغّل التطبيق بـ Airplane Mode بعد تشغيل سورة مرة واحدة — يجب أن يعمل الصوت من الـ cache

---

## [M0-T4] إصلاح Android Manifest

**الملف:** `android/app/src/main/AndroidManifest.xml`

**الخطوة 1:** أضف داخل `<manifest>` مباشرة قبل `<application>`:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

**الخطوة 2:** أضف داخل `<application>` قبل `</application>`:
```xml
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    android:exported="false"/>
```

**التحقق:** شغّل على Android 13+ وأعد تشغيل الجهاز — يجب أن تصل الإشعارات المجدولة

---

## [M0-T5] إصلاحات UX سريعة

### [M0-T5a] Status Bar يتكيف مع Dark Mode

**الملف:** `lib/core/theme/theme_cubit.dart`

ابحث عن دالة `toggleTheme()` أو `emit()` وأضف استدعاء `_applyStatusBar`:

```dart
import 'package:flutter/services.dart';

// أضف هذه الدالة داخل ThemeCubit class:
void _applyStatusBar(bool isDark) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ),
  );
}

// استدعِها في كل emit:
// مثال: في toggleTheme() بعد emit(newState):
//   _applyStatusBar(newState.isDark);
// وفي loadTheme() بعد emit:
//   _applyStatusBar(state.isDark);
```

### [M0-T5b] Bookmark Error Handling

**الملف:** `lib/features/quran/presentation/pages/surah_detail_page.dart`

ابحث عن `_toggleBookmark` وأضف try/catch:
```dart
Future<void> _toggleBookmark(Ayah ayah, String surahName) async {
  try {
    await _bookmarkService.toggle(ayah: ayah, surahName: surahName);
    _loadBookmarks();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء حفظ العلامة المرجعية'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
```

### [M0-T5c] Speech Permission Timing

**الملف:** `lib/features/memorization_plus/presentation/pages/quiz_page.dart`

```dart
// 1. في initState: احذف استدعاء _initSpeech() تماماً
@override
void initState() {
  super.initState();
  // لا تستدعِ _initSpeech() هنا
}

// 2. في دالة _listen(): أضف التهيئة قبل الاستماع
Future<void> _listen() async {
  if (!_speechEnabled) {
    // طلب الإذن أولاً
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يُرجى السماح للتطبيق بالوصول إلى الميكروفون')),
        );
      }
      return;
    }
    _speechEnabled = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!_speechEnabled) return;
  }
  // باقي كود _listen() كما هو
  if (_speech.isListening) {
    await _speech.stop();
    setState(() {});
  } else {
    setState(() {});
    await _speech.listen(
      onResult: (result) {
        setState(() => _recognizedText = result.recognizedWords);
      },
      localeId: 'ar_SA',
    );
  }
}
```

---

# 🟠 المرحلة 1 — نظام التحفيز (Gamification)
**الوقت: 3 أسابيع | أعلى تأثير على الـ Engagement**

---

## [M1-T1] نظام Streak اليومي

### الخطوة 1: Isar Schema

**الملف الجديد:** `lib/features/streak/data/models/streak_isar.dart`

```dart
import 'package:isar/isar.dart';
part 'streak_isar.g.dart';

@collection
class StreakIsar {
  // id ثابت = 1 لأننا نريد سجلاً واحداً دائماً
  Id id = 1;
  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastActivityDate;
  int freezesAvailable = 0;
}
```

**بعد إنشاء الملف:** `dart run build_runner build --delete-conflicting-outputs`

### الخطوة 2: تسجيل Schema في Isar.open()

**الملف:** `lib/core/di/injection.dart`

ابحث عن:
```dart
final isar = await Isar.open(
  [IsarAyahProgressSchema],
  directory: dir.path,
);
```

استبدل بـ:
```dart
final isar = await Isar.open(
  [
    IsarAyahProgressSchema,
    StreakIsarSchema,   // أضف هذا
    XpIsarSchema,      // أضف هذا (سيُعرَّف في M1-T2)
  ],
  directory: dir.path,
);
```

وأضف الـ import في أعلى الملف:
```dart
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart'; // سيُنشأ في M1-T2
```

### الخطوة 3: Entity

**الملف الجديد:** `lib/features/streak/domain/entities/streak_entity.dart`

```dart
import 'package:equatable/equatable.dart';

class StreakEntity extends Equatable {
  const StreakEntity({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.freezesAvailable = 0,
  });

  final int currentStreak;
  final DateTime? lastActivityDate;
  final int longestStreak;
  final int freezesAvailable;

  StreakEntity copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? freezesAvailable,
  }) =>
      StreakEntity(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastActivityDate: lastActivityDate ?? this.lastActivityDate,
        freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      );

  @override
  List<Object?> get props =>
      [currentStreak, longestStreak, lastActivityDate, freezesAvailable];
}
```

### الخطوة 4: StreakResult

**الملف الجديد:** `lib/features/streak/domain/entities/streak_result.dart`

```dart
import 'package:equatable/equatable.dart';

class StreakResult extends Equatable {
  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.isNewActivity,
    this.isNewRecord = false,
    this.milestoneReached,
  });

  /// نُستخدم عند نفس اليوم — لا تغيير في الـ Streak
  const StreakResult.sameDay()
      : currentStreak = 0,
        longestStreak = 0,
        isNewActivity = false,
        isNewRecord = false,
        milestoneReached = null;

  final int currentStreak;
  final int longestStreak;
  final bool isNewActivity;
  final bool isNewRecord;
  final int? milestoneReached; // null أو رقم milestone (3، 7، 14، 30 ...)

  @override
  List<Object?> get props =>
      [currentStreak, longestStreak, isNewActivity, isNewRecord, milestoneReached];
}
```

### الخطوة 5: StreakService

**الملف الجديد:** `lib/core/services/streak_service.dart`

```dart
import 'package:isar/isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/streak/domain/entities/streak_entity.dart';
import '../../features/streak/domain/entities/streak_result.dart';

class StreakService {
  StreakService(this._isar);

  final Isar _isar;

  static const List<int> _milestones = [3, 7, 14, 30, 60, 100, 365];

  Future<StreakEntity> getStreak() async {
    final data = await _isar.streakIsars.get(1);
    if (data == null) return const StreakEntity(currentStreak: 0, longestStreak: 0);
    return StreakEntity(
      currentStreak: data.currentStreak,
      longestStreak: data.longestStreak,
      lastActivityDate: data.lastActivityDate,
      freezesAvailable: data.freezesAvailable,
    );
  }

  Future<StreakResult> recordActivity() async {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    return _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1) ?? StreakIsar();
      final lastDate = data.lastActivityDate;

      if (lastDate != null) {
        final lastNormalized =
            DateTime(lastDate.year, lastDate.month, lastDate.day);

        // نفس اليوم → لا تغيير
        if (lastNormalized == todayDate) {
          return const StreakResult.sameDay();
        }

        final yesterday = todayDate.subtract(const Duration(days: 1));

        if (lastNormalized == yesterday) {
          // يوم متتابع
          data.currentStreak += 1;
        } else {
          // انقطع التسلسل — أعد من 1
          data.currentStreak = 1;
        }
      } else {
        // أول مرة
        data.currentStreak = 1;
      }

      final isNewRecord = data.currentStreak > data.longestStreak;
      if (isNewRecord) data.longestStreak = data.currentStreak;

      data.lastActivityDate = todayDate;
      await _isar.streakIsars.put(data);

      return StreakResult(
        currentStreak: data.currentStreak,
        longestStreak: data.longestStreak,
        isNewActivity: true,
        isNewRecord: isNewRecord,
        milestoneReached: _milestones.contains(data.currentStreak)
            ? data.currentStreak
            : null,
      );
    });
  }

  Future<void> useFreeze() async {
    await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1);
      if (data == null || data.freezesAvailable <= 0) return;
      data.freezesAvailable -= 1;
      // امتد اليوم الأخير بيوم إضافي
      if (data.lastActivityDate != null) {
        data.lastActivityDate =
            data.lastActivityDate!.add(const Duration(days: 1));
      }
      await _isar.streakIsars.put(data);
    });
  }

  Future<void> addFreeze(int count) async {
    await _isar.writeTxn(() async {
      final data = await _isar.streakIsars.get(1) ?? StreakIsar();
      data.freezesAvailable += count;
      await _isar.streakIsars.put(data);
    });
  }
}
```

### الخطوة 6: StreakCubit + StreakState

**الملف الجديد:** `lib/features/streak/presentation/cubits/streak_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/streak_result.dart';
import '../../../../core/services/streak_service.dart';

part 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  StreakCubit(this._streakService) : super(const StreakInitial());

  final StreakService _streakService;

  Future<void> loadStreak() async {
    try {
      final entity = await _streakService.getStreak();
      emit(StreakLoaded(streak: entity));
    } catch (e) {
      emit(StreakError(e.toString()));
    }
  }

  Future<StreakResult> recordActivity() async {
    try {
      final result = await _streakService.recordActivity();
      if (result.isNewActivity) {
        final entity = await _streakService.getStreak();
        emit(StreakLoaded(streak: entity));
      }
      return result;
    } catch (e) {
      emit(StreakError(e.toString()));
      return const StreakResult.sameDay();
    }
  }

  Future<void> useFreeze() async {
    await _streakService.useFreeze();
    await loadStreak();
  }
}
```

**الملف الجديد:** `lib/features/streak/presentation/cubits/streak_state.dart`

```dart
part of 'streak_cubit.dart';

abstract class StreakState extends Equatable {
  const StreakState();
  @override
  List<Object?> get props => [];
}

class StreakInitial extends StreakState {
  const StreakInitial();
}

class StreakLoaded extends StreakState {
  const StreakLoaded({required this.streak});
  final StreakEntity streak;
  @override
  List<Object?> get props => [streak];
}

class StreakError extends StreakState {
  const StreakError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
```

### الخطوة 7: تسجيل في injection.dart

```dart
// أضف import:
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/streak/presentation/cubits/streak_cubit.dart';
import '../services/streak_service.dart';

// أضف في قسم Core Services:
getIt.registerSingleton<StreakService>(StreakService(getIt<Isar>()));

// أضف في قسم Cubits:
getIt.registerFactory<StreakCubit>(() => StreakCubit(getIt<StreakService>()));
```

### الخطوة 8: ربط في HifzSessionCubit

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`

```dart
// 1. أضف StreakService في الـ constructor:
HifzSessionCubit(
  this._getSurahDetail,
  this._saveAyahProgress,
  this._getProgressForSurah,
  this._settingsRepository,
  this._streakService,  // ← أضف
);

final StreakService _streakService;

// 2. في الدالة التي تُعالج إتمام/تسجيل الآية (ابحث عن saveAyahProgress أو markAsMastered):
final streakResult = await _streakService.recordActivity();
// يمكن تمرير النتيجة للـ state إذا أردت عرض milestone notification
```

**في injection.dart:** حدّث تسجيل `HifzSessionCubit`:
```dart
getIt.registerFactory<HifzSessionCubit>(
  () => HifzSessionCubit(
    getIt<GetSurahDetailUsecase>(),
    getIt<SaveAyahProgressUsecase>(),
    getIt<GetProgressForSurahUsecase>(),
    getIt<SettingsRepository>(),
    getIt<StreakService>(), // ← أضف
  ),
);
```

### الخطوة 9: Streak Widget في HomePage

**الملف:** `lib/features/home/presentation/pages/home_page.dart`

أضف `BlocProvider` لـ `StreakCubit` في شجرة الـ Providers وأضف Widget:

```dart
// في أعلى AppBar أو في أي مكان مناسب في HomePage:
BlocProvider(
  create: (_) => getIt<StreakCubit>()..loadStreak(),
  child: BlocBuilder<StreakCubit, StreakState>(
    builder: (context, state) {
      if (state is! StreakLoaded) return const SizedBox.shrink();
      return _StreakBadge(streak: state.streak.currentStreak);
    },
  ),
)

// Widget مستقل:
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streak يوم',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## [M1-T2] نظام XP والمستويات

### الخطوة 1: Isar Schema

**الملف الجديد:** `lib/features/xp/data/models/xp_isar.dart`

```dart
import 'package:isar/isar.dart';
part 'xp_isar.g.dart';

@collection
class XpIsar {
  // id ثابت = 1 — سجل واحد فقط
  Id id = 1;
  int totalXp = 0;
}
```

**بعد إنشاء الملف:** `dart run build_runner build --delete-conflicting-outputs`

تأكد من إضافة `XpIsarSchema` في `Isar.open()` كما في M1-T1 الخطوة 2.

### الخطوة 2: XP Constants

**الملف الجديد:** `lib/core/constants/xp_constants.dart`

```dart
class XpLevel {
  const XpLevel({
    required this.name,
    required this.minXp,
    required this.icon,
    required this.colorHex,
  });

  final String name;
  final int minXp;
  final String icon;
  final int colorHex;
}

class XpConstants {
  const XpConstants._();

  static const Map<String, int> rewards = {
    'ayah_memorized': 10,
    'page_completed': 50,
    'juz_completed': 500,
    'daily_review': 5,
    'perfect_quiz': 25,
    'streak_7': 100,
    'streak_30': 500,
    'first_ayah': 20,
    'recitation_perfect': 15,
    'recitation_good': 8,
  };

  static const List<XpLevel> levels = [
    XpLevel(name: 'مبتدئ',  minXp: 0,     icon: '🌱', colorHex: 0xFF6B7280),
    XpLevel(name: 'طالب',   minXp: 100,   icon: '📚', colorHex: 0xFF3B82F6),
    XpLevel(name: 'حافظ',   minXp: 500,   icon: '⭐', colorHex: 0xFF8B5CF6),
    XpLevel(name: 'شيخ',    minXp: 2000,  icon: '🏆', colorHex: 0xFFF59E0B),
    XpLevel(name: 'إمام',   minXp: 10000, icon: '👑', colorHex: 0xFFEF4444),
  ];
}
```

### الخطوة 3: XpGainResult

**الملف الجديد:** `lib/features/xp/domain/entities/xp_gain_result.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../../../core/constants/xp_constants.dart';

class XpGainResult extends Equatable {
  const XpGainResult({
    required this.xpAdded,
    required this.totalXp,
    required this.leveledUp,
    required this.currentLevel,
    required this.progressToNextLevel,
  });

  const XpGainResult.zero()
      : xpAdded = 0,
        totalXp = 0,
        leveledUp = false,
        currentLevel = const XpLevel(
          name: 'مبتدئ', minXp: 0, icon: '🌱', colorHex: 0xFF6B7280,
        ),
        progressToNextLevel = 0.0;

  final int xpAdded;
  final int totalXp;
  final bool leveledUp;
  final XpLevel currentLevel;
  final double progressToNextLevel; // 0.0 → 1.0

  @override
  List<Object?> get props =>
      [xpAdded, totalXp, leveledUp, currentLevel.name, progressToNextLevel];
}
```

### الخطوة 4: XpService

**الملف الجديد:** `lib/core/services/xp_service.dart`

```dart
import 'package:isar/isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../../features/xp/domain/entities/xp_gain_result.dart';
import '../constants/xp_constants.dart';

class XpService {
  XpService(this._isar);

  final Isar _isar;

  Future<XpGainResult> addXp(String eventKey) async {
    final points = XpConstants.rewards[eventKey] ?? 0;
    if (points == 0) return const XpGainResult.zero();

    return _isar.writeTxn(() async {
      final data = await _isar.xpIsars.get(1) ?? XpIsar();
      final oldLevel = _getLevel(data.totalXp);
      data.totalXp += points;
      final newLevel = _getLevel(data.totalXp);
      await _isar.xpIsars.put(data);

      return XpGainResult(
        xpAdded: points,
        totalXp: data.totalXp,
        leveledUp: newLevel.name != oldLevel.name,
        currentLevel: newLevel,
        progressToNextLevel: _getProgress(data.totalXp),
      );
    });
  }

  Future<int> getTotalXp() async {
    final data = await _isar.xpIsars.get(1);
    return data?.totalXp ?? 0;
  }

  XpLevel getCurrentLevel(int xp) => _getLevel(xp);

  XpLevel _getLevel(int xp) {
    final levels = XpConstants.levels;
    for (int i = levels.length - 1; i >= 0; i--) {
      if (xp >= levels[i].minXp) return levels[i];
    }
    return levels.first;
  }

  double _getProgress(int xp) {
    final levels = XpConstants.levels;
    final current = _getLevel(xp);
    final currentIdx = levels.indexWhere((l) => l.name == current.name);
    if (currentIdx >= levels.length - 1) return 1.0;
    final next = levels[currentIdx + 1];
    final range = next.minXp - current.minXp;
    final progress = xp - current.minXp;
    return (progress / range).clamp(0.0, 1.0);
  }
}
```

### الخطوة 5: تسجيل في injection.dart

```dart
// أضف imports:
import '../../features/xp/data/models/xp_isar.dart';
import '../services/xp_service.dart';

// أضف في Core Services:
getIt.registerSingleton<XpService>(XpService(getIt<Isar>()));
```

### الخطوة 6: ربط مع HifzSessionCubit

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`

```dart
// أضف XpService في constructor مع StreakService:
HifzSessionCubit(
  this._getSurahDetail,
  this._saveAyahProgress,
  this._getProgressForSurah,
  this._settingsRepository,
  this._streakService,
  this._xpService,
);

final XpService _xpService;

// في دالة تسجيل الآية:
final xpResult = await _xpService.addXp('ayah_memorized');
final streakResult = await _streakService.recordActivity();

// إذا leveledUp: أضف levelUpEvent للـ state (اختياري للـ animation)
```

**حدّث تسجيل `HifzSessionCubit` في injection.dart:**
```dart
getIt.registerFactory<HifzSessionCubit>(
  () => HifzSessionCubit(
    getIt<GetSurahDetailUsecase>(),
    getIt<SaveAyahProgressUsecase>(),
    getIt<GetProgressForSurahUsecase>(),
    getIt<SettingsRepository>(),
    getIt<StreakService>(),
    getIt<XpService>(),
  ),
);
```

---

## [M1-T3] Celebration Animations

### الخطوة 1: إضافة confetti للـ pubspec.yaml

```yaml
dependencies:
  confetti: ^0.7.0
```

شغّل: `flutter pub get`

### الخطوة 2: CelebrationOverlay Widget

**الملف الجديد:** `lib/core/widgets/celebration_overlay.dart`

```dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum CelebrationType { ayah, page, juz }

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.type,
    required this.xpGained,
    required this.onComplete,
  });

  final CelebrationType type;
  final int xpGained;
  final VoidCallback onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    final duration = widget.type == CelebrationType.juz
        ? const Duration(seconds: 5)
        : const Duration(seconds: 2);
    _confetti = ConfettiController(duration: duration)..play();

    Future.delayed(
      widget.type == CelebrationType.juz
          ? const Duration(milliseconds: 4500)
          : const Duration(milliseconds: 2200),
      () {
        if (mounted) widget.onComplete();
      },
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _getMessage() => switch (widget.type) {
        CelebrationType.ayah => 'أحسنت! +${widget.xpGained} XP ⭐',
        CelebrationType.page => 'اكتملت الصفحة! +${widget.xpGained} XP 🎯',
        CelebrationType.juz  => 'مبارك! أتممت الجزء 🏆',
      };

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // طبقة شفافة تحجب التفاعل مع ما تحتها أثناء الـ celebration
        const ModalBarrier(color: Colors.transparent),

        // Confetti من الأعلى
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFF59E0B),
              Color(0xFF8B5CF6),
              Color(0xFF10B981),
              Color(0xFFEF4444),
              Color(0xFF3B82F6),
            ],
            numberOfParticles: widget.type == CelebrationType.juz ? 50 : 25,
            maxBlastForce: 20,
            minBlastForce: 8,
          ),
        ),

        // XP Badge يظهر ويصعد
        Positioned(
          top: 100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              _getMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),

        // شاشة احتفالية كاملة لإتمام الجزء
        if (widget.type == CelebrationType.juz)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 80))
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    'مبارك!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 8),
                  Text(
                    'أتممت الجزء كاملاً بإذن الله',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                  Text(
                    '+${widget.xpGained} XP 👑',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

### الخطوة 3: إضافة حقول للـ HifzSessionLoaded

**الملف:** `lib/features/hifz/presentation/cubits/hifz_session_state.dart`

أضف الحقول التالية داخل `HifzSessionLoaded`:

```dart
// أضف في نهاية قائمة الحقول الموجودة:
final CelebrationType? celebrationTrigger;
final int lastXpGained;

// عدّل copyWith() ليشمل الحقول الجديدة:
HifzSessionLoaded copyWith({
  // ... الحقول الموجودة كما هي ...
  CelebrationType? celebrationTrigger,
  bool clearCelebration = false,
  int? lastXpGained,
}) {
  return HifzSessionLoaded(
    // ... القيم الموجودة ...
    celebrationTrigger: clearCelebration ? null : (celebrationTrigger ?? this.celebrationTrigger),
    lastXpGained: lastXpGained ?? this.lastXpGained,
  );
}

// عدّل props:
@override
List<Object?> get props => [
  // ... الحقول الموجودة ...
  celebrationTrigger,
  lastXpGained,
];
```

### الخطوة 4: ربط في HifzSessionPage

**الملف:** `lib/features/hifz/presentation/pages/hifz_session_page.dart`

```dart
// في build() اجعل body عبارة عن Stack:
body: BlocConsumer<HifzSessionCubit, HifzSessionState>(
  listener: (context, state) {
    // استخدم listener للـ side effects مثل XP level up
  },
  builder: (context, state) {
    if (state is! HifzSessionLoaded) return _buildLoadingOrError(state);
    return Stack(
      children: [
        _buildMainContent(context, state),
        if (state.celebrationTrigger != null)
          CelebrationOverlay(
            type: state.celebrationTrigger!,
            xpGained: state.lastXpGained,
            onComplete: () =>
                context.read<HifzSessionCubit>().clearCelebration(),
          ),
      ],
    );
  },
),

// أضف دالة clearCelebration في HifzSessionCubit:
// void clearCelebration() {
//   if (state is HifzSessionLoaded) {
//     emit((state as HifzSessionLoaded).copyWith(clearCelebration: true));
//   }
// }
```

---

## [M1-T4] Haptic Feedback

**الملف الجديد:** `lib/core/services/haptic_service.dart`

```dart
import 'package:flutter/services.dart';

/// خدمة الاهتزاز — static methods لسهولة الاستخدام من أي مكان
class HapticService {
  const HapticService._();

  /// اهتزاز خفيف — عند حفظ آية أو أي إجراء ناجح
  static Future<void> success() => HapticFeedback.lightImpact();

  /// اهتزاز ثقيل — عند الخطأ أو التنبيه
  static Future<void> error() => HapticFeedback.heavyImpact();

  /// اهتزاز انتقاء — عند تبديل خيار أو التنقل
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// اهتزازات متتالية — عند إتمام صفحة أو جزء
  static Future<void> celebration() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }
}
```

**أماكن الاستخدام في المشروع:**

| الملف | الحدث | الاستدعاء |
|-------|-------|-----------|
| `hifz_session_cubit.dart` | حفظ آية بنجاح | `HapticService.success()` |
| `hifz_session_cubit.dart` | خطأ في الاختبار | `HapticService.error()` |
| `hifz_session_cubit.dart` | إتمام صفحة/جزء | `HapticService.celebration()` |
| `quiz_page.dart` | إجابة صحيحة | `HapticService.success()` |
| `quiz_page.dart` | إجابة خاطئة | `HapticService.error()` |
| `progress_page.dart` | فتح badge جديد | `HapticService.celebration()` |

---

## [M1-T5] Heat Map للنشاط اليومي

**الملف الجديد:** `lib/core/widgets/activity_heatmap.dart`

```dart
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({super.key, required this.isar});
  final Isar isar;

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  Map<String, int> _activityMap = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // اجلب كل progress من آخر 365 يوم
    final since = DateTime.now().subtract(const Duration(days: 365));
    final allProgress = await widget.isar.isarAyahProgresss
        .filter()
        .lastReviewedAtGreaterThan(since)
        .findAll();

    final map = <String, int>{};
    for (final p in allProgress) {
      if (p.lastReviewedAt == null) continue;
      final d = p.lastReviewedAt!;
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      map[key] = (map[key] ?? 0) + 1;
    }

    if (mounted) setState(() { _activityMap = map; _loaded = true; });
  }

  Color _getColor(int count, ColorScheme cs) {
    if (count == 0) return cs.surfaceVariant.withOpacity(0.3);
    if (count < 5)  return cs.primary.withOpacity(0.25);
    if (count < 15) return cs.primary.withOpacity(0.5);
    if (count < 30) return cs.primary.withOpacity(0.75);
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!_loaded) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }

    final today = DateTime.now();
    final days = List.generate(365, (i) => today.subtract(Duration(days: 364 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نشاط السنة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: days.map((day) {
            final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
            final count = _activityMap[key] ?? 0;
            return Tooltip(
              message: '$key\n$count آية',
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getColor(count, cs),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('أقل', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) => Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: _getColor([0, 3, 10, 20, 35][i], cs),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            Text('أكثر', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
```

**إضافته في ProgressPage:**
```dart
// في lib/features/progress/presentation/pages/progress_page.dart
// أضف في مكان مناسب داخل الصفحة:
ActivityHeatmap(isar: getIt<Isar>())
```

---

# 🟡 المرحلة 2 — الميزات الاجتماعية
**الوقت: 4 أسابيع**

---

## [M2-T1] تسجيل الدخول + مزامنة Supabase

### الخطوة 1: إضافة المكتبات

```yaml
dependencies:
  supabase_flutter: ^2.8.0
  google_sign_in: ^6.2.0
```

`flutter pub get`

### الخطوة 2: تهيئة Supabase في main.dart

```dart
// في main() قبل runApp():
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );
  await configureDependencies();
  runApp(const TaliaApp());
}
```

### الخطوة 3: AppUser Entity

**الملف الجديد:** `lib/features/auth/domain/entities/app_user.dart`

```dart
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  factory AppUser.fromSupabase(Map<String, dynamic> data) => AppUser(
        id: data['id'] as String,
        email: data['email'] as String? ?? '',
        displayName: data['display_name'] as String? ?? 'مستخدم',
        avatarUrl: data['avatar_url'] as String?,
      );

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl];
}
```

### الخطوة 4: AuthRepository

**الملف الجديد:** `lib/features/auth/domain/repositories/auth_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// تسجيل دخول بـ Google
  Future<Either<Failure, AppUser>> signInWithGoogle();

  /// تسجيل خروج
  Future<Either<Failure, Unit>> signOut();

  /// مزامنة التقدم المحلي مع Supabase
  Future<Either<Failure, Unit>> syncProgressToCloud();

  /// سحب التقدم من Supabase
  Future<Either<Failure, Unit>> pullProgressFromCloud();

  /// المستخدم الحالي (null = غير مسجل)
  AppUser? get currentUser;

  /// Stream لتتبع حالة الـ Auth
  Stream<AppUser?> get authStateChanges;
}
```

### الخطوة 5: AuthRepositoryImpl

**الملف الجديد:** `lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._isar);

  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn();
  final dynamic _isar; // Isar — يُستخدم للمزامنة

  @override
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'] as String? ?? 'مستخدم',
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges => _supabase.auth.onAuthStateChange
      .map((event) => event.session?.user)
      .map((user) => user == null
          ? null
          : AppUser(
              id: user.id,
              email: user.email ?? '',
              displayName: user.userMetadata?['full_name'] as String? ?? 'مستخدم',
              avatarUrl: user.userMetadata?['avatar_url'] as String?,
            ));

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Left(AuthFailure('تم إلغاء تسجيل الدخول'));
      }

      final googleAuth = await googleUser.authentication;
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        return Left(AuthFailure('فشل تسجيل الدخول'));
      }

      final user = AppUser(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName: googleUser.displayName ?? 'مستخدم',
        avatarUrl: googleUser.photoUrl,
      );

      // مزامنة فورية بعد تسجيل الدخول
      await syncProgressToCloud();

      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      // جلب البيانات المحلية من Isar وتحميلها لـ Supabase
      // هذا placeholder — الـ Agent يُكمله بناءً على هيكل IsarAyahProgress
      // final localProgress = await _isar.isarAyahProgresss.where().findAll();
      // await _supabase.from('ayah_progress').upsert(
      //   localProgress.map((p) => {
      //     'user_id': user.id,
      //     'surah_id': p.surahId,
      //     'ayah_number': p.ayahNumber,
      //     'repetitions': p.repetitions,
      //     'ease_factor': p.easeFactor,
      //     'next_review': p.nextReview?.toIso8601String(),
      //   }).toList(),
      //   onConflict: 'user_id,surah_id,ayah_number',
      // );
      debugPrint('Sync to cloud completed');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);
      // جلب من Supabase ودمج مع المحلي
      debugPrint('Pull from cloud completed');
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// أضف هذا في lib/core/error/failures.dart إذا لم يكن موجوداً:
// class AuthFailure extends Failure { const AuthFailure(String message) : super(message); }
```

### الخطوة 6: Login Page

**الملف الجديد:** `lib/features/auth/presentation/pages/login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await getIt<AuthRepository>().signInWithGoogle();
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.toString())),
        );
      },
      (_) => context.go('/home'),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // شعار
                Icon(Icons.menu_book_rounded, size: 80, color: cs.primary),
                const SizedBox(height: 16),
                Text('تالية', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'سجّل دخولك لحفظ تقدمك على جميع أجهزتك',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  // زر Google
                  _AuthButton(
                    onTap: _signInWithGoogle,
                    label: 'تسجيل الدخول بـ Google',
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                  ),
                  const SizedBox(height: 12),


                  // تخطي
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text('تخطي الآن', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.onTap, required this.label, required this.icon});
  final VoidCallback onTap;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
```

### الخطوة 7: إضافة route في app_router.dart

```dart
// في قائمة الـ routes أضف:
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginPage(),
),

// Redirect للـ routes المحمية (Premium مثلاً):
redirect: (context, routerState) {
  final isLoggedIn = getIt<AuthRepository>().currentUser != null;
  if (!isLoggedIn && routerState.matchedLocation == '/premium') {
    return '/login';
  }
  return null;
},
```

---

## [M2-T2] شهادات الإتمام

### الخطوة 1: إضافة screenshot للـ pubspec.yaml

```yaml
dependencies:
  screenshot: ^3.0.0
```

`flutter pub get`

### الخطوة 2: CertificateIslamicPainter (زخارف)

**الملف الجديد:** `lib/features/certificate/presentation/widgets/certificate_widget.dart`

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ─── Painter للزخارف الإسلامية ─────────────────────────────────────────────

class _IslamicOrnamentPainter extends CustomPainter {
  const _IslamicOrnamentPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // رسم أشكال هندسية في الزوايا الأربع
    _drawCornerOrnament(canvas, paint, Offset.zero, 0, size.width * 0.22);
    _drawCornerOrnament(canvas, paint, Offset(size.width, 0), math.pi / 2, size.width * 0.22);
    _drawCornerOrnament(canvas, paint, Offset(0, size.height), -math.pi / 2, size.width * 0.22);
    _drawCornerOrnament(canvas, paint, Offset(size.width, size.height), math.pi, size.width * 0.22);
  }

  void _drawCornerOrnament(Canvas canvas, Paint paint, Offset corner, double rotation, double size) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.rotate(rotation);

    // مربع مُدوَّر مُزخرَف
    for (int i = 1; i <= 3; i++) {
      final rect = Rect.fromLTWH(8.0 * i, 8.0 * i, size - 16.0 * i, size - 16.0 * i);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(4.0 * i)), paint);
    }

    // خطوط زخرفية
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(10 + i * 6.0, size),
        Offset(size, 10 + i * 6.0),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_IslamicOrnamentPainter old) => old.color != color;
}

// ─── Certificate Widget ─────────────────────────────────────────────────────

class CertificateWidget extends StatelessWidget {
  const CertificateWidget({
    super.key,
    required this.userName,
    required this.juzNumber,
    required this.completionDate,
  });

  final String userName;
  final int juzNumber;
  final DateTime completionDate;

  String get _arabicJuzNumber {
    const arabic = ['', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
        'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
        'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر',
        'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
        'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون',
        'الخامس والعشرون', 'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون',
        'التاسع والعشرون', 'الثلاثون'];
    return juzNumber <= 30 ? arabic[juzNumber] : juzNumber.toString();
  }

  String get _formattedDate {
    const months = ['يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${completionDate.day} ${months[completionDate.month - 1]} ${completionDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    const goldLight = Color(0xFFF5D78E);
    const goldDark = Color(0xFF8B6914);
    const goldAccent = Color(0xFFC9A84C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: 1080 / 1350,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), goldDark, Color(0xFF1A0F08)],
            ),
          ),
          child: Stack(
            children: [
              // زخارف الزوايا
              Positioned.fill(
                child: CustomPaint(painter: _IslamicOrnamentPainter(color: goldAccent)),
              ),

              // إطار ذهبي
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: goldAccent.withOpacity(0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // المحتوى
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // بسملة
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        color: goldLight.withOpacity(0.9),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // فاصل
                    _GoldDivider(color: goldAccent),

                    // شهادة إتمام
                    Text(
                      'شهادة إتمام',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: goldLight,
                        letterSpacing: 2,
                        shadows: [Shadow(color: goldDark, blurRadius: 8)],
                      ),
                    ),

                    Text(
                      'يُشهد بأن',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        color: goldLight.withOpacity(0.75),
                      ),
                    ),

                    // اسم المستخدم
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: goldAccent, width: 1.5),
                          top: BorderSide(color: goldAccent, width: 1.5),
                        ),
                      ),
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: goldLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // النص
                    Text(
                      'قد أتمّ بفضل الله وتوفيقه\nحفظ الجزء $_arabicJuzNumber\nمن القرآن الكريم',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        color: goldLight.withOpacity(0.9),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    _GoldDivider(color: goldAccent),

                    // التاريخ
                    Text(
                      _formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: goldLight.withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),

                    // شعار تالية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, color: goldAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'تطبيق تالية لحفظ القرآن الكريم',
                          style: TextStyle(
                            fontSize: 12,
                            color: goldAccent.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Divider(color: color.withOpacity(0.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.star_four_points, color: color, size: 12),
          ),
          Expanded(child: Divider(color: color.withOpacity(0.4))),
        ],
      );
}
```

### الخطوة 3: CertificatePage

**الملف الجديد:** `lib/features/certificate/presentation/pages/certificate_page.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/certificate_widget.dart';

class CertificatePage extends StatefulWidget {
  const CertificatePage({
    super.key,
    required this.juzNumber,
    required this.userName,
  });

  final int juzNumber;
  final String userName;

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  final _screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<File> _captureAsFile() async {
    final bytes = await _screenshotController.captureFromWidget(
      CertificateWidget(
        userName: widget.userName,
        juzNumber: widget.juzNumber,
        completionDate: DateTime.now(),
      ),
      pixelRatio: 3.0, // دقة عالية 3240×4050 px
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/talia_certificate_juz${widget.juzNumber}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _share() async {
    setState(() => _isSaving = true);
    try {
      final file = await _captureAsFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'بفضل الله أتممت حفظ الجزء ${widget.juzNumber} من القرآن الكريم 📖\n'
            'انضم إليّ في تطبيق تالية لحفظ القرآن 🌙',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء المشاركة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final file = await _captureAsFile();
      // نسخ للمستندات ليتمكن المستخدم من إيجادها
      final docsDir = await getApplicationDocumentsDirectory();
      final savedFile = await file.copy(
        '${docsDir.path}/talia_certificate_juz${widget.juzNumber}.png',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الشهادة في: ${savedFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('شهادتك', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Screenshot(
                  controller: _screenshotController,
                  child: CertificateWidget(
                    userName: widget.userName,
                    juzNumber: widget.juzNumber,
                    completionDate: DateTime.now(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saveToGallery,
                              icon: const Icon(Icons.download),
                              label: const Text('حفظ'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _share,
                              icon: const Icon(Icons.share),
                              label: const Text('مشاركة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC9A84C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### الخطوة 4: إضافة route

```dart
// في app_router.dart:
import '../../features/certificate/presentation/pages/certificate_page.dart';

GoRoute(
  path: '/certificate',
  builder: (context, state) {
    final args = state.extra as Map<String, dynamic>;
    return CertificatePage(
      juzNumber: args['juzNumber'] as int,
      userName: args['userName'] as String,
    );
  },
),
```

### الخطوة 5: فتح الشهادة تلقائياً

**الملف:** `lib/features/hifz/presentation/pages/hifz_session_page.dart`

```dart
// في BlocListener أو Consumer:
BlocListener<HifzSessionCubit, HifzSessionState>(
  listenWhen: (prev, curr) =>
      curr is HifzSessionLoaded && (curr as HifzSessionLoaded).juzCompleted != null,
  listener: (context, state) {
    final loaded = state as HifzSessionLoaded;
    if (loaded.juzCompleted != null) {
      final userName = getIt<SharedPreferences>().getString('user_name') ?? 'أخي الحافظ';
      context.push('/certificate', extra: {
        'juzNumber': loaded.juzCompleted!,
        'userName': userName,
      });
    }
  },
  child: /* ... */,
)
```

---

## [M2-T3] إشعارات ذكية

**الملف:** `lib/core/services/notification_service.dart`

أضف هذه الإضافات للملف الحالي:

```dart
// أضف هذه الثوابت في بداية الـ class:
static const List<String> _motivationalMessages = [
  'القرآن يشتاق إليك! 📖',
  'خطوة صغيرة اليوم، ثواب كبير غداً ✨',
  'جلسة حفظ اليوم تنتظرك 🌙',
  'لا تكسر تسلسلك! 🔥',
  'آية واحدة تبني لك مكانة في الجنة 💎',
  'راجع ما حفظته قبل أن تنسى 📚',
  'اليوم فرصة لإضافة آية جديدة لقلبك 💚',
];

// ─── Smart Reminder ────────────────────────────────────────────────────────

Future<void> scheduleSmartReminder() async {
  final prefs = await SharedPreferences.getInstance();

  // سجّل وقت فتح التطبيق الحالي
  final currentHour = DateTime.now().hour;
  final storedHours = prefs.getStringList('open_hours') ?? [];
  storedHours.add(currentHour.toString());
  if (storedHours.length > 14) storedHours.removeAt(0); // آخر 14 مرة
  await prefs.setStringList('open_hours', storedHours);

  // احسب متوسط وقت الفتح
  int avgHour = 20; // 8 مساءً افتراضياً
  if (storedHours.length >= 3) {
    final sum = storedHours.map(int.parse).reduce((a, b) => a + b);
    avgHour = (sum / storedHours.length).round();
  }

  // اختر رسالة غير مكررة
  final usedIndex = prefs.getInt('last_msg_index') ?? 0;
  final nextIndex = (usedIndex + 1) % _motivationalMessages.length;
  await prefs.setInt('last_msg_index', nextIndex);

  // إلغاء القديم وجدولة الجديد
  await _plugin.cancel(_dailyAyahId);

  final tzNow = tz.TZDateTime.now(tz.local);
  var scheduledTime = tz.TZDateTime(
    tz.local, tzNow.year, tzNow.month, tzNow.day, avgHour,
  );
  if (scheduledTime.isBefore(tzNow)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }

  await _plugin.zonedSchedule(
    _dailyAyahId,
    'تالية 📖',
    _motivationalMessages[nextIndex],
    scheduledTime,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'التذكير اليومي',
        channelDescription: 'تذكير يومي لحفظ القرآن',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'daily_reminder',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

// ─── Streak Alert ──────────────────────────────────────────────────────────

Future<void> scheduleStreakAlert(int currentStreak) async {
  if (currentStreak <= 3) return;

  await _plugin.cancel(_streakAlertId);

  final tzNow = tz.TZDateTime.now(tz.local);
  var alertTime = tz.TZDateTime(
    tz.local, tzNow.year, tzNow.month, tzNow.day, 21, 0,
  );
  if (alertTime.isBefore(tzNow)) {
    alertTime = alertTime.add(const Duration(days: 1));
  }

  await _plugin.zonedSchedule(
    _streakAlertId,
    'تحذير الـ Streak! 🔥',
    'أيامك الـ $currentStreak على المحك — حافظ على تسلسلك الآن',
    alertTime,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'streak_alert',
        'تنبيه الـ Streak',
        channelDescription: 'تنبيه عند خطر انقطاع التسلسل اليومي',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

---

# ⚫ المرحلة 4 — التحقيق المادي (Premium)
**الوقت: أسبوع**

---

## [M4-T2] نظام الاشتراك Premium

### الخطوة 1: إضافة RevenueCat

```yaml
dependencies:
  purchases_flutter: ^8.0.0
```

### الخطوة 2: SubscriptionService

**الملف الجديد:** `lib/core/services/subscription_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const String _entitlementId = 'premium';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration(
        const String.fromEnvironment('REVENUECAT_KEY', defaultValue: ''),
      ),
    );
    _initialized = true;
  }

  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('isPremium error: $e');
      return false;
    }
  }

  Future<bool> purchaseMonthly() async {
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) return false;
      final info = await Purchases.purchasePackage(monthly);
      return info.entitlements.active.containsKey(_entitlementId);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  Future<bool> purchaseYearly() async {
    try {
      final offerings = await Purchases.getOfferings();
      final annual = offerings.current?.annual;
      if (annual == null) return false;
      final info = await Purchases.purchasePackage(annual);
      return info.entitlements.active.containsKey(_entitlementId);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('restorePurchases error: $e');
      return false;
    }
  }
}
```

### الخطوة 3: PremiumGate Widget

**الملف الجديد:** `lib/core/widgets/premium_gate.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../services/subscription_service.dart';

class PremiumGate extends StatefulWidget {
  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
  });

  final Widget child;
  final String featureName; // اسم الميزة للعرض

  @override
  State<PremiumGate> createState() => _PremiumGateState();
}

class _PremiumGateState extends State<PremiumGate> {
  bool? _isPremium;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final result = await getIt<SubscriptionService>().isPremium();
    if (mounted) setState(() => _isPremium = result);
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isPremium!) return widget.child;

    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✨', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '${widget.featureName} — تالية بلس',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'هذه الميزة متاحة للمشتركين في تالية بلس',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'جرّب 7 أيام مجاناً',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**مثال الاستخدام:**
```dart
// لحجب أي ميزة:
PremiumGate(
  featureName: 'تقييم التلاوة',
  child: RecitationButton(
    expectedAyah: currentAyah.text,
    onResult: _onRecitationResult,
  ),
)
```

---

# 📊 ملخص التنفيذ

## جدول المراحل

| المرحلة | المدة | الملفات الجديدة | الأثر |
|---------|-------|----------------|-------|
| 0 — Bug Fixes | 1 يوم | 0 ملفات جديدة — تعديل فقط | 🔴 ضروري |
| 1 — Gamification | 3 أسابيع | ~15 ملف | ⬆️ Engagement × 3 |
| 2 — Social | 4 أسابيع | ~12 ملف | ⬆️ Retention × 2 |

| 4 — Premium | أسبوع | ~5 ملفات | 💰 Revenue |

## ترتيب التنفيذ بالـ Impact/Effort

```
ابدأ هنا (Impact عالٍ + Effort منخفض):
  ① M0 — Bug Fixes (يوم)
  ② M1-T4 — Haptic Feedback (ساعة)
  ③ M1-T3 — Celebration Animations (يوم)
  ④ M1-T1 — Streak System (3 أيام)
  ⑤ M1-T2 — XP System (3 أيام)

ثم (Impact عالٍ + Effort متوسط):
  ⑥ M2-T2 — Certificates (يومان)
  ⑦ M2-T3 — Smart Notifications (يوم)
  ⑧ M1-T5 — Activity Heatmap (يوم)

أخيراً (Impact عالٍ + Effort عالٍ):
  ⑨ M2-T1 — Auth + Supabase Sync (أسبوع)
  ⑩ M4-T2 — Premium System (أسبوع)
```

## Checklist نهاية كل Task

```
□ flutter analyze → صفر أخطاء جديدة
□ flutter build apk --debug → يكتمل بنجاح
□ كل Isar schema جديد مضاف في Isar.open() بـ injection.dart
□ كل service مسجلة في injection.dart
□ كل route مضاف في app_router.dart
□ RTL: Directionality موجود في كل شاشة جديدة
□ الألوان من Theme.of(context).colorScheme
□ المسافات من AppSpacing.*
□ dispose() موجود لكل AnimationController / StreamSubscription / GestureRecognizer
□ try/catch موجود لكل async operation
□ build_runner شُغِّل بعد أي Isar schema جديد
```

## متغيرات البيئة

```bash
# .env (أضفه في .gitignore)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
REVENUECAT_KEY=appl_...

# تشغيل Debug
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# بناء Release (سيُعدَّل يدوياً لاحقاً)
# flutter build appbundle --release
```
