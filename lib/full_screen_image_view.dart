
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// Aurora & Custom Widgets
import 'photo_cleaner_service.dart'; 
import 'main.dart'; // For ActionButton colors

class FullScreenImageView extends StatefulWidget {
  final List<PhotoResult> photos;
  final int initialIndex;
  final Set<String> ignoredPhotos;
  final Function(String) onToggleKeep;

  const FullScreenImageView({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.ignoredPhotos,
    required this.onToggleKeep,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;
  final ValueNotifier<bool> _isZoomed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _isZoomed.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onPageChanged(int index) {
    _isZoomed.value = false;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhotoId = widget.photos[_currentIndex].asset.id;
    final isKept = widget.ignoredPhotos.contains(currentPhotoId);

    return Scaffold(
      backgroundColor: darkCharcoal,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (!_isZoomed.value && (details.primaryVelocity ?? 0) > 250) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.photos.length,
              builder: (context, index) {
                final asset = widget.photos[index].asset;
                return PhotoViewGalleryPageOptions.customChild(
                  child: PhotoPage(key: ValueKey(asset.id), asset: asset, isZoomedNotifier: _isZoomed),
                  heroAttributes: PhotoViewHeroAttributes(tag: asset.id),
                );
              },
              onPageChanged: _onPageChanged,
              backgroundDecoration: const BoxDecoration(color: darkCharcoal),
              scrollPhysics: const BouncingScrollPhysics(),
              loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: etherealGreen)),
            ),
            // Top Gradient and App Bar
            _buildGradientOverlay(
              child: SafeArea(
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                  title: Text('${_currentIndex + 1} of ${widget.photos.length}', style: Theme.of(context).textTheme.titleMedium),
                  centerTitle: true,
                ),
              ),
            ),
            // Bottom Action Button with Gradient
            _buildGradientOverlay(
              isBottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                child: ActionButton(
                  label: isKept ? 'Kept' : 'Keep',
                  onPressed: () => setState(() => widget.onToggleKeep(currentPhotoId)),
                  isPrimary: !isKept,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay({required Widget child, bool isBottom = false}) {
    return Positioned(
      top: isBottom ? null : 0,
      bottom: isBottom ? 0 : null,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isBottom ? Alignment.bottomCenter : Alignment.topCenter,
            end: isBottom ? Alignment.topCenter : Alignment.bottomCenter,
            colors: [darkCharcoal.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: child,
      ),
    );
  }
}

class PhotoPage extends StatefulWidget {
  final AssetEntity asset;
  final ValueNotifier<bool> isZoomedNotifier;

  const PhotoPage({super.key, required this.asset, required this.isZoomedNotifier});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  File? _file;
  Uint8List? _thumbnailData;
  dynamic _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final thumb = await widget.asset.thumbnailDataWithSize(const ThumbnailSize(300, 300));
      if (mounted) setState(() => _thumbnailData = thumb);
      final file = await widget.asset.file;
      if (mounted) setState(() => _file = file);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Failed to load image', style: Theme.of(context).textTheme.titleMedium),
            if (kDebugMode) Padding(padding: const EdgeInsets.all(16.0), child: Text(_loadError.toString(), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)),
          ],
        ),
      );
    }

    if (_file != null) {
      return PhotoView(
        imageProvider: FileImage(_file!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        scaleStateChangedCallback: (state) => widget.isZoomedNotifier.value = state != PhotoViewScaleState.initial,
        loadingBuilder: (context, event) {
          if (_thumbnailData != null) {
            return PhotoView(imageProvider: MemoryImage(_thumbnailData!));
          }
          return const Center(child: CircularProgressIndicator(color: etherealGreen));
        },
      );
    }

    if (_thumbnailData != null) {
      return PhotoView(imageProvider: MemoryImage(_thumbnailData!));
    }

    return const Center(child: CircularProgressIndicator(color: etherealGreen));
  }
}
