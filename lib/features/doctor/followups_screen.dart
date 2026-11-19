import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  String _tab = 'Missed follow-ups';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-ups')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ChoiceGroup<String>(
                options: const ['Missed follow-ups', 'Pending vaccines'],
                selected: _tab,
                onChanged: (v) => setState(() => _tab = v),
                labelOf: (v) => v,
              ),
            ),
          ),
          Expanded(
            child: _tab == 'Missed follow-ups' ? const _MissedList() : const _PendingVaccineList(),
          ),
        ],
      ),
    );
  }
}

class _MissedList extends ConsumerWidget {
  const _MissedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(missedFollowupsProvider);
    return AsyncValueView<List<MissedFollowUp>>(
      value: async,
      onRetry: () => ref.invalidate(missedFollowupsProvider),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No missed follow-ups',
            message: 'All patients with a scheduled review date have completed their visit.',
          );
        }
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(missedFollowupsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final f = list[i];
              return AppCard(
                onTap: () => context.push('/doctor/patient/${f.childId}'),
                child: Row(
                  children: [
                    InitialAvatar(name: f.childName),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.childName, style: AppText.h3),
                          Text(
                              '${f.diagnosis ?? 'Review'} · due ${fmtShortDate(f.followUpDate)}',
                              style: AppText.small),
                          const SizedBox(height: 6),
                          StatusPill('${f.daysOverdue} days overdue', tone: Tone.danger),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Message parent',
                      style: IconButton.styleFrom(backgroundColor: AppColors.orangeSoft),
                      icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.orange),
                      onPressed: () => context.push('/doctor/chat/${f.childId}'),
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

class _PendingVaccineList extends ConsumerWidget {
  const _PendingVaccineList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingVaccinesProvider);
    return AsyncValueView<List<PendingVaccine>>(
      value: async,
      onRetry: () => ref.invalidate(pendingVaccinesProvider),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.vaccines_rounded,
            title: 'No vaccines due',
            message: 'No patient has a vaccine due in the next 7 days or overdue.',
          );
        }
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(pendingVaccinesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final v = list[i];
              final overdue = v.daysToDue < 0;
              return AppCard(
                onTap: () => context.push('/doctor/patient/${v.childId}'),
                child: Row(
                  children: [
                    IconBadge(
                      icon: Icons.vaccines_rounded,
                      color: overdue ? AppColors.danger : AppColors.orange,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.childName, style: AppText.h3),
                          Text(v.vaccineName, style: AppText.muted),
                        ],
                      ),
                    ),
                    StatusPill(
                      overdue ? '${-v.daysToDue}d overdue' : relativeDays(v.dueDate),
                      tone: overdue ? Tone.danger : Tone.accent,
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
