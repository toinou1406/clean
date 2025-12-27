import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:fastclean/aurora_circular_indicator.dart';

import 'package:fastclean/sorting_indicator_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

// Aurora & Custom Widgets
import 'aurora_widgets.dart';

import 'full_screen_image_view.dart';
import 'permission_screen.dart';
import 'language_settings_screen.dart';
import 'photo_cleaner_service.dart';

// Isolate Functions and Data Structures
// Moved here to resolve build issues with function visibility across libraries.
class GetSizesIsolateData {
  final RootIsolateToken token;
  final List<String> ids;
  GetSizesIsolateData(this.token, this.ids);
}

Future<Map<String, int>> getPhotoSizesInIsolate(GetSizesIsolateData isolateData) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);
  final Map<String, int> sizeMap = {};
  for (final id in isolateData.ids) {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        final file = await asset.file;
        sizeMap[id] = await file?.length() ?? 0;
      }
    } catch (e) {
      developer.log('Failed to get size for asset $id', name: 'photo_cleaner.isolate', error: e);
    }
  }
  return sizeMap;
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool permissionGranted = prefs.getBool('permission_granted') ?? false;
  final String? languageCode = prefs.getString('language_code');

  // Start scanning photos in the background if permission is granted
  if (permissionGranted) {
    // We don't have a context here, so we use a default error message.
    // This can be improved by passing the message from the UI layer later.
    PhotoCleanerService.instance.scanPhotosInBackground(permissionErrorMessage: "Photo access permission is required.");
  }

  runApp(MyApp(
    initialRoute: permissionGranted ? AppRoutes.home : AppRoutes.permission,
    locale: languageCode != null ? Locale(languageCode) : null,
  ));
}

class AppRoutes {
  static const String home = '/';
  static const String permission = '/permission';
  static const String settings = '/settings';
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.initialRoute, this.locale});
  final String initialRoute;
  final Locale? locale;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale ?? AppLocalizations.supportedLocales.first;
  }

  void _changeLocale(Locale locale) {
    if (AppLocalizations.supportedLocales.contains(locale)) {
      setState(() {
        _locale = locale;
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('language_code', locale.languageCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color(0xFF2E7D32); // Deep Green from Logo

    final TextTheme appTextTheme = GoogleFonts.nunitoTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.nunito(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
      displayMedium: GoogleFonts.nunito(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
      displaySmall: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
      headlineMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(242)), // ~0.95 opacity
      headlineSmall: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(229)), // ~0.9 opacity
      titleLarge: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(217)), // ~0.85 opacity
      titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(204)), // ~0.8 opacity
      bodyLarge: GoogleFonts.nunito(fontSize: 16, color: Colors.white.withAlpha(191), height: 1.5), // ~0.75 opacity
      bodyMedium: GoogleFonts.nunito(fontSize: 14, color: Colors.white.withAlpha(179), height: 1.5), // ~0.7 opacity
      labelLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
    );

    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primarySeedColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: appTextTheme.labelLarge,
        elevation: 2,
        shadowColor: primarySeedColor.withAlpha(102), // ~0.4 opacity
      ),
    );

    final cardTheme = CardThemeData(
      elevation: 0,
      color: Colors.white.withAlpha(13), // ~0.05 opacity
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
        primary: primarySeedColor,
        secondary: const Color(0xFF4CAF50),
        surface: const Color(0xFFF5F5F5),
      ),
      textTheme: appTextTheme.apply(bodyColor: const Color(0xFF121212), displayColor: const Color(0xFF121212)),
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appTextTheme.headlineSmall?.apply(color: const Color(0xFF121212)),
        iconTheme: const IconThemeData(color: Color(0xFF121212)),
      ),
      elevatedButtonTheme: elevatedButtonTheme,
      cardTheme: cardTheme,
      dividerColor: Colors.black.withAlpha(26), // ~0.1 opacity
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
        primary: const Color(0xFF66BB6A),
        secondary: const Color(0xFF81C784),
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white.withAlpha(229),
        surfaceTint: const Color(0xFF2A2A2A),
      ),
      textTheme: appTextTheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appTextTheme.headlineSmall,
        iconTheme: IconThemeData(color: Colors.white.withAlpha(217)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF66BB6A)),
          foregroundColor: WidgetStateProperty.all(Colors.black),
          shadowColor: WidgetStateProperty.all(Colors.black.withAlpha(128)),
          elevation: WidgetStateProperty.all(5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.black.withAlpha(102),
      ),
      dividerColor: Colors.white.withAlpha(38),
    );


    return MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        locale: _locale,
        debugShowCheckedModeBanner: false,
        initialRoute: widget.initialRoute,
        routes: {
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.permission: (context) => PermissionScreen(
            onPermissionGranted: () {
              PhotoCleanerService.instance.scanPhotosInBackground(permissionErrorMessage: AppLocalizations.of(context).photoAccessRequired);
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            onLocaleChanged: _changeLocale,
          ),
          AppRoutes.settings: (context) => LanguageSettingsScreen(onLocaleChanged: _changeLocale),
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final PhotoCleanerService _service = PhotoCleanerService.instance;

  StorageInfo? _storageInfo;
  double _spaceSaved = 0.0;
  List<PhotoResult> _selectedPhotos = [];
  final Set<String> _permanentlyIgnoredIds = {};
  bool _isLoading = false;
  bool _isDeleting = false;
  String _sortingMessage = "";
  Timer? _messageTimer;
  Timer? _notificationTimer;
  Future<List<PhotoResult>>? _currentBatchFuture;
  Future<List<PhotoResult>>? _nextBatchFuture;
  String? _topNotificationMessage;
  bool _showGridTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadStorageInfo();
    await _resetMonthlySavedSpace();
    await _loadSavedSpace();
    await _restoreState();
    if (mounted) {
      // Start fetching the initial batch of photos as soon as the app is initialized.
      setState(() {
        _currentBatchFuture = _prepareNextBatch();
      });
    }
  }

  Future<List<PhotoResult>> _prepareNextBatch() async {
    _service.reset();
    // We use a default permission error message here because we don't have build context
    // and this runs in the background. A more robust solution might involve passing
    // the localized string from a higher level.
    await _service.scanPhotosInBackground(permissionErrorMessage: "Photo access permission is required.");
    final photos = await _service.selectPhotosToDelete(excludedIds: _permanentlyIgnoredIds.toList());
    return photos.take(15).toList();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveIgnoredIds();
    }
  }

  Future<void> _saveIgnoredIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('permanently_ignored_ids', _permanentlyIgnoredIds.toList());
  }

  Future<void> _saveState() async {
    // This method is now only a proxy to _saveIgnoredIds, but could be expanded later.
    await _saveIgnoredIds();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final ignoredIds = prefs.getStringList('permanently_ignored_ids') ?? [];
    if (mounted) {
      setState(() {
        _permanentlyIgnoredIds.addAll(ignoredIds);
      });
    }
  }

  Future<void> _resetMonthlySavedSpace() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('lastSavedMonth') != DateTime.now().month) {
      setState(() => _spaceSaved = 0.0);
      await prefs.setDouble('spaceSaved', 0.0);
      await prefs.setInt('lastSavedMonth', DateTime.now().month);
    }
  }

  Future<void> _loadSavedSpace() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _spaceSaved = prefs.getDouble('spaceSaved') ?? 0.0);
  }

  Future<void> _saveSavedSpace() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('spaceSaved', _spaceSaved);
    await prefs.setInt('lastSavedMonth', DateTime.now().month);
  }

  String _formatBytes(double bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Future<void> _loadStorageInfo() async {
    final info = await _service.getStorageInfo();
    if (mounted) setState(() => _storageInfo = info);
  }

  Future<void> _checkAndShowGridTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool tutorialShown = prefs.getBool('grid_tutorial_shown') ?? false;
    if (!tutorialShown && _selectedPhotos.isNotEmpty && mounted) {
      setState(() {
        _showGridTutorial = true;
      });
    }
  }

  Future<void> _showInitialBatch() async {
    final l10n = AppLocalizations.of(context);
    if (_currentBatchFuture == null) {
      // This can happen if the initial prefetch fails.
      // We can trigger it again.
      setState(() {
        _currentBatchFuture = _prepareNextBatch();
      });
    }

    final sortingMessages = [
      l10n.sortingMessageAnalyzing,
      l10n.sortingMessageBlurry,
      l10n.sortingMessageScreenshots,
      l10n.sortingMessageDuplicates,
      l10n.sortingMessageScores,
      l10n.sortingMessageCompiling,
      l10n.sortingMessageRanking,
      l10n.sortingMessageFinalizing,
    ];

    setState(() {
      _isLoading = true;
      _selectedPhotos = [];
      _sortingMessage = sortingMessages.first;
    });

    _messageTimer?.cancel();
    int msgIndex = 0;
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isLoading) {
        timer.cancel();
        return;
      }
      setState(() => _sortingMessage = sortingMessages[++msgIndex % sortingMessages.length]);
    });

    try {
      final photos = await _currentBatchFuture!;
      if (mounted) {
        setState(() {
          _selectedPhotos = photos;
        });
        _checkAndShowGridTutorial();
        // Start fetching the next batch now that the first is displayed.
        _nextBatchFuture = _prepareNextBatch();
      }
    } catch (e, s) {
      developer.log('Error during initial photo sort', name: 'photo_cleaner.error', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString()), style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _messageTimer?.cancel();
    }
  }

  Future<void> _showNextBatch() async {
    final l10n = AppLocalizations.of(context);
    if (_nextBatchFuture == null) {
      // If there is no next batch, it might be because the user cleared everything
      // or the prefetch failed. Let's try to prepare a new one.
      setState(() {
        _isLoading = true;
        _selectedPhotos = [];
        _sortingMessage = l10n.sortingMessageCompiling;
      });
      _nextBatchFuture = _prepareNextBatch();
    } else {
      setState(() {
        _isLoading = true;
        _selectedPhotos = [];
        _sortingMessage = l10n.sortingMessageFinalizing;
      });
    }


    try {
        final photos = await _nextBatchFuture!;

        if (mounted) {
          // The next batch becomes the current one.
          _currentBatchFuture = _nextBatchFuture;
          // Immediately prefetch the one after.
          _nextBatchFuture = _prepareNextBatch();

          setState(() {
            _selectedPhotos = photos;
            // _permanentlyIgnoredIds is persistent and should not be cleared.
          });

          if (photos.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.noMorePhotos, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
        }
    } catch (e, s) {
      developer.log('Error showing next batch', name: 'photo_cleaner.error', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString()), style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }



  Future<void> _deletePhotos() async {
    HapticFeedback.heavyImpact();
    setState(() => _isDeleting = true);

    final l10n = AppLocalizations.of(context);

    try {
      final photosToDelete = _selectedPhotos.where((p) => !_permanentlyIgnoredIds.contains(p.asset.id)).toList();
      
      // Get photo sizes in an isolate to avoid UI jank
      final idsToGetSize = photosToDelete.map((p) => p.asset.id).toList();
      final rootToken = RootIsolateToken.instance;
      final Map<String, int> sizeMap;
      if (rootToken != null) {
        sizeMap = await compute(getPhotoSizesInIsolate, GetSizesIsolateData(rootToken, idsToGetSize));
      } else {
        // Fallback for safety, though it should not happen in release builds.
        developer.log("Could not get RootIsolateToken, getting sizes on main thread.", name: 'photo_cleaner.warning');
        sizeMap = {};
        await Future.forEach(photosToDelete, (photo) async {
          final file = await photo.asset.file;
          sizeMap[photo.asset.id] = await file?.length() ?? 0;
        });
      }

      final deletedIds = await _service.deletePhotos(photosToDelete);
      
      if (deletedIds.isEmpty && photosToDelete.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.couldNotDelete, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ));
        setState(() => _isDeleting = false);
        return;
      }
      int totalBytesDeleted = deletedIds.fold(0, (sum, id) => sum + (sizeMap[id] ?? 0));

      if (mounted) {
        setState(() {
          _selectedPhotos = [];
          _spaceSaved += totalBytesDeleted;
          _topNotificationMessage = l10n.photosDeleted(deletedIds.length, _formatBytes(totalBytesDeleted.toDouble()));
          
          // Advance the batch queue.
          _currentBatchFuture = _nextBatchFuture;
          _nextBatchFuture = _prepareNextBatch();
        });
        _saveSavedSpace();
        _notificationTimer?.cancel();
        _notificationTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _topNotificationMessage = null;
            });
          }
        });
      }
      await _loadStorageInfo();
    } catch (e, s) {
      developer.log('Error deleting photos', name: 'photo_cleaner.error', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeleting(e.toString()), style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _toggleIgnoredPhoto(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_permanentlyIgnoredIds.contains(id)) {
        _permanentlyIgnoredIds.remove(id);
      } else {
        _permanentlyIgnoredIds.add(id);
      }
    });
    // Persist the change immediately.
    _saveIgnoredIds();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          NoiseBox(
            child: SafeArea(
              bottom: false, // We only want safe area at the top for the main view
              child: Column(
                children: [
                  // Banner Title for Empty State
                  if (_selectedPhotos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E3D32), // Dark Green-Gray
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.homeScreenTitle,
                              key: const Key('homeScreenTitle'),
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                              tooltip: l10n.settings,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Header for Grid View
                  if (_selectedPhotos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => setState(() => _selectedPhotos = []),
                            tooltip: 'Back',
                          ),
                          Text(
                            'Review Photos',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                            tooltip: l10n.settings,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                          ),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: _buildMainContent(),
                    ),
                  ),
                  // Ensure bottom bar respects the bottom safe area
                  SafeArea(
                    top: false,
                    child: _buildBottomBar(),
                  ),
                ],
              ),
            ),
          ),
          // --- Overlay Notification ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -0.2), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _topNotificationMessage != null
                  ? Material(
                      key: const ValueKey('notification_bar'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                      color: Colors.grey.shade800.withOpacity(0.98),
                      elevation: 4.0,
                      shadowColor: Colors.black.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Text(
                          _topNotificationMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('no_notification')),
            ),
          ),
           if (_showGridTutorial)
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('grid_tutorial_shown', true);
                setState(() => _showGridTutorial = false);
              },
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.touch_app_outlined, color: Colors.white, size: 64),
                            const SizedBox(height: 24),
                            Text(
                              l10n.gridTutorialText,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              l10n.gridTutorialDismiss,
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('grid_tutorial_shown', true);
                          setState(() => _showGridTutorial = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedPhotos.isNotEmpty) {
      return GridView.builder(
        key: const ValueKey('grid'),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _selectedPhotos.length,
        itemBuilder: (context, index) {
          final photo = _selectedPhotos[index];
          return PhotoCard(
            key: ValueKey(photo.asset.id),
            photo: photo,
            isIgnored: _permanentlyIgnoredIds.contains(photo.asset.id),
            onToggleKeep: () => _toggleIgnoredPhoto(photo.asset.id),
            onOpenFullScreen: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageView(
                  photos: _selectedPhotos,
                  initialIndex: index,
                  ignoredPhotos: _permanentlyIgnoredIds,
                  onToggleKeep: _toggleIgnoredPhoto,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ),
          );
        },
      );
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary)));
    }

    final l10n = AppLocalizations.of(context);
    return EmptyState(
      key: const ValueKey('empty'),
      storageInfo: _storageInfo,
      spaceSaved: _spaceSaved,
      formattedSpaceSaved: _formatBytes(_spaceSaved),
      totalSpaceSavedText: l10n.totalSpaceSaved,
    );
  }

  Widget _buildBottomBar() {
    if (_isDeleting) return const SizedBox.shrink();

    int photosToDeleteCount = _selectedPhotos.where((p) => !_permanentlyIgnoredIds.contains(p.asset.id)).length;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isLoading
            ? SortingProgressIndicator(message: _sortingMessage)
            : _selectedPhotos.isNotEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: FittedBox(child: Text(l10n.reSort)),
                          onPressed: _showNextBatch,
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(179)), // ~0.7 opacity
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: Icon(photosToDeleteCount > 0 ? Icons.delete_outline_rounded : Icons.check_rounded),
                          label: FittedBox(child: Text(photosToDeleteCount > 0 ? l10n.delete(photosToDeleteCount) : l10n.pass)),
                          onPressed: photosToDeleteCount > 0
                              ? _deletePhotos
                              : _showNextBatch,
                          style: photosToDeleteCount > 0
                              ? null
                              : ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                                ),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.bolt_rounded),
                    label: FittedBox(child: Text(l10n.analyzePhotos)),
                    onPressed: _showInitialBatch,
                    key: const Key('analyzePhotosButton'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  ),
      ),
    );
  }
}

class PhotoCard extends StatefulWidget {
  final PhotoResult photo;
  final bool isIgnored;
  final VoidCallback onToggleKeep;
  final VoidCallback onOpenFullScreen;

  const PhotoCard({super.key, required this.photo, required this.isIgnored, required this.onToggleKeep, required this.onOpenFullScreen});

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> with SingleTickerProviderStateMixin {
  Uint8List? _thumbnailData;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isIgnored) {
      _controller.repeat(reverse: true);
    } else {
      // Set the controller to the middle of the animation (0.5), which corresponds to a rotation of 0.
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isIgnored != oldWidget.isIgnored) {
      if (widget.isIgnored) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        // Animate back to the middle (0 rotation) smoothly.
        _controller.animateTo(0.5, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    try {
      final data = await widget.photo.asset.thumbnailDataWithSize(const ThumbnailSize(250, 250));
      if (mounted) setState(() => _thumbnailData = data);
    } catch (e, s) {
      developer.log('Error loading thumbnail', name: 'photo_cleaner.error', error: e, stackTrace: s);
      if (mounted) setState(() => _thumbnailData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return RotationTransition(
      turns: _animation,
      child: GestureDetector(
        onTap: widget.onOpenFullScreen,
        onDoubleTap: widget.onToggleKeep,
        onLongPress: widget.onToggleKeep,
        child: Hero(
          tag: widget.photo.asset.id,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_thumbnailData != null)
                  Image.memory(
                    _thumbnailData!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: theme.colorScheme.surface);
                    },
                  )
                else
                  Container(color: theme.colorScheme.surface),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: widget.isIgnored ? Colors.black.withAlpha(128) : Colors.transparent, // ~0.5 opacity
                    border: Border.all(
                      color: widget.isIgnored ? theme.colorScheme.primary : Colors.transparent,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                AnimatedOpacity(
                  opacity: widget.isIgnored ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white.withAlpha(229), size: 32), // ~0.9 opacity
                        const SizedBox(height: 4),
                        Text(
                          l10n.keep.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withAlpha(229), // ~0.9 opacity
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatefulWidget {
  final StorageInfo? storageInfo;
  final double spaceSaved;
  final String formattedSpaceSaved;
  final String totalSpaceSavedText;

  const EmptyState({
    super.key,
    required this.storageInfo,
    required this.spaceSaved,
    required this.formattedSpaceSaved,
    required this.totalSpaceSavedText,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Note to user: Run 'flutter pub get' to generate new localization files.

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // A more engaging title
            Text(
              l10n.letsFindPhotos, // This could also be localized
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 1),

            // The main stats cards in a more interesting layout
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storageSpaceSaved, // Hardcoded for now
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (widget.storageInfo != null && widget.storageInfo!.totalSpace > 0)
                      LinearProgressIndicator(
                        value: widget.spaceSaved / widget.storageInfo!.totalSpace,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      )
                    else
                      const LinearProgressIndicator(
                        value: 0,
                        minHeight: 10,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.formattedSpaceSaved,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // The circular progress indicator remains a central focus
            if (widget.storageInfo != null)
              StorageCircularIndicator(storageInfo: widget.storageInfo!)
            else
              const SizedBox.shrink(),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
