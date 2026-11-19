import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

/// Vaccine schedule for one child. Used by the parent app and the doctor's patient view.
class VaccinesView extends ConsumerWidget {
  const VaccinesView({super.key, required this.childId});

  final String childId;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    ChildVaccine v, {
    required bool done,
    DateTime? on,
  }) async {
    try {
      await ref.read(healthRepositoryProvider).setVaccineDone(v.id, done: done, givenOn: on);
      ref.invalidate(vaccinesProvider(childId));
      ref.invalidate(pendingVaccinesProvider);
      ref.invalidate(doctorStatsProvider);
      ref.invalidate(timelineProvider(childId));
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  void _openSheet(BuildContext context, WidgetRef ref, ChildVaccine v) {
    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v.name, style: AppText.h1),
          if (v.protectsAgainst != null) ...[
            const SizedBox(height: 4),
            Text('Protects against ${v.protectsAgainst}', style: AppText.muted),
          ],
          const SizedBox(height: 14),
          InfoRow('Recommended', '${v.ageLabel} · ${fmtDate(v.dueDate)}'),
          if (v.isDone && v.givenOn != null) InfoRow('Given on', fmtDate(v.givenOn!)),
          const SizedBox(height: 18),
          if (!v.isDone) ...[
            AppButton(
              label: 'Mark as given today',
              icon: Icons.check_circle_outline_rounded,
              kind: AppButtonKind.accent,
              onPressed: () {
                Navigator.pop(ctx);
                _set(context, ref, v, done: true, on: DateTime.now());
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Given on another date',
              icon: Icons.event_rounded,
              kind: AppButtonKind.outline,
              onPressed: () async {
                final d = await pickDate(ctx,
                    initial: DateTime.now(),
                    first: DateTime.now().subtract(const Duration(days: 365 * 20)),
                    last: DateTime.now());
                if (d == null || !ctx.mounted) return;
                Navigator.pop(ctx);
                if (context.mounted) _set(context, ref, v, done: true, on: d);
              },
            ),
          ] else
            AppButton(
              label: 'Undo - mark as pending',
              kind: AppButtonKind.outline,
              onPressed: () {
                Navigator.pop(ctx);
                _set(context, ref, v, done: false);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _markOverdue(BuildContext context, WidgetRef ref, List<ChildVaccine> overdue) async {
    final ok = await confirmDialog(
      context,
      title: 'Mark overdue vaccines as given?',
      message:
          'This marks ${overdue.length} vaccines as given on their recommended dates. '
          'Please check your child’s vaccination card first.',
      confirmLabel: 'Yes, mark given',
    );
    if (!ok) return;
    try {
      await ref.read(healthRepositoryProvider).markManyDone(overdue);
      ref.invalidate(vaccinesProvider(childId));
      ref.invalidate(pendingVaccinesProvider);
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vaccinesProvider(childId));
    return AsyncValueView<List<ChildVaccine>>(
      value: async,
      onRetry: () => ref.invalidate(vaccinesProvider(childId)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.vaccines_rounded,
            title: 'No schedule yet',
            message: 'The vaccine schedule is created automatically when a child is added.',
          );
        }
        final done = list.where((v) => v.isDone).length;
        final overdue = list.where((v) => v.isOverdue).toList();
        final soon = list.where((v) => v.isDueSoon).length;

        // Group by recommended age, keeping chronological order.
        final groups = <String, List<ChildVaccine>>{};
        for (final v in list) {
          groups.putIfAbsent(v.ageLabel, () => []).add(v);
        }

        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(vaccinesProvider(childId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppCard(
                color: AppColors.navy,
                borderColor: AppColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vaccination progress',
                        style: AppText.muted.copyWith(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('$done of ${list.length} vaccines done',
                        style: AppText.h1.copyWith(color: Colors.white)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: done / list.length,
                        minHeight: 10,
                        backgroundColor: AppColors.navyLight,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        StatusPill('$soon due soon', tone: Tone.accent),
                        const SizedBox(width: 8),
                        StatusPill('${overdue.length} overdue',
                            tone: overdue.isEmpty ? Tone.neutral : Tone.danger),
                      ],
                    ),
                  ],
                ),
              ),
              if (overdue.length > 2) ...[
                const SizedBox(height: 12),
                AppCard(
                  color: AppColors.warningSoft,
                  borderColor: AppColors.warningSoft,
                  shadow: false,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${overdue.length} vaccines are past their recommended date. Already given?',
                          style: AppText.body,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _markOverdue(context, ref, overdue),
                        child: const Text('Mark given'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                  child: Row(
                    children: [
                      Text(entry.key.toUpperCase(), style: AppText.label),
                      const SizedBox(width: 8),
                      Text(fmtDate(entry.value.first.dueDate), style: AppText.small),
                    ],
                  ),
                ),
                for (final v in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _VaccineTile(v: v, onTap: () => _openSheet(context, ref, v)),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VaccineTile extends StatelessWidget {
  const _VaccineTile({required this.v, required this.onTap});

  final ChildVaccine v;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = v.isDone
        ? (Icons.check_circle_rounded, AppColors.success)
        : v.isOverdue
            ? (Icons.error_rounded, AppColors.danger)
            : v.isDueSoon
                ? (Icons.schedule_rounded, AppColors.orange)
                : (Icons.radio_button_unchecked_rounded, AppColors.muted);

    final pill = v.isDone
        ? const StatusPill('Done', tone: Tone.success, icon: Icons.check_rounded)
        : v.isOverdue
            ? StatusPill('${-v.daysToDue}d overdue', tone: Tone.danger)
            : v.isDueSoon
                ? StatusPill(relativeDays(v.dueDate), tone: Tone.accent)
                : const StatusPill('Upcoming');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name, style: AppText.bodyBold),
                const SizedBox(height: 2),
                Text(
                  v.isDone && v.givenOn != null
                      ? 'Given ${fmtDate(v.givenOn!)}'
                      : 'Due ${fmtDate(v.dueDate)}',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          pill,
        ],
      ),
    );
  }
}
