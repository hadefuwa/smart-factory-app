import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation (zoom in effect)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotation animation (subtle spin)
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOut),
    );

    // Pulse animation (breathing effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Glow animation (shimmer effect)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade in
    _fadeController.forward();

    // Start scale animation slightly delayed
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();

    // Start rotation
    await Future.delayed(const Duration(milliseconds: 100));
    _rotationController.forward();

    // Start pulse (repeat)
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseController.repeat(reverse: true);

    // Start glow (repeat)
    await Future.delayed(const Duration(milliseconds: 200));
    _glowController.repeat(reverse: true);

    // Wait for main animations to complete, then navigate
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              const Color(0xFF1A1A2E).withValues(alpha: 0.8),
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeAnimation,
              _scaleAnimation,
              _rotationAnimation,
              _pulseAnimation,
              _glowAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: _glowAnimation.value * 0.6),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 10 * _glowAnimation.value,
                          ),
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: _glowAnimation.value * 0.3),
                            blurRadius: 60 * _glowAnimation.value,
                            spreadRadius: 20 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/logo2.svg',
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.height * 0.15,
                        colorFilter: ColorFilter.mode(
                          Color.lerp(
                            Colors.white,
                            Theme.of(context).colorScheme.primary,
                            _glowAnimation.value * 0.3,
                          )!,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

