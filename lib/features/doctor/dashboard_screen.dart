import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(doctorStatsProvider);
    ref.invalidate(todaysQueueProvider);
  }

  Future<void> _start(BuildContext context, WidgetRef ref, Appointment a) async {
    try {
      if (a.status == 'booked') {
        await ref.read(appointmentRepositoryProvider).setStatus(a.id, 'in_consult');
        await _refresh(ref);
      }
      if (context.mounted) context.push('/doctor/patient/${a.childId}?appt=${a.id}');
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, Appointment a, String s) async {
    try {
      await ref.read(appointmentRepositoryProvider).setStatus(a.id, s);
      await _refresh(ref);
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final clinic = ref.watch(myClinicProvider).valueOrNull;
    final ClinicDepartment department =
        clinic?.department ?? ref.watch(activeClinicDepartmentProvider);
    final stats = ref.watch(doctorStatsProvider);
    final queue = ref.watch(todaysQueueProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.orange,
        edgeOffset: 80,
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            BrandHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(fmtDayDate(DateTime.now()).toUpperCase(),
                                    style: AppText.label),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: department.color.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: department.color.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(department.icon, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        department.shortName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Today’s clinic',
                                style: AppText.h1.copyWith(color: Colors.white, fontSize: 26)),
                            const SizedBox(height: 2),
                            Text(clinic?.name ?? '',
                                style: AppText.muted.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: InitialAvatar(name: profile?.fullName ?? '?', dark: true, size: 46),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  stats.when(
                    loading: () => const SizedBox(
                        height: 150, child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text(errorMessage(e),
                        style: AppText.body.copyWith(color: Colors.white)),
                    data: (s) {
                      final (stat2Label, stat2Icon) = switch (department) {
                        ClinicDepartment.pediatrics => ('Pending vaccines', Icons.vaccines_rounded),
                        ClinicDepartment.dermatology => ('Active sessions', Icons.healing_rounded),
                        ClinicDepartment.dental => ('Active treatments', Icons.health_and_safety_rounded),
                        ClinicDepartment.pregnancyCare => ('Due this month', Icons.calendar_month_rounded),
                        ClinicDepartment.ophthalmology => ('Refraction cases', Icons.visibility_rounded),
                        ClinicDepartment.psychiatry => ('Active screeners', Icons.psychology_rounded),
                      };
                      final (stat3Label, stat3Icon) = switch (department) {
                        ClinicDepartment.pediatrics => ('Missed follow-ups', Icons.event_busy_rounded),
                        ClinicDepartment.dermatology => ('Review photos', Icons.photo_library_rounded),
                        ClinicDepartment.dental => ('Recall checkups', Icons.event_repeat_rounded),
                        ClinicDepartment.pregnancyCare => ('High-risk ANC', Icons.monitor_heart_rounded),
                        ClinicDepartment.ophthalmology => ('IOP / Glaucoma', Icons.speed_rounded),
                        ClinicDepartment.psychiatry => ('Therapy sessions', Icons.note_alt_rounded),
                      };

                      return Column(
                        children: [
                          Row(children: [
                            Expanded(
                                child: _Stat(
                                    department == ClinicDepartment.pregnancyCare
                                        ? 'Expectant Mothers'
                                        : (department == ClinicDepartment.psychiatry
                                            ? 'Active Clients'
                                            : 'Patients'),
                                    s.patients,
                                    Icons.groups_rounded,
                                    () => context.go('/doctor/patients'))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _Stat(stat2Label, s.pendingVaccines, stat2Icon,
                                    () => context.go('/doctor/followups'))),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: _Stat(stat3Label, s.missedFollowups, stat3Icon,
                                    () => context.go('/doctor/followups'),
                                    alert: s.missedFollowups > 0)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _Stat('Messages', s.unreadMessages,
                                    Icons.chat_bubble_rounded, () => context.go('/doctor/chat'))),
                          ]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: AsyncValueView<List<Appointment>>(
                value: queue,
                onRetry: () => ref.invalidate(todaysQueueProvider),
                data: (list) {
                  final active = list.where((a) => a.isActive).toList();
                  final next = active.firstOrNull;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Next patient'),
                      if (next == null)
                        AppCard(
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 20, color: AppColors.muted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('No one is waiting. Queue is clear.',
                                    style: AppText.muted),
                              ),
                            ],
                          ),
                        )
                      else
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InitialAvatar(name: next.childName ?? '?', size: 50),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(next.childName ?? 'Patient', style: AppText.h2),
                                        Text(
                                          '${next.childDob == null ? '' : '${ageLabel(next.childDob!)} · '}'
                                          '${fmtTime(next.scheduledAt)}'
                                          '${next.tokenNo == null ? '' : ' · Token #${next.tokenNo}'}',
                                          style: AppText.small,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (next.status == 'in_consult')
                                    const StatusPill('In consult', tone: Tone.accent),
                                ],
                              ),
                              if (next.reason != null || next.symptoms != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  [next.reason, next.symptoms].whereType<String>().join(' - '),
                                  style: AppText.body,
                                ),
                              ],
                              const SizedBox(height: 14),
                              AppButton(
                                label: next.status == 'in_consult'
                                    ? 'Open patient'
                                    : 'Start consultation',
                                icon: Icons.play_arrow_rounded,
                                kind: AppButtonKind.accent,
                                onPressed: () => _start(context, ref, next),
                              ),
                            ],
                          ),
                        ),
                      SectionHeader('Today’s queue', action: null),
                      if (list.isEmpty)
                        AppCard(
                            shadow: false,
                            child: Text('No appointments today.', style: AppText.muted))
                      else
                        for (final a in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QueueRow(
                              a: a,
                              onOpen: () => _start(context, ref, a),
                              onNoShow: () => _setStatus(context, ref, a, 'no_show'),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.onTap, {this.alert = false});

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.orange, size: 22),
              const SizedBox(height: 10),
              Text('$value',
                  style: AppText.display.copyWith(
                      color: alert ? AppColors.orange : Colors.white, fontSize: 30)),
              const SizedBox(height: 2),
              Text(label, style: AppText.small.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.a, required this.onOpen, required this.onNoShow});

  final Appointment a;
  final VoidCallback onOpen;
  final VoidCallback onNoShow;

  @override
  Widget build(BuildContext context) {
    final (String label, Tone tone) = switch (a.status) {
      'in_consult' => ('In consult', Tone.accent),
      'completed' => ('Done', Tone.success),
      'no_show' => ('No-show', Tone.danger),
      _ => ('Waiting', Tone.info),
    };
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(14)),
            child: Text('#${a.tokenNo ?? '-'}',
                style: AppText.h3.copyWith(color: AppColors.orange)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.childName ?? 'Patient', style: AppText.bodyBold),
                Text('${fmtTime(a.scheduledAt)}${a.reason == null ? '' : ' · ${a.reason}'}',
                    style: AppText.small),
              ],
            ),
          ),
          StatusPill(label, tone: tone),
          if (a.status == 'booked')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
              onSelected: (v) {
                if (v == 'noshow') onNoShow();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'noshow', child: Text('Mark as no-show')),
              ],
            ),
        ],
      ),
    );
  }
}
