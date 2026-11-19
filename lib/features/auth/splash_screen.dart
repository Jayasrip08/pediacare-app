import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 72),
              const SizedBox(height: 12),
              Text('Smart child healthcare',
                  style: AppText.muted.copyWith(color: Colors.white70)),
              const SizedBox(height: 40),
              if (profile.hasError && !profile.isLoading) ...[
                Text(errorMessage(profile.error!),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: Colors.white)),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Try again',
                  kind: AppButtonKind.accent,
                  expand: false,
                  onPressed: () => ref.invalidate(profileProvider),
                ),
                TextButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('Sign out', style: TextStyle(color: Colors.white70)),
                ),
              ] else
                const CircularProgressIndicator(color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
