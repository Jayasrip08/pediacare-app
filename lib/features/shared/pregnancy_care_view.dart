import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

// ============================================================================
// PREGNANCY CARE & ANC VIEW
// ============================================================================

class PregnancyAncView extends ConsumerWidget {
  const PregnancyAncView({super.key, required this.patientId});

  final String patientId;

  void _editLmp(BuildContext context, WidgetRef ref, PregnancyRecord record) {
    showAppSheet<void>(
      context,
      builder: (_) => _EditLmpSheet(patientId: patientId, record: record),
    );
  }

  void _logAncCheckup(BuildContext context, WidgetRef ref, int currentWeeks) {
    showAppSheet<void>(
      context,
      builder: (_) => _LogAncSheet(patientId: patientId, defaultWeeks: currentWeeks),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(pregnancyRecordProvider(patientId));
    final checkups = ref.watch(ancCheckupsProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Gestational Milestone Hero Card
        AppCard(
          color: const Color(0xFF4A148C), // Deep Violet
          borderColor: const Color(0xFF4A148C),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TRIMESTER ${record.trimester}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    onPressed: () => _editLmp(context, ref, record),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text('Edit LMP'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Week ${record.gestationalWeeks}, Day ${record.gestationalDays}',
                style: AppText.h1.copyWith(color: Colors.white, fontSize: 26),
              ),
              const SizedBox(height: 4),
              Text(
                'EDD: ${fmtDate(record.edd)} · ${record.daysRemaining} days until due date',
                style: AppText.body.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.child_friendly_rounded, color: Color(0xFFCE93D8), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fetal Development',
                              style: AppText.small
                                  .copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(record.babyMilestone,
                              style: AppText.small.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ANC Visits Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader('Antenatal Care (ANC) Visits'),
            TextButton.icon(
              onPressed: () => _logAncCheckup(context, ref, record.gestationalWeeks),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Visit'),
            ),
          ],
        ),
        if (checkups.isEmpty)
          const EmptyState(
            icon: Icons.monitor_heart_outlined,
            title: 'No ANC checkups logged',
            message: 'Record blood pressure, maternal weight, fetal heart rate, and fundal height.',
          )
        else
          ...checkups.map((c) => _AncCheckupCard(checkup: c)),
      ],
    );
  }
}

class _AncCheckupCard extends StatelessWidget {
  const _AncCheckupCard({required this.checkup});

  final AncCheckup checkup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: checkup.isBpElevated ? AppColors.danger : AppColors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E44AD).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Week ${checkup.gestationalWeeks}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E44AD))),
                    ),
                    const SizedBox(width: 8),
                    Text(fmtDate(checkup.date), style: AppText.small.copyWith(color: AppColors.muted)),
                  ],
                ),
                if (checkup.isBpElevated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('High BP Warning',
                        style: AppText.small.copyWith(
                            color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Vitals Row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _VitalItem(
                  label: 'Blood Pressure',
                  value: checkup.bloodPressure,
                  icon: Icons.speed_rounded,
                  isAlert: checkup.isBpElevated,
                ),
                _VitalItem(
                  label: 'Weight',
                  value: '${numFmt(checkup.weightKg)} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
                if (checkup.fetalHeartRateBpm != null)
                  _VitalItem(
                    label: 'Fetal Heart Rate',
                    value: '${checkup.fetalHeartRateBpm} bpm',
                    icon: Icons.favorite_rounded,
                  ),
                if (checkup.fundalHeightCm != null)
                  _VitalItem(
                    label: 'Fundal Height',
                    value: '${numFmt(checkup.fundalHeightCm!)} cm',
                    icon: Icons.straighten_rounded,
                  ),
              ],
            ),
            if (checkup.doctorAdvice != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(checkup.doctorAdvice!, style: AppText.small)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  const _VitalItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isAlert ? AppColors.danger : const Color(0xFF8E44AD)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.small.copyWith(fontSize: 10, color: AppColors.muted)),
            Text(value,
                style: AppText.bodyBold.copyWith(
                    fontSize: 13, color: isAlert ? AppColors.danger : AppColors.ink)),
          ],
        ),
      ],
    );
  }
}

class _EditLmpSheet extends StatefulWidget {
  const _EditLmpSheet({required this.patientId, required this.record});

  final String patientId;
  final PregnancyRecord record;

  @override
  State<_EditLmpSheet> createState() => _EditLmpSheetState();
}

class _EditLmpSheetState extends State<_EditLmpSheet> {
  late DateTime _selectedLmp;

  @override
  void initState() {
    super.initState();
    _selectedLmp = widget.record.lmp;
  }

  @override
  Widget build(BuildContext context) {
    final edd = PregnancyRecord.computeEdd(_selectedLmp);
    final weeks = DateTime.now().difference(_selectedLmp).inDays ~/ 7;

    return Consumer(
      builder: (context, ref, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Calculate Gestational Age & EDD', style: AppText.h2),
              const SizedBox(height: 8),
              Text(
                'Uses Naegele’s Rule: EDD = LMP + 280 days (40 completed weeks).',
                style: AppText.small.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Last Menstrual Period (LMP)'),
                subtitle: Text(fmtDate(_selectedLmp), style: AppText.bodyBold),
                trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.orange),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedLmp,
                    firstDate: DateTime.now().subtract(const Duration(days: 300)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedLmp = picked);
                },
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Due Date (EDD):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fmtDate(edd),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8E44AD))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Gestation:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Week $weeks',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8E44AD))),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save & Recalculate Timeline',
                kind: AppButtonKind.accent,
                onPressed: () {
                  final updated = PregnancyRecord(
                    patientId: widget.patientId,
                    lmp: _selectedLmp,
                    edd: edd,
                  );
                  ref.read(departmentRepositoryProvider).updatePregnancyRecord(widget.patientId, updated);
                  ref.read(pregnancyRecordProvider(widget.patientId).notifier).state = updated;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogAncSheet extends StatefulWidget {
  const _LogAncSheet({required this.patientId, required this.defaultWeeks});

  final String patientId;
  final int defaultWeeks;

  @override
  State<_LogAncSheet> createState() => _LogAncSheetState();
}

class _LogAncSheetState extends State<_LogAncSheet> {
  late final TextEditingController _weeksCtrl;
  final _bpCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fhrCtrl = TextEditingController();
  final _fundalCtrl = TextEditingController();
  final _adviceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weeksCtrl = TextEditingController(text: '${widget.defaultWeeks}');
  }

  @override
  void dispose() {
    _weeksCtrl.dispose();
    _bpCtrl.dispose();
    _weightCtrl.dispose();
    _fhrCtrl.dispose();
    _fundalCtrl.dispose();
    _adviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Log ANC Checkup', style: AppText.h2),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weeksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Gestation (Weeks) *'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bpCtrl,
                      decoration: const InputDecoration(labelText: 'BP (e.g. 118/76) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weight (kg) *'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fhrCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'FHR (bpm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fundalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fundal Height (cm)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adviceCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Clinical Advice & Supplements'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save ANC Record',
                kind: AppButtonKind.accent,
                onPressed: () {
                  final weeks = int.tryParse(_weeksCtrl.text.trim()) ?? widget.defaultWeeks;
                  final wt = double.tryParse(_weightCtrl.text.trim()) ?? 60.0;
                  final fhr = int.tryParse(_fhrCtrl.text.trim());
                  final fundal = double.tryParse(_fundalCtrl.text.trim());

                  final item = AncCheckup(
                    id: 'anc-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    date: DateTime.now(),
                    gestationalWeeks: weeks,
                    bloodPressure: _bpCtrl.text.trim(),
                    weightKg: wt,
                    fetalHeartRateBpm: fhr,
                    fundalHeightCm: fundal,
                    doctorAdvice: _adviceCtrl.text.trim().isEmpty ? null : _adviceCtrl.text.trim(),
                  );

                  ref.read(departmentRepositoryProvider).addAncCheckup(widget.patientId, item);
                  ref.read(ancCheckupsProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getAncCheckups(widget.patientId);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// PRENATAL CHECKLIST VIEW
// ============================================================================

class PrenatalChecklistView extends ConsumerWidget {
  const PrenatalChecklistView({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(prenatalTestsProvider(patientId));
    final t1 = tests.where((t) => t.trimester == 1).toList();
    final t2 = tests.where((t) => t.trimester == 2).toList();
    final t3 = tests.where((t) => t.trimester == 3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AppCard(
          color: AppColors.navy,
          borderColor: AppColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRENATAL PROTOCOL', style: AppText.label.copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text('Scans, Blood Screeners & Vaccines',
                  style: AppText.h1.copyWith(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 4),
              Text('Recommended schedule aligned with FOGSI & WHO guidelines',
                  style: AppText.small.copyWith(color: Colors.white60)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _TrimesterSection(
          title: 'Trimester 1 (Weeks 1 – 13)',
          tests: t1,
          patientId: patientId,
        ),
        const SizedBox(height: 16),
        _TrimesterSection(
          title: 'Trimester 2 (Weeks 14 – 27)',
          tests: t2,
          patientId: patientId,
        ),
        const SizedBox(height: 16),
        _TrimesterSection(
          title: 'Trimester 3 (Weeks 28 – 40+)',
          tests: t3,
          patientId: patientId,
        ),
      ],
    );
  }
}

class _TrimesterSection extends ConsumerWidget {
  const _TrimesterSection({
    required this.title,
    required this.tests,
    required this.patientId,
  });

  final String title;
  final List<PrenatalTestItem> tests;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        ...tests.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: t.isDone,
                    activeColor: const Color(0xFF8E44AD),
                    onChanged: (_) {
                      ref.read(departmentRepositoryProvider).togglePrenatalTest(patientId, t.name);
                      ref.read(prenatalTestsProvider(patientId).notifier).state =
                          ref.read(departmentRepositoryProvider).getPrenatalTests(patientId);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: AppText.bodyBold.copyWith(
                            decoration:
                                t.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        Text(t.recommendedWeeks,
                            style: AppText.small.copyWith(color: AppColors.muted)),
                        if (t.resultNote != null) ...[
                          const SizedBox(height: 4),
                          Text(t.resultNote!,
                              style: AppText.small.copyWith(color: const Color(0xFF6A1B9A))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
