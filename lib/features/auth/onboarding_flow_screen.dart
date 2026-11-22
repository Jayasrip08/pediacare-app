import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Complete Healthcare\nfor Your Child',
      subtitle:
          'Book appointments, track growth,\nmanage vaccinations and more —\nall in one place.',
      imagePath: 'assets/images/onboarding_care.png',
      tags: ['Growth Milestones', 'Vaccine Alerts', 'Trusted Care'],
    ),
    _OnboardingItem(
      title: 'Expert Pediatric Care\nAlways Nearby',
      subtitle:
          'Connect with trusted pediatricians\nand multiple specialists for\nholistic child care.',
      imagePath: 'assets/images/onboarding_doctor.png',
      tags: ['Verified Specialists', 'Instant Booking', 'Teleconsult'],
    ),
    _OnboardingItem(
      title: 'All Health Records\nin One Place',
      subtitle:
          'Securely store your child\'s medical\nhistory, reports and prescriptions\nanytime, anywhere.',
      imagePath: 'assets/images/onboarding_records.png',
      tags: ['Digital Prescriptions', 'Lab Reports', '100% Encrypted'],
    ),
  ];

  void _onSkip() {
    context.go('/choose-role');
  }

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/choose-role');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo inside Main Screen
                        const BrandMark(size: 32, showName: true, light: false),
                        const SizedBox(height: 8),

                        // Adaptive Illustration with Ambient Radial Glow
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Soft ambient circular backdrop
                                    Container(
                                      width: 290,
                                      height: 290,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            AppColors.lavender.withValues(alpha: 0.7),
                                            AppColors.mintSoft.withValues(alpha: 0.4),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    // 3D PNG Image
                                    Image.asset(
                                      item.imagePath,
                                      width: 330,
                                      height: 330,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppText.h1.copyWith(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: AppColors.muted,
                            height: 1.4,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Value highlight pill tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: item.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lavender.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
              child: _currentPage == _items.length - 1
                  ? SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Smooth animated dots
                        Row(
                          children: List.generate(_items.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              width: isActive ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.line,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),

                        // Circular Next Button
                        InkWell(
                          onTap: _onNext,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.tags,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final List<String> tags;
}
