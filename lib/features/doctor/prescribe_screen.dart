import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'dose_calculator.dart';

class PrescribeScreen extends ConsumerStatefulWidget {
  const PrescribeScreen({super.key, required this.childId, this.appointmentId});

  final String childId;
  final String? appointmentId;

  @override
  ConsumerState<PrescribeScreen> createState() => _PrescribeScreenState();
}

class _PrescribeScreenState extends ConsumerState<PrescribeScreen> {
  final _weight = TextEditingController();
  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  final _items = <RxItem>[];
  DateTime? _followUp;
  bool _confirmed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillWeight();
  }

  @override
  void dispose() {
    _weight.dispose();
    _diagnosis.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _prefillWeight() async {
    try {
      final growth = await ref.read(growthProvider(widget.childId).future);
      final latest = growth.reversed.where((g) => g.weightKg != null).firstOrNull;
      if (latest != null && mounted && _weight.text.isEmpty) {
        setState(() => _weight.text = numFmt(latest.weightKg!));
      }
    } catch (_) {
      // Weight can be typed manually.
    }
  }

  double? get _weightKg => double.tryParse(_weight.text.trim().replaceAll(',', '.'));

  Future<void> _addMedicine(Child child) async {
    final w = _weightKg;
    if (w == null || w <= 0) {
      showToast(context, 'Enter the child’s weight first', error: true);
      return;
    }
    final formulary = await ref.read(formularyProvider.future);
    if (!mounted) return;
    final item = await showAppSheet<RxItem>(
      context,
      builder: (_) => _MedicineSheet(formulary: formulary, weightKg: w, ageMonths: child.ageMonths),
    );
    if (item != null) {
      setState(() {
        _items.add(item);
        _confirmed = false;
      });
    }
  }

  Future<void> _feverTemplate(Child child) async {
    final w = _weightKg;
    if (w == null || w <= 0) {
      showToast(context, 'Enter the child’s weight first', error: true);
      return;
    }
    final formulary = await ref.read(formularyProvider.future);
    final para = formulary.where((d) => d.name.toLowerCase().startsWith('paracetamol')).firstOrNull;
    if (para == null) {
      if (mounted) showToast(context, 'Paracetamol is not in the formulary', error: true);
      return;
    }
    final s = DoseCalculator.suggest(para, weightKg: w, ageMonths: child.ageMonths);
    setState(() {
      _items.add(RxItem(
        name: '${para.name} ${para.form}',
        doseMg: s.mgPerDose,
        doseMl: s.mlPerDose,
        timesPerDay: s.timesPerDay,
        durationDays: para.defaultDurationDays,
        instructions: para.instructions,
      ));
      if (_diagnosis.text.isEmpty) _diagnosis.text = 'Fever';
      _followUp ??= DateTime.now().add(const Duration(days: 3));
      _confirmed = false;
    });
  }

  Future<void> _send(Child child, Clinic clinic) async {
    final w = _weightKg;
    if (w == null || w <= 0) {
      showToast(context, 'Enter the child’s weight', error: true);
      return;
    }
    if (_items.isEmpty) {
      showToast(context, 'Add at least one medicine', error: true);
      return;
    }
    if (!_confirmed) {
      showToast(context, 'Please confirm the doses before sending', error: true);
      return;
    }
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(prescriptionRepositoryProvider).create(
            clinicId: clinic.id,
            childId: child.id,
            doctorId: uid,
            appointmentId: widget.appointmentId,
            weightKg: w,
            diagnosis: _diagnosis.text,
            items: _items,
            notes: _notes.text,
            followUpDate: _followUp,
          );
      ref.invalidate(prescriptionsProvider(child.id));
      ref.invalidate(timelineProvider(child.id));
      ref.invalidate(todaysQueueProvider);
      ref.invalidate(doctorStatsProvider);
      ref.invalidate(missedFollowupsProvider);
      ref.invalidate(patientsProvider);
      if (mounted) {
        showToast(context, 'Prescription sent to parent app');
        context.pushReplacement('/prescription/$id');
      }
    } catch (e) {
      if (mounted) {
        showToast(context, errorMessage(e), error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childAsync = ref.watch(childByIdProvider(widget.childId));
    final clinic = ref.watch(myClinicProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('New prescription')),
      body: AsyncValueView<Child>(
        value: childAsync,
        onRetry: () => ref.invalidate(childByIdProvider(widget.childId)),
        data: (child) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            AppCard(
              child: Row(
                children: [
                  InitialAvatar(name: child.name),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.name, style: AppText.h3),
                        Text('${child.age} · ${child.gender}', style: AppText.small),
                      ],
                    ),
                  ),
                  if (child.allergies != null)
                    StatusPill('Allergy', tone: Tone.danger, icon: Icons.warning_amber_rounded),
                ],
              ),
            ),
            if (child.allergies != null) ...[
              const SizedBox(height: 8),
              Text('Allergies: ${child.allergies}',
                  style: AppText.small.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Weight today',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _diagnosis,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Diagnosis / complaint',
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
            ),
            const SectionHeader('Medicines'),
            if (_items.isEmpty)
              AppCard(
                shadow: false,
                child: Text('No medicines added yet.', style: AppText.muted),
              ),
            for (var i = 0; i < _items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBadge(icon: Icons.medication_liquid_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_items[i].name, style: AppText.h3),
                            Text(_items[i].doseLabel,
                                style: AppText.bodyBold.copyWith(color: AppColors.orange)),
                            Text(_items[i].scheduleLabel, style: AppText.muted),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                        onPressed: () => setState(() {
                          _items.removeAt(i);
                          _confirmed = false;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add medicine',
                    icon: Icons.add_rounded,
                    kind: AppButtonKind.outline,
                    height: 48,
                    onPressed: () => _addMedicine(child),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Template: Fever',
                    icon: Icons.bolt_rounded,
                    kind: AppButtonKind.outline,
                    height: 48,
                    onPressed: () => _feverTemplate(child),
                  ),
                ),
              ],
            ),
            const SectionHeader('Follow-up'),
            ChoiceGroup<int>(
              options: const [3, 5, 7, 14],
              selected: _followUp == null
                  ? null
                  : dateOnly(_followUp!).difference(dateOnly(DateTime.now())).inDays,
              onChanged: (d) =>
                  setState(() => _followUp = DateTime.now().add(Duration(days: d))),
              labelOf: (d) => 'In $d days',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final d = await pickDate(context,
                        initial: _followUp ?? DateTime.now().add(const Duration(days: 3)),
                        first: DateTime.now(),
                        last: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setState(() => _followUp = d);
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text(_followUp == null ? 'Pick date' : fmtDate(_followUp!)),
                ),
                if (_followUp != null)
                  TextButton(
                      onPressed: () => setState(() => _followUp = null),
                      child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Advice for parents (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              color: AppColors.orangeSoft,
              borderColor: AppColors.orangeSoft,
              shadow: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                activeColor: AppColors.navy,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I have reviewed the weight and every dose, and I confirm this prescription.',
                  style: AppText.small.copyWith(color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Send to parent app',
              icon: Icons.send_rounded,
              kind: AppButtonKind.accent,
              loading: _saving,
              onPressed: clinic == null ? null : () => _send(child, clinic),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-medicine sheet with live dose calculation
// ---------------------------------------------------------------------------
class _MedicineSheet extends StatefulWidget {
  const _MedicineSheet({required this.formulary, required this.weightKg, required this.ageMonths});

  final List<DrugFormulary> formulary;
  final double weightKg;
  final int ageMonths;

  @override
  State<_MedicineSheet> createState() => _MedicineSheetState();
}

class _MedicineSheetState extends State<_MedicineSheet> {
  DrugFormulary? _drug;
  bool _custom = false;

  final _ml = TextEditingController();
  final _instructions = TextEditingController();
  final _customName = TextEditingController();
  final _customDose = TextEditingController();
  int _times = 3;
  int _days = 3;

  @override
  void dispose() {
    _ml.dispose();
    _instructions.dispose();
    _customName.dispose();
    _customDose.dispose();
    super.dispose();
  }

  void _select(DrugFormulary d) {
    final s = DoseCalculator.suggest(d, weightKg: widget.weightKg, ageMonths: widget.ageMonths);
    setState(() {
      _drug = d;
      _custom = false;
      _ml.text = numFmt(s.mlPerDose);
      _times = s.timesPerDay;
      _days = d.defaultDurationDays;
      _instructions.text = d.instructions ?? '';
    });
  }

  double? get _mlValue => double.tryParse(_ml.text.trim().replaceAll(',', '.'));

  List<String> get _warnings {
    final d = _drug;
    final ml = _mlValue;
    if (d == null || ml == null) return const [];
    return DoseCalculator.validate(
      d,
      weightKg: widget.weightKg,
      doseMg: DoseCalculator.mlToMg(d, ml),
      timesPerDay: _times,
      ageMonths: widget.ageMonths,
    );
  }

  void _save() {
    if (_custom) {
      if (_customName.text.trim().isEmpty || _customDose.text.trim().isEmpty) {
        showToast(context, 'Enter medicine name and dose', error: true);
        return;
      }
      Navigator.pop(
        context,
        RxItem(
          name: _customName.text.trim(),
          doseText: _customDose.text.trim(),
          timesPerDay: _times,
          durationDays: _days,
          instructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
        ),
      );
      return;
    }
    final d = _drug;
    final ml = _mlValue;
    if (d == null || ml == null || ml <= 0) {
      showToast(context, 'Choose a medicine and enter a valid dose', error: true);
      return;
    }
    Navigator.pop(
      context,
      RxItem(
        name: '${d.name} ${d.form}',
        doseMl: ml,
        doseMg: DoseCalculator.mlToMg(d, ml),
        timesPerDay: _times,
        durationDays: _days,
        instructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
      ),
    );
  }

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('$value', style: AppText.h2),
                  Text(label, style: AppText.small),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _drug;
    final warnings = _warnings;
    final mg = (d != null && _mlValue != null) ? DoseCalculator.mlToMg(d, _mlValue!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add medicine', style: AppText.h1),
        const SizedBox(height: 4),
        Text('For ${numFmt(widget.weightKg)} kg · ${ageLabel(DateTime.now().subtract(Duration(days: (widget.ageMonths * 30.4375).round())))}',
            style: AppText.muted),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in widget.formulary)
              ChoiceChip(
                label: Text(f.name),
                selected: !_custom && _drug?.id == f.id,
                onSelected: (_) => _select(f),
                showCheckmark: false,
                selectedColor: AppColors.navy,
                labelStyle: AppText.bodyBold.copyWith(
                    fontSize: 13,
                    color: (!_custom && _drug?.id == f.id) ? Colors.white : AppColors.ink),
              ),
            ChoiceChip(
              label: const Text('Other…'),
              selected: _custom,
              onSelected: (_) => setState(() {
                _custom = true;
                _drug = null;
              }),
              showCheckmark: false,
              selectedColor: AppColors.navy,
              labelStyle: AppText.bodyBold.copyWith(
                  fontSize: 13, color: _custom ? Colors.white : AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_custom) ...[
          TextField(
            controller: _customName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Medicine name & form'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customDose,
            decoration: const InputDecoration(
                labelText: 'Dose (as written for parents, e.g. 5 mL)'),
          ),
          const SizedBox(height: 8),
          Text('Custom medicines are not checked by the dose calculator.',
              style: AppText.small.copyWith(color: AppColors.warning)),
          const SizedBox(height: 12),
        ],
        if (d != null) ...[
          AppCard(
            color: AppColors.infoSoft,
            borderColor: AppColors.infoSoft,
            shadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggested for ${numFmt(widget.weightKg)} kg', style: AppText.label.copyWith(color: AppColors.info)),
                const SizedBox(height: 4),
                Text(
                  '${d.mgPerKgPerDose.toStringAsFixed(0)} mg/kg/dose · ${d.dosesPerDay}×/day · '
                  'max ${d.maxMgPerKgPerDay.toStringAsFixed(0)} mg/kg/day',
                  style: AppText.small.copyWith(color: AppColors.ink),
                ),
                if (!d.reviewed) ...[
                  const SizedBox(height: 6),
                  Text('Default formulary value - not yet clinically reviewed. Verify before use.',
                      style: AppText.small.copyWith(color: AppColors.warning)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ml,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Dose per time',
              suffixText: 'mL',
              helperText: mg == null ? null : '= ${numFmt(mg)} mg',
            ),
          ),
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(w, style: AppText.small.copyWith(color: AppColors.danger))),
                ],
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (d != null || _custom) ...[
          Row(
            children: [
              _stepper('times/day', _times, 1, 6, (v) => setState(() => _times = v)),
              const SizedBox(width: 10),
              _stepper('days', _days, 1, 30, (v) => setState(() => _days = v)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _instructions,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Instructions (optional)'),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Add to prescription', kind: AppButtonKind.accent, onPressed: _save),
        ],
      ],
    );
  }
}
