import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

/// Shared profile screen for parent and doctor.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            child: Row(
              children: [
                InitialAvatar(name: profile?.fullName ?? '?', size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.fullName ?? '', style: AppText.h2),
                      const SizedBox(height: 2),
                      Text(profile?.phone == null ? '' : '+${profile!.phone}', style: AppText.muted),
                      const SizedBox(height: 6),
                      StatusPill(profile?.role.name == 'doctor' ? 'Doctor' : 'Parent',
                          tone: Tone.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (children.isNotEmpty) ...[
            const SectionHeader('My children'),
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      InitialAvatar(name: c.name),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: AppText.h3),
                            Text('${c.age} · born ${fmtDate(c.dob)}', style: AppText.small),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SectionHeader('Privacy & support'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your child’s records are encrypted in transit and at rest, and visible only to you '
                  'and the clinic you connect with. PediaCare gives guidance only - never a diagnosis.',
                  style: AppText.small,
                ),
                const SizedBox(height: 10),
                Text('Support: ${AppConfig.supportEmail}', style: AppText.bodyBold),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            kind: AppButtonKind.outline,
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: 'Sign out?', message: 'You can sign back in any time.', confirmLabel: 'Sign out');
              if (ok) {
                ref.read(selectedChildIdProvider.notifier).state = null;
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
