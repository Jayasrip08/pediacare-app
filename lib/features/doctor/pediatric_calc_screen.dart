import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class PediatricCalcScreen extends StatefulWidget {
  const PediatricCalcScreen({super.key});

  @override
  State<PediatricCalcScreen> createState() => _PediatricCalcScreenState();
}

class _PediatricCalcScreenState extends State<PediatricCalcScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  double _weightKg = 12.0;
  int _ageYears = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void disposeWidget() {
    _tabController.dispose();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Holliday-Segar Maintenance Fluid Calculator
  double get _dailyFluidMl {
    if (_weightKg <= 10) {
      return _weightKg * 100;
    } else if (_weightKg <= 20) {
      return 1000 + ((_weightKg - 10) * 50);
    } else {
      return 1500 + ((_weightKg - 20) * 20);
    }
  }

  double get _hourlyRateMl => _dailyFluidMl / 24.0;

  // ETT Size: (Age / 4) + 4
  double get _ettUncuffed => (_ageYears / 4.0) + 4.0;
  double get _ettCuffed => (_ageYears / 4.0) + 3.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pediatric Dose & Resus',
          style: AppText.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Emergency / Resus'),
            Tab(text: 'Routine Drugs'),
            Tab(text: 'IV Fluids'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Weight Header & Broselow Estimator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: AppColors.line.withValues(alpha: 0.8))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Patient Body Weight', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${_weightKg.toStringAsFixed(1)} kg',
                                style: AppText.h1.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lavender,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Age: $_ageYears yrs', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Quick Age-Weight Preset Buttons
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildPresetChip('10 kg (1y)', 10.0, 1),
                          _buildPresetChip('15 kg (3y)', 15.0, 3),
                          _buildPresetChip('20 kg (5y)', 20.0, 5),
                          _buildPresetChip('30 kg (9y)', 30.0, 9),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _weightKg,
                    min: 3.0,
                    max: 50.0,
                    divisions: 94,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() {
                      _weightKg = (v * 10).round() / 10;
                      _ageYears = (_weightKg / 3.0).clamp(1, 14).round();
                    }),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmergencyResusTab(),
                  _buildRoutineDrugsTab(),
                  _buildIvFluidsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double wt, int age) {
    final isSelected = (_weightKg - wt).abs() < 0.2;
    return InkWell(
      onTap: () => setState(() {
        _weightKg = wt;
        _ageYears = age;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyResusTab() {
    // Exact calculations
    final epiAnaphylaxisMl = (_weightKg * 0.01).clamp(0.05, 0.5); // 1:1,000 IM (1mg/ml)
    final epiCardiacMl = (_weightKg * 0.1); // 1:10,000 IV (0.1mg/ml)
    final nsBolusMl = _weightKg * 20.0; // 20 ml/kg
    final midazolamMg = (_weightKg * 0.2).clamp(1.0, 10.0); // 0.2 mg/kg buccal
    final d10Ml = _weightKg * 5.0; // 5 ml/kg of D10W
    final shockJoules = (_weightKg * 2.0).round(); // 2 J/kg

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionHeader('Airway & Defibrillation', Icons.air_rounded, const Color(0xFFEF4444)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDoseMetricCard('ETT Size (Cuffed)', '${_ettCuffed.toStringAsFixed(1)} mm', 'Formula: (Age/4) + 3.5'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDoseMetricCard('Defib Shock (2 J/kg)', '$shockJoules Joules', 'Subsequent: ${shockJoules * 2} J'),
            ),
          ],
        ),
        const SizedBox(height: 18),

        _buildSectionHeader('Emergency Resuscitation Drugs', Icons.emergency_rounded, const Color(0xFFDC2626)),
        const SizedBox(height: 10),
        _buildDrugItem(
          drugName: 'Adrenaline (Anaphylaxis)',
          doseFormula: '0.01 mg/kg IM of 1:1,000 (1 mg/mL)',
          resultText: '${epiAnaphylaxisMl.toStringAsFixed(2)} mL IM',
          highlightColor: const Color(0xFFDC2626),
          note: 'Anterolateral mid-thigh. Repeat in 5-15 mins if needed. Max 0.5 mL.',
        ),
        _buildDrugItem(
          drugName: 'Adrenaline (Cardiac Arrest)',
          doseFormula: '0.01 mg/kg IV of 1:10,000 (0.1 mg/mL)',
          resultText: '${epiCardiacMl.toStringAsFixed(1)} mL IV/IO',
          highlightColor: const Color(0xFFDC2626),
          note: 'Repeat every 3-5 mins during CPR. Flush with 5 mL Normal Saline.',
        ),
        _buildDrugItem(
          drugName: 'Normal Saline 0.9% Bolus',
          doseFormula: '20 mL/kg rapid IV/IO push',
          resultText: '${nsBolusMl.toStringAsFixed(0)} mL push',
          highlightColor: AppColors.primary,
          note: 'Infuse over 10-20 mins for hypovolemic/septic shock. Reassess lung sounds.',
        ),
        _buildDrugItem(
          drugName: 'Midazolam (Status Epilepticus)',
          doseFormula: '0.2 mg/kg Buccal / Intranasal',
          resultText: '${midazolamMg.toStringAsFixed(1)} mg',
          highlightColor: const Color(0xFF8B5CF6),
          note: 'If seizure > 5 mins. For 5mg/ml solution: ${(midazolamMg / 5.0).toStringAsFixed(2)} mL.',
        ),
        _buildDrugItem(
          drugName: '10% Dextrose (Hypoglycemia)',
          doseFormula: '5 mL/kg IV slow push',
          resultText: '${d10Ml.toStringAsFixed(0)} mL IV',
          highlightColor: const Color(0xFFD97706),
          note: 'Bolus over 3-5 mins for Blood Glucose < 54 mg/dL. Re-check in 15 mins.',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRoutineDrugsTab() {
    final pcmMg = _weightKg * 15.0; // 15 mg/kg
    final pcm120Ml = (pcmMg / 120.0) * 5.0; // 120mg/5ml
    final pcm250Ml = (pcmMg / 250.0) * 5.0; // 250mg/5ml
    final ibupMg = _weightKg * 10.0; // 10 mg/kg
    final ibupMl = (ibupMg / 100.0) * 5.0; // 100mg/5ml
    final amoxStdMg = _weightKg * 45.0; // 45 mg/kg/day
    final amoxHighMg = _weightKg * 90.0; // 90 mg/kg/day
    final ondansetronMg = (_weightKg * 0.15).clamp(2.0, 8.0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionHeader('Antipyretics & Analgesics', Icons.thermostat_rounded, const Color(0xFFD97706)),
        const SizedBox(height: 10),
        _buildDrugItem(
          drugName: 'Paracetamol (Acetaminophen)',
          doseFormula: '15 mg/kg per dose (Max 60 mg/kg/day)',
          resultText: '${pcmMg.toStringAsFixed(0)} mg per dose',
          highlightColor: AppColors.primary,
          note: '• Syrup 120mg/5ml: ${pcm120Ml.toStringAsFixed(1)} mL\n• Syrup 250mg/5ml: ${pcm250Ml.toStringAsFixed(1)} mL\nGive every 4-6 hours as needed (Max 4 doses/24h).',
        ),
        _buildDrugItem(
          drugName: 'Ibuprofen',
          doseFormula: '10 mg/kg per dose (Child > 6 months)',
          resultText: '${ibupMg.toStringAsFixed(0)} mg (${ibupMl.toStringAsFixed(1)} mL of 100mg/5ml)',
          highlightColor: const Color(0xFFD97706),
          note: 'Give with food every 8 hours. Avoid in dehydration or chickenpox.',
        ),
        const SizedBox(height: 18),

        _buildSectionHeader('Common Pediatric Antibiotics', Icons.medication_liquid_rounded, AppColors.mint),
        const SizedBox(height: 10),
        _buildDrugItem(
          drugName: 'Amoxicillin (Standard Dose)',
          doseFormula: '45 mg/kg/day divided twice daily',
          resultText: '${(amoxStdMg / 2).toStringAsFixed(0)} mg BID',
          highlightColor: AppColors.mint,
          note: 'For 250mg/5ml syrup: ${((amoxStdMg / 2 / 250.0) * 5.0).toStringAsFixed(1)} mL every 12 hours for 5-7 days.',
        ),
        _buildDrugItem(
          drugName: 'Amoxicillin (High Dose - Otitis Media)',
          doseFormula: '90 mg/kg/day divided twice daily',
          resultText: '${(amoxHighMg / 2).toStringAsFixed(0)} mg BID',
          highlightColor: AppColors.primary,
          note: 'For 250mg/5ml syrup: ${((amoxHighMg / 2 / 250.0) * 5.0).toStringAsFixed(1)} mL every 12 hours for 7-10 days.',
        ),
        _buildDrugItem(
          drugName: 'Ondansetron (Antiemetic)',
          doseFormula: '0.15 mg/kg per dose (Max 8 mg)',
          resultText: '${ondansetronMg.toStringAsFixed(1)} mg Oral/IV',
          highlightColor: const Color(0xFF8B5CF6),
          note: 'For acute gastroenteritis vomiting prior to oral rehydration therapy.',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildIvFluidsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionHeader('Holliday-Segar Maintenance Rate', Icons.water_drop_rounded, AppColors.primary),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3478ED), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hourly Infusion Rate', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '${_hourlyRateMl.toStringAsFixed(1)} mL/hr',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('24-Hour Total', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '${_dailyFluidMl.toStringAsFixed(0)} mL/day',
                        style: const TextStyle(color: Color(0xFF36C6B0), fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Microdrip set (60 gtt/mL) = ${_hourlyRateMl.round()} drops/min',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Fluid Composition Guidelines', Icons.science_outlined, AppColors.mint),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Solutions (Isotonic Maintenance):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
              ),
              SizedBox(height: 8),
              Text(
                '• Standard: D5 0.9% Normal Saline with 20 mEq/L KCl (Prevents hospital-acquired hyponatremia).\n'
                '• Alternative: D5 0.45% NS + 20 mEq KCl in stable non-surgical children.\n'
                '• Fluid Deficit in Dehydration:\n'
                '   - Mild (5%): 50 mL/kg\n'
                '   - Moderate (10%): 100 mL/kg\n'
                '   - Add deficit to maintenance over 24-48 hours.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppText.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDoseMetricCard(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: AppText.h2.copyWith(fontSize: 17, color: AppColors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildDrugItem({
    required String drugName,
    required String doseFormula,
    required String resultText,
    required Color highlightColor,
    required String note,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(drugName, style: AppText.h3.copyWith(fontWeight: FontWeight.w800, fontSize: 14.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: highlightColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resultText,
                  style: TextStyle(color: highlightColor, fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(doseFormula, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              note,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
