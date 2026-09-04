import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleJsonString = '''
{
  "tier": "guidance",
  "source": "مصحف مجمع الملك فهد لطباعة المصحف الشريف",
  "sourceNote": "دعاء مأثور ومشهور مطبوع في ملحق مصحف مجمع الملك فهد لطباعة المصحف الشريف بالمدينة المنورة؛ يصنف كإرشاد ودعاء عام وليس حديثاً نبوياً مرفوعاً.",
  "arabicText": "اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ...",
  "dedicationInserts": {
    "alive": "اللَّهُمَّ اجْعَلْ ثَوَابَ هَذِهِ التِّلَاوَةِ وَبَرَكَتَهَا لِعَبْدِكَ {name}",
    "deceased": "اللَّهُمَّ اغْفِرْ لِعَبْدِكَ {name} وَارْحَمْهُ",
    "sick": "اللَّهُمَّ اشْفِ عَبْدَكَ {name}"
  }
}
''';

  group('KhatmDuaData', () {
    test('unreviewed legacy templates cannot infer gender from a name', () {
      final data = KhatmDuaData.fromJson({
        'arabicText': 'text',
        'source': 'unverified claim',
        'sourceNote': 'note',
        'tier': 'guidance',
        'dedicationInserts': {'alive': 'لِعَبْدِكَ {name}'},
      });
      for (final condition in DedicationCondition.values) {
        expect(data.getDedicationInsert(condition, 'فاطمة'), isEmpty);
      }
    });
    test('fromJson parses all fields correctly', () {
      final json = {
        'arabicText': 'اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ...',
        'source': 'مصحف مجمع الملك فهد لطباعة المصحف الشريف',
        'sourceNote': 'دعاء مأثور',
        'tier': 'guidance',
        'dedicationInserts': {
          'alive': 'بركة لـ {name}',
          'deceased': 'رحمة لـ {name}',
          'sick': 'شفاء لـ {name}',
        },
      };

      final data = KhatmDuaData.fromJson(json);

      expect(data.arabicText, 'اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ...');
      expect(data.source, 'مصحف مجمع الملك فهد لطباعة المصحف الشريف');
      expect(data.sourceNote, 'دعاء مأثور');
      expect(data.tier, 'guidance');
      expect(data.dedicationInserts['alive'], 'بركة لـ {name}');
      expect(data.dedicationInserts['deceased'], 'رحمة لـ {name}');
      expect(data.dedicationInserts['sick'], 'شفاء لـ {name}');
    });

    test('legacy templates stay quarantined for all recipient conditions', () {
      final data = KhatmDuaData.fromJson({
        'arabicText': 'text',
        'source': 'source',
        'sourceNote': 'note',
        'tier': 'guidance',
        'dedicationInserts': {
          'alive': 'اللهم بارك في {name}',
          'deceased': 'اللهم ارحم {name}',
          'sick': 'اللهم اشف {name}',
        },
      });

      expect(data.getDedicationInsert(DedicationCondition.alive, 'أحمد'), '');
      expect(
        data.getDedicationInsert(DedicationCondition.deceased, 'فاطمة'),
        '',
      );
      expect(data.getDedicationInsert(DedicationCondition.sick, 'سعيد'), '');
    });
  });

  group('KhatmDuaDatasource', () {
    late MockAssetBundle mockBundle;
    late KhatmDuaDatasource datasource;

    setUp(() {
      mockBundle = MockAssetBundle();
      datasource = KhatmDuaDatasource(bundle: mockBundle);
    });

    test('loadDua loads JSON from bundle and caches response', () async {
      when(
        () => mockBundle.loadString('assets/data/khatm_dua.json'),
      ).thenAnswer((_) async => sampleJsonString);

      final data1 = await datasource.loadDua();
      final data2 = await datasource.loadDua();

      expect(data1.tier, 'guidance');
      expect(data1.source, 'مصحف مجمع الملك فهد لطباعة المصحف الشريف');
      expect(identical(data1, data2), isTrue);
      verify(
        () => mockBundle.loadString('assets/data/khatm_dua.json'),
      ).called(1);
    });
  });
}
