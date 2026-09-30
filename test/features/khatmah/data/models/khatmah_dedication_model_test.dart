import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_dedication_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';

void main() {
  test('gender round-trips through JSON', () {
    const entity = KhatmahDedication(
      isDedicated: true,
      recipientName: 'فاطمة',
      recipientGender: DedicationGender.female,
    );
    final json = KhatmahDedicationModel.fromEntity(entity).toJson();
    expect(json['recipientGender'], 'female');
    expect(KhatmahDedicationModel.fromJson(json).toEntity(), entity);
  });

  test('legacy JSON without gender stays unknown', () {
    final entity = KhatmahDedicationModel.fromJson({
      'isDedicated': true,
      'recipientName': 'x',
      'relationship': 'والد / والدة',
    }).toEntity();
    expect(entity.recipientGender, isNull);
    expect(entity.effectiveGender, isNull);
  });

  test('an unknown stored gender is not mapped to a default', () {
    final entity = KhatmahDedicationModel.fromJson({
      'isDedicated': true,
      'recipientGender': 'plural',
    }).toEntity();
    expect(entity.recipientGender, isNull);
  });

  test('explicit relationship implies gender', () {
    expect(
      const KhatmahDedication(relationship: 'الأم').effectiveGender,
      DedicationGender.female,
    );
    expect(
      const KhatmahDedication(relationship: 'والدة').effectiveGender,
      DedicationGender.female,
    );
    expect(
      const KhatmahDedication(relationship: 'Father').effectiveGender,
      DedicationGender.male,
    );
    expect(
      const KhatmahDedication(
        relationship: 'الأم',
        recipientGender: DedicationGender.male,
      ).effectiveGender,
      DedicationGender.male,
    );
  });
}
