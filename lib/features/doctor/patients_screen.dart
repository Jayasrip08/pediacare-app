import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by child or parent name',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView<List<Patient>>(
              value: async,
              onRetry: () => ref.invalidate(patientsProvider),
              data: (all) {
                final list = all
                    .where((p) =>
                        _query.isEmpty ||
                        p.child.name.toLowerCase().contains(_query) ||
                        (p.child.parentName ?? '').toLowerCase().contains(_query))
                    .toList();
                if (all.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_rounded,
                    title: 'No patients yet',
                    message:
                        'Parents join your clinic by scanning the QR code on the Clinic tab.',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.orange,
                  onRefresh: () async => ref.invalidate(patientsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return AppCard(
                        onTap: () => context.push('/doctor/patient/${p.child.id}'),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            InitialAvatar(name: p.child.name, size: 48),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.child.name, style: AppText.h3),
                                  Text(
                                    '${p.child.age} · ${p.child.gender}'
                                    '${p.child.parentName == null ? '' : ' · ${p.child.parentName}'}',
                                    style: AppText.small,
                                  ),
                                  Text(
                                    p.lastVisit == null
                                        ? 'No visits yet'
                                        : 'Last visit ${fmtDate(p.lastVisit!)}',
                                    style: AppText.small,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
