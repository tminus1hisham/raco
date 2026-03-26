import 'package:flutter/material.dart';
import 'package:atom/config/constants.dart';
import 'dart:math' as math;

class RadarSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final ThemeMode themeMode;

  const RadarSplashScreen({
    super.key,
    required this.nextScreen,
    required this.themeMode,
  });

  @override
  State<RadarSplashScreen> createState() => _RadarSplashScreenState();
}

class _RadarSplashScreenState extends State<RadarSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF141720) : kWhite;
    final rColor = kBlue;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Pulse between 1.0 and 1.1
            final pulseScale = 1.0 + 0.05 * math.sin(_controller.value * math.pi * 2);

            return CustomPaint(
              painter: RadarPainter(
                sweepAngle: _controller.value * 2 * math.pi,
                radarColor: rColor,
              ),
              child: SizedBox(
                width: 320,
                height: 320,
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: Transform.scale(
                      scale: pulseScale,
                      child: Image.asset(
                        'assets/orca_logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
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

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color radarColor;

  RadarPainter({required this.sweepAngle, required this.radarColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = radarColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw background grid circles
    canvas.drawCircle(center, radius, linePaint);
    canvas.drawCircle(center, radius * 0.66, linePaint);
    canvas.drawCircle(center, radius * 0.33, linePaint);
    
    // Draw crosshairs
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), linePaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), linePaint);

    // Draw the sweeping gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          radarColor.withValues(alpha: 0.0),
          radarColor.withValues(alpha: 0.1),
          radarColor.withValues(alpha: 0.4),
          radarColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.7, 0.98, 1.0],
        transform: GradientRotation(sweepAngle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, radius, sweepPaint);
    
    // Draw leading edge line
    final edgePaint = Paint()
      ..color = radarColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    // The peak of the gradient is at 0.98 of 2*pi, added to the rotation offset
    final edgeAngle = sweepAngle - math.pi / 2 + (math.pi * 2 * 0.98);
    final edgeX = center.dx + radius * math.cos(edgeAngle);
    final edgeY = center.dy + radius * math.sin(edgeAngle);
    canvas.drawLine(center, Offset(edgeX, edgeY), edgePaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle || oldDelegate.radarColor != radarColor;
}
