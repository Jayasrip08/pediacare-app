import 'package:flutter_test/flutter_test.dart';
import 'package:pediacare/features/doctor/dose_calculator.dart';
import 'package:pediacare/models/models.dart';

DrugFormulary _drug({
  double mgPerKg = 15,
  int doses = 4,
  double maxDaily = 60,
  double? maxSingle = 500,
  int minAge = 3,
}) =>
    DrugFormulary(
      id: 1,
      name: 'Test',
      form: 'Syrup',
      strengthMg: 125,
      strengthMl: 5,
      mgPerKgPerDose: mgPerKg,
      dosesPerDay: doses,
      maxMgPerKgPerDay: maxDaily,
      maxSingleDoseMg: maxSingle,
      minAgeMonths: minAge,
      defaultDurationDays: 3,
      reviewed: false,
    );

void main() {
  group('DoseCalculator.suggest', () {
    test('calculates mg and mL from weight', () {
      final s = DoseCalculator.suggest(_drug(), weightKg: 12.5, ageMonths: 28);
      expect(s.mgPerDose, 187.5);
      expect(s.mlPerDose, 7.5);
      expect(s.capped, isFalse);
      expect(s.warnings, isEmpty);
    });

    test('caps at maximum single dose', () {
      final s = DoseCalculator.suggest(_drug(), weightKg: 40, ageMonths: 120);
      expect(s.mgPerDose, 500);
      expect(s.capped, isTrue);
    });

    test('caps at maximum daily dose', () {
      final s = DoseCalculator.suggest(_drug(mgPerKg: 20), weightKg: 10, ageMonths: 24);
      // 20 mg/kg x 4 = 80 mg/kg/day > 60 -> reduced to 15 mg/kg/dose
      expect(s.mgPerDose, 150);
      expect(s.capped, isTrue);
    });

    test('rounds mL down, never up', () {
      final s = DoseCalculator.suggest(_drug(), weightKg: 7.3, ageMonths: 8);
      // 109.5 mg -> 4.38 mL -> 4.3 mL
      expect(s.mlPerDose, 4.3);
      expect(s.mgPerDose, closeTo(107.5, 1e-9));
    });
  });

  group('DoseCalculator.validate', () {
    test('warns below minimum age', () {
      final w = DoseCalculator.validate(_drug(minAge: 6),
          weightKg: 6, doseMg: 90, timesPerDay: 4, ageMonths: 4);
      expect(w.any((e) => e.contains('younger')), isTrue);
    });

    test('warns when manual dose exceeds daily limit', () {
      final w = DoseCalculator.validate(_drug(),
          weightKg: 10, doseMg: 200, timesPerDay: 4, ageMonths: 24);
      expect(w.any((e) => e.contains('mg/kg')), isTrue);
    });

    test('requires a weight', () {
      final w = DoseCalculator.validate(_drug(),
          weightKg: 0, doseMg: 100, timesPerDay: 4, ageMonths: 24);
      expect(w, isNotEmpty);
    });
  });
}
