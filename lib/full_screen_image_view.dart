import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:fastclean/photo_cleaner_service.dart';
import 'package:fastclean/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

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

  // --- Pre-caching Implementation ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache images around the initial viewing index for a smoother experience.
    _precacheImage(widget.initialIndex + 1);
    _precacheImage(widget.initialIndex - 1);
  }

  void _precacheImage(int index) {
    if (!mounted) return;
    if (index >= 0 && index < widget.photos.length) {
      final provider = AssetEntityImageProvider(widget.photos[index].asset, isOriginal: true);
      precacheImage(provider, context);
    }
  }
  // --- End Pre-caching ---

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    // As the user swipes, pre-cache the next images in the direction of the swipe.
    _precacheImage(index + 1);
    _precacheImage(index - 1);
  }

  void _toggleUiVisibility() {
    setState(() {
      _isUiVisible = !_isUiVisible;
    });
  }

  // --- "Keep" Button Fix ---
  void _handleToggleKeep() {
    final currentPhotoId = widget.photos[_currentIndex].asset.id;
    HapticFeedback.lightImpact();
    // Calling setState here rebuilds this widget to reflect the change in the button's state,
    // even though the actual state is managed by the parent (HomeScreen).
    setState(() {
      widget.onToggleKeep(currentPhotoId);
    });
  }
  // --- End "Keep" Button Fix ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentPhoto = widget.photos[_currentIndex];
    final isKept = widget.ignoredPhotos.contains(currentPhoto.asset.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 30.0,
                  height: 30.0,
                  child: CircularProgressIndicator(
                    value: event == null || event.expectedTotalBytes == null
                        ? null
                        : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  ),
                ),
              ),
            ),
          ),
          _buildAnimatedUi(theme, l10n, isKept),
        ],
      ),
    );
  }

  Widget _buildAnimatedUi(
    ThemeData theme,
    AppLocalizations l10n,
    bool isKept,
  ) {
    return AnimatedOpacity(
      opacity: _isUiVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(153), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  l10n.fullScreenTitle(widget.photos.length, _currentIndex + 1),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),
            ),
          ),
          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(204), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKeepButton(l10n, theme, isKept),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeepButton(
    AppLocalizations l10n,
    ThemeData theme,
    bool isKept,
  ) {
    return ElevatedButton.icon(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: isKept
            ? Icon(
                Icons.check_circle_rounded,
                key: const ValueKey('kept_icon'),
                color: theme.colorScheme.primary,
              )
            : const Icon(
                Icons.radio_button_unchecked_rounded,
                key: ValueKey('not_kept_icon'),
              ),
      ),
      label: Text(
        isKept ? l10n.kept : l10n.keep,
        style: theme.elevatedButtonTheme.style?.textStyle?.resolve({}),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isKept
            ? theme.colorScheme.primary.withAlpha(38)
            : theme.colorScheme.surface.withAlpha(204),
        foregroundColor: isKept ? theme.colorScheme.primary : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: const StadiumBorder(),
        side: isKept
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
        elevation: 0,
      ),
      onPressed: _handleToggleKeep,
    );
  }
}
