import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

// ============================================================================
// DERMATOLOGY BEFORE / AFTER PHOTO GALLERY
// ============================================================================

class DermatologyGalleryView extends ConsumerWidget {
  const DermatologyGalleryView({super.key, required this.patientId});

  final String patientId;

  void _addComparison(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      builder: (_) => _AddComparisonSheet(patientId: patientId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisons = ref.watch(dermaComparisonsProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Dermatology Banner
        AppCard(
          color: const Color(0xFF880E4F), // Deep Rose
          borderColor: const Color(0xFF880E4F),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clinical Photography & Progress',
                        style: AppText.h2.copyWith(color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('Side-by-side comparisons across treatment sessions',
                        style: AppText.small.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                onPressed: () => _addComparison(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader('Treatment Progress Comparisons'),
        if (comparisons.isEmpty)
          const EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No photo comparisons yet',
            message: 'Capture or upload before/after photos to track treatment results over time.',
          )
        else
          ...comparisons.map((c) => _DermaComparisonCard(item: c)),
      ],
    );
  }
}

class _DermaComparisonCard extends StatefulWidget {
  const _DermaComparisonCard({required this.item});

  final DermaComparison item;

  @override
  State<_DermaComparisonCard> createState() => _DermaComparisonCardState();
}

class _DermaComparisonCardState extends State<_DermaComparisonCard> {
  bool _showAfter = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.item;
    final diffDays = c.afterDate.difference(c.beforeDate).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: AppText.bodyBold),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(c.affectedArea, style: AppText.small.copyWith(color: AppColors.muted)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE05688).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+$diffDays days',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFAD1457)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (c.treatmentTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(c.treatmentTag!,
                        style: AppText.small.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Side by Side comparison mock visualizer
            Row(
              children: [
                // BEFORE BOX
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF48FB1)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.face_unlock_rounded, size: 40, color: Color(0xFFD81B60)),
                              const SizedBox(height: 4),
                              Text('Before Treatment',
                                  style: AppText.small.copyWith(fontWeight: FontWeight.bold)),
                              Text(fmtDate(c.beforeDate),
                                  style: AppText.small.copyWith(fontSize: 10, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('BEFORE',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // AFTER BOX
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 40, color: Color(0xFF2E7D32)),
                              const SizedBox(height: 4),
                              Text('Latest Result',
                                  style: AppText.small.copyWith(fontWeight: FontWeight.bold)),
                              Text(fmtDate(c.afterDate),
                                  style: AppText.small.copyWith(fontSize: 10, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('AFTER',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (c.conditionNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, size: 16, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.conditionNotes!, style: AppText.small),
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

class _AddComparisonSheet extends StatefulWidget {
  const _AddComparisonSheet({required this.patientId});

  final String patientId;

  @override
  State<_AddComparisonSheet> createState() => _AddComparisonSheetState();
}

class _AddComparisonSheetState extends State<_AddComparisonSheet> {
  final _titleCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _areaCtrl.dispose();
    _treatmentCtrl.dispose();
    _notesCtrl.dispose();
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
              Text('New Photo Comparison', style: AppText.h2),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Condition Title (e.g. Acne Vulgaris) *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(labelText: 'Affected Area (e.g. Face Cheeks) *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _treatmentCtrl,
                decoration: const InputDecoration(labelText: 'Treatment (e.g. Salicylic Peel)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Clinical Evaluation Notes'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Comparison Pair',
                kind: AppButtonKind.accent,
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty) return;
                  final item = DermaComparison(
                    id: 'dc-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    title: _titleCtrl.text.trim(),
                    affectedArea: _areaCtrl.text.trim().isEmpty ? 'General' : _areaCtrl.text.trim(),
                    beforeDate: DateTime.now().subtract(const Duration(days: 30)),
                    afterDate: DateTime.now(),
                    beforePhotoUrl: '',
                    afterPhotoUrl: '',
                    treatmentTag: _treatmentCtrl.text.trim().isEmpty ? null : _treatmentCtrl.text.trim(),
                    conditionNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  );
                  ref.read(departmentRepositoryProvider).addDermaComparison(widget.patientId, item);
                  ref.read(dermaComparisonsProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getDermaComparisons(widget.patientId);
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
// DERMATOLOGY SESSIONS TRACKING VIEW
// ============================================================================

class DermatologySessionsView extends ConsumerWidget {
  const DermatologySessionsView({super.key, required this.patientId});

  final String patientId;

  void _logSession(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      builder: (_) => _LogSessionSheet(patientId: patientId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(dermaSessionsProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Summary Card
        AppCard(
          color: AppColors.navy,
          borderColor: AppColors.navy,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TREATMENT SESSIONS', style: AppText.label.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('${sessions.length} Logged',
                      style: AppText.h1.copyWith(color: Colors.white, fontSize: 24)),
                  Text('Packages, laser & peel intervals',
                      style: AppText.small.copyWith(color: Colors.white60)),
                ],
              ),
              AppButton(
                label: 'Log Session',
                icon: Icons.add_rounded,
                kind: AppButtonKind.accent,
                height: 40,
                onPressed: () => _logSession(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader('Session History & Milestones'),
        if (sessions.isEmpty)
          const EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No sessions logged',
            message: 'Record treatment sessions, laser energy parameters, and skin reactions.',
          )
        else
          ...sessions.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(s.treatmentName, style: AppText.bodyBold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05688).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.sessionLabel,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFAD1457)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.progressFraction,
                        minHeight: 6,
                        backgroundColor: AppColors.line,
                        color: const Color(0xFFE05688),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(fmtDate(s.sessionDate), style: AppText.small),
                        if (s.nextSessionDate != null) ...[
                          const SizedBox(width: 14),
                          const Icon(Icons.next_plan_outlined, size: 14, color: Color(0xFFE05688)),
                          const SizedBox(width: 4),
                          Text('Next: ${fmtDate(s.nextSessionDate!)}',
                              style: AppText.small.copyWith(
                                  fontWeight: FontWeight.w600, color: const Color(0xFFAD1457))),
                        ],
                      ],
                    ),
                    if (s.energyParameters != null) ...[
                      const SizedBox(height: 6),
                      Text('Settings: ${s.energyParameters}',
                          style: AppText.small.copyWith(color: AppColors.muted)),
                    ],
                    if (s.clinicalReaction != null) ...[
                      const SizedBox(height: 4),
                      Text('Reaction: ${s.clinicalReaction}', style: AppText.small),
                    ],
                    if (s.notes != null) ...[
                      const SizedBox(height: 6),
                      Text(s.notes!, style: AppText.small.copyWith(color: AppColors.ink)),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _LogSessionSheet extends StatefulWidget {
  const _LogSessionSheet({required this.patientId});

  final String patientId;

  @override
  State<_LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends State<_LogSessionSheet> {
  final _treatmentCtrl = TextEditingController();
  final _sessionNumCtrl = TextEditingController();
  final _totalSessionsCtrl = TextEditingController();
  final _energyCtrl = TextEditingController();
  final _reactionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _treatmentCtrl.dispose();
    _sessionNumCtrl.dispose();
    _totalSessionsCtrl.dispose();
    _energyCtrl.dispose();
    _reactionCtrl.dispose();
    _notesCtrl.dispose();
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
              Text('Log Treatment Session', style: AppText.h2),
              const SizedBox(height: 14),
              TextFormField(
                controller: _treatmentCtrl,
                decoration: const InputDecoration(labelText: 'Treatment / Procedure *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sessionNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Session #'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalSessionsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total in Package'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _energyCtrl,
                decoration:
                    const InputDecoration(labelText: 'Energy / Parameters (e.g. Fluence, Needle depth)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reactionCtrl,
                decoration: const InputDecoration(labelText: 'Immediate Reaction (e.g. Mild erythema)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Post-procedure instructions / Notes'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Session Log',
                kind: AppButtonKind.accent,
                onPressed: () {
                  if (_treatmentCtrl.text.trim().isEmpty) return;
                  final sNum = int.tryParse(_sessionNumCtrl.text.trim()) ?? 1;
                  final tot = int.tryParse(_totalSessionsCtrl.text.trim()) ?? 6;
                  final item = DermaSessionLog(
                    id: 'ds-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    treatmentName: _treatmentCtrl.text.trim(),
                    sessionNumber: sNum,
                    totalSessions: tot,
                    sessionDate: DateTime.now(),
                    energyParameters: _energyCtrl.text.trim().isEmpty ? null : _energyCtrl.text.trim(),
                    clinicalReaction: _reactionCtrl.text.trim().isEmpty ? null : _reactionCtrl.text.trim(),
                    nextSessionDate: DateTime.now().add(const Duration(days: 14)),
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  );
                  ref.read(departmentRepositoryProvider).addDermaSession(widget.patientId, item);
                  ref.read(dermaSessionsProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getDermaSessions(widget.patientId);
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
