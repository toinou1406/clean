
import 'dart:math';
import 'package:flutter/material.dart';

// --- Core Aurora Animation Logic ---

class AuroraPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;
  final List<double> stops;

  AuroraPainter({required this.animation, required this.colors, required this.stops}) 
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        stops: stops,
        transform: GradientRotation(animation.value * 2 * pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant AuroraPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}

// --- Aurora Themed Widgets ---

class AuroraBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;

  const AuroraBorder({
    super.key,
    required this.child,
    this.borderWidth = 3.0,
    required this.borderRadius,
  });

  @override
  State<AuroraBorder> createState() => _AuroraBorderState();
}

class _AuroraBorderState extends State<AuroraBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraBorderPainter(
        animation: _controller,
        borderRadius: widget.borderRadius,
        borderWidth: widget.borderWidth,
      ),
      child: widget.child,
    );
  }
}

class _AuroraBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final BorderRadius borderRadius;
  final double borderWidth;

  final List<Color> _colors = const [
    Color(0xFF00FFA3), // Ethereal Green
    Color(0xFF00D4FF), // Deep Cyan
    Color(0xFF00FFA3), // Ethereal Green
  ];

  final List<double> _stops = const [0.0, 0.5, 1.0];

  _AuroraBorderPainter({
    required this.animation,
    required this.borderRadius,
    required this.borderWidth,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = LinearGradient(
              colors: _colors,
              stops: _stops,
              transform: GradientRotation(animation.value * 2 * pi),
            ).createShader(rect);

    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraBorderPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}


class AuroraLinearProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0

  const AuroraLinearProgressIndicator({super.key, required this.progress});

  @override
  State<AuroraLinearProgressIndicator> createState() =>
      _AuroraLinearProgressIndicatorState();
}

class _AuroraLinearProgressIndicatorState extends State<AuroraLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(color: Colors.white.withOpacity(0.15)),
            FractionallySizedBox(
              widthFactor: widget.progress,
              child: CustomPaint(
                painter: AuroraPainter(
                  animation: _controller,
                  colors: const [
                    Color(0xFF00FFA3), // Ethereal Green
                    Color(0xFF00D4FF), // Deep Cyan
                    Color(0xFF00FFA3), // Ethereal Green
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
