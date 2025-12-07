
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:fastclean/aurora_circular_indicator.dart';
import 'package:fastclean/saved_space_indicator.dart';
import 'package:fastclean/sorting_indicator_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

// Aurora & Custom Widgets
import 'aurora_widgets.dart';

import 'full_screen_image_view.dart';
import 'permission_screen.dart';
import 'language_settings_screen.dart';
import 'photo_analyzer.dart';
import 'photo_cleaner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool permissionGranted = prefs.getBool('permission_granted') ?? false;
  final String? languageCode = prefs.getString('language_code');

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

  void changeLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color(0xFF2E7D32); // Deep Green from Logo

    final TextTheme appTextTheme = GoogleFonts.nunitoTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      // Overriding specific styles for a unique look
      displayLarge: GoogleFonts.nunito(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
      displayMedium: GoogleFonts.nunito(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
      displaySmall: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
      headlineMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.95)),
      headlineSmall: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.9)),
      titleLarge: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
      titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, color: Colors.white.withOpacity(0.75), height: 1.5),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, color: Colors.white.withOpacity(0.7), height: 1.5),
      labelLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold), // For buttons
    );

    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primarySeedColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // More rounded
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: appTextTheme.labelLarge,
        elevation: 2,
        shadowColor: primarySeedColor.withOpacity(0.4),
      ),
    );

    final cardTheme = CardTheme(
      elevation: 0,
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
        // Customizing scheme colors
        primary: primarySeedColor,
        secondary: const Color(0xFF4CAF50), // Brighter Green
        surface: const Color(0xFFF5F5F5), // Off-white
        background: const Color(0xFFFFFFFF), // Pure white
      ),
      textTheme: appTextTheme.apply(bodyColor: const Color(0xFF121212), displayColor: const Color(0xFF121212)),
      scaffoldBackgroundColor: const Color(0xFFF9F9F9), // A slightly off-white for depth
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appTextTheme.headlineSmall?.apply(color: const Color(0xFF121212)),
        iconTheme: const IconThemeData(color: Color(0xFF121212)),
      ),
      elevatedButtonTheme: elevatedButtonTheme,
      cardTheme: cardTheme,
      dividerColor: Colors.black.withOpacity(0.1),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
        primary: primarySeedColor, 
        secondary: const Color(0xFF66BB6A), // Lighter green for dark mode
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212), // Deep grey
      ),
      textTheme: appTextTheme, // Already defined for white text
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appTextTheme.headlineSmall,
        iconTheme: IconThemeData(color: Colors.white.withOpacity(0.85)),
      ),
      elevatedButtonTheme: elevatedButtonTheme,
      cardTheme: cardTheme,
      dividerColor: Colors.white.withOpacity(0.1),
    );


    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
     theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark, // Force dark mode for now
      locale: _locale,
      debugShowCheckedModeBanner: false,
      initialRoute: widget.initialRoute,
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.permission: (context) => PermissionScreen(
          onPermissionGranted: () {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          },
          onLocaleChanged: changeLocale,
        ),
        AppRoutes.settings: (context) => LanguageSettingsScreen(onLocaleChanged: changeLocale),
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
  final PhotoCleanerService _service = PhotoCleanerService();

  StorageInfo? _storageInfo;
  double _spaceSaved = 0.0;
  List<PhotoResult> _selectedPhotos = [];
  final Set<String> _ignoredPhotos = {};
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _hasScanned = false;
  String _sortingMessage = "";
  Timer? _messageTimer;
  bool _isInitialized = false;

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
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveState();
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_photo_ids', _selectedPhotos.map((p) => p.asset.id).toList());
    await prefs.setStringList('ignored_photo_ids', _ignoredPhotos.toList());
    await prefs.setBool('has_scanned', _hasScanned);
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('selected_photo_ids')) return;

    final photoIds = prefs.getStringList('selected_photo_ids') ?? [];
    final ignoredIds = prefs.getStringList('ignored_photo_ids') ?? [];
    final hasScanned = prefs.getBool('has_scanned') ?? false;

    if (photoIds.isNotEmpty) {
      List<PhotoResult> restoredPhotos = [];
      for (final id in photoIds) {
        try {
          final asset = await AssetEntity.fromId(id);
          if (asset != null) {
            restoredPhotos.add(PhotoResult(asset, PhotoAnalysisResult.empty()));
          }
        } catch (e) { /* Asset might have been deleted. */ }
      }

      if (mounted) {
        setState(() {
          _selectedPhotos = restoredPhotos;
          _ignoredPhotos.addAll(ignoredIds);
          _hasScanned = hasScanned;
        });
      }
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

  Future<void> _sortPhotos({bool rescan = false}) async {
    final l10n = AppLocalizations.of(context)!;
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
      _sortingMessage = sortingMessages.first;
    });

    _messageTimer?.cancel();
    int msgIndex = 0;
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isLoading) { timer.cancel(); return; }
      setState(() => _sortingMessage = sortingMessages[++msgIndex % sortingMessages.length]);
    });

    try {
      if (rescan) _service.reset();
      await _service.scanPhotos(permissionErrorMessage: l10n.photoAccessRequired);
      if (mounted) setState(() => _hasScanned = true);

      final photos = await _service.selectPhotosToDelete(excludedIds: _ignoredPhotos.toList());

      if (mounted) {
        if (photos.isEmpty && _hasScanned) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noMorePhotos)),
          );
        }
        setState(() => _selectedPhotos = photos);
        _preCachePhotoFiles(photos);
      }
    } catch (e, s) {
      developer.log('Error during photo sorting', name: 'photo_cleaner.error', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOccurred(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _messageTimer?.cancel();
    }
  }

  void _preCachePhotoFiles(List<PhotoResult> photos) {
    for (final photo in photos) {
      photo.asset.file; // no need to await
    }
  }

  Future<void> _deletePhotos() async {
    HapticFeedback.heavyImpact();
    setState(() => _isDeleting = true);

    try {
      final photosToDelete = _selectedPhotos.where((p) => !_ignoredPhotos.contains(p.asset.id)).toList();
      final Map<String, int> sizeMap = {};
      await Future.forEach(photosToDelete, (photo) async {
        final file = await photo.asset.file;
        sizeMap[photo.asset.id] = await file?.length() ?? 0;
      });

      final deletedIds = await _service.deletePhotos(photosToDelete);
      if (deletedIds.isEmpty && photosToDelete.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotDelete)));
        setState(() => _isDeleting = false);
        return;
      }

      int totalBytesDeleted = deletedIds.fold(0, (sum, id) => sum + (sizeMap[id] ?? 0));

      if (mounted) {
        setState(() {
          _selectedPhotos = [];
          _ignoredPhotos.clear();
          _spaceSaved += totalBytesDeleted;
        });
        _saveSavedSpace();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.photosDeleted(deletedIds.length, _formatBytes(totalBytesDeleted.toDouble())))),
        );
      }
      await _loadStorageInfo();
    } catch (e,s) {
      developer.log('Error deleting photos', name: 'photo_cleaner.error', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorDeleting(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _toggleIgnoredPhoto(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_ignoredPhotos.contains(id)) {
        _ignoredPhotos.remove(id);
      } else {
        _ignoredPhotos.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeScreenTitle, key: const Key('homeScreenTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            tooltip: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
      // Add the noise background to the entire screen
      body: NoiseBox(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: _buildMainContent(),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedPhotos.isNotEmpty) {
      return GridView.builder(
        key: const ValueKey('grid'),
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), // 3 columns
        itemCount: _selectedPhotos.length,
        itemBuilder: (context, index) {
          final photo = _selectedPhotos[index];
          return PhotoCard(
            key: ValueKey(photo.asset.id),
            photo: photo,
            isIgnored: _ignoredPhotos.contains(photo.asset.id),
            onToggleKeep: () => _toggleIgnoredPhoto(photo.asset.id),
            onOpenFullScreen: () => Navigator.push(
              context,
              // A more polished page transition
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageView(
                  photos: _selectedPhotos,
                  initialIndex: index,
                  ignoredPhotos: _ignoredPhotos,
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
      // The sorting indicator is now shown in the bottom bar.
      // We can show a simple spinner here or a placeholder.
      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary)));
    }

    return EmptyState(
      key: const ValueKey('empty'),
      storageInfo: _storageInfo,
      spaceSaved: _spaceSaved,
      formattedSpaceSaved: _formatBytes(_spaceSaved),
    );
  }

  Widget _buildBottomBar() {
    if (_isDeleting) return const SizedBox.shrink();

    int photosToDeleteCount = _selectedPhotos.length - _ignoredPhotos.length;
    final l10n = AppLocalizations.of(context)!;

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
                      // Re-sort Button (now a TextButton for secondary action)
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.reSort),
                          onPressed: () => _sortPhotos(),
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Main Action Button (Delete or Pass)
                      Expanded(
                        flex: 2, // Give more space to the primary action
                        child: ElevatedButton.icon(
                          icon: Icon(photosToDeleteCount > 0 ? Icons.delete_outline_rounded : Icons.check_rounded),
                          label: Text(photosToDeleteCount > 0 ? l10n.delete(photosToDeleteCount) : l10n.pass),
                          onPressed: photosToDeleteCount > 0
                              ? _deletePhotos
                              : () => setState(() {
                                    _selectedPhotos = [];
                                    _ignoredPhotos.clear();
                                  }),
                          style: photosToDeleteCount > 0
                              ? null // Use default ElevatedButton style
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
                    label: Text(l10n.analyzePhotos),
                    onPressed: () => _sortPhotos(rescan: true),
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

class _PhotoCardState extends State<PhotoCard> {
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.photo.asset.thumbnailDataWithSize(const ThumbnailSize(250, 250)); // Higher res thumbnail
    if (mounted) setState(() => _thumbnailData = data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onOpenFullScreen,
      onDoubleTap: widget.onToggleKeep,
      child: Hero(
        tag: widget.photo.asset.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16), // Softer corners
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail with a placeholder
              if (_thumbnailData != null)
                Image.memory(_thumbnailData!, fit: BoxFit.cover)
              else
                Container(color: theme.colorScheme.surface),

              // Animated overlay for the "Keep" state
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: widget.isIgnored ? Colors.black.withOpacity(0.5) : Colors.transparent,
                  border: Border.all(
                    color: widget.isIgnored ? theme.colorScheme.primary : Colors.transparent,
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(13), // Inset border
                ),
              ),

              // Animated "Keep" icon and text
              AnimatedOpacity(
                opacity: widget.isIgnored ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.white.withOpacity(0.9), size: 32),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.keep.toUpperCase(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
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
    );
  }
}

class EmptyState extends StatefulWidget {
  final StorageInfo? storageInfo;
  final double spaceSaved;
  final String formattedSpaceSaved;

  const EmptyState({super.key, required this.storageInfo, required this.spaceSaved, required this.formattedSpaceSaved});

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Using the new StatCard for a consistent look
            StatCard(
              icon: Icons.cleaning_services_rounded,
              iconColor: theme.colorScheme.secondary, // A vibrant color
              title: l10n.totalSpaceSaved,
              value: widget.formattedSpaceSaved,
            ),
            const SizedBox(height: 40),
            // Using the new StorageCircularIndicator
            if (widget.storageInfo != null)
              StorageCircularIndicator(storageInfo: widget.storageInfo!)
            else
              CircularProgressIndicator(color: theme.colorScheme.primary),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
