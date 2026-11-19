import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

final _takenSlotsProvider = FutureProvider.autoDispose.family<List<DateTime>, (String, DateTime)>(
  (ref, key) => ref.watch(appointmentRepositoryProvider).takenSlots(key.$1, key.$2),
);

List<DateTime> _slotsFor(Clinic c, DateTime day) {
  final open = parseHm(c.openTime);
  final close = parseHm(c.closeTime);
  var t = DateTime(day.year, day.month, day.day, open.hour, open.minute);
  final end = DateTime(day.year, day.month, day.day, close.hour, close.minute);
  final step = Duration(minutes: c.slotMinutes);
  final out = <DateTime>[];
  while (!t.add(step).isAfter(end)) {
    out.add(t);
    t = t.add(step);
  }
  return out;
}

const _reasons = ['Fever', 'Cough / cold', 'Vaccination', 'Check-up', 'Stomach upset', 'Other'];

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  late DateTime _day = dateOnly(DateTime.now());
  DateTime? _slot;
  String? _reason;
  final _symptoms = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _book(Child child, Clinic clinic) async {
    if (_slot == null) {
      showToast(context, 'Please choose a time slot', error: true);
      return;
    }
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(appointmentRepositoryProvider).book(
            clinicId: clinic.id,
            childId: child.id,
            parentId: uid,
            scheduledAt: _slot!,
            reason: _reason,
            symptoms: _symptoms.text,
          );
      ref.invalidate(childAppointmentsProvider(child.id));
      if (mounted) {
        context.pop();
        showToast(context, 'Appointment booked for ${fmtTime(_slot!)}');
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final taken = e.code == '23505';
        showToast(context, taken ? 'That slot was just taken. Please pick another.' : e.message,
            error: true);
        if (taken) {
          ref.invalidate(_takenSlotsProvider((clinic.id, _day)));
          setState(() => _slot = null);
        }
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider).valueOrNull;
    final clinicAsync =
        child == null ? const AsyncValue<Clinic?>.data(null) : ref.watch(childClinicProvider(child.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: child == null
          ? const ErrorView(message: 'No child selected')
          : AsyncValueView<Clinic?>(
              value: clinicAsync,
              data: (clinic) {
                if (clinic == null) {
                  return EmptyState(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Connect your clinic first',
                    actionLabel: 'Scan clinic QR',
                    onAction: () => context.pushReplacement('/parent/join-clinic'),
                  );
                }
                final slots = _slotsFor(clinic, _day);
                final taken = ref.watch(_takenSlotsProvider((clinic.id, _day))).valueOrNull ?? const [];
                final takenMs = taken.map((e) => e.millisecondsSinceEpoch).toSet();
                final now = DateTime.now();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          const IconBadge(icon: Icons.local_hospital_rounded),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(clinic.name, style: AppText.h3),
                                Text('For ${child.name} · ${clinic.openTime}–${clinic.closeTime}',
                                    style: AppText.small),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader('Choose a day'),
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = dateOnly(now).add(Duration(days: i));
                          final sel = d == _day;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _day = d;
                              _slot = null;
                            }),
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                color: sel ? AppColors.navy : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: sel ? AppColors.navy : AppColors.line),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(fmtDayDate(d).split(',').first,
                                      style: AppText.small
                                          .copyWith(color: sel ? Colors.white70 : AppColors.muted)),
                                  const SizedBox(height: 4),
                                  Text('${d.day}',
                                      style: AppText.h2
                                          .copyWith(color: sel ? Colors.white : AppColors.ink)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SectionHeader('Choose a time'),
                    if (slots.isEmpty)
                      Text('No slots available on this day.', style: AppText.muted)
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in slots)
                            Builder(builder: (_) {
                              final unavailable =
                                  takenMs.contains(s.millisecondsSinceEpoch) || s.isBefore(now);
                              final sel = _slot == s;
                              return ChoiceChip(
                                label: Text(fmtTime(s)),
                                selected: sel,
                                showCheckmark: false,
                                onSelected: unavailable ? null : (_) => setState(() => _slot = s),
                                selectedColor: AppColors.orange,
                                backgroundColor: Colors.white,
                                disabledColor: const Color(0xFFEEF0F6),
                                side: BorderSide(
                                    color: sel ? AppColors.orange : AppColors.line),
                                labelStyle: AppText.bodyBold.copyWith(
                                  fontSize: 13,
                                  color: unavailable
                                      ? AppColors.muted.withValues(alpha: 0.6)
                                      : (sel ? Colors.white : AppColors.ink),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              );
                            }),
                        ],
                      ),
                    const SectionHeader('Reason for visit'),
                    ChoiceGroup<String>(
                      options: _reasons,
                      selected: _reason,
                      onChanged: (v) => setState(() => _reason = v),
                      labelOf: (v) => v,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _symptoms,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Symptoms / notes for the doctor (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: _slot == null
                          ? 'Select a time'
                          : 'Confirm · ${fmtDayDate(_slot!)}, ${fmtTime(_slot!)}',
                      kind: AppButtonKind.accent,
                      loading: _saving,
                      onPressed: _slot == null ? null : () => _book(child, clinic),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
