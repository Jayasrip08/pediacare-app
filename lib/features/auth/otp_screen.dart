import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _seconds = _seconds - 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(widget.phone, _code.text);
      // Router redirect takes over once the session is established.
    } catch (e) {
      if (mounted) {
        _code.clear();
        showToast(context, errorMessage(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).sendOtp(widget.phone);
      _startTimer();
      if (mounted) showToast(context, 'OTP sent again');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your number', style: AppText.display),
              const SizedBox(height: 10),
              Text('Enter the 6-digit code sent to ${widget.phone}', style: AppText.muted),
              const SizedBox(height: 32),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.display.copyWith(letterSpacing: 14, fontSize: 32),
                decoration: const InputDecoration(counterText: '', hintText: '------'),
                onChanged: (v) {
                  setState(() {});
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Verify & continue',
                kind: AppButtonKind.accent,
                loading: _loading,
                onPressed: _code.text.length == 6 ? _verify : null,
              ),
              const SizedBox(height: 12),
              Center(
                child: _seconds > 0
                    ? Text('Resend code in ${_seconds}s', style: AppText.muted)
                    : TextButton(onPressed: _resend, child: const Text('Resend code')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
