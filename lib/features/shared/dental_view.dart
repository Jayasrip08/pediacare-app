import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class DentalOdontogramView extends ConsumerWidget {
  const DentalOdontogramView({super.key, required this.patientId});

  final String patientId;

  void _openToothEditor(BuildContext context, WidgetRef ref, ToothData tooth) {
    showAppSheet<void>(
      context,
      builder: (_) => _EditToothSheet(
        patientId: patientId,
        initialTooth: tooth,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teeth = ref.watch(dentalChartProvider(patientId));
    final upperTeeth = teeth.where((t) => t.arch == 'upper').toList();
    final lowerTeeth = teeth.where((t) => t.arch == 'lower').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header card with summary
        AppCard(
          color: const Color(0xFF004D40), // Dark Teal
          borderColor: const Color(0xFF004D40),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text('Adult Odontogram (Universal #1–#32)',
                      style: AppText.h2.copyWith(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap any tooth to update condition, record affected surfaces, or view treatment notes.',
                style: AppText.small.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Condition Legend
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: ToothCondition.values.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(c.label.split(' ').first, style: AppText.small),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Upper Arch (Maxilla)
        Row(
          children: [
            const Icon(Icons.north_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text('UPPER ARCH (MAXILLARY: #1 TO #16)', style: AppText.label),
          ],
        ),
        const SizedBox(height: 8),
        _ToothGrid(
          teeth: upperTeeth,
          onTapTooth: (t) => _openToothEditor(context, ref, t),
        ),
        const SizedBox(height: 22),

        // Lower Arch (Mandible)
        Row(
          children: [
            const Icon(Icons.south_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text('LOWER ARCH (MANDIBULAR: #17 TO #32)', style: AppText.label),
          ],
        ),
        const SizedBox(height: 8),
        _ToothGrid(
          teeth: lowerTeeth,
          onTapTooth: (t) => _openToothEditor(context, ref, t),
        ),
      ],
    );
  }
}

class _ToothGrid extends StatelessWidget {
  const _ToothGrid({required this.teeth, required this.onTapTooth});

  final List<ToothData> teeth;
  final ValueChanged<ToothData> onTapTooth;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.05,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: teeth.length,
      itemBuilder: (_, i) {
        final t = teeth[i];
        final isSound = t.condition == ToothCondition.sound;

        return InkWell(
          onTap: () => onTapTooth(t),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSound ? Colors.white : t.condition.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSound ? AppColors.line : t.condition.color,
                width: isSound ? 1 : 1.6,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.condition.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#${t.toothNumber}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: t.condition.color)),
                    ),
                    Icon(t.condition.icon, size: 15, color: t.condition.color),
                  ],
                ),
                const Spacer(),
                Text(
                  t.condition.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: t.condition.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (t.surfaces.isNotEmpty)
                  Text(
                    t.surfaces.map((s) => s[0]).join(''),
                    style: AppText.small.copyWith(fontSize: 9, color: AppColors.muted),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditToothSheet extends StatefulWidget {
  const _EditToothSheet({required this.patientId, required this.initialTooth});

  final String patientId;
  final ToothData initialTooth;

  @override
  State<_EditToothSheet> createState() => _EditToothSheetState();
}

class _EditToothSheetState extends State<_EditToothSheet> {
  late ToothCondition _condition;
  late List<String> _surfaces;
  late final TextEditingController _notesCtrl;

  final _allSurfaces = const ['Occlusal', 'Mesial', 'Distal', 'Buccal', 'Lingual'];

  @override
  void initState() {
    super.initState();
    _condition = widget.initialTooth.condition;
    _surfaces = List.from(widget.initialTooth.surfaces);
    _notesCtrl = TextEditingController(text: widget.initialTooth.notes ?? '');
  }

  @override
  void dispose() {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Tooth #${widget.initialTooth.toothNumber}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00796B))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.initialTooth.name,
                        style: AppText.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Condition', style: AppText.bodyBold),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ToothCondition.values.map((c) {
                  final isSel = _condition == c;
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: isSel,
                    selectedColor: c.color.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSel ? c.color : AppColors.ink,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _condition = c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('Surfaces Involved', style: AppText.bodyBold),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allSurfaces.map((s) {
                  final has = _surfaces.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: has,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _surfaces.add(s);
                        } else {
                          _surfaces.remove(s);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('Clinical Notes', style: AppText.bodyBold),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g., Deep decay, secondary margin stain...',
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Tooth Status',
                kind: AppButtonKind.accent,
                onPressed: () {
                  final updated = widget.initialTooth.copyWith(
                    condition: _condition,
                    surfaces: _surfaces,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    lastTreated: DateTime.now(),
                  );
                  ref.read(departmentRepositoryProvider).updateTooth(widget.patientId, updated);
                  ref.read(dentalChartProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getToothChart(widget.patientId);
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
// DENTAL TREATMENT PLANS VIEW
// ============================================================================

class DentalTreatmentPlansView extends ConsumerWidget {
  const DentalTreatmentPlansView({super.key, required this.patientId});

  final String patientId;

  void _addProcedureDialog(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context,
      builder: (_) => _AddProcedureSheet(patientId: patientId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(dentalPlansProvider(patientId));
    final totalCost = plans.fold<double>(0.0, (acc, p) => acc + p.estimatedCost);
    final completedCost = plans
        .where((p) => p.isCompleted)
        .fold<double>(0.0, (acc, p) => acc + p.estimatedCost);

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
                  Text('TREATMENT ESTIMATE', style: AppText.label.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('₹${numFmt(totalCost)}',
                      style: AppText.h1.copyWith(color: Colors.white, fontSize: 24)),
                  Text('${plans.where((p) => p.isCompleted).length} of ${plans.length} procedures done',
                      style: AppText.small.copyWith(color: Colors.white60)),
                ],
              ),
              AppButton(
                label: 'Add Procedure',
                icon: Icons.add_rounded,
                kind: AppButtonKind.accent,
                height: 40,
                onPressed: () => _addProcedureDialog(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader('Proposed & Active Procedures'),
        if (plans.isEmpty)
          const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No procedures planned',
            message: 'Add dental procedures, cleanings, or restorations for this patient.',
          )
        else
          ...plans.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                borderColor: p.isCompleted ? AppColors.line : const Color(0xFF009688),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: p.isCompleted,
                      activeColor: const Color(0xFF009688),
                      onChanged: (_) {
                        ref.read(departmentRepositoryProvider).toggleTreatmentPlan(patientId, p.id);
                        ref.read(dentalPlansProvider(patientId).notifier).state =
                            ref.read(departmentRepositoryProvider).getTreatmentPlans(patientId);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.procedureName,
                            style: AppText.bodyBold.copyWith(
                              decoration:
                                  p.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Teeth: ${p.teethInvolved} · ₹${numFmt(p.estimatedCost)}',
                            style: AppText.small.copyWith(color: AppColors.muted),
                          ),
                          if (p.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(p.notes!, style: AppText.small),
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

class _AddProcedureSheet extends StatefulWidget {
  const _AddProcedureSheet({required this.patientId});

  final String patientId;

  @override
  State<_AddProcedureSheet> createState() => _AddProcedureSheetState();
}

class _AddProcedureSheetState extends State<_AddProcedureSheet> {
  final _nameCtrl = TextEditingController();
  final _teethCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _presets = [
    'Composite Restoration (Filling)',
    'Root Canal Treatment (RCT)',
    'Ultrasonic Scaling & Polishing',
    'Zirconia / Ceramic Crown',
    'Tooth Extraction',
    'Dental Implant Placement',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teethCtrl.dispose();
    _costCtrl.dispose();
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
              Text('Add Dental Procedure', style: AppText.h2),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _presets.map((p) {
                  return ActionChip(
                    label: Text(p, style: AppText.small),
                    onPressed: () => setState(() => _nameCtrl.text = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Procedure Name *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _teethCtrl,
                      decoration: const InputDecoration(labelText: 'Teeth (e.g. #14, #19)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cost (₹) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Clinical Notes (optional)'),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Procedure',
                kind: AppButtonKind.accent,
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  final cost = double.tryParse(_costCtrl.text.trim()) ?? 0.0;
                  final item = DentalTreatmentItem(
                    id: 'dp-${DateTime.now().millisecondsSinceEpoch}',
                    patientId: widget.patientId,
                    procedureName: _nameCtrl.text.trim(),
                    teethInvolved: _teethCtrl.text.trim().isEmpty ? 'General' : _teethCtrl.text.trim(),
                    estimatedCost: cost,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  );
                  ref.read(departmentRepositoryProvider).addTreatmentPlan(widget.patientId, item);
                  ref.read(dentalPlansProvider(widget.patientId).notifier).state =
                      ref.read(departmentRepositoryProvider).getTreatmentPlans(widget.patientId);
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
