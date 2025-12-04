
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'photo_cleaner_service.dart'; // For StorageInfo

class AuroraCircularIndicator extends StatefulWidget {
  final StorageInfo storageInfo;

  const AuroraCircularIndicator({super.key, required this.storageInfo});

  @override
  State<AuroraCircularIndicator> createState() =>
      _AuroraCircularIndicatorState();
}

class _AuroraCircularIndicatorState extends State<AuroraCircularIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Controller for the fill animation of the progress bar
    _progressController = AnimationController(
      duration: const Duration(seconds: 1, milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    // Controller for the continuous rotation of the gradient
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _progressController.forward();
  }

  @override
  void didUpdateWidget(AuroraCircularIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.storageInfo.usedPercentage != oldWidget.storageInfo.usedPercentage) {
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _rotationController]),
      builder: (context, child) {
        final animatedPercentage = _progressAnimation.value * widget.storageInfo.usedPercentage / 100;

        return CustomPaint(
          painter: _AuroraPainter(
            percentage: animatedPercentage,
            rotation: _rotationController.value * 2 * pi,
          ),
          child: SizedBox(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(animatedPercentage * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Storage Used',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double percentage;
  final double rotation;

  _AuroraPainter({required this.percentage, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    const double strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF00FFA3), // Ethereal Green (starts here)
          Color(0xFF00D4FF), // Deep Cyan
          Color(0xFF00FFA3), // Ethereal Green (ends here, creating a loop)
        ],
        stops: const [0.0, 0.5, 1.0], // Green at both ends, Cyan in the middle
        transform: GradientRotation(rotation),
        tileMode: TileMode.repeated,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi, // Full circle background
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * percentage,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.rotation != rotation;
  }
}
