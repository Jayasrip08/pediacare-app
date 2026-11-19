import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _mode = 'Email';
  bool _signUp = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_mode == 'Phone OTP') {
        final phone = '+91${_phone.text.trim()}';
        await auth.sendOtp(phone);
        if (mounted) context.push('/otp', extra: phone);
      } else if (_signUp) {
        final res = await auth.signUpWithEmail(_email.text.trim(), _password.text);
        if (res.session == null && mounted) {
          showToast(context, 'Account created. Please confirm your email, then sign in.');
          setState(() => _signUp = false);
        }
      } else {
        await auth.signInWithEmail(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _mode == 'Phone OTP';
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          BrandHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const BrandMark(size: 60),
                const SizedBox(height: 36),
                Text('Clinical healthcare,\nall in one place.',
                    style: AppText.display.copyWith(color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  'Appointments, records, consultations and care plans - connected directly with your clinic.',
                  style: AppText.muted.copyWith(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign in or create an account', style: AppText.h2),
                  const SizedBox(height: 14),
                  ChoiceGroup<String>(
                    options: const ['Phone OTP', 'Email'],
                    selected: _mode,
                    onChanged: (v) => setState(() => _mode = v),
                    labelOf: (v) => v,
                  ),
                  const SizedBox(height: 18),
                  if (isPhone)
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixText: '+91  ',
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                      ),
                      validator: (v) =>
                          (v ?? '').length == 10 ? null : 'Enter a valid 10-digit number',
                    )
                  else ...[
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) =>
                          (v ?? '').contains('@') ? null : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').length >= 6 ? null : 'Use at least 6 characters',
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppButton(
                    label: isPhone ? 'Send OTP' : (_signUp ? 'Create account' : 'Sign in'),
                    kind: AppButtonKind.accent,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  if (!isPhone)
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _signUp = !_signUp),
                        child: Text(_signUp
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account'),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 18, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your child’s data is encrypted and shared only with your clinic, '
                          'with your consent (DPDP Act).',
                          style: AppText.small,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
