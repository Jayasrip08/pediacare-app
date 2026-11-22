import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import '../shared/chat_thread_view.dart';
import '../shared/growth_view.dart';
import '../shared/records_view.dart';
import '../shared/vaccines_view.dart';
import 'child_scope.dart';
import 'parent_bottom_nav.dart';

class ParentVaccinesScreen extends StatelessWidget {
  const ParentVaccinesScreen({super.key});

  @override
  Widget build(BuildContext context) => ChildScope(
        title: 'Vaccine tracker',
        builder: (_, child) => VaccinesView(childId: child.id),
      );
}

class ParentGrowthScreen extends StatelessWidget {
  const ParentGrowthScreen({super.key});

  @override
  Widget build(BuildContext context) => ChildScope(
        title: 'Growth',
        builder: (_, child) => GrowthView(key: ValueKey(child.id), child: child),
      );
}

class ParentRecordsScreen extends StatelessWidget {
  const ParentRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChildScope(
        title: 'Reports & documents',
        builder: (_, child) => RecordsView(childId: child.id),
        bottomNavigationBar: const ParentBottomNav(currentIndex: 3),
      );
}

class ParentChatScreen extends ConsumerWidget {
  const ParentChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChildScope(
      title: 'Doctor chat',
      builder: (context, child) {
        final clinic = ref.watch(childClinicProvider(child.id));
        return AsyncValueView<Clinic?>(
          value: clinic,
          onRetry: () => ref.invalidate(childClinicProvider(child.id)),
          data: (c) {
            if (c == null) {
              return EmptyState(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Connect your clinic',
                message: 'Scan the QR code at your pediatrician’s clinic to chat with the doctor.',
                actionLabel: 'Scan clinic QR',
                onAction: () => context.push('/parent/join-clinic'),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                Expanded(
                  child: ChatThreadView(
                    key: ValueKey('${c.id}-${child.id}'),
                    chatKey: ChatKey(c.id, child.id),
                    myRole: UserRole.parent,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
