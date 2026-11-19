import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class DepartmentRepository {
  DepartmentRepository(this._c);
  // ignore: unused_field
  final SupabaseClient _c;

  // In-memory / cache stores per patientId
  final Map<String, List<ToothData>> _dentalTeeth = {};
  final Map<String, List<DentalTreatmentItem>> _dentalPlans = {};

  final Map<String, List<DermaComparison>> _dermaComparisons = {};
  final Map<String, List<DermaSessionLog>> _dermaSessions = {};

  final Map<String, PregnancyRecord> _pregnancyRecords = {};
  final Map<String, List<AncCheckup>> _ancCheckups = {};
  final Map<String, List<PrenatalTestItem>> _prenatalTests = {};

  final Map<String, RefractionPrescription?> _refractions = {};
  final Map<String, List<EyeExamRecord>> _eyeExams = {};

  final Map<String, List<ScreenerResult>> _screeners = {};
  final Map<String, List<TherapyNote>> _therapyNotes = {};
  final Map<String, List<CopingGoal>> _copingGoals = {};

  // ==========================================================================
  // DENTAL
  // ==========================================================================

  List<ToothData> getToothChart(String patientId) {
    if (_dentalTeeth.containsKey(patientId)) {
      return _dentalTeeth[patientId]!;
    }

    // Default 32 adult teeth with standard Universal numbering
    final teeth = <ToothData>[];

    // Upper Arch (1 to 16, Right to Left)
    final upperNames = [
      'Upper Right 3rd Molar (#1)',
      'Upper Right 2nd Molar (#2)',
      'Upper Right 1st Molar (#3)',
      'Upper Right 2nd Premolar (#4)',
      'Upper Right 1st Premolar (#5)',
      'Upper Right Canine (#6)',
      'Upper Right Lateral Incisor (#7)',
      'Upper Right Central Incisor (#8)',
      'Upper Left Central Incisor (#9)',
      'Upper Left Lateral Incisor (#10)',
      'Upper Left Canine (#11)',
      'Upper Left 1st Premolar (#12)',
      'Upper Left 2nd Premolar (#13)',
      'Upper Left 1st Molar (#14)',
      'Upper Left 2nd Molar (#15)',
      'Upper Left 3rd Molar (#16)',
    ];

    // Lower Arch (17 to 32, Left to Right)
    final lowerNames = [
      'Lower Left 3rd Molar (#17)',
      'Lower Left 2nd Molar (#18)',
      'Lower Left 1st Molar (#19)',
      'Lower Left 2nd Premolar (#20)',
      'Lower Left 1st Premolar (#21)',
      'Lower Left Canine (#22)',
      'Lower Left Lateral Incisor (#23)',
      'Lower Left Central Incisor (#24)',
      'Lower Right Central Incisor (#25)',
      'Lower Right Lateral Incisor (#26)',
      'Lower Right Canine (#27)',
      'Lower Right 1st Premolar (#28)',
      'Lower Right 2nd Premolar (#29)',
      'Lower Right 1st Molar (#30)',
      'Lower Right 2nd Molar (#31)',
      'Lower Right 3rd Molar (#32)',
    ];

    for (int i = 0; i < 16; i++) {
      final num = i + 1;
      // Default demo conditions on teeth 3 & 14
      var cond = ToothCondition.sound;
      List<String> surfaces = [];
      String? notes;
      if (num == 3) {
        cond = ToothCondition.filled;
        surfaces = ['Occlusal'];
        notes = 'Amalgam replaced with composite resin';
      } else if (num == 14) {
        cond = ToothCondition.caries;
        surfaces = ['Occlusal', 'Distal'];
        notes = 'Moderate decay, filling advised';
      }
      teeth.add(ToothData(
        toothNumber: num,
        name: upperNames[i],
        arch: 'upper',
        condition: cond,
        surfaces: surfaces,
        notes: notes,
      ));
    }

    for (int i = 0; i < 16; i++) {
      final num = i + 17;
      var cond = ToothCondition.sound;
      List<String> surfaces = [];
      String? notes;
      if (num == 19) {
        cond = ToothCondition.rootCanal;
        notes = 'RCT completed; crown placement scheduled';
      } else if (num == 30) {
        cond = ToothCondition.crown;
        notes = 'Porcelain-fused-to-metal crown';
      }
      teeth.add(ToothData(
        toothNumber: num,
        name: lowerNames[i],
        arch: 'lower',
        condition: cond,
        surfaces: surfaces,
        notes: notes,
      ));
    }

    _dentalTeeth[patientId] = teeth;
    return teeth;
  }

  void updateTooth(String patientId, ToothData updated) {
    final list = getToothChart(patientId);
    final idx = list.indexWhere((t) => t.toothNumber == updated.toothNumber);
    if (idx != -1) {
      list[idx] = updated;
    }
  }

  List<DentalTreatmentItem> getTreatmentPlans(String patientId) {
    if (_dentalPlans.containsKey(patientId)) {
      return _dentalPlans[patientId]!;
    }

    final initial = [
      DentalTreatmentItem(
        id: 'dp-1',
        patientId: patientId,
        procedureName: 'Composite Filling (Tooth #14)',
        teethInvolved: '#14 Occlusal-Distal',
        estimatedCost: 1800.0,
        isCompleted: false,
        scheduledDate: DateTime.now().add(const Duration(days: 4)),
        notes: 'Decay excavation and tooth-colored composite restoration',
      ),
      DentalTreatmentItem(
        id: 'dp-2',
        patientId: patientId,
        procedureName: 'Zirconia Crown Placement (Tooth #19)',
        teethInvolved: '#19',
        estimatedCost: 8500.0,
        isCompleted: false,
        scheduledDate: DateTime.now().add(const Duration(days: 10)),
        notes: 'Post-endodontic full contour crown',
      ),
      DentalTreatmentItem(
        id: 'dp-3',
        patientId: patientId,
        procedureName: 'Full Mouth Ultrasonic Scaling & Polishing',
        teethInvolved: 'All Quadrants',
        estimatedCost: 1200.0,
        isCompleted: true,
        scheduledDate: DateTime.now().subtract(const Duration(days: 14)),
        notes: 'Plaque and calculus removal complete',
      ),
    ];
    _dentalPlans[patientId] = initial;
    return initial;
  }

  void addTreatmentPlan(String patientId, DentalTreatmentItem item) {
    final plans = getTreatmentPlans(patientId);
    plans.insert(0, item);
  }

  void toggleTreatmentPlan(String patientId, String itemId) {
    final plans = getTreatmentPlans(patientId);
    final idx = plans.indexWhere((p) => p.id == itemId);
    if (idx != -1) {
      plans[idx] = plans[idx].copyWith(isCompleted: !plans[idx].isCompleted);
    }
  }

  // ==========================================================================
  // DERMATOLOGY
  // ==========================================================================

  List<DermaComparison> getDermaComparisons(String patientId) {
    if (_dermaComparisons.containsKey(patientId)) {
      return _dermaComparisons[patientId]!;
    }

    final initial = [
      DermaComparison(
        id: 'dc-1',
        patientId: patientId,
        title: 'Acne Vulgaris & Post-Inflammatory Erythema',
        affectedArea: 'Bilateral Cheeks & Chin',
        beforeDate: DateTime.now().subtract(const Duration(days: 45)),
        afterDate: DateTime.now().subtract(const Duration(days: 3)),
        beforePhotoUrl: 'assets/derma/acne_before.jpg',
        afterPhotoUrl: 'assets/derma/acne_after.jpg',
        treatmentTag: 'Salicylic Acid 20% + Topical Retinoid',
        conditionNotes: '70% reduction in inflammatory papules; significant redness improvement.',
      ),
      DermaComparison(
        id: 'dc-2',
        patientId: patientId,
        title: 'Melasma & Hyperpigmentation',
        affectedArea: 'Malar Eminence & Forehead',
        beforeDate: DateTime.now().subtract(const Duration(days: 90)),
        afterDate: DateTime.now().subtract(const Duration(days: 12)),
        beforePhotoUrl: 'assets/derma/melasma_before.jpg',
        afterPhotoUrl: 'assets/derma/melasma_after.jpg',
        treatmentTag: 'Q-Switched Laser + Tranexamic Acid Serum',
        conditionNotes: 'Pigment tone significantly evened out; SPF 50+ reapplication reinforced.',
      ),
    ];
    _dermaComparisons[patientId] = initial;
    return initial;
  }

  void addDermaComparison(String patientId, DermaComparison item) {
    final list = getDermaComparisons(patientId);
    list.insert(0, item);
  }

  List<DermaSessionLog> getDermaSessions(String patientId) {
    if (_dermaSessions.containsKey(patientId)) {
      return _dermaSessions[patientId]!;
    }

    final initial = [
      DermaSessionLog(
        id: 'ds-1',
        patientId: patientId,
        treatmentName: 'Salicylic Acid 20% Chemical Peel',
        sessionNumber: 3,
        totalSessions: 6,
        sessionDate: DateTime.now().subtract(const Duration(days: 7)),
        energyParameters: 'Contact time: 4 mins, Neutralizer applied',
        clinicalReaction: 'Mild frosting observed, tolerable tingling',
        nextSessionDate: DateTime.now().add(const Duration(days: 14)),
        notes: 'Patient tolerating well. Advised strict sunscreen and gentle cleanser.',
      ),
      DermaSessionLog(
        id: 'ds-2',
        patientId: patientId,
        treatmentName: 'Acne Scar Subcision & Microneedling',
        sessionNumber: 2,
        totalSessions: 4,
        sessionDate: DateTime.now().subtract(const Duration(days: 28)),
        energyParameters: 'Needle depth: 1.5mm, 12-pin cartridge',
        clinicalReaction: 'Erythema and mild pinpoint bleeding, resolved in 48h',
        nextSessionDate: DateTime.now().add(const Duration(days: 21)),
        notes: 'Noticeable improvement in rolling scars over right cheek.',
      ),
      DermaSessionLog(
        id: 'ds-3',
        patientId: patientId,
        treatmentName: 'Salicylic Acid 20% Chemical Peel',
        sessionNumber: 2,
        totalSessions: 6,
        sessionDate: DateTime.now().subtract(const Duration(days: 21)),
        energyParameters: 'Contact time: 3 mins',
        clinicalReaction: 'Mild erythema, no peeling',
        notes: 'Gradual decrease in active pustules.',
      ),
    ];
    _dermaSessions[patientId] = initial;
    return initial;
  }

  void addDermaSession(String patientId, DermaSessionLog session) {
    final list = getDermaSessions(patientId);
    list.insert(0, session);
  }

  // ==========================================================================
  // PREGNANCY CARE
  // ==========================================================================

  PregnancyRecord getPregnancyRecord(String patientId) {
    if (_pregnancyRecords.containsKey(patientId)) {
      return _pregnancyRecords[patientId]!;
    }

    // Default to ~24 weeks pregnant (LMP 168 days ago)
    final lmp = DateTime.now().subtract(const Duration(days: 168));
    final edd = PregnancyRecord.computeEdd(lmp);
    final rec = PregnancyRecord(
      patientId: patientId,
      lmp: lmp,
      edd: edd,
      gravida: 1,
      para: 0,
      bloodGroup: 'B+',
      isHighRisk: false,
      highRiskReason: null,
    );
    _pregnancyRecords[patientId] = rec;
    return rec;
  }

  void updatePregnancyRecord(String patientId, PregnancyRecord record) {
    _pregnancyRecords[patientId] = record;
  }

  List<AncCheckup> getAncCheckups(String patientId) {
    if (_ancCheckups.containsKey(patientId)) {
      return _ancCheckups[patientId]!;
    }

    final initial = [
      AncCheckup(
        id: 'anc-1',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 10)),
        gestationalWeeks: 23,
        bloodPressure: '114/74',
        weightKg: 64.2,
        fundalHeightCm: 23.5,
        fetalHeartRateBpm: 144,
        urineSugarAlbumin: 'Nil / Nil',
        doctorAdvice: 'Fetal growth on track. Continue Iron + Calcium and daily 30-min walk.',
      ),
      AncCheckup(
        id: 'anc-2',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 38)),
        gestationalWeeks: 19,
        bloodPressure: '110/72',
        weightKg: 62.0,
        fundalHeightCm: 19.0,
        fetalHeartRateBpm: 148,
        urineSugarAlbumin: 'Nil / Nil',
        doctorAdvice: 'TIFFA anomaly scan reviewed - normal anatomy. Good fetal movements.',
      ),
      AncCheckup(
        id: 'anc-3',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 72)),
        gestationalWeeks: 14,
        bloodPressure: '118/76',
        weightKg: 59.8,
        fundalHeightCm: 14.2,
        fetalHeartRateBpm: 152,
        urineSugarAlbumin: 'Nil / Nil',
        doctorAdvice: 'Entering 2nd trimester. Morning sickness subsided. Start oral iron supplement.',
      ),
    ];
    _ancCheckups[patientId] = initial;
    return initial;
  }

  void addAncCheckup(String patientId, AncCheckup checkup) {
    final list = getAncCheckups(patientId);
    list.insert(0, checkup);
  }

  List<PrenatalTestItem> getPrenatalTests(String patientId) {
    if (_prenatalTests.containsKey(patientId)) {
      return _prenatalTests[patientId]!;
    }

    final initial = [
      // Trimester 1
      const PrenatalTestItem(
        name: 'Dating & Viability Ultrasound Scan',
        trimester: 1,
        recommendedWeeks: 'Week 7 - 9',
        isDone: true,
        resultNote: 'Single intrauterine gestation confirmed, cardiac activity present.',
      ),
      const PrenatalTestItem(
        name: 'NT (Nuchal Translucency) Scan & Dual Marker',
        trimester: 1,
        recommendedWeeks: 'Week 11 - 13',
        isDone: true,
        resultNote: 'NT: 1.4mm (Low risk for chromosomal aneuploidies).',
      ),
      const PrenatalTestItem(
        name: 'Complete Blood Count, Blood Group & Thyroid (TSH)',
        trimester: 1,
        recommendedWeeks: 'Week 8 - 12',
        isDone: true,
        resultNote: 'Hb: 11.8 g/dL, TSH: 1.9 mIU/L (Euthyroid).',
      ),
      // Trimester 2
      const PrenatalTestItem(
        name: 'TIFFA (Targeted Level II Anomaly Scan)',
        trimester: 2,
        recommendedWeeks: 'Week 18 - 20',
        isDone: true,
        resultNote: 'Normal fetal anatomy, placenta anterior, liquor adequate.',
      ),
      const PrenatalTestItem(
        name: 'OGTT (Oral Glucose Tolerance Test - 75g)',
        trimester: 2,
        recommendedWeeks: 'Week 24 - 28',
        isDone: false,
        resultNote: 'Scheduled for next visit to screen for gestational diabetes.',
      ),
      const PrenatalTestItem(
        name: 'Tetanus Toxoid (TT-1 / Tdap) Vaccine',
        trimester: 2,
        recommendedWeeks: 'Week 20 - 24',
        isDone: true,
        resultNote: 'Administered on 19th week visit.',
      ),
      // Trimester 3
      const PrenatalTestItem(
        name: 'Growth & Fetal Doppler Ultrasound Scan',
        trimester: 3,
        recommendedWeeks: 'Week 32 - 34',
        isDone: false,
        resultNote: 'Pending 3rd trimester.',
      ),
      const PrenatalTestItem(
        name: 'Group B Streptococcus (GBS) Swab',
        trimester: 3,
        recommendedWeeks: 'Week 36 - 37',
        isDone: false,
        resultNote: 'Routine pre-delivery swab.',
      ),
    ];
    _prenatalTests[patientId] = initial;
    return initial;
  }

  void togglePrenatalTest(String patientId, String testName) {
    final list = getPrenatalTests(patientId);
    final idx = list.indexWhere((t) => t.name == testName);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isDone: !list[idx].isDone);
    }
  }

  // ==========================================================================
  // OPHTHALMOLOGY & EYE CLINIC
  // ==========================================================================

  RefractionPrescription getRefraction(String patientId) {
    if (_refractions.containsKey(patientId) && _refractions[patientId] != null) {
      return _refractions[patientId]!;
    }

    final initial = RefractionPrescription(
      id: 'ref-1',
      patientId: patientId,
      date: DateTime.now().subtract(const Duration(days: 8)),
      od: const RefractionReading(
        sphere: -2.00,
        cylinder: -0.50,
        axis: 90,
        nearAdd: 1.25,
        visualAcuity: '6/6',
      ),
      os: const RefractionReading(
        sphere: -2.25,
        cylinder: -0.75,
        axis: 180,
        nearAdd: 1.25,
        visualAcuity: '6/6',
      ),
      pupillaryDistanceMm: 63.0,
      lensTypeAdvice: 'Progressive Addition Lenses (PAL) with Blue-cut Anti-reflective coating',
      notes: 'Advised 20-20-20 rule during computer screen use.',
    );
    _refractions[patientId] = initial;
    return initial;
  }

  void saveRefraction(String patientId, RefractionPrescription rx) {
    _refractions[patientId] = rx;
  }

  List<EyeExamRecord> getEyeExams(String patientId) {
    if (_eyeExams.containsKey(patientId)) {
      return _eyeExams[patientId]!;
    }

    final initial = [
      EyeExamRecord(
        id: 'exam-1',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 8)),
        iopOD: 15.0,
        iopOS: 16.0,
        slitLampFindings: 'Cornea clear, anterior chamber deep & quiet, lens clear OU',
        fundusFindings: 'Optic disc pink with sharp margins, cup-disc ratio 0.3, macula healthy',
        diagnosis: 'Compound Myopic Astigmatism with Early Presbyopia',
        eyeDropMedications: 'Carboxymethylcellulose 0.5% lubricating drops (1 drop 4x daily)',
      ),
      EyeExamRecord(
        id: 'exam-2',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 180)),
        iopOD: 14.5,
        iopOS: 15.0,
        slitLampFindings: 'Mild conjunctival hyperemia, mild tear film instability',
        fundusFindings: 'Fundus within normal limits',
        diagnosis: 'Digital Eye Strain & Mild Dry Eye Syndrome',
        eyeDropMedications: 'Sodium Hyaluronate 0.1% drops',
      ),
    ];
    _eyeExams[patientId] = initial;
    return initial;
  }

  void addEyeExam(String patientId, EyeExamRecord exam) {
    final list = getEyeExams(patientId);
    list.insert(0, exam);
  }

  // ==========================================================================
  // PSYCHIATRY & COUNSELLING
  // ==========================================================================

  List<ScreenerResult> getScreenerHistory(String patientId) {
    if (_screeners.containsKey(patientId)) {
      return _screeners[patientId]!;
    }

    final initial = [
      ScreenerResult(
        id: 'scr-1',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 4)),
        type: ScreenerType.phq9,
        totalScore: 8,
        severityBand: 'Mild (5-9)',
        answers: const [1, 1, 1, 1, 1, 1, 1, 1, 0],
        clinicalSummary:
            'Significant improvement from baseline (score 16 -> 8). Sleep architecture improved, active interest returning.',
      ),
      ScreenerResult(
        id: 'scr-2',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 4)),
        type: ScreenerType.gad7,
        totalScore: 6,
        severityBand: 'Mild (5-9)',
        answers: const [1, 1, 1, 1, 1, 1, 0],
        clinicalSummary:
            'Generalized worrying reduced. Somatic restlessness decreased with daily 4-7-8 breathing practice.',
      ),
      ScreenerResult(
        id: 'scr-3',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 35)),
        type: ScreenerType.phq9,
        totalScore: 16,
        severityBand: 'Moderately Severe (15-19)',
        answers: const [2, 2, 2, 2, 2, 2, 2, 2, 0],
        clinicalSummary:
            'Initial intake: Low mood, terminal insomnia, persistent fatigue, feeling overwhelmed by workplace burnout.',
      ),
    ];
    _screeners[patientId] = initial;
    return initial;
  }

  void submitScreener(
    String patientId,
    ScreenerType type,
    List<int> answers, {
    String? clinicalSummary,
  }) {
    final total = answers.fold<int>(0, (a, b) => a + b);
    final severity = ScreenerResult.computeSeverity(type, total);
    final item = ScreenerResult(
      id: 'scr-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      date: DateTime.now(),
      type: type,
      totalScore: total,
      severityBand: severity,
      answers: answers,
      clinicalSummary: clinicalSummary,
    );
    final list = getScreenerHistory(patientId);
    list.insert(0, item);
  }

  List<TherapyNote> getTherapyNotes(String patientId) {
    if (_therapyNotes.containsKey(patientId)) {
      return _therapyNotes[patientId]!;
    }

    final initial = [
      TherapyNote(
        id: 'tn-1',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 4)),
        sessionNumber: 4,
        modality: 'Cognitive Behavioral Therapy (CBT)',
        subjective:
            'Client reports: "I managed my presentation without experiencing a panic attack. I used the grounding exercise before entering the room."',
        objective:
            'Client arrived on time, dressed appropriately. Affect was congruent, speech rate normal. Eye contact was steady and engaged.',
        assessment:
            'Client is progressing well through cognitive restructuring. The catastrophic thought loop ("I will fail and lose my job") was challenged effectively.',
        plan:
            '1. Continue daily thought journal (3 column technique).\n2. Practice progressive muscle relaxation before sleep.\n3. Next session in 2 weeks.',
        riskLevel: 'Low',
      ),
      TherapyNote(
        id: 'tn-2',
        patientId: patientId,
        date: DateTime.now().subtract(const Duration(days: 18)),
        sessionNumber: 3,
        modality: 'Cognitive Behavioral Therapy (CBT) & Psychoeducation',
        subjective:
            'Client described persistent anticipatory anxiety regarding performance reviews. Sleep interrupted around 3 AM with racing thoughts.',
        objective:
            'Appeared mildly fatigued. Fidgeting with hands noted. Mood described as "nervous but willing to try."',
        assessment:
            'High cognitive distortions, specifically "fortune-telling" and "all-or-nothing thinking". Insight is good.',
        plan:
            'Introduced cognitive distortions worksheet. Began sleep hygiene protocol (no screens 1h before bed).',
        riskLevel: 'Low',
      ),
    ];
    _therapyNotes[patientId] = initial;
    return initial;
  }

  void addTherapyNote(String patientId, TherapyNote note) {
    final list = getTherapyNotes(patientId);
    list.insert(0, note);
  }

  List<CopingGoal> getCopingGoals(String patientId) {
    if (_copingGoals.containsKey(patientId)) {
      return _copingGoals[patientId]!;
    }

    final initial = [
      CopingGoal(
        id: 'cg-1',
        patientId: patientId,
        title: 'Daily 4-7-8 Breathing (Morning & Evening)',
        description: 'Inhale for 4 seconds, hold for 7 seconds, exhale slowly for 8 seconds.',
        category: 'Somatic Grounding',
        isCompleted: true,
      ),
      CopingGoal(
        id: 'cg-2',
        patientId: patientId,
        title: 'Thought Record for Anticipatory Worry',
        description: 'Identify trigger -> Automatic thought -> Evidence against thought -> Alternative balanced thought.',
        category: 'Cognitive Reframing',
        isCompleted: false,
      ),
      CopingGoal(
        id: 'cg-3',
        patientId: patientId,
        title: 'Sleep Hygiene Boundary (Wind-down at 10 PM)',
        description: 'Dim room lights, digital detox 45 mins prior to bedtime, no caffeine past 3 PM.',
        category: 'Lifestyle & Sleep',
        isCompleted: false,
      ),
    ];
    _copingGoals[patientId] = initial;
    return initial;
  }

  void toggleCopingGoal(String patientId, String goalId) {
    final list = getCopingGoals(patientId);
    final idx = list.indexWhere((g) => g.id == goalId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isCompleted: !list[idx].isCompleted);
    }
  }
}
