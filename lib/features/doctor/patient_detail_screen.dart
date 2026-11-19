import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import '../shared/dental_view.dart';
import '../shared/dermatology_view.dart';
import '../shared/growth_view.dart';
import '../shared/ophthalmology_view.dart';
import '../shared/pregnancy_care_view.dart';
import '../shared/psychiatry_view.dart';
import '../shared/records_view.dart';
import '../shared/vaccines_view.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.childId, this.appointmentId});

  final String childId;
  final String? appointmentId;

  Future<void> _completeVisit(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(appointmentRepositoryProvider).setStatus(appointmentId!, 'completed');
      ref.invalidate(todaysQueueProvider);
      ref.invalidate(doctorStatsProvider);
      ref.invalidate(timelineProvider(childId));
      if (context.mounted) {
        showToast(context, 'Visit marked complete');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(childByIdProvider(childId));
    final department = ref.watch(activeClinicDepartmentProvider);
    final appt = appointmentId == null ? '' : '?appt=$appointmentId';

    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: errorMessage(e), onRetry: () => ref.invalidate(childByIdProvider(childId))),
      ),
      data: (child) => DefaultTabController(
        key: ValueKey(department.key),
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(child.name),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: department.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: department.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(department.icon, size: 14, color: department.color),
                    const SizedBox(width: 5),
                    Text(
                      department.shortName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: department.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppCard(
                  color: AppColors.navy,
                  borderColor: AppColors.navy,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InitialAvatar(name: child.name, dark: true, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(child.name,
                                          style: AppText.h2.copyWith(color: Colors.white)),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        department.patientLabel.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${child.age} · ${child.gender}'
                                  '${child.bloodGroup == null ? '' : ' · ${child.bloodGroup}'}',
                                  style: AppText.muted.copyWith(color: Colors.white70),
                                ),
                                if (child.parentName != null)
                                  Text('Parent: ${child.parentName}',
                                      style: AppText.small.copyWith(color: Colors.white60)),
                              ],
                            ),
                          ),
                          if (child.parentPhone != null)
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: AppColors.navyLight),
                              icon: const Icon(Icons.call_rounded, color: AppColors.orange),
                              onPressed: () =>
                                  launchUrl(Uri.parse('tel:+${child.parentPhone}')),
                            ),
                        ],
                      ),
                      if (child.allergies != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFFF8A8E), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Allergies: ${child.allergies}',
                                    style: AppText.small.copyWith(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Prescribe',
                        icon: Icons.edit_note_rounded,
                        kind: AppButtonKind.accent,
                        height: 48,
                        onPressed: () => context.push('/doctor/patient/$childId/prescribe$appt'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Chat',
                        icon: Icons.chat_bubble_outline_rounded,
                        kind: AppButtonKind.outline,
                        height: 48,
                        onPressed: () => context.push('/doctor/chat/$childId'),
                      ),
                    ),
                  ],
                ),
              ),
              if (appointmentId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: TextButton.icon(
                    onPressed: () => _completeVisit(context, ref),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark visit complete (no prescription)'),
                  ),
                ),
              TabBar(
                labelColor: AppColors.navy,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: department.color,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.line,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: department.tabs.map((t) => Tab(text: t)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: switch (department) {
                    ClinicDepartment.pediatrics => [
                        _TimelineTab(childId: childId),
                        VaccinesView(childId: childId),
                        GrowthView(child: child),
                        RecordsView(childId: childId),
                      ],
                    ClinicDepartment.dermatology => [
                        _TimelineTab(childId: childId),
                        DermatologyGalleryView(patientId: childId),
                        DermatologySessionsView(patientId: childId),
                        RecordsView(childId: childId),
                      ],
                    ClinicDepartment.dental => [
                        _TimelineTab(childId: childId),
                        DentalOdontogramView(patientId: childId),
                        DentalTreatmentPlansView(patientId: childId),
                        RecordsView(childId: childId),
                      ],
                    ClinicDepartment.pregnancyCare => [
                        _TimelineTab(childId: childId),
                        PregnancyAncView(patientId: childId),
                        PrenatalChecklistView(patientId: childId),
                        RecordsView(childId: childId),
                      ],
                    ClinicDepartment.ophthalmology => [
                        _TimelineTab(childId: childId),
                        OphthalmologyRefractionView(patientId: childId),
                        OphthalmologyExamsView(patientId: childId),
                        RecordsView(childId: childId),
                      ],
                    ClinicDepartment.psychiatry => [
                        _TimelineTab(childId: childId),
                        PsychiatryScreenersView(patientId: childId),
                        PsychiatryNotesView(patientId: childId),
                        RecordsView(childId: childId),
                      ],
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab({required this.childId});

  final String childId;

  static (IconData, Color) _style(TimelineKind k) => switch (k) {
        TimelineKind.visit => (Icons.medical_services_rounded, AppColors.info),
        TimelineKind.prescription => (Icons.receipt_long_rounded, AppColors.orange),
        TimelineKind.vaccine => (Icons.vaccines_rounded, AppColors.success),
        TimelineKind.growth => (Icons.monitor_weight_rounded, AppColors.navyLight),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timelineProvider(childId));
    return AsyncValueView<List<TimelineEvent>>(
      value: async,
      onRetry: () => ref.invalidate(timelineProvider(childId)),
      data: (events) {
        if (events.isEmpty) {
          return const EmptyState(
            icon: Icons.timeline_rounded,
            title: 'No history yet',
            message: 'Visits, prescriptions, vaccines and growth checks will appear here.',
          );
        }
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(timelineProvider(childId)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: events.length,
            itemBuilder: (_, i) {
              final e = events[i];
              final (icon, color) = _style(e.kind);
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          IconBadge(icon: icon, color: color, size: 36),
                          if (i != events.length - 1)
                            Expanded(
                              child: Container(width: 2, color: AppColors.line),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          radius: 16,
                          onTap: e.refId == null
                              ? null
                              : () => context.push('/prescription/${e.refId}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmtDate(e.date), style: AppText.small),
                              const SizedBox(height: 2),
                              Text(e.title, style: AppText.bodyBold),
                              if (e.subtitle != null && e.subtitle!.isNotEmpty)
                                Text(e.subtitle!, style: AppText.muted),
                            ],
                          ),
                        ),
                      ),
                    ),
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
