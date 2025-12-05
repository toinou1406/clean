
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aurora_widgets.dart';

class SortingIndicatorBar extends StatefulWidget {
  final String message;

  const SortingIndicatorBar({super.key, required this.message});

  @override
  State<SortingIndicatorBar> createState() => _SortingIndicatorBarState();
}

class _SortingIndicatorBarState extends State<SortingIndicatorBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Aurora Background
            CustomPaint(
              painter: AuroraPainter(
                animation: _controller,
                colors: const [
                  Color(0xFF00FFA3), // Ethereal Green
                  Color(0xFF00D4FF), // Deep Cyan
                  Color(0xFF00FFA3), // Ethereal Green
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            // Dark overlay for text readability
            Container(color: Colors.black.withOpacity(0.3)),
            // Message Text
            Center(
              child: Text(
                widget.message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
