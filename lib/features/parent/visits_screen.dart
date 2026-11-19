import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'child_scope.dart';

Tone _statusTone(String s) => switch (s) {
      'booked' => Tone.info,
      'in_consult' => Tone.accent,
      'completed' => Tone.success,
      'cancelled' || 'no_show' => Tone.danger,
      _ => Tone.neutral,
    };

String _statusLabel(String s) => switch (s) {
      'booked' => 'Booked',
      'in_consult' => 'In consultation',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      'no_show' => 'Missed',
      _ => s,
    };

class ParentVisitsScreen extends StatelessWidget {
  const ParentVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChildScope(
        title: 'Visits',
        builder: (_, child) => _VisitsBody(key: ValueKey(child.id), child: child),
      );
}

class _VisitsBody extends ConsumerStatefulWidget {
  const _VisitsBody({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<_VisitsBody> createState() => _VisitsBodyState();
}

class _VisitsBodyState extends ConsumerState<_VisitsBody> {
  String _tab = 'Appointments';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ChoiceGroup<String>(
              options: const ['Appointments', 'Prescriptions'],
              selected: _tab,
              onChanged: (v) => setState(() => _tab = v),
              labelOf: (v) => v,
            ),
          ),
        ),
        Expanded(
          child: _tab == 'Appointments'
              ? _AppointmentsList(child: widget.child)
              : _PrescriptionsList(child: widget.child),
        ),
      ],
    );
  }
}

class _AppointmentsList extends ConsumerWidget {
  const _AppointmentsList({required this.child});

  final Child child;

  Future<void> _cancel(BuildContext context, WidgetRef ref, Appointment a) async {
    final ok = await confirmDialog(context,
        title: 'Cancel appointment?',
        message: '${fmtDayDate(a.scheduledAt)} at ${fmtTime(a.scheduledAt)} will be released.',
        confirmLabel: 'Cancel appointment',
        destructive: true);
    if (!ok) return;
    try {
      await ref.read(appointmentRepositoryProvider).setStatus(a.id, 'cancelled');
      ref.invalidate(childAppointmentsProvider(child.id));
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childAppointmentsProvider(child.id));
    final clinic = ref.watch(childClinicProvider(child.id)).valueOrNull;

    return AsyncValueView<List<Appointment>>(
      value: async,
      onRetry: () => ref.invalidate(childAppointmentsProvider(child.id)),
      data: (list) {
        final upcoming = list.where((a) => a.isUpcoming).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final past = list.where((a) => !a.isUpcoming).toList();

        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(childAppointmentsProvider(child.id)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              AppButton(
                label: clinic == null ? 'Connect clinic to book' : 'Book appointment',
                icon: clinic == null ? Icons.qr_code_scanner_rounded : Icons.add_rounded,
                kind: AppButtonKind.accent,
                onPressed: () =>
                    context.push(clinic == null ? '/parent/join-clinic' : '/parent/book'),
              ),
              const SectionHeader('Upcoming'),
              if (upcoming.isEmpty)
                AppCard(
                  shadow: false,
                  child: Text('No upcoming appointments.', style: AppText.muted),
                )
              else
                for (final a in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpcomingCard(a: a, onCancel: () => _cancel(context, ref, a)),
                  ),
              if (past.isNotEmpty) ...[
                const SectionHeader('Past'),
                for (final a in past)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fmtDateTime(a.scheduledAt), style: AppText.bodyBold),
                                Text(a.reason ?? 'Clinic visit', style: AppText.small),
                              ],
                            ),
                          ),
                          StatusPill(_statusLabel(a.status), tone: _statusTone(a.status)),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard({required this.a, required this.onCancel});

  final Appointment a;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = dateOnly(a.scheduledAt) == dateOnly(DateTime.now());
    final queue = isToday ? ref.watch(queueStatusProvider(a.id)).valueOrNull : null;

    return AppCard(
      color: AppColors.navy,
      borderColor: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(fmtDayDate(a.scheduledAt),
                    style: AppText.h1.copyWith(color: Colors.white)),
              ),
              StatusPill(_statusLabel(a.status), tone: _statusTone(a.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${fmtTime(a.scheduledAt)} · ${a.clinicName ?? 'Clinic'}',
              style: AppText.body.copyWith(color: Colors.white70)),
          if (a.reason != null) ...[
            const SizedBox(height: 4),
            Text(a.reason!, style: AppText.small.copyWith(color: Colors.white60)),
          ],
          if (a.tokenNo != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _QueueStat('Your token', '#${a.tokenNo}', highlight: true),
                  if (queue != null) ...[
                    _QueueStat('Now serving',
                        queue.nowServing == null ? '-' : '#${queue.nowServing}'),
                    _QueueStat('Ahead of you', '${queue.ahead}'),
                  ],
                ],
              ),
            ),
          ],
          if (a.status == 'booked') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel appointment',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  const _QueueStat(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.small.copyWith(color: Colors.white60)),
          const SizedBox(height: 4),
          Text(value,
              style: AppText.h1.copyWith(
                  color: highlight ? AppColors.orange : Colors.white, fontSize: 22)),
        ],
      ),
    );
  }
}

class _PrescriptionsList extends ConsumerWidget {
  const _PrescriptionsList({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prescriptionsProvider(child.id));
    return AsyncValueView<List<Prescription>>(
      value: async,
      onRetry: () => ref.invalidate(prescriptionsProvider(child.id)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No prescriptions yet',
            message: 'Prescriptions from your doctor will appear here instantly.',
          );
        }
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(prescriptionsProvider(child.id)),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = list[i];
              return AppCard(
                onTap: () => context.push('/prescription/${p.id}'),
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.receipt_long_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.diagnosis ?? 'Prescription', style: AppText.h3),
                          const SizedBox(height: 2),
                          Text('${fmtDate(p.createdAt)} · ${p.doctorName ?? 'Doctor'}',
                              style: AppText.small),
                          const SizedBox(height: 2),
                          Text(p.items.map((e) => e.name).join(', '),
                              style: AppText.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
