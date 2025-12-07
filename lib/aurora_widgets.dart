import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that applies a subtle, animated noise texture as a background.
/// This adds a premium, tactile feel to the UI, inspired by the design brief.
class NoiseBox extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final double borderRadius;

  const NoiseBox({
    super.key,
    this.child,
    this.padding,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Solid background color
          Container(color: backgroundColor),
          // The subtle noise texture, tiled across the widget
          // This is a more modern and performant approach than a custom painter.
          Opacity(
            opacity: 0.05, // Keep it subtle
            child: Image.asset(
              'assets/images/noise.png', // Ensure this image is in your assets
              repeat: ImageRepeat.repeat,
              fit: BoxFit.cover,
            ),
          ),
          // The actual content
          if (child != null)
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
        ],
      ),
    );
  }
}

/// A simple, pulsing icon widget to draw attention in a subtle, polished way.
class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const PulsingIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 24.0,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? Theme.of(context).colorScheme.secondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            widget.icon,
            color: iconColor,
            size: widget.size,
            shadows: [
              // A soft glow effect using shadows, matching the new design language
              BoxShadow(
                color: iconColor.withOpacity(0.5),
                blurRadius: 12.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
        );
      },
    );
  }
}
