import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

/// Horizontal child switcher.
class ChildChips extends ConsumerWidget {
  const ChildChips({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).valueOrNull ?? const <Child>[];
    final selected = ref.watch(selectedChildProvider).valueOrNull;

    Widget pill({
      required String label,
      required bool active,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      final bg = active
          ? AppColors.orange
          : (dark ? AppColors.navyLight : Colors.white);
      final fg = active || dark ? Colors.white : AppColors.ink;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border:
                    dark || active ? null : Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6)
                  ],
                  Text(label,
                      style:
                          AppText.bodyBold.copyWith(color: fg, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            dark ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final c in children)
            pill(
              label: '${c.name.split(' ').first} · ${c.age}',
              active: c.id == selected?.id,
              onTap: () =>
                  ref.read(selectedChildIdProvider.notifier).state = c.id,
            ),
          pill(
            label: 'Add child',
            icon: Icons.add_rounded,
            active: false,
            onTap: () => context.push('/parent/add-child'),
          ),
        ],
      ),
    );
  }
}

/// Scaffold for parent tabs that operate on the currently selected child.
class ChildScope extends ConsumerWidget {
  const ChildScope({
    super.key,
    required this.title,
    required this.builder,
    this.actions,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget Function(BuildContext context, Child child) builder;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChildProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/parent/home'),
        ),
        title: Text(title),
        actions: actions,
      ),
      body: AsyncValueView<Child?>(
        value: selected,
        onRetry: () => ref.invalidate(childrenProvider),
        data: (child) {
          if (child == null) {
            return EmptyState(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Add patient profile',
              message: 'Add a patient profile to view $title.',
              actionLabel: 'Add profile',
              onAction: () => context.push('/parent/add-child'),
            );
          }
          final many =
              (ref.watch(childrenProvider).valueOrNull?.length ?? 0) > 1;
          return Column(
            children: [
              if (many) ...[const ChildChips(), const SizedBox(height: 8)],
              Expanded(child: builder(context, child)),
            ],
          );
        },
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
