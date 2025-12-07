import 'package:flutter/material.dart';

/// A visually engaging indicator for the photo sorting process, matching the new UI.
class SortingProgressIndicator extends StatefulWidget {
  final String message;

  const SortingProgressIndicator({super.key, required this.message});

  @override
  State<SortingProgressIndicator> createState() => _SortingProgressIndicatorState();
}

class _SortingProgressIndicatorState extends State<SortingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Indeterminate progress
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor, // Uses the card color from the theme
        borderRadius: BorderRadius.circular(16),
        // The requested grey contour
        border: Border.all(color: theme.dividerColor.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2), // Shadow at the top for a lifted feel
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AnimatedSwitcher for the message text, providing a smooth transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              widget.message,
              key: ValueKey(widget.message), // Important for the animation
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // The sleek, animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: null, // Indeterminate
              backgroundColor: theme.dividerColor.withOpacity(0.1),
              valueColor: _controller.drive(ColorTween(
                begin: theme.colorScheme.primary,
                end: theme.colorScheme.secondary,
              )),
              minHeight: 6, // A bit thicker for better visibility
            ),
          ),
        ],
      ),
    );
  }
}
