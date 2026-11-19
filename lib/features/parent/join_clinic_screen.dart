import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class JoinClinicScreen extends ConsumerStatefulWidget {
  const JoinClinicScreen({super.key});

  @override
  ConsumerState<JoinClinicScreen> createState() => _JoinClinicScreenState();
}

class _JoinClinicScreenState extends ConsumerState<JoinClinicScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _clean(String raw) {
    var v = raw.trim();
    if (v.toUpperCase().startsWith(AppConfig.clinicQrPrefix)) {
      v = v.substring(AppConfig.clinicQrPrefix.length);
    }
    return v.toUpperCase();
  }

  Future<void> _join(String raw) async {
    final child = ref.read(selectedChildProvider).valueOrNull;
    if (child == null) {
      showToast(context, 'Add a child first', error: true);
      return;
    }
    final code = _clean(raw);
    if (code.length < 4 || _busy) return;
    setState(() => _busy = true);
    try {
      final clinic = await ref.read(clinicRepositoryProvider).joinClinic(code, child.id);
      ref.invalidate(childClinicProvider(child.id));
      if (mounted) {
        context.pop();
        showToast(context, '${child.name} is now connected to ${clinic.name}');
      }
    } catch (e) {
      if (mounted) {
        showToast(context, errorMessage(e), error: true);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect your clinic')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text('Scan the QR code displayed at your pediatrician’s clinic.', style: AppText.muted),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final raw = capture.barcodes.firstOrNull?.rawValue;
                      if (raw != null && raw.toUpperCase().startsWith(AppConfig.clinicQrPrefix)) {
                        _join(raw);
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.orange, width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  if (_busy)
                    Container(color: Colors.black45, child: const LoadingView()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or enter clinic code', style: AppText.small),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: AppText.h1.copyWith(letterSpacing: 4),
            decoration: const InputDecoration(hintText: 'CLINIC CODE'),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Connect',
            kind: AppButtonKind.accent,
            loading: _busy,
            onPressed: () => _join(_code.text),
          ),
        ],
      ),
    );
  }
}
