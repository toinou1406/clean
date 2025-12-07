import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:fastclean/photo_analyzer.dart';
import 'package:fastclean/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class FullScreenImageView extends StatefulWidget {
  final List<PhotoResult> photos;
  final int initialIndex;
  final Set<String> ignoredPhotos;
  final void Function(String) onToggleKeep;

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
  late final PageController _pageController;
  late int _currentIndex;
  bool _isUiVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleUiVisibility() {
    setState(() {
      _isUiVisible = !_isUiVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentPhoto = widget.photos[_currentIndex];
    final isKept = widget.ignoredPhotos.contains(currentPhoto.asset.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The main photo gallery
          GestureDetector(
            onTap: _toggleUiVisibility,
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.photos.length,
              builder: (context, index) {
                final photo = widget.photos[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: AssetEntityImageProvider(photo.asset, isOriginal: true),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: photo.asset.id),
                );
              },
              onPageChanged: _onPageChanged,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),

          // Animated UI elements (Header and Footer)
          _buildAnimatedUi(theme, l10n, isKept, currentPhoto),
        ],
      ),
    );
  }

  Widget _buildAnimatedUi(ThemeData theme, AppLocalizations l10n, bool isKept, PhotoResult currentPhoto) {
    return AnimatedOpacity(
      opacity: _isUiVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Stack(
        children: [
          // Top Bar (Header)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  "${_currentIndex + 1} / ${widget.photos.length}",
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                centerTitle: true,
              ),
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKeepButton(l10n, theme, isKept, currentPhoto),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeepButton(AppLocalizations l10n, ThemeData theme, bool isKept, PhotoResult currentPhoto) {
    return ElevatedButton.icon(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: isKept
            ? Icon(Icons.check_circle_rounded, key: const ValueKey('kept'), color: theme.colorScheme.primary)
            : Icon(Icons.radio_button_unchecked_rounded, key: const ValueKey('not_kept')),
      ),
      label: Text(
        isKept ? l10n.keep : l10n.keep, // Text remains the same, but style could change
        style: theme.elevatedButtonTheme.style?.textStyle?.resolve({}),
      ),
      style: ElevatedButton.styleFrom(
        // A slightly different style for this specific context
        backgroundColor: isKept ? theme.colorScheme.primary.withOpacity(0.15) : theme.colorScheme.surface.withOpacity(0.8),
        foregroundColor: isKept ? theme.colorScheme.primary : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: isKept ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
        elevation: 0,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onToggleKeep(currentPhoto.asset.id);
      },
    );
  }
}
