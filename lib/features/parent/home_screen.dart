import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import 'child_scope.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final children = ref.watch(childrenProvider).valueOrNull ?? const <Child>[];
    final childAsync = ref.watch(selectedChildProvider);
    final child = childAsync.valueOrNull;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.orange,
        edgeOffset: 80,
        onRefresh: () async {
          ref.invalidate(childrenProvider);
          if (child != null) {
            ref.invalidate(vaccinesProvider(child.id));
            ref.invalidate(growthProvider(child.id));
            ref.invalidate(childAppointmentsProvider(child.id));
            ref.invalidate(recordsProvider(child.id));
            ref.invalidate(prescriptionsProvider(child.id));
          }
        },
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
                            Text(greeting(),
                                style: AppText.muted.copyWith(color: Colors.white70)),
                            const SizedBox(height: 2),
                            Text(
                              'Hi, ${(profile?.fullName ?? '').split(' ').first}',
                              style: AppText.h1.copyWith(color: Colors.white, fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/parent/profile'),
                        child: InitialAvatar(name: profile?.fullName ?? '?', dark: true, size: 46),
                      ),
                    ],
                  ),
                  if (children.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const ChildChips(dark: true),
                  ],
                  if (child != null) ...[
                    const SizedBox(height: 18),
                    _DepartmentHeroCard(child: child),
                  ],
                ],
              ),
            ),
            if (childAsync.isLoading && child == null)
              const Padding(padding: EdgeInsets.all(48), child: LoadingView())
            else if (child == null)
              const _EmptyDashboardView()
            else
              _HomeBody(child: child),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardView extends StatelessWidget {
  const _EmptyDashboardView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.navy, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Add Child Profile',
                    style: AppText.h2, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Register your child to generate an automated vaccine schedule, record growth milestones, and access clinic records.',
                  style: AppText.muted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Add Profile',
                  icon: Icons.add_rounded,
                  expand: false,
                  onPressed: () => context.push('/parent/add-child'),
                  kind: AppButtonKind.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Healthcare Services', style: AppText.h3),
          const SizedBox(height: 12),
          const _ServiceInfoCard(
            icon: Icons.vaccines_rounded,
            title: 'Immunization Tracker',
            description: 'Automatic Indian Academy of Pediatrics (IAP) schedule with due dates.',
          ),
          const SizedBox(height: 10),
          const _ServiceInfoCard(
            icon: Icons.show_chart_rounded,
            title: 'Growth Milestones',
            description: 'Track height, weight, and head circumference percentiles against WHO standards.',
          ),
          const SizedBox(height: 10),
          const _ServiceInfoCard(
            icon: Icons.medical_services_rounded,
            title: 'Clinic Consults & Prescriptions',
            description: 'Connect with your doctor, receive digital prescriptions, and view records.',
          ),
        ],
      ),
    );
  }
}

class _ServiceInfoCard extends StatelessWidget {
  const _ServiceInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.navy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyBold),
                const SizedBox(height: 3),
                Text(description, style: AppText.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentHeroCard extends ConsumerWidget {
  const _DepartmentHeroCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinic = ref.watch(childClinicProvider(child.id)).valueOrNull;
    final dept = clinic?.department ?? ClinicDepartment.pediatrics;

    return switch (dept) {
      ClinicDepartment.pediatrics => _NextVaccineCard(child: child),
      ClinicDepartment.dental => _DentalHeroCard(child: child),
      ClinicDepartment.dermatology => _DermaHeroCard(child: child),
      ClinicDepartment.pregnancyCare => _PregnancyHeroCard(child: child),
      ClinicDepartment.ophthalmology => _EyeHeroCard(child: child),
      ClinicDepartment.psychiatry => _PsychiatryHeroCard(child: child),
    };
  }
}

class _NextVaccineCard extends ConsumerWidget {
  const _NextVaccineCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccines = ref.watch(vaccinesProvider(child.id)).valueOrNull;
    final next = vaccines?.where((v) => v.status == 'pending').firstOrNull;

    final String title;
    final String subtitle;
    if (vaccines == null) {
      title = 'Loading…';
      subtitle = '';
    } else if (next == null) {
      title = 'All vaccines done';
      subtitle = 'Great job keeping ${child.name.split(' ').first} protected!';
    } else {
      title = next.name;
      subtitle = next.isOverdue
          ? 'Overdue since ${fmtShortDate(next.dueDate)} (${-next.daysToDue} days)'
          : 'Due ${fmtShortDate(next.dueDate)} · ${relativeDays(next.dueDate)}';
    }

    return _HeroCardContainer(
      color: AppColors.navy,
      tag: 'NEXT VACCINE · PEDIATRICS',
      title: title,
      subtitle: subtitle,
      icon: Icons.vaccines_rounded,
      onTap: () => context.go('/parent/vaccines'),
    );
  }
}

class _DentalHeroCard extends ConsumerWidget {
  const _DentalHeroCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(dentalPlansProvider(child.id));
    final pending = plans.where((p) => !p.isCompleted).toList();
    final title = pending.isNotEmpty ? pending.first.procedureName : 'Teeth All Healthy';
    final subtitle = pending.isNotEmpty
        ? 'Scheduled next: ${pending.first.teethInvolved}'
        : 'Regular 6-month checkup advised';

    return _HeroCardContainer(
      color: AppColors.navy,
      tag: 'DENTAL & ORAL CARE',
      title: title,
      subtitle: subtitle,
      icon: Icons.medical_services_rounded,
      onTap: () => context.go('/parent/visits'),
    );
  }
}

class _DermaHeroCard extends ConsumerWidget {
  const _DermaHeroCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(dermaSessionsProvider(child.id));
    final latest = sessions.firstOrNull;
    final title = latest != null ? latest.treatmentName : 'Active Skin Care Plan';
    final subtitle = latest != null
        ? '${latest.sessionLabel} · Next in 2 weeks'
        : 'Before/after comparisons & therapy logged';

    return _HeroCardContainer(
      color: AppColors.navy,
      tag: 'DERMATOLOGY & SKIN',
      title: title,
      subtitle: subtitle,
      icon: Icons.healing_rounded,
      onTap: () => context.go('/parent/visits'),
    );
  }
}

class _PregnancyHeroCard extends ConsumerWidget {
  const _PregnancyHeroCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(pregnancyRecordProvider(child.id));
    final title = 'Week ${record.gestationalWeeks} · Trimester ${record.trimester}';
    final subtitle = '${record.daysRemaining} days to EDD (${fmtDate(record.edd)})';

    return _HeroCardContainer(
      color: AppColors.navy,
      tag: 'PREGNANCY & MATERNITY',
      title: title,
      subtitle: subtitle,
      icon: Icons.favorite_rounded,
      onTap: () => context.go('/parent/visits'),
    );
  }
}

class _EyeHeroCard extends ConsumerWidget {
  const _EyeHeroCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rx = ref.watch(refractionProvider(child.id));
    final title = 'OD ${rx.od.sphere.toStringAsFixed(2)} · OS ${rx.os.sphere.toStringAsFixed(2)}';
    final subtitle = 'Visual Acuity: 6/6 OU · ${rx.lensTypeAdvice}';

    return _HeroCardContainer(
      color: AppColors.navy,
      tag: 'EYE CLINIC & VISION',
      title: title,
      subtitle: subtitle,
      icon: Icons.visibility_rounded,
      onTap: () => context.go('/parent/visits'),
    );
  }
}

class _PsychiatryHeroCard extends ConsumerWidget {
  const _PsychiatryHeroCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(copingGoalsProvider(child.id));
    final doneCount = goals.where((g) => g.isCompleted).length;
    final title = 'Mental Wellness Plan';
    final subtitle = '$doneCount of ${goals.length} Coping Goals completed';

    return _HeroCardContainer(
      color: AppColors.navy,
      tag: 'PSYCHIATRY & COUNSELLING',
      title: title,
      subtitle: subtitle,
      icon: Icons.psychology_rounded,
      onTap: () => context.go('/parent/visits'),
    );
  }
}

class _HeroCardContainer extends StatelessWidget {
  const _HeroCardContainer({
    required this.color,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tag,
                      style: AppText.label.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 6),
                  Text(title, style: AppText.h1.copyWith(color: Colors.white, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.95))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinic = ref.watch(childClinicProvider(child.id));
    final appts = ref.watch(childAppointmentsProvider(child.id)).valueOrNull ?? const <Appointment>[];
    final records = ref.watch(recordsProvider(child.id)).valueOrNull;
    final rx = ref.watch(prescriptionsProvider(child.id)).valueOrNull;
    final unread = ref.watch(unreadFromDoctorProvider(child.id)).valueOrNull ?? 0;
    final vaccines = ref.watch(vaccinesProvider(child.id)).valueOrNull;
    final growth = ref.watch(growthProvider(child.id)).valueOrNull;

    final upcoming = appts.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final nextAppt = upcoming.firstOrNull;
    final latestGrowth = growth?.lastOrNull;
    final done = vaccines?.where((v) => v.isDone).length ?? 0;
    final total = vaccines?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (clinic.hasValue && clinic.value == null) ...[
            AppCard(
              color: AppColors.orangeSoft,
              borderColor: AppColors.orangeSoft,
              shadow: false,
              onTap: () => context.push('/parent/join-clinic'),
              child: Row(
                children: [
                  const IconBadge(icon: Icons.qr_code_scanner_rounded),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect your clinic', style: AppText.h3),
                        const SizedBox(height: 2),
                        Text('Scan the clinic QR to book visits and chat with the doctor.',
                            style: AppText.small),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.event_rounded,
                  label: 'Appointment',
                  value: nextAppt == null ? 'Book now' : fmtDayDate(nextAppt.scheduledAt),
                  hint: nextAppt == null ? null : fmtTime(nextAppt.scheduledAt),
                  onTap: () => context.go('/parent/visits'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickTile(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Doctor chat',
                  value: unread > 0 ? '$unread new' : 'Message',
                  highlight: unread > 0,
                  onTap: () => context.go('/parent/chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.folder_rounded,
                  label: 'Reports',
                  value: records == null ? '-' : '${records.length} file${records.length == 1 ? '' : 's'}',
                  onTap: () => context.push('/parent/records'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Prescriptions',
                  value: rx == null ? '-' : '${rx.length} issued',
                  onTap: () => context.go('/parent/visits'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SectionHeader('Vaccination', action: 'View all', onAction: () => context.go('/parent/vaccines')),
          AppCard(
            onTap: () => context.go('/parent/vaccines'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                            total == 0 ? 'Schedule loading…' : '$done of $total vaccines done',
                            style: AppText.h3)),
                    Text(total == 0 ? '' : '${(done * 100 / total).round()}%',
                        style: AppText.bodyBold.copyWith(color: AppColors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total, minHeight: 10),
                ),
              ],
            ),
          ),
          SectionHeader('Growth', action: 'Chart', onAction: () => context.go('/parent/growth')),
          AppCard(
            onTap: () => context.go('/parent/growth'),
            child: latestGrowth == null
                ? Row(
                    children: [
                      const IconBadge(icon: Icons.monitor_weight_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text('Add the first weight & height measurement',
                              style: AppText.body)),
                    ],
                  )
                : Row(
                    children: [
                      _Stat('Weight', latestGrowth.weightKg, 'kg'),
                      _Stat('Height', latestGrowth.heightCm, 'cm'),
                      _Stat('Head', latestGrowth.headCm, 'cm'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit);

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.small),
          const SizedBox(height: 4),
          Text(value == null ? '-' : numFmt(value!), style: AppText.h1),
          Text(unit, style: AppText.small),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, size: 40),
          const SizedBox(height: 14),
          Text(label, style: AppText.small),
          const SizedBox(height: 2),
          Text(value,
              style: AppText.h3.copyWith(color: highlight ? AppColors.orange : AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (hint != null) Text(hint!, style: AppText.small),
        ],
      ),
    );
  }
}
