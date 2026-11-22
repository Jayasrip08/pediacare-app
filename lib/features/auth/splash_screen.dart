import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _subtitleSlideAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 1. Logo slide-in from top with smooth spring bounce
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // 2. Title slide-in from bottom
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
      ),
    );

    // 3. Subtitle subtle slide up & fade
    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    // Wave motion animation
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // Auto-navigate to Onboarding flow after splash presentation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });
  }

  void _proceed() {
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceed,
        child: Stack(
          children: [
            // Top soft subtle glow
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft.withValues(alpha: 0.6),
                ),
              ),
            ),

            // Bottom animated wavy background matching design
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: _SplashWavesPainter(progress: _waveAnimation.value),
                  );
                },
              ),
            ),

            // Center Content: Logo + App Name + Subtitle
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Sliding 3D Logo Icon (Twin Smiling Faces)
                    SlideTransition(
                      position: _logoSlideAnimation,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Image.asset(
                          'assets/images/logo_icon.png',
                          width: 154,
                          height: 82,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Sliding Authentic Brand Wordmark "Pediacare" with Mint Smile Underline
                    SlideTransition(
                      position: _titleSlideAnimation,
                      child: FadeTransition(
                        opacity: _titleFadeAnimation,
                        child: Image.asset(
                          'assets/images/logo_wordmark.png',
                          width: 175,
                          height: 58,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Sliding Subtitle
                    SlideTransition(
                      position: _subtitleSlideAnimation,
                      child: FadeTransition(
                        opacity: _subtitleFadeAnimation,
                        child: Text(
                          'Complete Child Health Care\nfor Every Stage',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: AppColors.muted,
                            height: 1.45,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom subtle indicator pill
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the layered soft cyan/lavender/blue waves at the bottom of the splash screen
class _SplashWavesPainter extends CustomPainter {
  const _SplashWavesPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Back Wave (Mint Green #36C6B0)
    final p1 = Paint()
      ..color = AppColors.mint.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.quadraticBezierTo(
      w * 0.35,
      h * 0.25 + math.sin(progress) * 8,
      w * 0.7,
      h * 0.55,
    );
    path1.quadraticBezierTo(w * 0.88, h * 0.7, w, h * 0.5);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, p1);

    // Layer 2: Middle Wave (Soft Lavender #E9EDFF)
    final p2 = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, h * 0.6);
    path2.quadraticBezierTo(
      w * 0.25,
      h * 0.4 + math.cos(progress) * 6,
      w * 0.6,
      h * 0.65,
    );
    path2.quadraticBezierTo(w * 0.85, h * 0.8, w, h * 0.65);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, p2);

    // Layer 3: Front Wave (Primary Blue & Lavender gradient)
    final p3 = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.35),
          AppColors.lavender.withValues(alpha: 0.7),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    final path3 = Path();
    path3.moveTo(0, h * 0.75);
    path3.quadraticBezierTo(
      w * 0.4,
      h * 0.6 + math.sin(progress + 1) * 6,
      w * 0.75,
      h * 0.85,
    );
    path3.quadraticBezierTo(w * 0.9, h * 0.95, w, h * 0.82);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, p3);
  }

  @override
  bool shouldRepaint(covariant _SplashWavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
