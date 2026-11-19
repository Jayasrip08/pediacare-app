import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers.dart';

class DoctorShell extends ConsumerWidget {
  const DoctorShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(doctorStatsProvider).valueOrNull?.unreadMessages ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.line),
              ),
            ),
            child: shell,
          ),
        ),
      ),
      bottomNavigationBar: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.line),
              ),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              destinations: [
                const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard'),
                const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded),
                    label: 'Patients'),
                const NavigationDestination(
                    icon: Icon(Icons.event_repeat_outlined),
                    selectedIcon: Icon(Icons.event_repeat_rounded),
                    label: 'Follow-ups'),
                NavigationDestination(
                  icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.chat_bubble_outline_rounded)),
                  selectedIcon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.chat_bubble_rounded)),
                  label: 'Chat',
                ),
                const NavigationDestination(
                    icon: Icon(Icons.local_hospital_outlined),
                    selectedIcon: Icon(Icons.local_hospital_rounded),
                    label: 'Clinic'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
