import 'package:flutter/material.dart';

// ============================================================================
// CLINIC DEPARTMENT DEFINITION
// ============================================================================

enum ClinicDepartment {
  pediatrics,
  dermatology,
  dental,
  pregnancyCare,
  ophthalmology,
  psychiatry;

  String get key => switch (this) {
        ClinicDepartment.pediatrics => 'pediatrics',
        ClinicDepartment.dermatology => 'dermatology',
        ClinicDepartment.dental => 'dental',
        ClinicDepartment.pregnancyCare => 'pregnancy_care',
        ClinicDepartment.ophthalmology => 'ophthalmology',
        ClinicDepartment.psychiatry => 'psychiatry',
      };

  static ClinicDepartment fromKey(String? key) => switch (key?.toLowerCase().trim()) {
        'dermatology' || 'derma' || 'skin' => ClinicDepartment.dermatology,
        'dental' || 'dentistry' || 'teeth' => ClinicDepartment.dental,
        'pregnancy_care' ||
        'pregnancy' ||
        'maternity' ||
        'obstetrics' =>
          ClinicDepartment.pregnancyCare,
        'ophthalmology' || 'eye' || 'optometry' => ClinicDepartment.ophthalmology,
        'psychiatry' || 'counselling' || 'mental_health' => ClinicDepartment.psychiatry,
        _ => ClinicDepartment.pediatrics,
      };

  String get displayName => switch (this) {
        ClinicDepartment.pediatrics => 'Pediatrics (Child Care)',
        ClinicDepartment.dermatology => 'Dermatology & Skin Care',
        ClinicDepartment.dental => 'Dental & Oral Health',
        ClinicDepartment.pregnancyCare => 'Pregnancy & Maternity Care',
        ClinicDepartment.ophthalmology => 'Eye Clinic & Ophthalmology',
        ClinicDepartment.psychiatry => 'Psychiatry & Counselling',
      };

  String get shortName => switch (this) {
        ClinicDepartment.pediatrics => 'Pediatrics',
        ClinicDepartment.dermatology => 'Dermatology',
        ClinicDepartment.dental => 'Dental',
        ClinicDepartment.pregnancyCare => 'Pregnancy Care',
        ClinicDepartment.ophthalmology => 'Eye Clinic',
        ClinicDepartment.psychiatry => 'Psychiatry',
      };

  String get description => switch (this) {
        ClinicDepartment.pediatrics =>
          'Vaccine tracker, growth percentiles, pediatric dose calculator',
        ClinicDepartment.dermatology =>
          'Before/after photo gallery, session tracking, skin regimens',
        ClinicDepartment.dental =>
          'Interactive tooth chart (odontogram), treatment plans, dental records',
        ClinicDepartment.pregnancyCare =>
          'EDD & gestational age tracker, ANC checkups, prenatal checklist',
        ClinicDepartment.ophthalmology =>
          'Refraction prescription (OD/OS), IOP tonometry, visual acuity',
        ClinicDepartment.psychiatry =>
          'PHQ-9 & GAD-7 screeners, therapy SOAP notes, coping goals',
      };

  String get patientLabel => switch (this) {
        ClinicDepartment.pediatrics => 'Child',
        ClinicDepartment.pregnancyCare => 'Expectant Mother',
        ClinicDepartment.psychiatry => 'Client',
        _ => 'Patient',
      };

  IconData get icon => switch (this) {
        ClinicDepartment.pediatrics => Icons.health_and_safety_rounded,
        ClinicDepartment.dermatology => Icons.healing_rounded,
        ClinicDepartment.dental => Icons.medical_services_rounded,
        ClinicDepartment.pregnancyCare => Icons.favorite_rounded,
        ClinicDepartment.ophthalmology => Icons.visibility_rounded,
        ClinicDepartment.psychiatry => Icons.psychology_rounded,
      };

  Color get color => const Color(0xFF1565C0); // Vibrant Medical Royal Blue for all specialties

  List<String> get tabs => switch (this) {
        ClinicDepartment.pediatrics => ['Timeline', 'Vaccines', 'Growth', 'Records'],
        ClinicDepartment.dermatology => ['Timeline', 'Before / After', 'Sessions', 'Records'],
        ClinicDepartment.dental => ['Timeline', 'Tooth Chart', 'Treatment Plans', 'Records'],
        ClinicDepartment.pregnancyCare => ['Timeline', 'ANC & Gestation', 'Checklist', 'Records'],
        ClinicDepartment.ophthalmology => ['Timeline', 'Refraction & Vision', 'IOP & Exams', 'Records'],
        ClinicDepartment.psychiatry => ['Timeline', 'Screeners (PHQ/GAD)', 'Therapy Notes', 'Records'],
      };
}

// ============================================================================
// 1. DERMATOLOGY MODELS
// ============================================================================

class DermaComparison {
  const DermaComparison({
    required this.id,
    required this.patientId,
    required this.title,
    required this.affectedArea,
    required this.beforeDate,
    required this.afterDate,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    this.conditionNotes,
    this.treatmentTag,
  });

  final String id;
  final String patientId;
  final String title;
  final String affectedArea;
  final DateTime beforeDate;
  final DateTime afterDate;
  final String beforePhotoUrl;
  final String afterPhotoUrl;
  final String? conditionNotes;
  final String? treatmentTag;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'title': title,
        'affected_area': affectedArea,
        'before_date': beforeDate.toIso8601String(),
        'after_date': afterDate.toIso8601String(),
        'before_photo_url': beforePhotoUrl,
        'after_photo_url': afterPhotoUrl,
        'condition_notes': conditionNotes,
        'treatment_tag': treatmentTag,
      };

  factory DermaComparison.fromJson(Map<String, dynamic> j) => DermaComparison(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        title: j['title'] as String,
        affectedArea: j['affected_area'] as String,
        beforeDate: DateTime.parse(j['before_date'] as String),
        afterDate: DateTime.parse(j['after_date'] as String),
        beforePhotoUrl: j['before_photo_url'] as String,
        afterPhotoUrl: j['after_photo_url'] as String,
        conditionNotes: j['condition_notes'] as String?,
        treatmentTag: j['treatment_tag'] as String?,
      );
}

class DermaSessionLog {
  const DermaSessionLog({
    required this.id,
    required this.patientId,
    required this.treatmentName,
    required this.sessionNumber,
    required this.totalSessions,
    required this.sessionDate,
    this.energyParameters,
    this.clinicalReaction,
    this.nextSessionDate,
    this.notes,
    this.isCompleted = true,
  });

  final String id;
  final String patientId;
  final String treatmentName;
  final int sessionNumber;
  final int totalSessions;
  final DateTime sessionDate;
  final String? energyParameters;
  final String? clinicalReaction;
  final DateTime? nextSessionDate;
  final String? notes;
  final bool isCompleted;

  String get sessionLabel => 'Session $sessionNumber of $totalSessions';
  double get progressFraction => totalSessions > 0 ? (sessionNumber / totalSessions).clamp(0.0, 1.0) : 1.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'treatment_name': treatmentName,
        'session_number': sessionNumber,
        'total_sessions': totalSessions,
        'session_date': sessionDate.toIso8601String(),
        'energy_parameters': energyParameters,
        'clinical_reaction': clinicalReaction,
        'next_session_date': nextSessionDate?.toIso8601String(),
        'notes': notes,
        'is_completed': isCompleted,
      };

  factory DermaSessionLog.fromJson(Map<String, dynamic> j) => DermaSessionLog(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        treatmentName: j['treatment_name'] as String,
        sessionNumber: (j['session_number'] as num).toInt(),
        totalSessions: (j['total_sessions'] as num).toInt(),
        sessionDate: DateTime.parse(j['session_date'] as String),
        energyParameters: j['energy_parameters'] as String?,
        clinicalReaction: j['clinical_reaction'] as String?,
        nextSessionDate: j['next_session_date'] != null
            ? DateTime.parse(j['next_session_date'] as String)
            : null,
        notes: j['notes'] as String?,
        isCompleted: (j['is_completed'] as bool?) ?? true,
      );
}

// ============================================================================
// 2. DENTAL MODELS
// ============================================================================

enum ToothCondition {
  sound,
  caries,
  filled,
  rootCanal,
  crown,
  missing,
  implant;

  String get label => switch (this) {
        ToothCondition.sound => 'Healthy / Sound',
        ToothCondition.caries => 'Caries (Cavity)',
        ToothCondition.filled => 'Restored (Filling)',
        ToothCondition.rootCanal => 'Root Canal (RCT)',
        ToothCondition.crown => 'Crown / Cap',
        ToothCondition.missing => 'Missing / Extracted',
        ToothCondition.implant => 'Dental Implant',
      };

  Color get color => switch (this) {
        ToothCondition.sound => const Color(0xFFEFF6FF), // Soft White-Blue
        ToothCondition.caries => const Color(0xFF1565C0), // Medical Blue
        ToothCondition.filled => const Color(0xFF1565C0), // Medical Blue
        ToothCondition.rootCanal => const Color(0xFF1976D2), // Medical Blue
        ToothCondition.crown => const Color(0xFF1565C0), // Medical Blue
        ToothCondition.missing => const Color(0xFF94A3B8), // Subtle Slate
        ToothCondition.implant => const Color(0xFF1565C0), // Medical Blue
      };

  IconData get icon => switch (this) {
        ToothCondition.sound => Icons.check_circle_outline_rounded,
        ToothCondition.caries => Icons.warning_amber_rounded,
        ToothCondition.filled => Icons.format_paint_rounded,
        ToothCondition.rootCanal => Icons.healing_rounded,
        ToothCondition.crown => Icons.workspace_premium_rounded,
        ToothCondition.missing => Icons.block_rounded,
        ToothCondition.implant => Icons.push_pin_rounded,
      };
}

class ToothData {
  const ToothData({
    required this.toothNumber,
    required this.name,
    required this.arch,
    this.condition = ToothCondition.sound,
    this.surfaces = const [],
    this.notes,
    this.lastTreated,
  });

  final int toothNumber; // 1 - 32 Universal numbering
  final String name; // e.g. "Upper Right 1st Molar (#3)"
  final String arch; // "upper" or "lower"
  final ToothCondition condition;
  final List<String> surfaces; // Occlusal, Mesial, Distal, Buccal, Lingual
  final String? notes;
  final DateTime? lastTreated;

  ToothData copyWith({
    ToothCondition? condition,
    List<String>? surfaces,
    String? notes,
    DateTime? lastTreated,
  }) =>
      ToothData(
        toothNumber: toothNumber,
        name: name,
        arch: arch,
        condition: condition ?? this.condition,
        surfaces: surfaces ?? this.surfaces,
        notes: notes ?? this.notes,
        lastTreated: lastTreated ?? this.lastTreated,
      );

  Map<String, dynamic> toJson() => {
        'tooth_number': toothNumber,
        'name': name,
        'arch': arch,
        'condition': condition.name,
        'surfaces': surfaces,
        'notes': notes,
        'last_treated': lastTreated?.toIso8601String(),
      };

  factory ToothData.fromJson(Map<String, dynamic> j) => ToothData(
        toothNumber: (j['tooth_number'] as num).toInt(),
        name: j['name'] as String,
        arch: j['arch'] as String,
        condition: ToothCondition.values.firstWhere(
          (c) => c.name == j['condition'],
          orElse: () => ToothCondition.sound,
        ),
        surfaces: (j['surfaces'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        notes: j['notes'] as String?,
        lastTreated: j['last_treated'] != null ? DateTime.parse(j['last_treated'] as String) : null,
      );
}

class DentalTreatmentItem {
  const DentalTreatmentItem({
    required this.id,
    required this.patientId,
    required this.procedureName,
    required this.teethInvolved,
    required this.estimatedCost,
    this.isCompleted = false,
    this.scheduledDate,
    this.notes,
  });

  final String id;
  final String patientId;
  final String procedureName;
  final String teethInvolved;
  final double estimatedCost;
  final bool isCompleted;
  final DateTime? scheduledDate;
  final String? notes;

  DentalTreatmentItem copyWith({bool? isCompleted}) => DentalTreatmentItem(
        id: id,
        patientId: patientId,
        procedureName: procedureName,
        teethInvolved: teethInvolved,
        estimatedCost: estimatedCost,
        isCompleted: isCompleted ?? this.isCompleted,
        scheduledDate: scheduledDate,
        notes: notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'procedure_name': procedureName,
        'teeth_involved': teethInvolved,
        'estimated_cost': estimatedCost,
        'is_completed': isCompleted,
        'scheduled_date': scheduledDate?.toIso8601String(),
        'notes': notes,
      };

  factory DentalTreatmentItem.fromJson(Map<String, dynamic> j) => DentalTreatmentItem(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        procedureName: j['procedure_name'] as String,
        teethInvolved: j['teeth_involved'] as String,
        estimatedCost: (j['estimated_cost'] as num).toDouble(),
        isCompleted: (j['is_completed'] as bool?) ?? false,
        scheduledDate: j['scheduled_date'] != null
            ? DateTime.parse(j['scheduled_date'] as String)
            : null,
        notes: j['notes'] as String?,
      );
}

// ============================================================================
// 3. PREGNANCY CARE MODELS
// ============================================================================

class PregnancyRecord {
  const PregnancyRecord({
    required this.patientId,
    required this.lmp, // Last Menstrual Period
    required this.edd, // Estimated Due Date
    this.gravida = 1,
    this.para = 0,
    this.bloodGroup = 'O+',
    this.isHighRisk = false,
    this.highRiskReason,
  });

  final String patientId;
  final DateTime lmp;
  final DateTime edd;
  final int gravida;
  final int para;
  final String bloodGroup;
  final bool isHighRisk;
  final String? highRiskReason;

  int get daysSinceLmp => DateTime.now().difference(lmp).inDays.clamp(0, 300);
  int get gestationalWeeks => daysSinceLmp ~/ 7;
  int get gestationalDays => daysSinceLmp % 7;
  int get daysRemaining => edd.difference(DateTime.now()).inDays.clamp(0, 300);

  int get trimester {
    if (gestationalWeeks <= 13) return 1;
    if (gestationalWeeks <= 27) return 2;
    return 3;
  }

  String get babyMilestone => switch (gestationalWeeks) {
        <= 8 => 'Size of a Raspberry (~1.6 cm, heart beating)',
        <= 12 => 'Size of a Lime (~5.4 cm, all organs forming)',
        <= 16 => 'Size of an Avocado (~11.6 cm, can hear sounds)',
        <= 20 => 'Size of a Banana (~25.6 cm, movements noticeable)',
        <= 24 => 'Size of an Ear of Corn (~30 cm, developing lungs)',
        <= 28 => 'Size of an Eggplant (~37 cm, eyes can blink)',
        <= 32 => 'Size of a Jicama (~42 cm, practicing breathing)',
        <= 36 => 'Size of a Papaya (~47 cm, rapid weight gain)',
        _ => 'Size of a Watermelon (~50 cm, fully ready for birth)',
      };

  static DateTime computeEdd(DateTime lmp) => lmp.add(const Duration(days: 280));

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'lmp': lmp.toIso8601String(),
        'edd': edd.toIso8601String(),
        'gravida': gravida,
        'para': para,
        'blood_group': bloodGroup,
        'is_high_risk': isHighRisk,
        'high_risk_reason': highRiskReason,
      };

  factory PregnancyRecord.fromJson(Map<String, dynamic> j) => PregnancyRecord(
        patientId: j['patient_id'] as String,
        lmp: DateTime.parse(j['lmp'] as String),
        edd: DateTime.parse(j['edd'] as String),
        gravida: (j['gravida'] as num?)?.toInt() ?? 1,
        para: (j['para'] as num?)?.toInt() ?? 0,
        bloodGroup: (j['blood_group'] as String?) ?? 'O+',
        isHighRisk: (j['is_high_risk'] as bool?) ?? false,
        highRiskReason: j['high_risk_reason'] as String?,
      );
}

class AncCheckup {
  const AncCheckup({
    required this.id,
    required this.patientId,
    required this.date,
    required this.gestationalWeeks,
    required this.bloodPressure, // e.g. "116/78"
    required this.weightKg,
    this.fundalHeightCm,
    this.fetalHeartRateBpm, // e.g. 142
    this.urineSugarAlbumin,
    this.doctorAdvice,
  });

  final String id;
  final String patientId;
  final DateTime date;
  final int gestationalWeeks;
  final String bloodPressure;
  final double weightKg;
  final double? fundalHeightCm;
  final int? fetalHeartRateBpm;
  final String? urineSugarAlbumin;
  final String? doctorAdvice;

  bool get isBpElevated {
    final parts = bloodPressure.split('/');
    if (parts.length == 2) {
      final sys = int.tryParse(parts[0].trim()) ?? 120;
      final dia = int.tryParse(parts[1].trim()) ?? 80;
      return sys >= 140 || dia >= 90;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'date': date.toIso8601String(),
        'gestational_weeks': gestationalWeeks,
        'blood_pressure': bloodPressure,
        'weight_kg': weightKg,
        'fundal_height_cm': fundalHeightCm,
        'fetal_heart_rate_bpm': fetalHeartRateBpm,
        'urine_sugar_albumin': urineSugarAlbumin,
        'doctor_advice': doctorAdvice,
      };

  factory AncCheckup.fromJson(Map<String, dynamic> j) => AncCheckup(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        date: DateTime.parse(j['date'] as String),
        gestationalWeeks: (j['gestational_weeks'] as num).toInt(),
        bloodPressure: j['blood_pressure'] as String,
        weightKg: (j['weight_kg'] as num).toDouble(),
        fundalHeightCm: (j['fundal_height_cm'] as num?)?.toDouble(),
        fetalHeartRateBpm: (j['fetal_heart_rate_bpm'] as num?)?.toInt(),
        urineSugarAlbumin: j['urine_sugar_albumin'] as String?,
        doctorAdvice: j['doctor_advice'] as String?,
      );
}

class PrenatalTestItem {
  const PrenatalTestItem({
    required this.name,
    required this.trimester,
    required this.recommendedWeeks,
    this.isDone = false,
    this.resultNote,
  });

  final String name;
  final int trimester;
  final String recommendedWeeks;
  final bool isDone;
  final String? resultNote;

  PrenatalTestItem copyWith({bool? isDone, String? resultNote}) => PrenatalTestItem(
        name: name,
        trimester: trimester,
        recommendedWeeks: recommendedWeeks,
        isDone: isDone ?? this.isDone,
        resultNote: resultNote ?? this.resultNote,
      );
}

// ============================================================================
// 4. OPHTHALMOLOGY & EYE CLINIC MODELS
// ============================================================================

class RefractionReading {
  const RefractionReading({
    required this.sphere,
    required this.cylinder,
    required this.axis,
    this.nearAdd,
    required this.visualAcuity, // e.g. "6/6", "20/20"
  });

  final double sphere; // SPH: e.g. -2.25
  final double cylinder; // CYL: e.g. -0.50
  final int axis; // AXIS: 0 - 180
  final double? nearAdd; // ADD: e.g. +1.50
  final String visualAcuity;

  String get formula =>
      'SPH ${sphere >= 0 ? '+' : ''}${sphere.toStringAsFixed(2)} '
      'CYL ${cylinder >= 0 ? '+' : ''}${cylinder.toStringAsFixed(2)} '
      'AXIS ${axis}°${nearAdd != null ? ' ADD +${nearAdd!.toStringAsFixed(2)}' : ''} (VA: $visualAcuity)';

  Map<String, dynamic> toJson() => {
        'sphere': sphere,
        'cylinder': cylinder,
        'axis': axis,
        'near_add': nearAdd,
        'visual_acuity': visualAcuity,
      };

  factory RefractionReading.fromJson(Map<String, dynamic> j) => RefractionReading(
        sphere: (j['sphere'] as num).toDouble(),
        cylinder: (j['cylinder'] as num).toDouble(),
        axis: (j['axis'] as num).toInt(),
        nearAdd: (j['near_add'] as num?)?.toDouble(),
        visualAcuity: (j['visual_acuity'] as String?) ?? '6/6',
      );
}

class RefractionPrescription {
  const RefractionPrescription({
    required this.id,
    required this.patientId,
    required this.date,
    required this.od, // Right Eye
    required this.os, // Left Eye
    required this.pupillaryDistanceMm, // e.g. 62 mm
    this.lensTypeAdvice = 'Anti-reflective, Blue-cut coating',
    this.notes,
  });

  final String id;
  final String patientId;
  final DateTime date;
  final RefractionReading od; // Right eye (Oculus Dexter)
  final RefractionReading os; // Left eye (Oculus Sinister)
  final double pupillaryDistanceMm;
  final String lensTypeAdvice;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'date': date.toIso8601String(),
        'od': od.toJson(),
        'os': os.toJson(),
        'pupillary_distance_mm': pupillaryDistanceMm,
        'lens_type_advice': lensTypeAdvice,
        'notes': notes,
      };

  factory RefractionPrescription.fromJson(Map<String, dynamic> j) => RefractionPrescription(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        date: DateTime.parse(j['date'] as String),
        od: RefractionReading.fromJson(Map<String, dynamic>.from(j['od'] as Map)),
        os: RefractionReading.fromJson(Map<String, dynamic>.from(j['os'] as Map)),
        pupillaryDistanceMm: (j['pupillary_distance_mm'] as num).toDouble(),
        lensTypeAdvice: (j['lens_type_advice'] as String?) ?? 'Single Vision',
        notes: j['notes'] as String?,
      );
}

class EyeExamRecord {
  const EyeExamRecord({
    required this.id,
    required this.patientId,
    required this.date,
    required this.iopOD, // Intraocular Pressure (mmHg)
    required this.iopOS,
    this.slitLampFindings,
    this.fundusFindings,
    this.diagnosis,
    this.eyeDropMedications,
  });

  final String id;
  final String patientId;
  final DateTime date;
  final double iopOD; // Normal is 10 - 21 mmHg
  final double iopOS;
  final String? slitLampFindings;
  final String? fundusFindings;
  final String? diagnosis;
  final String? eyeDropMedications;

  bool get isIopHigh => iopOD > 21 || iopOS > 21;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'date': date.toIso8601String(),
        'iop_od': iopOD,
        'iop_os': iopOS,
        'slit_lamp_findings': slitLampFindings,
        'fundus_findings': fundusFindings,
        'diagnosis': diagnosis,
        'eye_drop_medications': eyeDropMedications,
      };

  factory EyeExamRecord.fromJson(Map<String, dynamic> j) => EyeExamRecord(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        date: DateTime.parse(j['date'] as String),
        iopOD: (j['iop_od'] as num).toDouble(),
        iopOS: (j['iop_os'] as num).toDouble(),
        slitLampFindings: j['slit_lamp_findings'] as String?,
        fundusFindings: j['fundus_findings'] as String?,
        diagnosis: j['diagnosis'] as String?,
        eyeDropMedications: j['eye_drop_medications'] as String?,
      );
}

// ============================================================================
// 5. PSYCHIATRY & COUNSELLING MODELS
// ============================================================================

enum ScreenerType {
  phq9,
  gad7;

  String get label => switch (this) {
        ScreenerType.phq9 => 'PHQ-9 (Depression Screener)',
        ScreenerType.gad7 => 'GAD-7 (Anxiety Screener)',
      };

  List<String> get questions => switch (this) {
        ScreenerType.phq9 => const [
            'Little interest or pleasure in doing things',
            'Feeling down, depressed, or hopeless',
            'Trouble falling or staying asleep, or sleeping too much',
            'Feeling tired or having little energy',
            'Poor appetite or overeating',
            'Feeling bad about yourself — or that you are a failure',
            'Trouble concentrating on things, like reading or television',
            'Moving or speaking slowly, or fidgety / restless',
            'Thoughts that you would be better off dead or hurting yourself',
          ],
        ScreenerType.gad7 => const [
            'Feeling nervous, anxious, or on edge',
            'Not being able to stop or control worrying',
            'Worrying too much about different things',
            'Trouble relaxing',
            'Being so restless that it is hard to sit still',
            'Becoming easily annoyed or irritable',
            'Feeling afraid, as if something awful might happen',
          ],
      };
}

class ScreenerResult {
  const ScreenerResult({
    required this.id,
    required this.patientId,
    required this.date,
    required this.type,
    required this.totalScore,
    required this.severityBand,
    required this.answers,
    this.clinicalSummary,
  });

  final String id;
  final String patientId;
  final DateTime date;
  final ScreenerType type;
  final int totalScore;
  final String severityBand;
  final List<int> answers;
  final String? clinicalSummary;

  static String computeSeverity(ScreenerType type, int score) {
    if (type == ScreenerType.phq9) {
      if (score <= 4) return 'Minimal (0-4)';
      if (score <= 9) return 'Mild (5-9)';
      if (score <= 14) return 'Moderate (10-14)';
      if (score <= 19) return 'Moderately Severe (15-19)';
      return 'Severe (20-27)';
    } else {
      if (score <= 4) return 'Minimal (0-4)';
      if (score <= 9) return 'Mild (5-9)';
      if (score <= 14) return 'Moderate (10-14)';
      return 'Severe (15-21)';
    }
  }

  Color get severityColor => const Color(0xFF1565C0); // Medical Blue

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'date': date.toIso8601String(),
        'type': type.name,
        'total_score': totalScore,
        'severity_band': severityBand,
        'answers': answers,
        'clinical_summary': clinicalSummary,
      };

  factory ScreenerResult.fromJson(Map<String, dynamic> j) => ScreenerResult(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        date: DateTime.parse(j['date'] as String),
        type: ScreenerType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => ScreenerType.phq9,
        ),
        totalScore: (j['total_score'] as num).toInt(),
        severityBand: j['severity_band'] as String,
        answers: (j['answers'] as List).map((e) => (e as num).toInt()).toList(),
        clinicalSummary: j['clinical_summary'] as String?,
      );
}

class TherapyNote {
  const TherapyNote({
    required this.id,
    required this.patientId,
    required this.date,
    required this.sessionNumber,
    required this.modality, // e.g. "Cognitive Behavioral Therapy (CBT)"
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    this.riskLevel = 'Low',
  });

  final String id;
  final String patientId;
  final DateTime date;
  final int sessionNumber;
  final String modality;
  final String subjective; // S
  final String objective; // O
  final String assessment; // A
  final String plan; // P
  final String riskLevel; // Low, Moderate, High

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'date': date.toIso8601String(),
        'session_number': sessionNumber,
        'modality': modality,
        'subjective': subjective,
        'objective': objective,
        'assessment': assessment,
        'plan': plan,
        'risk_level': riskLevel,
      };

  factory TherapyNote.fromJson(Map<String, dynamic> j) => TherapyNote(
        id: j['id'] as String,
        patientId: j['patient_id'] as String,
        date: DateTime.parse(j['date'] as String),
        sessionNumber: (j['session_number'] as num).toInt(),
        modality: j['modality'] as String,
        subjective: j['subjective'] as String,
        objective: j['objective'] as String,
        assessment: j['assessment'] as String,
        plan: j['plan'] as String,
        riskLevel: (j['risk_level'] as String?) ?? 'Low',
      );
}

class CopingGoal {
  const CopingGoal({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
  });

  final String id;
  final String patientId;
  final String title;
  final String description;
  final String category; // e.g. "Mindfulness", "Sleep Hygiene", "Cognitive Reframing"
  final bool isCompleted;

  CopingGoal copyWith({bool? isCompleted}) => CopingGoal(
        id: id,
        patientId: patientId,
        title: title,
        description: description,
        category: category,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
