import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photo_cleaner_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'permission_screen.dart';
import 'full_screen_image_view.dart';
import 'compression_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.deepPurple;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
      labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
    );

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    return MaterialApp(
      title: 'Photo Cleaner',
      theme: theme,
      home: const AppFlow(),
    );
  }
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (mounted) {
      setState(() {
        _hasPermission = ps.hasAccess;
        _isCheckingPermission = false;
      });
    }
  }

  void _onPermissionGranted() {
    setState(() {
      _hasPermission = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return _hasPermission
        ? const HomeScreen()
        : PermissionScreen(onPermissionGranted: _onPermissionGranted);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PhotoCleanerService _service = PhotoCleanerService();
  
  StorageInfo? _storageInfo;
  List<PhotoResult> _selectedPhotos = [];
  final Set<String> _ignoredPhotos = {};
  bool _isLoading = false;
  bool _hasScanned = false;
  String _sortingMessage = "Sorting...";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStorageInfo() async {
    final info = await _service.getStorageInfo();
    if (mounted) {
      setState(() {
        _storageInfo = info;
      });
    }
  }
  
  Future<void> _sortPhotos() async {
    setState(() {
      _isLoading = true;
      _sortingMessage = "Sorting...";
    });
    
    // Give the UI time to build the first message
    await Future.delayed(const Duration(milliseconds: 100));
    if(mounted) setState(() => _sortingMessage = "it will take above 5 sec");

    await Future.delayed(const Duration(seconds: 2));
    if(mounted) setState(() => _sortingMessage = "finalyzing");


    _fadeController.reset();
    
    try {
      // The first scan can be slow, subsequent scans can be faster if we cache results.
      if (!_hasScanned) {
        await _service.scanPhotos();
        if (mounted) setState(() => _hasScanned = true);
      }
      
      final photos = await _service.selectPhotosToDelete(excludedIds: _ignoredPhotos.toList());
      
      if (mounted) {
        // Handle case where no photos are returned
        if (photos.isEmpty && _hasScanned) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No more deletable photos found! Try a new scan.')),
            );
        }
        setState(() {
          _selectedPhotos = photos;
          _isLoading = false;
        });
        if (photos.isNotEmpty) {
            _fadeController.forward();
        }
      }
    } catch (e, s) {
        if (mounted) {
            setState(() => _isLoading = false);
            developer.log(
                'Error during photo sorting',
                name: 'photo_cleaner.error',
                error: e,
                stackTrace: s,
            );
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('An error occurred: ${e.toString()}')),
            );
        }
    }
  }
  
  Future<void> _deletePhotos() async {
    setState(() => _isLoading = true);
    
    try {
      final photosToDelete = _selectedPhotos
          .where((p) => !_ignoredPhotos.contains(p.asset.id))
          .toList();
      
      await _service.deletePhotos(photosToDelete);
      
      if (mounted) {
        setState(() {
          _selectedPhotos = [];
          _ignoredPhotos.clear();
          _isLoading = false;
        });
      }
      
      await _loadStorageInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting photos: $e')),
        );
      }
    }
  }
  
  void _toggleIgnoredPhoto(String id) {
    HapticFeedback.mediumImpact();
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
    final int photosToDeleteCount = _selectedPhotos.length - _ignoredPhotos.length;

    return Scaffold(
      body: Container(
        decoration: Platform.environment.containsKey('FLUTTER_TEST')
            ? null
            : const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/noise.png"),
                  fit: BoxFit.cover, 
                  opacity: 0.05,
                ),
              ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('AI Photo Cleaner', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36)),
                    const SizedBox(height: 20),
                    if (_storageInfo != null) 
                      StorageIndicator(storageInfo: _storageInfo!),
                  ],
                ),
              ),
              
              const Divider(),
              
              // PHOTO GRID
              Expanded(
                child: _selectedPhotos.isEmpty && !_isLoading
                        ? const EmptyState()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _selectedPhotos.length,
                              itemBuilder: (context, index) {
                                final photo = _selectedPhotos[index];
                                return PhotoCard(
                                  photo: photo,
                                  isIgnored: _ignoredPhotos.contains(photo.asset.id),
                                  onLongPress: () => _toggleIgnoredPhoto(photo.asset.id),
                                );
                              },
                            ),
                          ),
              ),
              
              // ACTION BUTTONS
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLoading) ...[
                      ActionButton(
                        label: 'Compress Photos',
                        icon: Icons.compress,
                        backgroundColor: Colors.indigo[700],
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CompressionScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _isLoading
                      ? SortingProgressIndicator(message: _sortingMessage)
                      : _selectedPhotos.isEmpty
                        ? ActionButton(
                            label: 'Sort',
                            icon: Icons.sort,
                            onPressed: _sortPhotos,
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ActionButton(
                                  label: 'Re-sort',
                                  icon: Icons.refresh,
                                  onPressed: _sortPhotos,
                                  backgroundColor: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ActionButton(
                                  label: 'Delete ($photosToDeleteCount)',
                                  icon: Icons.delete_forever,
                                  onPressed: photosToDeleteCount > 0 ? _deletePhotos : null,
                                  backgroundColor: photosToDeleteCount > 0 ? Colors.red[800] : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StorageIndicator extends StatelessWidget {
  final StorageInfo storageInfo;
  const StorageIndicator({super.key, required this.storageInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Used Storage', style: Theme.of(context).textTheme.titleLarge),
            Text('${storageInfo.usedSpaceGB} / ${storageInfo.totalSpaceGB}', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: storageInfo.usedPercentage / 100,
            minHeight: 12,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              storageInfo.usedPercentage > 80 ? Colors.red.shade400 : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class PhotoCard extends StatefulWidget {
  final PhotoResult photo;
  final bool isIgnored;
  final VoidCallback onLongPress;

  const PhotoCard({
    super.key,
    required this.photo,
    required this.isIgnored,
    required this.onLongPress,
  });

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> with SingleTickerProviderStateMixin {
  late AnimationController _swayController;
  late Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _swayAnimation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(
        parent: _swayController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _swayController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _swayController.forward();
      }
    });

    if (widget.isIgnored) {
      _swayController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isIgnored != oldWidget.isIgnored) {
      if (widget.isIgnored) {
        _swayController.forward();
      } else {
        _swayController.stop();
        _swayController.reset();
      }
    }
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageView(asset: widget.photo.asset),
          ),
        );
      },
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _swayAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.isIgnored ? _swayAnimation.value : 0,
            child: child,
          );
        },
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withAlpha(128),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder(
                future: widget.photo.asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              if (widget.isIgnored)
                Container(
                  color: Colors.green.withAlpha((255 * 0.5).round()),
                  child: Center(
                    child: Text(
                      'KEEP',
                      style: GoogleFonts.oswald(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
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

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const ActionButton({super.key, required this.label, required this.icon, this.onPressed, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        minimumSize: const Size(double.infinity, 60),
        shadowColor: (backgroundColor ?? Theme.of(context).colorScheme.primary).withAlpha(128),
        elevation: 8,
      ),
    );
  }
}

class SortingProgressIndicator extends StatefulWidget {
  final String message;
  const SortingProgressIndicator({super.key, required this.message});

  @override
  State<SortingProgressIndicator> createState() => _SortingProgressIndicatorState();
}

class _SortingProgressIndicatorState extends State<SortingProgressIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      if (mounted) {
        setState(() {
          _progress = _controller.value;
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The progress bar background and shimmer effect
            Stack(
              children: [
                Container(color: Colors.grey[800]), // Background
                FractionallySizedBox(
                  widthFactor: _progress,
                  alignment: Alignment.centerLeft,
                  child: Shimmer.fromColors(
                    baseColor: Colors.deepPurple,
                    highlightColor: Colors.purple.shade300,
                    child: Container(color: Colors.white), // Shimmer needs a solid child
                  ),
                ),
              ],
            ),
            // The text on top
            Text(
              widget.message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                shadows: [
                  const Shadow(blurRadius: 4.0, color: Colors.black87, offset: Offset(1,1)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 100, color: Theme.of(context).colorScheme.primary.withAlpha(178)),
          const SizedBox(height: 24),
          Text('Press "Sort" to Begin', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Let the AI find photos you can delete', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center,),
        ],
      ),
    );
  }
}
