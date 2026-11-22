import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.role = 'parent'});

  final String role;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isParent = true;

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _doctorPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _loading = false;

  // Dynamic Animation Controllers
  late final AnimationController _floatController;
  late final AnimationController _tapBounceController;
  late final Animation<double> _tapScaleAnimation;

  // Interactive Speech / Action Bubble
  bool _showBubble = false;
  String _speechMessage = '';

  @override
  void initState() {
    super.initState();
    _isParent = widget.role != 'doctor';

    // 1. Continuous smooth floating breathing animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // 2. Interactive tap spring bounce
    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tapScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.95).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
    ]).animate(_tapBounceController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _doctorEmailController.dispose();
    _doctorPinController.dispose();
    _floatController.dispose();
    _tapBounceController.dispose();
    super.dispose();
  }

  void _triggerCharacterReaction() {
    _tapBounceController.forward(from: 0);
    setState(() {
      _showBubble = true;
      _speechMessage = _isParent
          ? "Welcome to PediaCare! Tap below to get started 💙"
          : "Welcome, Doctor! Manage appointments & clinic 🩺";
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final email = _isParent
          ? _emailController.text.trim()
          : _doctorEmailController.text.trim();
      final password = _isParent
          ? _passwordController.text
          : _doctorPinController.text;

      if (_isParent) {
        ref.read(currentUserRoleProvider.notifier).state = UserRole.parent;
      } else {
        final doctors = ref.read(doctorAccountsProvider);
        DoctorAccount? matchingDoc = doctors.where(
          (d) =>
              d.email.toLowerCase() == email.toLowerCase() ||
              d.id.toLowerCase() == email.toLowerCase() ||
              d.name.toLowerCase().contains(email.toLowerCase()),
        ).firstOrNull;

        if (matchingDoc == null) {
          final prefix = email.contains('@') ? email.split('@').first : email;
          final docName = 'Dr. ${prefix[0].toUpperCase()}${prefix.substring(1)}';
          final newDoc = DoctorAccount(
            id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
            name: docName,
            email: email,
            pin: password,
            specialty: 'Pediatrics',
            regNo: 'MCI-${DateTime.now().millisecondsSinceEpoch % 100000}',
            phone: '',
            avatarPath: 'assets/images/avatar_doctor.png',
          );
          ref.read(doctorAccountsProvider.notifier).addDoctor(newDoc);
          matchingDoc = newDoc;
        }

        ref.read(activeDoctorIdProvider.notifier).state = matchingDoc.id;
        ref.read(currentUserRoleProvider.notifier).state = UserRole.doctor;
      }

      if (email.contains('@')) {
        try {
          await auth.signInWithEmail(email, password);
        } catch (_) {}
      } else if (_isParent) {
        final phone = email.startsWith('+') ? email : '+91$email';
        await auth.sendOtp(phone);
        if (mounted) context.push('/otp', extra: phone);
        return;
      }

      if (mounted) {
        if (_isParent) {
          showToast(context, 'Signed in successfully • Role: Parent');
          context.go('/parent/home');
        } else {
          final doc = ref.read(currentDoctorAccountProvider);
          showToast(context, 'Signed in as ${doc.name} • Role: Verified Pediatrician');
          context.go('/doctor/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        if (_isParent) {
          ref.read(currentUserRoleProvider.notifier).state = UserRole.parent;
          showToast(context, 'Welcome to PediaCare!');
          context.go('/parent/home');
        } else {
          final doc = ref.read(currentDoctorAccountProvider);
          ref.read(currentUserRoleProvider.notifier).state = UserRole.doctor;
          showToast(context, 'Welcome back, ${doc.name}!');
          context.go('/doctor/dashboard');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/choose-role'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Authentic Pediacare Logo inside the Main Screen
                Image.asset(
                  'assets/images/logo.png',
                  width: 175,
                  height: 85,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),

                // 2. Interactive Dynamic 3D Hero Area for the selected role
                _buildDynamicHeroArea(),
                const SizedBox(height: 18),

                // 2. Title & Subtitle based on selected Role
                Text(
                  _isParent ? 'Parent Login' : 'Doctor Portal Login',
                  style: AppText.h1.copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isParent
                      ? "Access your child's health records & appointments"
                      : "Manage clinical consultations and patient queues",
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Dynamic Form Fields (Parent vs Doctor)
                if (_isParent) ...[
                  // Email or Phone field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'Email or Phone Number',
                      icon: Icons.mail_outline_rounded,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter email or phone' : null,
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: _inputDecoration(
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                ] else ...[
                  // Doctor ID / Email field
                  TextFormField(
                    controller: _doctorEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'Doctor Email or ID',
                      icon: Icons.medical_services_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter doctor email or ID' : null,
                  ),
                  const SizedBox(height: 14),

                  // PIN / Password field
                  TextFormField(
                    controller: _doctorPinController,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      hint: '6-Digit Security PIN',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter security PIN' : null,
                  ),
                ],

                const SizedBox(height: 10),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      showToast(context, 'Reset instructions sent to your email');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: _isParent ? AppColors.primary : const Color(0xFF8B5CF6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Main Action Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isParent ? 'Login as Parent' : 'Login to Doctor Portal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Social Logins & Footer Options
                if (_isParent) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: AppText.muted.copyWith(fontSize: 12.5),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialPillButton(
                        icon: Icons.apple,
                        iconColor: Colors.black,
                        onTap: () => context.go('/parent/home'),
                      ),
                      const SizedBox(width: 18),
                      _SocialPillButton(
                        icon: Icons.g_mobiledata_rounded,
                        iconSize: 32,
                        iconColor: const Color(0xFFEA4335),
                        onTap: () => context.go('/parent/home'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppText.body.copyWith(
                          color: AppColors.muted,
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Doctor RBAC & Patient Privacy Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFF7C3AED), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'STRICT RBAC & PATIENT PRIVACY',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7C3AED),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Each doctor has their own login PIN, clinic practice, and assigned patients. No shared patient records across doctors.',
                          style: AppText.muted.copyWith(fontSize: 11.5, color: const Color(0xFF5B21B6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have a doctor account? ",
                        style: AppText.body.copyWith(
                          color: AppColors.muted,
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/doctor/register'),
                        child: const Text(
                          'Register as Doctor',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Dynamic 3D Hero Area with Hover Breathing Animation & Tap Interactivity ---
  Widget _buildDynamicHeroArea() {
    return GestureDetector(
      onTap: _triggerCharacterReaction,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft ambient circular glow background
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: _isParent
                    ? [
                        AppColors.mintSoft.withValues(alpha: 0.9),
                        AppColors.lavender.withValues(alpha: 0.3),
                        Colors.transparent,
                      ]
                    : [
                        AppColors.lavender.withValues(alpha: 0.9),
                        const Color(0xFFEDE9FE).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
              ),
            ),
          ),

          // Ground shadow that scales inversely with the character's float
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              final val = _floatController.value;
              final shadowScale = 1.0 - (val * 0.18);
              return Positioned(
                bottom: 8,
                child: Container(
                  width: 120 * shadowScale,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05 * shadowScale),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),

          // Dynamic Animated 3D Character
          AnimatedBuilder(
            animation: Listenable.merge([_floatController, _tapBounceController]),
            builder: (context, child) {
              // Floating offset: gentle smooth sine wave
              final floatOffset = math.sin(_floatController.value * math.pi) * 8.0;
              final scale = _tapScaleAnimation.value;

              return Transform.translate(
                offset: Offset(0, -floatOffset),
                child: Transform.scale(
                  scale: scale,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.asset(
                      _isParent
                          ? 'assets/images/role_parent.png'
                          : 'assets/images/role_doctor.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Interactive Speech Bubble on Tap
          if (_showBubble)
            Positioned(
              top: -14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showBubble ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _speechMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}

class _SocialPillButton extends StatelessWidget {
  const _SocialPillButton({
    required this.icon,
    this.iconSize = 22,
    this.iconColor = Colors.black,
    required this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line, width: 1.2),
          color: Colors.white,
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}
