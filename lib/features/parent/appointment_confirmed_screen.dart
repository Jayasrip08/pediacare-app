import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';

class AppointmentConfirmedScreen extends StatefulWidget {
  const AppointmentConfirmedScreen({
    super.key,
    this.doctorName = 'Pediatrician',
    this.specialty = 'Pediatrician',
  });

  final String doctorName;
  final String specialty;

  @override
  State<AppointmentConfirmedScreen> createState() =>
      _AppointmentConfirmedScreenState();
}

class _AppointmentConfirmedScreenState extends State<AppointmentConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/parent/appointments'),
        ),
        title: Text(
          'Appointment Confirmed',
          style: AppText.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Celebratory Animated Badge (Prominent 3D PNG)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/confirmed_badge.png',
                  width: 175,
                  height: 175,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'Appointment Booked!',
                style: AppText.h1.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your appointment has been\nsuccessfully scheduled.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Appointment Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      text: 'Tue, 24 Nov 2026',
                    ),
                    const Divider(color: AppColors.line, height: 22),
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      text: '10:30 AM',
                    ),
                    const Divider(color: AppColors.line, height: 22),
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      text: '${widget.doctorName} (${widget.specialty})',
                    ),
                    const Divider(color: AppColors.line, height: 22),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      text: "Pediacare Children's Clinic\nThanjavur",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    showToast(context, 'Added to your calendar');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.lavender,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFC7D5FD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add to Calendar',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/parent/appointments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'View My Appointments',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => context.go('/parent/home'),
                  child: const Text(
                    'Back to Home Dashboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppText.bodyBold.copyWith(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
