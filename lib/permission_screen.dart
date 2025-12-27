import 'dart:developer' as developer;
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

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _currentLanguageCode;
  late AnimationController _fadeController;

  // State flags to manage the permission request flow
  bool _isResumingFromSettings = false;
  bool _hasAttemptedRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isResumingFromSettings) {
      _isResumingFromSettings = false; // Reset flag
      
      // Automatically re-check permission after returning from settings.
      // Add a small delay to ensure the OS has updated the permission state.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _handleSilentPermissionCheck();
        }
      });
    }
  }

  /// This is the main entry point when the user clicks the button.
  Future<void> _handlePermissionRequest() async {
    // We call requestPermissionExtend primarily for its side-effect of showing
    // the OS permission dialog if the status is undetermined.
    await PhotoManager.requestPermissionExtend();

    // After the dialog is dismissed, we use getAssetPathList to reliably check
    // the actual, current permission state, as this has proven to work
    // in the resume-from-settings flow.
    try {
      // According to docs, this throws if permission is not granted.
      await PhotoManager.getAssetPathList();

      // If we get here without an exception, permission has been granted.
      _grantAccess();
    } catch (e) {
      // If getAssetPathList throws, it means we definitely don't have access.
      // Now we apply the logic to either do nothing or go to settings.
      if (_hasAttemptedRequest) {
        // This is the second time we've ended up here, so guide to settings.
        _isResumingFromSettings = true;
        await PhotoManager.openSetting();
      } else {
        // This was the first failed attempt. Just set the flag and let the user try again.
        if (mounted) {
          setState(() {
            _hasAttemptedRequest = true;
          });
        }
      }
    }
  }

  /// This function is for silent checks when returning from settings.
  /// It uses `getAssetPathList` which, per documentation, should throw an
  /// error if permission is not granted.
  Future<void> _handleSilentPermissionCheck() async {
    developer.log("Checking permission status on resume...");
    try {
      await PhotoManager.getAssetPathList();
      developer.log("Permission check successful (getAssetPathList did not throw). Granting access.");
      _grantAccess();
    } catch (e, s) {
      developer.log("Permission check failed, user likely did not grant permission in settings.", name: 'permission.error', error: e, stackTrace: s);
      // If it fails, do nothing. The user remains on the screen.
    }
  }

  void _grantAccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_granted', true);
    if (mounted) {
      widget.onPermissionGranted();
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
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
                  const Spacer(flex: 1),
                  _buildLanguageSelector(theme, l10n),
                  const Spacer(flex: 1),
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
                      color:
                          theme.colorScheme.onSurface.withAlpha(179), // ~0.7 opacity
                      height: 1.6,
                    ),
                  ),
                  const Spacer(flex: 3),
                  ElevatedButton(
                    onPressed: _handlePermissionRequest,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 20)),
                    ),
                    child: Text(l10n.grantPermission),
                  ),
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
    if (_currentLanguageCode == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          l10n.chooseYourLanguage.toUpperCase(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(128), // ~0.5 opacity
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('🇬🇧')),
            ButtonSegment(value: 'fr', label: Text('🇫🇷')),
            ButtonSegment(value: 'es', label: Text('🇪🇸')),
            ButtonSegment(value: 'zh', label: Text('🇨🇳')),
            ButtonSegment(value: 'uk', label: Text('🇺🇦')),
          ],
          selected: {_currentLanguageCode!},
          onSelectionChanged: (newSelection) {
            _changeLanguage(newSelection.first);
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor:
                theme.colorScheme.onSurface.withAlpha(179), // ~0.7 opacity
            selectedForegroundColor: theme.colorScheme.primary,
            selectedBackgroundColor:
                theme.colorScheme.primary.withAlpha(26), // ~0.1 opacity
            side: BorderSide(color: theme.dividerColor),
          ),
        ),
      ],
    );
  }
}