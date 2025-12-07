import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fastclean/l10n/app_localizations.dart';
import 'package:fastclean/aurora_widgets.dart'; // For PulsingIcon

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;
  final void Function(Locale) onLocaleChanged;

  const PermissionScreen({
    super.key,
    required this.onPermissionGranted,
    required this.onLocaleChanged,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with SingleTickerProviderStateMixin {
  String? _currentLanguageCode;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Set initial language from the system and start the fade-in animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    if (mounted) {
      final languageCode = Localizations.localeOf(context).languageCode;
      setState(() {
        _currentLanguageCode = languageCode;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    if (state.hasAccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permission_granted', true);
      widget.onPermissionGranted();
    } else {
      // Optionally, show a dialog or a snackbar explaining why permission is needed.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.photoAccessRequired)),
        );
      }
    }
  }

  void _changeLanguage(String languageCode) async {
    if (_currentLanguageCode == languageCode) return;

    final newLocale = Locale(languageCode);
    widget.onLocaleChanged(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    if (mounted) {
      setState(() {
        _currentLanguageCode = languageCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      // Use the NoiseBox for a consistent background texture
      body: NoiseBox(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // Pulsing icon for a modern, engaging feel
                  PulsingIcon(
                    icon: Icons.shield_outlined,
                    color: theme.colorScheme.primary,
                    size: 60,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.permissionTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.permissionDescription,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.6,
                    ),
                  ),
                  const Spacer(flex: 3),
                  // The main action button
                  ElevatedButton(
                    onPressed: _requestPermission,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 20)),
                    ),
                    child: Text(l10n.grantPermission),
                  ),
                  const SizedBox(height: 40),
                  // Language selector at the bottom
                  _buildLanguageSelector(theme, l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(ThemeData theme, AppLocalizations l10n) {
    // Ensure _currentLanguageCode is not null before building
    if (_currentLanguageCode == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          l10n.chooseYourLanguage.toUpperCase(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        // Using a segmented button for a clean, modern look
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('🇬🇧 English')),
            ButtonSegment(value: 'fr', label: Text('🇫🇷 Français')),
            ButtonSegment(value: 'es', label: Text('🇪🇸 Español')),
             ButtonSegment(value: 'zh', label: Text('🇨🇳 中文')),
          ],
          selected: {_currentLanguageCode!},
          onSelectionChanged: (newSelection) {
            _changeLanguage(newSelection.first);
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            selectedForegroundColor: theme.colorScheme.primary,
            selectedBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            side: BorderSide(color: theme.dividerColor),
          ),
        ),
      ],
    );
  }
}
