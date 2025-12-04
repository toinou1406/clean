import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fastclean/main.dart'; // Assuming ActionButton is in main.dart
import 'photo_cleaner_service.dart';

class CompressionScreen extends StatefulWidget {
  const CompressionScreen({super.key});

  @override
  State<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends State<CompressionScreen> {
  final PhotoCleanerService _service = PhotoCleanerService();
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;
  bool _isCompressing = false;
  final Set<String> _selectedAlbumIds = {};
  double _compressionQuality = 75.0;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (mounted) {
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    }
  }

  void _onAlbumSelected(bool? isSelected, String albumId) {
    setState(() {
      if (isSelected == true) {
        _selectedAlbumIds.add(albumId);
      } else {
        _selectedAlbumIds.remove(albumId);
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _showSummaryDialog(CompressionResult result, List<AssetPathEntity> originalAlbums) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Compression Complete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('${result.totalFiles} photos were compressed.'),
                const SizedBox(height: 10),
                Text('Space saved: ${_formatBytes(result.spaceSaved)}'),
                const SizedBox(height: 20),
                const Text(
                  'Do you want to delete the original albums?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Originals'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                setState(() => _isCompressing = true); // Show loading overlay again
                await _service.deleteAlbums(originalAlbums);
                if(mounted) {
                   setState(() {
                     _isCompressing = false;
                     _selectedAlbumIds.clear();
                   });
                   // Refresh album list
                   _loadAlbums();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _validateCompression() async {
    setState(() => _isCompressing = true);

    final albumsToCompress = _albums.where((album) => _selectedAlbumIds.contains(album.id)).toList();

    try {
      final result = await _service.compressAlbums(
        albums: albumsToCompress,
        quality: _compressionQuality.toInt(),
      );
      
      if (mounted) {
        _showSummaryDialog(result, albumsToCompress);
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompressing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress Albums'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Select the albums you want to compress.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _albums.length,
                        itemBuilder: (context, index) {
                          final album = _albums[index];
                          return CheckboxListTile(
                            title: Text(album.name),
                          subtitle: FutureBuilder<int>(
                            future: album.assetCountAsync,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text('${snapshot.data} photos');
                              }
                              return const Text('...');
                            },
                          ),
                            value: _selectedAlbumIds.contains(album.id),
                            onChanged: _isCompressing ? null : (isSelected) => _onAlbumSelected(isSelected, album.id),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Compression Quality: ${_compressionQuality.toInt()}%'),
                          Slider(
                            value: _compressionQuality,
                            min: 10,
                            max: 90,
                            divisions: 8,
                            label: '${_compressionQuality.toInt()}%',
                            onChanged: _isCompressing ? null : (value) {
                              setState(() {
                                _compressionQuality = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ActionButton(
                        label: 'Validate Compression',
                        icon: Icons.compress,
                        onPressed: _selectedAlbumIds.isEmpty || _isCompressing ? null : _validateCompression,
                      ),
                    ),
                  ],
                ),
          if (_isCompressing)
            Container(
              color: Colors.black.withAlpha((255 * 0.7).round()),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Compressing albums...\nThis may take a while.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}