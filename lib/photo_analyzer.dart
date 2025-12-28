import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';

class PhotoAnalysisResult {
  final String md5Hash;
  final String pHash;
  final double blurScore;
  final double luminanceScore;
  final double entropyScore;
  final double edgeDensityScore;
  final bool isFromScreenshotAlbum;
  final int faceCount;
  final double aestheticScore;
  double finalScore = 0.0;

  PhotoAnalysisResult({
    required this.md5Hash,
    required this.pHash,
    required this.blurScore,
    required this.luminanceScore,
    required this.entropyScore,
    required this.edgeDensityScore,
    required this.isFromScreenshotAlbum,
    this.faceCount = 0,
    this.aestheticScore = 0.5,
  }) {
    finalScore = _calculateFinalScore();
  }

  factory PhotoAnalysisResult.empty() {
    return PhotoAnalysisResult(
      md5Hash: '',
      pHash: '',
      blurScore: 150.0,
      luminanceScore: 128.0,
      entropyScore: 6.0,
      edgeDensityScore: 0.05,
      isFromScreenshotAlbum: false,
    );
  }

  double _calculateFinalScore() {
    // If faces are detected, this photo should never be suggested for deletion.
    if (faceCount > 0) {
      return 0.0;
    }
    
    double score = 0;
    if (isFromScreenshotAlbum) {
      return 2000.0;
    }
    if (edgeDensityScore > 0.07 && entropyScore < 5.5) {
      score += 400;
    }
    if (luminanceScore < 50.0) {
      score += 200;
    }
    if (blurScore < 100.0) {
      score += 200;
    }
    if (luminanceScore < 60.0 && blurScore < 120.0) {
      score += 400;
    }
    if (luminanceScore > 240.0) {
      score -= 100;
    }
    if (edgeDensityScore > 0.08) {
      score += 300;
    }
    if (kDebugMode) {
      print(
          "Photo [${md5Hash.substring(0, 6)}...]: Final Score = $score (Blur: $blurScore, Lum: $luminanceScore, Entropy: $entropyScore, Edges: $edgeDensityScore, isSS: $isFromScreenshotAlbum, Faces: $faceCount)");
    }
    return score;
  }
}

class PhotoAnalyzer {

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
    ),
  );


  Future<String> calculatePerceptualHash(img.Image resizedImage) async {
    final grayscaleImg = img.grayscale(resizedImage);
    final smallImg = img.copyResize(grayscaleImg,
        width: 8, height: 8, interpolation: img.Interpolation.average);
    double total = 0;
    for (int y = 0; y < smallImg.height; y++) {
      for (int x = 0; x < smallImg.width; x++) {
        total += smallImg.getPixel(x, y).r;
      }
    }
    final double average = total / 64.0;
    BigInt hash = BigInt.zero;
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        if (smallImg.getPixel(x, y).r >= average) {
          hash |= (BigInt.one << (y * 8 + x));
        }
      }
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  int hammingDistance(String pHash1, String pHash2) {
    if (pHash1.length != pHash2.length) return pHash1.length;
    final val1 = BigInt.parse(pHash1, radix: 16);
    final val2 = BigInt.parse(pHash2, radix: 16);
    BigInt xor = val1 ^ val2;
    int distance = 0;
    while (xor > BigInt.zero) {
      distance += (xor & BigInt.one) == BigInt.one ? 1 : 0;
      xor >>= 1;
    }
    return distance;
  }

  double _calculateLaplacianVariance(img.Image image) {
    final laplace = img.convolution(image, filter: [
      0,
      1,
      0,
      1,
      -4,
      1,
      0,
      1,
      0,
    ]);
    final pixels = laplace.getBytes(order: img.ChannelOrder.red);
    double mean = pixels.reduce((a, b) => a + b) / pixels.length;
    double variance =
        pixels.map((p) => math.pow(p - mean, 2)).reduce((a, b) => a + b) /
            pixels.length;
    return variance;
  }

  Map<String, double> _calculateLuminanceAndEntropy(img.Image image) {
    final luminances = <int>[];
    final histogram = List<int>.filled(256, 0);
    for (final pixel in image) {
      final luminance = pixel.r.toInt();
      luminances.add(luminance);
      histogram[luminance]++;
    }
    final double meanLuminance =
        luminances.reduce((a, b) => a + b) / luminances.length;
    double entropy = 0.0;
    final int totalPixels = luminances.length;
    for (int count in histogram) {
      if (count > 0) {
        double probability = count / totalPixels;
        entropy -= probability * (math.log(probability) / math.log(2));
      }
    }
    return {'luminance': meanLuminance, 'entropy': entropy};
  }

  double _calculateEdgeDensity(img.Image image) {
    final edgeImage = img.sobel(image);
    final edgePixels = edgeImage.getBytes(order: img.ChannelOrder.red);
    int edgeCount = edgePixels.where((p) => p > 50).length;
    return edgeCount / edgePixels.length;
  }

  Future<double> _getAestheticScore(img.Image image) async {
    return 0.5;
  }
    Future<int> _countFaces(img.Image image) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: Uint8List.fromList(img.encodeJpg(image)),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.width * 4,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces.length;
    } catch (e) {
      // Handle any errors during face detection, e.g., from an invalid image format.
      print("Error during face detection: $e");
      return 0;
    }
  }


  Future<PhotoAnalysisResult> analyze(Uint8List imageBytes,
      {bool isFromScreenshotAlbum = false}) async {
    if (kDebugMode) {
      final hash = md5.convert(imageBytes).toString().substring(0, 6);
      print("ANALYZE START for photo [$hash]...");
    }
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Could not decode image");
    }
    final lowResGray = img.copyResize(originalImage,
        width: 64, height: 64, interpolation: img.Interpolation.average);
    img.grayscale(lowResGray);
    final md5Hash = md5.convert(imageBytes).toString();
    final pHashFuture = calculatePerceptualHash(lowResGray);
    final blurScore = _calculateLaplacianVariance(lowResGray);
    final lumAndEntropy = _calculateLuminanceAndEntropy(lowResGray);
    final edgeScore = _calculateEdgeDensity(lowResGray);
    final aestheticScoreFuture = _getAestheticScore(originalImage);
    final faceCountFuture = _countFaces(originalImage);

    final results = await Future.wait([
      pHashFuture,
      aestheticScoreFuture,
      faceCountFuture,
    ]);
    return PhotoAnalysisResult(
      md5Hash: md5Hash,
      pHash: results[0] as String,
      blurScore: blurScore,
      luminanceScore: lumAndEntropy['luminance']!,
      entropyScore: lumAndEntropy['entropy']!,
      edgeDensityScore: edgeScore,
      isFromScreenshotAlbum: isFromScreenshotAlbum,
      faceCount: results[2] as int,
      aestheticScore: results[1] as double,
    );
  }
}
