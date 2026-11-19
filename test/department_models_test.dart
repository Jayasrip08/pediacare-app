import 'package:flutter_test/flutter_test.dart';
import 'package:pediacare/models/department_models.dart';

void main() {
  group('ClinicDepartment enum', () {
    test('parses department keys properly', () {
      expect(ClinicDepartment.fromKey('pediatrics'), ClinicDepartment.pediatrics);
      expect(ClinicDepartment.fromKey('dental'), ClinicDepartment.dental);
      expect(ClinicDepartment.fromKey('teeth'), ClinicDepartment.dental);
      expect(ClinicDepartment.fromKey('dermatology'), ClinicDepartment.dermatology);
      expect(ClinicDepartment.fromKey('skin'), ClinicDepartment.dermatology);
      expect(ClinicDepartment.fromKey('pregnancy_care'), ClinicDepartment.pregnancyCare);
      expect(ClinicDepartment.fromKey('maternity'), ClinicDepartment.pregnancyCare);
      expect(ClinicDepartment.fromKey('ophthalmology'), ClinicDepartment.ophthalmology);
      expect(ClinicDepartment.fromKey('eye'), ClinicDepartment.ophthalmology);
      expect(ClinicDepartment.fromKey('psychiatry'), ClinicDepartment.psychiatry);
      expect(ClinicDepartment.fromKey('counselling'), ClinicDepartment.psychiatry);
    });

    test('returns correct tab lists for each department', () {
      expect(ClinicDepartment.pediatrics.tabs, contains('Vaccines'));
      expect(ClinicDepartment.dental.tabs, contains('Tooth Chart'));
      expect(ClinicDepartment.dermatology.tabs, contains('Before / After'));
      expect(ClinicDepartment.pregnancyCare.tabs, contains('ANC & Gestation'));
      expect(ClinicDepartment.ophthalmology.tabs, contains('Refraction & Vision'));
      expect(ClinicDepartment.psychiatry.tabs, contains('Screeners (PHQ/GAD)'));
    });
  });

  group('Pregnancy Care calculations', () {
    test('Naegele rule: EDD is LMP + 280 days', () {
      final lmp = DateTime(2026, 1, 1);
      final edd = PregnancyRecord.computeEdd(lmp);
      expect(edd.difference(lmp).inDays, 280);
    });
  });

  group('Psychiatry screeners scoring', () {
    test('PHQ-9 severity bands', () {
      expect(ScreenerResult.computeSeverity(ScreenerType.phq9, 3), 'Minimal (0-4)');
      expect(ScreenerResult.computeSeverity(ScreenerType.phq9, 7), 'Mild (5-9)');
      expect(ScreenerResult.computeSeverity(ScreenerType.phq9, 12), 'Moderate (10-14)');
      expect(ScreenerResult.computeSeverity(ScreenerType.phq9, 17), 'Moderately Severe (15-19)');
      expect(ScreenerResult.computeSeverity(ScreenerType.phq9, 23), 'Severe (20-27)');
    });

    test('GAD-7 severity bands', () {
      expect(ScreenerResult.computeSeverity(ScreenerType.gad7, 2), 'Minimal (0-4)');
      expect(ScreenerResult.computeSeverity(ScreenerType.gad7, 8), 'Mild (5-9)');
      expect(ScreenerResult.computeSeverity(ScreenerType.gad7, 13), 'Moderate (10-14)');
      expect(ScreenerResult.computeSeverity(ScreenerType.gad7, 18), 'Severe (15-21)');
    });
  });
}
