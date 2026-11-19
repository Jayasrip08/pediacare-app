import '../../models/models.dart';

/// Result of a weight-based dose suggestion. Always a *suggestion*: the doctor
/// must review and confirm every dose before a prescription can be sent.
class DoseSuggestion {
  const DoseSuggestion({
    required this.mgPerDose,
    required this.mlPerDose,
    required this.timesPerDay,
    required this.mgPerKgPerDay,
    required this.capped,
    required this.warnings,
  });

  final double mgPerDose;
  final double mlPerDose;
  final int timesPerDay;
  final double mgPerKgPerDay;
  final bool capped;
  final List<String> warnings;
}

class DoseCalculator {
  DoseCalculator._();

  static const _eps = 1e-6;

  /// mL <-> mg conversion for a liquid formulation.
  static double mgToMl(DrugFormulary d, double mg) => mg / d.strengthMg * d.strengthMl;
  static double mlToMg(DrugFormulary d, double ml) => ml * d.strengthMg / d.strengthMl;

  /// Suggested dose for [weightKg]. mL is rounded *down* to 0.1 mL so the
  /// measured dose never exceeds the calculated one.
  static DoseSuggestion suggest(
    DrugFormulary d, {
    required double weightKg,
    required int ageMonths,
  }) {
    var mg = weightKg * d.mgPerKgPerDose;
    var capped = false;

    final single = d.maxSingleDoseMg;
    if (single != null && mg > single + _eps) {
      mg = single;
      capped = true;
    }
    final maxDaily = d.maxMgPerKgPerDay * weightKg;
    if (mg * d.dosesPerDay > maxDaily + _eps) {
      mg = maxDaily / d.dosesPerDay;
      capped = true;
    }

    final ml = ((mgToMl(d, mg) * 10) + 1e-9).floorToDouble() / 10;
    final finalMg = mlToMg(d, ml);

    return DoseSuggestion(
      mgPerDose: finalMg,
      mlPerDose: ml,
      timesPerDay: d.dosesPerDay,
      mgPerKgPerDay: weightKg <= 0 ? 0 : finalMg * d.dosesPerDay / weightKg,
      capped: capped,
      warnings: validate(d,
          weightKg: weightKg,
          doseMg: finalMg,
          timesPerDay: d.dosesPerDay,
          ageMonths: ageMonths),
    );
  }

  /// Safety checks for a (possibly hand-edited) dose.
  static List<String> validate(
    DrugFormulary d, {
    required double weightKg,
    required double doseMg,
    required int timesPerDay,
    required int ageMonths,
  }) {
    final w = <String>[];
    if (weightKg <= 0) {
      w.add('Enter the child’s weight.');
      return w;
    }
    if (ageMonths < d.minAgeMonths) {
      w.add('Child is younger than ${d.minAgeMonths} months - this drug needs special review.');
    }
    final perKgDay = doseMg * timesPerDay / weightKg;
    if (perKgDay > d.maxMgPerKgPerDay + _eps) {
      w.add('Daily total is ${perKgDay.toStringAsFixed(1)} mg/kg - above the '
          '${d.maxMgPerKgPerDay.toStringAsFixed(0)} mg/kg/day limit.');
    }
    final single = d.maxSingleDoseMg;
    if (single != null && doseMg > single + _eps) {
      w.add('Single dose exceeds ${single.toStringAsFixed(0)} mg.');
    }
    if (doseMg <= 0) w.add('Dose must be greater than zero.');
    return w;
  }
}
