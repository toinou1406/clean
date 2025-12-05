
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
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
/// This function is now wrapped in a robust try-catch block to prevent any crash.
Future<dynamic> analyzePhotoInIsolate(IsolateData isolateData) async {
  try {
    // Initialize platform channels for this isolate.
    BackgroundIsolateBinaryMessenger.ensureInitialized(isolateData.token);

    final String assetId = isolateData.assetId;
    final AssetEntity? asset = await AssetEntity.fromId(assetId);
    if (asset == null) {
      return null;
    }

    final Uint8List? imageBytes = await asset.thumbnailDataWithSize(const ThumbnailSize(64, 64));
    if (imageBytes == null) {
      return null;
    }

    final analyzer = PhotoAnalyzer();
    final analysisResult = await analyzer.analyze(
      imageBytes,
      isFromScreenshotAlbum: isolateData.isFromScreenshotAlbum,
    );
    return IsolateAnalysisResult(asset.id, analysisResult);

  } catch (e, s) {
    // Log the specific error from the isolate for future debugging.
    developer.log(
      'Analysis failed for asset ${isolateData.assetId}',
      name: 'photo_cleaner.isolate',
      error: e,
      stackTrace: s,
    );
    // Return null to signify that this specific photo failed, allowing the batch to continue.
    return null;
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

class PhotoCleanerService {
  final DiskSpacePlus _diskSpace = DiskSpacePlus();
  
  final List<PhotoResult> _allPhotos = [];
  final Set<String> _seenPhotoIds = {};

  void reset() {
    _seenPhotoIds.clear();
  }

  /// Scans all photos using a high-performance, batched background process.
  /// Returns the number of photos successfully analyzed.
  Future<void> scanPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      throw Exception('Full photo access permission is required.');
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;

    List<AssetEntity> screenshotAssets = [];
    List<AssetEntity> otherAssets = [];
    final Set<String> screenshotAssetIds = {}; // Keep this to flag screenshots for the analyzer

    final screenshotAlbums = albums.where((album) => album.name.toLowerCase() == 'screenshots').toList();
    final otherAlbums = albums.where((album) => album.name.toLowerCase() != 'screenshots').toList();

    // Get all screenshot assets
    for (final album in screenshotAlbums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        screenshotAssetIds.addAll(assets.map((a) => a.id));
        screenshotAssets.addAll(assets);
    }
    
    // Get all other assets
    for (final album in otherAlbums) {
        final assets = await album.getAssetListRange(start: 0, end: await album.assetCountAsync);
        otherAssets.addAll(assets);
    }
    
    // Shuffle both lists to get a random sample
    screenshotAssets.shuffle();
    otherAssets.shuffle();

    // Apply the 60/40 ratio
    const totalToAnalyze = 300;
    final screenshotsCount = (totalToAnalyze * 0.6).round();
    final othersCount = totalToAnalyze - screenshotsCount;

    final selectedScreenshots = screenshotAssets.take(screenshotsCount).toList();
    final selectedOthers = otherAssets.take(othersCount).toList();

    List<AssetEntity> assetsToAnalyze = [
      ...selectedScreenshots,
      ...selectedOthers,
    ];
    
    // Shuffle the final list before analysis
    assetsToAnalyze.shuffle();
    
    _allPhotos.clear();

    final rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      throw Exception("Failed to get RootIsolateToken. Make sure you are on Flutter 3.7+ and running on the main isolate.");
    }
    
    final analysisFutures = assetsToAnalyze.map((asset) {
        final bool isScreenshot = screenshotAssetIds.contains(asset.id);
        return compute(analyzePhotoInIsolate, IsolateData(rootIsolateToken, asset.id, isScreenshot));
    }).toList();

    final List<IsolateAnalysisResult> analysisResults = [];
    const batchSize = 12;

    for (int i = 0; i < analysisFutures.length; i += batchSize) {
        final end = (i + batchSize > analysisFutures.length) ? analysisFutures.length : i + batchSize;
        final batch = analysisFutures.sublist(i, end);
        final List<dynamic> batchResults = await Future.wait(batch);

        for (final result in batchResults) {
          if (result is IsolateAnalysisResult) {
            analysisResults.add(result);
          }
        }
        await PhotoManager.clearFileCache();
    }

    final Map<String, AssetEntity> assetMap = {for (var asset in assetsToAnalyze) asset.id: asset};

    _allPhotos.addAll(
        analysisResults.where((r) => assetMap.containsKey(r.assetId)).map((r) => PhotoResult(assetMap[r.assetId]!, r.analysis))
    );
  }

  Future<List<PhotoResult>> selectPhotosToDelete({List<String> excludedIds = const []}) async {
    List<PhotoResult> candidates = _allPhotos
        .where((p) => !excludedIds.contains(p.asset.id) && !_seenPhotoIds.contains(p.asset.id))
        .toList();

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final selected = candidates.take(24).toList();

    _seenPhotoIds.addAll(selected.map((p) => p.asset.id));
    
    return selected;
  }

  Future<List<String>> deletePhotos(List<PhotoResult> photos) async {
    if (photos.isEmpty) return [];
    final ids = photos.map((p) => p.asset.id).toList();
    final List<String> deletedIds = await PhotoManager.editor.deleteWithIds(ids);
    return deletedIds;
  }

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
