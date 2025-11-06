import 'dart:math' as math;
import 'package:flutter/material.dart';

class HexagonPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HexagonPainter({
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw hexagon
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexagonPainter oldDelegate) {
    return color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
  }
}

class AnimatedHexagonBackground extends StatefulWidget {
  final Widget child;

  const AnimatedHexagonBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedHexagonBackground> createState() =>
      _AnimatedHexagonBackgroundState();
}

class _AnimatedHexagonBackgroundState
    extends State<AnimatedHexagonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: HexagonGridPainter(
            animationValue: _animation.value,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class HexagonGridPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;

  HexagonGridPainter({
    required this.animationValue,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const hexSize = 80.0;
    const spacing = hexSize * 1.5;

    // Create grid of hexagons
    for (double y = -spacing; y < size.height + spacing; y += spacing * 0.75) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final offsetX = (y % (spacing * 1.5) == 0) ? x : x + spacing / 2;
        
        // Calculate distance from center for fade effect
        final centerX = size.width / 2;
        final centerY = size.height / 2;
        final distance = math.sqrt(
          math.pow(offsetX - centerX, 2) + math.pow(y - centerY, 2),
        );
        final maxDistance = math.sqrt(
          math.pow(size.width, 2) + math.pow(size.height, 2),
        ) / 2;
        final opacity = (1 - (distance / maxDistance)).clamp(0.0, 0.3);

        // Animate opacity based on position and time
        final animatedOpacity = (opacity *
                (0.5 + 0.5 * math.sin(animationValue + distance / 50)))
            .clamp(0.05, 0.3);

        paint.color = primaryColor.withValues(alpha: animatedOpacity);

        _drawHexagon(canvas, Offset(offsetX, y), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexagonGridPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        primaryColor != oldDelegate.primaryColor;
  }
}

class FloatingHexagon extends StatefulWidget {
  final Color color;
  final double size;
  final Offset startPosition;
  final Duration duration;

  const FloatingHexagon({
    super.key,
    required this.color,
    required this.size,
    required this.startPosition,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<FloatingHexagon> createState() => _FloatingHexagonState();
}

class _FloatingHexagonState extends State<FloatingHexagon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    final random = math.Random();
    _xAnimation = Tween<double>(
      begin: widget.startPosition.dx,
      end: widget.startPosition.dx + (random.nextDouble() - 0.5) * 200,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _yAnimation = Tween<double>(
      begin: widget.startPosition.dy,
      end: widget.startPosition.dy + (random.nextDouble() - 0.5) * 200,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.6),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _xAnimation.value,
          top: _yAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: HexagonPainter(
                  color: widget.color,
                  strokeWidth: 2.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

