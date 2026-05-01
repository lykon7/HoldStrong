import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Pure-Dart gold pulse animation — expands a gold circle from the centre
/// with fading opacity. One-shot, sharp, no spring physics.
class GoldPulseAnimation extends StatefulWidget {
  const GoldPulseAnimation({super.key});

  @override
  State<GoldPulseAnimation> createState() => _GoldPulseAnimationState();
}

class _GoldPulseAnimationState extends State<GoldPulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _radius;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _radius = Tween<double>(begin: 0.05, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _PulsePainter(
            radiusFraction: _radius.value,
            opacity: _opacity.value,
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.radiusFraction, required this.opacity});

  final double radiusFraction;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        (size.width > size.height ? size.width : size.height) * radiusFraction;

    final paint = Paint()
      ..color = AppColors.accentGold.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(centre, maxRadius, paint);
  }

  @override
  bool shouldRepaint(_PulsePainter old) =>
      old.radiusFraction != radiusFraction || old.opacity != opacity;
}
