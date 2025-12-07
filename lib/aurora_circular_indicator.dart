import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fastclean/photo_cleaner_service.dart';
import 'package:fastclean/l10n/app_localizations.dart';

/// A circular indicator to display device storage usage, redesigned to match the new UI.
class StorageCircularIndicator extends StatelessWidget {
  final StorageInfo storageInfo;

  const StorageCircularIndicator({super.key, required this.storageInfo});

  String _formatBytes(double bytes) {
    // Simple and effective byte formatting
    if (bytes < 1024) return "${bytes.toStringAsFixed(0)} B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final double percentage = storageInfo.usedSpace / storageInfo.totalSpace;

    return CircularPercentIndicator(
      radius: 120.0,
      lineWidth: 16.0,
      percent: percentage,
      // The clean, modern progress bar
      progressColor: theme.colorScheme.primary,
      // The subtle grey contour for the background
      backgroundColor: theme.dividerColor.withOpacity(0.1),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1200,
      // Center content with the new design
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            // Display percentage with the new font
            "${(percentage * 100).toStringAsFixed(1)}%",
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.used.toUpperCase(), // "USED"
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      // Footer text showing used/total space
      footer: Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: Text(
          "${_formatBytes(storageInfo.usedSpace)} / ${_formatBytes(storageInfo.totalSpace)}",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
