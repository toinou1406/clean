
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:image/image.dart' as img;
import 'photo_analyzer.dart';
import 'package:flutter/services.dart';



//##############################################################################
//# 1. ISOLATE DATA STRUCTURES & TOP-LEVEL FUNCTION
//##############################################################################

/// Wrapper containing all data returned from the background analysis isolate.
class IsolateAnalysisResult {
    final String assetId;
    final PhotoAnalysisResult analysis;

    IsolateAnalysisResult(this.assetId, this.analysis);
}

/// Data structure to pass to the isolate.
class IsolateData {
  final RootIsolateToken token;
  final String assetId;
  final bool isFromScreenshotAlbum;
  IsolateData(this.token, this.assetId, this.isFromScreenshotAlbum);
}

/// Top-level function executed in a separate isolate.
/// This function is the entry point for the background processing.
Future<dynamic> analyzePhotoInIsolate(IsolateData isolateData) async {
    // Initialize platform channels for this isolate
    BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);

    final String assetId = isolateData.assetId;
    final AssetEntity? asset = await AssetEntity.fromId(assetId);
    if (asset == null) {
        return "Error: AssetEntity.fromId returned null for $assetId";
    }

    // Get thumbnail data instead of original bytes to prevent OutOfMemoryErrors.
    // Using a minimal thumbnail (32x32) to absolutely minimize memory usage.
    final Uint8List? imageBytes = await asset.thumbnailDataWithSize(const ThumbnailSize(32, 32));
    if (imageBytes == null) {
        return "Error: asset.thumbnailDataWithSize returned null for $assetId";
    }

    // The new analyzer performs all heavy lifting.
    final analyzer = PhotoAnalyzer();
    try {
        // Call the new byte-based analysis method.
        final analysisResult = await analyzer.analyze(
          imageBytes, 
          isFromScreenshotAlbum: isolateData.isFromScreenshotAlbum,
        );
        return IsolateAnalysisResult(asset.id, analysisResult);
    } catch (e, stackTrace) {
        // If a single analysis fails, we don't want to crash the whole batch.
        return "Error: analyzer.analyze failed for asset $assetId: $e\n$stackTrace";
    }
}

//##############################################################################
//# 2. MAIN SERVICE & DATA MODELS
//##############################################################################

/// A unified class to hold the asset and its complete analysis result.
class PhotoResult {
  final AssetEntity asset;
  final PhotoAnalysisResult analysis;
  
  // For convenience, we expose the final score directly.
  double get score => analysis.finalScore;

  PhotoResult(this.asset, this.analysis);
}

/// Holds the result of a compression operation.
class CompressionResult {
  final int totalFiles;
  final int spaceSaved; // in bytes
  CompressionResult({required this.totalFiles, required this.spaceSaved});
}

/// Data structure to pass to the compression isolate.
class IsolateCompressionData {
  final RootIsolateToken token;
  final String assetId;
  final int quality;
  final String newAlbumName;

  IsolateCompressionData(this.token, this.assetId, this.quality, this.newAlbumName);
}

/// Data structure to return from the compression isolate.
class IsolateCompressionResult {
  final int originalSize;
  final int compressedSize;

  IsolateCompressionResult(this.originalSize, this.compressedSize);
}


/// Top-level function for compression executed in a separate isolate.
Future<dynamic> compressPhotoInIsolate(IsolateCompressionData isolateData) async {
  // Initialize platform channels
  BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);
  
  final asset = await AssetEntity.fromId(isolateData.assetId);
  if (asset == null) {
    return "Error: AssetEntity.fromId returned null for ${isolateData.assetId}";
  }

  try {
    // Using .originBytes is crucial for getting the full image data for compression.
    // However, this is memory-intensive. The isolate architecture contains this risk.
    final Uint8List? assetBytes = await asset.originBytes;
    if (assetBytes == null) {
      return "Error: asset.originBytes returned null for ${isolateData.assetId}";
    }

    final int originalSize = assetBytes.length;
    final img.Image? originalImage = img.decodeImage(assetBytes);

    if (originalImage != null) {
      final List<int> compressedBytes = img.encodeJpg(originalImage, quality: isolateData.quality);
      final int compressedSize = compressedBytes.length;

      final String filename;
      if (asset.title != null && asset.title!.isNotEmpty) {
        final String base = asset.title!.split('.').first;
        filename = '$base.jpg';
      } else {
        filename = 'compressed_${asset.id}.jpg';
      }

      await PhotoManager.editor.saveImage(
        Uint8List.fromList(compressedBytes),
        title: filename,
        relativePath: isolateData.newAlbumName, filename: '',
      );
      
      return IsolateCompressionResult(originalSize, compressedSize);
    } else {
      return "Error: Could not decode image for asset ${isolateData.assetId}";
    }
  } catch (e, stackTrace) {
    // Return a detailed error message.
    return "Error: Compression failed for asset ${isolateData.assetId}: $e\n$stackTrace";
  }
}


class PhotoCleanerService {
  final DiskSpacePlus _diskSpace = DiskSpacePlus();
  
  final List<PhotoResult> _allPhotos = [];
  final Set<String> _seenPhotoIds = {};

  /// Scans all photos using a high-performance, batched background process.
  /// Returns the number of photos successfully analyzed.
  Future<void> scanPhotos() async {
    if (kDebugMode) {
      print("PhotoCleanerService: Starting photo scan...");
    }
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (kDebugMode) {
        print("PhotoCleanerService: Full photo access permission denied.");
      }
      throw Exception('Full photo access permission is required.');
    }
    if (kDebugMode) {
      print("PhotoCleanerService: Photo access permission granted.");
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (kDebugMode) {
      print("PhotoCleanerService: Found ${albums.length} photo albums.");
    }
    if (albums.isEmpty) return;

    // --- NEW LOGIC: Prioritize albums and limit to 200 photos ---
    List<AssetEntity> assetsToAnalyze = [];
    final Set<String> screenshotAssetIds = {};

    final priorityAlbums = albums.where((album) =>
        album.name.toLowerCase() == 'screenshots' || album.name.toLowerCase() == 'whatsapp').toList();

    final otherAlbums = albums.where((album) =>
        album.name.toLowerCase() != 'screenshots' && album.name.toLowerCase() != 'whatsapp').toList();

    // Process priority albums first
    for (final album in priorityAlbums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        if (album.name.toLowerCase() == 'screenshots') {
          screenshotAssetIds.addAll(assets.map((a) => a.id));
        }
        assetsToAnalyze.addAll(assets);
    }

    // Fill with other albums if we haven't reached the limit
    if (assetsToAnalyze.length < 200) {
      for (final album in otherAlbums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        assetsToAnalyze.addAll(assets);
        if (assetsToAnalyze.length >= 200) break;
      }
    }

    // Shuffle and limit to unique assets
    assetsToAnalyze.shuffle();
    final uniqueAssets = { for (var e in assetsToAnalyze) e.id: e };
    assetsToAnalyze = uniqueAssets.values.toList();
    if (assetsToAnalyze.length > 200) {
      assetsToAnalyze = assetsToAnalyze.sublist(0, 200);
    }
    
    if (kDebugMode) {
      print("PhotoCleanerService: Selected ${assetsToAnalyze.length} unique assets to analyze.");
    }

    _allPhotos.clear();
    // _seenPhotoIds.clear(); // We should not clear this here, so re-sort works as expected

    final rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      if (kDebugMode) {
        print("FATAL: Could not get RootIsolateToken. Background processing is not possible.");
      }
      // This is a critical failure, we cannot proceed.
      throw Exception("Failed to get RootIsolateToken. Make sure you are on Flutter 3.7+ and running on the main isolate.");
    }
    
    // Create futures with the new IsolateData structure
    final analysisFutures = assetsToAnalyze.map((asset) {
        final bool isScreenshot = screenshotAssetIds.contains(asset.id);
        return compute(analyzePhotoInIsolate, IsolateData(rootIsolateToken, asset.id, isScreenshot));
    }).toList();

    if (kDebugMode) {
      print("PhotoCleanerService: Created ${analysisFutures.length} analysis futures. Starting batch processing...");
    }

    // --- BATCH PROCESSING ---
    // This is critical for performance and memory management.
    final List<IsolateAnalysisResult> analysisResults = [];
    const batchSize = 3;

    for (int i = 0; i < analysisFutures.length; i += batchSize) {
        final end = (i + batchSize > analysisFutures.length) ? analysisFutures.length : i + batchSize;
        final batch = analysisFutures.sublist(i, end);
        if (kDebugMode) {
          print("PhotoCleanerService: Processing batch ${i ~/ batchSize + 1}/${(analysisFutures.length / batchSize).ceil()} with ${batch.length} photos.");
        }
        final List<dynamic> batchResults = await Future.wait(batch);

        // New error handling to get logs from the isolate
        for (final result in batchResults) {
          if (result is IsolateAnalysisResult) {
            analysisResults.add(result);
          } else if (result is String) {
            if (kDebugMode) {
              print("Isolate Error: $result");
            }
          }
        }

        if (kDebugMode) {
          print("PhotoCleanerService: Batch ${i ~/ batchSize + 1} finished. Total results so far: ${analysisResults.length}");
        }

        // Manually release photo_manager's cache to combat memory leaks.
        await PhotoManager.clearFileCache();
        
        // Optional: Provide progress updates to the UI here.
    }

    // Create a quick lookup map for assets by ID.
    final Map<String, AssetEntity> assetMap = {for (var asset in assetsToAnalyze) asset.id: asset};

    // Populate the final list of results.
    _allPhotos.addAll(
        analysisResults.where((r) => assetMap.containsKey(r.assetId)).map((r) => PhotoResult(assetMap[r.assetId]!, r.analysis))
    );
    if (kDebugMode) {
      print("PhotoCleanerService: Scan complete. Populated ${_allPhotos.length} photo results.");
    }
  }

  /// ##########################################################################
  /// # NEW SELECTION ALGORITHM
  /// ##########################################################################
  Future<List<PhotoResult>> selectPhotosToDelete({List<String> excludedIds = const []}) async {
    // User's proposed logic: Always show the 12 worst photos based on score.
    List<PhotoResult> candidates = _allPhotos
        .where((p) => !excludedIds.contains(p.asset.id) && !_seenPhotoIds.contains(p.asset.id))
        .toList();

    // Sort all candidates by their score in descending order (worst first).
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Take the top 12.
    final selected = candidates.take(12).toList();

    // Add these to the list of photos we've already seen.
    _seenPhotoIds.addAll(selected.map((p) => p.asset.id));
    
    return selected;
  }

  /// Deletes the selected photos from the device.
  Future<void> deletePhotos(List<PhotoResult> photos) async {
    if (photos.isEmpty) return;
    final ids = photos.map((p) => p.asset.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
  }

  /// Deletes all photos within the provided list of albums.
  Future<void> deleteAlbums(List<AssetPathEntity> albums) async {
    if (albums.isEmpty) return;

    List<String> allAssetIds = [];
    for (final album in albums) {
      final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
      allAssetIds.addAll(assets.map((a) => a.id));
    }

    if (allAssetIds.isNotEmpty) {
      await PhotoManager.editor.deleteWithIds(allAssetIds);
    }
  }

  /// Gets storage information from the device.
  Future<StorageInfo> getStorageInfo() async {
    final double total = await _diskSpace.getTotalDiskSpace ?? 0.0;
    final double free = await _diskSpace.getFreeDiskSpace ?? 0.0;
    
    final int totalSpace = (total * 1024 * 1024).toInt();
    final int usedSpace = ((total - free) * 1024 * 1024).toInt();

    return StorageInfo(
      totalSpace: totalSpace,
      usedSpace: usedSpace,
    );
  }

  /// Compresses all photos in the given albums to a new album using background isolates.
  Future<CompressionResult> compressAlbums({
    required List<AssetPathEntity> albums,
    required int quality,
  }) async {
    final rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      throw Exception("Failed to get RootIsolateToken for compression.");
    }
    
    int totalFiles = 0;
    int totalOriginalSize = 0;
    int totalCompressedSize = 0;

    List<Future<dynamic>> compressionFutures = [];

    for (final album in albums) {
      final newAlbumName = "${album.name} (compressed)";
      final List<AssetEntity> assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
      totalFiles += assets.length;

      for (final asset in assets) {
        final data = IsolateCompressionData(rootIsolateToken, asset.id, quality, newAlbumName);
        compressionFutures.add(compute(compressPhotoInIsolate, data));
      }
    }

    // Process in batches to avoid overwhelming the system
    const batchSize = 2; // Smaller batch for memory-intensive tasks
    for (int i = 0; i < compressionFutures.length; i += batchSize) {
      final end = (i + batchSize > compressionFutures.length) ? compressionFutures.length : i + batchSize;
      final batch = compressionFutures.sublist(i, end);
      
      final List<dynamic> batchResults = await Future.wait(batch);

      for (final result in batchResults) {
        if (result is IsolateCompressionResult) {
          totalOriginalSize += result.originalSize;
          totalCompressedSize += result.compressedSize;
        } else if (result is String) {
          if (kDebugMode) {
            print("Isolate Compression Error: $result");
          }
        }
      }
      await PhotoManager.clearFileCache(); // Clear cache between batches
    }

    return CompressionResult(
      totalFiles: totalFiles,
      spaceSaved: totalOriginalSize - totalCompressedSize,
    );
  }
}
//##############################################################################
//# 3. UTILITY CLASSES
//##############################################################################

class StorageInfo {
  final int totalSpace;
  final int usedSpace;

  StorageInfo({required this.totalSpace, required this.usedSpace});

  double get usedPercentage => totalSpace > 0 ? (usedSpace / totalSpace) * 100 : 0;
  String get usedSpaceGB => (usedSpace / 1073741824).toStringAsFixed(1);
  String get totalSpaceGB => (totalSpace / 1073741824).toStringAsFixed(0);
}
