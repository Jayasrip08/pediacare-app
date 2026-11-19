import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

// ============================================================================
// PSYCHIATRY & COUNSELLING SCREENERS VIEW (PHQ-9 & GAD-7)
// ============================================================================

class PsychiatryScreenersView extends ConsumerWidget {
  const PsychiatryScreenersView({super.key, required this.patientId});

  final String patientId;

  void _openScreenerTest(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      builder: (_) => _ScreenerAssessmentSheet(patientId: patientId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screeners = ref.watch(screenerHistoryProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Screener Hero Card
        AppCard(
          color: const Color(0xFF1B5E20), // Forest Green
          borderColor: const Color(0xFF1B5E20),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clinical Mental Health Screeners',
                        style: AppText.h2.copyWith(color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('Standardized PHQ-9 (Depression) & GAD-7 (Anxiety)',
                        style: AppText.small.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              AppButton(
                label: 'New Screener',
                icon: Icons.assignment_turned_in_rounded,
                kind: AppButtonKind.accent,
                height: 40,
                onPressed: () => _openScreenerTest(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader('Assessment Score History'),
        if (screeners.isEmpty)
          const EmptyState(
            icon: Icons.checklist_rtl_rounded,
            title: 'No screeners completed',
            message: 'Administer PHQ-9 or GAD-7 assessment to gauge symptom severity over time.',
          )
        else
          ...screeners.map((s) => _ScreenerCard(screener: s)),
      ],
    );
  }
}

class _ScreenerCard extends StatelessWidget {
  const _ScreenerCard({required this.screener});

  final ScreenerResult screener;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
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
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        screener.type.name.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(screener.type.label, style: AppText.bodyBold),
                  ],
                ),
                Text(fmtDate(screener.date), style: AppText.small.copyWith(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: screener.severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: screener.severityColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Score: ${screener.totalScore}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: screener.severityColor)),
                      const SizedBox(width: 8),
                      Text('·  ${screener.severityBand}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: screener.severityColor)),
                    ],
                  ),
                ),
              ],
            ),
            if (screener.clinicalSummary != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(screener.clinicalSummary!, style: AppText.small),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScreenerAssessmentSheet extends StatefulWidget {
  const _ScreenerAssessmentSheet({required this.patientId});

  final String patientId;

  @override
  State<_ScreenerAssessmentSheet> createState() => _ScreenerAssessmentSheetState();
}

class _ScreenerAssessmentSheetState extends State<_ScreenerAssessmentSheet> {
  ScreenerType _type = ScreenerType.phq9;
  late List<int> _answers;
  final _summaryCtrl = TextEditingController();

  final _options = const [
    'Not at all (0)',
    'Several days (1)',
    'More than half the days (2)',
    'Nearly every day (3)',
  ];

  @override
  void initState() {
    super.initState();
    _answers = List.filled(_type.questions.length, 0);
  }

  void _switchType(ScreenerType t) {
    setState(() {
      _type = t;
      _answers = List.filled(t.questions.length, 0);
    });
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _answers.fold<int>(0, (a, b) => a + b);
    final severity = ScreenerResult.computeSeverity(_type, total);

    return Consumer(
      builder: (context, ref, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conduct Screener Assessment', style: AppText.h2),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('PHQ-9 (Depression)'),
                    selected: _type == ScreenerType.phq9,
                    onSelected: (_) => _switchType(ScreenerType.phq9),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('GAD-7 (Anxiety)'),
                    selected: _type == ScreenerType.gad7,
                    onSelected: (_) => _switchType(ScreenerType.gad7),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Score: $total',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(severity,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Over the last 2 weeks, how often have you been bothered by any of the following?',
                style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              ...List.generate(_type.questions.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${_type.questions[i]}', style: AppText.bodyBold),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: List.generate(4, (optIdx) {
                            final isSel = _answers[i] == optIdx;
                            return ChoiceChip(
                              label: Text('$optIdx', style: const TextStyle(fontSize: 11)),
                              selected: isSel,
                              onSelected: (_) => setState(() => _answers[i] = optIdx),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Clinician Notes & Observations'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Screener Result ($total - $severity)',
                kind: AppButtonKind.accent,
                onPressed: () {
                  ref.read(departmentRepositoryProvider).submitScreener(
                        widget.patientId,
                        _type,
                        _answers,
                        clinicalSummary:
                            _summaryCtrl.text.trim().isEmpty ? null : _summaryCtrl.text.trim(),
                      );
                  ref.read(screenerHistoryProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getScreenerHistory(widget.patientId);
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
// PSYCHIATRY SOAP THERAPY NOTES & COPING GOALS
// ============================================================================

class PsychiatryNotesView extends ConsumerWidget {
  const PsychiatryNotesView({super.key, required this.patientId});

  final String patientId;

  void _addNote(BuildContext context, WidgetRef ref, int nextSession) {
    showAppSheet<void>(
      context,
      builder: (_) => _AddTherapyNoteSheet(patientId: patientId, sessionNumber: nextSession),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(therapyNotesProvider(patientId));
    final goals = ref.watch(copingGoalsProvider(patientId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Coping Goals Section
        AppCard(
          color: AppColors.navy,
          borderColor: AppColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COPING GOALS & HOMEWORK',
                      style: AppText.label.copyWith(color: Colors.white70)),
                  Text('${goals.where((g) => g.isCompleted).length} / ${goals.length} Done',
                      style: AppText.small.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 10),
              ...goals.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: g.isCompleted,
                        activeColor: const Color(0xFF2E7D32),
                        checkColor: Colors.white,
                        onChanged: (_) {
                          ref.read(departmentRepositoryProvider).toggleCopingGoal(patientId, g.id);
                          ref.read(copingGoalsProvider(patientId).notifier).state =
                              ref.read(departmentRepositoryProvider).getCopingGoals(patientId);
                        },
                      ),
                      Expanded(
                        child: Text(
                          g.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            decoration:
                                g.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader('SOAP Progress Notes'),
            TextButton.icon(
              onPressed: () => _addNote(context, ref, notes.length + 1),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Note'),
            ),
          ],
        ),
        if (notes.isEmpty)
          const EmptyState(
            icon: Icons.note_alt_outlined,
            title: 'No session notes yet',
            message: 'Document confidential psychotherapy sessions with standard SOAP format.',
          )
        else
          ...notes.map((n) => _SoapNoteCard(note: n)),
      ],
    );
  }
}

class _SoapNoteCard extends StatelessWidget {
  const _SoapNoteCard({required this.note});

  final TherapyNote note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
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
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Session #${note.sessionNumber}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ),
                    const SizedBox(width: 8),
                    Text(note.modality, style: AppText.small.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(fmtDate(note.date), style: AppText.small.copyWith(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 12),
            _SoapSection(letter: 'S', title: 'Subjective', text: note.subjective),
            const SizedBox(height: 8),
            _SoapSection(letter: 'O', title: 'Objective', text: note.objective),
            const SizedBox(height: 8),
            _SoapSection(letter: 'A', title: 'Assessment', text: note.assessment),
            const SizedBox(height: 8),
            _SoapSection(letter: 'P', title: 'Plan', text: note.plan),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.security_rounded, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text('Risk Level: ${note.riskLevel}',
                    style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoapSection extends StatelessWidget {
  const _SoapSection({required this.letter, required this.title, required this.text});

  final String letter;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(letter,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppText.small.copyWith(color: AppColors.ink),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTherapyNoteSheet extends StatefulWidget {
  const _AddTherapyNoteSheet({required this.patientId, required this.sessionNumber});

  final String patientId;
  final int sessionNumber;

  @override
  State<_AddTherapyNoteSheet> createState() => _AddTherapyNoteSheetState();
}

class _AddTherapyNoteSheetState extends State<_AddTherapyNoteSheet> {
  final _modalityCtrl = TextEditingController(text: 'Cognitive Behavioral Therapy (CBT)');
  final _sCtrl = TextEditingController();
  final _oCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  String _risk = 'Low';

  @override
  void dispose() {
    _modalityCtrl.dispose();
    _sCtrl.dispose();
    _oCtrl.dispose();
    _aCtrl.dispose();
    _pCtrl.dispose();
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
              Text('SOAP Therapy Note (Session #${widget.sessionNumber})', style: AppText.h2),
              const SizedBox(height: 14),
              TextFormField(
                controller: _modalityCtrl,
                decoration: const InputDecoration(labelText: 'Therapy Modality *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'S - Subjective (Client statements & mood) *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _oCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'O - Objective (Clinical observations & affect) *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'A - Assessment (Progress, insight, response) *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'P - Plan (Interventions & homework) *'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Risk Assessment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  ...['Low', 'Moderate', 'High'].map((r) {
                    final isSel = _risk == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(r),
                        selected: isSel,
                        onSelected: (_) => setState(() => _risk = r),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Therapy Note',
                kind: AppButtonKind.accent,
                onPressed: () {
                  if (_sCtrl.text.trim().isEmpty) return;
                  final note = TherapyNote(
                    id: 'tn-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    date: DateTime.now(),
                    sessionNumber: widget.sessionNumber,
                    modality: _modalityCtrl.text.trim(),
                    subjective: _sCtrl.text.trim(),
                    objective: _oCtrl.text.trim(),
                    assessment: _aCtrl.text.trim(),
                    plan: _pCtrl.text.trim(),
                    riskLevel: _risk,
                  );
                  ref.read(departmentRepositoryProvider).addTherapyNote(widget.patientId, note);
                  ref.read(therapyNotesProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getTherapyNotes(widget.patientId);
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
