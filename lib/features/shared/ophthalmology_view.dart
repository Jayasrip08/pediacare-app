import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

// ============================================================================
// OPHTHALMOLOGY REFRACTION PRESCRIPTION VIEW
// ============================================================================

class OphthalmologyRefractionView extends ConsumerWidget {
  const OphthalmologyRefractionView({super.key, required this.patientId});

  final String patientId;

  void _editRefraction(BuildContext context, WidgetRef ref, RefractionPrescription rx) {
    showAppSheet<void>(
      context,
      builder: (_) => _EditRefractionSheet(patientId: patientId, currentRx: rx),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rx = ref.watch(refractionProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Prescription Pad Card
        AppCard(
          color: const Color(0xFF0D47A1), // Deep Blue
          borderColor: const Color(0xFF0D47A1),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text('Spectacle Prescription',
                          style: AppText.h2.copyWith(color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                    onPressed: () => _editRefraction(context, ref, rx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Prescribed on ${fmtDate(rx.date)} · P.D. ${numFmt(rx.pupillaryDistanceMm)} mm',
                style: AppText.small.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),

              // Refraction Grid Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const SizedBox(
                            width: 50,
                            child: Text('EYE',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.muted))),
                        Expanded(
                            child: Text('SPH',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.muted))),
                        Expanded(
                            child: Text('CYL',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.muted))),
                        Expanded(
                            child: Text('AXIS',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.muted))),
                        Expanded(
                            child: Text('ADD',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.muted))),
                        Expanded(
                            child: Text('VA',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.muted))),
                      ],
                    ),
                    const Divider(height: 16),
                    // Right Eye OD
                    _EyeRow(label: 'OD (R)', reading: rx.od),
                    const SizedBox(height: 8),
                    // Left Eye OS
                    _EyeRow(label: 'OS (L)', reading: rx.os),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Recommended Lens Type:',
                  style: AppText.small.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(rx.lensTypeAdvice,
                  style: AppText.bodyBold.copyWith(color: Colors.white, fontSize: 13)),
              if (rx.notes != null) ...[
                const SizedBox(height: 6),
                Text('Instructions: ${rx.notes}',
                    style: AppText.small.copyWith(color: Colors.white60)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('Visual Acuity Quick Reference'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _VaSummaryBox(label: 'Right Eye (OD)', va: rx.od.visualAcuity, isNormal: rx.od.visualAcuity == '6/6'),
                  Container(width: 1, height: 40, color: AppColors.line),
                  _VaSummaryBox(label: 'Left Eye (OS)', va: rx.os.visualAcuity, isNormal: rx.os.visualAcuity == '6/6'),
                ],
              ),
              const Divider(height: 24),
              Text(
                '• 6/6 (or 20/20) represents standard clear visual acuity at 6 meters.\n'
                '• Axis is recorded from 0° to 180° for astigmatism correction.\n'
                '• ADD power is for presbyopia (reading / intermediate distance).',
                style: AppText.small.copyWith(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.reading});

  final String label;
  final RefractionReading reading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D47A1))),
        ),
        Expanded(
          child: Text(
            '${reading.sphere >= 0 ? '+' : ''}${reading.sphere.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            '${reading.cylinder >= 0 ? '+' : ''}${reading.cylinder.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            '${reading.axis}°',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            reading.nearAdd != null ? '+${reading.nearAdd!.toStringAsFixed(2)}' : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reading.visualAcuity,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1976D2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _VaSummaryBox extends StatelessWidget {
  const _VaSummaryBox({required this.label, required this.va, required this.isNormal});

  final String label;
  final String va;
  final bool isNormal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppText.small.copyWith(color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(va,
            style: AppText.h1.copyWith(
                fontSize: 22, color: isNormal ? const Color(0xFF2E7D32) : const Color(0xFFF7861E))),
        Text(isNormal ? 'Normal Acuity' : 'Corrected',
            style: AppText.small.copyWith(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}

class _EditRefractionSheet extends StatefulWidget {
  const _EditRefractionSheet({required this.patientId, required this.currentRx});

  final String patientId;
  final RefractionPrescription currentRx;

  @override
  State<_EditRefractionSheet> createState() => _EditRefractionSheetState();
}

class _EditRefractionSheetState extends State<_EditRefractionSheet> {
  late final TextEditingController _odSph;
  late final TextEditingController _odCyl;
  late final TextEditingController _odAxis;
  late final TextEditingController _odAdd;
  late final TextEditingController _odVa;

  late final TextEditingController _osSph;
  late final TextEditingController _osCyl;
  late final TextEditingController _osAxis;
  late final TextEditingController _osAdd;
  late final TextEditingController _osVa;

  late final TextEditingController _pdCtrl;
  late final TextEditingController _lensTypeCtrl;

  @override
  void initState() {
    super.initState();
    final od = widget.currentRx.od;
    final os = widget.currentRx.os;

    _odSph = TextEditingController(text: od.sphere.toStringAsFixed(2));
    _odCyl = TextEditingController(text: od.cylinder.toStringAsFixed(2));
    _odAxis = TextEditingController(text: '${od.axis}');
    _odAdd = TextEditingController(text: od.nearAdd != null ? od.nearAdd!.toStringAsFixed(2) : '');
    _odVa = TextEditingController(text: od.visualAcuity);

    _osSph = TextEditingController(text: os.sphere.toStringAsFixed(2));
    _osCyl = TextEditingController(text: os.cylinder.toStringAsFixed(2));
    _osAxis = TextEditingController(text: '${os.axis}');
    _osAdd = TextEditingController(text: os.nearAdd != null ? os.nearAdd!.toStringAsFixed(2) : '');
    _osVa = TextEditingController(text: os.visualAcuity);

    _pdCtrl = TextEditingController(text: widget.currentRx.pupillaryDistanceMm.toStringAsFixed(0));
    _lensTypeCtrl = TextEditingController(text: widget.currentRx.lensTypeAdvice);
  }

  @override
  void dispose() {
    _odSph.dispose();
    _odCyl.dispose();
    _odAxis.dispose();
    _odAdd.dispose();
    _odVa.dispose();
    _osSph.dispose();
    _osCyl.dispose();
    _osAxis.dispose();
    _osAdd.dispose();
    _osVa.dispose();
    _pdCtrl.dispose();
    _lensTypeCtrl.dispose();
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
              Text('Update Refraction Prescription', style: AppText.h2),
              const SizedBox(height: 16),
              Text('Right Eye (OD)', style: AppText.bodyBold.copyWith(color: const Color(0xFF0D47A1))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _odSph, decoration: const InputDecoration(labelText: 'SPH'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _odCyl, decoration: const InputDecoration(labelText: 'CYL'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _odAxis, decoration: const InputDecoration(labelText: 'AXIS'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _odVa, decoration: const InputDecoration(labelText: 'VA'))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Left Eye (OS)', style: AppText.bodyBold.copyWith(color: const Color(0xFF0D47A1))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _osSph, decoration: const InputDecoration(labelText: 'SPH'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _osCyl, decoration: const InputDecoration(labelText: 'CYL'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _osAxis, decoration: const InputDecoration(labelText: 'AXIS'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _osVa, decoration: const InputDecoration(labelText: 'VA'))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _pdCtrl, decoration: const InputDecoration(labelText: 'P.D. (mm)'))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                        controller: _lensTypeCtrl, decoration: const InputDecoration(labelText: 'Lens Coating / Type')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Refraction',
                kind: AppButtonKind.accent,
                onPressed: () {
                  final od = RefractionReading(
                    sphere: double.tryParse(_odSph.text) ?? 0.0,
                    cylinder: double.tryParse(_odCyl.text) ?? 0.0,
                    axis: int.tryParse(_odAxis.text) ?? 0,
                    nearAdd: double.tryParse(_odAdd.text),
                    visualAcuity: _odVa.text.trim().isEmpty ? '6/6' : _odVa.text.trim(),
                  );
                  final os = RefractionReading(
                    sphere: double.tryParse(_osSph.text) ?? 0.0,
                    cylinder: double.tryParse(_osCyl.text) ?? 0.0,
                    axis: int.tryParse(_osAxis.text) ?? 0,
                    nearAdd: double.tryParse(_osAdd.text),
                    visualAcuity: _osVa.text.trim().isEmpty ? '6/6' : _osVa.text.trim(),
                  );
                  final pd = double.tryParse(_pdCtrl.text) ?? 62.0;

                  final rx = RefractionPrescription(
                    id: 'ref-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    date: DateTime.now(),
                    od: od,
                    os: os,
                    pupillaryDistanceMm: pd,
                    lensTypeAdvice: _lensTypeCtrl.text.trim().isEmpty
                        ? 'Standard Single Vision'
                        : _lensTypeCtrl.text.trim(),
                  );

                  ref.read(departmentRepositoryProvider).saveRefraction(widget.patientId, rx);
                  ref.read(refractionProvider(widget.patientId).notifier).state = rx;
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
// OPHTHALMOLOGY EXAMS & IOP VIEW
// ============================================================================

class OphthalmologyExamsView extends ConsumerWidget {
  const OphthalmologyExamsView({super.key, required this.patientId});

  final String patientId;

  void _logExam(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      builder: (_) => _LogEyeExamSheet(patientId: patientId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(eyeExamsProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header
        AppCard(
          color: AppColors.navy,
          borderColor: AppColors.navy,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EYE EXAMINATIONS', style: AppText.label.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('IOP & Slit Lamp',
                      style: AppText.h1.copyWith(color: Colors.white, fontSize: 22)),
                  Text('Tonometry & anterior/posterior segment',
                      style: AppText.small.copyWith(color: Colors.white60)),
                ],
              ),
              AppButton(
                label: 'Log Exam',
                icon: Icons.add_rounded,
                kind: AppButtonKind.accent,
                height: 40,
                onPressed: () => _logExam(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader('Exam History'),
        if (exams.isEmpty)
          const EmptyState(
            icon: Icons.remove_red_eye_outlined,
            title: 'No exams logged',
            message: 'Record tonometry IOP readings, slit lamp observations, and prescribed eye drops.',
          )
        else
          ...exams.map((e) => _EyeExamCard(exam: e)),
      ],
    );
  }
}

class _EyeExamCard extends StatelessWidget {
  const _EyeExamCard({required this.exam});

  final EyeExamRecord exam;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: exam.isIopHigh ? AppColors.danger : AppColors.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmtDate(exam.date), style: AppText.small.copyWith(color: AppColors.muted)),
                if (exam.isIopHigh)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Elevated IOP (>21 mmHg)',
                        style: AppText.small.copyWith(
                            color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // IOP readings
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B84D8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('OD IOP: ${exam.iopOD} mmHg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B84D8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('OS IOP: ${exam.iopOS} mmHg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            if (exam.diagnosis != null) ...[
              const SizedBox(height: 10),
              Text('Diagnosis: ${exam.diagnosis!}', style: AppText.bodyBold),
            ],
            if (exam.slitLampFindings != null) ...[
              const SizedBox(height: 6),
              Text('Slit Lamp: ${exam.slitLampFindings!}', style: AppText.small),
            ],
            if (exam.fundusFindings != null) ...[
              const SizedBox(height: 4),
              Text('Fundus: ${exam.fundusFindings!}',
                  style: AppText.small.copyWith(color: AppColors.muted)),
            ],
            if (exam.eyeDropMedications != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, size: 16, color: Color(0xFF1B84D8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Drops: ${exam.eyeDropMedications!}',
                          style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                    ),
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

class _LogEyeExamSheet extends StatefulWidget {
  const _LogEyeExamSheet({required this.patientId});

  final String patientId;

  @override
  State<_LogEyeExamSheet> createState() => _LogEyeExamSheetState();
}

class _LogEyeExamSheetState extends State<_LogEyeExamSheet> {
  final _iopOD = TextEditingController();
  final _iopOS = TextEditingController();
  final _diagCtrl = TextEditingController();
  final _slitCtrl = TextEditingController();
  final _fundusCtrl = TextEditingController();
  final _dropsCtrl = TextEditingController();

  @override
  void dispose() {
    _iopOD.dispose();
    _iopOS.dispose();
    _diagCtrl.dispose();
    _slitCtrl.dispose();
    _fundusCtrl.dispose();
    _dropsCtrl.dispose();
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
              Text('Log Eye Examination & Tonometry', style: AppText.h2),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _iopOD,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'OD IOP (mmHg) *'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _iopOS,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'OS IOP (mmHg) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagCtrl,
                decoration: const InputDecoration(labelText: 'Clinical Diagnosis'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slitCtrl,
                decoration: const InputDecoration(labelText: 'Slit Lamp Examination'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fundusCtrl,
                decoration: const InputDecoration(labelText: 'Fundus / Retinal Findings'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dropsCtrl,
                decoration: const InputDecoration(labelText: 'Eye Drops / Medications'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Examination',
                kind: AppButtonKind.accent,
                onPressed: () {
                  final od = double.tryParse(_iopOD.text) ?? 15.0;
                  final os = double.tryParse(_iopOS.text) ?? 15.0;

                  final item = EyeExamRecord(
                    id: 'exam-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    date: DateTime.now(),
                    iopOD: od,
                    iopOS: os,
                    diagnosis: _diagCtrl.text.trim().isEmpty ? null : _diagCtrl.text.trim(),
                    slitLampFindings: _slitCtrl.text.trim().isEmpty ? null : _slitCtrl.text.trim(),
                    fundusFindings: _fundusCtrl.text.trim().isEmpty ? null : _fundusCtrl.text.trim(),
                    eyeDropMedications: _dropsCtrl.text.trim().isEmpty ? null : _dropsCtrl.text.trim(),
                  );

                  ref.read(departmentRepositoryProvider).addEyeExam(widget.patientId, item);
                  ref.read(eyeExamsProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getEyeExams(widget.patientId);
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
