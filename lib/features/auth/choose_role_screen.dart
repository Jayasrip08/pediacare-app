import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // --- TOP HERO SECTION (Fills upper space with rich visuals & branding) ---
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 1. Authentic Pediacare Logo inside Main Screen
                              Image.asset(
                                'assets/images/logo.png',
                                width: 170,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 14),

                              // 2. 3D Hero Illustration with Soft Ambient Glow
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 175,
                                    height: 175,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.lavender.withValues(alpha: 0.8),
                                          AppColors.mintSoft.withValues(alpha: 0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/images/parent_family.png',
                                    width: 155,
                                    height: 155,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Headline & Tagline
                              Text(
                                'Welcome to Pediacare',
                                textAlign: TextAlign.center,
                                style: AppText.h1.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Complete child health care for every family & clinic.\nConnect with pediatricians or manage your care.',
                                textAlign: TextAlign.center,
                                style: AppText.body.copyWith(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Trust proof chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: const [
                                  _TrustChip(
                                    icon: Icons.star_rounded,
                                    label: '4.9 ★ Rating',
                                    color: Color(0xFFF59E0B),
                                  ),
                                  _TrustChip(
                                    icon: Icons.verified_user_rounded,
                                    label: 'Verified Doctors',
                                    color: AppColors.primary,
                                  ),
                                  _TrustChip(
                                    icon: Icons.family_restroom_rounded,
                                    label: '10K+ Families',
                                    color: AppColors.mint,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      // --- BOTTOM SPLIT SECTION (Brings Role Cards to the Bottom) ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          border: Border(
                            top: BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.line,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Heading
                            Text(
                              'Choose Your Role',
                              style: AppText.h2.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Select your profile to continue with Pediacare',
                              style: AppText.muted.copyWith(fontSize: 12.5),
                            ),
                            const SizedBox(height: 16),

                            // Role Card 1: Parent
                            _RoleCard(
                              title: "I'm a Parent",
                              subtitle: "Manage my child's health,\nappointments and records.",
                              imagePath: 'assets/images/role_parent.png',
                              accentColor: AppColors.mint,
                              bgColor: AppColors.mintSoft,
                              borderColor: AppColors.mint.withValues(alpha: 0.35),
                              onTap: () => context.go('/login?role=parent'),
                            ),
                            const SizedBox(height: 12),

                            // Role Card 2: Doctor
                            _RoleCard(
                              title: "I'm a Doctor",
                              subtitle: "Run my clinic, manage\npatients and provide care.",
                              imagePath: 'assets/images/role_doctor.png',
                              accentColor: AppColors.primary,
                              bgColor: AppColors.lavender,
                              borderColor: AppColors.lavenderDark.withValues(alpha: 0.35),
                              onTap: () => context.go('/login?role=doctor'),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => context.push('/doctor/register'),
                                icon: const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF7C3AED)),
                                label: const Text(
                                  'New Doctor? Register with Clinic Join Code',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Character Illustration (Prominent 3D PNG)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  width: 82,
                  height: 82,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.h2.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppText.muted.copyWith(
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Arrow Button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
