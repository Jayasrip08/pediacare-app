import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';
import '../shared/chat_thread_view.dart';

/// Doctor's inbox: one row per child with an active conversation.
class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatThreadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Parent messages')),
      body: AsyncValueView<List<ChatThread>>(
        value: async,
        onRetry: () => ref.invalidate(chatThreadsProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              message: 'Messages from parents will appear here.',
            );
          }
          return RefreshIndicator(
            color: AppColors.orange,
            onRefresh: () async => ref.invalidate(chatThreadsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = list[i];
                return AppCard(
                  onTap: () async {
                    await context.push('/doctor/chat/${t.childId}');
                    ref.invalidate(chatThreadsProvider);
                    ref.invalidate(doctorStatsProvider);
                  },
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      InitialAvatar(name: t.childName, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.childName, style: AppText.h3),
                            const SizedBox(height: 2),
                            Text(t.lastBody ?? '',
                                style: t.unread > 0
                                    ? AppText.bodyBold
                                    : AppText.muted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(relativeDays(t.lastAt) == 'Today'
                              ? fmtTime(t.lastAt)
                              : fmtShortDate(t.lastAt),
                              style: AppText.small),
                          const SizedBox(height: 6),
                          if (t.unread > 0)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(99)),
                              child: Text('${t.unread}',
                                  style: AppText.small.copyWith(
                                      color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DoctorChatScreen extends ConsumerWidget {
  const DoctorChatScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinic = ref.watch(myClinicProvider);
    final child = ref.watch(childByIdProvider(childId));
    return Scaffold(
      appBar: AppBar(
        title: Text(child.valueOrNull?.name ?? 'Chat'),
        actions: [
          IconButton(
            tooltip: 'Open patient',
            icon: const Icon(Icons.assignment_ind_outlined),
            onPressed: () => context.push('/doctor/patient/$childId'),
          ),
        ],
      ),
      body: AsyncValueView<Clinic?>(
        value: clinic,
        data: (c) => c == null
            ? const ErrorView(message: 'No clinic found for this account.')
            : ChatThreadView(
                key: ValueKey('${c.id}-$childId'),
                chatKey: ChatKey(c.id, childId),
                myRole: UserRole.doctor,
              ),
      ),
    );
  }
}
