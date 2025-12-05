
import 'package:flutter/material.dart';
import 'aurora_widgets.dart';

class SavedSpaceIndicator extends StatelessWidget {
  final double spaceSaved;
  final String formattedSpaceSaved;

  const SavedSpaceIndicator({
    super.key,
    required this.spaceSaved,
    required this.formattedSpaceSaved,
  });

  @override
  Widget build(BuildContext context) {
    // This is a mock value, it will be replaced with the actual value
    double maxMonthlyGoal = 5 * 1024 * 1024 * 1024; // 5 GB
    double progress = (spaceSaved / maxMonthlyGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Small padding for alignment
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Space Saved (This Month)', style: Theme.of(context).textTheme.titleMedium),
              Text(formattedSpaceSaved, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AuroraLinearProgressIndicator(progress: progress),
      ],
    );
  }
}
