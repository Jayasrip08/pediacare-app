import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

class PediaCareApp extends ConsumerWidget {
  const PediaCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PediaCare',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Shown when SUPABASE_URL / SUPABASE_ANON_KEY were not provided at build time.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest_rounded, size: 56, color: AppColors.orange),
                const SizedBox(height: 16),
                Text('Supabase is not configured', style: AppText.h1, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Run the app with\n--dart-define-from-file=env.json\n(see env.example.json and README).',
                  style: AppText.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
